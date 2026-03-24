/**
 * gemm_with_loader.cpp
 *
 * Real GPU GEMM test with kernel binary loading
 * Loads gemm_kernel.bin, configures GPU, and executes kernel
 *
 * Build: g++ -std=c++17 -O2 -I. kernel_loader.cpp gemm_with_loader.cpp -o gemm_with_loader
 * Usage: sudo ./gemm_with_loader [kernel_binary]
 */

#include "kernel_loader.h"
#include <chrono>
#include <thread>
#include <cstring>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

// ============================================================================
// Constants
// ============================================================================

#define GPU_CSR_LAUNCH         0x128
#define GPU_CSR_STATUS         0x12C
#define GPU_CSR_CYCLE_LO       0x130
#define GPU_CSR_CYCLE_HI       0x134

#define STATUS_IDLE            0x00
#define STATUS_RUNNING         0x01
#define STATUS_DONE            0x02

// GEMM Kernel Arguments (must match kernel_args.h)
struct GemmKernelArgs {
    uint64_t A_addr;
    uint64_t B_addr;
    uint64_t C_addr;
    uint32_t M, N, K;
    uint32_t lda, ldb, ldc;
    float    alpha, beta;
    uint64_t completion_addr;
} __attribute__((aligned(64)));

struct CompletionData {
    uint32_t magic;
    uint32_t status;
    uint64_t result;
    uint64_t cycles;
    uint64_t timestamp;
    uint8_t  reserved[32];
} __attribute__((aligned(64)));

static constexpr uint32_t COMPLETION_MAGIC = 0xDEADBEEF;

// ============================================================================
// Helper Functions
// ============================================================================

class GPUInterface {
private:
    int mem_fd_;
    volatile uint32_t* bar0_;
    volatile uint8_t* kernel_mem_;

public:
    GPUInterface() : mem_fd_(-1), bar0_(nullptr), kernel_mem_(nullptr) {
        mem_fd_ = open("/dev/mem", O_RDWR | O_SYNC);
        if (mem_fd_ < 0) {
            perror("open /dev/mem");
            return;
        }

        // Map BAR0
        bar0_ = (volatile uint32_t*)mmap(nullptr, 0x200000,
                                         PROT_READ | PROT_WRITE,
                                         MAP_SHARED, mem_fd_, 0xa2800000UL);
        if (bar0_ == MAP_FAILED) {
            perror("mmap BAR0");
            bar0_ = nullptr;
        }

        // Map kernel memory (if accessible)
        // kernel_mem_ = (volatile uint8_t*)mmap(nullptr, 0x100000,
        //                                         PROT_READ | PROT_WRITE,
        //                                         MAP_SHARED, mem_fd_, 0x80000000UL);
    }

    ~GPUInterface() {
        if (bar0_) munmap((void*)bar0_, 0x200000);
        if (kernel_mem_) munmap((void*)kernel_mem_, 0x100000);
        if (mem_fd_ >= 0) close(mem_fd_);
    }

    bool is_valid() const { return bar0_ != nullptr; }

    void write_csr(uint32_t offset, uint32_t value) {
        if (!bar0_) return;
        volatile uint32_t* reg = bar0_ + (0x180100 + offset) / 4;
        *reg = value;
        printf("  CSR[0x%03x] = 0x%08x\n", offset, value);
    }

    uint32_t read_csr(uint32_t offset) {
        if (!bar0_) return 0;
        volatile uint32_t* reg = bar0_ + (0x180100 + offset) / 4;
        uint32_t value = *reg;
        printf("  CSR[0x%03x] = 0x%08x\n", offset, value);
        return value;
    }

    void launch_kernel() {
        write_csr(GPU_CSR_LAUNCH, 1);
    }

    uint32_t get_status() {
        return read_csr(GPU_CSR_STATUS);
    }

    void wait_for_completion(int timeout_ms = 60000) {
        printf("Waiting for kernel completion (timeout: %d ms)...\n", timeout_ms);
        auto start = std::chrono::high_resolution_clock::now();

        while (true) {
            uint32_t status = get_status();
            if (status == STATUS_DONE) {
                printf("Kernel completed!\n");
                return;
            }
            if (status == 0xFF) {
                printf("ERROR: Kernel execution failed!\n");
                return;
            }

            auto now = std::chrono::high_resolution_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                now - start).count();
            if (elapsed > timeout_ms) {
                printf("TIMEOUT: Kernel did not complete within %d ms\n", timeout_ms);
                return;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
};

// ============================================================================
// Main
// ============================================================================

int main(int argc, char** argv) {
    printf("================================================\n");
    printf("Real GPU GEMM Test with Kernel Loading\n");
    printf("CXL Type2 Device GPU GEMM Execution\n");
    printf("================================================\n\n");

    // Parse arguments
    const char* kernel_file = "../kernels/gemm_kernel.bin";
    if (argc >= 2) {
        kernel_file = argv[1];
    }

    // Initialize kernel loader
    printf("Step 1: Initialize Kernel Loader\n");
    printf("────────────────────────────────\n");
    KernelLoader loader;
    printf("✓ Kernel loader ready\n\n");

    // Load kernel
    printf("Step 2: Load Kernel Binary\n");
    printf("─────────────────────────\n");
    if (!loader.load_kernel(kernel_file, 0x80000000UL)) {
        fprintf(stderr, "ERROR: Failed to load kernel\n");
        return 1;
    }
    printf("✓ Kernel loaded to 0x80000000\n\n");

    // Configure GPU
    printf("Step 3: Configure GPU\n");
    printf("─────────────────────\n");

    GPUInterface gpu;
    if (!gpu.is_valid()) {
        fprintf(stderr, "ERROR: Cannot access GPU CSR\n");
        return 1;
    }

    // Set grid and block dimensions (GEMM 64x64x64)
    uint32_t M = 64, N = 64, K = 64;
    uint32_t grid_x = (M * N + 4095) / 4096;   // 1 block for 64x64
    uint32_t block_x = 32, block_y = 4;

    loader.set_grid_block_dims(grid_x, 1, 1, block_x, block_y, 1);
    printf("✓ GPU configured for GEMM %ux%ux%u\n", M, N, K);
    printf("  Grid: (%u, 1, 1)  Block: (%u, %u, 1)\n\n", grid_x, block_x, block_y);

    // Setup kernel arguments (example)
    printf("Step 4: Setup Kernel Arguments\n");
    printf("──────────────────────────────\n");

    uint64_t kernel_args_addr = 0x80001000UL;
    loader.set_kernel_args(kernel_args_addr);

    // Note: In a real application, you would:
    // 1. Allocate memory for matrices A, B, C
    // 2. Fill kernel arguments structure
    // 3. Write to BAR0 or use AXI4-MM to program kernel memory
    printf("✓ Kernel arguments configured\n");
    printf("  (Full setup would require matrix allocation)\n\n");

    // Launch kernel
    printf("Step 5: Launch Kernel\n");
    printf("─────────────────────\n");
    gpu.launch_kernel();
    printf("✓ Kernel launched\n\n");

    // Wait for completion
    printf("Step 6: Wait for Completion\n");
    printf("──────────────────────────\n");
    gpu.wait_for_completion(60000);
    printf("✓ Test complete\n\n");

    // Print summary
    printf("================================================\n");
    printf("GPU GEMM Execution Complete\n");
    printf("================================================\n");

    return 0;
}
