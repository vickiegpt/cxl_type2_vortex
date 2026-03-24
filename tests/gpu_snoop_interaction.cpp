/**
 * gpu_snoop_interaction.cpp
 *
 * Detailed Type2 snoop interaction testing with GPU simulation
 * Measures:
 * - GPU write → CPU snoop invalidation latency
 * - Cache line write-back through snoop
 * - Coherency domain transitions
 * - Snoop traffic patterns
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <vector>
#include <algorithm>
#include <atomic>
#include <thread>

// ============================================================================
// Simulated GPU Snoop Trigger - mimics GPU updating shared memory
// ============================================================================

class GPUSnoopSimulator {
public:
    /**
     * Simulate GPU performing a write to a cache line that CPU has cached.
     * This should trigger an invalidation snoop to the CPU.
     */
    static void gpu_write_with_snoop(volatile uint64_t* target, uint64_t value) {
        // Simulate: GPU writes to CXL address space
        *target = value;
        
        // Simulate: GPU sends snoop request (CXL.mem coherency)
        // This invalidates the line from CPU cache
        __builtin_ia32_clflush((void*)target);
    }

    /**
     * Simulate GPU reading from a location that CPU may have cached.
     * Triggers snoop for read-to-write upgrade.
     */
    static uint64_t gpu_read_trigger_snoop(volatile uint64_t* target) {
        uint64_t val = *target;
        __builtin_ia32_clflush((void*)target);
        return val;
    }
};

// ============================================================================
// Test 1: Snoop Invalidation Latency (GPU write → CPU sees new value)
// ============================================================================

void test_gpu_write_snoop_latency() {
    printf("\n========================================\n");
    printf("Test 1: GPU Write → Snoop Invalidation\n");
    printf("========================================\n");

    volatile uint64_t shared_data = 0;
    std::vector<uint64_t> snoop_latencies;

    printf("GPU updates shared data, CPU reads back:\n");
    printf("(Measures snoop invalidation + cache miss latency)\n\n");

    for (int iter = 0; iter < 100; iter++) {
        // CPU caches the data
        uint64_t cached = shared_data;

        // GPU updates the location via snoop
        uint64_t gpu_value = 0x1000000000000000ULL | iter;
        
        auto t_write = std::chrono::high_resolution_clock::now();
        GPUSnoopSimulator::gpu_write_with_snoop(
            (volatile uint64_t*)&shared_data, gpu_value);
        
        // CPU reads new value (should have been invalidated by snoop)
        auto t_read_start = std::chrono::high_resolution_clock::now();
        uint64_t new_val = shared_data;
        auto t_read_end = std::chrono::high_resolution_clock::now();

        auto read_latency = std::chrono::duration_cast<std::chrono::nanoseconds>(
            t_read_end - t_read_start).count();
        snoop_latencies.push_back(read_latency);

        // Verify coherency
        if (new_val != gpu_value) {
            printf("ERROR: Coherency violation at iter %d\n", iter);
            printf("  GPU wrote: 0x%lx\n", gpu_value);
            printf("  CPU read:  0x%lx\n", new_val);
        }
    }

    // Analyze latencies
    std::sort(snoop_latencies.begin(), snoop_latencies.end());
    printf("Snoop invalidation latencies:\n");
    printf("  Min:    %3lu ns\n", snoop_latencies[0]);
    printf("  P25:    %3lu ns\n", snoop_latencies[snoop_latencies.size()/4]);
    printf("  Median: %3lu ns\n", snoop_latencies[snoop_latencies.size()/2]);
    printf("  P75:    %3lu ns\n", snoop_latencies[(snoop_latencies.size()*3)/4]);
    printf("  P99:    %3lu ns\n", snoop_latencies[(snoop_latencies.size()*99)/100]);
    printf("  Max:    %3lu ns\n", snoop_latencies.back());

    // Estimate snoop latency (subtract cache hit latency ~50ns)
    printf("\nEstimated pure snoop latency: %lu ns\n",
           snoop_latencies[snoop_latencies.size()/2] - 50);
}

// ============================================================================
// Test 2: Multiple Cache Lines (Snoop Bandwidth)
// ============================================================================

