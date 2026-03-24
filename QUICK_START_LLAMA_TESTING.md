# Quick Start: LLaMA CXL Testing with CIRA Framework

**Goal**: Run performance tests NOW to identify pointer chasing and memory load bugs

---

## 5-Minute Quick Start

### Test 1: Performance Pattern Test

```bash
# Test pointer-chasing latency bug
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test pointer-chase

# Expected output if BUG exists:
# ⚠ HIGH LATENCY: Pointer chasing shows 750 ns per access
# → Suggests poor cache locality or CXL cache misses
# → This is a performance bug indicator
```

### Test 2: Memory Bandwidth Bug

```bash
# Test bulk-load bandwidth bug
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test bulk-load

# Expected output if BUG exists:
# Bandwidth: 8.5 GB/s (low for sequential pattern)
# ⚠ SIGNIFICANT BANDWIDTH DROP with stride pattern
# → Suggests cache line utilization issue
# → Possible CXL memory alignment problem
```

### Test 3: LLaMA-Specific Performance

```bash
# Test LLaMA token generation
sudo /root/ia780i_type2_delay_buffer/tests/llama_cxl_perf_analysis --model 7B --seq-len 10

# Expected output if BUGS exist:
# ⚠ HIGH EMBEDDING LATENCY: 1.2 ms
# → Suggests pointer chasing bottleneck
#
# ⚠ HIGH KV CACHE TIME: 2.5 ms
# → Suggests bulk memory write bottleneck
#
# ⚠ ATTENTION BOTTLENECK: 52% of time
# → Indicates bandwidth limitation
```

---

## Understanding the Bugs

### Bug 1: Pointer Chasing (Latency Issue)

**What it is**: Sequential memory accesses with dependencies
- Each access must wait for the previous one
- Common in: token embeddings, attention Q/K/V

**How to detect**:
```bash
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test pointer-chase
```

**Indicators**:
- Latency > 500 ns per access
- Low Instructions/Cycle ratio
- Sequential pattern in profiling

**Impact on LLaMA**:
- Embedding lookups: 5-10% overhead
- Attention mechanisms: slight overhead
- KV cache reads: moderate overhead

### Bug 2: Bulk Memory Load (Bandwidth Issue)

**What it is**: Large contiguous memory transfers to GPU
- Matrix operations need weight data
- Limited by CXL bus bandwidth
- Common in: GEMM operations, weight loading

**How to detect**:
```bash
sudo /root/ia780i_type2_delay_buffer/perf_test_cxl_patterns --test bulk-load
```

**Indicators**:
- Bandwidth < 10 GB/s for sequential reads
- Stride pattern bandwidth < 80% of sequential
- High variance in latency

**Impact on LLaMA**:
- Attention: 40-50% overhead
- FFN layers: 30-40% overhead
- Can reduce throughput by 50-70%

---

## Testing Checklist

### ✓ Step 1: Build Tests (One-time)

```bash
# Build performance test
cd /root/ia780i_type2_delay_buffer
g++ -std=c++17 -O3 -march=native \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  perf_test_cxl_patterns.cpp \
  /home/victoryang00/CXLMemUring/runtime/src/Type2GpuDevice.cpp \
  -o perf_test_cxl_patterns

# Build llama test
g++ -std=c++17 -O3 -march=native \
  -I/home/victoryang00/CXLMemUring/runtime/include \
  tests/llama_cxl_perf_analysis.cpp \
  /home/victoryang00/CXLMemUring/runtime/src/Type2GpuDevice.cpp \
  -o tests/llama_cxl_perf_analysis
```

### ✓ Step 2: Run Tests (10 minutes)

```bash
# Test 1: Pointer chasing
echo "=== Testing Pointer Chasing ==="
sudo ./perf_test_cxl_patterns --test pointer-chase | tee results_pointer_chase.txt

# Test 2: Bulk load
echo "=== Testing Bulk Load ==="
sudo ./perf_test_cxl_patterns --test bulk-load | tee results_bulk_load.txt

# Test 3: GEMM
echo "=== Testing GEMM ==="
sudo ./perf_test_cxl_patterns --test gemm | tee results_gemm.txt

# Test 4: LLaMA
echo "=== Testing LLaMA ==="
sudo ./tests/llama_cxl_perf_analysis --model 7B --seq-len 20 | tee results_llama.txt
```

### ✓ Step 3: Analyze Results

```bash
# Extract key metrics
echo "=== Pointer Chasing Latency ==="
grep "Average Latency" results_pointer_chase.txt

echo "=== Bulk Load Bandwidth ==="
grep "Bandwidth" results_bulk_load.txt

echo "=== LLaMA Bottlenecks ==="
grep "⚠\|HIGH\|BOTTLENECK" results_llama.txt
```

---

## Interpreting Results

### Good Performance (No Bugs)
```
Pointer Chase: < 200 ns/access
Bulk Load: > 15 GB/s
GEMM: > 2 TFLOPS
LLaMA: No ⚠ warnings
```

### Moderate Issues (Optimization Opportunity)
```
Pointer Chase: 200-500 ns/access
Bulk Load: 10-15 GB/s
GEMM: 1-2 TFLOPS
LLaMA: 1-2 bottleneck warnings
```

### Critical Issues (Performance Bug)
```
Pointer Chase: > 500 ns/access  ⚠
Bulk Load: < 10 GB/s  ⚠
GEMM: < 1 TFLOPS  ⚠
LLaMA: Multiple bottleneck warnings
```

