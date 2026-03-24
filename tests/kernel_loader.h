/**
 * kernel_loader.h
 *
 * Utility for loading GPU kernel binaries into instruction memory.
 * Supports loading RISC-V kernel binaries from disk and programming
 * them into GPU memory via multiple mechanisms.
 */

#ifndef KERNEL_LOADER_H
#define KERNEL_LOADER_H

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <memory>
#include <string>
#include <vector>

// ============================================================================
// Kernel Memory Configuration
// ============================================================================

// GPU instruction memory base address (as seen by CPU via BAR0)
#define GPU_KERNEL_MEM_BASE   0x80000000UL

// GPU CSR base address in BAR0
#define GPU_CSR_BASE          0x180100

// GPU CSR register offsets
#define GPU_CSR_KERNEL_ADDR_LO  0x100
#define GPU_CSR_KERNEL_ADDR_HI  0x104
#define GPU_CSR_KERNEL_ARGS_LO  0x108
#define GPU_CSR_KERNEL_ARGS_HI  0x10C
#define GPU_CSR_GRID_DIM_X      0x110
#define GPU_CSR_STATUS          0x12C

// ============================================================================
// Kernel Loader Class
// ============================================================================

class KernelLoader {
public:
    /**
     * Constructor - initializes kernel loader
     * @param bar0_base Physical address of BAR0 (typically 0xa2800000)
     */
    explicit KernelLoader(uint64_t bar0_base = 0xa2800000UL);

    ~KernelLoader();

    /**
     * Load kernel binary from file into GPU memory
     * @param filename Path to kernel binary file (e.g., "kernels/gemm_kernel.bin")
     * @param kernel_addr GPU memory address to load kernel to (default 0x80000000)
     * @return true if load successful, false otherwise
     */
    bool load_kernel(const char* filename, uint64_t kernel_addr = GPU_KERNEL_MEM_BASE);

    /**
     * Load kernel binary from memory buffer
     * @param data Pointer to kernel binary data
     * @param size Size of kernel binary in bytes
     * @param kernel_addr GPU memory address to load kernel to
     * @return true if load successful, false otherwise
     */
    bool load_kernel_from_buffer(const uint8_t* data, size_t size,
                                 uint64_t kernel_addr = GPU_KERNEL_MEM_BASE);

    /**
     * Read kernel binary file into buffer
     * @param filename Path to kernel binary
     * @param buffer Output buffer (allocated by this function)
     * @return Size of kernel, 0 on error
     */
    static size_t read_kernel_file(const char* filename, std::unique_ptr<uint8_t[]>& buffer);

    /**
     * Verify kernel was loaded correctly
     * @param kernel_addr Address kernel was loaded to
     * @param expected_data Pointer to expected kernel data
     * @param size Size to verify
     * @return true if loaded kernel matches expected data
     */
    bool verify_kernel(uint64_t kernel_addr, const uint8_t* expected_data, size_t size);

    /**
     * Set kernel entry point in GPU CSR
     * @param kernel_addr Address of kernel entry point
     * @return true if CSR write successful
     */
    bool set_kernel_entry_point(uint64_t kernel_addr);

    /**
     * Set kernel arguments pointer
     * @param args_addr Physical address of kernel arguments structure
     * @return true if CSR write successful
     */
    bool set_kernel_args(uint64_t args_addr);

    /**
     * Set grid and block dimensions
     * @param grid_x Number of blocks in X dimension
     * @param grid_y Number of blocks in Y dimension
     * @param grid_z Number of blocks in Z dimension
     * @param block_x Threads per block in X
     * @param block_y Threads per block in Y
     * @param block_z Threads per block in Z
     * @return true if all CSR writes successful
     */
    bool set_grid_block_dims(uint32_t grid_x, uint32_t grid_y, uint32_t grid_z,
                             uint32_t block_x, uint32_t block_y, uint32_t block_z);

    /**
     * Get kernel size (from last load)
     * @return Size in bytes, 0 if not loaded
     */
    size_t get_kernel_size() const { return kernel_size_; }

    /**
     * Get kernel entry point address
     * @return Address, GPU_KERNEL_MEM_BASE if not set
     */
    uint64_t get_kernel_entry_point() const { return kernel_entry_point_; }

    /**
     * Print kernel information
     */
    void print_info() const;

    /**
     * Dump kernel memory for debugging
     * @param kernel_addr Address to dump from
     * @param num_bytes Number of bytes to dump
     */
    void dump_kernel_memory(uint64_t kernel_addr, size_t num_bytes = 256);

    /**
     * Map BAR0 memory (can be called explicitly for re-initialization)
     * @return true if mapping successful
     */
    bool map_bar0_memory();

private:
    uint64_t bar0_base_;
    volatile uint32_t* bar0_ptr_;
    size_t kernel_size_;
    uint64_t kernel_entry_point_;
    bool memory_mapped_;

    // Helper methods
    void unmap_bar0_memory();

    uint32_t read_csr(uint32_t offset);
    void write_csr(uint32_t offset, uint32_t value);

    void write_kernel_memory(uint64_t addr, const uint8_t* data, size_t size);
    void read_kernel_memory(uint64_t addr, uint8_t* buffer, size_t size);

    bool verify_memory_access();
};

#endif // KERNEL_LOADER_H
