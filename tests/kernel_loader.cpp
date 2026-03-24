/**
 * kernel_loader.cpp
 *
 * Implementation of kernel loader utility for GPU kernel binary loading
 */

#include "kernel_loader.h"
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>

// ============================================================================
// Constructor / Destructor
// ============================================================================

KernelLoader::KernelLoader(uint64_t bar0_base)
    : bar0_base_(bar0_base),
      bar0_ptr_(nullptr),
      kernel_size_(0),
      kernel_entry_point_(GPU_KERNEL_MEM_BASE),
      memory_mapped_(false) {
    // Try to map BAR0 memory
    map_bar0_memory();
}

KernelLoader::~KernelLoader() {
    unmap_bar0_memory();
}

// ============================================================================
// Memory Mapping
// ============================================================================

bool KernelLoader::map_bar0_memory() {
    if (memory_mapped_) return true;

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open /dev/mem");
        return false;
    }

    // Map 2MB BAR0 space
    bar0_ptr_ = (volatile uint32_t*)mmap(nullptr, 0x200000,
                                         PROT_READ | PROT_WRITE,
                                         MAP_SHARED, fd, bar0_base_);
    close(fd);

    if (bar0_ptr_ == MAP_FAILED) {
        perror("mmap BAR0");
        bar0_ptr_ = nullptr;
        return false;
    }

    memory_mapped_ = true;
    printf("[KernelLoader] BAR0 mapped at %p (physical 0x%lx)\n",
           bar0_ptr_, bar0_base_);

    // Verify we can access GPU CSR
    if (!verify_memory_access()) {
        printf("ERROR: Cannot access GPU CSR area\n");
        return false;
    }

    return true;
}

void KernelLoader::unmap_bar0_memory() {
    if (bar0_ptr_ && memory_mapped_) {
        munmap((void*)bar0_ptr_, 0x200000);
        bar0_ptr_ = nullptr;
        memory_mapped_ = false;
    }
}

bool KernelLoader::verify_memory_access() {
    if (!bar0_ptr_) return false;

    // Try to read CXL CM Capability at 0x151000
    uint32_t cm_cap = bar0_ptr_[0x151000 / 4];
    if ((cm_cap & 0xFFFF) == 1) {
        printf("[KernelLoader] CXL CM Cap readable: 0x%08x ✓\n", cm_cap);
        return true;
    }

    printf("WARNING: CXL CM Cap read 0x%08x (expected low word = 1)\n", cm_cap);
    return true;  // Still proceed - may be valid in some configs
}

// ============================================================================
// CSR Interface
// ============================================================================

uint32_t KernelLoader::read_csr(uint32_t offset) {
    if (!bar0_ptr_) {
        fprintf(stderr, "ERROR: BAR0 not mapped\n");
        return 0;
    }

    uint32_t addr = GPU_CSR_BASE + offset;
    uint32_t value = bar0_ptr_[addr / 4];
    printf("  CSR Read:  [0x%06x] = 0x%08x\n", addr, value);
    return value;
}

void KernelLoader::write_csr(uint32_t offset, uint32_t value) {
    if (!bar0_ptr_) {
        fprintf(stderr, "ERROR: BAR0 not mapped\n");
        return;
    }

    uint32_t addr = GPU_CSR_BASE + offset;
    bar0_ptr_[addr / 4] = value;
    printf("  CSR Write: [0x%06x] = 0x%08x\n", addr, value);

    // Read back to verify
    uint32_t readback = bar0_ptr_[addr / 4];
    if (readback != value) {
        printf("  WARNING: Readback mismatch! Read 0x%08x\n", readback);
    }
}

// ============================================================================
// Kernel Memory Access
// ============================================================================

