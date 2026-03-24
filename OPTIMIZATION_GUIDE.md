# Performance Optimization Guide
## LLaMA.cpp CXL Type2 GPU Offloading

**Date:** March 24, 2026
**Priority:** CRITICAL - Bandwidth Bottleneck
**Target:** 2.5-3x throughput improvement

---

## EXECUTIVE SUMMARY

Based on comprehensive performance analysis, the **BANDWIDTH BOTTLENECK** is the limiting factor:
- Current bandwidth: **5.98 GB/s** (sequential reads)
- Required for optimal FFN: **>15 GB/s**
- Gap: **60% below requirement**

---

## PART 1: ROOT CAUSE ANALYSIS

### The Bottleneck Chain
```
CXL Memory Bandwidth (5.98 GB/s)
    ↓
FFN GEMM Operations (hidden_size × ffn_hidden × hidden_size)
    ↓
FFN dominates execution (61% of total time)
    ↓
LLaMA throughput capped at 32,586 tokens/sec
```

### Why FFN is Bandwidth-Limited
**7B Model:**
- FFN weights: 11.54 GB
- Attention weights: 8.58 GB
- Total: 20 GB loaded per token
- At 6 GB/s: 3.3 seconds per token (CRITICAL!)

**Actual result:** 0.031 ms per token (CPU simulation)
**With real offload:** Would be limited by bandwidth

---

## PART 2: OPTIMIZATION STRATEGIES

### STRATEGY 1: Improve Memory Bandwidth (Hardware-Level)

#### 1A: CXL Configuration Optimization
**Location:** BIOS/Kernel CXL Configuration
**Actions:**
```bash
# Check current CXL settings
cat /sys/bus/cxl/devices/*/hdm_decoder*/

# Verify HDM decoder programming
cat /sys/firmware/cxl/

# Check for prefetching support
cat /proc/cpuinfo | grep prefetch
```

**Expected Impact:** +30-50% bandwidth

#### 1B: Memory Access Patterns
**Current Issue:** Sequential accesses at ~6 GB/s
**Optimization:**
- Enable memory prefetching (L3 cache)
- Reduce memory access fragmentation
- Use cache-aligned allocations

```cpp
// Optimized memory allocation
alignas(64) float weights[size];  // 64-byte cache line alignment
```

**Expected Impact:** +15-25% bandwidth

#### 1C: PCIe Configuration
**Check current setup:**
```bash
# Verify PCIe Gen speed
lspci -vv | grep "LnkSta:"

# Check CXL port configuration
cat /sys/bus/pci/devices/0000:3b:00.0/config
```

**If Gen 4:** Consider upgrading to Gen 5 (2x bandwidth)
**Expected Impact:** +100% (if available)

---

### STRATEGY 2: Optimize FFN Operations (Algorithm-Level)

#### 2A: Block GEMM Implementation
**Problem:** Large 1 × 11008 × 4096 GEMMs stress memory bandwidth
**Solution:** Decompose into cache-friendly blocks

```cpp
// Block size tuned for L3 cache
const int BLOCK_SIZE = 256;

for (int bi = 0; bi < M; bi += BLOCK_SIZE) {
    for (int bk = 0; bk < K; bk += BLOCK_SIZE) {
        for (int bj = 0; bj < N; bj += BLOCK_SIZE) {
            // Compute block [bi:bi+BLOCK][bj:bj+BLOCK]
            // A[bi:bi+BLOCK, bk:bk+BLOCK]
            // B[bk:bk+BLOCK, bj:bj+BLOCK]
            // C[bi:bi+BLOCK, bj:bj+BLOCK]
        }
    }
}
```

**Expected Impact:** +20-30% cache reuse, faster compute

**Impact on Bandwidth:** Reduce effective working set by 50%

#### 2B: Weight Quantization
**From:** 32-bit float (4 bytes/value)
**To:** 16-bit float (2 bytes/value) or INT8 (1 byte/value)

**Trade-off:**
- Bandwidth: 2-4x improvement
- Accuracy: 1-2% loss (typically acceptable)
- Compute: 2-4x faster

```cpp
// Convert weights to fp16
std::vector<float16_t> weights_fp16(weights.begin(), weights.end());
// Results in 2x bandwidth improvement
```

**Expected Impact:** +100-300% throughput with minimal accuracy loss

