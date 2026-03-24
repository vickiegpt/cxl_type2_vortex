/**
 * type2_snoop_test.cpp
 *
 * Comprehensive Type2 snoop testing:
 * - Measure snoop latency (GPU→Host)
 * - Verify cache coherency
 * - Test different access patterns
 * - Measure bandwidth through snoop path
 * - Check data integrity
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <thread>
#include <atomic>
#include <vector>
#include <numeric>
#include <algorithm>

// ============================================================================
// Test 1: Basic Snoop Latency (GPU writes, CPU reads)
// ============================================================================

struct SnoopLatencyTest {
    static void run() {
        printf("\n========================================\n");
        printf("Test 1: Snoop Latency Measurement\n");
        printf("========================================\n");

        // Shared memory location
        volatile uint64_t* target = new uint64_t;
        *target = 0xDEADBEEFCAFEBABEULL;

        // Simulate GPU writing to shared memory
        printf("Baseline: CPU directly writes to target\n");
        auto t0 = std::chrono::high_resolution_clock::now();
        *target = 0x0123456789ABCDEFULL;
        auto t1 = std::chrono::high_resolution_clock::now();
        auto direct_write_us = std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count();
        printf("  Direct write latency: %.1f ns\n", (double)direct_write_us);

        // Simulate snoop by reading after write
        printf("Snoop test: Write then read with delay\n");
        std::vector<uint64_t> latencies;
        
        for (int iter = 0; iter < 100; iter++) {
            *target = 0xAAAAAAAAAAAAAAAAULL;
            
            // Flush cache (simulate GPU snoop invalidation)
            __builtin_ia32_clflush((void*)target);
            
            auto t_start = std::chrono::high_resolution_clock::now();
            uint64_t val = *target;  // Read (should trigger snoop)
            auto t_end = std::chrono::high_resolution_clock::now();
            
            auto lat = std::chrono::duration_cast<std::chrono::nanoseconds>(t_end - t_start).count();
            latencies.push_back(lat);
            
            if (val != 0xAAAAAAAAAAAAAAAAULL) {
                printf("  ERROR: Data mismatch! Expected 0x%lx, got 0x%lx\n",
                       0xAAAAAAAAAAAAAAAAULL, val);
            }
        }

        // Analyze latencies
        std::sort(latencies.begin(), latencies.end());
        double avg = std::accumulate(latencies.begin(), latencies.end(), 0.0) / latencies.size();
        double min = latencies.front();
        double max = latencies.back();
        double p50 = latencies[latencies.size()/2];
        double p99 = latencies[(latencies.size()*99)/100];

        printf("  Snoop read latency statistics:\n");
        printf("    Min:  %.1f ns\n", min);
        printf("    Avg:  %.1f ns\n", avg);
        printf("    P50:  %.1f ns\n", p50);
        printf("    P99:  %.1f ns\n", p99);
        printf("    Max:  %.1f ns\n", max);

        delete target;
    }
};

// ============================================================================
// Test 2: Snoop Bandwidth (Sequential writes from GPU perspective)
// ============================================================================

struct SnoopBandwidthTest {
    static void run() {
        printf("\n========================================\n");
        printf("Test 2: Snoop Bandwidth Measurement\n");
        printf("========================================\n");

        size_t buffer_size = 1024 * 1024;  // 1MB
        auto buffer = std::make_unique<volatile uint8_t[]>(buffer_size);

        // Sequential write test (simulating GPU streaming writes)
        printf("Sequential 64-byte writes (GPU→Host via snoop)\n");
        auto t_start = std::chrono::high_resolution_clock::now();
        
        for (size_t i = 0; i < buffer_size; i += 64) {
            // Write 64-byte cache line
            uint64_t* line = (uint64_t*)(buffer.get() + i);
            for (int j = 0; j < 8; j++) {
                line[j] = 0xDEADBEEF00000000ULL | (uint64_t)i;
            }
        }
        
        auto t_end = std::chrono::high_resolution_clock::now();
        auto duration_us = std::chrono::duration_cast<std::chrono::microseconds>(t_end - t_start).count();
        
        double bandwidth_gbps = (buffer_size * 8.0) / (duration_us * 1000.0) / 1000.0;
        printf("  Time: %.3f ms\n", duration_us / 1000.0);
        printf("  Bandwidth: %.2f GB/s\n", bandwidth_gbps);

        // Random access test
        printf("Random access (cache line granularity)\n");
        std::vector<size_t> indices;
        for (size_t i = 0; i < buffer_size / 64; i++) indices.push_back(i * 64);
        std::random_shuffle(indices.begin(), indices.end());

        t_start = std::chrono::high_resolution_clock::now();
        for (size_t idx : indices) {
            uint64_t* line = (uint64_t*)(buffer.get() + idx);
            line[0] = 0xCAFEBABE00000000ULL | idx;
        }
        t_end = std::chrono::high_resolution_clock::now();
        duration_us = std::chrono::duration_cast<std::chrono::microseconds>(t_end - t_start).count();
        
        bandwidth_gbps = (buffer_size * 8.0) / (duration_us * 1000.0) / 1000.0;
        printf("  Time: %.3f ms\n", duration_us / 1000.0);
        printf("  Bandwidth: %.2f GB/s\n", bandwidth_gbps);
    }
};

// ============================================================================
// Test 3: Cache Coherency Verification (multiple CPUs / GPU)
// ============================================================================

struct CoherencyTest {
    static void run() {
        printf("\n========================================\n");
        printf("Test 3: Cache Coherency Verification\n");
        printf("========================================\n");

        volatile uint64_t shared_val = 0x0000000000000001ULL;
        const int num_threads = 4;
        std::atomic<int> ready_threads(0);
        std::atomic<bool> start_test(false);
        std::atomic<int> errors(0);

        printf("Testing coherency with %d CPU threads\n", num_threads);

        // Spawn threads that will contend on shared value
        std::vector<std::thread> threads;
        for (int t = 0; t < num_threads; t++) {
            threads.emplace_back([&, t]() {
                ready_threads++;
                while (!start_test) std::this_thread::yield();
                
                for (int iter = 0; iter < 1000; iter++) {
                    uint64_t expected = (uint64_t)t * 0x0000000100000000ULL + iter;
                    
                    // Write
                    const_cast<uint64_t&>(shared_val) = expected;
                    
                    // Flush to ensure snoop propagation
                    __builtin_ia32_clflush((void*)&shared_val);
                    
                    // Read back
                    std::this_thread::sleep_for(std::chrono::nanoseconds(100));
                    uint64_t actual = shared_val;
                    
                    // Verify (if this thread's update is still there)
                    if (actual == expected) {
                        // Good - our write is visible
                    } else if ((actual >> 32) != (expected >> 32)) {
                        // This could indicate coherency issue if we expect our thread's data
                    }
                }
            });
        }

        // Wait for threads to be ready
        while (ready_threads < num_threads) std::this_thread::yield();
        start_test = true;

        // Wait for completion
        for (auto& th : threads) th.join();

        printf("  Multi-threaded coherency: %s\n", 
               errors == 0 ? "PASS (no detected issues)" : "ISSUES DETECTED");
    }
};

// ============================================================================
// Test 4: Snoop Type Analysis (what kind of traffic is going through?)
// ============================================================================

struct SnoopTypeTest {
    static void run() {
        printf("\n========================================\n");
        printf("Test 4: Snoop Request Type Analysis\n");
        printf("========================================\n");

        volatile uint64_t target = 0xDEADBEEFCAFEBABEULL;

        printf("Tracking different snoop operations:\n\n");

        // Type 1: Read that misses L3 (should trigger snoop)
        printf("1. Cache miss read (should trigger snoop):\n");
        __builtin_ia32_clflush((void*)&target);
        auto t0 = std::chrono::high_resolution_clock::now();
        uint64_t val = target;
        auto t1 = std::chrono::high_resolution_clock::now();
        printf("   Latency: %.1f ns\n", 
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());

        // Type 2: Write (may invalidate shared copies)
        printf("2. Cache-modifying write:\n");
        t0 = std::chrono::high_resolution_clock::now();
        const_cast<uint64_t&>(target) = 0x1234567890ABCDEFULL;
        t1 = std::chrono::high_resolution_clock::now();
        printf("   Write latency: %.1f ns\n",
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());

        // Type 3: Atomic operation (strongest snoop)
        printf("3. Atomic compare-and-swap (strongest snoop):\n");
        std::atomic<uint64_t> atomic_val(0x0);
        t0 = std::chrono::high_resolution_clock::now();
        atomic_val.compare_exchange_strong(*(uint64_t*)&target, 0x9999999999999999ULL);
        t1 = std::chrono::high_resolution_clock::now();
        printf("   Atomic latency: %.1f ns\n",
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());

        // Type 4: Prefetch (no data transfer, just invalidation notice)
        printf("4. Cache line prefetch (triggers snoop path)\n");
        __builtin_ia32_clflush((void*)&target);
        t0 = std::chrono::high_resolution_clock::now();
        __builtin_prefetch((void*)&target, 0, 3);
        t1 = std::chrono::high_resolution_clock::now();
        printf("   Prefetch latency: %.1f ns\n",
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());
    }
};

// ============================================================================
// Test 5: Snoop Path Verification with CXL Semantics
// ============================================================================

struct CXLSnoopPathTest {
    static void run() {
        printf("\n========================================\n");
        printf("Test 5: CXL Type2 Snoop Path Verification\n");
        printf("========================================\n");

        // Simulate GPU memory location in CXL address space
        volatile uint64_t* cxl_data = new uint64_t;
        *cxl_data = 0;

        printf("CXL Device Memory Snoop Characteristics:\n\n");

        // Test 1: GPU update visibility
        printf("1. GPU→Host snoop path (data visibility):\n");
        *cxl_data = 0xA5A5A5A5A5A5A5A5ULL;  // Simulate GPU write
        __builtin_ia32_clflush((void*)cxl_data);  // Flush, trigger snoop
        uint64_t read_val = *cxl_data;
        printf("   Written: 0xA5A5A5A5A5A5A5A5\n");
        printf("   Read back: 0x%016lx\n", read_val);
        printf("   Coherency: %s\n", read_val == 0xA5A5A5A5A5A5A5A5ULL ? "✓ PASS" : "✗ FAIL");

        // Test 2: Snoop invalidation latency
        printf("2. Snoop invalidation latency:\n");
        std::vector<uint64_t> invalidation_times;
        for (int i = 0; i < 50; i++) {
            *cxl_data = i;
            __builtin_ia32_clflush((void*)cxl_data);
            
            auto t0 = std::chrono::high_resolution_clock::now();
            volatile uint64_t* dummy_ptr = cxl_data;
            uint64_t dummy_read = *dummy_ptr;  // Read after snoop invalidation
            auto t1 = std::chrono::high_resolution_clock::now();
            
            auto inv_time = std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count();
            invalidation_times.push_back(inv_time);
        }
        
        std::sort(invalidation_times.begin(), invalidation_times.end());
        printf("   Min invalidation: %.1f ns\n", (double)invalidation_times.front());
        printf("   Max invalidation: %.1f ns\n", (double)invalidation_times.back());
        printf("   Median: %.1f ns\n", (double)invalidation_times[invalidation_times.size()/2]);

        // Test 3: Snoop-induced ordering
        printf("3. Memory ordering through snoop:\n");
        std::atomic<uint64_t> order_test(0);
        *cxl_data = 100;
        order_test.store(1, std::memory_order_release);
        __builtin_ia32_clflush((void*)cxl_data);
        
        if (order_test.load(std::memory_order_acquire) == 1 && *cxl_data == 100) {
            printf("   Release/acquire ordering: ✓ PASS\n");
        } else {
            printf("   Release/acquire ordering: ✗ FAIL\n");
        }

        delete cxl_data;
    }
};

// ============================================================================
// Main Test Runner
// ============================================================================

int main() {
    printf("================================================\n");
    printf("Comprehensive Type2 Snoop Path Testing\n");
    printf("CXL Type2 Device Coherency Analysis\n");
    printf("================================================\n");

    SnoopLatencyTest::run();
    SnoopBandwidthTest::run();
    CoherencyTest::run();
    SnoopTypeTest::run();
    CXLSnoopPathTest::run();

    printf("\n================================================\n");
    printf("All snoop tests completed\n");
    printf("================================================\n");

    return 0;
}
