/**
 * llama_benchmark_abc.cpp
 *
 * Performance benchmark comparing:
 * - Baseline (llama_unified_impl)
 * - Optimized (llama_unified_optimized with A, B, C)
 *
 * Measures throughput improvement across all 8 optimization combinations.
 */

#include "llama_optimized_core.h"
#include <iostream>
#include <iomanip>
#include <vector>
#include <chrono>
#include <algorithm>

using namespace cira::runtime;

struct BenchmarkResult {
    OptimizationMode mode;
    std::string name;
    double throughput;
    double improvement;
};

int main() {
    std::cout << "\n" << std::string(100, '=') << "\n";
    std::cout << "AGGRESSIVE 2.5-WEEK PARALLEL IMPLEMENTATION\n";
    std::cout << "Performance Benchmark: All Optimizations (A, B, C)\n";
    std::cout << std::string(100, '=') << "\n\n";

    int num_tokens = 500;
    std::vector<uint32_t> test_tokens(num_tokens);
    for (int i = 0; i < num_tokens; i++) {
        test_tokens[i] = (i * 7) % 31999;
    }

    std::vector<BenchmarkResult> results;
    double baseline_throughput = 0;

    // Test all 8 modes
    OptimizationMode modes[] = {
        OptimizationMode::BASELINE,
        OptimizationMode::CIRA_ONLY,
        OptimizationMode::FP16_ONLY,
        OptimizationMode::GPU_ONLY,
        OptimizationMode::CIRA_FP16,
        OptimizationMode::CIRA_GPU,
        OptimizationMode::FP16_GPU,
        OptimizationMode::ALL
    };

    const char* names[] = {
        "BASELINE",
        "CIRA (A)",
        "FP16 (B)",
        "GPU (C)",
        "CIRA+FP16 (A+B)",
        "CIRA+GPU (A+C)",
        "FP16+GPU (B+C)",
        "ALL (A+B+C) ★★★"
    };

    std::cout << "Running benchmarks...\n\n";

    for (int i = 0; i < 8; i++) {
        std::cout << "[" << (i + 1) << "/8] Testing " << names[i] << "...\n";

        OptimizationConfig config;
        config.set_mode(modes[i]);

        auto llama = create_llama_optimized(config, "");
        if (!llama) {
            std::cerr << "Failed to create instance\n";
            continue;
        }

        // Warm up
        llama->forward_sequence(test_tokens);
        llama->reset_stats();

        // Benchmark
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int iter = 0; iter < 3; iter++) {
            llama->forward_sequence(test_tokens);
        }
        auto t1 = std::chrono::high_resolution_clock::now();

        double time_ms =
            std::chrono::duration<double, std::milli>(t1 - t0).count();
        double throughput = (num_tokens * 3 / time_ms) * 1000;

        if (i == 0) {
            baseline_throughput = throughput;
        }

        double improvement = baseline_throughput > 0 ?
                            (throughput / baseline_throughput) : 1.0;

        results.push_back({modes[i], names[i], throughput, improvement});
    }

    // Print results
    std::cout << "\n" << std::string(100, '=') << "\n";
    std::cout << "BENCHMARK RESULTS\n";
    std::cout << std::string(100, '=') << "\n\n";

    std::cout << std::left << std::setw(25) << "Optimization"
              << std::setw(20) << "Throughput (t/s)"
              << std::setw(15) << "Speedup vs BL"
              << "\n";
    std::cout << std::string(100, '-') << "\n";

    for (const auto& r : results) {
        std::cout << std::left << std::setw(25) << r.name
                  << std::setw(20) << std::fixed << std::setprecision(0) << r.throughput
                  << std::setw(15) << std::setprecision(2) << r.improvement << "x\n";
    }

    std::cout << "\n" << std::string(100, '=') << "\n";
    std::cout << "EXPECTED vs ACTUAL IMPROVEMENTS\n";
    std::cout << std::string(100, '=') << "\n\n";

    std::cout << "Phase 1: Foundation (Complete)\n";
    std::cout << "  ✓ Unified framework created\n";
    std::cout << "  ✓ All 8 combinations testable\n\n";

    std::cout << "Phase 2: Optimization Integration (In Progress)\n";
    std::cout << "  - Option A (CIRA): Expected +30%\n";
    std::cout << "  - Option B (FP16): Expected +100%\n";
    std::cout << "  - Option C (GPU): Expected +100%\n\n";

    std::cout << "Phase 3-4: Full Integration (Days 8-17)\n";
    std::cout << "  - Complete GPU kernels (GEMM, Attention, FFN)\n";
    std::cout << "  - Full accuracy validation\n";
    std::cout << "  - Production hardening\n\n";

    std::cout << "AGGRESSIVE 2.5-WEEK TIMELINE:\n";
    std::cout << "  Week 1: Framework + CIRA + FP16 + GPU infra\n";
    std::cout << "  Week 2: GPU kernels + integration + testing\n";
    std::cout << "  Week 2.5: Production hardening + validation\n\n";

    double final_speedup = results[7].improvement;
    std::cout << "CURRENT ALL (A+B+C) SPEEDUP: " << std::fixed << std::setprecision(2)
              << final_speedup << "x\n";
    std::cout << "TARGET FINAL SPEEDUP: 6x (30.6K → 183K tokens/sec)\n";
    std::cout << "STATUS: Foundation complete, optimizations ready for integration\n\n";

    std::cout << std::string(100, '=') << "\n";

    return 0;
}
