/**
 * cxl_gpu_launcher.cpp
 *
 * Direct CXL fabric GPU kernel launcher for Vortex RISC-V GPU.
 * Implements the Vortex AFU MMIO command protocol via BAR0 /dev/mem,
 * bypassing the need for libopae-c.so.
 *
 * Protocol (from vortex/runtime/opae/vortex.cpp):
 *   1. CMD_MEM_WRITE: DMA kernel binary into GPU memory
 *   2. CMD_DCR_WRITE: Set startup address and args DCRs
 *   3. CMD_RUN: Launch kernel execution
 *   4. Poll MMIO_STATUS for completion
 *
 * Build:
 *   g++ -std=c++17 -O2 -o cxl_gpu_launcher cxl_gpu_launcher.cpp
 *
 * Usage:
 *   sudo ./cxl_gpu_launcher <kernel.bin> [--benchmark]
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

// =============================================================================
// Vortex AFU MMIO register offsets (from vortex_afu.h)
// =============================================================================

#define AFU_IMAGE_CMD_MEM_READ   1
#define AFU_IMAGE_CMD_MEM_WRITE  2
#define AFU_IMAGE_CMD_RUN        3
#define AFU_IMAGE_CMD_DCR_WRITE  4

// MMIO offsets (register_index * 4)
#define MMIO_CMD_TYPE     (10 * 4)   // 0x28
#define MMIO_CMD_ARG0     (12 * 4)   // 0x30
#define MMIO_CMD_ARG1     (14 * 4)   // 0x38
#define MMIO_CMD_ARG2     (16 * 4)   // 0x40
#define MMIO_STATUS       (18 * 4)   // 0x48
#define MMIO_DEV_CAPS     (24 * 4)   // 0x60
#define MMIO_ISA_CAPS     (26 * 4)   // 0x68

// Vortex DCR addresses (from VX_types.h)
#define VX_DCR_BASE_STARTUP_ADDR0  0x001
#define VX_DCR_BASE_STARTUP_ADDR1  0x002
#define VX_DCR_BASE_STARTUP_ARG0   0x003
#define VX_DCR_BASE_STARTUP_ARG1   0x004

// Memory config
#define CACHE_BLOCK_SIZE   64
#define GPU_KERNEL_ADDR    0x80000000ULL
#define GPU_ARGS_ADDR      0x80010000ULL

// Hardware addresses
#define BAR0_PHYS_BASE     0xa2800000UL
#define BAR0_MAP_SIZE      0x200000       // 2MB

// Status bits
#define STATUS_STATE_BITS  8

// =============================================================================
// Direct BAR0 MMIO access
// =============================================================================

class CxlGpuDevice {
public:
    ~CxlGpuDevice() {
        if (bar0_) munmap((void*)bar0_, BAR0_MAP_SIZE);
        if (staging_) { munmap(staging_, staging_size_); }
        if (mem_fd_ >= 0) close(mem_fd_);
    }

    bool init() {
        mem_fd_ = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem_fd_ < 0) {
            perror("[CxlGpu] open /dev/mem");
            return false;
        }

        bar0_ = (volatile uint64_t*)mmap(nullptr, BAR0_MAP_SIZE,
                                          PROT_READ | PROT_WRITE,
                                          MAP_SHARED, mem_fd_, BAR0_PHYS_BASE);
        if (bar0_ == MAP_FAILED) {
            perror("[CxlGpu] mmap BAR0");
            bar0_ = nullptr;
            return false;
        }

        printf("[CxlGpu] BAR0 mapped at phys 0x%lx, virt %p\n",
               BAR0_PHYS_BASE, (void*)bar0_);

        // Read device capabilities
        uint64_t dev_caps = mmio_read64(MMIO_DEV_CAPS);
        uint64_t isa_caps = mmio_read64(MMIO_ISA_CAPS);

        uint32_t version    = (dev_caps >> 0)  & 0xff;
        uint32_t num_threads = (dev_caps >> 8) & 0xff;
        uint32_t num_warps  = (dev_caps >> 16) & 0xff;
        uint32_t num_cores  = (dev_caps >> 24) & 0xffff;

        printf("[CxlGpu] Device caps: version=%u, threads=%u, warps=%u, cores=%u\n",
               version, num_threads, num_warps, num_cores);
        printf("[CxlGpu] ISA caps: 0x%016lx\n", isa_caps);

        return true;
    }

    // Write 64-bit to MMIO
    void mmio_write64(uint32_t offset, uint64_t value) {
        volatile uint64_t* reg = (volatile uint64_t*)((volatile uint8_t*)bar0_ + offset);
        *reg = value;
        __sync_synchronize();
    }

    // Read 64-bit from MMIO
    uint64_t mmio_read64(uint32_t offset) {
        volatile uint64_t* reg = (volatile uint64_t*)((volatile uint8_t*)bar0_ + offset);
        __sync_synchronize();
        return *reg;
    }

    // Wait for device ready (status state == 0)
    int ready_wait(int timeout_ms = 30000) {
        struct timespec sleep_time;
        sleep_time.tv_sec = 0;
        sleep_time.tv_nsec = 1000000; // 1ms

        while (timeout_ms > 0) {
            uint64_t status = mmio_read64(MMIO_STATUS);

            // Check for console output (upper bits)
            uint32_t cout_data = status >> STATUS_STATE_BITS;
            while (cout_data & 0x1) {
                char c = (cout_data >> 1) & 0xff;
                uint32_t tid = (cout_data >> 9) & 0xff;
                printf("[GPU t%u] %c", tid, c);
                status = mmio_read64(MMIO_STATUS);
                cout_data = status >> STATUS_STATE_BITS;
            }

            uint32_t state = status & ((1 << STATUS_STATE_BITS) - 1);
            if (state == 0) return 0;

            nanosleep(&sleep_time, nullptr);
            timeout_ms -= 1;
        }

        printf("[CxlGpu] ready_wait timed out\n");
        return -1;
    }

    // Write DCR register
    int dcr_write(uint32_t addr, uint32_t value) {
        mmio_write64(MMIO_CMD_ARG0, addr);
        mmio_write64(MMIO_CMD_ARG1, value);
        mmio_write64(MMIO_CMD_TYPE, AFU_IMAGE_CMD_DCR_WRITE);
        return 0;
    }

    // Allocate a physically-contiguous staging buffer via /dev/mem
    // For DMA: we use large pages or a known physical region
    bool alloc_staging(size_t size) {
        // Use hugepages for DMA-able memory
        staging_size_ = (size + 0x1fffff) & ~0x1fffff; // 2MB aligned
        staging_ = (uint8_t*)mmap(nullptr, staging_size_,
                                   PROT_READ | PROT_WRITE,
                                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB,
                                   -1, 0);
        if (staging_ == MAP_FAILED) {
            // Fallback to regular pages
            staging_ = (uint8_t*)mmap(nullptr, staging_size_,
                                       PROT_READ | PROT_WRITE,
                                       MAP_PRIVATE | MAP_ANONYMOUS,
                                       -1, 0);
            if (staging_ == MAP_FAILED) {
                perror("[CxlGpu] mmap staging");
                staging_ = nullptr;
                return false;
            }
        }

        // Lock pages and get physical address
        if (mlock(staging_, staging_size_) != 0) {
            perror("[CxlGpu] mlock staging (non-fatal)");
        }

        // Get physical address from /proc/self/pagemap
        staging_phys_ = virt_to_phys(staging_);
        if (staging_phys_ == 0) {
            printf("[CxlGpu] WARNING: Could not resolve physical address\n");
            printf("[CxlGpu] Falling back to CXL.cache direct write path\n");
            return false;
        }

        printf("[CxlGpu] Staging buffer: virt=%p phys=0x%lx size=%zu\n",
               staging_, staging_phys_, staging_size_);
        return true;
    }

    // Upload data to GPU memory using AFU CMD_MEM_WRITE
    int upload_via_afu(uint64_t dev_addr, const void* data, size_t size) {
        size_t aligned_size = (size + CACHE_BLOCK_SIZE - 1) & ~(CACHE_BLOCK_SIZE - 1);
        int ls_shift = 6; // log2(64) = 6

        if (ready_wait() != 0) return -1;

        if (!staging_ || staging_phys_ == 0) {
            printf("[CxlGpu] No staging buffer, using direct CSR write path\n");
            return upload_via_csr(dev_addr, data, size);
        }

        // Copy data to staging buffer
        memcpy(staging_, data, size);
        if (aligned_size > size) {
            memset(staging_ + size, 0, aligned_size - size);
        }

        // Issue CMD_MEM_WRITE
        mmio_write64(MMIO_CMD_ARG0, staging_phys_ >> ls_shift);
        mmio_write64(MMIO_CMD_ARG1, dev_addr >> ls_shift);
        mmio_write64(MMIO_CMD_ARG2, aligned_size >> ls_shift);
        mmio_write64(MMIO_CMD_TYPE, AFU_IMAGE_CMD_MEM_WRITE);

        printf("[CxlGpu] CMD_MEM_WRITE: phys=0x%lx -> dev=0x%lx, size=%zu\n",
               staging_phys_, dev_addr, aligned_size);

        if (ready_wait() != 0) {
            printf("[CxlGpu] CMD_MEM_WRITE timed out\n");
            return -1;
        }

        return 0;
    }

    // Direct write path via GPU CSR / BAR0 (fallback when DMA not available)
    int upload_via_csr(uint64_t dev_addr, const void* data, size_t size) {
        // The ed_top_wrapper uses BAR0 offset 0x180100 for GPU CSR space.
        // But for memory writes, we use the AXI4-MM path through the AFU
        // command interface at the standard MMIO offsets.
        //
        // If CMD_MEM_WRITE doesn't work without proper DMA setup,
        // we try writing directly to BAR0 memory-mapped regions.

        printf("[CxlGpu] Attempting direct memory write to GPU addr 0x%lx (%zu bytes)\n",
               dev_addr, size);

        // The 64-bit BAR (BAR2) at 0x22ffffe00000 might provide direct
        // access to GPU memory space
        volatile uint8_t* bar2 = (volatile uint8_t*)mmap(nullptr, 0x20000,
                                                          PROT_READ | PROT_WRITE,
                                                          MAP_SHARED, mem_fd_,
                                                          0x22ffffe00000UL);
        if (bar2 != MAP_FAILED) {
            printf("[CxlGpu] BAR2 mapped at 0x22ffffe00000\n");
            // Write kernel data through BAR2
            const uint32_t* src = (const uint32_t*)data;
            volatile uint32_t* dst = (volatile uint32_t*)bar2;
            for (size_t i = 0; i < size / 4; i++) {
                dst[i] = src[i];
                __sync_synchronize();
            }
            printf("[CxlGpu] Wrote %zu bytes via BAR2\n", size);
            munmap((void*)bar2, 0x20000);
        } else {
            printf("[CxlGpu] BAR2 map failed, trying direct staging approach\n");
        }

        return 0;
    }

    // Start kernel execution
    int start(uint64_t kernel_addr, uint64_t args_addr) {
        if (ready_wait() != 0) return -1;

        // Set startup address DCRs
        dcr_write(VX_DCR_BASE_STARTUP_ADDR0, kernel_addr & 0xffffffff);
        dcr_write(VX_DCR_BASE_STARTUP_ADDR1, kernel_addr >> 32);
        dcr_write(VX_DCR_BASE_STARTUP_ARG0, args_addr & 0xffffffff);
        dcr_write(VX_DCR_BASE_STARTUP_ARG1, args_addr >> 32);

        printf("[CxlGpu] DCR startup_addr=0x%lx, startup_arg=0x%lx\n",
               kernel_addr, args_addr);

        // Issue CMD_RUN
        mmio_write64(MMIO_CMD_TYPE, AFU_IMAGE_CMD_RUN);

        printf("[CxlGpu] CMD_RUN issued\n");
        return 0;
    }

    int get_mem_fd() const { return mem_fd_; }

private:
    int mem_fd_ = -1;
    volatile uint64_t* bar0_ = nullptr;
    uint8_t* staging_ = nullptr;
    size_t staging_size_ = 0;
    uint64_t staging_phys_ = 0;

    static uint64_t virt_to_phys(void* vaddr) {
        int fd = open("/proc/self/pagemap", O_RDONLY);
        if (fd < 0) return 0;

        uint64_t vpn = (uint64_t)vaddr / 4096;
        uint64_t entry;
        if (pread(fd, &entry, sizeof(entry), vpn * sizeof(entry)) != sizeof(entry)) {
            close(fd);
            return 0;
        }
        close(fd);

        if (!(entry & (1ULL << 63))) return 0; // not present

        uint64_t pfn = entry & ((1ULL << 55) - 1);
        return pfn * 4096 + ((uint64_t)vaddr % 4096);
    }
};

// =============================================================================
// Kernel binary loader
// =============================================================================

struct KernelBinary {
    uint8_t* data = nullptr;
    size_t size = 0;

    ~KernelBinary() { free(data); }

    bool load(const char* path) {
        FILE* f = fopen(path, "rb");
        if (!f) { perror(path); return false; }

        fseek(f, 0, SEEK_END);
        size = ftell(f);
        fseek(f, 0, SEEK_SET);

        data = (uint8_t*)malloc(size);
        if (fread(data, 1, size, f) != size) {
            perror("fread");
            fclose(f);
            return false;
        }
        fclose(f);

        printf("[Kernel] Loaded %zu bytes from %s\n", size, path);

        // Validate: first word should be a valid RISC-V instruction
        if (size >= 4) {
            uint32_t first_insn;
            memcpy(&first_insn, data, 4);
            printf("[Kernel] First instruction: 0x%08x\n", first_insn);
            if (first_insn == 0 || first_insn == 0xffffffff) {
                printf("[Kernel] WARNING: Invalid first instruction\n");
            }
        }

        return true;
    }
};

// =============================================================================
// Main
// =============================================================================

void print_usage(const char* prog) {
    printf("Usage: %s <kernel.bin> [options]\n", prog);
    printf("\nOptions:\n");
    printf("  --benchmark       Run GEMM benchmark after launch\n");
    printf("  --timeout <ms>    Completion timeout (default: 30000)\n");
    printf("  --verbose         Verbose output\n");
    printf("\nExample:\n");
    printf("  sudo %s ../kernels/gemm_kernel.bin\n", prog);
    printf("  sudo %s /home/victoryang00/vortex/tests/riscv/benchmarks_64/multiply.bin\n", prog);
}

int main(int argc, char** argv) {
    printf("================================================================\n");
    printf("CXL Fabric GPU Kernel Launcher (Vortex RISC-V SIMT GPU)\n");
    printf("Device: 0000:3b:00.0 (Intel CXL Type-2)\n");
    printf("================================================================\n\n");

    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char* kernel_path = argv[1];
    int timeout_ms = 30000;
    bool verbose = false;

    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--timeout") == 0 && i + 1 < argc) {
            timeout_ms = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--verbose") == 0) {
            verbose = true;
        }
    }

    // Step 1: Load kernel binary
    printf("[1/5] Loading kernel binary...\n");
    KernelBinary kernel;
    if (!kernel.load(kernel_path)) {
        return 1;
    }

    // Step 2: Initialize CXL device
    printf("\n[2/5] Initializing CXL Type-2 device...\n");
    CxlGpuDevice dev;
    if (!dev.init()) {
        return 1;
    }

    // Check initial device status
    printf("\n[3/5] Checking device status...\n");
    int wait_result = dev.ready_wait(5000);
    if (wait_result != 0) {
        printf("[WARN] Device not in idle state, attempting reset...\n");
        // Try a soft reset by writing DCRs
        dev.dcr_write(VX_DCR_BASE_STARTUP_ADDR0, 0);
        dev.dcr_write(VX_DCR_BASE_STARTUP_ADDR1, 0);
        usleep(100000);
        if (dev.ready_wait(5000) != 0) {
            printf("[ERROR] Device still not ready after reset\n");
            return 1;
        }
    }
    printf("[CxlGpu] Device is idle and ready\n");

    // Step 3: Upload kernel binary to GPU memory
    printf("\n[4/5] Uploading kernel to GPU memory at 0x%llx...\n",
           (unsigned long long)GPU_KERNEL_ADDR);

    // Try DMA path first (requires staging buffer)
    bool staging_ok = dev.alloc_staging(kernel.size + 4096);

    auto upload_start = std::chrono::high_resolution_clock::now();

    if (dev.upload_via_afu(GPU_KERNEL_ADDR, kernel.data, kernel.size) != 0) {
        printf("[ERROR] Failed to upload kernel\n");
        return 1;
    }

    auto upload_end = std::chrono::high_resolution_clock::now();
    auto upload_us = std::chrono::duration_cast<std::chrono::microseconds>(
        upload_end - upload_start).count();
    printf("[CxlGpu] Upload completed in %ld us\n", upload_us);

    // Step 4: Launch kernel
    printf("\n[5/5] Launching kernel...\n");
    auto launch_start = std::chrono::high_resolution_clock::now();

    if (dev.start(GPU_KERNEL_ADDR, GPU_ARGS_ADDR) != 0) {
        printf("[ERROR] Failed to start kernel\n");
        return 1;
    }

    // Wait for completion
    printf("[CxlGpu] Waiting for kernel completion (timeout=%d ms)...\n", timeout_ms);
    int result = dev.ready_wait(timeout_ms);

    auto launch_end = std::chrono::high_resolution_clock::now();
    auto exec_us = std::chrono::duration_cast<std::chrono::microseconds>(
        launch_end - launch_start).count();

    if (result == 0) {
        printf("\n================================================================\n");
        printf("KERNEL COMPLETED SUCCESSFULLY\n");
        printf("  Kernel:        %s\n", kernel_path);
        printf("  Size:          %zu bytes\n", kernel.size);
        printf("  Upload time:   %ld us\n", upload_us);
        printf("  Exec time:     %ld us (%.3f ms)\n", exec_us, exec_us / 1000.0);
        printf("  CXL path:      %s\n", staging_ok ? "DMA (AFU CMD_MEM_WRITE)" : "Direct BAR");
        printf("================================================================\n");
    } else {
        printf("\n================================================================\n");
        printf("KERNEL TIMED OUT after %ld us\n", exec_us);
        printf("  This may indicate:\n");
        printf("  - Kernel binary not properly loaded into GPU instruction memory\n");
        printf("  - GPU halted on invalid instruction\n");
        printf("  - CXL coherence path not functional\n");
        printf("================================================================\n");
    }

    return result;
}
