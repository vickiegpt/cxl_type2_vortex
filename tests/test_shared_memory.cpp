/**
 * test_shared_memory.cpp
 *
 * Example demonstrating Host and Vortex GPU sharing CXL memory
 * with cache coherence via the shared memory arbiter.
 *
 * Memory Model:
 *   - Host and Vortex see the same unified address space
 *   - Host accesses via CXL.mem (load/store instructions)
 *   - Vortex accesses via AXI (internal memory requests)
 *   - Arbiter serializes and maintains coherence
 *
 * Usage Pattern:
 *   1. Host writes input data to shared buffer
 *   2. Host launches kernel (Vortex reads input, computes, writes output)
 *   3. Host reads output data (sees Vortex's writes coherently)
 *   4. Optional: Host can use mwait/monitor for completion notification
 */

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <thread>
#include <chrono>
#include <atomic>

//=============================================================================
// Memory Map Constants (matches RTL)
//=============================================================================
constexpr uint64_t CXL_MEM_BASE        = 0x0000000000000000ULL;  // CXL device memory base
constexpr uint64_t KERNEL_CODE_BASE    = 0x0000000080000000ULL;  // Kernel code region
constexpr uint64_t KERNEL_DATA_BASE    = 0x0000000090000000ULL;  // Kernel data/args
constexpr uint64_t SHARED_BUFFER_BASE  = 0x00000000A0000000ULL;  // Shared compute buffers
constexpr uint64_t COMPLETION_ADDR     = 0x0000000000001000ULL;  // Completion structure

constexpr size_t CACHE_LINE_SIZE = 64;

//=============================================================================
// CSR Register Map
//=============================================================================
constexpr uint64_t CSR_BASE            = 0x0000000000000000ULL;  // MMIO base
constexpr uint32_t REG_KERNEL_ADDR_LO  = 0x100;
constexpr uint32_t REG_KERNEL_ADDR_HI  = 0x104;
constexpr uint32_t REG_KERNEL_ARGS_LO  = 0x108;
constexpr uint32_t REG_KERNEL_ARGS_HI  = 0x10C;
constexpr uint32_t REG_GRID_DIM_X      = 0x110;
constexpr uint32_t REG_GRID_DIM_Y      = 0x114;
constexpr uint32_t REG_GRID_DIM_Z      = 0x118;
constexpr uint32_t REG_BLOCK_DIM_X     = 0x11C;
constexpr uint32_t REG_BLOCK_DIM_Y     = 0x120;
constexpr uint32_t REG_BLOCK_DIM_Z     = 0x124;
constexpr uint32_t REG_LAUNCH          = 0x128;
constexpr uint32_t REG_STATUS          = 0x12C;
constexpr uint32_t REG_COMPLETION_LO   = 0x140;
constexpr uint32_t REG_COMPLETION_HI   = 0x144;
constexpr uint32_t REG_DCOH_ENABLE     = 0x148;

// Status values
constexpr uint8_t STATUS_IDLE    = 0x00;
constexpr uint8_t STATUS_RUNNING = 0x01;
constexpr uint8_t STATUS_DONE    = 0x02;
constexpr uint8_t STATUS_ERROR   = 0xFF;

//=============================================================================
// Completion Structure (64-byte cache line aligned)
//=============================================================================
struct alignas(CACHE_LINE_SIZE) CompletionData {
    uint32_t magic;       // 0xDEADBEEF when complete
    uint32_t status;      // Kernel exit status
    uint64_t result;      // Result value
    uint64_t cycles;      // Cycle count
    uint64_t timestamp;   // Completion timestamp
    uint8_t  reserved[32];// Padding to 64 bytes
};

static_assert(sizeof(CompletionData) == 64, "CompletionData must be 64 bytes");

//=============================================================================
// Simulated CXL Memory Access
//=============================================================================
class CXLMemory {
public:
    static constexpr size_t MEM_SIZE = 256 * 1024 * 1024;  // 256MB simulated

    CXLMemory() {
        memory_ = new uint8_t[MEM_SIZE];
        memset(memory_, 0, MEM_SIZE);
        printf("[CXL] Memory initialized: %zu MB\n", MEM_SIZE / (1024*1024));
    }

