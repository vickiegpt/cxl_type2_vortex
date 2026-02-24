/**
 * gemm_kernel.c
 *
 * Vortex GPU GEMM kernel — C implementation.
 *
 * Computes C = alpha * A * B + beta * C using SIMT parallelism.
 * Each hardware thread computes one element of the output matrix C.
 *
 * Compile with:
 *   riscv64-unknown-elf-gcc -march=rv64imafdc -mabi=lp64d \
 *       -nostdlib -nostartfiles -O2 -ffreestanding -c gemm_kernel.c
 *
 * Thread mapping:
 *   global_tid = core_id * (num_warps * num_threads) + warp_id * num_threads + thread_id
 *   total_hw_threads = num_cores * num_warps * num_threads
 *
 *   For each (row, col) where row < M and col < N:
 *     flat_idx = row * N + col
 *     Threads stride by total_hw_threads to cover all elements.
 */

#include "vx_intrinsics.h"
#include "gemm_args.h"

/**
 * kernel_main — Entry point called by crt0.S
 *
 * @param args  Pointer to GemmKernelArgs in shared memory (from mscratch)
 */
void kernel_main(GemmKernelArgs *args) {
    /* Read matrix parameters */
    const uint32_t M     = args->M;
    const uint32_t N     = args->N;
    const uint32_t K     = args->K;
    const uint32_t lda   = args->lda;
    const uint32_t ldb   = args->ldb;
    const uint32_t ldc   = args->ldc;
    const float    alpha = args->alpha;
    const float    beta  = args->beta;

    /* Matrix base pointers (addresses/offsets from shared memory base).
     * In the Vortex memory model, these are direct pointers — the host
     * sets them to the shared memory region accessible by the GPU via AXI. */
    const float *A = (const float *)(uintptr_t)args->A_addr;
    const float *B = (const float *)(uintptr_t)args->B_addr;
    float       *C = (float       *)(uintptr_t)args->C_addr;

    /* Compute global thread ID and total thread count */
    const uint32_t gtid       = vx_global_tid();
    const uint32_t num_threads_total = vx_num_hw_threads();

    /* Total output elements */
    const uint32_t total_elements = M * N;

    /* Each thread iterates over output elements with a stride of
     * total hardware threads (grid-stride loop pattern) */
    for (uint32_t idx = gtid; idx < total_elements; idx += num_threads_total) {
        const uint32_t row = idx / N;
        const uint32_t col = idx % N;

        /* Bounds check (handles non-uniform last iteration) */
        if (row >= M || col >= N)
            continue;

        /* Dot product: acc = sum_{k=0}^{K-1} A[row][k] * B[k][col] */
        float acc = 0.0f;
        for (uint32_t k = 0; k < K; k++) {
            acc += A[row * lda + k] * B[k * ldb + col];
        }

        /* C[row][col] = alpha * acc + beta * C[row][col] */
        C[row * ldc + col] = alpha * acc + beta * C[row * ldc + col];
    }

    /* Ensure all stores are visible before signaling completion */
    vx_fence();
}