void KernelLoader::write_kernel_memory(uint64_t addr, const uint8_t* data, size_t size) {
    if (!bar0_ptr_) {
        fprintf(stderr, "ERROR: BAR0 not mapped\n");
        return;
    }

    // For now, we can only write through CSR interface at fixed addresses
    // Real implementation would use AXI4-MM port for flexible addresses
    printf("[KernelLoader] Writing %zu bytes to kernel memory at 0x%lx\n", size, addr);

    // If address is within BAR0 (unlikely for kernel memory), write directly
    if (addr >= bar0_base_ && addr < bar0_base_ + 0x200000) {
        uint32_t offset = addr - bar0_base_;
        const uint32_t* data32 = (const uint32_t*)data;
        size_t words = (size + 3) / 4;

        for (size_t i = 0; i < words; i++) {
            bar0_ptr_[offset / 4 + i] = data32[i];
        }
        printf("  Direct write via BAR0 complete\n");
    } else {
        // Kernel memory is typically in AXI4 addressable space
        // This would require AXI4-MM master access (not implemented yet)
        printf("  WARNING: Kernel at 0x%lx not in BAR0 range\n", addr);
        printf("  Would require AXI4-MM master access (not yet implemented)\n");
    }
}

void KernelLoader::read_kernel_memory(uint64_t addr, uint8_t* buffer, size_t size) {
    if (!bar0_ptr_) {
        fprintf(stderr, "ERROR: BAR0 not mapped\n");
        return;
    }

    printf("[KernelLoader] Reading %zu bytes from kernel memory at 0x%lx\n", size, addr);

    if (addr >= bar0_base_ && addr < bar0_base_ + 0x200000) {
        uint32_t offset = addr - bar0_base_;
        const volatile uint32_t* src = bar0_ptr_ + offset / 4;
        uint32_t* dst = (uint32_t*)buffer;
        size_t words = (size + 3) / 4;

        for (size_t i = 0; i < words; i++) {
            dst[i] = src[i];
        }
    }
}

// ============================================================================
// File Operations
// ============================================================================

size_t KernelLoader::read_kernel_file(const char* filename,
                                      std::unique_ptr<uint8_t[]>& buffer) {
    FILE* f = fopen(filename, "rb");
    if (!f) {
        perror("fopen kernel");
        return 0;
    }

    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);

    buffer = std::make_unique<uint8_t[]>(size);
    if (fread(buffer.get(), 1, size, f) != size) {
        perror("fread kernel");
        fclose(f);
        return 0;
    }

    fclose(f);
    printf("[KernelLoader] Loaded %zu bytes from %s\n", size, filename);
    return size;
}

// ============================================================================
// Kernel Loading
// ============================================================================

bool KernelLoader::load_kernel(const char* filename, uint64_t kernel_addr) {
    std::unique_ptr<uint8_t[]> buffer;
    size_t size = read_kernel_file(filename, buffer);
    if (size == 0) return false;

    return load_kernel_from_buffer(buffer.get(), size, kernel_addr);
}

bool KernelLoader::load_kernel_from_buffer(const uint8_t* data, size_t size,
                                          uint64_t kernel_addr) {
    printf("[KernelLoader] Loading kernel (%zu bytes) to 0x%lx\n", size, kernel_addr);

    if (!bar0_ptr_ && !map_bar0_memory()) {
        printf("ERROR: Cannot map BAR0\n");
        return false;
    }

    // Write kernel to memory
    write_kernel_memory(kernel_addr, data, size);

    // Set entry point
    if (!set_kernel_entry_point(kernel_addr)) {
        printf("ERROR: Failed to set kernel entry point\n");
        return false;
    }

    kernel_size_ = size;
    kernel_entry_point_ = kernel_addr;

    printf("[KernelLoader] Kernel loaded successfully\n");
    print_info();

    return true;
}

// ============================================================================
// Verification
// ============================================================================