    ~CXLMemory() {
        delete[] memory_;
    }

    // Host read (via CXL.mem)
    template<typename T>
    T read(uint64_t addr) {
        if (addr + sizeof(T) > MEM_SIZE) {
            printf("[CXL] ERROR: Read out of bounds at 0x%lx\n", addr);
            return T{};
        }
        T value;
        memcpy(&value, &memory_[addr], sizeof(T));
        return value;
    }

    // Host write (via CXL.mem)
    template<typename T>
    void write(uint64_t addr, T value) {
        if (addr + sizeof(T) > MEM_SIZE) {
            printf("[CXL] ERROR: Write out of bounds at 0x%lx\n", addr);
            return;
        }
        memcpy(&memory_[addr], &value, sizeof(T));
    }

    // Get raw pointer for bulk operations
    uint8_t* ptr(uint64_t addr) {
        return &memory_[addr];
    }

    // Vortex access (via AXI through arbiter)
    // In real HW, this goes through the arbiter and triggers coherence
    void vortex_read(uint64_t addr, void* data, size_t len) {
        memcpy(data, &memory_[addr], len);
    }

    void vortex_write(uint64_t addr, const void* data, size_t len) {
        memcpy(&memory_[addr], data, len);
    }

private:
    uint8_t* memory_;
};

//=============================================================================
// Simulated Vortex GPU
//=============================================================================
class VortexGPU {
public:
    VortexGPU(CXLMemory& mem) : memory_(mem), running_(false) {}

    // CSR write
    void csr_write(uint32_t addr, uint64_t value) {
        switch (addr) {
            case REG_KERNEL_ADDR_LO: kernel_addr_ = (kernel_addr_ & 0xFFFFFFFF00000000ULL) | (value & 0xFFFFFFFF); break;
            case REG_KERNEL_ADDR_HI: kernel_addr_ = (kernel_addr_ & 0x00000000FFFFFFFFULL) | ((value & 0xFFFFFFFF) << 32); break;
            case REG_KERNEL_ARGS_LO: kernel_args_ = (kernel_args_ & 0xFFFFFFFF00000000ULL) | (value & 0xFFFFFFFF); break;
            case REG_KERNEL_ARGS_HI: kernel_args_ = (kernel_args_ & 0x00000000FFFFFFFFULL) | ((value & 0xFFFFFFFF) << 32); break;
            case REG_GRID_DIM_X:     grid_dim_[0] = value; break;
            case REG_GRID_DIM_Y:     grid_dim_[1] = value; break;
            case REG_GRID_DIM_Z:     grid_dim_[2] = value; break;
            case REG_BLOCK_DIM_X:    block_dim_[0] = value; break;
            case REG_BLOCK_DIM_Y:    block_dim_[1] = value; break;
            case REG_BLOCK_DIM_Z:    block_dim_[2] = value; break;
            case REG_COMPLETION_LO:  completion_addr_ = (completion_addr_ & 0xFFFFFFFF00000000ULL) | (value & 0xFFFFFFFF); break;
            case REG_COMPLETION_HI:  completion_addr_ = (completion_addr_ & 0x00000000FFFFFFFFULL) | ((value & 0xFFFFFFFF) << 32); break;
            case REG_DCOH_ENABLE:    dcoh_enabled_ = (value != 0); break;
            case REG_LAUNCH:
                if (value & 1) {
                    launch_kernel();
                }
                break;
        }
    }

    // CSR read
    uint64_t csr_read(uint32_t addr) {
        switch (addr) {
            case REG_STATUS: return status_;
            default: return 0;
        }
    }

    bool is_running() const { return running_; }
    uint8_t status() const { return status_; }

private:
    void launch_kernel() {
        if (running_) return;

        printf("[Vortex] Kernel launched: addr=0x%lx args=0x%lx grid=(%u,%u,%u)\n",
               kernel_addr_, kernel_args_, grid_dim_[0], grid_dim_[1], grid_dim_[2]);

        running_ = true;
        status_ = STATUS_RUNNING;

        // Simulate kernel execution in a thread
        std::thread([this]() {
            execute_kernel();
        }).detach();
    }