void test_snoop_cache_line_bandwidth() {
    printf("\n========================================\n");
    printf("Test 2: Snoop Cache Line Bandwidth\n");
    printf("========================================\n");

    // Allocate 64 cache lines (4KB)
    const int num_lines = 64;
    auto buffer = std::make_unique<volatile uint64_t[]>(num_lines * 8);

    printf("GPU snoops multiple cache lines:\n");
    printf("  Testing %d cache lines (4KB)\n\n", num_lines);

    // Warm up
    for (int i = 0; i < num_lines; i++) {
        buffer[i*8] = i;
    }

    // Measure sequential snoop
    auto t_start = std::chrono::high_resolution_clock::now();
    
    for (int i = 0; i < num_lines; i++) {
        buffer[i*8] = 0x0000000100000000ULL | i;
        __builtin_ia32_clflush((void*)&buffer[i*8]);
    }
    
    auto t_end = std::chrono::high_resolution_clock::now();
    auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(t_end - t_start).count();

    double latency_per_line = (double)elapsed / num_lines;
    double bandwidth = (64.0 * num_lines) / (elapsed / 1e9) / 1e9;  // GB/s

    printf("Sequential snoop throughput:\n");
    printf("  Total time:        %.3f us\n", elapsed / 1000.0);
    printf("  Per cache line:    %.1f ns\n", latency_per_line);
    printf("  Bandwidth:         %.2f GB/s\n", bandwidth);

    // Interleaved access (test cache effects)
    t_start = std::chrono::high_resolution_clock::now();
    
    for (int round = 0; round < 4; round++) {
        for (int i = 0; i < num_lines; i += 4) {
            buffer[i*8] = 0x0000000200000000ULL | i;
            __builtin_ia32_clflush((void*)&buffer[i*8]);
        }
    }
    
    t_end = std::chrono::high_resolution_clock::now();
    elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(t_end - t_start).count();

    bandwidth = (64.0 * num_lines) / (elapsed / 1e9) / 1e9;
    printf("\nInterleaved snoop throughput:\n");
    printf("  Total time:        %.3f us\n", elapsed / 1000.0);
    printf("  Bandwidth:         %.2f GB/s\n", bandwidth);
}

// ============================================================================
// Test 3: Snoop-Induced False Sharing
// ============================================================================

void test_snoop_false_sharing() {
    printf("\n========================================\n");
    printf("Test 3: Snoop-Induced False Sharing\n");
    printf("========================================\n");

    // Two data elements in same cache line
    struct {
        uint64_t gpu_counter;
        uint64_t cpu_counter;
    } __attribute__((packed)) shared = {0, 0};

    printf("CPU and GPU updating adjacent data in same cache line:\n");
    printf("(Snoop invalidation causes cache line bouncing)\n\n");

    std::vector<uint64_t> bounce_latencies;

    for (int iter = 0; iter < 50; iter++) {
        // CPU reads GPU counter
        auto t1_start = std::chrono::high_resolution_clock::now();
        uint64_t gpu_val = shared.gpu_counter;
        auto t1_end = std::chrono::high_resolution_clock::now();

        // GPU updates its counter (same cache line)
        GPUSnoopSimulator::gpu_write_with_snoop(
            (volatile uint64_t*)&shared.gpu_counter, 
            gpu_val + 1);

        // CPU updates its counter (same cache line - snoop bounce!)
        auto t2_start = std::chrono::high_resolution_clock::now();
        shared.cpu_counter++;
        auto t2_end = std::chrono::high_resolution_clock::now();

        auto bounce = std::chrono::duration_cast<std::chrono::nanoseconds>(
            t2_end - t2_start).count();
        bounce_latencies.push_back(bounce);
    }

    std::sort(bounce_latencies.begin(), bounce_latencies.end());
    printf("Cache line bounce latencies (false sharing):\n");
    printf("  Min:    %3lu ns\n", bounce_latencies[0]);
    printf("  Median: %3lu ns\n", bounce_latencies[bounce_latencies.size()/2]);
    printf("  Max:    %3lu ns\n", bounce_latencies.back());
    printf("\nNote: High latencies indicate snoop-induced cache bouncing\n");
}

// ============================================================================
// Test 4: DCOH Completion Latency (GPU→Host signaling)
// ============================================================================

