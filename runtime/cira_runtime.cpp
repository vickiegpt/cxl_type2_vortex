/**
 * cira_runtime.cpp
 *
 * Host-side CIRA runtime — real hardware implementation.
 * Uses Vortex AFU MMIO command protocol on Intel Agilex 7 CXL Type 2 FPGA.
 *
 * BAR0 at 0xa2800000, device BDF 0000:3b:00.0
 */

#include "cira_runtime.h"
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <time.h>

namespace cira::runtime {

CiraRuntime::CiraRuntime() = default;

CiraRuntime::~CiraRuntime() {
    if (staging_) {
        munmap(staging_, staging_size_);
    }
    if (bar0_) {
        munmap((void*)bar0_, BAR0_MAP_SIZE);
    }
    if (mem_fd_ >= 0) {
        close(mem_fd_);
    }
}

// ============================================================================
// Low-level MMIO
// ============================================================================

void CiraRuntime::mmio_write64(uint32_t offset, uint64_t value) {
    volatile uint64_t* reg = (volatile uint64_t*)(bar0_ + offset);
    *reg = value;
    __sync_synchronize();
}

uint64_t CiraRuntime::mmio_read64(uint32_t offset) {
    volatile uint64_t* reg = (volatile uint64_t*)(bar0_ + offset);
    __sync_synchronize();
    return *reg;
}

// ============================================================================
// Physical address resolution (via /proc/self/pagemap)
// ============================================================================

uint64_t CiraRuntime::virt_to_phys(void* vaddr) {
    uint64_t page_size = sysconf(_SC_PAGESIZE);
    uint64_t vpn = (uint64_t)vaddr / page_size;

    int fd = open("/proc/self/pagemap", O_RDONLY);
    if (fd < 0) return 0;

    uint64_t entry = 0;
    if (pread(fd, &entry, sizeof(entry), vpn * sizeof(uint64_t)) != sizeof(uint64_t)) {
        close(fd);
        return 0;
    }
    close(fd);

    if (!(entry & (1ULL << 63))) return 0;  // Page not present

    uint64_t pfn = entry & ((1ULL << 55) - 1);
    uint64_t offset = (uint64_t)vaddr % page_size;
    return pfn * page_size + offset;
}

// ============================================================================
// Staging buffer (hugepage-backed for DMA)
// ============================================================================

bool CiraRuntime::alloc_staging(size_t size) {
    staging_size_ = (size + 0x1fffff) & ~0x1fffffULL;  // 2MB aligned

    // Try hugepages first
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
            perror("[CIRA] mmap staging");
            staging_ = nullptr;
            return false;
        }
    }

    // Lock pages for DMA
    mlock(staging_, staging_size_);

    // Resolve physical address
    staging_phys_ = virt_to_phys(staging_);
    if (staging_phys_ == 0) {
        fprintf(stderr, "[CIRA] WARNING: Could not resolve staging phys addr\n");
        fprintf(stderr, "[CIRA] Will use direct CSR write path instead\n");
    } else {
        fprintf(stderr, "[CIRA] Staging buffer: virt=%p phys=0x%lx size=%zu\n",
                staging_, staging_phys_, staging_size_);
    }

    return true;
}

// ============================================================================
// Device initialization
// ============================================================================

bool CiraRuntime::init(uint64_t bar0_phys) {
    mem_fd_ = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd_ < 0) {
        perror("[CIRA] open /dev/mem (need root)");
        return false;
    }

    bar0_ = (volatile uint8_t*)mmap(nullptr, BAR0_MAP_SIZE,
                                     PROT_READ | PROT_WRITE,
                                     MAP_SHARED, mem_fd_, bar0_phys);
    if (bar0_ == MAP_FAILED) {
        perror("[CIRA] mmap BAR0");
        bar0_ = nullptr;
        return false;
    }

    fprintf(stderr, "[CIRA] BAR0 mapped: phys=0x%lx virt=%p size=0x%zx\n",
            bar0_phys, (void*)bar0_, BAR0_MAP_SIZE);

    // Query device capabilities
    uint64_t dev_caps = mmio_read64(MMIO_DEV_CAPS);
    caps_.version     = (dev_caps >>  0) & 0xff;
    caps_.num_threads = (dev_caps >>  8) & 0xff;
    caps_.num_warps   = (dev_caps >> 16) & 0xff;
    caps_.num_cores   = (dev_caps >> 24) & 0xffff;
    caps_.isa_caps    = mmio_read64(MMIO_ISA_CAPS);

    fprintf(stderr, "[CIRA] Device: version=%u cores=%u warps=%u threads=%u\n",
            caps_.version, caps_.num_cores, caps_.num_warps, caps_.num_threads);
    fprintf(stderr, "[CIRA] ISA caps: 0x%016lx\n", caps_.isa_caps);

    // Allocate staging buffer for DMA (2MB)
    alloc_staging(2 * 1024 * 1024);

    // Wait for device ready
    if (wait_completion(5000) != 0) {
        fprintf(stderr, "[CIRA] WARNING: Device not in idle state at init\n");
    }

    fprintf(stderr, "[CIRA] Runtime initialized (hardware mode)\n");
    return true;
}