#### 2C: Sparse GEMM
**From:** Full dense matrix multiplication
**To:** Pruned sparse GEMM (80-90% sparsity in many LLMs)

**If 90% sparse:**
- Bandwidth: 10x reduction
- Computation: 10x reduction

```cpp
// Skip zero entries during GEMM
for (int i = 0; i < M; i++) {
    for (int j = 0; j < N; j++) {
        if (weights[i][j] != 0.0f) {  // Skip zeros
            // Compute
        }
    }
}
```

**Expected Impact:** +500-1000% with sparse weights

---

### STRATEGY 3: Reduce Memory Traffic (Data Organization)

#### 3A: KV Cache Optimization
**Current:** Write full K, V separately
**Optimized:** Batch write K and V together

```cpp
// Before: Two separate writes
kv_cache[pos * hs] = K[i];  // Write K
kv_cache[pos * hs + size/2] = V[i];  // Write V

// After: Single batched write
struct KV { float k, v; };
KV* kv_ptr = (KV*)&kv_cache[pos * hs];
for (int i = 0; i < hs; i++) {
    kv_ptr[i] = {K[i], V[i]};  // Single write
}
```

**Expected Impact:** +15% (reduce memory operations)

#### 3B: Embedding Pre-computation
**Current:** Compute embeddings per token
**Optimized:** Pre-compute and cache embeddings

```cpp
// Cache embeddings to avoid repeated lookups
class EmbeddingCache {
    std::unordered_map<uint32_t, std::vector<float>> cache;

    const float* get(uint32_t token_id) {
        if (cache.count(token_id)) return cache[token_id].data();
        // Compute and cache
    }
};
```

**Expected Impact:** +10-15% (avoid pointer-chasing for repeated tokens)

---

### STRATEGY 4: GPU Offloading (Long-Term)

#### 4A: Real GPU GEMM Offload
**Current:** CPU simulation of GEMM via Type2GpuDevice
**Optimal:** Actual GPU kernel execution

```cpp
// Current: Simulated on CPU
gpu->gemm_f32(C, A, B, M, N, K, alpha, beta, timeout);

// Desired: Real GPU kernel
Type2KernelRequest req = {
    .kernel_addr = fused_kernel_addr,
    .args_addr = {C, A, B, M, N, K, alpha, beta},
    .dcoh_enabled = true,
    .timeout_ms = 5000
};
gpu->launch_kernel(req);
```

**Expected Impact:** +1000%+ with actual GPU compute

#### 4B: Fused Kernels
**Current:** Separate kernels for QKV, GEMM, Activation
**Optimized:** Single kernel that does all in one pass

```cuda
// Fused kernel: QKV proj + attention + output proj
__global__ void fused_attention(
    float* out, const float* hidden, const float* weights,
    int seq_len, int hidden_size
) {
    // All operations in device memory
    // Minimal data transfer
}
```

**Expected Impact:** +2-3x (reduce data movement)

---

## PART 3: IMPLEMENTATION ROADMAP

### Phase 1: Short-term (1-2 weeks) - 1.5x improvement
**Focus:** Algorithm optimization without HW changes

1. ✓ Identify bandwidth bottleneck
2. → Implement block GEMM
3. → Add embedding caching
4. → Optimize memory layout
5. → Re-test and validate

**Expected:** 32K → 48K tokens/sec

### Phase 2: Medium-term (2-4 weeks) - 2.5x improvement
**Focus:** Weight quantization and optimization

1. → Quantize weights to fp16
2. → Test accuracy impact
3. → Profile reduced bandwidth usage
4. → Implement sparse GEMM
5. → Re-test full pipeline

**Expected:** 32K → 82K tokens/sec

### Phase 3: Long-term (4+ weeks) - 4x+ improvement
**Focus:** Real GPU offloading

1. → Implement Type2 GPU kernel loader
2. → Write fused attention kernel
3. → Implement offload scheduler
4. → Profile end-to-end execution
5. → Integrate with llama.cpp

**Expected:** 32K → 130K+ tokens/sec

---

## PART 4: SPECIFIC CODE OPTIMIZATIONS

