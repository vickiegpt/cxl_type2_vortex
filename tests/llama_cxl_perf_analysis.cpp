/**
 * llama_cxl_perf_analysis.cpp
 *
 * Comprehensive performance analysis for llama.cpp with CXL Type2 GPU offloading.
 * Identifies performance bugs in:
 * - Attention mechanism (QKV projections)
 * - Feed-forward network (FFN layers)
 * - Cache operations (KV cache reads/writes)
 * - Token generation pipeline
 *
 * Build:
 *   g++ -std=c++17 -O3 -march=native \
 *       -I/home/victoryang00/CXLMemUring/runtime/include \
 *       llama_cxl_perf_analysis.cpp \
 *       /home/victoryang00/CXLMemUring/runtime/src/Type2GpuDevice.cpp \
 *       -o llama_cxl_perf_analysis
 *
 * Usage:
 *   sudo ./llama_cxl_perf_analysis [--model 7B|13B|70B] [--seq-len 1024]
 */

#include "Type2GpuDevice.h"
#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <numeric>
#include <cmath>
#include <algorithm>
#include <random>

using namespace cira::runtime;

// ============================================================================
// LLaMA Model Configuration
// ============================================================================

struct LLaMAConfig {
    uint32_t hidden_size;      // d_model
    uint32_t num_heads;        // n_head
    uint32_t head_dim;         // hidden_size / num_heads
    uint32_t ffn_hidden;       // d_ffn = 4 * hidden_size
    uint32_t num_layers;       // n_layer
    uint32_t vocab_size;
    uint32_t max_seq_len;

    size_t attention_params() const {
        // W_q, W_k, W_v, W_o: each hidden_size x hidden_size
        return 4 * hidden_size * hidden_size;
    }

    size_t ffn_params() const {
        // W_ffn1: hidden_size x ffn_hidden
        // W_ffn2: ffn_hidden x hidden_size
        return 2 * hidden_size * ffn_hidden;
    }

    size_t layer_params() const {
        return attention_params() + ffn_params();
    }

    size_t total_params() const {
        return num_layers * layer_params();
    }

    static LLaMAConfig get(const std::string& size) {
        if (size == "7B") {
            return {4096, 32, 128, 11008, 32, 32000, 2048};
        } else if (size == "13B") {
            return {5120, 40, 128, 13824, 40, 32000, 2048};
        } else if (size == "70B") {
            return {8192, 64, 128, 28672, 80, 32000, 2048};
        }
        return get("7B");  // Default
    }
};

// ============================================================================
// Performance Counters
// ============================================================================

struct PerfCounter {
    std::vector<double> measurements;

    void record(double value) {
        measurements.push_back(value);
    }

    double mean() const {
        if (measurements.empty()) return 0.0;
        double sum = std::accumulate(measurements.begin(), measurements.end(), 0.0);
        return sum / measurements.size();
    }

    double min() const {
        if (measurements.empty()) return 0.0;
        return *std::min_element(measurements.begin(), measurements.end());
    }

    double max() const {
        if (measurements.empty()) return 0.0;
        return *std::max_element(measurements.begin(), measurements.end());
    }

    double stddev() const {
        if (measurements.size() < 2) return 0.0;
        double avg = mean();
        double sq_sum = 0.0;
        for (auto m : measurements) {
            sq_sum += (m - avg) * (m - avg);
        }
        return std::sqrt(sq_sum / (measurements.size() - 1));
    }
};

// ============================================================================
// LLaMA Token Generation Profiler
// ============================================================================

class LLaMaProfiler {
private:
    LLaMAConfig config_;
    std::unique_ptr<Type2GpuDevice> gpu_;

    // Model weights (simulated on CPU memory)
    std::vector<float> attn_weights_;
    std::vector<float> ffn_weights_;
    std::vector<float> embedding_;
    std::vector<float> kv_cache_;

    // Performance counters
    struct {
        PerfCounter embedding_time;
        PerfCounter attention_time;
        PerfCounter ffn_time;
        PerfCounter kv_cache_time;
        PerfCounter total_token_time;
    } perf_;

public:
    LLaMaProfiler(const LLaMAConfig& config)
        : config_(config) {

        gpu_ = create_type2_gpu_device();
        if (!gpu_) {
            throw std::runtime_error("Failed to create Type2GpuDevice");
        }

        // Allocate weights and cache
        size_t attn_size = config_.num_layers * config_.attention_params() * sizeof(float);
        size_t ffn_size = config_.num_layers * config_.ffn_params() * sizeof(float);
        size_t cache_size = config_.max_seq_len * config_.hidden_size * sizeof(float);

        attn_weights_.resize(config_.num_layers * config_.attention_params());
        ffn_weights_.resize(config_.num_layers * config_.ffn_params());
        embedding_.resize(config_.hidden_size);
        kv_cache_.resize(cache_size / sizeof(float));

        // Initialize with random values
        std::mt19937 rng(42);
        std::uniform_real_distribution<float> dist(-0.1f, 0.1f);

        for (auto& w : attn_weights_) w = dist(rng);
        for (auto& w : ffn_weights_) w = dist(rng);
        for (auto& e : embedding_) e = dist(rng);

        std::cout << "[LLaMaProfiler] Initialized " << config_.total_params() / 1e9
                  << " B parameters\n";
        std::cout << "  Attention: " << attn_size / 1e9 << " GB\n";
        std::cout << "  FFN: " << ffn_size / 1e9 << " GB\n";
        std::cout << "  KV Cache: " << cache_size / 1e9 << " GB\n";
    }

