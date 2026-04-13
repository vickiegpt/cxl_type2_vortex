/**
 * cira_hw_test.cpp
 *
 * Hardware integration test for the CIRA runtime.
 * Loads prefetch kernels onto the Vortex GPU and validates end-to-end
 * operation via the AFU MMIO command protocol.
 *
 * Tests:
 *   1. Runtime init (BAR0 mmap, device caps query)
 *   2. Kernel upload (CMD_MEM_WRITE to 0x80000000)
 *   3. Kernel launch with PrefetchChainArgs (CMD_RUN)
 *   4. Completion detection (MMIO_STATUS polling)
 *   5. DCOH completion data readback
 *
 * Build:
 *   g++ -std=c++17 -O2 -march=native -o tests/cira_hw_test \
 *       tests/cira_hw_test.cpp runtime/cira_runtime.cpp \
 *       -Iruntime -lpthread
 *
 * Usage:
 *   sudo ./tests/cira_hw_test [--kernel <path>] [--timeout <ms>]
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include "cira_runtime.h"
#include "../kernels/prefetch_args.h"

using namespace cira::runtime;

static int test_count = 0;
static int pass_count = 0;

#define TEST_START(name) do { \
    test_count++; \
    printf("\n[TEST %d] %s\n", test_count, name); \
} while(0)

#define TEST_PASS() do { \
    pass_count++; \
    printf("[PASS]\n"); \
} while(0)

#define TEST_FAIL(msg) do { \
    printf("[FAIL] %s\n", msg); \
} while(0)

// Build a small linked list in contiguous memory for the chain prefetch test
struct TestNode {
    TestNode* next;
    int64_t   value;
    uint8_t   pad[48];  // Pad to 64 bytes (one cacheline)
};
static_assert(sizeof(TestNode) == 64, "TestNode must be one cacheline");

int main(int argc, char** argv) {
    const char* kernel_dir = "../kernels";
    int timeout_ms = 10000;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--kernel-dir") == 0 && i + 1 < argc)
            kernel_dir = argv[++i];
        else if (strcmp(argv[i], "--timeout") == 0 && i + 1 < argc)
            timeout_ms = atoi(argv[++i]);
    }

    printf("================================================================\n");
    printf("CIRA Hardware Integration Test\n");
    printf("  Device: 0000:3b:00.0 (Intel CXL Type-2, Agilex 7)\n");
    printf("  Kernel dir: %s\n", kernel_dir);
    printf("  Timeout: %d ms\n", timeout_ms);
    printf("================================================================\n");

    // ========================================================================
    // Test 1: Runtime initialization
    // ========================================================================
    TEST_START("Runtime init (BAR0 mmap + device caps)");

    CiraRuntime rt;
    if (!rt.init()) {
        TEST_FAIL("rt.init() returned false — check /dev/mem permissions");
        printf("\nResults: %d/%d passed\n", pass_count, test_count);
        return 1;
    }

    const DeviceCaps& caps = rt.caps();
    printf("  Version:  %u\n", caps.version);
    printf("  Cores:    %u\n", caps.num_cores);
    printf("  Warps:    %u\n", caps.num_warps);
    printf("  Threads:  %u\n", caps.num_threads);
    printf("  ISA caps: 0x%016lx\n", caps.isa_caps);

    if (caps.num_cores == 0 && caps.num_warps == 0 && caps.num_threads == 0) {
        TEST_FAIL("All capability fields are zero — device may not be responding");
    } else {
        TEST_PASS();
    }

    // ========================================================================
    // Test 2: Device idle check
    // ========================================================================
    TEST_START("Device idle state (MMIO_STATUS poll)");

    int wait_rc = rt.wait_completion(5000);
    if (wait_rc == 0) {
        TEST_PASS();
    } else {
        TEST_FAIL("Device not idle after 5s — may need reset");
    }

    // ========================================================================
    // Test 3: Load prefetch_chain kernel
    // ========================================================================
    TEST_START("Load prefetch_chain_kernel.bin via CMD_MEM_WRITE");

    char kernel_path[512];
    snprintf(kernel_path, sizeof(kernel_path),
             "%s/prefetch_chain_kernel.bin", kernel_dir);

    auto t0 = std::chrono::high_resolution_clock::now();
    bool load_ok = rt.load_kernel(kernel_path, FUNC_PREFETCH_CHAIN);
    auto t1 = std::chrono::high_resolution_clock::now();
    double load_us = std::chrono::duration<double, std::micro>(t1 - t0).count();

    if (load_ok) {
        printf("  Upload time: %.1f us\n", load_us);
        TEST_PASS();
    } else {
        TEST_FAIL("load_kernel() failed — check staging buffer / DMA path");
    }

    // ========================================================================
    // Test 4: Upload args + launch prefetch_chain kernel
    // ========================================================================
    TEST_START("Launch prefetch_chain with test linked list");

    // Build a small test linked list (16 nodes)
    const uint32_t NUM_NODES = 16;
    TestNode nodes[NUM_NODES];
    for (uint32_t i = 0; i < NUM_NODES; i++) {
        nodes[i].next = (i + 1 < NUM_NODES) ? &nodes[i + 1] : nullptr;
        nodes[i].value = (int64_t)(i * 100 + 42);
        memset(nodes[i].pad, 0, sizeof(nodes[i].pad));
    }

    // Create a future for completion tracking
    CiraFuture f = rt.future_create(1);

    // Set up kernel args
    PrefetchChainArgs args = {};
    args.start_node     = reinterpret_cast<uint64_t>(&nodes[0]);
    args.next_offset    = offsetof(TestNode, next);
    args.data_offset    = offsetof(TestNode, value);
    args.data_size      = sizeof(int64_t);
    args.depth          = NUM_NODES;
    args.output_buf     = 0;  // No output buffer for this test
    args.completion_addr = f.device_addr;
    args.task_id        = f.id;

    printf("  Nodes: %u, Start: %p, Depth: %u\n",
           NUM_NODES, (void*)&nodes[0], NUM_NODES);
    printf("  Completion slot: dev 0x%lx\n", f.device_addr);

    auto t2 = std::chrono::high_resolution_clock::now();
    bool offload_ok = rt.offload(FUNC_PREFETCH_CHAIN, &args, sizeof(args), &f);
    if (!offload_ok) {
        TEST_FAIL("offload() failed — args upload or kernel launch error");
    } else {
        printf("  Kernel launched, waiting for completion...\n");

        bool done = rt.future_await(f, timeout_ms);
        auto t3 = std::chrono::high_resolution_clock::now();
        double exec_us = std::chrono::duration<double, std::micro>(t3 - t2).count();

        if (done) {
            printf("  Execution time: %.1f us (%.3f ms)\n", exec_us, exec_us / 1000.0);
            TEST_PASS();
        } else {
            printf("  Timed out after %d ms\n", timeout_ms);
            TEST_FAIL("Kernel did not complete within timeout");
        }
    }

    rt.release(f);

    // ========================================================================
    // Test 5: Sequential kernel re-launch (verify device can be reused)
    // ========================================================================
    TEST_START("Re-launch kernel (device reuse after completion)");

    CiraFuture f2 = rt.future_create(1);

    PrefetchChainArgs args2 = {};
    args2.start_node     = reinterpret_cast<uint64_t>(&nodes[0]);
    args2.next_offset    = offsetof(TestNode, next);
    args2.data_offset    = offsetof(TestNode, value);
    args2.data_size      = sizeof(int64_t);
    args2.depth          = 8;  // Shorter chain this time
    args2.output_buf     = 0;
    args2.completion_addr = f2.device_addr;
    args2.task_id        = f2.id;

    auto t4 = std::chrono::high_resolution_clock::now();
    bool ok2 = rt.offload(FUNC_PREFETCH_CHAIN, &args2, sizeof(args2), &f2);
    if (!ok2) {
        TEST_FAIL("Second offload() failed");
    } else {
        bool done2 = rt.future_await(f2, timeout_ms);
        auto t5 = std::chrono::high_resolution_clock::now();
        double exec2_us = std::chrono::duration<double, std::micro>(t5 - t4).count();

        if (done2) {
            printf("  Re-launch exec time: %.1f us\n", exec2_us);
            TEST_PASS();
        } else {
            TEST_FAIL("Re-launched kernel did not complete");
        }
    }
    rt.release(f2);

    // ========================================================================
    // Test 6: Phase boundary (barrier + log)
    // ========================================================================
    TEST_START("Phase boundary (barrier sync)");
    rt.phase_boundary("test_phase");
    printf("  pending_tasks() = %u\n", rt.pending_tasks());
    if (rt.pending_tasks() == 0) {
        TEST_PASS();
    } else {
        TEST_FAIL("Expected 0 pending tasks after phase boundary");
    }

    // ========================================================================
    // Summary
    // ========================================================================
    printf("\n================================================================\n");
    printf("Results: %d/%d tests passed\n", pass_count, test_count);
    if (pass_count == test_count) {
        printf("ALL TESTS PASSED\n");
    } else {
        printf("SOME TESTS FAILED\n");
    }
    printf("================================================================\n");

    return (pass_count == test_count) ? 0 : 1;
}
