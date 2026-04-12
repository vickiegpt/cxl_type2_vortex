/**
 * completion_data.h
 *
 * DCOH completion protocol between x86 host and Vortex RISC-V GPU.
 *
 * The device writes CompletionData to a pre-allocated cacheline-aligned
 * slot. DCOH (Device Coherent) automatically pushes the written cacheline
 * to the host's LLC. The host polls the magic field using mwait semantics:
 * if the line is M/O/E the host proceeds; if S/I it busy-waits.
 *
 * On Granite Rapids, mwait-style polling does NOT alter cache state
 * (confirmed experimentally, spec confirms).
 */

#pragma once

#include <cstdint>
#include <cstring>
#include <atomic>
#include <immintrin.h>

namespace cira::runtime {

static constexpr uint32_t COMPLETION_MAGIC = 0xDEADBEEF;
static constexpr uint32_t COMPLETION_PENDING = 0x00000000;
static constexpr size_t CACHELINE_SIZE = 64;

/**
 * CompletionData — 64-byte cache-line-aligned struct.
 * Written by device, read by host.
 *
 * Layout matches what the Vortex kernel writes to shared memory.
 */
struct alignas(CACHELINE_SIZE) CompletionData {
    uint32_t magic;           // 0xDEADBEEF when complete, 0x0 when pending
    uint32_t task_id;         // Which offload task completed
    uint32_t status;          // 0=success, 1=error, 2=timeout
    uint32_t cycles;          // Vortex cycle count for this task
    uint64_t result_addr;     // Address of result data (if any)
    uint32_t result_size;     // Size of result data in bytes
    uint32_t padding[9];      // Pad to exactly 64 bytes
};
static_assert(sizeof(CompletionData) == CACHELINE_SIZE,
              "CompletionData must be exactly one cache line");

/**
 * Poll a CompletionData slot until the device signals completion.
 * Uses pause instruction to reduce power consumption during busy-wait.
 *
 * @param cd      Pointer to completion data slot (must be cacheline-aligned)
 * @param spins   Max spin iterations before returning false
 * @return true if completion detected, false if timed out
 */
inline bool poll_completion(volatile CompletionData* cd, uint64_t spins = 1000000) {
    for (uint64_t i = 0; i < spins; ++i) {
        uint32_t val = __atomic_load_n(&cd->magic, __ATOMIC_ACQUIRE);
        if (val == COMPLETION_MAGIC) {
            return true;
        }
        _mm_pause();
    }
    return false;
}

/**
 * Reset a CompletionData slot for reuse.
 * Host calls this after consuming the completion, signaling the device
 * that the slot is free for the next task.
 */
inline void reset_completion(volatile CompletionData* cd) {
    __atomic_store_n(const_cast<uint32_t*>(&cd->magic), COMPLETION_PENDING,
                     __ATOMIC_RELEASE);
    // Flush the line so the device sees the reset via CXL.mem
    _mm_clflush(const_cast<CompletionData*>(const_cast<volatile CompletionData*>(cd)));
}

}  // namespace cira::runtime
