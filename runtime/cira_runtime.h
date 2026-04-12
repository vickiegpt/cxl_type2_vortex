/**
 * cira_runtime.h
 *
 * Host-side CIRA runtime for CXL Type 2 heterogeneous execution.
 *
 * Manages:
 *   - BAR0 MMIO mapping (real hardware) or simulated fallback
 *   - MMIO ring buffer for task submission
 *   - DCOH completion data for task synchronization
 *   - Kernel binary loading to Vortex instruction memory
 *   - Future allocation and mwait-based signaling
 *
 * Usage:
 *   CiraRuntime rt;
 *   rt.init("/dev/mem", 0xa2800000);
 *   rt.load_kernel("kernels/prefetch_chain_kernel.bin");
 *   auto future = rt.future_create(1);
 *   rt.offload(data_ptr, FUNC_PREFETCH_CHAIN, {depth, count}, future);
 *   rt.future_await(future);
 *   rt.release(future);
 *   rt.barrier();
 */

#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <memory>
#include "completion_data.h"
#include "mmio_ring_buffer.h"

namespace cira::runtime {

// Well-known function addresses loaded into Vortex instruction memory.
// These correspond to entry points of prefetch kernels.
enum CiraDeviceFunc : uint64_t {
    FUNC_PREFETCH_CHAIN   = 0x80000000ULL,
    FUNC_PREFETCH_HASH    = 0x80004000ULL,
    FUNC_PREFETCH_STREAM  = 0x80008000ULL,
};

// Opaque handle for allocated futures
struct CiraFuture {
    uint32_t id;
    volatile CompletionData* completion;
};

// Handle to CXL memory region
struct CiraHandle {
    uint64_t device_addr;   // Address in CXL/device memory space
    void* host_addr;        // Host-visible mmap'd address (via HDM)
    size_t size;
};

/**
 * CiraRuntime — main host-side runtime class.
 */
class CiraRuntime {
public:
    CiraRuntime();
    ~CiraRuntime();

    /**
     * Initialize the runtime.
     * @param dev_path    Path to memory device (e.g., "/dev/mem")
     * @param bar0_phys   Physical address of BAR0 (e.g., 0xa2800000)
     * @param bar0_size   Size of BAR0 mapping (default 2MB)
     * @param simulate    If true, use simulated BAR0 (no real hardware)
     * @return true on success
     */
    bool init(const std::string& dev_path = "/dev/mem",
              uint64_t bar0_phys = 0xa2800000UL,
              size_t bar0_size = 2 * 1024 * 1024,
              bool simulate = false);

    /**
     * Load a kernel binary into Vortex instruction memory.
     * @param path        Path to .bin file (RV64 raw binary)
     * @param load_addr   Device address to load at
     * @return true on success
     */
    bool load_kernel(const std::string& path, uint64_t load_addr = FUNC_PREFETCH_CHAIN);

    // ---- CIRA Operations (match the IR ops) ----

    /** Allocate a region in CXL-visible memory */
    CiraHandle alloc_cxl(size_t size);

    /** Free a CXL region */
    void free_cxl(CiraHandle& handle);

    /** Create a future with num_lines completion slots */
    CiraFuture future_create(uint32_t num_lines);

    /** Wait for a future to be signaled by device */
    bool future_await(CiraFuture& future, uint64_t timeout_spins = 10000000);

    /** Release a future's resources and signal device that tile is free */
    void release(CiraFuture& future);

    /** Submit a high-priority offload task */
    bool offload(uint64_t data_ptr, uint64_t func_addr,
                 uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg3,
                 uint32_t prefetch_depth, CiraFuture* future = nullptr);

    /** Submit a low-priority speculative task */
    bool speculate(uint64_t data_ptr, uint64_t func_addr,
                   uint32_t arg0, uint32_t arg1, uint32_t arg2, uint32_t arg3,
                   uint32_t prefetch_depth, CiraFuture* future = nullptr);

    /** Wait for all outstanding tasks to complete */
    bool barrier(uint64_t timeout_spins = 50000000);

    /** Phase boundary (barrier + potential ReJIT trigger) */
    void phase_boundary(const std::string& phase_name = "");

    /** Check if runtime is using real hardware */
    bool is_hardware() const { return !simulate_; }

    /** Get ring buffer stats */
    uint32_t pending_tasks() const;

private:
    // BAR0 MMIO mapping
    int mem_fd_ = -1;
    volatile void* bar0_ = nullptr;
    size_t bar0_size_ = 0;
    bool simulate_ = false;

    // Simulated BAR0 for testing
    std::unique_ptr<uint8_t[]> sim_bar0_;

    // Ring buffer
    MmioRingBuffer ring_buffer_;

    // Completion data pool
    static constexpr uint32_t MAX_FUTURES = 64;
    CompletionData completion_pool_[MAX_FUTURES] = {};
    uint32_t next_future_id_ = 0;
    uint32_t next_task_id_ = 0;

    // Kernel upload helpers
    void mmio_write64(uint32_t offset, uint64_t value);
    uint64_t mmio_read64(uint32_t offset);
};

}  // namespace cira::runtime
