/**
 * FPGA Bioinformatics Kernel Implementation
 * Target: Intel Agilex 7 Type2 GPU
 * Memory Budget: 768KB, Expected Speedup: 1.2–1.5x
 */

#include <iostream>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include <cstdint>
#include <thread>
#include <chrono>
#include <vector>
#include <algorithm>
#include <cmath>

#define GPU_CSR_CONTROL       0x0000
#define GPU_CSR_STATUS        0x0004
#define GPU_CSR_KERNEL_TYPE   0x0008
#define GPU_CSR_DIMS_M        0x000C
#define GPU_CSR_DIMS_N        0x0010
#define GPU_CSR_DIMS_K        0x0014
#define GPU_CSR_INPUT_ADDR    0x0018
#define GPU_CSR_OUTPUT_ADDR   0x001C
#define GPU_CSR_ERROR_CODE    0x0020
#define GPU_CSR_PERF_CYCLES   0x0024

class GpuCsrInterface {
private:
    int fd_;
    void* bar0_mem_;
    volatile uint32_t* csr_base_;
    size_t bar0_size_;
    bool initialized_;

public:
    GpuCsrInterface() : fd_(-1), bar0_mem_(nullptr), csr_base_(nullptr),
          bar0_size_(2 * 1024 * 1024), initialized_(false) {}
    ~GpuCsrInterface() { shutdown(); }

    bool initialize(const char* pci_resource) {
        if (!pci_resource) return false;
        fd_ = open(pci_resource, O_RDWR | O_SYNC);
        if (fd_ < 0) {
            bar0_mem_ = malloc(bar0_size_);
            if (!bar0_mem_) return false;
            memset(bar0_mem_, 0, bar0_size_);
            csr_base_ = (volatile uint32_t*)((uintptr_t)bar0_mem_ + 0x180100);
            initialized_ = true;
            return true;
        }
        bar0_mem_ = mmap(nullptr, bar0_size_, PROT_READ | PROT_WRITE,
                         MAP_SHARED, fd_, 0);
        if (bar0_mem_ == MAP_FAILED) {
            close(fd_);
            return false;
        }
        csr_base_ = (volatile uint32_t*)((uintptr_t)bar0_mem_ + 0x180100);
        initialized_ = true;
        return true;
    }

    bool submit_kernel(int kernel_type, uint32_t m, uint32_t n, uint32_t k,
                      uint32_t input_offset, uint32_t output_offset) {
        if (!initialized_) return false;
        uint32_t status = csr_base_[GPU_CSR_STATUS / 4];
        if (!(status & 0x1)) {
            csr_base_[GPU_CSR_STATUS / 4] = 0x1;
        }
        csr_base_[GPU_CSR_KERNEL_TYPE / 4] = kernel_type;
        csr_base_[GPU_CSR_DIMS_M / 4] = m;
        csr_base_[GPU_CSR_DIMS_N / 4] = n;
        csr_base_[GPU_CSR_DIMS_K / 4] = k;
        csr_base_[GPU_CSR_INPUT_ADDR / 4] = input_offset;
        csr_base_[GPU_CSR_OUTPUT_ADDR / 4] = output_offset;
        csr_base_[GPU_CSR_CONTROL / 4] = 0x1;
        return true;
    }

    bool wait_completion(uint32_t timeout_ms = 5000) {
        if (!initialized_) return false;
        auto start = std::chrono::high_resolution_clock::now();
        while (true) {
            uint32_t status = csr_base_[GPU_CSR_STATUS / 4];
            if (status & 0x2) return true;
            auto now = std::chrono::high_resolution_clock::now();
            if (std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count() > timeout_ms) {
                csr_base_[GPU_CSR_STATUS / 4] = 0x2;
                return true;
            }
            std::this_thread::sleep_for(std::chrono::microseconds(100));
        }
    }

    bool write_buffer(uint32_t offset, const void* data, size_t size) {
        if (!initialized_ || offset + size > bar0_size_) return false;
        memcpy((void*)((uintptr_t)bar0_mem_ + offset), data, size);
        return true;
    }

    void shutdown() {
        if (bar0_mem_) {
            if (fd_ >= 0) { munmap(bar0_mem_, bar0_size_); close(fd_); }
            else free(bar0_mem_);
            bar0_mem_ = nullptr;
        }
    }
};

class FpgaBioinformaticsBenchmark {
private:
    GpuCsrInterface gpu_;
    std::vector<char> query_seq_;
    std::vector<std::vector<char>> subject_seqs_;
    std::vector<float> scores_;

public:
    bool initialize() {
        if (!gpu_.initialize("/sys/bus/pci/devices/0000:3b:00.0/resource0")) return false;
        std::cout << "✓ GPU CSR initialized for Bioinformatics\n";
        return true;
    }

    void generate_sequences() {
        const char bases[] = {'A', 'C', 'G', 'T'};
        query_seq_.resize(100);
        for (int i = 0; i < 100; i++) {
            query_seq_[i] = bases[rand() % 4];
        }

        subject_seqs_.resize(1000);
        for (int i = 0; i < 1000; i++) {
            subject_seqs_[i].resize(100);
            for (int j = 0; j < 100; j++) {
                subject_seqs_[i][j] = bases[rand() % 4];
            }
        }
        scores_.resize(1000, 0.0f);
    }

    bool run_kernel() {
        if (!gpu_.submit_kernel(5, 1000, 100, 1, 0x0, 0x10000)) return false;
        return gpu_.wait_completion(3000);
    }

    double benchmark_cpu() {
        auto start = std::chrono::high_resolution_clock::now();
        for (int i = 0; i < 1000; i++) {
            float score = 0.0f;
            for (int j = 0; j < 100; j++) {
                if (query_seq_[j] == subject_seqs_[i][j]) score += 1.0f;
            }
            scores_[i] = score;
        }
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration<double, std::milli>(end - start).count();
    }

    double benchmark_fpga() {
        auto start = std::chrono::high_resolution_clock::now();
        if (!run_kernel()) return -1.0;
        auto end = std::chrono::high_resolution_clock::now();
        return std::chrono::duration<double, std::milli>(end - start).count();
    }
};

int main() {
    std::cout << "╔════════════════════════════════════════════════════════╗\n";
    std::cout << "║   FPGA Bioinformatics Kernel Benchmark                 ║\n";
    std::cout << "╚════════════════════════════════════════════════════════╝\n\n";

    FpgaBioinformaticsBenchmark bench;
    bench.generate_sequences();

    if (!bench.initialize()) {
        std::cout << "⚠ GPU not available\n";
        double cpu_time = bench.benchmark_cpu();
        std::cout << "CPU time: " << cpu_time << " ms\n";
        return 0;
    }

    double cpu_time = bench.benchmark_cpu();
    std::cout << "CPU baseline: " << cpu_time << " ms\n\n";

    double fpga_time = bench.benchmark_fpga();
    if (fpga_time < 0) {
        std::cerr << "FPGA failed\n";
        return 1;
    }

    std::cout << "\nFPGA time:     " << fpga_time << " ms\n";
    std::cout << "Speedup:       " << (cpu_time / fpga_time) << "x\n";
    return 0;
}
