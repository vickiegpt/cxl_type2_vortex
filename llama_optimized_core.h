/**
 * llama_optimized_core.h
 *
 * Unified LLaMA optimization framework supporting:
 * - Option A: CIRA compiler optimizations (SIMD, prefetch, loop unroll)
 * - Option B: FP16 weight quantization (2x bandwidth)
 * - Option C: GPU kernel offloading (Type2 GPU acceleration)
 *
 * Single base class that all optimizations extend.
 * All three can be enabled simultaneously for maximum throughput.
 */

#pragma once

#include <cstdint>
#include <vector>
#include <memory>
#include <chrono>
#include <string>

namespace cira::runtime {

// ============================================================================
// CONFIGURATION: Controls which optimizations are active
// ============================================================================

enum class OptimizationMode : uint8_t {
    BASELINE    = 0,           // No optimizations
    CIRA_ONLY   = 1,           // Option A: SIMD, prefetch, unroll
    FP16_ONLY   = 2,           // Option B: FP16 quantization
    GPU_ONLY    = 4,           // Option C: GPU kernels
    CIRA_FP16   = CIRA_ONLY | FP16_ONLY,     // A + B
    CIRA_GPU    = CIRA_ONLY | GPU_ONLY,      // A + C
    FP16_GPU    = FP16_ONLY | GPU_ONLY,      // B + C
    ALL         = CIRA_ONLY | FP16_ONLY | GPU_ONLY  // A + B + C (AGGRESSIVE MODE)
};

struct OptimizationConfig {
    OptimizationMode mode = OptimizationMode::BASELINE;
    bool enable_cira = false;
    bool enable_fp16 = false;
    bool enable_gpu = false;
    bool enable_profiling = true;

    void set_mode(OptimizationMode m) {
        mode = m;
        enable_cira = (static_cast<uint8_t>(m) & 1) != 0;
        enable_fp16 = (static_cast<uint8_t>(m) & 2) != 0;
        enable_gpu = (static_cast<uint8_t>(m) & 4) != 0;
    }
};

// ============================================================================
// PERFORMANCE STATISTICS
// ============================================================================

struct PerfStats {
    // Timing
    double total_time_ms = 0.0;
    double embedding_time_ms = 0.0;
    double attention_time_ms = 0.0;
    double ffn_time_ms = 0.0;
    double kv_cache_time_ms = 0.0;

    // Throughput
    double tokens_per_sec = 0.0;
    double gflops = 0.0;

    // Breakdown
    double embedding_percent = 0.0;
    double attention_percent = 0.0;
    double ffn_percent = 0.0;
    double kv_cache_percent = 0.0;

    // Optimization-specific
    struct {
        double speedup_vs_baseline = 1.0;
        double cache_hit_rate = 0.0;
        double memory_traffic_gb = 0.0;
    } optimization;
};

// ============================================================================
// CORE INTERFACE: All optimizations implement this
// ============================================================================

class LLaMAOptimized {
public:
    virtual ~LLaMAOptimized() = default;

    // Initialization
    virtual bool initialize(const OptimizationConfig& config) = 0;
    virtual bool initialize_weights(const std::string& weights_path = "") = 0;
    virtual void shutdown() = 0;

    // Forward pass operations
    virtual void forward_embedding(uint32_t token_id) = 0;
    virtual void forward_attention(uint32_t layer) = 0;
    virtual void forward_ffn(uint32_t layer) = 0;
    virtual void forward_token(uint32_t token_id, uint32_t position) = 0;

    // Batch operations
    virtual void forward_sequence(const std::vector<uint32_t>& token_ids) = 0;
    virtual std::vector<float> get_logits() = 0;

    // Profiling
    virtual PerfStats get_stats() const = 0;
    virtual void reset_stats() = 0;
    virtual void print_stats() const = 0;

    // Configuration
    virtual const OptimizationConfig& get_config() const = 0;
    virtual void set_config(const OptimizationConfig& config) = 0;

    // Model info
    virtual uint32_t get_hidden_size() const = 0;
    virtual uint32_t get_vocab_size() const = 0;
    virtual uint32_t get_num_layers() const = 0;
    virtual uint32_t get_num_heads() const = 0;
};

// ============================================================================
// FACTORY: Create optimized LLaMA instance
// ============================================================================

std::unique_ptr<LLaMAOptimized> create_llama_optimized(
    const OptimizationConfig& config,
    const std::string& weights_path = ""
);

}  // namespace cira::runtime
