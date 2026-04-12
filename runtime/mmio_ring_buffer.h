/**
 * mmio_ring_buffer.h
 *
 * Lock-free MMIO ring buffer for host->device task submission.
 *
 * Memory layout in BAR0 (starting at RING_BUFFER_OFFSET):
 *   [0x000] head        (uint32_t, written by host)
 *   [0x004] tail        (uint32_t, written by device)
 *   [0x008] capacity    (uint32_t, set once at init)
 *   [0x00C] reserved
 *   [0x040] entries[0]  (TaskDescriptor, 64 bytes each)
 *   [0x080] entries[1]
 *   ...
 *
 * Protocol:
 *   Host: write descriptor to entries[head % capacity], increment head
 *   Device: read entries[tail % capacity], increment tail
 *   Full when: (head + 1) % capacity == tail
 *   Empty when: head == tail
 */

#pragma once

#include <cstdint>
#include <cstring>
#include "completion_data.h"

namespace cira::runtime {

static constexpr uint32_t RING_BUFFER_OFFSET = 0x1000;  // Offset in BAR0
static constexpr uint32_t RING_CAPACITY = 16;            // Max in-flight tasks

/**
 * TaskDescriptor — 64 bytes, matches one cache line.
 * Written by host into the ring buffer, read by device.
 */
struct alignas(CACHELINE_SIZE) TaskDescriptor {
    uint32_t task_id;           // Unique task identifier
    uint32_t priority;          // 0=high (offload), 1=low (speculate)
    uint64_t func_addr;         // Device-side function address
    uint64_t data_ptr;          // Pointer to input data in CXL memory
    uint64_t completion_addr;   // Where device writes CompletionData
    uint32_t arg0;              // Generic arguments
    uint32_t arg1;
    uint32_t arg2;
    uint32_t arg3;
    uint32_t prefetch_depth;    // For prefetch functions
    uint32_t flags;             // Bit 0: requires barrier before next
    uint32_t padding[2];
};
static_assert(sizeof(TaskDescriptor) == CACHELINE_SIZE,
              "TaskDescriptor must be exactly one cache line");

/**
 * RingBufferHeader — lives at RING_BUFFER_OFFSET in BAR0.
 * Head is written by host, tail by device.
 */
struct alignas(CACHELINE_SIZE) RingBufferHeader {
    volatile uint32_t head;
    volatile uint32_t tail;
    uint32_t capacity;
    uint32_t initialized;       // Set to 0xCAFECAFE when ready
    uint32_t padding[12];
};
static_assert(sizeof(RingBufferHeader) == CACHELINE_SIZE,
              "RingBufferHeader must be exactly one cache line");

/**
 * MmioRingBuffer — host-side interface to the ring buffer.
 *
 * The ring buffer lives in BAR0 memory, accessible to both host (via MMIO)
 * and device (via AXI). The host writes task descriptors and the device
 * reads them. No locks needed: single-producer (host), single-consumer (device).
 */
class MmioRingBuffer {
public:
    /**
     * Initialize with a pointer to the BAR0 region.
     * ring_base should point to BAR0 + RING_BUFFER_OFFSET.
     */
    bool init(volatile void* ring_base) {
        header_ = reinterpret_cast<volatile RingBufferHeader*>(ring_base);
        entries_ = reinterpret_cast<volatile TaskDescriptor*>(
            reinterpret_cast<volatile uint8_t*>(ring_base) + CACHELINE_SIZE
        );

        // Initialize header
        header_->head = 0;
        header_->tail = 0;
        header_->capacity = RING_CAPACITY;
        header_->initialized = 0xCAFECAFE;
        __sync_synchronize();

        return true;
    }

    /**
     * Enqueue a task descriptor. Returns false if the queue is full.
     */
    bool enqueue(const TaskDescriptor& task) {
        uint32_t head = header_->head;
        uint32_t tail = header_->tail;
        uint32_t next_head = (head + 1) % RING_CAPACITY;

        if (next_head == tail) {
            return false;  // Queue full
        }

        // Write descriptor to slot
        volatile TaskDescriptor* slot = &entries_[head];
        // Use non-temporal stores to bypass cache for MMIO
        memcpy(const_cast<TaskDescriptor*>(slot), &task, sizeof(TaskDescriptor));
        __sync_synchronize();

        // Advance head (device sees this and knows a new task is ready)
        header_->head = next_head;
        __sync_synchronize();

        return true;
    }

    /**
     * Check if the queue is empty (all tasks consumed by device).
     */
    bool is_empty() const {
        return header_->head == header_->tail;
    }

    /**
     * Check if the queue is full.
     */
    bool is_full() const {
        return ((header_->head + 1) % RING_CAPACITY) == header_->tail;
    }

    /**
     * Number of pending tasks.
     */
    uint32_t pending_count() const {
        uint32_t h = header_->head;
        uint32_t t = header_->tail;
        return (h >= t) ? (h - t) : (RING_CAPACITY - t + h);
    }

private:
    volatile RingBufferHeader* header_ = nullptr;
    volatile TaskDescriptor* entries_ = nullptr;
};

}  // namespace cira::runtime