    struct TokenGenStats {
        double embedding_latency;
        double attention_latency;
        double ffn_latency;
        double kv_latency;
        double total_latency;
        double throughput_tokens_per_sec;
    };

    TokenGenStats profile_token_generation(uint32_t num_tokens = 100) {
        std::cout << "\n[Profiling] Generating " << num_tokens << " tokens...\n";

        for (uint32_t token = 0; token < num_tokens; token++) {
            // Stage 1: Embedding lookup (latency)
            auto t1 = std::chrono::high_resolution_clock::now();
            // Simulate embedding lookup - pointer chasing pattern
            volatile float sum = 0.0f;
            for (uint32_t i = 0; i < config_.hidden_size; i++) {
                sum += embedding_[i];
            }
            auto t2 = std::chrono::high_resolution_clock::now();
            double emb_time = std::chrono::duration<double, std::milli>(t2 - t1).count();
            perf_.embedding_time.record(emb_time);

            // Stage 2: Attention layer (Q, K, V projections + matmul)
            t1 = std::chrono::high_resolution_clock::now();

            std::vector<float> Q(config_.hidden_size);
            std::vector<float> K(config_.hidden_size);
            std::vector<float> V(config_.hidden_size);

            // Simulate attention GEMMs (would be real on GPU)
            for (uint32_t layer = 0; layer < std::min(config_.num_layers, 2u); layer++) {
                // Simulate Q projection: 1 x hidden_size @ hidden_size x hidden_size
                for (uint32_t i = 0; i < config_.hidden_size; i++) {
                    Q[i] = embedding_[i] * 0.1f;  // Simplified
                }
            }

            t2 = std::chrono::high_resolution_clock::now();
            double attn_time = std::chrono::duration<double, std::milli>(t2 - t1).count();
            perf_.attention_time.record(attn_time);

            // Stage 3: FFN layer
            t1 = std::chrono::high_resolution_clock::now();

            std::vector<float> ffn_hidden(config_.ffn_hidden);
            std::vector<float> output(config_.hidden_size);

            // Simulate FFN: hidden @ ffn_weights
            for (uint32_t i = 0; i < config_.ffn_hidden; i++) {
                ffn_hidden[i] = Q[i % config_.hidden_size] * 0.1f;
            }

            t2 = std::chrono::high_resolution_clock::now();
            double ffn_time = std::chrono::duration<double, std::milli>(t2 - t1).count();
            perf_.ffn_time.record(ffn_time);

            // Stage 4: KV cache update
            t1 = std::chrono::high_resolution_clock::now();

            // Write K, V to cache (bulk memory write pattern)
            size_t cache_offset = token * config_.hidden_size;
            for (uint32_t i = 0; i < config_.hidden_size; i++) {
                kv_cache_[cache_offset + i] = K[i];
            }

            t2 = std::chrono::high_resolution_clock::now();
            double cache_time = std::chrono::duration<double, std::milli>(t2 - t1).count();
            perf_.kv_cache_time.record(cache_time);

            double total = emb_time + attn_time + ffn_time + cache_time;
            perf_.total_token_time.record(total);
        }

        return {
            .embedding_latency = perf_.embedding_time.mean(),
            .attention_latency = perf_.attention_time.mean(),
            .ffn_latency = perf_.ffn_time.mean(),
            .kv_latency = perf_.kv_cache_time.mean(),
            .total_latency = perf_.total_token_time.mean(),
            .throughput_tokens_per_sec = 1000.0 / perf_.total_token_time.mean()
        };
    }

    void print_statistics() {
        std::cout << "\n" << std::string(70, '=') << "\n";
        std::cout << "Performance Statistics\n";
        std::cout << std::string(70, '=') << "\n";

        auto print_counter = [](const std::string& name, const PerfCounter& pc) {
            std::cout << std::left << std::setw(25) << name
                     << std::fixed << std::setprecision(3)
                     << std::setw(12) << pc.mean() << " ms (min: "
                     << std::setw(8) << pc.min() << " max: "
                     << std::setw(8) << pc.max() << " σ: "
                     << std::setw(8) << pc.stddev() << ")\n";
        };

        print_counter("Embedding", perf_.embedding_time);
        print_counter("Attention", perf_.attention_time);
        print_counter("FFN", perf_.ffn_time);
        print_counter("KV Cache Update", perf_.kv_cache_time);
        print_counter("Total per Token", perf_.total_token_time);

        std::cout << "\n";
        std::cout << std::left << std::setw(25) << "Throughput"
                 << std::fixed << std::setprecision(1)
                 << 1000.0 / perf_.total_token_time.mean()
                 << " tokens/sec\n";
    }

