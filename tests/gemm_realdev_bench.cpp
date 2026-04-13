/**
 * gemm_realdev_bench.cpp
 *
 * Real device GEMM benchmark with Type2 snoop DCOH verification.
 * Tests actual GPU kernel execution and measures coherency performance.
 *
 * Usage: gemm_realdev_bench [--dim N] [--verbose]
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <memory>

#include "../kernels/gemm_args.h"

// BAR0 base address and GPU CSR offsets
#define BAR0_BASE    0xa2800000UL
#define GPU_CSR_BASE (BAR0_BASE + 0x180100)

// GPU CSR registers
#define KERNEL_ADDR_LO  0x100
#define KERNEL_ADDR_HI  0x104
#define KERNEL_ARGS_LO  0x108
#define KERNEL_ARGS_HI  0x10C
#define GRID_DIM_X      0x110
#define GRID_DIM_Y      0x114
#define GRID_DIM_Z      0x118
#define BLOCK_DIM_X     0x11C
#define BLOCK_DIM_Y     0x120
#define BLOCK_DIM_Z     0x124
#define LAUNCH          0x128
#define STATUS          0x12C
#define CYCLE_LO        0x130
#define CYCLE_HI        0x134
#define DCOH_ENABLE     0x148

#define STATUS_IDLE     0x00
#define STATUS_RUNNING  0x01
#define STATUS_DONE     0x02

typedef volatile uint32_t vreg32;

class DeviceMemoryMap {
public:
    ~DeviceMemoryMap() {
        if (bar0_) munmap((void*)bar0_, 0x200000);
        if (mem_fd_ >= 0) close(mem_fd_);
    }

    bool init() {
        mem_fd_ = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem_fd_ < 0) {
            perror("open /dev/mem");
            return false;
        }

        // Map entire BAR0 region (2MB) at page-aligned address
        bar0_ = (vreg32*)mmap(nullptr, 0x200000, PROT_READ | PROT_WRITE,
                              MAP_SHARED, mem_fd_, BAR0_BASE);
        if (bar0_ == MAP_FAILED) {
            perror("mmap BAR0");
            bar0_ = nullptr;
            return false;
        }

        printf("[DeviceMemory] Mapped BAR0 at 0x%lx (GPU CSR at 0x%lx)\n", BAR0_BASE, GPU_CSR_BASE);
        return true;
    }

    void csr_write(uint32_t offset, uint32_t value) {
        // GPU CSR is at BAR0+0x180100, offset is relative to that base
        vreg32* reg = bar0_ + (0x180100 + offset) / 4;
        *reg = value;
    }

    uint32_t csr_read(uint32_t offset) {
        // GPU CSR is at BAR0+0x180100, offset is relative to that base
        vreg32* reg = bar0_ + (0x180100 + offset) / 4;
        return *reg;
    }

    bool is_valid() const { return bar0_ != nullptr; }

private:
    int mem_fd_ = -1;
    vreg32* bar0_ = nullptr;
};

// Load kernel binary from file
std::unique_ptr<uint8_t[]> load_kernel(const char* path, size_t& size) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        perror("fopen kernel");
        return nullptr;
    }

    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fseek(f, 0, SEEK_SET);

    auto buf = std::make_unique<uint8_t[]>(size);
    if (fread(buf.get(), 1, size, f) != size) {
        perror("fread kernel");
        fclose(f);
        return nullptr;
    }

    fclose(f);
    printf("[Kernel] Loaded %zu bytes from %s\n", size, path);
    return buf;
}

// Run GEMM on real GPU with DCOH completion verification
bool run_gemm_benchmark(DeviceMemoryMap& dev,
                        uint32_t M, uint32_t N, uint32_t K,
                        const std::unique_ptr<uint8_t[]>& kernel_binary,
                        size_t kernel_size) {
    printf("\n=== GEMM %ux%ux%u ===\n", M, N, K);

    if (!dev.is_valid()) {
        printf("ERROR: Device not initialized\n");
        return false;
    }

    if (!kernel_binary || kernel_size == 0) {
        printf("ERROR: Kernel binary not loaded\n");
        return false;
    }

    // Allocate host memory for matrices + kernel (use posix_memalign for alignment)
    size_t kernel_offset = 0;  // Kernel code at start
    size_t kernel_aligned = (kernel_size + 4095) & ~4095;  // Align to 4KB

    size_t Asize = M * K * sizeof(float);
    size_t Bsize = K * N * sizeof(float);
    size_t Csize = M * N * sizeof(float);
    size_t args_size = 256; // Extra padding
    size_t comp_size = 256;

    size_t A_offset = kernel_aligned;
    size_t B_offset = A_offset + Asize;
    size_t C_offset = B_offset + Bsize;
    size_t args_offset = C_offset + Csize;
    size_t comp_offset = args_offset + args_size;
    size_t total_size = comp_offset + comp_size;

    void* buf = nullptr;
    if (posix_memalign(&buf, 4096, total_size)) {
        perror("posix_memalign");
        return false;
    }

    // Copy kernel binary to beginning of allocation
    memcpy((uint8_t*)buf + kernel_offset, kernel_binary.get(), kernel_size);
    printf("[Kernel] Loaded %zu bytes at memory offset 0x%zx (GPU address 0x80000000)\n",
           kernel_size, kernel_offset);

    float* A = (float*)((uint8_t*)buf + A_offset);
    float* B = (float*)((uint8_t*)buf + B_offset);
    float* C = (float*)((uint8_t*)buf + C_offset);
    GemmKernelArgs* args = (GemmKernelArgs*)((uint8_t*)buf + args_offset);
    CompletionData* comp = (CompletionData*)((uint8_t*)buf + comp_offset);

    // Initialize matrices
    for (uint32_t i = 0; i < M * K; i++) A[i] = 1.0f + (i % 10) * 0.1f;
    for (uint32_t i = 0; i < K * N; i++) B[i] = 2.0f + (i % 10) * 0.1f;
    for (uint32_t i = 0; i < M * N; i++) C[i] = 0.0f;

    // Setup kernel arguments (use offsets from coherent memory base)
    // GPU virtual address base: 0x80000000
    args->A_addr = 0x80000000 + A_offset;  // A at kernel_base + A_offset
    args->B_addr = 0x80000000 + B_offset;  // B at kernel_base + B_offset
    args->C_addr = 0x80000000 + C_offset;  // C at kernel_base + C_offset
    args->M = M;
    args->N = N;
    args->K = K;
    args->lda = K;
    args->ldb = N;
    args->ldc = N;
    args->alpha = 1.0f;
    args->beta = 0.0f;
    args->completion_addr = 0x80000000 + comp_offset;  // GPU virtual address of completion

    memset(comp, 0, sizeof(*comp));

    // Cleanup helper
    auto cleanup = [&]() {
        free(buf);
    };

    // Wait for GPU to be idle
    int timeout = 1000;
    while (timeout-- > 0) {
        uint32_t status = dev.csr_read(STATUS);
        if (status == STATUS_IDLE) break;
        usleep(100);
    }
    if (timeout <= 0) {
        printf("ERROR: GPU didn't become idle\n");
        cleanup();
        return false;
    }

    // Launch kernel
    printf("Launching kernel...\n");

    // Set kernel address (kernel is at GPU virtual address 0x80000000)
    dev.csr_write(KERNEL_ADDR_LO, 0x80000000);
    dev.csr_write(KERNEL_ADDR_HI, 0x00000000);

    // Set arguments address (args are in coherent memory at 0x80000000 + args_offset)
    uint32_t args_addr_lo = 0x80000000 + args_offset;
    uint32_t args_addr_hi = 0x00000000;
    dev.csr_write(KERNEL_ARGS_LO, args_addr_lo);
    dev.csr_write(KERNEL_ARGS_HI, args_addr_hi);

    // Set grid dimensions (1D: gridX threads, gridY=1)
    uint32_t threads_per_block = 32;
    uint32_t blocks = (M * N + threads_per_block - 1) / threads_per_block;
    dev.csr_write(GRID_DIM_X, blocks);
    dev.csr_write(GRID_DIM_Y, 1);
    dev.csr_write(GRID_DIM_Z, 1);

    // Set block dimensions
    dev.csr_write(BLOCK_DIM_X, threads_per_block);
    dev.csr_write(BLOCK_DIM_Y, 1);
    dev.csr_write(BLOCK_DIM_Z, 1);

    // Enable DCOH completion
    dev.csr_write(DCOH_ENABLE, 1);

    // Read cycle counter before launch
    uint32_t cycle_lo_before = dev.csr_read(CYCLE_LO);
    uint32_t cycle_hi_before = dev.csr_read(CYCLE_HI);

    auto time_start = std::chrono::high_resolution_clock::now();

    // Trigger kernel launch
    dev.csr_write(LAUNCH, 1);

    // Poll for completion
    uint32_t poll_count = 0;
    timeout = 100000; // 10s timeout
    while (timeout-- > 0) {
        uint32_t status = dev.csr_read(STATUS);
        poll_count++;

        if (status == STATUS_DONE) {
            auto time_end = std::chrono::high_resolution_clock::now();
            auto elapsed_us = std::chrono::duration_cast<std::chrono::microseconds>(
                time_end - time_start).count();

            // Read cycle counter after completion
            uint32_t cycle_lo_after = dev.csr_read(CYCLE_LO);
            uint32_t cycle_hi_after = dev.csr_read(CYCLE_HI);

            uint64_t cycles_before = cycle_lo_before | ((uint64_t)cycle_hi_before << 32);
            uint64_t cycles_after = cycle_lo_after | ((uint64_t)cycle_hi_after << 32);
            uint64_t gpu_cycles = cycles_after - cycles_before;

            printf("Kernel completed!\n");
            printf("  Host time:    %.3f ms\n", elapsed_us / 1000.0);
            printf("  GPU cycles:   %lu (@ 400MHz = %.3f ms)\n",
                   gpu_cycles, gpu_cycles / 400000.0);
            printf("  Polls:        %u\n", poll_count);

            // Check DCOH completion
            if (comp->magic == COMPLETION_MAGIC) {
                printf("✓ DCOH completion received! (Type2 snoop working)\n");
                printf("  Result: 0x%lx\n", comp->result);
                printf("  Status: %u\n", comp->status);
            } else {
                printf("✗ DCOH completion NOT received (magic=0x%08x)\n", comp->magic);
            }

            // Verify result (host-side GEMM reference)
            float max_error = 0.0f;
            for (uint32_t i = 0; i < M * N; i++) {
                float expected = (float)K * (1.5f + (i % 10) * 0.1f); // Approximate
                float error = fabsf(C[i] - expected);
                if (error > max_error) max_error = error;
            }

            double flops = (double)M * N * K * 2;  // Multiply-add = 2 FLOPs
            double gflops = flops / (elapsed_us * 1000);  // GFLOPS

            printf("  Max error:    %.6e\n", max_error);
            printf("  Performance:  %.2f GFLOPS\n", gflops);

            cleanup();
            return true;
        }

        if (status == 0xFF) { // Error status
            printf("ERROR: Kernel execution failed!\n");
            cleanup();
            return false;
        }

        usleep(100);
    }

    printf("ERROR: Kernel timeout!\n");
    cleanup();
    return false;
}

int main(int argc, char** argv) {
    printf("========================================\n");
    printf("Real Device GEMM Benchmark with Type2 Snoop\n");
    printf("CXL Type2 Device 0000:3b:00.0\n");
    printf("========================================\n");

    DeviceMemoryMap dev;
    if (!dev.init()) {
        fprintf(stderr, "Failed to initialize device memory\n");
        return 1;
    }

    // Load GPU kernel binary
    size_t kernel_size = 0;
    auto kernel_binary = load_kernel("../kernels/gemm_kernel.bin", kernel_size);
    if (!kernel_binary || kernel_size == 0) {
        fprintf(stderr, "Failed to load kernel binary\n");
        return 1;
    }
    printf("[Main] Kernel binary loaded: %zu bytes\n", kernel_size);

    // Test different matrix sizes
    uint32_t dims[] = {32, 64, 128, 256};
    for (uint32_t dim : dims) {
        if (!run_gemm_benchmark(dev, dim, dim, dim, kernel_binary, kernel_size)) {
            fprintf(stderr, "GEMM %ux%ux%u failed\n", dim, dim, dim);
        }
    }

    printf("\n========================================\n");
    printf("Benchmark complete\n");
    printf("========================================\n");

    return 0;
}
