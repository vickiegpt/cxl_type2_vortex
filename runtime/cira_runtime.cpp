/**
 * cira_runtime.cpp
 *
 * Host-side CIRA runtime implementation.
 */

#include "cira_runtime.h"
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

namespace cira::runtime {

CiraRuntime::CiraRuntime() = default;

CiraRuntime::~CiraRuntime() {
    if (bar0_ && !simulate_) {
        munmap(const_cast<void*>(static_cast<const volatile void*>(bar0_)), bar0_size_);
    }
    if (mem_fd_ >= 0) {
        close(mem_fd_);
    }
}

bool CiraRuntime::init(const std::string& dev_path, uint64_t bar0_phys,
                       size_t bar0_size, bool simulate) {
    simulate_ = simulate;
    bar0_size_ = bar0_size;

    if (simulate) {
        sim_bar0_ = std::make_unique<uint8_t[]>(bar0_size);
        memset(sim_bar0_.get(), 0, bar0_size);
        bar0_ = sim_bar0_.get();
        fprintf(stderr, "[CIRA] Initialized in simulation mode\n");
    } else {
        mem_fd_ = open(dev_path.c_str(), O_RDWR | O_SYNC);
        if (mem_fd_ < 0) {
            perror("[CIRA] open device");
            return false;
        }
        bar0_ = mmap(nullptr, bar0_size, PROT_READ | PROT_WRITE,
                      MAP_SHARED, mem_fd_, bar0_phys);
        if (bar0_ == MAP_FAILED) {
            perror("[CIRA] mmap BAR0");
            bar0_ = nullptr;
            return false;
        }
        fprintf(stderr, "[CIRA] BAR0 mapped: phys=0x%lx size=%zu\n",
                bar0_phys, bar0_size);
    }

    // Initialize ring buffer at BAR0 + RING_BUFFER_OFFSET
    volatile void* ring_base = reinterpret_cast<volatile uint8_t*>(bar0_)
                                + RING_BUFFER_OFFSET;
    if (!ring_buffer_.init(ring_base)) {
        fprintf(stderr, "[CIRA] Failed to initialize ring buffer\n");
        return false;
    }

    // Zero out completion pool
    memset(completion_pool_, 0, sizeof(completion_pool_));

    fprintf(stderr, "[CIRA] Runtime initialized (%s mode)\n",
            simulate ? "simulation" : "hardware");
    return true;
}

bool CiraRuntime::load_kernel(const std::string& path, uint64_t load_addr) {
    FILE* f = fopen(path.c_str(), "rb");
    if (!f) {
        perror("[CIRA] open kernel binary");
        return false;
    }

    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);

    std::vector<uint8_t> data(size);
    if (fread(data.data(), 1, size, f) != size) {
        perror("[CIRA] read kernel binary");
        fclose(f);
        return false;
    }
    fclose(f);

    if (simulate_) {
        fprintf(stderr, "[CIRA] Simulated kernel load: %s (%zu bytes at 0x%lx)\n",
                path.c_str(), size, load_addr);
        return true;
    }

    // Use AFU CMD_MEM_WRITE protocol (same as cxl_gpu_launcher.cpp)
    // ARG0 = host phys addr >> 6, ARG1 = dev addr >> 6, ARG2 = size >> 6
    fprintf(stderr, "[CIRA] Loading kernel: %s (%zu bytes at 0x%lx)\n",
            path.c_str(), size, load_addr);

    // Write via AFU MMIO command interface
    constexpr uint32_t MMIO_CMD_TYPE = 0x28;
    constexpr uint32_t MMIO_CMD_ARG1 = 0x38;
    constexpr uint32_t MMIO_CMD_ARG2 = 0x40;
    constexpr uint32_t AFU_CMD_MEM_WRITE = 2;

    size_t aligned = (size + 63) & ~63ULL;
    mmio_write64(MMIO_CMD_ARG1, load_addr >> 6);
    mmio_write64(MMIO_CMD_ARG2, aligned >> 6);
    mmio_write64(MMIO_CMD_TYPE, AFU_CMD_MEM_WRITE);

    return true;
}

CiraHandle CiraRuntime::alloc_cxl(size_t size) {
    // Align to cacheline
    size_t aligned = (size + CACHELINE_SIZE - 1) & ~(CACHELINE_SIZE - 1);

    CiraHandle h;
    if (simulate_) {
        h.host_addr = aligned_alloc(CACHELINE_SIZE, aligned);
        h.device_addr = reinterpret_cast<uint64_t>(h.host_addr);
    } else {
        // In real hardware, allocate from CXL HDM region
        // For now, use mmap of the HDM BAR
        h.host_addr = aligned_alloc(CACHELINE_SIZE, aligned);
        h.device_addr = reinterpret_cast<uint64_t>(h.host_addr);
    }
    h.size = aligned;
    memset(h.host_addr, 0, aligned);
    return h;
}

