/**
 * prefetch_args.h
 *
 * Shared argument structures for CIRA prefetch kernels.
 * These structs are allocated by the host and passed to Vortex
 * kernels via the DCR startup_arg mechanism.
 *
 * All addresses are 64-bit physical/device addresses.
 * All structs are cache-line aligned for DCOH coherence.
 */

#ifndef PREFETCH_ARGS_H
#define PREFETCH_ARGS_H

#include <stdint.h>

#define CACHELINE_ALIGN __attribute__((aligned(64)))

/**
 * PrefetchChainArgs — pointer-chase prefetch kernel.
 *
 * Chases a linked list: start_node->next->next->... for depth steps.
 * Writes each node's data to the output buffer for host consumption.
 * Signals completion by writing magic to completion_addr.
 */
typedef struct CACHELINE_ALIGN {
    uint64_t start_node;        // Address of first node in the chain
    uint64_t next_offset;       // Byte offset of 'next' pointer within node
    uint64_t data_offset;       // Byte offset of 'data' field within node
    uint32_t data_size;         // Size of data to copy per node (bytes)
    uint32_t depth;             // Number of nodes to chase ahead
    uint64_t output_buf;        // Host-visible buffer to write data into
    uint64_t completion_addr;   // Where to write CompletionData (magic=0xDEADBEEF)
    uint32_t task_id;           // Task ID for completion tracking
    uint32_t padding[5];
} PrefetchChainArgs;

/**
 * PrefetchHashArgs — hash-probe prefetch kernel.
 *
 * Given an array of hash values, prefetches the corresponding bucket
 * heads and chases collision chains. Writes resolved nodes to output.
 */
typedef struct CACHELINE_ALIGN {
    uint64_t bucket_array;      // Base address of hash table bucket array
    uint64_t hash_values;       // Array of pre-computed hash values
    uint32_t num_probes;        // Number of hash probes to perform
    uint32_t bucket_count;      // Number of buckets in hash table
    uint64_t next_offset;       // Byte offset of 'next' in bucket node
    uint64_t output_buf;        // Host-visible buffer for resolved nodes
    uint64_t completion_addr;   // CompletionData address
    uint32_t task_id;
    uint32_t max_chain_len;     // Max collision chain length to follow
    uint32_t padding[2];
} PrefetchHashArgs;

/**
 * PrefetchStreamArgs — streaming/strided prefetch kernel.
 *
 * Issues prefetch requests for a contiguous or strided memory region,
 * bringing data into the host LLC ahead of consumption.
 */
typedef struct CACHELINE_ALIGN {
    uint64_t base_addr;         // Start address
    uint64_t stride;            // Stride between elements (bytes), 0 = contiguous
    uint32_t count;             // Number of elements to prefetch
    uint32_t element_size;      // Size of each element (bytes)
    uint64_t output_buf;        // Not used for streaming, but kept for uniformity
    uint64_t completion_addr;
    uint32_t task_id;
    uint32_t padding[5];
} PrefetchStreamArgs;

/* Completion magic value (must match runtime/completion_data.h) */
#define COMPLETION_MAGIC 0xDEADBEEF

#endif /* PREFETCH_ARGS_H */
