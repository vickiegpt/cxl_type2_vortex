/**
 * prefetch_chain_kernel.c
 *
 * Vortex GPU kernel: pointer-chase prefetch.
 *
 * Chases a linked-list chain for 'depth' steps, installing each node's
 * cacheline into the device cache (which DCOH pushes to host LLC).
 * Writes each node's data payload to a host-visible output buffer.
 *
 * This is the device-side implementation of:
 *   func @chase_prefetch(%node, %buf, %f)
 * from the paper's Listing 1.
 *
 * Thread model: Thread 0 does the chain walk (inherently serial).
 * Other threads in the warp can handle parallel prefetch of node
 * data fields if data_size > cacheline.
 */

#include "vx_intrinsics.h"
#include "prefetch_args.h"

/**
 * Signal completion to the host.
 * Writes CompletionData struct to the pre-allocated cacheline.
 */
static void signal_completion(uint64_t completion_addr, uint32_t task_id,
                              uint32_t status, uint32_t cycles) {
    volatile uint32_t* magic  = (volatile uint32_t*)(uintptr_t)(completion_addr);
    volatile uint32_t* tid    = (volatile uint32_t*)(uintptr_t)(completion_addr + 4);
    volatile uint32_t* stat   = (volatile uint32_t*)(uintptr_t)(completion_addr + 8);
    volatile uint32_t* cyc    = (volatile uint32_t*)(uintptr_t)(completion_addr + 12);

    *tid = task_id;
    *stat = status;
    *cyc = cycles;
    vx_fence();      // Ensure data fields visible before magic
    *magic = COMPLETION_MAGIC;
    vx_fence();      // Ensure magic is globally visible (DCOH pushes to host)
}

void kernel_main(PrefetchChainArgs *args) {
    uint32_t gtid = vx_global_tid();

    // Only thread 0 performs the chain walk (pointer chasing is serial)
    if (gtid != 0) return;

    uint64_t node_addr = args->start_node;
    uint32_t next_off  = (uint32_t)args->next_offset;
    uint32_t data_off  = (uint32_t)args->data_offset;
    uint32_t data_sz   = args->data_size;
    uint32_t depth     = args->depth;
    uint64_t out_buf   = args->output_buf;

    uint32_t nodes_fetched = 0;

    for (uint32_t step = 0; step < depth && node_addr != 0; step++) {
        // Read the 'next' pointer (this is the dependent load chain)
        volatile uint64_t* next_ptr =
            (volatile uint64_t*)(uintptr_t)(node_addr + next_off);
        uint64_t next_addr = *next_ptr;

        // Copy the node's data payload to the output buffer
        if (data_sz > 0 && out_buf != 0) {
            volatile uint8_t* src = (volatile uint8_t*)(uintptr_t)(node_addr + data_off);
            volatile uint8_t* dst = (volatile uint8_t*)(uintptr_t)(out_buf + step * data_sz);

            // Copy in 8-byte chunks for efficiency on RV64
            uint32_t chunks = data_sz / 8;
            uint32_t remainder = data_sz % 8;
            for (uint32_t i = 0; i < chunks; i++) {
                ((volatile uint64_t*)dst)[i] = ((volatile uint64_t*)src)[i];
            }
            for (uint32_t i = 0; i < remainder; i++) {
                dst[chunks * 8 + i] = src[chunks * 8 + i];
            }
        }

        nodes_fetched++;
        node_addr = next_addr;
    }

    // Signal completion to host via DCOH
    if (args->completion_addr != 0) {
        signal_completion(args->completion_addr, args->task_id,
                          0 /* success */, nodes_fetched);
    }

    vx_fence();
}
