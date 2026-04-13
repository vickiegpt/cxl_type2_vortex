/**
 * spmv_kernel.c
 *
 * Vortex GPU SpMV (Sparse Matrix-Vector Multiply) kernel — C implementation.
 *
 * Computes y = A * x where A is in CSR format using SIMT parallelism.
 * Each hardware thread computes one or more rows of the output vector y.
 *
 * Compile with:
 *   riscv64-unknown-elf-gcc -march=rv64imafdc -mabi=lp64d \
 *       -nostdlib -nostartfiles -O2 -ffreestanding -c spmv_kernel.c
 *
 * Thread mapping:
 *   global_tid = core_id * (num_warps * num_threads) + warp_id * num_threads + thread_id
 *   total_hw_threads = num_cores * num_warps * num_threads
 *
 *   For each row i where i < M:
 *     Threads stride by total_hw_threads to cover all rows.
 */

#include "vx_intrinsics.h"
#include "spmv_args.h"

/**
 * kernel_main — Entry point called by crt0.S
 *
 * @param args  Pointer to SpmvKernelArgs in shared memory (from mscratch)
 */
void kernel_main(SpmvKernelArgs *args) {
    /* Read SpMV parameters */
    const uint32_t M   = args->m;
    const uint32_t nnz = args->nnz;

    /* Array base pointers (addresses/offsets from shared memory base).
     * In the Vortex memory model, these are direct pointers — the host
     * sets them to the shared memory region accessible by the GPU via AXI. */
    const int   *row_ptr = (const int   *)(uintptr_t)args->row_ptr_addr;
    const int   *col_idx = (const int   *)(uintptr_t)args->col_idx_addr;
    const float *values  = (const float *)(uintptr_t)args->values_addr;
    const float *x       = (const float *)(uintptr_t)args->x_addr;
    float       *y       = (float       *)(uintptr_t)args->y_addr;

    /* Compute global thread ID and total thread count */
    const uint32_t gtid             = vx_global_tid();
    const uint32_t num_threads_total = vx_num_hw_threads();

    /* Each thread iterates over rows with a stride of
     * total hardware threads (grid-stride loop pattern) */
    for (uint32_t i = gtid; i < M; i += num_threads_total) {
        float sum = 0.0f;
        int row_start = row_ptr[i];
        int row_end   = row_ptr[i + 1];

        for (int j = row_start; j < row_end; j++) {
            sum += values[j] * x[col_idx[j]];
        }

        y[i] = sum;
    }

    /* Ensure all stores are visible before signaling completion */
    vx_fence();
}