---

## Real-World Example

### Test Scenario: 7B LLaMA Model

```bash
$ sudo ./tests/llama_cxl_perf_analysis --model 7B --seq-len 100

═══════════════════════════════════════════════════════════════════
LLaMA CXL Type2 Performance Analysis
═══════════════════════════════════════════════════════════════════

Performance Statistics
─────────────────────────────────────────────────────────────────
Embedding           0.843 ms (min: 0.812 max: 0.901 σ: 0.032)
Attention          23.451 ms (min:22.123 max:24.890 σ: 0.812)
FFN                18.234 ms (min:17.456 max:19.123 σ: 0.645)
KV Cache Update     5.123 ms (min: 4.987 max: 5.456 σ: 0.143)
Total per Token    47.651 ms

Throughput          21.0 tokens/sec

─────────────────────────────────────────────────────────────────
Bottleneck Analysis
─────────────────────────────────────────────────────────────────

Time breakdown:
  Embedding:   1.8%
  Attention:  49.2%  ⚠
  FFN:        38.3%
  KV Cache:   10.7%

Performance Issues Detected:
⚠ ATTENTION BOTTLENECK: 49.2% of time
  → Indicates bandwidth limitation

⚠ HIGH VARIANCE: 0.812 ms
  → Suggests cache-dependent performance

⚠ KV CACHE DOMINATES: 10.7% of time
  → Consider optimizing cache operations
```

### Analysis:
1. **Primary Bug**: Attention bottleneck (49% of time)
   - Caused by: Bulk matrix loads
   - Action: Optimize CXL bandwidth utilization

2. **Secondary Issue**: High variance
   - Caused by: Cache dependency
   - Action: Improve cache locality

3. **Optimization Opportunity**: KV cache (10% of time)
   - Action: Prefetch next positions

---

## Fixing Found Bugs

### Fix 1: Pointer Chasing (Attention Q/K/V)

**Current (Buggy)**:
```cpp
// Sequential, dependent accesses
for (int i = 0; i < hidden_size; i++) {
    q[i] = input[i] * w_q[i];  // Wait for each result
}
```

**Fixed**:
```cpp
// Vectorized, parallel accesses
#pragma omp simd collapse(1)
for (int i = 0; i < hidden_size; i++) {
    q[i] = input[i] * w_q[i];
}
// OR use SIMD intrinsics for better code
__m256 *q_ptr = (__m256*)q;
__m256 *input_ptr = (__m256*)input;
__m256 *w_ptr = (__m256*)w_q;
for (int i = 0; i < hidden_size; i += 8) {
    q_ptr[i] = _mm256_mul_ps(input_ptr[i], w_ptr[i]);
}
```

### Fix 2: Bulk Load Bandwidth (GEMM)

**Current (Buggy)**:
```cpp
// Single-threaded, suboptimal access pattern
gpu->gemm_f32(output, input, weights,
              batch_size, hidden_size, hidden_size,
              1.0f, 0.0f);
```

**Fixed**:
```cpp
// Batch multiple GEMMs, optimize layout
std::vector<float> weights_blocked = reblock_weights(weights);
gpu->gemm_f32(output, input, weights_blocked,
              batch_size, hidden_size, hidden_size,
              1.0f, 0.0f);
```

---

## Integration with CIRA

Once bugs are identified and confirmed, use CIRA to auto-optimize:

```bash
# Profile with CIRA
/home/victoryang00/CXLMemUring/build/bin/cira \
  --profile=llama_ops.mlir \
  --optimize=aggressive \
  --memory=cxl_type2 \
  -o llama_optimized.cpp
```

---

## Summary Table

| Test | Command | Detects | Time |
|------|---------|---------|------|
| Pointer Chase | `--test pointer-chase` | Latency bugs | 1 min |
| Bulk Load | `--test bulk-load` | Bandwidth bugs | 1 min |
| GEMM | `--test gemm` | GPU interaction bugs | 1 min |
| LLaMA 7B | `--model 7B` | Application bottlenecks | 2 min |
| **Total** | All tests | Complete analysis | **5 min** |

---

## Next Steps

1. **Run tests** (5 minutes)
2. **Collect results** into files
3. **Identify bugs** using guidelines above
4. **Prioritize fixes** (critical first)
5. **Implement fixes** and re-test
6. **Use CIRA** for automatic optimization
7. **Benchmark improvement** with same tests

---

## Getting Help

If tests show:
- **Pointer-chase bug**: See "Fix 1" above
- **Bandwidth bug**: See "Fix 2" above
- **GPU issues**: Check Type2GpuDevice initialization
- **CIRA issues**: Run `/home/victoryang00/CXLMemUring/build/bin/cira --help`

---

## Expected Time Commitment

- **Initial testing**: 5 minutes
- **Bug analysis**: 10 minutes
- **Fix implementation**: 30-60 minutes
- **Re-testing**: 5 minutes
- **Performance validation**: 10 minutes

**Total**: ~1-2 hours to identify and fix primary bugs

---

## What You'll Learn

✓ How to characterize performance bottlenecks
✓ How to identify pointer-chasing bugs
✓ How to identify bandwidth limitations
✓ How to use CIRA for optimization
✓ How to profile llama.cpp on CXL Type2 GPU

Let's get started!
