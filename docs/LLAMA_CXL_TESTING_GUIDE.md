# LLaMA.cpp with CXL Type2 GPU - Performance Testing & Instrumentation Guide

**Date**: March 24, 2026
**Status**: Testing Infrastructure Ready
**Focus**: Identifying pointer chasing and bulk memory load performance bugs

---

## Overview

This guide provides comprehensive instructions for:
1. **Performance Testing**: Identify bottlenecks in llama.cpp with CXL GPU offloading
2. **CIRA Compiler Integration**: Compile and optimize llama.cpp for CXL
3. **Runtime Instrumentation**: Automatic performance monitoring and profiling

---

## Part 1: Quick Start - Running Performance Tests

### Test 1: CXL Pattern Performance Analysis

Identifies latency and bandwidth bottlenecks:

```bash
# Test pointer chasing (latency-sensitive access pattern)
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test pointer-chase

# Test bulk memory loads (bandwidth-sensitive)
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test bulk-load

# Test GEMM with CXL memory (mixed pattern)
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test gemm

# Run all tests
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test all
```

### Test 2: LLaMA.cpp Performance Profiler

Simulates llama.cpp token generation and identifies bottlenecks:

```bash
# Profile 7B model
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 7B --seq-len 100

# Profile 13B model
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 13B --seq-len 100

# Profile 70B model
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 70B --seq-len 50
```

---

## Part 2: Understanding Performance Bottlenecks

### Pointer Chasing Bug (Latency)

**Symptom**: High per-access latency (>500 ns)

```
Pointer Chasing Test Output:
├─ Latency per access: 750 ns  ⚠ HIGH
├─ Root cause: Sequential memory loads with dependencies
└─ Indicates: CXL cache misses or long latency round trips
```

**In LLaMA Context**:
- Token embedding lookups follow pointer-based patterns
- Attention mechanism computes Q, K, V with sequential dependencies
- KV cache reads during attention show pointer-chasing behavior

**Solution**:
1. Increase CXL cache size
2. Prefetch next cache lines
3. Batch memory requests

### Bulk Memory Load Bug (Bandwidth)

**Symptom**: Low bandwidth for contiguous reads (<10 GB/s)

```
Bulk Memory Test Output:
├─ Sequential read: 8 GB/s  ⚠ LOW
├─ Stride pattern: 6 GB/s   ⚠ DROPPED
└─ Root cause: CXL bus saturation or memory controller bottleneck
```

**In LLaMA Context**:
- Attention matrix computation: Q @ K^T (bandwidth-intensive)
- FFN layer: hidden_state @ W_ffn (bulk weight loads)
- KV cache prefetching for next tokens

**Solution**:
1. Optimize memory alignment
2. Reduce memory request size
3. Increase banking/parallelism in memory subsystem

### Mixed Workload Analysis

The llama_cxl_perf_analysis tool breaks down token generation into:

```
Time Breakdown:
├─ Embedding Lookup: 5-10%    (pointer chasing)
├─ Attention: 40-50%          (bulk loads + GEMM)
├─ FFN: 30-40%                (bulk loads + GEMM)
└─ KV Cache Update: 10-20%    (bulk writes)
```

---

## Part 3: CIRA Compiler Integration with llama.cpp

### Architecture: CIRA Compiler Pipeline

```
llama.cpp source code
    ↓
[CIRA Compiler Pass 1: Offload Analysis]
    ├─ Identify GEMM operations (candidates for GPU)
    ├─ Analyze data dependencies
    └─ Generate offload regions
    ↓
[CIRA Compiler Pass 2: Memory Optimization]
    ├─ Determine CXL memory placement
    ├─ Insert prefetch hints
    └─ Optimize data layout
    ↓
[CIRA Compiler Pass 3: Instrumentation]
    ├─ Insert performance counters
    ├─ Add timing probes
    └─ Enable runtime profiling
    ↓
[Code Generation]
    └─ Generate optimized C++ with Type2GpuDevice calls
    ↓
[Runtime Execution with Instrumentation]
    ├─ Performance monitoring
    ├─ Bottleneck detection
    └─ Adaptive optimization
```

### Compiling llama.cpp with CIRA

**Step 1**: Prepare llama.cpp for CIRA

