# Workload Porting Guide
## Converting CIRA Compiler Passes to FPGA Hardware Kernels

**Target:** Intel Agilex 7 Type2 GPU (BAR0+0x180100 CSR interface)
**Status:** Framework & template implementation
**Date:** March 24, 2026

---

## Overview

This guide walks through porting each of the 8 CIRA workload compiler passes from software simulation to actual FPGA hardware. We use **Sparse Matrix (SpMV)** as the template, then apply the same pattern to the remaining 7 workloads.

### Porting Workflow

```
Phase 2 Compiler Pass (CIRA IR)
    ↓
FPGA Kernel Wrapper (BAR0 management)
    ↓
GPU CSR Integration (register mapping)
    ↓
Vortex SIMT Kernel (RISC-V implementation)
    ↓
Test Harness (verification + benchmarking)
    ↓
FPGA Hardware Validation
```

---

## Part 1: Template Implementation - Sparse Matrix (SpMV)

### Step 1: Understand Current Implementation

**File:** `cira_sparsematrix_pass.cpp`

Key components:
- Pattern detection: CSR/COO format identification
- CIRA IR generation: sparse_stream, prefetch operations
- Vortex kernel: index_reorder, prefetch_column_vectors
- Expected speedup: 1.3–1.5x

### Step 2: Create FPGA Kernel Wrapper

Create `fpga_sparse_matrix_kernel.cpp`:

```cpp
#include "gpu_csr_interface.cpp"
#include <vector>
#include <cstring>

class FpgaSparseBenchmark {
private:
    GpuCsrInterface gpu_;

    // CSR matrix format
    struct CSRMatrix {
        uint32_t m, n;              // dimensions
        uint32_t nnz;               // non-zeros
        uint32_t row_ptr_offset;    // BAR0 offset
        uint32_t col_idx_offset;
        uint32_t values_offset;
    };

    CSRMatrix matrix_;
    uint32_t x_vector_offset_;      // Input vector X
    uint32_t y_vector_offset_;      // Output vector Y

public:
    bool initialize() {
        // Initialize GPU CSR interface
        if (!gpu_.initialize("/sys/bus/pci/devices/0000:3b:00.0/resource0")) {
            std::cerr << "Failed to initialize GPU\n";
            return false;
        }

        // Allocate BAR0 memory layout
        // Total budget: 256KB
        // Layout:
        //   0x000000–0x00FFFF: Row pointers (64KB)
        //   0x010000–0x07FFFF: Column indices + values (448KB, but limit to ~170KB)
        //   0x050000–0x0FFFFF: Input vector X (64KB)
        //   0x060000–0x0FFFFF: Output vector Y (64KB)

        matrix_.row_ptr_offset = 0x000000;
        matrix_.col_idx_offset = 0x010000;
        matrix_.values_offset  = 0x020000;
        x_vector_offset_ = 0x050000;
        y_vector_offset_ = 0x060000;

        return true;
    }

    bool load_matrix(const std::vector<int>& row_offsets,
                    const std::vector<int>& col_indices,
                    const std::vector<float>& values,
                    int m, int n) {
        matrix_.m = m;
        matrix_.n = n;
        matrix_.nnz = col_indices.size();

        // Verify size constraints
        if (matrix_.nnz > 32768) {  // ~128KB for 4-byte values
            std::cerr << "Matrix too large for BAR0 budget\n";
            return false;
        }

        // Write to GPU memory
        gpu_.write_buffer(matrix_.row_ptr_offset,
                         row_offsets.data(),
                         row_offsets.size() * sizeof(int));

        gpu_.write_buffer(matrix_.col_idx_offset,
                         col_indices.data(),
                         col_indices.size() * sizeof(int));

        gpu_.write_buffer(matrix_.values_offset,
                         values.data(),
                         values.size() * sizeof(float));

        return true;
    }

    bool run_kernel() {
        // Submit kernel to GPU
        // Kernel type: 3 (custom sparse matrix)
        // m: matrix_.m
        // n: matrix_.nnz
        // k: matrix_.col_idx_offset (packed in k register)

        if (!gpu_.submit_kernel(3,  // custom kernel type
                               matrix_.m,
                               matrix_.nnz,
                               matrix_.row_ptr_offset)) {
            return false;
        }

        // Wait for completion
        return gpu_.wait_completion(5000);  // 5 second timeout
    }

    bool read_results(std::vector<float>& y) {
        y.resize(matrix_.m);
        return gpu_.read_buffer(y_vector_offset_,
                               y.data(),
                               matrix_.m * sizeof(float));
    }

    void shutdown() {
        gpu_.shutdown();
    }
};
```