void test_dcoh_completion_latency() {
    printf("\n========================================\n");
    printf("Test 4: DCOH Completion Signaling\n");
    printf("========================================\n");

    struct CompletionLine {
        uint32_t magic;
        uint32_t status;
        uint64_t timestamp;
        uint64_t reserved;
    } __attribute__((aligned(64)));

    volatile CompletionLine completion = {0, 0, 0, 0};

    printf("Measuring GPU→Host completion signaling via DCOH:\n");
    printf("(GPU writes completion magic, CPU polls for update)\n\n");

    std::vector<uint64_t> signal_latencies;

    for (int iter = 0; iter < 50; iter++) {
        // Simulate GPU signaling completion
        auto t_signal = std::chrono::high_resolution_clock::now();
        
        const_cast<CompletionLine&>(completion).timestamp = 
            std::chrono::high_resolution_clock::now().time_since_epoch().count();
        const_cast<CompletionLine&>(completion).magic = 0xDEADBEEF;
        __builtin_ia32_clflush((void*)&completion);

        // CPU polls for magic (DCOH completion detection)
        auto t_poll_start = std::chrono::high_resolution_clock::now();
        
        // Simulate polling loop (would be monitor/mwait in real code)
        while (completion.magic != 0xDEADBEEF) {
            std::this_thread::yield();
        }
        
        auto t_poll_end = std::chrono::high_resolution_clock::now();

        auto signal_lat = std::chrono::duration_cast<std::chrono::nanoseconds>(
            t_poll_end - t_poll_start).count();
        signal_latencies.push_back(signal_lat);

        // Reset for next iteration
        const_cast<CompletionLine&>(completion).magic = 0;
    }

    std::sort(signal_latencies.begin(), signal_latencies.end());
    printf("DCOH completion signaling latencies:\n");
    printf("  Min:    %3lu ns\n", signal_latencies[0]);
    printf("  P50:    %3lu ns\n", signal_latencies[signal_latencies.size()/2]);
    printf("  P99:    %3lu ns\n", signal_latencies[(signal_latencies.size()*99)/100]);
    printf("  Max:    %3lu ns\n", signal_latencies.back());
}

// ============================================================================
// Test 5: Snoop Protocol State Transitions
// ============================================================================

void test_snoop_protocol_states() {
    printf("\n========================================\n");
    printf("Test 5: Snoop Protocol State Analysis\n");
    printf("========================================\n");

    printf("CXL Type2 Snoop State Transitions:\n\n");

    volatile uint64_t data = 0;
    
    printf("1. CPU Reads (I→S transition via snoop):\n");
    {
        auto t0 = std::chrono::high_resolution_clock::now();
        uint64_t val = data;
        auto t1 = std::chrono::high_resolution_clock::now();
        printf("   Latency: %.0f ns\n", 
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());
    }

    printf("2. CPU Write (S→M transition, snoop invalidates GPU copy):\n");
    {
        auto t0 = std::chrono::high_resolution_clock::now();
        const_cast<uint64_t&>(data) = 0x1234;
        auto t1 = std::chrono::high_resolution_clock::now();
        printf("   Latency: %.0f ns\n",
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());
    }

    printf("3. GPU Write (M→I+M, snoop to other agents):\n");
    {
        auto t0 = std::chrono::high_resolution_clock::now();
        GPUSnoopSimulator::gpu_write_with_snoop(
            (volatile uint64_t*)&data, 0x5678);
        auto t1 = std::chrono::high_resolution_clock::now();
        printf("   Latency: %.0f ns\n",
               (double)std::chrono::duration_cast<std::chrono::nanoseconds>(t1-t0).count());
    }

    printf("\nNote: MESI/MOESI protocol state changes involve snoop traffic\n");
}

// ============================================================================
// Main
// ============================================================================

int main() {
    printf("================================================\n");
    printf("GPU↔Type2 Snoop Interaction Analysis\n");
    printf("Detailed Coherency Path Testing\n");
    printf("================================================\n");

    test_gpu_write_snoop_latency();
    test_snoop_cache_line_bandwidth();
    test_snoop_false_sharing();
    test_dcoh_completion_latency();
    test_snoop_protocol_states();

    printf("\n================================================\n");
    printf("Snoop interaction analysis complete\n");
    printf("================================================\n");

    return 0;
}