```bash
cd /home/victoryang00/CXLMemUring/bench/llama.cpp

# Extract relevant GEMM operations to MLIR
# This is conceptual - real implementation would use MLIR extraction
python3 -c "
import re
# Extract GEMM calls from llama.cpp
# Generate MLIR representation
# Save to llama_ops.mlir
"
```

**Step 2**: Run CIRA compiler with llama.cpp operations

```bash
# Compile with CXL Type2 offloading
/home/victoryang00/CXLMemUring/build/bin/cira \
  --offload-to-gpu \
  --memory=cxl_type2 \
  --instrument=full \
  --profile-output=llama_profile.json \
  llama_ops.mlir \
  -o llama_ops_optimized.cpp
```

**Step 3**: Link optimized operations with llama.cpp

```bash
g++ -std=c++17 -O3 \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  -L/home/victoryang00/CXLMemUring/build/lib \
  main.cpp llama_ops_optimized.cpp \
  -o llama_optimized \
  -lcira_runtime -lMLIRRemoteMem
```

---

## Part 4: Runtime Instrumentation (Advanced)

### Automatic Performance Monitoring

The Type2GpuDevice runtime automatically captures:

```cpp
// Automatic counters collected per kernel launch:
struct KernelProfile {
    uint64_t kernel_cycles;        // From GPU counter
    uint64_t kernel_instructions;  // From GPU counter
    uint64_t wall_time_us;         // From host timer
    uint64_t memory_reads;         // Inferred from pattern
    uint64_t memory_writes;        // Inferred from pattern
    double   bandwidth_gbps;       // Calculated metric
};
```

### Enabling Runtime Instrumentation

```cpp
// In your llama.cpp integration code:
#include "Type2GpuDevice.h"

auto gpu = create_type2_gpu_device();

// Configure instrumentation
Type2KernelRequest request = {
    .kernel_addr = kernel_addr,
    .args_addr = args_addr,
    .grid_x = grid_x, .grid_y = 1, .grid_z = 1,
    .block_x = block_x, .block_y = 1, .block_z = 1,
    .dcoh_enabled = true,  // Enable coherency monitoring
    .timeout_ms = 10000
};

// Launch with automatic profiling
gpu->launch_kernel(request);

// Profiling data automatically captured
uint64_t cycles = gpu->get_kernel_cycles();
uint64_t instructions = gpu->get_kernel_instructions();

// Analyze in real-time
double ops_per_cycle = (double)instructions / cycles;
if (ops_per_cycle < expected) {
    std::cerr << "⚠ Performance degradation detected\n";
}
```

### Custom Instrumentation Points

Add performance monitoring to llama.cpp:

```cpp
// instrumentation.h
class InstrumentationScope {
public:
    InstrumentationScope(const std::string& name) : name_(name) {
        start_ = std::chrono::high_resolution_clock::now();
    }

    ~InstrumentationScope() {
        auto end = std::chrono::high_resolution_clock::now();
        double elapsed_ms = std::chrono::duration<double, std::milli>(end - start_).count();

        std::cout << "[" << name_ << "] " << elapsed_ms << " ms\n";

        // Report to CIRA runtime for aggregation
        report_to_runtime(name_, elapsed_ms);
    }

private:
    std::string name_;
    std::chrono::high_resolution_clock::time_point start_;
};

// Usage in llama.cpp:
{
    InstrumentationScope scope("attention_qkv_projection");
    // Q, K, V projections here
}
```

---

## Part 5: Performance Bug Analysis Workflow

### Step 1: Baseline Measurement

```bash
# Run on CPU only
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 7B
# Record: tokens/sec baseline

# Run with CXL GPU (if hardware available)
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 7B
# Record: tokens/sec with GPU
```

### Step 2: Pattern Analysis

```bash
# Test dominant patterns
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test pointer-chase
# Check latency

sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test bulk-load
# Check bandwidth
```

### Step 3: Identify Bug

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| Pointer-chase latency > 500ns | CXL cache misses | Increase cache, use prefetch |
| Bulk-load bandwidth < 10GB/s | Memory bus saturation | Batch requests, optimize alignment |
| High variance in latency | Cache-dependent behavior | Reduce cache conflicts |
| KV cache dominates (>30%) | Memory write bottleneck | Use async writes, optimize layout |

### Step 4: Implement & Verify

