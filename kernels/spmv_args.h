/**
 * spmv_args.h
 *
 * Shared host/device argument structures for the SpMV kernel.
 *
 * This header is included by both:
 *   - Host code (fpga_sparse_matrix_kernel.cpp) compiled with g++
 *   - Device code (spmv_kernel.c) compiled with riscv64-unknown-elf-gcc
 *
 * All structures are layout-compatible across LP64 ABIs.
 */

#ifndef SPMV_ARGS_H
#define SPMV_ARGS_H

#include <stdint.h>

/* ========================================================================
 * Constants
 * ======================================================================== */

#define CACHE_LINE_SIZE     64
#define COMPLETION_MAGIC    0xDEADBEEF

/* ========================================================================
 * CompletionData — 64-byte cache-line aligned completion structure
 *
 * Written by the GPU (via DCOH writeback) to signal kernel completion.
 * The host polls 'magic' for COMPLETION_MAGIC.
 * ======================================================================== */

typedef struct __attribute__((aligned(CACHE_LINE_SIZE))) {
    uint32_t magic;         /* 0xDEADBEEF when valid                     */
    uint32_t status;        /* Kernel completion status (0 = success)     */
    uint64_t result;        /* Result data (e.g. FLOP count)             */
    uint64_t cycles;        /* GPU cycle count                            */
    uint64_t timestamp;     /* Timestamp                                  */
    uint8_t  reserved[32];  /* Padding to 64 bytes (full cache line)      */
} SpmvCompletionData;

/* ========================================================================
 * SpmvKernelArgs — Kernel argument block passed via mscratch
 *
 * Addresses are offsets from the shared memory base. The kernel reads
 * this structure pointer from CSR mscratch (0x340), which the host
 * sets via the DCR startup_arg register.
 * ======================================================================== */

typedef struct __attribute__((aligned(CACHE_LINE_SIZE))) {
    uint64_t row_ptr_addr;      /* Offset/address of row pointers (m+1 ints) */
    uint64_t col_idx_addr;      /* Offset/address of column indices (nnz ints) */
    uint64_t values_addr;       /* Offset/address of values array (nnz floats) */
    uint64_t x_addr;            /* Offset/address of input vector X (n floats) */
    uint64_t y_addr;            /* Offset/address of output vector Y (m floats) */
    uint32_t m;                 /* Number of rows                              */
    uint32_t n;                 /* Number of columns                           */
    uint32_t nnz;               /* Number of non-zeros                         */
    uint32_t pad0;              /* Alignment padding                           */
    uint64_t completion_addr;   /* Address for DCOH completion writeback       */
} SpmvKernelArgs;

/* ========================================================================
 * Memory layout offsets (must match host-side layout)
 * ======================================================================== */

#define SPMV_ARGS_OFFSET         0x0000  /* SpmvKernelArgs                */
#define SPMV_COMPLETION_OFFSET   0x0040  /* SpmvCompletionData            */
#define SPMV_DATA_BASE           0x1000  /* First data array (4KB aligned) */

#endif /* SPMV_ARGS_H */
