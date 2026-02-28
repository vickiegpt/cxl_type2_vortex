/**
 * test_gemm_coherent.cpp
 *
 * Real-device GEMM kernel launch with CXL coherently shared memory.
 *
 * Performs C = alpha*A*B + beta*C using the Vortex GPU (RV64 RISC-V SIMT)
 * on an Intel CXL Type2 device. Supports real PCIe BAR0 MMIO + CXL DAX
 * or hugepage memory, with automatic fallback to full simulation.
 *
 * Fallback chain:
 *   1. Real device (PCIe 0000:ad:00.0 BAR0) + DAX (/dev/dax0.0)
 *   2. Real device + hugepages (MAP_HUGETLB + /proc/self/pagemap)
 *   3. Full simulation (in-memory CSR + aligned_alloc)
 *
 * Usage:
 *   test_gemm_coherent [--dim N] [--alpha F] [--beta F] [--sim] [--verbose]
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <thread>
#include <atomic>
#include <memory>
#include <string>
#include <random>

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>

#include "../kernels/load_kernel.h"

// ============================================================================
// CSR Register Map (matches RTL and existing tests)
// ============================================================================
namespace VortexCSR {
    constexpr uint32_t KERNEL_ADDR_LO  = 0x100;
    constexpr uint32_t KERNEL_ADDR_HI  = 0x104;
    constexpr uint32_t KERNEL_ARGS_LO  = 0x108;
    constexpr uint32_t KERNEL_ARGS_HI  = 0x10C;
    constexpr uint32_t GRID_DIM_X      = 0x110;
    constexpr uint32_t GRID_DIM_Y      = 0x114;
    constexpr uint32_t GRID_DIM_Z      = 0x118;
    constexpr uint32_t BLOCK_DIM_X     = 0x11C;
    constexpr uint32_t BLOCK_DIM_Y     = 0x120;
    constexpr uint32_t BLOCK_DIM_Z     = 0x124;
    constexpr uint32_t LAUNCH          = 0x128;
    constexpr uint32_t STATUS          = 0x12C;
    constexpr uint32_t CYCLE_LO        = 0x130;
    constexpr uint32_t CYCLE_HI        = 0x134;
    constexpr uint32_t INSTR_LO        = 0x138;
    constexpr uint32_t INSTR_HI        = 0x13C;
    constexpr uint32_t COMPLETION_LO   = 0x140;
    constexpr uint32_t COMPLETION_HI   = 0x144;
    constexpr uint32_t DCOH_ENABLE     = 0x148;

    constexpr uint8_t STATUS_IDLE    = 0x00;
    constexpr uint8_t STATUS_RUNNING = 0x01;
    constexpr uint8_t STATUS_DONE    = 0x02;
    constexpr uint8_t STATUS_ERROR   = 0xFF;
}

// ============================================================================
// Completion Structure (64-byte cache-line aligned, same as existing tests)
// ============================================================================
constexpr size_t CACHE_LINE_SIZE = 64;
constexpr uint32_t COMPLETION_MAGIC = 0xDEADBEEF;

struct alignas(CACHE_LINE_SIZE) CompletionData {
    uint32_t magic;
    uint32_t status;
    uint64_t result;
    uint64_t cycles;
    uint64_t timestamp;
    uint8_t  reserved[32];
};
static_assert(sizeof(CompletionData) == 64, "CompletionData must be 64 bytes");

// ============================================================================
// GEMM Kernel Arguments (64-byte aligned)
// ============================================================================
struct alignas(CACHE_LINE_SIZE) GemmKernelArgs {
    uint64_t A_addr;            // Physical/virtual address of matrix A
    uint64_t B_addr;            // Physical/virtual address of matrix B
    uint64_t C_addr;            // Physical/virtual address of matrix C
    uint32_t M;                 // Rows of A, rows of C
    uint32_t N;                 // Cols of B, cols of C
    uint32_t K;                 // Cols of A, rows of B
    uint32_t lda;               // Leading dimension of A
    uint32_t ldb;               // Leading dimension of B
    uint32_t ldc;               // Leading dimension of C
    float    alpha;
    float    beta;
    uint64_t completion_addr;   // Address for DCOH completion
    uint8_t  pad[4];            // Pad to 72 bytes
};

// ============================================================================
// Global flags
// ============================================================================
static bool g_verbose = false;
static bool g_force_sim = false;
static const char* g_kernel_path = nullptr;

// ============================================================================
// DeviceInterface — CSR MMIO access abstraction
// ============================================================================
class DeviceInterface {
public:
    virtual ~DeviceInterface() = default;
    virtual void     csr_write32(uint32_t offset, uint32_t value) = 0;
    virtual uint32_t csr_read32(uint32_t offset) = 0;
    virtual const char* name() const = 0;

    void csr_write64(uint32_t offset, uint64_t value) {
        csr_write32(offset,     static_cast<uint32_t>(value));
        csr_write32(offset + 4, static_cast<uint32_t>(value >> 32));
    }
};

// --- RealDevice: mmap BAR0 of PCIe device -----------------------------------
class RealDevice : public DeviceInterface {
public:
    static constexpr const char* PCI_RESOURCE = "/sys/bus/pci/devices/0000:ad:00.0/resource0";
    static constexpr size_t BAR0_SIZE = 2 * 1024 * 1024;  // 2MB per lspci

    ~RealDevice() override {
        if (bar0_) { munmap(const_cast<uint32_t*>(bar0_), BAR0_SIZE); bar0_ = nullptr; }
        if (fd_ >= 0) { close(fd_); fd_ = -1; }
    }

    bool open() {
        fd_ = ::open(PCI_RESOURCE, O_RDWR | O_SYNC);
        if (fd_ < 0) {
            if (g_verbose) perror("RealDevice: open BAR0");
            return false;
        }
        bar0_ = static_cast<volatile uint32_t*>(
            mmap(nullptr, BAR0_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0));
        if (bar0_ == MAP_FAILED) {
            bar0_ = nullptr;
            if (g_verbose) perror("RealDevice: mmap BAR0");
            close(fd_); fd_ = -1;
            return false;
        }
        printf("[RealDevice] BAR0 mapped at %p (4KB)\n", (void*)bar0_);
        return true;
    }

    void csr_write32(uint32_t offset, uint32_t value) override {
        if (g_verbose) printf("CSR Write: 0x%03X = 0x%08X\n", offset, value);
        bar0_[offset / sizeof(uint32_t)] = value;
        asm volatile("sfence" ::: "memory");
    }

    uint32_t csr_read32(uint32_t offset) override {
        asm volatile("lfence" ::: "memory");
        uint32_t v = bar0_[offset / sizeof(uint32_t)];
        if (g_verbose) printf("CSR Read:  0x%03X = 0x%08X\n", offset, v);
        return v;
    }

    const char* name() const override { return "RealDevice (PCIe BAR0)"; }

private:
    int fd_ = -1;
    volatile uint32_t* bar0_ = nullptr;
};

// Forward declarations for simulation GEMM
struct SimGemmContext;
static void sim_execute_gemm(SimGemmContext* ctx);

struct SimGemmContext {
    uint8_t*    shared_mem;
    uint64_t    args_offset;
    uint32_t    grid[3];
    uint32_t    block[3];
    uint64_t    completion_addr;
    bool        dcoh_enabled;
    std::atomic<uint8_t>* status;
};

// --- SimulatedDevice: in-memory CSR array with GEMM execution ----------------
class SimulatedDevice : public DeviceInterface {
public:
    SimulatedDevice() {
        csr_ = new uint32_t[4096 / sizeof(uint32_t)]();
        ctx_.status = &status_;
    }

    ~SimulatedDevice() override { delete[] csr_; }

    void set_shared_memory(uint8_t* mem) { ctx_.shared_mem = mem; }

    void csr_write32(uint32_t offset, uint32_t value) override {
        if (g_verbose) printf("CSR Write: 0x%03X = 0x%08X\n", offset, value);
        csr_[offset / sizeof(uint32_t)] = value;

        if (offset == VortexCSR::LAUNCH && (value & 1)) {
            launch_kernel();
        }
    }

    uint32_t csr_read32(uint32_t offset) override {
        if (offset == VortexCSR::STATUS) return status_.load();
        uint32_t v = csr_[offset / sizeof(uint32_t)];
        if (g_verbose) printf("CSR Read:  0x%03X = 0x%08X\n", offset, v);
        return v;
    }

    const char* name() const override { return "SimulatedDevice"; }

private:
    void launch_kernel() {
        if (status_ == VortexCSR::STATUS_RUNNING) return;
        status_ = VortexCSR::STATUS_RUNNING;

        // Gather CSR state
        uint64_t args_lo = csr_[VortexCSR::KERNEL_ARGS_LO / 4];
        uint64_t args_hi = csr_[VortexCSR::KERNEL_ARGS_HI / 4];
        ctx_.args_offset = args_lo | (args_hi << 32);
        ctx_.grid[0] = csr_[VortexCSR::GRID_DIM_X / 4];
        ctx_.grid[1] = csr_[VortexCSR::GRID_DIM_Y / 4];
        ctx_.grid[2] = csr_[VortexCSR::GRID_DIM_Z / 4];
        ctx_.block[0] = csr_[VortexCSR::BLOCK_DIM_X / 4];
        ctx_.block[1] = csr_[VortexCSR::BLOCK_DIM_Y / 4];
        ctx_.block[2] = csr_[VortexCSR::BLOCK_DIM_Z / 4];

        uint64_t comp_lo = csr_[VortexCSR::COMPLETION_LO / 4];
        uint64_t comp_hi = csr_[VortexCSR::COMPLETION_HI / 4];
        ctx_.completion_addr = comp_lo | (comp_hi << 32);
        ctx_.dcoh_enabled = (csr_[VortexCSR::DCOH_ENABLE / 4] != 0);

        if (g_verbose)
            printf("[SimDev] Launching GEMM: args=0x%lx grid=(%u,%u,%u) block=(%u,%u,%u)\n",
                   ctx_.args_offset,
                   ctx_.grid[0], ctx_.grid[1], ctx_.grid[2],
                   ctx_.block[0], ctx_.block[1], ctx_.block[2]);

        std::thread([this]() { sim_execute_gemm(&ctx_); }).detach();
    }

    uint32_t* csr_ = nullptr;
    std::atomic<uint8_t> status_{VortexCSR::STATUS_IDLE};
    SimGemmContext ctx_{};
};

// Simulated GEMM kernel execution (runs in software)
static void sim_execute_gemm(SimGemmContext* ctx) {
    auto* args = reinterpret_cast<GemmKernelArgs*>(ctx->shared_mem + ctx->args_offset);

    uint32_t M = args->M, N = args->N, K = args->K;
    uint32_t lda = args->lda, ldb = args->ldb, ldc = args->ldc;
    float alpha = args->alpha, beta = args->beta;

    float* A = reinterpret_cast<float*>(ctx->shared_mem + args->A_addr);
    float* B = reinterpret_cast<float*>(ctx->shared_mem + args->B_addr);
    float* C = reinterpret_cast<float*>(ctx->shared_mem + args->C_addr);

    if (g_verbose)
        printf("[SimKernel] GEMM %ux%ux%u alpha=%.1f beta=%.1f\n", M, N, K, alpha, beta);

    // Triple-loop GEMM (simulating what Vortex threads would do)
    for (uint32_t row = 0; row < M; row++) {
        for (uint32_t col = 0; col < N; col++) {
            float acc = 0.0f;
            for (uint32_t k = 0; k < K; k++) {
                acc += A[row * lda + k] * B[k * ldb + col];
            }
            C[row * ldc + col] = alpha * acc + beta * C[row * ldc + col];
        }
    }

    // DCOH completion writeback
    if (ctx->dcoh_enabled && ctx->completion_addr) {
        auto* comp = reinterpret_cast<CompletionData*>(ctx->shared_mem + ctx->completion_addr);
        comp->status    = 0;
        comp->result    = (uint64_t)M * N * K * 2; // FLOP count
        comp->cycles    = 10000;
        comp->timestamp = 12345678;
        comp->magic     = COMPLETION_MAGIC;  // Write magic last (release semantics)
        if (g_verbose)
            printf("[SimKernel] DCOH writeback at 0x%lx\n", ctx->completion_addr);
    }

    ctx->status->store(VortexCSR::STATUS_DONE);
    if (g_verbose) printf("[SimKernel] Done\n");
}

// ============================================================================
// MemoryBackend — Coherent shared memory allocation
// ============================================================================
class MemoryBackend {
public:
    virtual ~MemoryBackend() = default;
    virtual uint8_t*    base() = 0;
    virtual size_t      size() const = 0;
    virtual uint64_t    phys_addr(void* va) { (void)va; return 0; } // VA→PA
    virtual const char* name() const = 0;
};

// --- CxlDaxMemory: /dev/dax0.0 or scan /sys/bus/dax/devices/ ----------------
class CxlDaxMemory : public MemoryBackend {
public:
    ~CxlDaxMemory() override {
        if (mem_) { munmap(mem_, size_); mem_ = nullptr; }
        if (fd_ >= 0) { close(fd_); fd_ = -1; }
    }

    bool open(size_t req_size) {
        // Try /dev/dax0.0 first
        std::string path = find_dax_device();
        if (path.empty()) return false;

        fd_ = ::open(path.c_str(), O_RDWR);
        if (fd_ < 0) {
            if (g_verbose) perror("CxlDaxMemory: open");
            return false;
        }

        size_ = req_size;
        mem_ = static_cast<uint8_t*>(
            mmap(nullptr, size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0));
        if (mem_ == MAP_FAILED) {
            mem_ = nullptr;
            if (g_verbose) perror("CxlDaxMemory: mmap");
            close(fd_); fd_ = -1;
            return false;
        }

        printf("[CxlDaxMemory] Mapped %zu bytes from %s\n", size_, path.c_str());
        return true;
    }

    uint8_t*    base() override { return mem_; }
    size_t      size() const override { return size_; }
    const char* name() const override { return "CxlDaxMemory (/dev/dax)"; }

private:
    std::string find_dax_device() {
        // Direct path first
        if (access("/dev/dax0.0", F_OK) == 0) return "/dev/dax0.0";

        // Scan /sys/bus/dax/devices/
        DIR* d = opendir("/sys/bus/dax/devices");
        if (!d) return "";
        std::string result;
        struct dirent* ent;
        while ((ent = readdir(d)) != nullptr) {
            if (ent->d_name[0] == '.') continue;
            result = std::string("/dev/") + ent->d_name;
            break;
        }
        closedir(d);
        return (result.empty() || access(result.c_str(), F_OK) != 0) ? "" : result;
    }

    int fd_ = -1;
    uint8_t* mem_ = nullptr;
    size_t size_ = 0;
};

// --- HugePageMemory: MAP_HUGETLB with /proc/self/pagemap VA→PA --------------
class HugePageMemory : public MemoryBackend {
public:
    ~HugePageMemory() override {
        if (mem_) { munmap(mem_, size_); mem_ = nullptr; }
    }

    bool open(size_t req_size) {
        // Round up to 2MB hugepage boundary
        constexpr size_t HPAGE = 2 * 1024 * 1024;
        size_ = (req_size + HPAGE - 1) & ~(HPAGE - 1);

        mem_ = static_cast<uint8_t*>(
            mmap(nullptr, size_, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0));
        if (mem_ == MAP_FAILED) {
            mem_ = nullptr;
            if (g_verbose) perror("HugePageMemory: mmap");
            return false;
        }
        // Touch all pages to populate
        memset(mem_, 0, size_);
        printf("[HugePageMemory] Allocated %zu bytes (hugepages)\n", size_);
        return true;
    }

    uint8_t*    base() override { return mem_; }
    size_t      size() const override { return size_; }
    const char* name() const override { return "HugePageMemory (MAP_HUGETLB)"; }

    uint64_t phys_addr(void* va) override {
        int fd = ::open("/proc/self/pagemap", O_RDONLY);
        if (fd < 0) return 0;
        uint64_t vaddr = reinterpret_cast<uint64_t>(va);
        uint64_t page_size = sysconf(_SC_PAGESIZE);
        uint64_t offset = (vaddr / page_size) * sizeof(uint64_t);
        uint64_t entry = 0;
        if (pread(fd, &entry, sizeof(entry), offset) != sizeof(entry)) {
            close(fd);
            return 0;
        }
        close(fd);
        if (!(entry & (1ULL << 63))) return 0; // Not present
        return (entry & ((1ULL << 55) - 1)) * page_size + (vaddr % page_size);
    }

private:
    uint8_t* mem_ = nullptr;
    size_t size_ = 0;
};

// --- SimulatedMemory: aligned_alloc fallback ---------------------------------
class SimulatedMemory : public MemoryBackend {
public:
    ~SimulatedMemory() override { free(mem_); }

    bool open(size_t req_size) {
        size_ = req_size;
        mem_ = static_cast<uint8_t*>(aligned_alloc(64, size_));
        if (!mem_) return false;
        memset(mem_, 0, size_);
        printf("[SimulatedMemory] Allocated %zu bytes (aligned_alloc)\n", size_);
        return true;
    }

    uint8_t*    base() override { return mem_; }
    size_t      size() const override { return size_; }
    const char* name() const override { return "SimulatedMemory (aligned_alloc)"; }

private:
    uint8_t* mem_ = nullptr;
    size_t size_ = 0;
};

// ============================================================================
// Shared Memory Layout
// ============================================================================
static constexpr size_t ARGS_OFFSET       = 0x0000;  // GemmKernelArgs
static constexpr size_t COMPLETION_OFFSET = 0x0040;  // CompletionData
static constexpr size_t MATRIX_BASE       = 0x1000;  // First matrix (4KB aligned)

static size_t align_up(size_t val, size_t align) {
    return (val + align - 1) & ~(align - 1);
}

struct MemoryLayout {
    size_t A_offset;
    size_t B_offset;
    size_t C_offset;
    size_t total_size;
};

static MemoryLayout compute_layout(uint32_t M, uint32_t N, uint32_t K) {
    MemoryLayout lay{};
    lay.A_offset   = MATRIX_BASE;
    size_t A_bytes = align_up((size_t)M * K * sizeof(float), 4096);
    lay.B_offset   = lay.A_offset + A_bytes;
    size_t B_bytes = align_up((size_t)K * N * sizeof(float), 4096);
    lay.C_offset   = lay.B_offset + B_bytes;
    size_t C_bytes = align_up((size_t)M * N * sizeof(float), 4096);
    lay.total_size = lay.C_offset + C_bytes;
    return lay;
}

// ============================================================================
// CPU Reference GEMM
// ============================================================================
static void cpu_gemm(const float* A, const float* B, float* C,
                     uint32_t M, uint32_t N, uint32_t K,
                     uint32_t lda, uint32_t ldb, uint32_t ldc,
                     float alpha, float beta) {
    for (uint32_t i = 0; i < M; i++) {
        for (uint32_t j = 0; j < N; j++) {
            float acc = 0.0f;
            for (uint32_t k = 0; k < K; k++) {
                acc += A[i * lda + k] * B[k * ldb + j];
            }
            C[i * ldc + j] = alpha * acc + beta * C[i * ldc + j];
        }
    }
}

// ============================================================================
// Verification
// ============================================================================
static bool verify_gemm(const float* result, const float* reference,
                        uint32_t M, uint32_t N, uint32_t ldc,
                        float abs_tol, float rel_tol) {
    int mismatches = 0;
    float max_abs_err = 0.0f;
    float max_rel_err = 0.0f;

    for (uint32_t i = 0; i < M; i++) {
        for (uint32_t j = 0; j < N; j++) {
            float r = result[i * ldc + j];
            float e = reference[i * ldc + j];
            float abs_err = fabsf(r - e);
            float rel_err = (fabsf(e) > 1e-8f) ? abs_err / fabsf(e) : abs_err;

            if (abs_err > max_abs_err) max_abs_err = abs_err;
            if (rel_err > max_rel_err) max_rel_err = rel_err;

            if (abs_err > abs_tol && rel_err > rel_tol) {
                if (mismatches < 5) {
                    printf("  MISMATCH [%u][%u]: got %.6f, expected %.6f "
                           "(abs=%.2e rel=%.2e)\n",
                           i, j, r, e, abs_err, rel_err);
                }
                mismatches++;
            }
        }
    }

    printf("  Max absolute error: %.2e\n", max_abs_err);
    printf("  Max relative error: %.2e\n", max_rel_err);
    if (mismatches > 0) {
        printf("  Total mismatches: %d / %u\n", mismatches, M * N);
    }
    return mismatches == 0;
}

// ============================================================================
// Hardware Auto-Detection and Backend Setup
// ============================================================================
struct TestContext {
    std::unique_ptr<DeviceInterface> device;
    std::unique_ptr<MemoryBackend>   memory;
    bool is_simulated;
};

static TestContext setup_backends(size_t mem_size) {
    TestContext ctx;
    ctx.is_simulated = false;

    if (!g_force_sim) {
        // Try real device + DAX
        auto real_dev = std::make_unique<RealDevice>();
        if (real_dev->open()) {
            auto dax_mem = std::make_unique<CxlDaxMemory>();
            if (dax_mem->open(mem_size)) {
                printf("[Setup] Using: %s + %s\n", real_dev->name(), dax_mem->name());
                ctx.device = std::move(real_dev);
                ctx.memory = std::move(dax_mem);
                return ctx;
            }
            // Try real device + hugepages
            auto huge_mem = std::make_unique<HugePageMemory>();
            if (huge_mem->open(mem_size)) {
                printf("[Setup] Using: %s + %s\n", real_dev->name(), huge_mem->name());
                ctx.device = std::move(real_dev);
                ctx.memory = std::move(huge_mem);
                return ctx;
            }
        }
        if (g_verbose) printf("[Setup] Real device not available, falling back to simulation\n");
    }

    // Full simulation
    ctx.is_simulated = true;
    auto sim_dev = std::make_unique<SimulatedDevice>();
    auto sim_mem = std::make_unique<SimulatedMemory>();
    if (!sim_mem->open(mem_size)) {
        fprintf(stderr, "FATAL: Cannot allocate simulated memory\n");
        exit(1);
    }
    sim_dev->set_shared_memory(sim_mem->base());
    printf("[Setup] Using: %s + %s\n", sim_dev->name(), sim_mem->name());
    ctx.device = std::move(sim_dev);
    ctx.memory = std::move(sim_mem);
    return ctx;
}

// ============================================================================
// Kernel Launch Helper
// ============================================================================
static bool launch_and_wait(DeviceInterface* dev, MemoryBackend* mem,
                            uint64_t args_addr, uint64_t completion_addr,
                            uint32_t grid_x, uint32_t grid_y,
                            uint32_t block_x, uint32_t block_y,
                            uint32_t timeout_ms = 10000) {
    // Clear completion
    auto* comp = reinterpret_cast<CompletionData*>(mem->base() + completion_addr);
    memset(comp, 0, sizeof(CompletionData));

    // Configure kernel
    dev->csr_write64(VortexCSR::KERNEL_ADDR_LO, 0x80000000ULL); // Kernel code addr
    dev->csr_write64(VortexCSR::KERNEL_ARGS_LO, args_addr);
    dev->csr_write32(VortexCSR::GRID_DIM_X,  grid_x);
    dev->csr_write32(VortexCSR::GRID_DIM_Y,  grid_y);
    dev->csr_write32(VortexCSR::GRID_DIM_Z,  1);
    dev->csr_write32(VortexCSR::BLOCK_DIM_X, block_x);
    dev->csr_write32(VortexCSR::BLOCK_DIM_Y, block_y);
    dev->csr_write32(VortexCSR::BLOCK_DIM_Z, 1);

    // Configure DCOH completion
    dev->csr_write64(VortexCSR::COMPLETION_LO, completion_addr);
    dev->csr_write32(VortexCSR::DCOH_ENABLE, 1);

    // Launch
    dev->csr_write32(VortexCSR::LAUNCH, 1);

    // Wait for DCOH completion
    auto start = std::chrono::steady_clock::now();
    while (true) {
        if (comp->magic == COMPLETION_MAGIC) {
            if (g_verbose) {
                printf("  Completion: status=%u cycles=%lu result=0x%lx\n",
                       comp->status, comp->cycles, comp->result);
            }
            return comp->status == 0;
        }

        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now() - start);
        if (elapsed.count() >= timeout_ms) {
            printf("  TIMEOUT waiting for kernel completion (%u ms)\n", timeout_ms);
            return false;
        }
        std::this_thread::sleep_for(std::chrono::microseconds(100));
    }
}

// ============================================================================
// Test Cases
// ============================================================================

// Test 1: Small smoke test (4x4)
static bool test_small_smoke(DeviceInterface* dev, MemoryBackend* mem) {
    printf("\n========================================\n");
    printf("Test 1: Small Smoke Test (4x4 GEMM)\n");
    printf("========================================\n");

    constexpr uint32_t M = 4, N = 4, K = 4;
    constexpr float alpha = 1.0f, beta = 0.0f;

    auto lay = compute_layout(M, N, K);
    uint8_t* base = mem->base();

    // Fill A and B with known values
    // A = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
    float* A = reinterpret_cast<float*>(base + lay.A_offset);
    float* B = reinterpret_cast<float*>(base + lay.B_offset);
    float* C = reinterpret_cast<float*>(base + lay.C_offset);

    for (uint32_t i = 0; i < M * K; i++) A[i] = (float)(i + 1);
    for (uint32_t i = 0; i < K * N; i++) B[i] = (float)(i + 1);
    memset(C, 0, M * N * sizeof(float));

    // Set up kernel args
    auto* args = reinterpret_cast<GemmKernelArgs*>(base + ARGS_OFFSET);
    args->A_addr = lay.A_offset;
    args->B_addr = lay.B_offset;
    args->C_addr = lay.C_offset;
    args->M = M; args->N = N; args->K = K;
    args->lda = K; args->ldb = N; args->ldc = N;
    args->alpha = alpha; args->beta = beta;
    args->completion_addr = COMPLETION_OFFSET;

    // Grid: ceil(4/8)=1, ceil(4/4)=1 → 1 block of 32 threads
    bool ok = launch_and_wait(dev, mem, ARGS_OFFSET, COMPLETION_OFFSET, 1, 1, 8, 4);
    if (!ok) { printf("Test 1 Result: FAIL (launch failed)\n"); return false; }

    // CPU reference
    float ref[M * N];
    float A_copy[M * K], B_copy[K * N];
    memcpy(A_copy, A, sizeof(A_copy));
    memcpy(B_copy, B, sizeof(B_copy));
    memset(ref, 0, sizeof(ref));
    cpu_gemm(A_copy, B_copy, ref, M, N, K, K, N, N, alpha, beta);

    bool pass = verify_gemm(C, ref, M, N, N, 1e-3f, 1e-2f);
    printf("Test 1 Result: %s\n", pass ? "PASS" : "FAIL");
    return pass;
}

// Test 2: Default GEMM (NxN, random floats)
static bool test_default_gemm(DeviceInterface* dev, MemoryBackend* mem,
                              uint32_t dim, float alpha, float beta_val) {
    printf("\n========================================\n");
    printf("Test 2: Default GEMM (%ux%u, alpha=%.1f, beta=%.1f)\n",
           dim, dim, alpha, beta_val);
    printf("========================================\n");

    uint32_t M = dim, N = dim, K = dim;
    auto lay = compute_layout(M, N, K);
    uint8_t* base = mem->base();

    float* A = reinterpret_cast<float*>(base + lay.A_offset);
    float* B = reinterpret_cast<float*>(base + lay.B_offset);
    float* C = reinterpret_cast<float*>(base + lay.C_offset);

    // Random fill
    std::mt19937 rng(42);
    std::uniform_real_distribution<float> dist(-1.0f, 1.0f);

    for (uint32_t i = 0; i < M * K; i++) A[i] = dist(rng);
    for (uint32_t i = 0; i < K * N; i++) B[i] = dist(rng);
    memset(C, 0, M * N * sizeof(float));

    // Keep copies for CPU reference
    std::unique_ptr<float[]> A_copy(new float[M * K]);
    std::unique_ptr<float[]> B_copy(new float[K * N]);
    memcpy(A_copy.get(), A, M * K * sizeof(float));
    memcpy(B_copy.get(), B, K * N * sizeof(float));

    // Setup args
    auto* args = reinterpret_cast<GemmKernelArgs*>(base + ARGS_OFFSET);
    args->A_addr = lay.A_offset;
    args->B_addr = lay.B_offset;
    args->C_addr = lay.C_offset;
    args->M = M; args->N = N; args->K = K;
    args->lda = K; args->ldb = N; args->ldc = N;
    args->alpha = alpha; args->beta = beta_val;
    args->completion_addr = COMPLETION_OFFSET;

    // Grid/block: block(8,4) = 32 threads/warp
    uint32_t grid_x = (N + 7) / 8;
    uint32_t grid_y = (M + 3) / 4;
    printf("  Grid: (%u, %u, 1)  Block: (8, 4, 1)  Threads: %u\n",
           grid_x, grid_y, grid_x * grid_y * 32);

    auto t0 = std::chrono::steady_clock::now();
    bool ok = launch_and_wait(dev, mem, ARGS_OFFSET, COMPLETION_OFFSET,
                              grid_x, grid_y, 8, 4);
    auto t1 = std::chrono::steady_clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    printf("  Kernel time: %.2f ms\n", ms);

    if (!ok) { printf("Test 2 Result: FAIL (launch failed)\n"); return false; }

    // CPU reference
    std::unique_ptr<float[]> ref(new float[M * N]());
    cpu_gemm(A_copy.get(), B_copy.get(), ref.get(), M, N, K, K, N, N, alpha, beta_val);

    bool pass = verify_gemm(C, ref.get(), M, N, N, 1e-3f, 1e-2f);
    printf("Test 2 Result: %s\n", pass ? "PASS" : "FAIL");
    return pass;
}

// Test 3: Accumulate path (beta=1.0, C = A*B + C)
static bool test_accumulate(DeviceInterface* dev, MemoryBackend* mem, uint32_t dim) {
    printf("\n========================================\n");
    printf("Test 3: Accumulate Path (%ux%u, beta=1.0)\n", dim, dim);
    printf("========================================\n");

    uint32_t M = dim, N = dim, K = dim;
    constexpr float alpha = 1.0f, beta = 1.0f;
    auto lay = compute_layout(M, N, K);
    uint8_t* base = mem->base();

    float* A = reinterpret_cast<float*>(base + lay.A_offset);
    float* B = reinterpret_cast<float*>(base + lay.B_offset);
    float* C = reinterpret_cast<float*>(base + lay.C_offset);

    std::mt19937 rng(123);
    std::uniform_real_distribution<float> dist(-1.0f, 1.0f);

    for (uint32_t i = 0; i < M * K; i++) A[i] = dist(rng);
    for (uint32_t i = 0; i < K * N; i++) B[i] = dist(rng);
    // Pre-fill C with values to accumulate onto
    for (uint32_t i = 0; i < M * N; i++) C[i] = dist(rng);

    // Keep copies
    std::unique_ptr<float[]> A_copy(new float[M * K]);
    std::unique_ptr<float[]> B_copy(new float[K * N]);
    std::unique_ptr<float[]> C_init(new float[M * N]);
    memcpy(A_copy.get(), A, M * K * sizeof(float));
    memcpy(B_copy.get(), B, K * N * sizeof(float));
    memcpy(C_init.get(), C, M * N * sizeof(float));

    auto* args = reinterpret_cast<GemmKernelArgs*>(base + ARGS_OFFSET);
    args->A_addr = lay.A_offset;
    args->B_addr = lay.B_offset;
    args->C_addr = lay.C_offset;
    args->M = M; args->N = N; args->K = K;
    args->lda = K; args->ldb = N; args->ldc = N;
    args->alpha = alpha; args->beta = beta;
    args->completion_addr = COMPLETION_OFFSET;

    uint32_t grid_x = (N + 7) / 8;
    uint32_t grid_y = (M + 3) / 4;

    bool ok = launch_and_wait(dev, mem, ARGS_OFFSET, COMPLETION_OFFSET,
                              grid_x, grid_y, 8, 4);
    if (!ok) { printf("Test 3 Result: FAIL (launch failed)\n"); return false; }

    // CPU reference: C_ref = A*B + C_init
    std::unique_ptr<float[]> ref(new float[M * N]);
    memcpy(ref.get(), C_init.get(), M * N * sizeof(float));
    cpu_gemm(A_copy.get(), B_copy.get(), ref.get(), M, N, K, K, N, N, alpha, beta);

    bool pass = verify_gemm(C, ref.get(), M, N, N, 1e-3f, 1e-2f);
    printf("Test 3 Result: %s\n", pass ? "PASS" : "FAIL");
    return pass;
}

// Test 4: Multiple sequential launches (different completion addresses)
static bool test_sequential_launches(DeviceInterface* dev, MemoryBackend* mem) {
    printf("\n========================================\n");
    printf("Test 4: Multiple Sequential Launches\n");
    printf("========================================\n");

    constexpr uint32_t M = 8, N = 8, K = 8;
    constexpr float alpha = 1.0f, beta = 0.0f;
    constexpr int NUM_LAUNCHES = 3;

    auto lay = compute_layout(M, N, K);
    uint8_t* base = mem->base();

    bool all_pass = true;
    std::mt19937 rng(999);
    std::uniform_real_distribution<float> dist(-2.0f, 2.0f);

    for (int launch = 0; launch < NUM_LAUNCHES; launch++) {
        printf("\n--- Launch %d ---\n", launch);

        // Use different completion addresses (staggered by 64 bytes)
        uint64_t comp_addr = COMPLETION_OFFSET + (uint64_t)launch * CACHE_LINE_SIZE;

        float* A = reinterpret_cast<float*>(base + lay.A_offset);
        float* B = reinterpret_cast<float*>(base + lay.B_offset);
        float* C = reinterpret_cast<float*>(base + lay.C_offset);

        for (uint32_t i = 0; i < M * K; i++) A[i] = dist(rng);
        for (uint32_t i = 0; i < K * N; i++) B[i] = dist(rng);
        memset(C, 0, M * N * sizeof(float));

        std::unique_ptr<float[]> A_copy(new float[M * K]);
        std::unique_ptr<float[]> B_copy(new float[K * N]);
        memcpy(A_copy.get(), A, M * K * sizeof(float));
        memcpy(B_copy.get(), B, K * N * sizeof(float));

        auto* args = reinterpret_cast<GemmKernelArgs*>(base + ARGS_OFFSET);
        args->A_addr = lay.A_offset;
        args->B_addr = lay.B_offset;
        args->C_addr = lay.C_offset;
        args->M = M; args->N = N; args->K = K;
        args->lda = K; args->ldb = N; args->ldc = N;
        args->alpha = alpha; args->beta = beta;
        args->completion_addr = comp_addr;

        bool ok = launch_and_wait(dev, mem, ARGS_OFFSET, comp_addr, 1, 2, 8, 4);
        if (!ok) {
            printf("  Launch %d: FAIL (launch failed)\n", launch);
            all_pass = false;
            continue;
        }

        std::unique_ptr<float[]> ref(new float[M * N]());
        cpu_gemm(A_copy.get(), B_copy.get(), ref.get(), M, N, K, K, N, N, alpha, beta);

        bool pass = verify_gemm(C, ref.get(), M, N, N, 1e-3f, 1e-2f);
        printf("  Launch %d: %s\n", launch, pass ? "PASS" : "FAIL");
        if (!pass) all_pass = false;
    }

    printf("Test 4 Result: %s\n", all_pass ? "PASS" : "FAIL");
    return all_pass;
}

// ============================================================================
// Main
// ============================================================================
int main(int argc, char** argv) {
    // Parse CLI
    uint32_t dim = 64;
    float alpha = 1.0f, beta = 0.0f;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--dim" && i + 1 < argc)     { dim = atoi(argv[++i]); }
        else if (arg == "--alpha" && i + 1 < argc) { alpha = atof(argv[++i]); }
        else if (arg == "--beta" && i + 1 < argc)  { beta = atof(argv[++i]); }
        else if (arg == "--kernel" && i + 1 < argc) { g_kernel_path = argv[++i]; }
        else if (arg == "--sim")     { g_force_sim = true; }
        else if (arg == "--verbose") { g_verbose = true; }
        else {
            fprintf(stderr, "Usage: %s [--dim N] [--alpha F] [--beta F] "
                    "[--kernel <path>] [--sim] [--verbose]\n", argv[0]);
            return 1;
        }
    }

    printf("========================================\n");
    printf("GEMM Coherent Shared Memory Test\n");
    printf("CXL Type2 Device — Vortex GPU (RV64)\n");
    printf("========================================\n");
    printf("Parameters: dim=%u alpha=%.2f beta=%.2f %s\n",
           dim, alpha, beta, g_force_sim ? "(forced sim)" : "(auto-detect)");

    // Compute memory needed for largest test (the dim x dim GEMM)
    auto max_lay = compute_layout(dim, dim, dim);
    // Extra space for multiple completion addresses in test 4
    size_t total_mem = max_lay.total_size + 4096;

    auto ctx = setup_backends(total_mem);

    // Wire up simulated device's shared memory pointer
    if (ctx.is_simulated) {
        static_cast<SimulatedDevice*>(ctx.device.get())
            ->set_shared_memory(ctx.memory->base());
    }

    printf("Device:  %s\n", ctx.device->name());
    printf("Memory:  %s (%zu bytes)\n", ctx.memory->name(), ctx.memory->size());

    // Load kernel binary if provided
    if (g_kernel_path) {
        size_t loaded = load_kernel_binary(
            g_kernel_path, ctx.memory->base(),
            KERNEL_CODE_OFFSET, ctx.memory->size(), g_verbose);
        if (loaded > 0) {
            printf("Kernel:  Loaded %zu bytes from '%s' at 0x%lx\n",
                   loaded, g_kernel_path, (unsigned long)KERNEL_CODE_OFFSET);
            if (!verify_kernel_loaded(ctx.memory->base(), KERNEL_CODE_OFFSET)) {
                fprintf(stderr, "WARNING: Kernel binary may be invalid\n");
            }
        } else {
            fprintf(stderr, "WARNING: Failed to load kernel binary '%s', "
                    "continuing with software simulation\n", g_kernel_path);
        }
    }

    int pass = 0, fail = 0;

    auto run = [&](bool result) { if (result) pass++; else fail++; };

    // Test 1: Small smoke test
    run(test_small_smoke(ctx.device.get(), ctx.memory.get()));

    // Test 2: Default GEMM
    run(test_default_gemm(ctx.device.get(), ctx.memory.get(), dim, alpha, beta));

    // Test 3: Accumulate path (always uses beta=1.0)
    run(test_accumulate(ctx.device.get(), ctx.memory.get(), std::min(dim, 32u)));

    // Test 4: Multiple sequential launches
    run(test_sequential_launches(ctx.device.get(), ctx.memory.get()));

    // Summary
    printf("\n========================================\n");
    printf("Summary: %d passed, %d failed (of %d)\n", pass, fail, pass + fail);
    printf("========================================\n");

    return fail > 0 ? 1 : 0;
}