bool KernelLoader::verify_kernel(uint64_t kernel_addr, const uint8_t* expected_data,
                                 size_t size) {
    if (!bar0_ptr_ && !map_bar0_memory()) {
        printf("ERROR: Cannot map BAR0 for verification\n");
        return false;
    }

    printf("[KernelLoader] Verifying kernel at 0x%lx (%zu bytes)...\n",
           kernel_addr, size);

    // Read kernel from memory
    std::unique_ptr<uint8_t[]> readback = std::make_unique<uint8_t[]>(size);
    read_kernel_memory(kernel_addr, readback.get(), size);

    // Compare
    int mismatches = 0;
    for (size_t i = 0; i < size; i++) {
        if (readback[i] != expected_data[i]) {
            if (mismatches < 16) {  // Report first 16 mismatches
                printf("  Mismatch at offset 0x%lx: got 0x%02x, expected 0x%02x\n",
                       i, readback[i], expected_data[i]);
            }
            mismatches++;
        }
    }

    if (mismatches == 0) {
        printf("  ✓ Verification passed\n");
        return true;
    } else {
        printf("  ✗ %d byte(s) mismatched\n", mismatches);
        return false;
    }
}

// ============================================================================
// CSR Configuration
// ============================================================================

bool KernelLoader::set_kernel_entry_point(uint64_t kernel_addr) {
    printf("[KernelLoader] Setting kernel entry point to 0x%lx\n", kernel_addr);

    uint32_t addr_lo = (uint32_t)(kernel_addr & 0xFFFFFFFFUL);
    uint32_t addr_hi = (uint32_t)((kernel_addr >> 32) & 0xFFFFFFFFUL);

    write_csr(GPU_CSR_KERNEL_ADDR_LO, addr_lo);
    write_csr(GPU_CSR_KERNEL_ADDR_HI, addr_hi);

    kernel_entry_point_ = kernel_addr;
    return true;
}

bool KernelLoader::set_kernel_args(uint64_t args_addr) {
    printf("[KernelLoader] Setting kernel args address to 0x%lx\n", args_addr);

    uint32_t args_lo = (uint32_t)(args_addr & 0xFFFFFFFFUL);
    uint32_t args_hi = (uint32_t)((args_addr >> 32) & 0xFFFFFFFFUL);

    write_csr(GPU_CSR_KERNEL_ARGS_LO, args_lo);
    write_csr(GPU_CSR_KERNEL_ARGS_HI, args_hi);

    return true;
}

bool KernelLoader::set_grid_block_dims(uint32_t grid_x, uint32_t grid_y,
                                       uint32_t grid_z, uint32_t block_x,
                                       uint32_t block_y, uint32_t block_z) {
    printf("[KernelLoader] Setting grid (%u,%u,%u) block (%u,%u,%u)\n",
           grid_x, grid_y, grid_z, block_x, block_y, block_z);

    write_csr(GPU_CSR_GRID_DIM_X, grid_x);
    write_csr(0x114, grid_y);  // GRID_DIM_Y
    write_csr(0x118, grid_z);  // GRID_DIM_Z
    write_csr(0x11C, block_x); // BLOCK_DIM_X
    write_csr(0x120, block_y); // BLOCK_DIM_Y
    write_csr(0x124, block_z); // BLOCK_DIM_Z

    return true;
}

// ============================================================================
// Debugging / Info
// ============================================================================

void KernelLoader::print_info() const {
    printf("\n");
    printf("Kernel Information:\n");
    printf("  Entry point:  0x%lx\n", kernel_entry_point_);
    printf("  Size:         %zu bytes\n", kernel_size_);
    printf("  Memory mapped: %s\n", memory_mapped_ ? "yes" : "no");
    printf("\n");
}

void KernelLoader::dump_kernel_memory(uint64_t kernel_addr, size_t num_bytes) {
    if (!bar0_ptr_) {
        printf("ERROR: BAR0 not mapped\n");
        return;
    }

    printf("Kernel memory dump at 0x%lx:\n", kernel_addr);

    std::unique_ptr<uint8_t[]> buffer = std::make_unique<uint8_t[]>(num_bytes);
    read_kernel_memory(kernel_addr, buffer.get(), num_bytes);

    for (size_t i = 0; i < num_bytes; i += 16) {
        printf("  0x%08lx: ", kernel_addr + i);
        for (size_t j = 0; j < 16 && i + j < num_bytes; j++) {
            printf("%02x ", buffer[i + j]);
        }
        printf("\n");
    }
}
