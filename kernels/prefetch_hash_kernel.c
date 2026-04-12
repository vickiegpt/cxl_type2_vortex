/**
 * prefetch_hash_kernel.c
 *
 * Vortex GPU kernel: hash-probe prefetch.
 *
 * Given pre-computed hash values, resolves bucket heads and follows
 * collision chains. Each SIMT thread handles one hash probe independently,
 * enabling parallel prefetch of multiple buckets.
 *
 * This is the device-side implementation of:
 *   func @walk_chain(%node, %buf, %f)
 * from the paper's Listing 2 (hash join probe).
 */

#include "vx_intrinsics.h"
#include "prefetch_args.h"

void kernel_main(PrefetchHashArgs *args) {
    uint32_t gtid = vx_global_tid();
    uint32_t total_threads = vx_num_hw_threads();

    uint64_t buckets   = args->bucket_array;
    uint64_t hashes    = args->hash_values;
    uint32_t n_probes  = args->num_probes;
    uint32_t n_buckets = args->bucket_count;
    uint32_t next_off  = (uint32_t)args->next_offset;
    uint64_t out_buf   = args->output_buf;
    uint32_t max_chain = args->max_chain_len;

    // Grid-stride loop: each thread handles multiple probes
    for (uint32_t i = gtid; i < n_probes; i += total_threads) {
        // Read pre-computed hash value
        volatile uint32_t* hash_ptr =
            (volatile uint32_t*)(uintptr_t)(hashes + i * 4);
        uint32_t h = *hash_ptr;
        uint32_t bucket_idx = h % n_buckets;

        // Read bucket head pointer
        volatile uint64_t* bucket_head_ptr =
            (volatile uint64_t*)(uintptr_t)(buckets + bucket_idx * 8);
        uint64_t node_addr = *bucket_head_ptr;

        // Follow collision chain
        uint32_t chain_depth = 0;
        while (node_addr != 0 && chain_depth < max_chain) {
            // Touch the node (brings it into device cache -> DCOH -> host LLC)
            volatile uint64_t* node_data = (volatile uint64_t*)(uintptr_t)node_addr;
            uint64_t dummy = *node_data;  // Force cache fill
            (void)dummy;

            // Write node address to output buffer so host can check matches
            if (out_buf != 0) {
                volatile uint64_t* out =
                    (volatile uint64_t*)(uintptr_t)(out_buf + (i * max_chain + chain_depth) * 8);
                *out = node_addr;
            }

            // Follow next pointer
            volatile uint64_t* next_ptr =
                (volatile uint64_t*)(uintptr_t)(node_addr + next_off);
            node_addr = *next_ptr;
            chain_depth++;
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