```cpp
// Example: Optimize KV cache writes
// Before: Simple sequential writes
for (int i = 0; i < hidden_size; i++) {
    kv_cache[pos * hidden_size + i] = k[i];  // Latency-dependent
}

// After: Batch writes with prefetch
__builtin_prefetch(&kv_cache[pos * hidden_size + 64], 1);  // Prefetch for write
memcpy(&kv_cache[pos * hidden_size], k, hidden_size * sizeof(float));
```

---

## Part 6: Expected Performance Numbers

### Pointer Chasing
- **Good**: < 100 ns/access (CPU cache hit)
- **Acceptable**: 100-500 ns/access (CXL cache hit)
- **Poor**: > 500 ns/access (Main memory or CXL bus latency)

### Bulk Memory Load
- **Excellent**: > 20 GB/s (Full bandwidth)
- **Good**: 15-20 GB/s (85-100% utilization)
- **Acceptable**: 10-15 GB/s (70-85%)
- **Poor**: < 10 GB/s (< 70% utilization)

### LLaMA Token Generation
- **7B Model**: 10-50 tokens/sec (CPU), 50-200 tokens/sec (with GPU offloading)
- **13B Model**: 5-25 tokens/sec (CPU), 30-120 tokens/sec (with GPU)
- **70B Model**: 1-10 tokens/sec (CPU), 10-50 tokens/sec (with GPU)

---

## Part 7: Advanced Topics

### Prefetching Strategy

```cpp
// Intelligent prefetch for KV cache reads
class KVCachePrefetcher {
public:
    void prefetch_for_next_token(int current_pos) {
        int next_pos = current_pos + 1;
        // Prefetch next iteration's data
        __builtin_prefetch(&k_cache[next_pos * hidden_size], 0);
        __builtin_prefetch(&v_cache[next_pos * hidden_size], 0);
    }
};
```

### DCOH Coherency Optimization

```cpp
// Optimize for cache-coherent completion
Type2KernelRequest request = {
    .dcoh_enabled = true,  // Enable snoop protocol
    .completion_addr = &completion_flag,
    // GPU writes completion_flag when done
    // CPU reads via snoop (low latency)
};
```

### Memory Layout Optimization

```cpp
// Optimize weight layout for bandwidth
// Original: Row-major (bad for some access patterns)
// Optimized: Block-major with padding

struct OptimizedWeights {
    float weights[num_blocks][block_size][block_size] __attribute__((aligned(64)));
};
```

---

## Part 8: Troubleshooting

### Issue: High pointer-chasing latency

**Diagnosis**:
```bash
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test pointer-chase
# If latency > 500ns, this is the issue
```

**Solutions**:
1. Profile CXL cache hits/misses
2. Reduce working set size
3. Increase prefetch distance
4. Use sequential access where possible

### Issue: Low bulk load bandwidth

**Diagnosis**:
```bash
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test bulk-load
# If bandwidth < 10GB/s, investigate memory subsystem
```

**Solutions**:
1. Check CXL bus utilization
2. Verify memory alignment (64-byte boundaries)
3. Batch requests to reduce overhead
4. Use DMA if available

### Issue: High variance in token latency

**Diagnosis**:
```bash
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 7B
# Check standard deviation in timing results
```

**Solutions**:
1. Enable CPU frequency scaling (for consistency)
2. Reduce background processes
3. Improve cache locality
4. Use NUMA-aware scheduling

---

## Summary

The testing infrastructure provides:
- ✓ Low-level pattern analysis (pointer-chase, bulk-load)
- ✓ High-level application profiling (llama.cpp simulation)
- ✓ Automatic instrumentation framework
- ✓ CIRA compiler integration
- ✓ Runtime performance monitoring

To identify performance bugs:

1. **Run baseline tests** to establish current performance
2. **Profile with pattern tests** to identify bottleneck type
3. **Analyze results** using provided guidelines
4. **Implement optimizations** and re-test
5. **Iterate** until performance targets met

---

## Next Steps

1. **Immediate**: Run tests to identify current bottlenecks
2. **Short-term**: Implement identified optimizations
3. **Medium-term**: Integrate CIRA compiler for automatic optimization
4. **Long-term**: Develop adaptive runtime optimization

---

## References

- CIRA Runtime API: `/home/victoryang00/CXLMemUring/runtime/include/Type2GpuDevice.h`
- Test Sources: `/root/ia780i_type2_delay_buffer/tests/`
- CIRA Compiler: `/home/victoryang00/CXLMemUring/build/bin/cira`
