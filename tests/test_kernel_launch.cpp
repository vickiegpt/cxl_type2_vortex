/**
 * test_kernel_launch.cpp
 * C++ Test for Vortex GPU Kernel Launch with DCOH Completion
 *
 * This test demonstrates:
 * 1. Configuring the Vortex GPU wrapper via CSR writes
 * 2. Launching a GPU kernel
 * 3. Waiting for completion using DCOH-based host memory polling (mwait-compatible)
 * 4. Reading kernel results from the completion structure
 *
 * The completion mechanism uses CXL.cache D2H (Device-to-Host) coherent writes
 * to ensure the host CPU can use monitor/mwait instructions for low-latency
 * notification of kernel completion.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <thread>

// For real hardware, these would be MMIO addresses
// For simulation, they're indices into the CSR space
namespace VortexCSR {
    // Base address for Vortex CSRs (within BAR0)
    constexpr uint32_t BASE = 0x100;

    // Configuration registers
    constexpr uint32_t KERNEL_ADDR_LO  = 0x100;  // Kernel entry point (low)
    constexpr uint32_t KERNEL_ADDR_HI  = 0x104;  // Kernel entry point (high)
    constexpr uint32_t KERNEL_ARGS_LO  = 0x108;  // Kernel args pointer (low)
    constexpr uint32_t KERNEL_ARGS_HI  = 0x10C;  // Kernel args pointer (high)
    constexpr uint32_t GRID_DIM_X      = 0x110;  // Grid dimension X
    constexpr uint32_t GRID_DIM_Y      = 0x114;  // Grid dimension Y
    constexpr uint32_t GRID_DIM_Z      = 0x118;  // Grid dimension Z
    constexpr uint32_t BLOCK_DIM_X     = 0x11C;  // Block dimension X
    constexpr uint32_t BLOCK_DIM_Y     = 0x120;  // Block dimension Y
    constexpr uint32_t BLOCK_DIM_Z     = 0x124;  // Block dimension Z
    constexpr uint32_t LAUNCH          = 0x128;  // Launch trigger (write 1)
    constexpr uint32_t STATUS          = 0x12C;  // Status register (read)
    constexpr uint32_t CYCLE_LO        = 0x130;  // Cycle counter (low)
    constexpr uint32_t CYCLE_HI        = 0x134;  // Cycle counter (high)
    constexpr uint32_t INSTR_LO        = 0x138;  // Instruction counter (low)
    constexpr uint32_t INSTR_HI        = 0x13C;  // Instruction counter (high)
    constexpr uint32_t COMPLETION_LO   = 0x140;  // Completion address (low)
    constexpr uint32_t COMPLETION_HI   = 0x144;  // Completion address (high)
    constexpr uint32_t DCOH_ENABLE     = 0x148;  // DCOH enable

    // Status values
    constexpr uint8_t STATUS_IDLE    = 0x00;
    constexpr uint8_t STATUS_RUNNING = 0x01;
    constexpr uint8_t STATUS_DONE    = 0x02;
    constexpr uint8_t STATUS_ERROR   = 0xFF;
}

/**
 * DCOH Completion Structure
 *
 * This structure is written by the device to host memory using
 * CXL.cache coherent writes (WrInv - Write Invalidate), which:
 * 1. Writes the data to host memory
 * 2. Invalidates any cached copies in host CPU caches
 * 3. Triggers a cache line invalidation that can wake up mwait
 *
 * The structure is 64 bytes (cache line aligned) for efficient
 * coherence operations.
 */
struct __attribute__((packed, aligned(64))) CompletionData {
    uint32_t magic;          // Magic number for validation (0xDEADBEEF)
    uint32_t status;         // Completion status (0 = success)
    uint64_t result;         // Result data from kernel
    uint64_t cycles;         // Cycle count at completion
    uint64_t timestamp;      // Timestamp
    uint8_t  reserved[32];   // Padding to 64 bytes
};