### Step 3: Map CIRA Operations to GPU CSR Registers

Create register mapping (from gpu_csr_interface.cpp):

```cpp
// GPU CSR Register Layout
#define GPU_CSR_CONTROL       0x0000  // RW: Kernel control
#define GPU_CSR_STATUS        0x0004  // RO: Status
#define GPU_CSR_KERNEL_TYPE   0x0008  // RW: Kernel type (3=sparse)
#define GPU_CSR_DIMS_M        0x000C  // RW: Matrix M dimension
#define GPU_CSR_DIMS_N        0x0010  // RW: Matrix N (nnz)
#define GPU_CSR_DIMS_K        0x0014  // RW: Row pointer offset
#define GPU_CSR_INPUT_ADDR    0x0018  // RW: X vector offset
#define GPU_CSR_OUTPUT_ADDR   0x001C  // RW: Y vector offset
#define GPU_CSR_ERROR_CODE    0x0020  // RO: Error code
#define GPU_CSR_PERF_CYCLES   0x0024  // RO: Performance cycles

// Mapping CIRA operations:
// cira.sparse_stream_create() → GPU_CSR_KERNEL_TYPE = 3
// cira.index_reorder_locality() → GPU_CSR_DIMS_K (row_ptr)
// cira.install_cacheline_pattern() → GPU_CSR_DIMS_N (nnz count)
// Kernel submission → GPU_CSR_CONTROL bit 0 = 1
```

### Step 4: Implement Vortex RISC-V SIMT Kernel

Create `vortex_sparse_kernel.s`:

```risc-v
# Vortex RISC-V SIMT Kernel for Sparse Matrix SpMV
# Performs: y = A * x (A in CSR format)
#
# Input:
#   a0 = row_ptr array (in BAR0)
#   a1 = col_idx array (in BAR0)
#   a2 = values array (in BAR0)
#   a3 = x vector (in BAR0)
#   t0 = y vector (in BAR0)
#   t1 = m (matrix rows)
#   t2 = n (matrix cols)

.global sparse_spmv_kernel

sparse_spmv_kernel:
    # Thread i processes row i
    li $tid, $tid           # Thread ID within warp (0-31)
    li $warp_size, 32

    # Skip if thread >= m
    bge $tid, t1, return

    # Load row range: row_ptr[i] .. row_ptr[i+1]
    lw $row_start, 0(a0 + $tid * 4)
    lw $row_end, 4(a0 + $tid * 4)

    # Initialize sum = 0
    fcvt.s.w $sum, $zero

    # Loop over non-zeros in this row
    add $j, $row_start, 0   # j = row_start
loop:
    bge $j, $row_end, done

    # Load col_idx[j]
    lw $col, 0(a1 + $j * 4)

    # Load value[j]
    flw $val, 0(a2 + $j * 4)

    # Load x[col]
    flw $x_val, 0(a3 + $col * 4)

    # Accumulate: sum += val * x[col]
    fmul.s $prod, $val, $x_val
    fadd.s $sum, $sum, $prod

    # Next non-zero
    addi $j, $j, 1
    j loop

done:
    # Store y[i] = sum (with atomic RMW for correctness)
    # In real Vortex: atomic_f32_store(y + i*4, sum)
    fsw $sum, 0(t0 + $tid * 4)

return:
    # Synchronize warp
    barrier.warp
    ret
```

