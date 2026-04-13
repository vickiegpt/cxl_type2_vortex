/**
 * cira_runtime.h
 *
 * Host-side CIRA runtime for CXL Type 2 heterogeneous execution.
 * Targets real hardware: Intel Agilex 7 FPGA with Vortex RISC-V GPU.
 *
 * Uses the Vortex AFU MMIO command protocol via BAR0 /dev/mem:
 *   1. CMD_MEM_WRITE: DMA kernel binary + args into GPU memory
 *   2. CMD_DCR_WRITE: Set startup address and args DCRs
 *   3. CMD_RUN: Launch kernel execution
 *   4. Poll MMIO_STATUS for completion
 *
 * CSR space at BAR0+0x180100 for direct register access:
 *   0x100: KERNEL_ADDR_LO/HI, 0x108: KERNEL_ARGS_LO/HI
 *   0x110-0x124: Grid/Block dims, 0x128: LAUNCH, 0x12C: STATUS
 *
 * Usage:
 *   CiraRuntime rt;
 *   rt.init();
 *   rt.load_kernel("kernels/prefetch_chain_kernel.bin");
 *   rt.upload_args(&args, sizeof(args), GPU_ARGS_ADDR);
 *   rt.launch_kernel(GPU_KERNEL_ADDR, GPU_ARGS_ADDR);
 *   rt.wait_completion();
 */

#pragma once

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>
#include <memory>
#include "completion_data.h"

namespace cira::runtime {

// ============================================================================
// Vortex AFU MMIO register offsets (from vortex_afu.h / cxl_gpu_launcher.cpp)
// ============================================================================

static constexpr uint32_t AFU_CMD_MEM_READ    = 1;
static constexpr uint32_t AFU_CMD_MEM_WRITE   = 2;
static constexpr uint32_t AFU_CMD_RUN         = 3;
static constexpr uint32_t AFU_CMD_DCR_WRITE   = 4;

// MMIO offsets (register_index * 4)
static constexpr uint32_t MMIO_CMD_TYPE       = 0x28;  // 10 * 4
static constexpr uint32_t MMIO_CMD_ARG0       = 0x30;  // 12 * 4
static constexpr uint32_t MMIO_CMD_ARG1       = 0x38;  // 14 * 4
static constexpr uint32_t MMIO_CMD_ARG2       = 0x40;  // 16 * 4
static constexpr uint32_t MMIO_STATUS         = 0x48;  // 18 * 4
static constexpr uint32_t MMIO_DEV_CAPS       = 0x60;  // 24 * 4
static constexpr uint32_t MMIO_ISA_CAPS       = 0x68;  // 26 * 4

// Vortex DCR addresses (from VX_types.h)
static constexpr uint32_t VX_DCR_BASE_STARTUP_ADDR0 = 0x001;
static constexpr uint32_t VX_DCR_BASE_STARTUP_ADDR1 = 0x002;
static constexpr uint32_t VX_DCR_BASE_STARTUP_ARG0  = 0x003;
static constexpr uint32_t VX_DCR_BASE_STARTUP_ARG1  = 0x004;

// Memory constants
static constexpr uint32_t CACHE_BLOCK_SIZE  = 64;
static constexpr int      LS_SHIFT          = 6;    // log2(64) = 6

// Default device memory layout
static constexpr uint64_t GPU_KERNEL_ADDR   = 0x80000000ULL;
static constexpr uint64_t GPU_ARGS_ADDR     = 0x80010000ULL;
static constexpr uint64_t GPU_COMPL_ADDR    = 0x80020000ULL;

// STATUS register bits
static constexpr uint32_t STATUS_STATE_BITS = 8;

// Hardware addresses
static constexpr uint64_t BAR0_PHYS_DEFAULT = 0xa2800000UL;
static constexpr size_t   BAR0_MAP_SIZE     = 0x200000;  // 2MB

// Well-known function addresses loaded into Vortex instruction memory.
enum CiraDeviceFunc : uint64_t {
    FUNC_PREFETCH_CHAIN   = 0x80000000ULL,
    FUNC_PREFETCH_HASH    = 0x80004000ULL,
    FUNC_PREFETCH_STREAM  = 0x80008000ULL,
};

// Device capabilities (queried from hardware)
struct DeviceCaps {
    uint32_t version;
    uint32_t num_threads;
    uint32_t num_warps;
    uint32_t num_cores;
    uint64_t isa_caps;
};

// Opaque handle for allocated futures
struct CiraFuture {
    uint32_t id;
    volatile CompletionData* completion;
    uint64_t device_addr;   // Device-side address of completion slot
};

// Handle to CXL memory region
struct CiraHandle {
    uint64_t device_addr;   // Address in device memory space
    void* host_addr;        // Host-visible mmap'd/staging address
    size_t size;
};

/**
 * CiraRuntime — host-side runtime for real Vortex hardware.
 */
class CiraRuntime {
public:
    CiraRuntime();
    ~CiraRuntime();