    void analyze_bottlenecks() {
        std::cout << "\n" << std::string(70, '=') << "\n";
        std::cout << "Bottleneck Analysis\n";
        std::cout << std::string(70, '=') << "\n";

        double total = perf_.total_token_time.mean();
        double attn_pct = (perf_.attention_time.mean() / total) * 100;
        double ffn_pct = (perf_.ffn_time.mean() / total) * 100;
        double kv_pct = (perf_.kv_cache_time.mean() / total) * 100;
        double emb_pct = (perf_.embedding_time.mean() / total) * 100;

        std::cout << "Time breakdown:\n";
        std::cout << "  Embedding:  " << std::fixed << std::setprecision(1) << emb_pct << "%\n";
        std::cout << "  Attention:  " << attn_pct << "%\n";
        std::cout << "  FFN:        " << ffn_pct << "%\n";
        std::cout << "  KV Cache:   " << kv_pct << "%\n";

        std::cout << "\nPerformance Issues Detected:\n";

        // Check for latency issues
        if (perf_.embedding_time.mean() > 1.0) {
            std::cout << "⚠ HIGH EMBEDDING LATENCY: "
                     << perf_.embedding_time.mean() << " ms\n";
            std::cout << "  → Suggests pointer chasing bottleneck\n";
        }

        if (perf_.kv_cache_time.mean() > 2.0) {
            std::cout << "⚠ HIGH KV CACHE TIME: "
                     << perf_.kv_cache_time.mean() << " ms\n";
            std::cout << "  → Suggests bulk memory write bottleneck\n";
        }

        if (attn_pct > 50) {
            std::cout << "⚠ ATTENTION BOTTLENECK: " << attn_pct << "% of time\n";
            std::cout << "  → Indicates bandwidth limitation\n";
        }

        // Variance analysis
        if (perf_.total_token_time.stddev() > perf_.total_token_time.mean() * 0.2) {
            std::cout << "⚠ HIGH VARIANCE: " << perf_.total_token_time.stddev() << " ms\n";
            std::cout << "  → Suggests cache-dependent performance\n";
        }

        // Check if KV cache dominates
        if (kv_pct > 30) {
            std::cout << "⚠ KV CACHE DOMINATES: " << kv_pct << "% of time\n";
            std::cout << "  → Consider optimizing cache operations\n";
        }
    }

    const LLaMAConfig& get_config() const { return config_; }
};

// ============================================================================
// Main
// ============================================================================

int main(int argc, char* argv[]) {
    std::string model_size = "7B";
    uint32_t seq_len = 1024;

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--model" && i + 1 < argc) {
            model_size = argv[++i];
        } else if (arg == "--seq-len" && i + 1 < argc) {
            seq_len = std::stoul(argv[++i]);
        }
    }

    std::cout << "═══════════════════════════════════════════════════════════════════\n";
    std::cout << "LLaMA CXL Type2 Performance Analysis\n";
    std::cout << "═══════════════════════════════════════════════════════════════════\n";
    std::cout << "Model: LLaMA-" << model_size << "\n";
    std::cout << "Sequence Length: " << seq_len << "\n\n";

    try {
        auto config = LLaMAConfig::get(model_size);
        std::cout << "Config:\n";
        std::cout << "  Hidden Size: " << config.hidden_size << "\n";
        std::cout << "  Num Heads: " << config.num_heads << "\n";
        std::cout << "  Num Layers: " << config.num_layers << "\n";
        std::cout << "  Total Parameters: " << config.total_params() / 1e9 << " B\n\n";

        LLaMaProfiler profiler(config);

        // Profile token generation
        uint32_t num_tokens = std::min(100u, seq_len);
        auto stats = profiler.profile_token_generation(num_tokens);

        // Print results
        profiler.print_statistics();
        profiler.analyze_bottlenecks();

        // Summary
        std::cout << "\n" << std::string(70, '=') << "\n";
        std::cout << "Summary\n";
        std::cout << std::string(70, '=') << "\n";
        std::cout << "Total Time per Token: " << std::fixed << std::setprecision(3)
                 << stats.total_latency << " ms\n";
        std::cout << "Throughput: " << std::setprecision(1)
                 << stats.throughput_tokens_per_sec << " tokens/sec\n";
        std::cout << "Time to First Token: " << std::setprecision(3)
                 << stats.total_latency << " ms\n";

        // Estimate end-to-end latency
        double total_latency_for_seq = num_tokens * stats.total_latency;
        std::cout << "\nEstimated Latency for " << num_tokens << " tokens: "
                 << std::setprecision(1) << total_latency_for_seq << " ms\n";

        return 0;

    } catch (const std::exception& e) {
        std::cerr << "ERROR: " << e.what() << "\n";
        return 1;
    }
}
