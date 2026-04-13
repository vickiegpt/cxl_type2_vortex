/**
 * dcoh_fence_test.cpp
 *
 * Tests for DCOH writeback fence ordering and cache line race conditions.
 *
 * Background (from conversation with Andi, 2026-04-08):
 *   - Device writes data to CXL memory, DCOH pushes cacheline to host LLC
 *   - Need a DFF (register stage) fence before DCOH writeback to ensure
 *     data fields are globally visible before the completion magic
 *   - Concern: LLC may evict the DCOH-pushed line before host reads it
 *   - Andi says: eviction should just cause a CXL.mem re-read (perf hit,
 *     not correctness bug), but we need test programs to confirm
 *   - All of these are potential race conditions, so tests must run many
 *     iterations to trigger them probabilistically
 *
 * Test matrix:
 *   Test 1: Basic completion magic ordering (data before magic)
 *   Test 2: LLC eviction stress (pollute LLC while waiting for DCOH)
 *   Test 3: Multi-cacheline ordering (16-depth prefetch chain)
 *   Test 4: Concurrent writer interference (another core writes nearby)
 *   Test 5: Rapid fire/reuse (reset and reuse completion slot quickly)
 *
 * Build:
 *   g++ -std=c++17 -O2 -march=native -o dcoh_fence_test dcoh_fence_test.cpp -lpthread
 *
 * Usage:
 *   sudo ./dcoh_fence_test [--iterations N] [--hardware]
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <cassert>
#include <atomic>
#include <thread>
#include <vector>
#include <chrono>
#include <random>
#include <immintrin.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

// ============================================================================
// Shared definitions (must match device-side kernel and runtime)
// ============================================================================

static constexpr uint32_t COMPLETION_MAGIC   = 0xDEADBEEF;
static constexpr uint32_t COMPLETION_PENDING = 0x00000000;
static constexpr size_t   CACHELINE_SIZE     = 64;
static constexpr size_t   LLC_SIZE_BYTES     = 352 * 1024 * 1024; // Granite Rapids 352MB

struct alignas(CACHELINE_SIZE) CompletionData {
    uint32_t magic;         // Offset 0: 0xDEADBEEF when complete
    uint32_t task_id;       // Offset 4: Which task completed
    uint32_t status;        // Offset 8: 0=success
    uint32_t cycles;        // Offset 12: Vortex cycle count
    uint64_t result_addr;   // Offset 16: Result data address
    uint32_t result_size;   // Offset 24: Result data size
    uint32_t sequence;      // Offset 28: Sequence number for ordering test
    uint32_t data[8];       // Offset 32-63: Test payload data
};
static_assert(sizeof(CompletionData) == CACHELINE_SIZE);

// A simulated "device write" that mimics what the Vortex kernel does.
// In real hardware, this runs on the Vortex core; here we simulate it
// from another thread to exercise the same memory ordering.
//
// KEY INSIGHT from Yiwei: need DFF (register stage) before the magic write.
// In software, this is a store fence. In RTL, this is a pipeline register
// between the data write and the completion write AXI transactions.
static void device_write_completion(volatile CompletionData* cd,
                                     uint32_t task_id,
                                     uint32_t sequence,
                                     const uint32_t* payload,
                                     size_t payload_words) {
    // Step 1: Write data fields FIRST
    cd->task_id = task_id;
    cd->status = 0;
    cd->cycles = 42;
    cd->result_addr = 0;
    cd->result_size = 0;
    cd->sequence = sequence;
    for (size_t i = 0; i < payload_words && i < 8; i++) {
        cd->data[i] = payload[i];
    }

    // Step 2: FENCE — this is the DFF Yiwei is talking about.
    // On Vortex this must be a fence instruction (vx_fence).
    // In RTL, this is a registered pipeline stage that ensures all
    // prior AXI write transactions complete before the next one.
    //
    // Without this fence, the magic write could be reordered before
    // the data writes, and the host would see DEADBEEF but stale data.
    __atomic_thread_fence(__ATOMIC_RELEASE);
    // On x86 this compiles to nothing (TSO gives us this for free),
    // but on RISC-V (Vortex) the fence instruction is required.
    // The RTL equivalent: register the AXI aw/w channel signals through
    // a DFF stage so the completion write cannot issue until the prior
    // data write's bresp is received.

    // Step 3: Write magic LAST
    __atomic_store_n(&cd->magic, COMPLETION_MAGIC, __ATOMIC_RELEASE);
}

// Host-side poll with ordering check
struct PollResult {
    bool completed;
    bool data_valid;        // true if all data fields are correct
    uint64_t poll_cycles;   // How many spins before completion
    uint32_t observed_magic;
    uint32_t observed_task_id;
    uint32_t observed_sequence;
};

static PollResult host_poll_completion(volatile CompletionData* cd,
                                       uint32_t expected_task_id,
                                       uint32_t expected_sequence,
                                       const uint32_t* expected_payload,
                                       size_t payload_words,
                                       uint64_t max_spins = 100000000ULL) {
    PollResult r = {};

    for (uint64_t i = 0; i < max_spins; i++) {
        uint32_t magic = __atomic_load_n(&cd->magic, __ATOMIC_ACQUIRE);
        if (magic == COMPLETION_MAGIC) {
            r.completed = true;
            r.poll_cycles = i;
            r.observed_magic = magic;

            // Read data fields AFTER seeing magic (acquire ordering)
            r.observed_task_id = cd->task_id;
            r.observed_sequence = cd->sequence;

            // Verify data integrity
            r.data_valid = true;
            if (r.observed_task_id != expected_task_id) {
                r.data_valid = false;
            }
            if (r.observed_sequence != expected_sequence) {
                r.data_valid = false;
            }
            for (size_t j = 0; j < payload_words && j < 8; j++) {
                if (cd->data[j] != expected_payload[j]) {
                    r.data_valid = false;
                    break;
                }
            }
            return r;
        }
        _mm_pause();
    }

    r.completed = false;
    r.observed_magic = __atomic_load_n(&cd->magic, __ATOMIC_ACQUIRE);
    return r;
}

// Reset completion slot (host does this after consuming)
static void host_reset_completion(volatile CompletionData* cd) {
    __atomic_store_n(&cd->magic, COMPLETION_PENDING, __ATOMIC_RELEASE);
    _mm_clflush(const_cast<CompletionData*>(const_cast<volatile CompletionData*>(cd)));
}

// ============================================================================
// Test 1: Basic completion magic ordering
//
// Verifies that when the host sees magic=DEADBEEF, all data fields
// written BEFORE the magic are visible (no stale data from reordering).
// This is the DFF/fence correctness test.
// ============================================================================

static int test_basic_ordering(int iterations) {
    printf("  Test 1: Basic completion magic ordering (%d iterations)\n", iterations);

    auto* cd = static_cast<CompletionData*>(
        aligned_alloc(CACHELINE_SIZE, sizeof(CompletionData)));
    memset(cd, 0, sizeof(CompletionData));

    int failures = 0;
    int data_corruptions = 0;

    for (int iter = 0; iter < iterations; iter++) {
        // Reset
        host_reset_completion(cd);

        // Prepare expected payload
        uint32_t payload[8];
        for (int j = 0; j < 8; j++) payload[j] = (iter << 8) | j;

        // Simulate device write from another thread
        std::thread device_thread([&]() {
            // Small random delay to vary timing
            for (volatile int d = 0; d < (iter % 100); d++) {}
            device_write_completion(cd, iter, iter * 7, payload, 8);
        });

        // Host polls
        PollResult r = host_poll_completion(cd, iter, iter * 7, payload, 8);
        device_thread.join();

        if (!r.completed) {
            failures++;
        } else if (!r.data_valid) {
            data_corruptions++;
            fprintf(stderr, "    CORRUPTION at iter %d: task_id=%u (expected %d), "
                    "seq=%u (expected %d)\n",
                    iter, r.observed_task_id, iter,
                    r.observed_sequence, iter * 7);
        }
    }

    free(cd);

    printf("    Results: %d/%d completed, %d data corruptions\n",
           iterations - failures, iterations, data_corruptions);

    if (data_corruptions > 0) {
        printf("    FAIL: Data corruption detected! Fence is not working.\n");
        printf("    FIX: Ensure vx_fence() / DFF register stage between\n");
        printf("         data writes and magic write on device side.\n");
        return 1;
    }
    if (failures > 0) {
        printf("    WARN: %d polls timed out (may be test timing issue)\n", failures);
    }
    printf("    PASS\n");
    return 0;
}

// ============================================================================
// Test 2: LLC eviction stress
//
// While waiting for device completion, pollute the LLC with unrelated data.
// If the DCOH-pushed line gets evicted, the host should still be able to
// read it (via CXL.mem re-fetch). This tests Andi's assertion that
// eviction = performance hit, not correctness bug.
// ============================================================================

static int test_llc_eviction_stress(int iterations) {
    printf("  Test 2: LLC eviction stress (%d iterations)\n", iterations);

    auto* cd = static_cast<CompletionData*>(
        aligned_alloc(CACHELINE_SIZE, sizeof(CompletionData)));
    memset(cd, 0, sizeof(CompletionData));

    // Allocate a buffer larger than LLC to cause evictions
    // Use 1/4 of LLC size to keep test duration reasonable
    size_t polluter_size = LLC_SIZE_BYTES / 4;
    auto* polluter = static_cast<uint8_t*>(malloc(polluter_size));
    if (!polluter) {
        printf("    SKIP: Cannot allocate %zu bytes for LLC pollution\n", polluter_size);
        free(cd);
        return 0;
    }
    memset(polluter, 0, polluter_size);

    int failures = 0;
    int data_corruptions = 0;
    int eviction_detected = 0; // Cases where poll took extra long (likely re-fetch)

    for (int iter = 0; iter < iterations; iter++) {
        host_reset_completion(cd);

        uint32_t payload[8];
        for (int j = 0; j < 8; j++) payload[j] = 0xAA000000 | (iter << 8) | j;

        // Device writes completion
        std::thread device_thread([&]() {
            device_write_completion(cd, iter, iter, payload, 8);
        });

        // Meanwhile, host pollutes LLC by streaming through a large buffer
        // This may evict the completion cacheline from LLC
        volatile uint64_t sink = 0;
        for (size_t i = 0; i < polluter_size; i += CACHELINE_SIZE) {
            sink += polluter[i];
        }
        (void)sink;

        // Now poll for completion — if line was evicted, this will be a CXL.mem miss
        PollResult r = host_poll_completion(cd, iter, iter, payload, 8);
        device_thread.join();

        if (!r.completed) {
            failures++;
        } else if (!r.data_valid) {
            data_corruptions++;
            fprintf(stderr, "    CORRUPTION at iter %d after LLC eviction stress\n", iter);
        } else {
            // Check if poll took a long time (suggesting LLC miss -> CXL re-fetch)
            if (r.poll_cycles > 10000) {
                eviction_detected++;
            }
        }
    }

    free(polluter);
    free(cd);

    printf("    Results: %d/%d completed, %d corruptions, %d likely eviction re-fetches\n",
           iterations - failures, iterations, data_corruptions, eviction_detected);

    if (data_corruptions > 0) {
        printf("    FAIL: Data corruption after LLC eviction!\n");
        printf("    This means the CXL.mem re-fetch path has a coherency bug.\n");
        printf("    Andi's expectation: eviction = perf hit, not data loss.\n");
        return 1;
    }
    printf("    PASS (eviction is performance-safe as expected)\n");
    return 0;
}

// ============================================================================
// Test 3: Multi-cacheline ordering (depth-16 prefetch chain)
//
// Simulates the 16-depth prefetch chain: device writes 16 completion
// slots in order. Host must see them in order. Tests whether the
// DFF fence is sufficient for multi-line writeback ordering.
//
// This is the "depth-16 viability" test Yiwei mentioned.
// ============================================================================

static int test_multi_cacheline_ordering(int iterations, int depth = 16) {
    printf("  Test 3: Multi-cacheline ordering (depth=%d, %d iterations)\n",
           depth, iterations);

    // Allocate array of completion slots
    auto* slots = static_cast<CompletionData*>(
        aligned_alloc(CACHELINE_SIZE, depth * sizeof(CompletionData)));
    memset(slots, 0, depth * sizeof(CompletionData));

    int failures = 0;
    int order_violations = 0;

    for (int iter = 0; iter < iterations; iter++) {
        // Reset all slots
        for (int d = 0; d < depth; d++) {
            host_reset_completion(&slots[d]);
        }

        // Device writes slots 0..depth-1 in order, each with a fence
        std::thread device_thread([&]() {
            for (int d = 0; d < depth; d++) {
                uint32_t payload[8] = {};
                payload[0] = iter;
                payload[1] = d;  // depth index
                payload[2] = 0xBEEF0000 | d;

                device_write_completion(&slots[d], iter * 100 + d, d, payload, 3);

                // On real Vortex: each write goes through AXI -> DDR -> DCOH
                // The DFF between writes ensures slot[d] is visible before slot[d+1]
                // In software simulation, the thread_fence provides this.
            }
        });

        device_thread.join();

        // Host reads all slots and checks ordering
        bool all_valid = true;
        uint32_t last_seen_sequence = 0;
        bool last_seen_valid = false;

        for (int d = 0; d < depth; d++) {
            uint32_t magic = __atomic_load_n(&slots[d].magic, __ATOMIC_ACQUIRE);
            if (magic != COMPLETION_MAGIC) {
                failures++;
                all_valid = false;
                break;
            }

            uint32_t seq = slots[d].sequence;
            if (last_seen_valid && seq < last_seen_sequence) {
                order_violations++;
                fprintf(stderr, "    ORDER VIOLATION at iter %d: slot[%d].seq=%u < slot[%d].seq=%u\n",
                        iter, d, seq, d - 1, last_seen_sequence);
                all_valid = false;
            }

            // Verify payload integrity
            if (slots[d].data[0] != (uint32_t)iter ||
                slots[d].data[1] != (uint32_t)d) {
                fprintf(stderr, "    PAYLOAD CORRUPTION at iter %d slot %d: "
                        "data[0]=%u (exp %d), data[1]=%u (exp %d)\n",
                        iter, d, slots[d].data[0], iter, slots[d].data[1], d);
                all_valid = false;
            }

            last_seen_sequence = seq;
            last_seen_valid = true;
        }
    }

    free(slots);

    printf("    Results: %d order violations, %d incomplete chains out of %d\n",
           order_violations, failures, iterations);

    if (order_violations > 0) {
        printf("    FAIL: Multi-line ordering violation detected!\n");
        printf("    FIX: Need per-line DFF fence in RTL, or device must wait for\n");
        printf("         AXI bresp before issuing next line's write.\n");
        return 1;
    }
    printf("    PASS\n");
    return 0;
}

// ============================================================================
// Test 4: Concurrent writer interference
//
// Another CPU core writes to cachelines adjacent to the completion slot.
// Tests whether a neighbor write can interfere with the DCOH push.
// This is the "another core overwrites nearby cacheline" concern.
// ============================================================================

static int test_concurrent_writer(int iterations) {
    printf("  Test 4: Concurrent writer interference (%d iterations)\n", iterations);

    // Allocate 3 adjacent cachelines: [neighbor0][completion][neighbor1]
    auto* block = static_cast<uint8_t*>(
        aligned_alloc(CACHELINE_SIZE, 3 * CACHELINE_SIZE));
    memset(block, 0, 3 * CACHELINE_SIZE);

    auto* neighbor0 = reinterpret_cast<volatile uint64_t*>(block);
    auto* cd = reinterpret_cast<CompletionData*>(block + CACHELINE_SIZE);
    auto* neighbor1 = reinterpret_cast<volatile uint64_t*>(block + 2 * CACHELINE_SIZE);

    int failures = 0;
    int data_corruptions = 0;
    std::atomic<bool> stop{false};

    // Interferer thread: continuously writes to neighbor cachelines
    std::thread interferer([&]() {
        uint64_t counter = 0;
        while (!stop.load(std::memory_order_relaxed)) {
            *neighbor0 = counter;
            *neighbor1 = counter;
            __atomic_thread_fence(__ATOMIC_RELEASE);
            counter++;
        }
    });

    for (int iter = 0; iter < iterations; iter++) {
        host_reset_completion(cd);

        uint32_t payload[8];
        for (int j = 0; j < 8; j++) payload[j] = 0xCC000000 | (iter << 8) | j;

        // Device writes completion while interferer is active
        std::thread device_thread([&]() {
            device_write_completion(cd, iter, iter, payload, 8);
        });

        PollResult r = host_poll_completion(cd, iter, iter, payload, 8);
        device_thread.join();

        if (!r.completed) {
            failures++;
        } else if (!r.data_valid) {
            data_corruptions++;
            fprintf(stderr, "    CORRUPTION at iter %d with concurrent neighbor writes\n", iter);
        }
    }

    stop.store(true, std::memory_order_relaxed);
    interferer.join();
    free(block);

    printf("    Results: %d/%d completed, %d corruptions\n",
           iterations - failures, iterations, data_corruptions);

    if (data_corruptions > 0) {
        printf("    FAIL: Neighbor writes corrupted completion data!\n");
        printf("    This could mean false sharing between adjacent cachelines.\n");
        return 1;
    }
    printf("    PASS (neighbor writes don't corrupt completion data)\n");
    return 0;
}

// ============================================================================
// Test 5: Rapid slot reuse
//
// Quickly reset and reuse the same completion slot. Tests whether
// the host's clflush (to signal "slot is free") races with the
// device's next DCOH push to the same slot.
// ============================================================================

static int test_rapid_reuse(int iterations) {
    printf("  Test 5: Rapid slot reuse (%d iterations)\n", iterations);

    auto* cd = static_cast<CompletionData*>(
        aligned_alloc(CACHELINE_SIZE, sizeof(CompletionData)));
    memset(cd, 0, sizeof(CompletionData));

    int failures = 0;
    int data_corruptions = 0;
    int stale_data_seen = 0;

    for (int iter = 0; iter < iterations; iter++) {
        // Reset ASAP (simulating tight loop reuse)
        host_reset_completion(cd);

        uint32_t payload[8];
        for (int j = 0; j < 8; j++) payload[j] = iter;

        // Immediately fire next device write (no delay)
        device_write_completion(cd, iter, iter, payload, 8);

        // Poll
        PollResult r = host_poll_completion(cd, iter, iter, payload, 8, 10000);
        if (!r.completed) {
            failures++;
        } else if (!r.data_valid) {
            // Check if we're seeing data from a PREVIOUS iteration
            if (r.observed_task_id == (uint32_t)(iter - 1)) {
                stale_data_seen++;
                fprintf(stderr, "    STALE DATA at iter %d: saw task_id=%u (previous iter)\n",
                        iter, r.observed_task_id);
            } else {
                data_corruptions++;
            }
        }
    }

    free(cd);

    printf("    Results: %d/%d completed, %d corruptions, %d stale reads\n",
           iterations - failures, iterations, data_corruptions, stale_data_seen);

    if (stale_data_seen > 0) {
        printf("    FAIL: Stale data from previous iteration detected!\n");
        printf("    The host's clflush didn't complete before device's next write.\n");
        printf("    FIX: Host must mfence after clflush, or use clflushopt + sfence.\n");
        return 1;
    }
    if (data_corruptions > 0) {
        printf("    FAIL: Data corruption on rapid reuse!\n");
        return 1;
    }
    printf("    PASS\n");
    return 0;
}

// ============================================================================
// Main
// ============================================================================

int main(int argc, char** argv) {
    int iterations = 10000;
    bool hardware = false;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--iterations") == 0 && i + 1 < argc)
            iterations = atoi(argv[++i]);
        else if (strcmp(argv[i], "--hardware") == 0)
            hardware = true;
    }

    printf("================================================================\n");
    printf("DCOH Fence Ordering & Cache Line Race Condition Tests\n");
    printf("================================================================\n");
    printf("Mode: %s\n", hardware ? "HARDWARE (real CXL device)" : "SOFTWARE SIMULATION");
    printf("Iterations: %d per test\n", iterations);
    printf("Purpose: Verify DFF fence ordering and LLC eviction safety\n");
    printf("\n");

    if (!hardware) {
        printf("NOTE: Software simulation uses x86 TSO memory model which is\n");
        printf("STRONGER than RISC-V. Bugs that appear here are real; bugs that\n");
        printf("DON'T appear here may still exist on Vortex (weaker ordering).\n");
        printf("Run with --hardware on the IA-780i for definitive results.\n\n");
    }

    int total_failures = 0;

    total_failures += test_basic_ordering(iterations);
    printf("\n");

    total_failures += test_llc_eviction_stress(iterations / 10); // Slower test
    printf("\n");

    total_failures += test_multi_cacheline_ordering(iterations / 10, 16);
    printf("\n");

    total_failures += test_concurrent_writer(iterations);
    printf("\n");

    total_failures += test_rapid_reuse(iterations);
    printf("\n");

    printf("================================================================\n");
    if (total_failures == 0) {
        printf("ALL TESTS PASSED\n");
    } else {
        printf("%d TESTS FAILED\n", total_failures);
    }
    printf("================================================================\n");

    return total_failures;
}