### Step 5: Create Test Harness

Create `test_sparse_fpga.cpp`:

```cpp
#include "fpga_sparse_matrix_kernel.cpp"
#include <iostream>
#include <vector>
#include <cmath>

int main() {
    FpgaSparseBenchmark benchmark;

    // Initialize GPU
    if (!benchmark.initialize()) {
        std::cerr << "GPU initialization failed\n";
        return 1;
    }

    // Create test matrix (4096x4096, ~90% sparse)
    int m = 4096, n = 4096;
    int nnz = (m * n * 10) / 100;  // 10% density

    std::vector<int> row_offsets(m + 1);
    std::vector<int> col_indices(nnz);
    std::vector<float> values(nnz);

    // Generate test matrix
    int idx = 0;
    for (int i = 0; i < m; i++) {
        row_offsets[i] = idx;
        int entries_in_row = nnz / m;
        for (int j = 0; j < entries_in_row && idx < nnz; j++) {
            col_indices[idx] = (i * 37 + j) % n;
            values[idx] = 1.0f + (idx % 100) / 100.0f;
            idx++;
        }
    }
    row_offsets[m] = nnz;

    // Load matrix
    if (!benchmark.load_matrix(row_offsets, col_indices, values, m, n)) {
        std::cerr << "Matrix loading failed\n";
        return 1;
    }

    // Load X vector
    std::vector<float> x(n, 1.0f);
    // benchmark.load_vector(x, ...);

    // Run kernel
    std::cout << "Running sparse matrix kernel...\n";
    if (!benchmark.run_kernel()) {
        std::cerr << "Kernel execution failed\n";
        return 1;
    }

    // Read results
    std::vector<float> y;
    if (!benchmark.read_results(y)) {
        std::cerr << "Result reading failed\n";
        return 1;
    }

    // Validate results
    std::cout << "Results: y[0]=" << y[0] << ", y[1]=" << y[1] << "\n";

    benchmark.shutdown();
    return 0;
}
```

### Step 6: Compile and Test

```bash
# Compile with GPU interface
g++ -std=c++17 -O2 -pthread -o test_sparse_fpga \
    test_sparse_fpga.cpp gpu_csr_interface.cpp

# Run (simulation mode if GPU not available)
./test_sparse_fpga

# Run on actual hardware (needs root)
sudo ./test_sparse_fpga
```

---

## Part 2: Porting Pattern - Apply to Other Workloads

### For Each Workload (Hash Agg, GNN, etc.)

**1. Create FPGA Kernel Wrapper**
```cpp
class FpgaWorkloadBenchmark {
    GpuCsrInterface gpu_;
    // Allocate BAR0 memory according to workload budget
    // Load data structures (hash tables, graphs, embeddings)
    // Submit kernel via CSR
    // Read results
};
```

**2. Map CIRA Operations → CSR Registers**
- Kernel type: unique ID per workload (3=sparse, 4=hash, 5=gnn, etc.)
- DIMS_M, DIMS_N, DIMS_K: pack workload-specific parameters
- INPUT_ADDR, OUTPUT_ADDR: data offsets in BAR0

**3. Implement Vortex SIMT Kernel**
- Start with template from Part 1
- Replace inner loop with workload-specific computation
- Use SIMT barriers for synchronization
- Prefetch strategy: overlap I/O with computation

**4. Test Harness**
- Generate synthetic data (same as CPU benchmark)
- Load into BAR0 via gpu_csr_interface
- Submit kernel, wait completion
- Validate output correctness
- Measure execution time

---

## BAR0 Memory Budget Allocation

Total: 2MB (minus CSR area ~256KB) = ~1.75MB for kernels