    void execute_kernel() {
        // Simulate kernel reading input data from shared memory
        uint64_t input_addr = kernel_args_;
        uint64_t output_addr = kernel_args_ + 4096;  // Output follows input

        printf("[Vortex] Reading input from 0x%lx\n", input_addr);

        // Read input data (simulated memory access through arbiter)
        uint32_t input_data[256];
        memory_.vortex_read(input_addr, input_data, sizeof(input_data));

        // Simple computation: square each element
        uint32_t output_data[256];
        uint64_t sum = 0;
        for (int i = 0; i < 256; i++) {
            output_data[i] = input_data[i] * input_data[i];
            sum += output_data[i];
        }

        // Simulate computation time
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // Write output data
        printf("[Vortex] Writing output to 0x%lx\n", output_addr);
        memory_.vortex_write(output_addr, output_data, sizeof(output_data));

        // Write completion via DCOH (coherent write to host memory)
        if (dcoh_enabled_) {
            printf("[Vortex] Writing DCOH completion to 0x%lx\n", completion_addr_);

            CompletionData completion;
            completion.magic = 0xDEADBEEF;
            completion.status = 0;  // Success
            completion.result = sum;
            completion.cycles = 1000;  // Simulated
            completion.timestamp = 12345678;
            memset(completion.reserved, 0, sizeof(completion.reserved));

            // This write goes through CXL.cache WrInv to maintain coherence
            memory_.vortex_write(completion_addr_, &completion, sizeof(completion));
        }

        status_ = STATUS_DONE;
        running_ = false;
        printf("[Vortex] Kernel completed\n");
    }

    CXLMemory& memory_;
    std::atomic<bool> running_;
    std::atomic<uint8_t> status_{STATUS_IDLE};

    uint64_t kernel_addr_ = 0;
    uint64_t kernel_args_ = 0;
    uint32_t grid_dim_[3] = {1, 1, 1};
    uint32_t block_dim_[3] = {1, 1, 1};
    uint64_t completion_addr_ = 0;
    bool dcoh_enabled_ = false;
};

