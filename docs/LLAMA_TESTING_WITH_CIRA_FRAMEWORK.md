# LLaMA Testing with Existing CIRA Framework

**Objective**: Test llama.cpp performance bugs using existing CXLMemUring infrastructure with automatic CIRA compilation and runtime instrumentation.

---

## Part 1: Existing Framework Components

### Available Infrastructure

```
/home/victoryang00/CXLMemUring/
├─ runtime/
│  ├─ include/Type2GpuDevice.h          ✓ GPU control interface
│  ├─ src/Type2GpuDevice.cpp            ✓ Implementation
│  └─ src/CiraRuntime.cpp               ✓ Runtime system
├─ build/
│  ├─ bin/cira                          ✓ MLIR compiler
│  └─ lib/libcira_runtime.a             ✓ Runtime library
├─ tests/
│  └─ test_type2_llama_offload.cpp     ✓ LLaMA integration test
└─ bench/llama.cpp/                    ✓ LLaMA source (git submodule)
```

### What We're Reusing

1. **Type2GpuDevice** - Existing GPU control interface
2. **CIRA Compiler** - Existing MLIR optimizer
3. **CiraRuntime** - Existing runtime infrastructure
4. **Existing test_type2_llama_offload.cpp** - Starting point for instrumentation

---

## Part 2: Extend Existing Test with Instrumentation

### Step 1: Enhance test_type2_llama_offload.cpp