    /**
     * Initialize: mmap BAR0, query device caps.
     * @param bar0_phys   Physical address of BAR0 (default 0xa2800000)
     * @return true on success
     */
    bool init(uint64_t bar0_phys = BAR0_PHYS_DEFAULT);

    /** Get device capabilities */
    const DeviceCaps& caps() const { return caps_; }

    /**
     * Load a kernel binary into Vortex instruction memory via AFU CMD_MEM_WRITE.
     * @param path        Path to .bin file (RV64 raw binary)
     * @param load_addr   Device address to load at (default 0x80000000)
     * @return true on success
     */
    bool load_kernel(const std::string& path,
                     uint64_t load_addr = GPU_KERNEL_ADDR);

    /**
     * Upload data to device memory via AFU CMD_MEM_WRITE.
     * Used for kernel arguments, input data, etc.
     */
    bool upload(const void* data, size_t size, uint64_t dev_addr);

    /**
     * Launch a kernel: writes DCRs for startup addr + args, then CMD_RUN.
     * @param kernel_addr  Device address where kernel is loaded
     * @param args_addr    Device address where kernel args are staged
     * @return true on success
     */
    bool launch_kernel(uint64_t kernel_addr = GPU_KERNEL_ADDR,
                       uint64_t args_addr = GPU_ARGS_ADDR);

    /**
     * Wait for Vortex to finish (poll MMIO_STATUS).
     * @param timeout_ms  Max wait time in milliseconds
     * @return 0 on success, -1 on timeout
     */
    int wait_completion(int timeout_ms = 30000);

    /**
     * Write a DCR register on the Vortex core.
     */
    void dcr_write(uint32_t addr, uint32_t value);

    // ---- High-level CIRA Operations ----

    /** Allocate device memory region (via staging buffer) */
    CiraHandle alloc_cxl(size_t size);

    /** Free a CXL region */
    void free_cxl(CiraHandle& handle);

    /** Create a future (allocates completion slot in device memory) */
    CiraFuture future_create(uint32_t num_lines = 1);

    /** Wait for future: poll completion magic via device memory read-back */
    bool future_await(CiraFuture& future, int timeout_ms = 10000);

    /** Release a future's resources */
    void release(CiraFuture& future);

    /**
     * Full offload sequence: upload args, load kernel, launch, wait.
     * This is the single-shot API for running a prefetch kernel.
     */
    bool offload(uint64_t func_addr, const void* args, size_t args_size,
                 CiraFuture* future = nullptr);

    /** Wait for all outstanding operations */
    bool barrier(int timeout_ms = 30000);

    /** Phase boundary (barrier + log) */
    void phase_boundary(const std::string& phase_name = "");

    /** Get pending task count (0 or 1, Vortex is single-kernel-at-a-time) */
    uint32_t pending_tasks() const;

private:
    int mem_fd_ = -1;
    volatile uint8_t* bar0_ = nullptr;
    DeviceCaps caps_ = {};

    // Staging buffer for DMA (hugepage-backed)
    uint8_t* staging_ = nullptr;
    uint64_t staging_phys_ = 0;
    size_t staging_size_ = 0;

    // Completion data pool
    static constexpr uint32_t MAX_FUTURES = 64;
    CompletionData completion_pool_[MAX_FUTURES] = {};
    uint32_t next_future_id_ = 0;
    uint64_t next_dev_alloc_ = GPU_ARGS_ADDR + 0x10000;  // bump allocator

    bool kernel_running_ = false;

    // Low-level MMIO
    void mmio_write64(uint32_t offset, uint64_t value);
    uint64_t mmio_read64(uint32_t offset);

    // Staging buffer management
    bool alloc_staging(size_t size);
    uint64_t virt_to_phys(void* vaddr);

    // Upload via AFU command (with staging DMA) or fallback CSR path
    int upload_via_afu(uint64_t dev_addr, const void* data, size_t size);
};

}  // namespace cira::runtime