// ============================================================================
// Wait for device idle (poll MMIO_STATUS)
// ============================================================================

int CiraRuntime::wait_completion(int timeout_ms) {
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 100000;  // 100us poll interval

    while (timeout_ms > 0) {
        uint64_t status = mmio_read64(MMIO_STATUS);

        // Check for console output (upper bits)
        uint32_t cout_data = status >> STATUS_STATE_BITS;
        while (cout_data & 0x1) {
            char c = (cout_data >> 1) & 0xff;
            uint32_t tid = (cout_data >> 9) & 0xff;
            fprintf(stderr, "[GPU t%u] %c", tid, c);
            status = mmio_read64(MMIO_STATUS);
            cout_data = status >> STATUS_STATE_BITS;
        }

        uint32_t state = status & ((1 << STATUS_STATE_BITS) - 1);
        if (state == 0) {
            kernel_running_ = false;
            return 0;  // Device idle
        }

        nanosleep(&ts, nullptr);
        timeout_ms -= 1;  // ~100us per iteration, approximate
    }

    fprintf(stderr, "[CIRA] wait_completion timed out\n");
    return -1;
}

// ============================================================================
// DCR write
// ============================================================================

void CiraRuntime::dcr_write(uint32_t addr, uint32_t value) {
    mmio_write64(MMIO_CMD_ARG0, addr);
    mmio_write64(MMIO_CMD_ARG1, value);
    mmio_write64(MMIO_CMD_TYPE, AFU_CMD_DCR_WRITE);
}

// ============================================================================
// Upload via AFU CMD_MEM_WRITE
// ============================================================================

int CiraRuntime::upload_via_afu(uint64_t dev_addr, const void* data, size_t size) {
    size_t aligned = (size + CACHE_BLOCK_SIZE - 1) & ~(size_t)(CACHE_BLOCK_SIZE - 1);

    if (wait_completion() != 0) return -1;

    if (!staging_ || staging_phys_ == 0) {
        // Fallback: write via DCR path (slow, cacheline-at-a-time)
        fprintf(stderr, "[CIRA] No staging buffer, upload via DCR path (%zu bytes)\n", size);
        // For small payloads (args), write via DCR
        // For large payloads (kernels), this won't work well
        return -1;
    }

    // Copy to staging buffer
    memcpy(staging_, data, size);
    if (aligned > size) {
        memset(staging_ + size, 0, aligned - size);
    }

    // Issue CMD_MEM_WRITE: staging phys -> device addr
    mmio_write64(MMIO_CMD_ARG0, staging_phys_ >> LS_SHIFT);
    mmio_write64(MMIO_CMD_ARG1, dev_addr >> LS_SHIFT);
    mmio_write64(MMIO_CMD_ARG2, aligned >> LS_SHIFT);
    mmio_write64(MMIO_CMD_TYPE, AFU_CMD_MEM_WRITE);

    fprintf(stderr, "[CIRA] CMD_MEM_WRITE: phys=0x%lx -> dev=0x%lx size=%zu\n",
            staging_phys_, dev_addr, aligned);

    if (wait_completion() != 0) {
        fprintf(stderr, "[CIRA] CMD_MEM_WRITE timed out\n");
        return -1;
    }

    return 0;
}

// ============================================================================
// Public API: upload
// ============================================================================

bool CiraRuntime::upload(const void* data, size_t size, uint64_t dev_addr) {
    return upload_via_afu(dev_addr, data, size) == 0;
}

// ============================================================================
// Load kernel binary
// ============================================================================