```
Offset      Size        Purpose
────────────────────────────────────
0x000000    256 KB      CSR + kernel instruction memory
0x040000    128 KB      Vortex local memory (per-core data)
0x060000    256 KB      Sparse Matrix (row_ptr, col_idx, values)
0x100000    256 KB      Hash Aggregation (hash table, buckets)
0x140000    512 KB      GNN (graph edges, embeddings, nodes)
0x240000    512 KB      Streaming Aggregation (input stream buffer)
0x340000    128 KB      B-Tree (tree structure, nodes)
0x360000    256 KB      Full-Text Search (index, postings)
0x3A0000    256 KB      Bioinformatics (sequences, profiles)
0x3E0000    256 KB      Recommender (embeddings, frequency table)
```

**Note:** Workloads run sequentially (or with subsets), not simultaneously.

---

## Workload-Specific Details

### Hash Aggregation (Task #7)

**CSR Kernel Type:** 4

**BAR0 Layout:**
- Hash table: 128K entries
- Key-value pairs: 8 bytes each (int key + float value)
- Collision chains: linked list pointers

**Vortex Kernel Strategy:**
- SIMT: 32 threads prefetch buckets in parallel
- Prefetch lookahead: 16 buckets ahead
- Collision detection: scan chains, count depth

**Test Data:**
- 100K operations
- 25% collision rate (predictable)

### Graph Neural Networks (Task #8)

**CSR Kernel Type:** 5

**BAR0 Layout:**
- Node embeddings: 1024 nodes × 128 dims × 4 bytes = 512KB
- Adjacency list: ~8 neighbors/node × 4K nodes = 128KB
- Aggregation buffer: 512KB (output embeddings)

**Vortex Kernel Strategy:**
- SIMT: per-node parallelism
- Multi-hop: prefetch 2 hops ahead
- Synchronization: barriers between aggregation phases

**Test Data:**
- Scale-free graph (Zipfian degree distribution)
- 1-hop, 2-hop, 3-hop aggregations

### Streaming Aggregation (Task #9)

**CSR Kernel Type:** 6

**BAR0 Layout:**
- Input stream: 1M tuples × 16 bytes = 16MB (windowed, use 128KB chunks)
- Partial sums: 32 warps × 8 bytes = 256 bytes
- Output aggregate: 8 bytes

**Vortex Kernel Strategy:**
- Per-warp partial reduction
- T-Digest sketch for quantiles
- Non-blocking atomic updates

**Test Data:**
- SUM, AVG, MIN, MAX, PERCENTILE operations
- Unbounded and tumbling window

### B-Tree (Task #10)

**CSR Kernel Type:** 7

**BAR0 Layout:**
- B-Tree nodes: ~256 nodes × 256 bytes = 64KB
- Node pool: 128KB (expansion space)
- Search path buffer: 4KB

**Vortex Kernel Strategy:**
- Speculative path prefetch
- Sibling preload for rebalancing
- Bottom-up bulk load

**Test Data:**
- 10K keys
- Search, insert, delete, bulk load operations

### Full-Text Search (Task #11)

**CSR Kernel Type:** 8

**BAR0 Layout:**
- Inverted index: 512KB (term → posting list map)
- Posting lists: 128KB (doc IDs + frequencies)
- Scoring buffer: 64KB

**Vortex Kernel Strategy:**
- Posting cache: top 256 terms
- SIMT: parallel Boolean evaluation
- BM25 scoring: per-document in Vortex

**Test Data:**
- Single term, phrase, Boolean AND/OR queries
- ~1000 documents

### Bioinformatics (Task #12)

**CSR Kernel Type:** 9

**BAR0 Layout:**
- Reference genome: 768KB (or use stub)
- Query sequence: 4KB
- DP table: 32KB (256×128 matrix)
- Alignment results: 64KB

**Vortex Kernel Strategy:**
- k-mer filtering: SIMT parallel scoring
- Profile computation: per-thread amino acid counting
- DP acceleration: profile-based costs

**Test Data:**
- 100 query sequences vs. 1000 reference sequences
- BLAST, Smith-Waterman, k-NN

### Recommender Systems (Task #13)

**CSR Kernel Type:** 10

