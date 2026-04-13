/**
 * lock_args.h
 *
 * Shared host/device argument structures for CXL lock test kernels.
 * Included by both host (g++) and device (riscv64 gcc) code.
 *
 * Memory layout (GPU address space, starting at SHARED_BASE):
 *   0x00  LockTestArgs      (kernel arguments)
 *   0x80  shared counter    (atomic, 64-bit)
 *   0x100 now_serving       (ticket lock: serving counter)
 *   0x140 next_ticket       (ticket lock: ticket dispenser)
 *   0x180 flag_x            (Dekker: CPU's flag)
 *   0x1C0 flag_y            (Dekker: GPU's flag)
 *   0x200 gpu_saw_x[]       (Dekker: per-iteration results)
 *   0x1000 values[]         (FetchAdd: per-thread collected values)
 */

#ifndef LOCK_ARGS_H
#define LOCK_ARGS_H

#include <stdint.h>

#define LOCK_COMPLETION_MAGIC  0xCAFEBEEF

/* Offsets from shared memory base (GPU address = SHARED_BASE + offset) */
#define LOCK_ARGS_OFFSET       0x000
#define LOCK_COUNTER_OFFSET    0x080
#define LOCK_NOW_SERVING_OFF   0x100
#define LOCK_NEXT_TICKET_OFF   0x140
#define LOCK_FLAG_X_OFFSET     0x180
#define LOCK_FLAG_Y_OFFSET     0x1C0
#define LOCK_GPU_SAW_X_OFFSET  0x200
#define LOCK_VALUES_OFFSET     0x1000

/* Test types */
#define LOCK_TEST_FETCHADD     1
#define LOCK_TEST_DEKKER       2
#define LOCK_TEST_MUTEX        3

/**
 * LockTestArgs - passed to GPU kernel via mscratch (DCR startup_arg)
 *
 * The args structure is placed at SHARED_BASE + LOCK_ARGS_OFFSET.
 * The host writes it before launching the GPU.
 * The kernel reads it from mscratch CSR.
 */
typedef struct __attribute__((aligned(64))) {
    uint32_t test_type;          /* LOCK_TEST_FETCHADD | DEKKER | MUTEX */
    uint32_t gpu_threads;        /* Number of GPU threads to use */
    uint64_t iterations;         /* Iterations per GPU thread */

    /* Pointers to shared state (GPU virtual addresses) */
    uint64_t counter_addr;       /* Shared atomic counter */
    uint64_t now_serving_addr;   /* Ticket lock: now_serving */
    uint64_t next_ticket_addr;   /* Ticket lock: next_ticket */
    uint64_t flag_x_addr;        /* Dekker: flag_x (CPU writes) */
    uint64_t flag_y_addr;        /* Dekker: flag_y (GPU writes) */
    uint64_t gpu_saw_x_addr;     /* Dekker: GPU results array */
    uint64_t values_addr;        /* FetchAdd: collected values array */

    /* Completion signaling */
    uint64_t completion_addr;    /* Write LOCK_COMPLETION_MAGIC here when done */

    uint64_t pad[2];             /* Align to 128 bytes */
} LockTestArgs;

#endif /* LOCK_ARGS_H */
