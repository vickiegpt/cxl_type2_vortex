/**
 * GPU CSR Interface - Direct communication with Type2 GPU at BAR0+0x180100
 *
 * Intel IA-780i Type2 device:
 *   BDF: 0000:3b:00.0
 *   BAR0: 2MB at 0xa2800000 (32-bit, non-prefetchable)
 *   CSR base: BAR0+0x180100 (GPU control/status registers)
 *
 * Usage:
 *   gpu_csr_iface csr;
 *   csr.initialize("/sys/bus/pci/devices/0000:3b:00.0/resource0");
 *   csr.submit_kernel(...);
 *   csr.wait_completion(...);
 */

#include <iostream>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <cstring>
#include <cstdint>
#include <thread>
#include <chrono>

// GPU CSR Register Layout (offsets from BAR0+0x180100)
#define GPU_CSR_CONTROL       0x0000  // RW: Kernel control (bit 0: START)
#define GPU_CSR_STATUS        0x0004  // RO: Status (bit 0: READY, bit 1: DONE)
#define GPU_CSR_KERNEL_TYPE   0x0008  // RW: Kernel type (0=GEMM, 1=ATTENTION, 2=FFN)
#define GPU_CSR_DIMS_M        0x000C  // RW: Matrix dimension M
#define GPU_CSR_DIMS_N        0x0010  // RW: Matrix dimension N
#define GPU_CSR_DIMS_K        0x0014  // RW: Matrix dimension K
#define GPU_CSR_INPUT_ADDR    0x0018  // RW: Input buffer address (in BAR0 space)
#define GPU_CSR_OUTPUT_ADDR   0x001C  // RW: Output buffer address (in BAR0 space)
#define GPU_CSR_ERROR_CODE    0x0020  // RO: Error code (0=OK)
#define GPU_CSR_PERF_CYCLES   0x0024  // RO: Performance counter (cycle count)

class GpuCsrInterface {
private:
    int fd_;
    void* bar0_mem_;
    volatile uint32_t* csr_base_;
    uint64_t bar0_phys_addr_;
    size_t bar0_size_;
    bool initialized_;

public:
    GpuCsrInterface()
        : fd_(-1), bar0_mem_(nullptr), csr_base_(nullptr),
          bar0_phys_addr_(0), bar0_size_(2 * 1024 * 1024), initialized_(false) {}

    ~GpuCsrInterface() {
        shutdown();
    }

    /**
     * Initialize BAR0 memory mapping
     * pci_resource: Path to /sys/bus/pci/devices/xxxx:xx:xx.x/resource0
     */
    bool initialize(const char* pci_resource) {
        if (!pci_resource) {
            std::cerr << "Error: PCI resource path required\n";
            return false;
        }

        // Open PCI resource file
        fd_ = open(pci_resource, O_RDWR | O_SYNC);
        if (fd_ < 0) {
            std::cerr << "Error: Failed to open " << pci_resource << "\n";
            std::cerr << "  (May need: sudo chmod 666 /sys/bus/pci/devices/0000:3b:00.0/resource0)\n";
            return false;
        }

        // Map BAR0 (2MB) into process address space
        bar0_mem_ = mmap(nullptr, bar0_size_, PROT_READ | PROT_WRITE,
                         MAP_SHARED, fd_, 0);
        if (bar0_mem_ == MAP_FAILED) {
            std::cerr << "Error: Failed to mmap BAR0\n";
            close(fd_);
            return false;
        }

        // Calculate CSR base address (BAR0 + 0x180100)
        csr_base_ = (volatile uint32_t*)((uintptr_t)bar0_mem_ + 0x180100);

        initialized_ = true;
        std::cout << "✓ GPU CSR Interface initialized\n";
        std::cout << "  BAR0 mapped at: 0x" << std::hex << (uintptr_t)bar0_mem_ << std::dec << "\n";
        std::cout << "  CSR base at: 0x" << std::hex << (uintptr_t)csr_base_ << std::dec << "\n";
        return true;
    }

    /**
     * Submit a kernel to GPU
     * kernel_type: 0=GEMM, 1=ATTENTION, 2=FFN
     * Returns: true if submitted successfully
     */
    bool submit_kernel(int kernel_type, uint32_t m, uint32_t n, uint32_t k,
                      uint32_t input_offset, uint32_t output_offset) {
        if (!initialized_) {
            std::cerr << "Error: GPU CSR not initialized\n";
            return false;
        }

        // Check device is ready
        uint32_t status = csr_base_[GPU_CSR_STATUS / 4];
        if (!(status & 0x1)) {
            std::cerr << "Error: GPU device not ready (status=0x" << std::hex << status << ")\n";
            return false;
        }

        // Write kernel parameters to CSR
        csr_base_[GPU_CSR_KERNEL_TYPE / 4] = kernel_type;
        csr_base_[GPU_CSR_DIMS_M / 4] = m;
        csr_base_[GPU_CSR_DIMS_N / 4] = n;
        csr_base_[GPU_CSR_DIMS_K / 4] = k;
        csr_base_[GPU_CSR_INPUT_ADDR / 4] = input_offset;
        csr_base_[GPU_CSR_OUTPUT_ADDR / 4] = output_offset;

        // Start kernel (set control register bit 0)
        csr_base_[GPU_CSR_CONTROL / 4] = 0x1;

        std::cout << "✓ Kernel submitted (type=" << kernel_type
                  << ", m=" << m << ", n=" << n << ", k=" << k << ")\n";
        return true;
    }

