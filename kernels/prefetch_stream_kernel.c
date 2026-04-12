/**
 * prefetch_stream_kernel.c
 *
 * Vortex GPU kernel: streaming/strided prefetch.
 *
 * Walks a contiguous or strided memory region, touching each element
 * to bring it into the device cache (DCOH pushes to host LLC).
 * All SIMT threads participate for maximum memory bandwidth.
 */

#include "vx_intrinsics.h"
#include "prefetch_args.h"

void kernel_main(PrefetchStreamArgs *args) {
    uint32_t gtid = vx_global_tid();
    uint32_t total_threads = vx_num_hw_threads();

    uint64_t base   = args->base_addr;
    uint64_t stride = args->stride;
    uint32_t count  = args->count;
    uint32_t elem_sz = args->element_size;

    // If stride is 0, use element_size as stride (contiguous)
    if (stride == 0) {
        stride = elem_sz;
    }

    // Grid-stride loop: each thread touches a subset of elements
    for (uint32_t i = gtid; i < count; i += total_threads) {
        uint64_t addr = base + i * stride;

        // Touch the first cacheline of this element
        volatile uint64_t* ptr = (volatile uint64_t*)(uintptr_t)addr;
        uint64_t dummy = *ptr;
        (void)dummy;

        // If element spans multiple cachelines, touch those too
        if (elem_sz > 64) {
            uint32_t extra_lines = (elem_sz - 1) / 64;
            for (uint32_t cl = 1; cl <= extra_lines; cl++) {
                volatile uint64_t* cl_ptr =
                    (volatile uint64_t*)(uintptr_t)(addr + cl * 64);
                dummy = *cl_ptr;
                (void)dummy;
            }
        }
    }

    vx_fence();

    // Thread 0 signals completion
    if (gtid == 0 && args->completion_addr != 0) {
        volatile uint32_t* magic =
            (volatile uint32_t*)(uintptr_t)(args->completion_addr);
        volatile uint32_t* tid =
            (volatile uint32_t*)(uintptr_t)(args->completion_addr + 4);
        *tid = args->task_id;
        vx_fence();
        *magic = COMPLETION_MAGIC;
        vx_fence();
    }
}