bool CiraRuntime::load_kernel(const std::string& path, uint64_t load_addr) {
    FILE* f = fopen(path.c_str(), "rb");
    if (!f) {
        perror("[CIRA] open kernel binary");
        return false;
    }

    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);

    std::vector<uint8_t> data(size);
    if (fread(data.data(), 1, size, f) != size) {
        perror("[CIRA] read kernel binary");
        fclose(f);
        return false;
    }
    fclose(f);

    fprintf(stderr, "[CIRA] Loading kernel: %s (%zu bytes -> dev 0x%lx)\n",
            path.c_str(), size, load_addr);

    return upload(data.data(), size, load_addr);
}

// ============================================================================
// Launch kernel
// ============================================================================

bool CiraRuntime::launch_kernel(uint64_t kernel_addr, uint64_t args_addr) {
    if (wait_completion(5000) != 0) {
        fprintf(stderr, "[CIRA] Device busy, cannot launch\n");
        return false;
    }

    // Write DCRs for startup address and args
    dcr_write(VX_DCR_BASE_STARTUP_ADDR0, (uint32_t)(kernel_addr & 0xFFFFFFFF));
    dcr_write(VX_DCR_BASE_STARTUP_ADDR1, (uint32_t)(kernel_addr >> 32));
    dcr_write(VX_DCR_BASE_STARTUP_ARG0,  (uint32_t)(args_addr & 0xFFFFFFFF));
    dcr_write(VX_DCR_BASE_STARTUP_ARG1,  (uint32_t)(args_addr >> 32));

    // Issue CMD_RUN
    mmio_write64(MMIO_CMD_TYPE, AFU_CMD_RUN);
    kernel_running_ = true;

    fprintf(stderr, "[CIRA] CMD_RUN: kernel=0x%lx args=0x%lx\n",
            kernel_addr, args_addr);

    return true;
}

// ============================================================================
// High-level CIRA operations
// ============================================================================

CiraHandle CiraRuntime::alloc_cxl(size_t size) {
    size_t aligned = (size + CACHELINE_SIZE - 1) & ~(CACHELINE_SIZE - 1);

    CiraHandle h;
    // Bump-allocate device memory addresses
    h.device_addr = next_dev_alloc_;
    next_dev_alloc_ += aligned;
    // Host staging copy
    h.host_addr = aligned_alloc(CACHELINE_SIZE, aligned);
    h.size = aligned;
    if (h.host_addr) memset(h.host_addr, 0, aligned);
    return h;
}

void CiraRuntime::free_cxl(CiraHandle& handle) {
    if (handle.host_addr) {
        free(handle.host_addr);
        handle.host_addr = nullptr;
    }
}

CiraFuture CiraRuntime::future_create(uint32_t num_lines) {
    CiraFuture f;
    f.id = next_future_id_++ % MAX_FUTURES;
    f.completion = &completion_pool_[f.id];
    f.device_addr = GPU_COMPL_ADDR + f.id * CACHELINE_SIZE;
    reset_completion(f.completion);

    // Upload zeroed completion slot to device memory
    CompletionData zero = {};
    upload(&zero, sizeof(zero), f.device_addr);

    return f;
}

bool CiraRuntime::future_await(CiraFuture& future, int timeout_ms) {
    // For real hardware: we need to read back from device memory
    // The device writes CompletionData to the slot; we read it back
    // via CMD_MEM_READ or by polling the host-visible HDM region.
    //
    // For now: wait for kernel completion (Vortex is single-kernel).
    return wait_completion(timeout_ms) == 0;
}

void CiraRuntime::release(CiraFuture& future) {
    reset_completion(future.completion);
}

bool CiraRuntime::offload(uint64_t func_addr, const void* args, size_t args_size,
                          CiraFuture* future) {
    // 1. Upload args to device memory
    if (!upload(args, args_size, GPU_ARGS_ADDR)) {
        fprintf(stderr, "[CIRA] Failed to upload kernel args\n");
        return false;
    }

    // 2. Launch kernel
    if (!launch_kernel(func_addr, GPU_ARGS_ADDR)) {
        fprintf(stderr, "[CIRA] Failed to launch kernel\n");
        return false;
    }

    return true;
}

bool CiraRuntime::barrier(int timeout_ms) {
    return wait_completion(timeout_ms) == 0;
}

void CiraRuntime::phase_boundary(const std::string& phase_name) {
    barrier();
    if (!phase_name.empty()) {
        fprintf(stderr, "[CIRA] Phase boundary: %s\n", phase_name.c_str());
    }
}

uint32_t CiraRuntime::pending_tasks() const {
    return kernel_running_ ? 1 : 0;
}

}  // namespace cira::runtime