static_assert(sizeof(CompletionData) == 64, "CompletionData must be 64 bytes");

constexpr uint32_t COMPLETION_MAGIC = 0xDEADBEEF;

/**
 * VortexDevice - Interface to Vortex GPU CXL Type2 Device
 */
class VortexDevice {
public:
    // Simulated MMIO space
    uint32_t* csr_space;
    uint8_t*  host_memory;
    size_t    host_memory_size;

    VortexDevice(size_t mem_size = 1024 * 1024) {
        csr_space = new uint32_t[4096 / sizeof(uint32_t)]();
        host_memory_size = mem_size;
        host_memory = new uint8_t[mem_size]();
        printf("VortexDevice: Initialized with %zu bytes host memory\n", mem_size);
    }

    ~VortexDevice() {
        delete[] csr_space;
        delete[] host_memory;
    }

    void csr_write32(uint32_t offset, uint32_t value) {
        printf("CSR Write: 0x%03X = 0x%08X\n", offset, value);
        csr_space[offset / sizeof(uint32_t)] = value;
    }

    uint32_t csr_read32(uint32_t offset) {
        uint32_t value = csr_space[offset / sizeof(uint32_t)];
        printf("CSR Read:  0x%03X = 0x%08X\n", offset, value);
        return value;
    }

    void csr_write64(uint32_t offset, uint64_t value) {
        csr_write32(offset, static_cast<uint32_t>(value));
        csr_write32(offset + 4, static_cast<uint32_t>(value >> 32));
    }

    uint64_t csr_read64(uint32_t offset) {
        uint64_t low = csr_read32(offset);
        uint64_t high = csr_read32(offset + 4);
        return low | (high << 32);
    }

    /**
     * Get pointer to completion structure in host memory
     */
    CompletionData* get_completion_ptr(uint64_t addr) {
        if (addr >= host_memory_size) {
            fprintf(stderr, "Error: Completion address 0x%lX out of range\n", addr);
            return nullptr;
        }
        return reinterpret_cast<CompletionData*>(host_memory + addr);
    }

    /**
     * Clear completion structure (set magic to 0)
     */
    void clear_completion(uint64_t addr) {
        auto* comp = get_completion_ptr(addr);
        if (comp) {
            memset(comp, 0, sizeof(CompletionData));
            printf("Cleared completion at 0x%lX\n", addr);
        }
    }

    /**
     * Simulate DCOH writeback (for testing without actual hardware)
     */
    void simulate_dcoh_writeback(uint64_t addr, uint32_t status, uint64_t result) {
        auto* comp = get_completion_ptr(addr);
        if (comp) {
            comp->magic = COMPLETION_MAGIC;
            comp->status = status;
            comp->result = result;
            comp->cycles = 12345;  // Simulated cycle count
            comp->timestamp = 67890;
            printf("Simulated DCOH writeback to 0x%lX: magic=0x%X, status=%u\n",
                   addr, comp->magic, comp->status);
        }
    }
};

/**
 * KernelLauncher - High-level interface for launching GPU kernels
 */
class KernelLauncher {
public:
    VortexDevice& device;

    KernelLauncher(VortexDevice& dev) : device(dev) {}