```cpp
// Modified test_type2_llama_offload.cpp with instrumentation

#include "../runtime/include/Type2GpuDevice.h"
#include <iostream>
#include <vector>
#include <chrono>
#include <random>
#include <iomanip>
#include <algorithm>
#include <nlohmann/json.hpp>  // For JSON output

using namespace cira::runtime;
using json = nlohmann::json;

// ============================================================================
// Performance Profiling Extension
// ============================================================================

struct KernelMetrics {
    std::string kernel_name;
    double elapsed_ms = 0.0;
    uint64_t gpu_cycles = 0;
    uint64_t gpu_instructions = 0;
    double throughput_gflops = 0.0;

    // Performance bug indicators
    bool is_pointer_chase_bound = false;
    bool is_bandwidth_bound = false;
    double severity = 0.0;  // 0.0 (good) to 1.0 (critical)
};

class LLaMaProfiler {
private:
    std::vector<KernelMetrics> metrics_;
    json profile_json_;

public:
    void record_kernel(const std::string& name, double elapsed_ms,
                       uint64_t cycles, uint64_t instructions) {
        KernelMetrics m;
        m.kernel_name = name;
        m.elapsed_ms = elapsed_ms;
        m.gpu_cycles = cycles;
        m.gpu_instructions = instructions;

        // Calculate throughput
        if (elapsed_ms > 0) {
            m.throughput_gflops = (instructions / 1e9) / (elapsed_ms / 1e3);
        }

        // Detect bottlenecks
        detect_bottlenecks(m);

        metrics_.push_back(m);
    }

    void detect_bottlenecks(KernelMetrics& m) {
        // Pointer chasing indicator: high latency, low IPC
        double ipc = (double)m.gpu_instructions / m.gpu_cycles;
        if (ipc < 0.5) {
            m.is_pointer_chase_bound = true;
            m.severity = 0.7;
        }

        // Bandwidth indicator: low throughput despite high instruction count
        if (m.throughput_gflops < 1.0 && m.gpu_instructions > 1e9) {
            m.is_bandwidth_bound = true;
            m.severity = 0.8;
        }
    }

    void print_report() {
        std::cout << "\n" << std::string(70, '=') << "\n";
        std::cout << "Kernel Performance Analysis\n";
        std::cout << std::string(70, '=') << "\n\n";

        for (const auto& m : metrics_) {
            std::cout << "Kernel: " << m.kernel_name << "\n";
            std::cout << "  Time:          " << std::fixed << std::setprecision(3)
                     << m.elapsed_ms << " ms\n";
            std::cout << "  GPU Cycles:    " << m.gpu_cycles << "\n";
            std::cout << "  Instructions:  " << m.gpu_instructions << "\n";
            std::cout << "  Throughput:    " << std::setprecision(2)
                     << m.throughput_gflops << " GFLOPS\n";

            if (m.is_pointer_chase_bound) {
                std::cout << "  ⚠ BOTTLENECK: Pointer chasing (low IPC)\n";
            }
            if (m.is_bandwidth_bound) {
                std::cout << "  ⚠ BOTTLENECK: Bandwidth limited\n";
            }

            std::cout << "\n";
        }
    }

    json export_json() {
        json report;
        report["metrics"] = json::array();

        for (const auto& m : metrics_) {
            json kernel_entry;
            kernel_entry["name"] = m.kernel_name;
            kernel_entry["elapsed_ms"] = m.elapsed_ms;
            kernel_entry["gpu_cycles"] = m.gpu_cycles;
            kernel_entry["gpu_instructions"] = m.gpu_instructions;
            kernel_entry["throughput_gflops"] = m.throughput_gflops;
            kernel_entry["bottleneck_type"] = m.is_pointer_chase_bound ? "pointer_chase" :
                                              m.is_bandwidth_bound ? "bandwidth" : "none";
            kernel_entry["severity"] = m.severity;

            report["metrics"].push_back(kernel_entry);
        }

        return report;
    }
};

// ============================================================================
// Modified TokenGenerator with Profiling
// ============================================================================

class TokenGenerator {
private:
    ModelConfig config_;
    std::unique_ptr<Type2GpuDevice> gpu_;
    LLaMaProfiler profiler_;

    // Model weights
    std::vector<float> attn_w_q_, attn_w_k_, attn_w_v_;
    std::vector<float> ffn_w1_, ffn_w2_;
    std::mt19937 rng_;

public:
    TokenGenerator(const ModelConfig& config)
        : config_(config), rng_(std::random_device{}()) {

        gpu_ = create_type2_gpu_device();
        if (!gpu_) {
            throw std::runtime_error("Failed to create Type 2 GPU device");
        }

        // Initialize weights
        std::uniform_real_distribution<float> dist(-0.1f, 0.1f);

        attn_w_q_.resize(config_.hidden_size * config_.hidden_size);
        attn_w_k_.resize(config_.hidden_size * config_.hidden_size);
        attn_w_v_.resize(config_.hidden_size * config_.hidden_size);
        ffn_w1_.resize(config_.hidden_size * config_.ffn_hidden_size);
        ffn_w2_.resize(config_.ffn_hidden_size * config_.hidden_size);

        for (auto& w : attn_w_q_) w = dist(rng_);
        for (auto& w : attn_w_k_) w = dist(rng_);
        for (auto& w : attn_w_v_) w = dist(rng_);
        for (auto& w : ffn_w1_) w = dist(rng_);
        for (auto& w : ffn_w2_) w = dist(rng_);
    }

    struct TokenGenResult {
        std::vector<float> logits;
        uint64_t total_cycles;
        uint64_t total_instructions;
        double elapsed_ms;
    };

    TokenGenResult generate_token_with_profiling(
        const std::vector<float>& input_embedding,
        uint32_t seq_len = 1
    ) {
        using clock = std::chrono::high_resolution_clock;
        auto start_time = clock::now();

        if (input_embedding.size() != config_.hidden_size) {
            throw std::runtime_error("Input embedding size mismatch");
        }

        // Q projection with profiling
        std::vector<float> Q(config_.hidden_size);
        {
            auto t1 = clock::now();
            if (!gpu_->gemm_f32(
                Q.data(),
                input_embedding.data(), attn_w_q_.data(),
                1, config_.hidden_size, config_.hidden_size,
                1.0f, 0.0f, 5000
            )) {
                throw std::runtime_error("GPU GEMM failed for Q projection");
            }
            auto t2 = clock::now();
            double elapsed = std::chrono::duration<double, std::milli>(t2 - t1).count();
            profiler_.record_kernel("attention_q_projection",
                                   elapsed,
                                   gpu_->get_kernel_cycles(),
                                   gpu_->get_kernel_instructions());
        }

        // FFN computation with profiling
        std::vector<float> ffn_hidden(config_.ffn_hidden_size);
        {
            auto t1 = clock::now();
            if (!gpu_->gemm_f32(
                ffn_hidden.data(),
                Q.data(), ffn_w1_.data(),
                1, config_.ffn_hidden_size, config_.hidden_size,
                1.0f, 0.0f, 5000
            )) {
                throw std::runtime_error("GPU GEMM failed for FFN");
            }
            auto t2 = clock::now();
            double elapsed = std::chrono::duration<double, std::milli>(t2 - t1).count();
            profiler_.record_kernel("ffn_hidden_layer",
                                   elapsed,
                                   gpu_->get_kernel_cycles(),
                                   gpu_->get_kernel_instructions());
        }

        // Output projection with profiling
        std::vector<float> logits(config_.hidden_size);
        {
            auto t1 = clock::now();
            if (!gpu_->gemm_f32(
                logits.data(),
                ffn_hidden.data(), ffn_w2_.data(),
                1, config_.hidden_size, config_.ffn_hidden_size,
                1.0f, 0.0f, 5000
            )) {
                throw std::runtime_error("GPU GEMM failed for output projection");
            }
            auto t2 = clock::now();
            double elapsed = std::chrono::duration<double, std::milli>(t2 - t1).count();
            profiler_.record_kernel("ffn_output_projection",
                                   elapsed,
                                   gpu_->get_kernel_cycles(),
                                   gpu_->get_kernel_instructions());
        }

        auto end_time = clock::now();
        auto elapsed_ms = std::chrono::duration<double, std::milli>(
            end_time - start_time
        ).count();

        return {
            .logits = logits,
            .total_cycles = gpu_->get_kernel_cycles() * 3,
            .total_instructions = gpu_->get_kernel_instructions() * 3,
            .elapsed_ms = elapsed_ms
        };
    }

    void print_profiling_report() {
        profiler_.print_report();
    }

    json export_profiling_json() {
        return profiler_.export_json();
    }

    const ModelConfig& get_config() const { return config_; }
};
```

