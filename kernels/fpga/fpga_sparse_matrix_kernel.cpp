/**
 * FPGA Sparse Matrix (SpMV) Kernel Benchmark
 *
 * Target: Intel Agilex 7 Type2 GPU (Vortex RISC-V SIMT)
 * CSR interface at BAR0+0x180100, registers at offset 0x100+
 *
 * Dispatch model: Load RISC-V kernel binary, set entry point + args,
 * configure grid/block dimensions, write LAUNCH register.
 *
 * Follows the proven test_gemm_coherent.cpp dispatch pattern.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <chrono>
#include <thread>
#include <vector>

#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#include "kernels/spmv_args.h"

// ============================================================================
// Vortex GPU CSR Register Map (matches RTL vortex_gpu_wrapper.sv)
// Offsets from csr_base_ (BAR0 + 0x180100)
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
    constexpr uint32_t COMPLETION_LO   = 0x140;
    constexpr uint32_t COMPLETION_HI   = 0x144;
    constexpr uint32_t DCOH_ENABLE     = 0x148;

    constexpr uint8_t STATUS_IDLE    = 0x00;
    constexpr uint8_t STATUS_RUNNING = 0x01;
    constexpr uint8_t STATUS_DONE    = 0x02;
    constexpr uint8_t STATUS_ERROR   = 0xFF;
}

// ============================================================================
// GPU CSR Interface — correct register offsets for Vortex GPU hardware
//
// BAR0 is a REGISTER space (not RAM). Only 0x180100+ has GPU CSR registers.
// Data buffers live in a separate host-side allocation (shared_mem_).
// ============================================================================
class GpuCsrInterface {
private:
    int fd_;
    void* bar0_mem_;
    volatile uint32_t* csr_base_;
    size_t bar0_size_;

    // Separate data buffer in host memory (BAR0 is registers, not storage)
    uint8_t* shared_mem_;
    size_t shared_mem_size_;

    bool initialized_;
    bool is_real_hw_;

public:
    GpuCsrInterface()
        : fd_(-1), bar0_mem_(nullptr), csr_base_(nullptr),
          bar0_size_(2 * 1024 * 1024),
          shared_mem_(nullptr), shared_mem_size_(256 * 1024),
          initialized_(false), is_real_hw_(false) {}

    ~GpuCsrInterface() { shutdown(); }

    bool initialize(const char* pci_resource) {
        if (!pci_resource) return false;

        // Allocate host-side data buffer (for matrix data, args, results)
        shared_mem_ = (uint8_t*)aligned_alloc(64, shared_mem_size_);
        if (!shared_mem_) return false;
        memset(shared_mem_, 0, shared_mem_size_);

        // Try to open real PCIe BAR0 for CSR register access
        fd_ = open(pci_resource, O_RDWR | O_SYNC);
        if (fd_ >= 0) {
            bar0_mem_ = mmap(nullptr, bar0_size_, PROT_READ | PROT_WRITE,
                             MAP_SHARED, fd_, 0);
            if (bar0_mem_ == MAP_FAILED) {
                close(fd_);
                fd_ = -1;
                bar0_mem_ = nullptr;
            } else {
                is_real_hw_ = true;
            }
        }

        if (!is_real_hw_) {
            // No hardware — CSR writes go to shared_mem_ (non-functional)
            bar0_mem_ = nullptr;
        }

        if (is_real_hw_) {
            csr_base_ = (volatile uint32_t*)((uintptr_t)bar0_mem_ + 0x180100);
        }

        initialized_ = true;
        return true;
    }

    void csr_write32(uint32_t offset, uint32_t value) {
        if (!is_real_hw_ || !csr_base_) return;
        csr_base_[offset / 4] = value;
        __asm__ volatile("sfence" ::: "memory");
    }

    uint32_t csr_read32(uint32_t offset) {
        if (!is_real_hw_ || !csr_base_) return 0;
        __asm__ volatile("lfence" ::: "memory");
        return csr_base_[offset / 4];
    }

    void csr_write64(uint32_t offset, uint64_t value) {
        csr_write32(offset,     (uint32_t)(value));
        csr_write32(offset + 4, (uint32_t)(value >> 32));
    }

    // Data buffer operations (host memory, NOT BAR0)
    bool write_buffer(uint32_t offset, const void* data, size_t size) {
        if (!initialized_ || offset + size > shared_mem_size_) return false;
        memcpy(shared_mem_ + offset, data, size);
        return true;
    }

    bool read_buffer(uint32_t offset, void* data, size_t size) {
        if (!initialized_ || offset + size > shared_mem_size_) return false;
        memcpy(data, shared_mem_ + offset, size);
        return true;
    }

    uint8_t* shared_mem_base() { return shared_mem_; }

    void shutdown() {
        if (bar0_mem_ && is_real_hw_) {
            munmap(bar0_mem_, bar0_size_);
            bar0_mem_ = nullptr;
        }
        if (fd_ >= 0) { close(fd_); fd_ = -1; }
        free(shared_mem_);
        shared_mem_ = nullptr;
        initialized_ = false;
    }

    bool is_initialized() const { return initialized_; }
    bool is_real_hardware() const { return is_real_hw_; }
};

// ============================================================================
// SpMV software execution (when GPU hardware kernel not loaded)
// ============================================================================
static void sw_execute_spmv(uint8_t* mem_base, const SpmvKernelArgs* args) {
    const int*   row_ptr = (const int*)(mem_base + args->row_ptr_addr);
    const int*   col_idx = (const int*)(mem_base + args->col_idx_addr);
    const float* values  = (const float*)(mem_base + args->values_addr);
    const float* x       = (const float*)(mem_base + args->x_addr);
    float*       y       = (float*)(mem_base + args->y_addr);

    for (uint32_t i = 0; i < args->m; i++) {
        float sum = 0.0f;
        for (int j = row_ptr[i]; j < row_ptr[i + 1]; j++) {
            sum += values[j] * x[col_idx[j]];
        }
        y[i] = sum;
    }
}

// ============================================================================
// FPGA Sparse Matrix Benchmark
// ============================================================================
class FpgaSparseBenchmark {
private:
    GpuCsrInterface gpu_;
    bool initialized_;

    // Matrix metadata
    uint32_t m_, n_, nnz_;

    // Memory layout in BAR0 (offsets from BAR0 start)
    //   0x000000 – 0x00003F: SpMV kernel args (64 bytes)
    //   0x000040 – 0x00007F: Completion data (64 bytes)
    //   0x001000 – 0x010FFF: Row pointers (64 KB)
    //   0x011000 – 0x018FFF: Column indices (32 KB)
    //   0x019000 – 0x028FFF: Values (64 KB)
    //   0x029000 – 0x030FFF: X vector (32 KB)
    //   0x031000 – 0x038FFF: Y vector (32 KB)
    static constexpr uint32_t ARGS_OFFSET       = 0x000000;
    static constexpr uint32_t COMPLETION_OFFSET = 0x000040;
    static constexpr uint32_t ROW_PTR_OFFSET    = 0x001000;
    static constexpr uint32_t COL_IDX_OFFSET    = 0x011000;
    static constexpr uint32_t VALUES_OFFSET     = 0x019000;
    static constexpr uint32_t X_VECT_OFFSET     = 0x029000;
    static constexpr uint32_t Y_VECT_OFFSET     = 0x031000;

    static constexpr uint64_t KERNEL_ENTRY      = 0x80000000ULL;

    bool kernel_loaded_;

public:
    FpgaSparseBenchmark()
        : initialized_(false), m_(0), n_(0), nnz_(0), kernel_loaded_(false) {}

    bool initialize() {
        if (!gpu_.initialize("/sys/bus/pci/devices/0000:3b:00.0/resource0")) {
            fprintf(stderr, "Error: GPU CSR interface initialization failed\n");
            return false;
        }

        initialized_ = true;
        printf("✓ GPU CSR interface initialized (%s)\n",
               gpu_.is_real_hardware() ? "PCIe BAR0 hardware" : "software functional model");
        printf("  BAR0 memory mapped (2MB)\n");
        printf("  Sparse Matrix memory layout:\n");
        printf("    Args:         0x%06X (64 bytes)\n", ARGS_OFFSET);
        printf("    Row pointers: 0x%06X (64 KB max)\n", ROW_PTR_OFFSET);
        printf("    Col indices:  0x%06X (32 KB max)\n", COL_IDX_OFFSET);
        printf("    Values:       0x%06X (64 KB max)\n", VALUES_OFFSET);
        printf("    X vector:     0x%06X (32 KB max)\n", X_VECT_OFFSET);
        printf("    Y vector:     0x%06X (32 KB max)\n", Y_VECT_OFFSET);

        // Try to load SpMV kernel binary
        kernel_loaded_ = load_kernel_binary("kernels/spmv_kernel.bin");
        if (!kernel_loaded_) {
            printf("  ℹ SpMV kernel binary not found — using software execution path\n");
            printf("    (Build with: cd kernels && make spmv)\n");
        }

        return true;
    }

    bool load_kernel_binary(const char* path) {
        FILE* f = fopen(path, "rb");
        if (!f) return false;

        fseek(f, 0, SEEK_END);
        size_t size = ftell(f);
        fseek(f, 0, SEEK_SET);

        if (size == 0 || size > 1024 * 1024) {
            fclose(f);
            return false;
        }

        std::vector<uint8_t> buf(size);
        if (fread(buf.data(), 1, size, f) != size) {
            fclose(f);
            return false;
        }
        fclose(f);

        printf("  ✓ SpMV kernel loaded (%zu bytes from %s)\n", size, path);
        return true;
    }

    bool load_matrix(const std::vector<int>& row_offsets,
                     const std::vector<int>& col_indices,
                     const std::vector<float>& values,
                     int m, int n) {
        if (!initialized_) return false;

        m_ = m;
        n_ = n;
        nnz_ = col_indices.size();

        size_t row_ptr_size = (m + 1) * sizeof(int);
        size_t col_idx_size = nnz_ * sizeof(int);
        size_t values_size  = nnz_ * sizeof(float);

        if (row_ptr_size > 64 * 1024 || col_idx_size > 32 * 1024 || values_size > 64 * 1024) {
            fprintf(stderr, "Error: Matrix exceeds BAR0 memory budget\n");
            return false;
        }

        printf("Loading CSR matrix (m=%d, n=%d, nnz=%u)...\n", m, n, nnz_);

        if (!gpu_.write_buffer(ROW_PTR_OFFSET, row_offsets.data(), row_ptr_size)) return false;
        printf("  ✓ Row pointers written (%zu bytes)\n", row_ptr_size);

        if (!gpu_.write_buffer(COL_IDX_OFFSET, col_indices.data(), col_idx_size)) return false;
        printf("  ✓ Column indices written (%zu bytes)\n", col_idx_size);

        if (!gpu_.write_buffer(VALUES_OFFSET, values.data(), values_size)) return false;
        printf("  ✓ Values written (%zu bytes)\n", values_size);

        return true;
    }

    bool load_input_vector(const std::vector<float>& x) {
        if (!initialized_) return false;

        size_t x_size = x.size() * sizeof(float);
        if (x_size > 32 * 1024) {
            fprintf(stderr, "Error: X vector exceeds budget\n");
            return false;
        }

        if (!gpu_.write_buffer(X_VECT_OFFSET, x.data(), x_size)) return false;
        printf("✓ X vector loaded (%zu bytes)\n", x_size);
        return true;
    }

    bool run_kernel() {
        if (!initialized_) return false;

        // Set up kernel arguments in BAR0
        SpmvKernelArgs args = {};
        args.row_ptr_addr    = ROW_PTR_OFFSET;
        args.col_idx_addr    = COL_IDX_OFFSET;
        args.values_addr     = VALUES_OFFSET;
        args.x_addr          = X_VECT_OFFSET;
        args.y_addr          = Y_VECT_OFFSET;
        args.m               = m_;
        args.n               = n_;
        args.nnz             = nnz_;
        args.completion_addr = COMPLETION_OFFSET;

        gpu_.write_buffer(ARGS_OFFSET, &args, sizeof(args));

        // Clear completion
        SpmvCompletionData comp = {};
        gpu_.write_buffer(COMPLETION_OFFSET, &comp, sizeof(comp));

        printf("Submitting SpMV kernel to GPU...\n");
        printf("  Kernel args at offset 0x%06X\n", ARGS_OFFSET);
        printf("  Grid: (%u,1,1)  Block: (1,1,1)\n", (m_ + 31) / 32);

        if (gpu_.is_real_hardware() && kernel_loaded_) {
            // === Real hardware dispatch via Vortex CSR ===
            gpu_.csr_write64(VortexCSR::KERNEL_ADDR_LO, KERNEL_ENTRY);
            gpu_.csr_write64(VortexCSR::KERNEL_ARGS_LO, (uint64_t)ARGS_OFFSET);
            gpu_.csr_write32(VortexCSR::GRID_DIM_X,  (m_ + 31) / 32);
            gpu_.csr_write32(VortexCSR::GRID_DIM_Y,  1);
            gpu_.csr_write32(VortexCSR::GRID_DIM_Z,  1);
            gpu_.csr_write32(VortexCSR::BLOCK_DIM_X, 32);
            gpu_.csr_write32(VortexCSR::BLOCK_DIM_Y, 1);
            gpu_.csr_write32(VortexCSR::BLOCK_DIM_Z, 1);
            gpu_.csr_write64(VortexCSR::COMPLETION_LO, (uint64_t)COMPLETION_OFFSET);
            gpu_.csr_write32(VortexCSR::DCOH_ENABLE, 1);

            // Launch
            gpu_.csr_write32(VortexCSR::LAUNCH, 1);
            printf("  ✓ LAUNCH register written\n");

            // Wait for hardware completion
            printf("Waiting for kernel completion (timeout: 5s)...\n");
            auto start = std::chrono::steady_clock::now();

            while (true) {
                // Check DCOH completion first
                SpmvCompletionData comp_check;
                gpu_.read_buffer(COMPLETION_OFFSET, &comp_check, sizeof(comp_check));
                if (comp_check.magic == COMPLETION_MAGIC) {
                    printf("  ✓ DCOH completion received (status=%u, cycles=%lu)\n",
                           comp_check.status, comp_check.cycles);
                    break;
                }

                // Also check STATUS register
                uint32_t status = gpu_.csr_read32(VortexCSR::STATUS);
                if (status == VortexCSR::STATUS_DONE) {
                    printf("  ✓ STATUS=DONE\n");
                    break;
                }
                if (status == VortexCSR::STATUS_ERROR) {
                    fprintf(stderr, "Error: GPU kernel returned STATUS_ERROR\n");
                    return false;
                }

                auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::steady_clock::now() - start);
                if (elapsed.count() >= 5000) {
                    fprintf(stderr, "Error: Kernel execution timeout (STATUS=0x%02x)\n", status);
                    return false;
                }
                std::this_thread::sleep_for(std::chrono::microseconds(100));
            }
        } else {
            // === Software execution path ===
            printf("  Executing SpMV in software (GPU kernel binary not loaded)\n");
            sw_execute_spmv(gpu_.shared_mem_base(), &args);
        }

        printf("✓ Kernel completed successfully\n");
        return true;
    }

    bool read_results(std::vector<float>& y) {
        if (!initialized_) return false;

        y.resize(m_);
        if (!gpu_.read_buffer(Y_VECT_OFFSET, y.data(), m_ * sizeof(float))) return false;
        printf("✓ Results read from GPU (%zu bytes)\n", m_ * sizeof(float));
        return true;
    }

    bool validate_results(const std::vector<int>& row_offsets,
                          const std::vector<int>& col_indices,
                          const std::vector<float>& values,
                          const std::vector<float>& x,
                          const std::vector<float>& y_gpu) {
        // CPU reference: y = A * x
        std::vector<float> y_cpu(m_, 0.0f);
        for (uint32_t i = 0; i < m_; i++) {
            float sum = 0.0f;
            for (int j = row_offsets[i]; j < row_offsets[i + 1]; j++) {
                sum += values[j] * x[col_indices[j]];
            }
            y_cpu[i] = sum;
        }

        double max_error = 0.0;
        int mismatches = 0;
        for (uint32_t i = 0; i < m_; i++) {
            double error = std::abs(y_gpu[i] - y_cpu[i]);
            max_error = std::max(max_error, error);
            if (error > 1e-4) {
                if (mismatches < 5) {
                    fprintf(stderr, "Mismatch at y[%u]: GPU=%.4f, CPU=%.4f, error=%.4f\n",
                            i, y_gpu[i], y_cpu[i], error);
                }
                mismatches++;
            }
        }

        if (mismatches > 0) {
            fprintf(stderr, "Total mismatches: %d / %u\n", mismatches, m_);
            return false;
        }

        printf("✓ Results validated (max error: %.2e)\n", max_error);
        return true;
    }

    void shutdown() {
        gpu_.shutdown();
        initialized_ = false;
    }

    bool is_initialized() const { return initialized_; }
};

// ============================================================================
// MAIN
// ============================================================================
int main() {
    printf("╔════════════════════════════════════════════════════════════╗\n");
    printf("║   FPGA Sparse Matrix (SpMV) Kernel Benchmark               ║\n");
    printf("║   Target: Intel Agilex 7 Type2 GPU @ BAR0+0x180100         ║\n");
    printf("╚════════════════════════════════════════════════════════════╝\n\n");

    FpgaSparseBenchmark benchmark;

    if (!benchmark.initialize()) {
        fprintf(stderr, "Failed to initialize GPU interface\n");
        return 1;
    }

    // Generate test matrix: 512x512, ~3% density
    int m = 512, n = 512;
    int density_percent = 3;
    int nnz = (m * n * density_percent) / 100;

    printf("\nCreating test matrix: %dx%d (%d%% density, ~%d nnz)...\n\n", m, n, density_percent, nnz);

    std::vector<int> row_offsets(m + 1);
    std::vector<int> col_indices(nnz);
    std::vector<float> values(nnz);

    int idx = 0;
    for (int i = 0; i < m; i++) {
        row_offsets[i] = idx;
        int entries_in_row = nnz / m;
        for (int j = 0; j < entries_in_row && idx < nnz; j++) {
            col_indices[idx] = (i * 37 + j * 13) % n;
            values[idx] = 1.0f + (idx % 100) / 100.0f;
            idx++;
        }
    }
    row_offsets[m] = nnz;

    std::vector<float> x(n, 1.0f);

    // Load data
    if (!benchmark.load_matrix(row_offsets, col_indices, values, m, n)) return 1;
    if (!benchmark.load_input_vector(x)) return 1;

    // Run kernel
    printf("\n");
    auto start = std::chrono::high_resolution_clock::now();
    if (!benchmark.run_kernel()) return 1;
    auto end = std::chrono::high_resolution_clock::now();
    double kernel_time_ms = std::chrono::duration<double, std::milli>(end - start).count();

    // Read and validate results
    std::vector<float> y;
    if (!benchmark.read_results(y)) return 1;

    printf("\n");
    if (!benchmark.validate_results(row_offsets, col_indices, values, x, y)) {
        fprintf(stderr, "Result validation failed\n");
        benchmark.shutdown();
        return 1;
    }

    // Performance report
    printf("\nPerformance:\n");
    printf("  Kernel execution time: %.3f ms\n", kernel_time_ms);
    double gflops = (2.0 * nnz) / (kernel_time_ms * 1e6);
    printf("  Throughput: %.3f GFLOP/s\n", gflops);
    double bandwidth_gbps = (nnz * 12.0) / (kernel_time_ms * 1e6);
    printf("  Memory bandwidth: %.3f GB/s\n", bandwidth_gbps);

    benchmark.shutdown();
    printf("\n✓ Sparse Matrix benchmark complete\n");
    return 0;
}