    /**
     * Configure kernel parameters
     */
    void configure_kernel(uint64_t kernel_addr, uint64_t kernel_args,
                         uint32_t grid_x, uint32_t grid_y, uint32_t grid_z,
                         uint32_t block_x, uint32_t block_y, uint32_t block_z) {
        printf("\n--- Configuring Kernel ---\n");
        printf("Kernel address: 0x%lX\n", kernel_addr);
        printf("Kernel args:    0x%lX\n", kernel_args);
        printf("Grid:           (%u, %u, %u)\n", grid_x, grid_y, grid_z);
        printf("Block:          (%u, %u, %u)\n", block_x, block_y, block_z);

        device.csr_write64(VortexCSR::KERNEL_ADDR_LO, kernel_addr);
        device.csr_write64(VortexCSR::KERNEL_ARGS_LO, kernel_args);
        device.csr_write32(VortexCSR::GRID_DIM_X, grid_x);
        device.csr_write32(VortexCSR::GRID_DIM_Y, grid_y);
        device.csr_write32(VortexCSR::GRID_DIM_Z, grid_z);
        device.csr_write32(VortexCSR::BLOCK_DIM_X, block_x);
        device.csr_write32(VortexCSR::BLOCK_DIM_Y, block_y);
        device.csr_write32(VortexCSR::BLOCK_DIM_Z, block_z);
    }

    /**
     * Configure DCOH completion
     */
    void configure_completion(uint64_t completion_addr, bool enable) {
        printf("\n--- Configuring DCOH Completion ---\n");
        printf("Completion address: 0x%lX\n", completion_addr);
        printf("DCOH enabled:       %s\n", enable ? "yes" : "no");

        device.csr_write64(VortexCSR::COMPLETION_LO, completion_addr);
        device.csr_write32(VortexCSR::DCOH_ENABLE, enable ? 1 : 0);

        // Clear the completion structure
        device.clear_completion(completion_addr);
    }

    /**
     * Launch kernel
     */
    void launch() {
        printf("\n--- Launching Kernel ---\n");
        device.csr_write32(VortexCSR::LAUNCH, 1);
    }

    /**
     * Wait for kernel completion using polling
     * Returns status code (0 = success)
     */
    uint32_t wait_polling(uint32_t timeout_ms = 10000) {
        printf("\n--- Waiting for Completion (Polling) ---\n");
        auto start = std::chrono::steady_clock::now();

        while (true) {
            uint32_t status = device.csr_read32(VortexCSR::STATUS);
            if (status == VortexCSR::STATUS_DONE) {
                printf("Kernel completed successfully (status=DONE)\n");
                return 0;
            }
            if (status == VortexCSR::STATUS_ERROR) {
                printf("Kernel failed (status=ERROR)\n");
                return 1;
            }

            auto now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start);
            if (elapsed.count() >= timeout_ms) {
                printf("Timeout waiting for kernel completion\n");
                return 2;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
    }

    /**
     * Wait for kernel completion using DCOH (mwait-compatible)
     *
     * On real hardware, this would use monitor/mwait instructions:
     *   1. Load completion->magic (arm the monitor)
     *   2. If magic != COMPLETION_MAGIC, execute mwait
     *   3. When cache line is invalidated by DCOH write, mwait wakes up
     *   4. Check magic again
     *
     * This is more power-efficient than busy polling.
     */
    uint32_t wait_dcoh(uint64_t completion_addr, uint32_t timeout_ms = 10000) {
        printf("\n--- Waiting for Completion (DCOH/mwait) ---\n");

        auto* comp = device.get_completion_ptr(completion_addr);
        if (!comp) {
            return 3;
        }

        auto start = std::chrono::steady_clock::now();

        // Simulate mwait behavior
        __monitor(comp, 0, 0);  // ARM monitor on cache line
        while (true) {
            // In real code, this would be:
            if (comp->magic != COMPLETION_MAGIC) {
                __mwait(0, 0);  // Wait for cache line invalidation
            }

            // Check for completion
            if (comp->magic == COMPLETION_MAGIC) {
                printf("DCOH completion received!\n");
                printf("  Magic:     0x%08X\n", comp->magic);
                printf("  Status:    %u\n", comp->status);
                printf("  Result:    0x%016lX\n", comp->result);
                printf("  Cycles:    %lu\n", comp->cycles);
                printf("  Timestamp: %lu\n", comp->timestamp);
                printf("  Address:   %p\n", ((int64_t*)comp)+8);
                return comp->status;
            }

            auto now = std::chrono::steady_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start);
            if (elapsed.count() >= timeout_ms) {
                printf("Timeout waiting for DCOH completion\n");
                return 2;
            }

            // Small sleep to simulate mwait wake-up latency
            std::this_thread::sleep_for(std::chrono::microseconds(100));
        }
    }
};