void CiraRuntime::free_cxl(CiraHandle& handle) {
    if (handle.host_addr) {
        free(handle.host_addr);
        handle.host_addr = nullptr;
    }
}

CiraFuture CiraRuntime::future_create(uint32_t num_lines) {
    CiraFuture f;
    f.id = next_future_id_++;
    if (f.id < MAX_FUTURES) {
        f.completion = &completion_pool_[f.id];
        reset_completion(f.completion);
    } else {
        // Wrap around
        f.id = f.id % MAX_FUTURES;
        f.completion = &completion_pool_[f.id];
        reset_completion(f.completion);
    }
    return f;
}

bool CiraRuntime::future_await(CiraFuture& future, uint64_t timeout_spins) {
    return poll_completion(future.completion, timeout_spins);
}

void CiraRuntime::release(CiraFuture& future) {
    reset_completion(future.completion);
}

bool CiraRuntime::offload(uint64_t data_ptr, uint64_t func_addr,
                          uint32_t arg0, uint32_t arg1,
                          uint32_t arg2, uint32_t arg3,
                          uint32_t prefetch_depth, CiraFuture* future) {
    TaskDescriptor task = {};
    task.task_id = next_task_id_++;
    task.priority = 0;  // High priority
    task.func_addr = func_addr;
    task.data_ptr = data_ptr;
    task.arg0 = arg0;
    task.arg1 = arg1;
    task.arg2 = arg2;
    task.arg3 = arg3;
    task.prefetch_depth = prefetch_depth;
    task.flags = 0;

    if (future) {
        task.completion_addr = reinterpret_cast<uint64_t>(future->completion);
    }

    if (simulate_) {
        // In simulation, immediately mark as complete
        if (future) {
            const_cast<CompletionData*>(
                const_cast<volatile CompletionData*>(future->completion)
            )->magic = COMPLETION_MAGIC;
            const_cast<CompletionData*>(
                const_cast<volatile CompletionData*>(future->completion)
            )->task_id = task.task_id;
            const_cast<CompletionData*>(
                const_cast<volatile CompletionData*>(future->completion)
            )->status = 0;
        }
        return true;
    }

    return ring_buffer_.enqueue(task);
}

bool CiraRuntime::speculate(uint64_t data_ptr, uint64_t func_addr,
                            uint32_t arg0, uint32_t arg1,
                            uint32_t arg2, uint32_t arg3,
                            uint32_t prefetch_depth, CiraFuture* future) {
    TaskDescriptor task = {};
    task.task_id = next_task_id_++;
    task.priority = 1;  // Low priority
    task.func_addr = func_addr;
    task.data_ptr = data_ptr;
    task.arg0 = arg0;
    task.arg1 = arg1;
    task.arg2 = arg2;
    task.arg3 = arg3;
    task.prefetch_depth = prefetch_depth;

    if (future) {
        task.completion_addr = reinterpret_cast<uint64_t>(future->completion);
    }

    if (simulate_) {
        if (future) {
            const_cast<CompletionData*>(
                const_cast<volatile CompletionData*>(future->completion)
            )->magic = COMPLETION_MAGIC;
        }
        return true;
    }

    return ring_buffer_.enqueue(task);
}

bool CiraRuntime::barrier(uint64_t timeout_spins) {
    if (simulate_) return true;

    // Wait until ring buffer is drained
    for (uint64_t i = 0; i < timeout_spins; ++i) {
        if (ring_buffer_.is_empty()) return true;
        _mm_pause();
    }
    fprintf(stderr, "[CIRA] barrier timed out with %u pending tasks\n",
            ring_buffer_.pending_count());
    return false;
}

void CiraRuntime::phase_boundary(const std::string& phase_name) {
    barrier();
    if (!phase_name.empty()) {
        fprintf(stderr, "[CIRA] Phase boundary: %s\n", phase_name.c_str());
    }
}

uint32_t CiraRuntime::pending_tasks() const {
    return ring_buffer_.pending_count();
}

void CiraRuntime::mmio_write64(uint32_t offset, uint64_t value) {
    volatile uint64_t* reg = reinterpret_cast<volatile uint64_t*>(
        reinterpret_cast<volatile uint8_t*>(bar0_) + offset
    );
    *reg = value;
    __sync_synchronize();
}

uint64_t CiraRuntime::mmio_read64(uint32_t offset) {
    volatile uint64_t* reg = reinterpret_cast<volatile uint64_t*>(
        reinterpret_cast<volatile uint8_t*>(bar0_) + offset
    );
    __sync_synchronize();
    return *reg;
}

}  // namespace cira::runtime