### Optimization #1: Block GEMM with Prefetch
```cpp
// File: llama_optimized.cpp
class BlockGEMM {
    static const int BLOCK = 256;

    static void compute_block(
        float* C, const float* A, const float* B,
        int m, int n, int k, float alpha, float beta
    ) {
        for (int i = 0; i < m; i++) {
            __builtin_prefetch(&A[(i+1)*k]);  // Prefetch next row of A
            for (int j = 0; j < n; j++) {
                float sum = 0;
                for (int l = 0; l < k; l++) {
                    sum += A[i*k + l] * B[l*n + j];
                }
                C[i*n + j] = alpha * sum + beta * C[i*n + j];
            }
        }
    }
};
```

**Benefit:** Better L3 cache utilization, +20-30% speedup

### Optimization #2: Batched KV Updates
```cpp
// File: llama_optimized.cpp
void update_kv_batched(const float* k, const float* v,
                       float* kv_cache, int pos, int size)
{
    // Single memcpy instead of element-wise writes
    __builtin_prefetch(&kv_cache[pos * size], 1);  // Prefetch write location

    float* dst_k = &kv_cache[pos * size];
    float* dst_v = &kv_cache[pos * size + size/2];

    memcpy(dst_k, k, size * sizeof(float));
    memcpy(dst_v, v, size * sizeof(float));
}
```

**Benefit:** Reduces memory operations by 50%, +15% speedup

### Optimization #3: FP16 Quantization
```cpp
// File: llama.cpp integration
void quantize_weights_fp16(float* weights, size_t size) {
    __m256 scale = _mm256_set1_ps(1.0f / 65504.0f);  // Max fp16 value

    for (size_t i = 0; i < size; i += 8) {
        __m256 v = _mm256_loadu_ps(&weights[i]);
        // Convert to fp16 (compiler helps with AVX intrinsics)
        // Store back
    }
}
```

**Benefit:** 2x bandwidth, 1-2% accuracy loss

---

## PART 5: VALIDATION AND TESTING

### Test 1: Block GEMM Performance
```bash
# Compile with optimization
g++ -O3 -march=native llama_optimized.cpp ...

# Run baseline
time sudo ./llama_cxl_perf_analysis --model 7B --seq-len 50

# Run optimized
time sudo ./llama_optimized --model 7B --seq-len 50

# Expected: 3-4x faster FFN operations
```

### Test 2: Memory Bandwidth
```bash
# Measure improved bandwidth
sudo ./tests/perf_patterns_hardware

# Expected: 6 GB/s → 10+ GB/s with optimizations
```

### Test 3: End-to-End LLaMA
```bash
# Test with real model
./llama/main -m model.gguf -p "Once upon a time" -n 100

# Measure:
# - Tokens/sec improvement
# - Memory usage reduction
# - Power consumption (if available)
```

---

## PART 6: EXPECTED IMPROVEMENTS SUMMARY

| Strategy | Effort | Impact | Timeline |
|----------|--------|--------|----------|
| Block GEMM | Low | +20-30% | 1 day |
| KV Cache batching | Low | +15% | 1 day |
| Embedding cache | Low | +10% | 1 day |
| FP16 quantization | Medium | +100% | 3-5 days |
| Sparse GEMM | High | +500% | 1-2 weeks |
| GPU kernel offload | Very High | +1000% | 4+ weeks |
| **Total (Phase 1-3)** | **N/A** | **+4x-10x** | **6+ weeks** |

---

## PART 7: NEXT IMMEDIATE STEPS

1. **Week 1:**
   - [ ] Implement block GEMM
   - [ ] Optimize KV cache writes
   - [ ] Add embedding cache
   - [ ] Measure improvement (target: +30-50%)

2. **Week 2:**
   - [ ] Quantize weights to fp16
   - [ ] Validate accuracy (<1% loss)
   - [ ] Profile bandwidth improvement
   - [ ] Measure overall speedup (target: +100%)

3. **Week 3-4:**
   - [ ] Investigate sparse tensor support
   - [ ] Profile CXL memory configuration
   - [ ] Plan GPU kernel development

---

## CONCLUSION

The identified **BANDWIDTH BOTTLENECK** at 5.98 GB/s is the primary limitation. Through systematic optimizations:

- **Phase 1 (1-2 weeks):** +50% throughput with algorithm changes
- **Phase 2 (2-4 weeks):** +200% throughput with quantization
- **Phase 3 (4+ weeks):** +400% throughput with real GPU offloading

**Target:** From 32K tokens/sec → **100K+ tokens/sec** (3-4x improvement)

**Most impactful:** Fix bandwidth bottleneck in CXL memory subsystem (would enable full GPU utilization)