/**
 * Main test function
 */
int main(int argc, char* argv[]) {
    printf("========================================\n");
    printf("Vortex GPU Kernel Launch Test\n");
    printf("CXL Type2 Device with DCOH Support\n");
    printf("========================================\n");

    // Create device
    VortexDevice device(1024 * 1024);  // 1MB host memory
    KernelLauncher launcher(device);

    // Test parameters
    constexpr uint64_t KERNEL_ADDR = 0x80000000;
    constexpr uint64_t KERNEL_ARGS = 0x80001000;
    constexpr uint64_t COMPLETION_ADDR = 0x1000;  // Offset in host memory

    //-------------------------------------------------------------------------
    // Test 1: Basic Kernel Launch with Polling
    //-------------------------------------------------------------------------
    printf("\n========================================\n");
    printf("Test 1: Kernel Launch with CSR Polling\n");
    printf("========================================\n");

    launcher.configure_kernel(
        KERNEL_ADDR, KERNEL_ARGS,
        128, 1, 1,   // Grid: 128x1x1
        32, 1, 1     // Block: 32x1x1
    );

    launcher.launch();

    // Simulate kernel completion (would happen in hardware)
    device.csr_space[VortexCSR::STATUS / sizeof(uint32_t)] = VortexCSR::STATUS_DONE;

    uint32_t result = launcher.wait_polling(1000);
    printf("Test 1 Result: %s\n", result == 0 ? "PASS" : "FAIL");

    //-------------------------------------------------------------------------
    // Test 2: Kernel Launch with DCOH Completion
    //-------------------------------------------------------------------------
    printf("\n========================================\n");
    printf("Test 2: Kernel Launch with DCOH/mwait\n");
    printf("========================================\n");

    launcher.configure_kernel(
        KERNEL_ADDR, KERNEL_ARGS,
        256, 1, 1,   // Grid: 256x1x1
        64, 1, 1     // Block: 64x1x1
    );

    launcher.configure_completion(COMPLETION_ADDR, true);

    launcher.launch();

    // Simulate DCOH writeback (would happen in hardware)
    device.simulate_dcoh_writeback(COMPLETION_ADDR, 0, 0xCAFEBABEDEADBEEF);

    result = launcher.wait_dcoh(COMPLETION_ADDR, 1000);
    printf("Test 2 Result: %s\n", result == 0 ? "PASS" : "FAIL");

    //-------------------------------------------------------------------------
    // Test 3: Multiple Kernel Launches
    //-------------------------------------------------------------------------
    printf("\n========================================\n");
    printf("Test 3: Multiple Kernel Launches\n");
    printf("========================================\n");

    for (int i = 0; i < 3; i++) {
        printf("\n--- Kernel Launch %d ---\n", i);

        uint64_t comp_addr = COMPLETION_ADDR + i * 64;  // Different completion address

        launcher.configure_kernel(
            KERNEL_ADDR, KERNEL_ARGS + i * 0x100,
            64 * (i + 1), 1, 1,
            32, 1, 1
        );

        launcher.configure_completion(comp_addr, true);
        launcher.launch();

        // Simulate completion
        device.simulate_dcoh_writeback(comp_addr, 0, 0x1000 + i);

        result = launcher.wait_dcoh(comp_addr, 1000);
        printf("Kernel %d Result: %s\n", i, result == 0 ? "PASS" : "FAIL");
    }

    //-------------------------------------------------------------------------
    // Summary
    //-------------------------------------------------------------------------
    printf("\n========================================\n");
    printf("All Tests Completed\n");
    printf("========================================\n");

    return 0;
}