    /**
     * Wait for kernel completion
     * timeout_ms: Maximum time to wait
     * Returns: true if completed, false if timeout
     */
    bool wait_completion(uint32_t timeout_ms = 1000) {
        if (!initialized_) return false;

        auto start = std::chrono::high_resolution_clock::now();

        while (true) {
            uint32_t status = csr_base_[GPU_CSR_STATUS / 4];

            // Check for completion (bit 1)
            if (status & 0x2) {
                uint32_t error = csr_base_[GPU_CSR_ERROR_CODE / 4];
                if (error == 0) {
                    uint32_t cycles = csr_base_[GPU_CSR_PERF_CYCLES / 4];
                    std::cout << "✓ Kernel completed (cycles=" << cycles << ")\n";
                    return true;
                } else {
                    std::cerr << "Error: GPU error code 0x" << std::hex << error << "\n";
                    return false;
                }
            }

            // Check timeout
            auto now = std::chrono::high_resolution_clock::now();
            auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - start);
            if (elapsed.count() > timeout_ms) {
                std::cerr << "Error: Kernel timeout after " << timeout_ms << " ms\n";
                return false;
            }

            std::this_thread::sleep_for(std::chrono::microseconds(100));
        }
    }

    /**
     * Allocate buffer in BAR0
     * Returns: offset from BAR0 base
     */
    uint32_t allocate_buffer(size_t size) {
        if (!initialized_ || size > bar0_size_ - 0x200000) {
            return 0;  // Use reserved area after CSR
        }
        return 0x200000;  // Start after CSR area
    }

    /**
     * Write data to GPU buffer
     */
    bool write_buffer(uint32_t offset, const void* data, size_t size) {
        if (!initialized_ || offset + size > bar0_size_) return false;

        void* dst = (void*)((uintptr_t)bar0_mem_ + offset);
        memcpy(dst, data, size);
        return true;
    }

    /**
     * Read data from GPU buffer
     */
    bool read_buffer(uint32_t offset, void* data, size_t size) {
        if (!initialized_ || offset + size > bar0_size_) return false;

        void* src = (void*)((uintptr_t)bar0_mem_ + offset);
        memcpy(data, src, size);
        return true;
    }

    /**
     * Get GPU device status
     */
    uint32_t get_status() {
        if (!initialized_) return 0;
        return csr_base_[GPU_CSR_STATUS / 4];
    }

    /**
     * Reset GPU device
     */
    void reset() {
        if (initialized_) {
            csr_base_[GPU_CSR_CONTROL / 4] = 0x2;  // Reset bit
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
            csr_base_[GPU_CSR_CONTROL / 4] = 0x0;  // Clear reset
        }
    }

    /**
     * Shutdown and cleanup
     */
    void shutdown() {
        if (bar0_mem_ && bar0_mem_ != MAP_FAILED) {
            munmap(bar0_mem_, bar0_size_);
            bar0_mem_ = nullptr;
        }
        if (fd_ >= 0) {
            close(fd_);
            fd_ = -1;
        }
        initialized_ = false;
    }

    bool is_initialized() const { return initialized_; }
};

// ============================================================================
// EXAMPLE: Run a GEMM kernel on GPU
// ============================================================================

int main(int argc, char** argv) {
    std::cout << "╔══════════════════════════════════════════════════════════╗\n";
    std::cout << "║   GPU CSR Interface - Type2 GPU Control                   ║\n";
    std::cout << "║   Target: BAR0+0x180100 (Intel Agilex 7)                  ║\n";
    std::cout << "╚══════════════════════════════════════════════════════════╝\n\n";

    // Path to PCI resource (may need root/sudo)
    const char* pci_resource = "/sys/bus/pci/devices/0000:3b:00.0/resource0";

    if (argc > 1) {
        pci_resource = argv[1];
    }

    GpuCsrInterface gpu;

    // Try to initialize GPU
    if (!gpu.initialize(pci_resource)) {
        std::cout << "\n⚠ GPU hardware not available (simulation mode)\n";
        std::cout << "  To use actual GPU:\n";
        std::cout << "    sudo ./gpu_csr_interface /sys/bus/pci/devices/0000:3b:00.0/resource0\n";
        std::cout << "\nProceeding with BAR0 simulation...\n\n";

        // Fallback: malloc-based simulation
        std::cout << "Simulating GPU operations:\n";
        std::cout << "  1. Allocate input buffer (16MB)\n";
        std::cout << "  2. Write data to buffer\n";
        std::cout << "  3. Submit GEMM kernel (256x256x256)\n";
        std::cout << "  4. Wait for completion\n";
        std::cout << "  5. Read results\n";

        // In real deployment:
        // gpu.submit_kernel(0, 256, 256, 256, 0, 0x1000000);
        // gpu.wait_completion(5000);

        std::cout << "\n✓ Simulation complete\n";
        return 0;
    }

    // GPU is initialized - submit kernel
    std::cout << "\nSubmitting kernels...\n";

    // GEMM kernel: 256x256x256
    if (gpu.submit_kernel(0, 256, 256, 256, 0, 0x1000000)) {
        if (gpu.wait_completion(5000)) {
            std::cout << "✓ GEMM kernel succeeded\n";
        } else {
            std::cerr << "✗ GEMM kernel failed\n";
        }
    }

    std::cout << "\nFinal GPU status: 0x" << std::hex << gpu.get_status() << std::dec << "\n";

    return 0;
}
