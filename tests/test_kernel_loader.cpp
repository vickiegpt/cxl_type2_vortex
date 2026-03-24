/**
 * test_kernel_loader.cpp
 *
 * Test program demonstrating kernel loader usage
 * Loads gemm_kernel.bin and prepares GPU for kernel execution
 *
 * Build: g++ -std=c++17 -O2 -I. kernel_loader.cpp test_kernel_loader.cpp -o test_kernel_loader
 * Usage: sudo ./test_kernel_loader [kernel.bin]
 */

#include "kernel_loader.h"
#include <chrono>
#include <thread>

// ============================================================================
// Helper Functions
// ============================================================================

void print_gpu_status() {
    // Note: This would require BAR0 mapping to read CSR registers
    // For now, just informational
    printf("\n GPU Status:\n");
    printf("  (CSR registers readable after kernel_loader init)\n\n");
}

void print_usage(const char* progname) {
    printf("Usage: %s [kernel_binary] [kernel_addr]\n", progname);
    printf("\n");
    printf("Arguments:\n");
    printf("  kernel_binary  Path to kernel binary (default: ../kernels/gemm_kernel.bin)\n");
    printf("  kernel_addr    Load address in hex (default: 0x80000000)\n");
    printf("\n");
    printf("Example:\n");
    printf("  sudo %s ../kernels/gemm_kernel.bin 0x80000000\n", progname);
    printf("  sudo %s ../kernels/gemm_kernel.bin\n", progname);
    printf("\n");
}

// ============================================================================
// Main
// ============================================================================

int main(int argc, char** argv) {
    printf("================================================\n");
    printf("GPU Kernel Loader Test\n");
    printf("CXL Type2 Device Kernel Binary Loading\n");
    printf("================================================\n\n");

    // Parse arguments
    const char* kernel_file = "../kernels/gemm_kernel.bin";
    uint64_t kernel_addr = 0x80000000UL;

    if (argc < 2) {
        printf("Using default kernel file: %s\n", kernel_file);
        printf("Using default load address: 0x%lx\n\n", kernel_addr);
    } else {
        kernel_file = argv[1];
        if (argc >= 3) {
            kernel_addr = strtoull(argv[2], nullptr, 16);
        }
    }

    if (argc > 3) {
        print_usage(argv[0]);
        return 1;
    }

    // Step 1: Initialize kernel loader
    printf("Step 1: Initializing Kernel Loader\n");
    printf("────────────────────────────────────\n");

    KernelLoader loader;
    if (!loader.map_bar0_memory()) {
        fprintf(stderr, "ERROR: Failed to initialize kernel loader\n");
        fprintf(stderr, "       Must run as root: sudo %s\n", argv[0]);
        return 1;
    }
    printf("✓ Kernel loader initialized\n\n");

    // Step 2: Read kernel file
    printf("Step 2: Loading Kernel Binary\n");
    printf("────────────────────────────\n");
    printf("Kernel file: %s\n", kernel_file);
    printf("Load address: 0x%lx\n\n", kernel_addr);

    if (!loader.load_kernel(kernel_file, kernel_addr)) {
        fprintf(stderr, "ERROR: Failed to load kernel\n");
        return 1;
    }
    printf("✓ Kernel loaded\n\n");

    // Step 3: Configure grid and block dimensions
    printf("Step 3: Configuring Grid and Block Dimensions\n");
    printf("──────────────────────────────────────────────\n");

    uint32_t grid_x = 8, grid_y = 16, grid_z = 1;
    uint32_t block_x = 32, block_y = 4, block_z = 1;

    if (!loader.set_grid_block_dims(grid_x, grid_y, grid_z, block_x, block_y, block_z)) {
        fprintf(stderr, "ERROR: Failed to set grid/block dimensions\n");
        return 1;
    }
    printf("✓ Grid and block dimensions configured\n\n");

    // Step 4: Set kernel arguments (example)
    printf("Step 4: Setting Kernel Arguments\n");
    printf("───────────────────────────────\n");

    uint64_t kernel_args_addr = 0x80001000UL;  // Example args location
    if (!loader.set_kernel_args(kernel_args_addr)) {
        fprintf(stderr, "ERROR: Failed to set kernel arguments\n");
        return 1;
    }
    printf("✓ Kernel arguments set\n\n");

    // Step 5: Print summary
    printf("Step 5: Summary\n");
    printf("───────────────\n");
    loader.print_info();

    printf("Kernel is now ready for launch!\n\n");
    printf("Next steps:\n");
    printf("  1. Write kernel arguments to 0x%lx\n", kernel_args_addr);
    printf("  2. Write launch trigger to GPU CSR 0x128\n");
    printf("  3. Poll GPU CSR 0x12C for completion status\n");
    printf("  4. Read results from kernel arguments location\n\n");

    // Step 6: Optional - verify kernel was loaded
    printf("Step 6: Verification\n");
    printf("─────────────────────\n");
    printf("To verify kernel was loaded, you can:\n");
    printf("  - Use kernel_loader.verify_kernel() in your test\n");
    printf("  - Read GPU CSR registers to check configuration\n");
    printf("  - Check GPU memory via AXI4-MM port (if available)\n\n");

    printf("================================================\n");
    printf("Kernel Loading Complete\n");
    printf("================================================\n");

    return 0;
}