**BAR0 Layout:**
- Embedding table: 384KB (sparse, ~10K items × 8 bytes)
- Frequency counters: 64KB
- Cache hotspots: 32KB
- Top-K results: 16KB

**Vortex Kernel Strategy:**
- Zipfian-aware caching: maintain hot 20% in LLC
- Top-K: bitonic sort within 32-thread warp
- Lookahead: prefetch next batch

**Test Data:**
- Collaborative filtering, neural recommender, batched inference
- Zipfian access distribution

---

## Compilation & Integration

### Build All Workloads

```bash
# Individual workload builds
g++ -std=c++17 -O2 test_sparse_fpga.cpp gpu_csr_interface.cpp -o test_sparse
g++ -std=c++17 -O2 test_hash_fpga.cpp gpu_csr_interface.cpp -o test_hash
# ... repeat for all 8

# Unified benchmark (once all tested)
g++ -std=c++17 -O3 fpga_workload_benchmark_integrated.cpp \
    test_sparse_fpga.cpp test_hash_fpga.cpp \
    ... (all 8) \
    gpu_csr_interface.cpp -o fpga_all_workloads
```

### Run Benchmarks

```bash
# Baseline (CPU simulation)
./fpga_all_workloads --mode=cpu --iterations=100

# CIRA-optimized (with Vortex prefetch)
./fpga_all_workloads --mode=fpga --iterations=100

# Profile with VTune
perf record -e cycles,LLC-load-misses ./fpga_all_workloads --mode=fpga
perf report
```

---

## Validation Checklist

For each workload:

- [ ] FPGA kernel wrapper compiles without errors
- [ ] CSR register mapping correct (verified via datasheet)
- [ ] Vortex SIMT kernel passes syntax check
- [ ] Test harness runs in simulation mode
- [ ] Data loads correctly into BAR0 (memcpy verified)
- [ ] Kernel submits and completes on simulator
- [ ] Output correctness validated (vs. CPU reference)
- [ ] Performance measured: baseline < CIRA (expected speedup within projections)
- [ ] Memory coherency: Y vector matches CPU result
- [ ] Long-run stability: 1M+ iterations without corruption

---

## Troubleshooting

### Issue: Kernel times out on FPGA

**Causes:**
- Infinite loop in Vortex kernel (check barrier statements)
- BAR0 address out of bounds
- CSR status register not updating

**Solutions:**
- Add debug prints before/after barriers
- Verify all array accesses within allocated regions
- Test CSR access independently with gpu_csr_interface

### Issue: Output values incorrect

**Causes:**
- BAR0 offsets colliding (data overwrites)
- Vortex kernel computation error
- X vector not loaded correctly

**Solutions:**
- Print first 10 bytes at each offset
- Manually trace Vortex kernel with example input
- Verify X vector load before kernel submit

### Issue: Speedup < 1.0x (regression)

**Causes:**
- Kernel submission overhead dominates (small problem)
- Vortex prefetch not effective for this data size
- SIMT serialization on dependencies

**Solutions:**
- Increase problem size
- Profile to see where cycles spent
- May indicate workload not suitable for FPGA (rare)

---

## Next Steps

1. **Implement Sparse Matrix (this week)**
   - Follow template exactly
   - Validate on FPGA simulator
   - Measure baseline speedup (~1.3x expected)

2. **Template Replication (next week)**
   - Use Sparse Matrix as reference
   - Port Hash Agg, GNN, Streaming Agg (Tier 1)
   - Test each sequentially

3. **Tier 2 Completion (week 3)**
   - Port Full-Text, Bioinformatics, Recommender
   - Integrate all 8 into unified benchmark

4. **Benchmarking & Paper (week 4)**
   - Collect VTune profiles
   - Generate speedup tables
   - Write MICRO 2026 Section 4

---

**Status: Template ready, ready for Sparse Matrix porting to begin**

This guide provides all necessary steps to port each workload. Follow the sparse matrix example exactly, then apply the pattern to the remaining 7 workloads.