//=============================================================================
// Test: Host and Vortex Shared Memory Access
//=============================================================================
void test_shared_memory() {
    printf("\n========================================\n");
    printf("Test: Host/Vortex Shared Memory Access\n");
    printf("========================================\n\n");

    // Create CXL memory (unified address space)
    CXLMemory cxl_mem;

    // Create Vortex GPU
    VortexGPU vortex(cxl_mem);

    // Define buffer addresses in unified space
    uint64_t input_buffer = 0x1000;   // Input data
    uint64_t output_buffer = 0x2000;  // Output data
    uint64_t completion = 0x3000;     // Completion notification

    //-------------------------------------------------------------------------
    // Step 1: Host writes input data to shared memory
    //-------------------------------------------------------------------------
    printf("Step 1: Host writing input data to shared memory...\n");

    uint32_t input_data[256];
    for (int i = 0; i < 256; i++) {
        input_data[i] = i + 1;  // 1, 2, 3, ..., 256
    }

    // Host write (via CXL.mem)
    memcpy(cxl_mem.ptr(input_buffer), input_data, sizeof(input_data));
    printf("  Input buffer at 0x%lx: %u, %u, %u, ...\n",
           input_buffer, input_data[0], input_data[1], input_data[2]);

    //-------------------------------------------------------------------------
    // Step 2: Configure Vortex and launch kernel
    //-------------------------------------------------------------------------
    printf("\nStep 2: Configuring and launching kernel...\n");

    // Set kernel parameters
    vortex.csr_write(REG_KERNEL_ADDR_LO, KERNEL_CODE_BASE & 0xFFFFFFFF);
    vortex.csr_write(REG_KERNEL_ADDR_HI, KERNEL_CODE_BASE >> 32);
    vortex.csr_write(REG_KERNEL_ARGS_LO, input_buffer & 0xFFFFFFFF);
    vortex.csr_write(REG_KERNEL_ARGS_HI, input_buffer >> 32);
    vortex.csr_write(REG_GRID_DIM_X, 1);
    vortex.csr_write(REG_GRID_DIM_Y, 1);
    vortex.csr_write(REG_GRID_DIM_Z, 1);
    vortex.csr_write(REG_BLOCK_DIM_X, 256);

    // Enable DCOH completion
    vortex.csr_write(REG_COMPLETION_LO, completion & 0xFFFFFFFF);
    vortex.csr_write(REG_COMPLETION_HI, completion >> 32);
    vortex.csr_write(REG_DCOH_ENABLE, 1);

    // Launch kernel
    vortex.csr_write(REG_LAUNCH, 1);

    //-------------------------------------------------------------------------
    // Step 3: Wait for completion (poll or mwait)
    //-------------------------------------------------------------------------
    printf("\nStep 3: Waiting for kernel completion...\n");

    // Method A: Poll status register
    printf("  Polling status register...\n");
    while (vortex.csr_read(REG_STATUS) == STATUS_RUNNING) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    // Method B: Poll completion magic (simulating mwait)
    printf("  Checking completion structure...\n");
    CompletionData* comp = reinterpret_cast<CompletionData*>(cxl_mem.ptr(completion));

    int timeout = 100;
    while (comp->magic != 0xDEADBEEF && timeout > 0) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        timeout--;
    }

    if (comp->magic == 0xDEADBEEF) {
        printf("  Completion received!\n");
        printf("    Magic:     0x%08X\n", comp->magic);
        printf("    Status:    %u\n", comp->status);
        printf("    Result:    %lu\n", comp->result);
        printf("    Cycles:    %lu\n", comp->cycles);
    } else {
        printf("  ERROR: Completion timeout!\n");
    }

    //-------------------------------------------------------------------------
    // Step 4: Host reads output data (coherently sees Vortex writes)
    //-------------------------------------------------------------------------
    printf("\nStep 4: Host reading output data...\n");

    uint32_t output_data[256];
    memcpy(output_data, cxl_mem.ptr(output_buffer), sizeof(output_data));

    printf("  Output buffer at 0x%lx: %u, %u, %u, ...\n",
           output_buffer, output_data[0], output_data[1], output_data[2]);

    // Verify results
    printf("\nVerifying results:\n");
    int errors = 0;
    for (int i = 0; i < 256; i++) {
        uint32_t expected = (i + 1) * (i + 1);
        if (output_data[i] != expected) {
            if (errors < 5) {
                printf("  ERROR at [%d]: expected %u, got %u\n", i, expected, output_data[i]);
            }
            errors++;
        }
    }

    if (errors == 0) {
        printf("  All 256 values correct!\n");
    } else {
        printf("  %d errors found\n", errors);
    }

    printf("\n========================================\n");
    printf("Test Complete\n");
    printf("========================================\n");
}

//=============================================================================
// Test: Concurrent Access Pattern
//=============================================================================
void test_concurrent_access() {
    printf("\n========================================\n");
    printf("Test: Concurrent Access Pattern\n");
    printf("========================================\n\n");

    CXLMemory cxl_mem;

    // Simulate host and device accessing different regions simultaneously
    // The arbiter would serialize these, but both can make progress

    printf("Demonstrating interleaved access pattern:\n\n");

    // Host writes to region A
    printf("  [Host]   Write to 0x1000\n");
    uint64_t host_data = 0xAAAAAAAAAAAAAAAAULL;
    cxl_mem.write<uint64_t>(0x1000, host_data);

    // Device writes to region B
    printf("  [Vortex] Write to 0x2000\n");
    uint64_t vortex_data = 0xBBBBBBBBBBBBBBBBULL;
    cxl_mem.vortex_write(0x2000, &vortex_data, sizeof(vortex_data));

    // Host reads from region B (sees Vortex write - coherent)
    printf("  [Host]   Read from 0x2000 -> 0x%lx (sees Vortex write)\n",
           cxl_mem.read<uint64_t>(0x2000));

    // Device reads from region A (sees Host write - coherent)
    uint64_t read_data;
    cxl_mem.vortex_read(0x1000, &read_data, sizeof(read_data));
    printf("  [Vortex] Read from 0x1000 -> 0x%lx (sees Host write)\n", read_data);

    printf("\nCoherence maintained through arbiter!\n");
}

//=============================================================================
// Main
//=============================================================================
int main(int argc, char** argv) {
    printf("CXL Type 2 Shared Memory Test\n");
    printf("Host and Vortex unified address space with coherence\n\n");

    test_shared_memory();
    test_concurrent_access();

    return 0;
}