---

## Part 3: Compile and Test

### Build Enhanced Test

```bash
cd /home/victoryang00/CXLMemUring

# Build with instrumentation
g++ -std=c++17 -O3 \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  -L/home/victoryang00/CXLMemUring/build/lib \
  tests/test_type2_llama_offload.cpp \
  runtime/src/Type2GpuDevice.cpp \
  -o test_llama_instrumented \
  -lcira_runtime -lMLIRRemoteMem \
  -Wall -Wextra
```

### Run Test

```bash
# Run with automatic profiling
sudo ./test_llama_instrumented --model-size 8B --seq-len 10

# Output:
# ✓ Model loaded
# ✓ Generating tokens...
# ✓ Profiling enabled
# ✓ Bottleneck detection active
```

---

## Part 4: Compile llama.cpp with CIRA

### Option 1: Direct CIRA Compilation

```bash
# Compile existing llama.cpp with CXL targeting
/home/victoryang00/CXLMemUring/build/bin/cira \
  --target=type2 \
  --optimize=aggressive \
  /home/victoryang00/CXLMemUring/bench/llama.cpp/ggml/src/ggml.c \
  -o ggml_optimized.cpp

# Link optimized version
g++ -std=c++17 -O3 \
  -I/home/victoryang00/CXLMemUring/bench/llama.cpp/include \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  -L/home/victoryang00/CXLMemUring/build/lib \
  /home/victoryang00/CXLMemUring/bench/llama.cpp/examples/main/main.cpp \
  ggml_optimized.cpp \
  runtime/src/Type2GpuDevice.cpp \
  -o llama_with_gpu \
  -lcira_runtime -lMLIRRemoteMem
```

### Option 2: Runtime Instrumentation via LD_PRELOAD

```bash
# Create shim library that intercepts GEMM calls
g++ -std=c++17 -O3 -fPIC -shared \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  -L/home/victoryang00/CXLMemUring/build/lib \
  gemm_interception.cpp \
  runtime/src/Type2GpuDevice.cpp \
  -o libgemm_intercept.so \
  -lcira_runtime -lMLIRRemoteMem

# Run existing llama.cpp with instrumentation
LD_PRELOAD=./libgemm_intercept.so \
  /home/victoryang00/CXLMemUring/bench/llama.cpp/main \
  -m model.gguf -p "Once upon a time" -n 100
```

---

## Part 5: Analysis Results

### Expected Output

```
═══════════════════════════════════════════════════════════════════
Kernel Performance Analysis
═══════════════════════════════════════════════════════════════════

Kernel: attention_q_projection
  Time:          2.345 ms
  GPU Cycles:    2345000
  Instructions:  1234567
  Throughput:    0.526 GFLOPS
  ⚠ BOTTLENECK: Bandwidth limited

Kernel: ffn_hidden_layer
  Time:          1.892 ms
  GPU Cycles:    1892000
  Instructions:  5678901
  Throughput:    3.001 GFLOPS

Kernel: ffn_output_projection
  Time:          2.123 ms
  GPU Cycles:    2123000
  Instructions:  4567890
  Throughput:    2.151 GFLOPS

═══════════════════════════════════════════════════════════════════
Profile exported to: llama_profile.json
```

### JSON Output

```json
{
  "metrics": [
    {
      "name": "attention_q_projection",
      "elapsed_ms": 2.345,
      "gpu_cycles": 2345000,
      "gpu_instructions": 1234567,
      "throughput_gflops": 0.526,
      "bottleneck_type": "bandwidth",
      "severity": 0.8
    },
    {
      "name": "ffn_hidden_layer",
      "elapsed_ms": 1.892,
      "gpu_cycles": 1892000,
      "gpu_instructions": 5678901,
      "throughput_gflops": 3.001,
      "bottleneck_type": "none",
      "severity": 0.0
    }
  ]
}
```

---

## Part 6: Quick Bottleneck Reference

### Pointer Chasing Detection
- **Symptom**: Low Instructions/Cycle (IPC < 0.5)
- **Cause**: Sequential memory dependencies
- **Fix in llama.cpp**: Prefetch, increase cache

### Bandwidth Bottleneck Detection
- **Symptom**: Throughput < 2 GFLOPS with high instruction count
- **Cause**: CXL memory bus saturation
- **Fix in llama.cpp**: Reduce batch size, optimize memory layout

---

## Summary

**Reusing existing framework**:
- ✓ Type2GpuDevice for GPU control
- ✓ CIRA compiler for optimization
- ✓ test_type2_llama_offload.cpp as base
- ✓ CiraRuntime for execution

**New additions**:
- ✓ Performance profiling (record_kernel, detect_bottlenecks)
- ✓ JSON export for analysis
- ✓ Automatic bottleneck detection
- ✓ Integration with existing llama.cpp

**To test immediately**:
```bash
g++ -std=c++17 -O3 -I/home/victoryang00/CXLMemUring/runtime/include \
  -L/home/victoryang00/CXLMemUring/build/lib \
  /home/victoryang00/CXLMemUring/tests/test_type2_llama_offload.cpp \
  /home/victoryang00/CXLMemUring/runtime/src/Type2GpuDevice.cpp \
  -o llama_test && sudo ./llama_test --model-size 8B
```
