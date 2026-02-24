/**
 * gemm_args.h
 *
 * Shared host/device argument structures for the GEMM kernel.
 *
 * This header is included by both:
 *   - Host code (test_gemm_coherent.cpp) compiled with g++
 *   - Device code (gemm_kernel.c) compiled with riscv64-unknown-elf-gcc
 *
 * All structures are layout-compatible across LP64 ABIs.
 */

#ifndef GEMM_ARGS_H
#define GEMM_ARGS_H

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
 * The host polls 'magic' for COMPLETION_MAGIC using monitor/mwait.
 * ======================================================================== */

typedef struct __attribute__((aligned(CACHE_LINE_SIZE))) {
    uint32_t magic;         /* 0xDEADBEEF when valid                     */
    uint32_t status;        /* Kernel completion status (0 = success)     */
    uint64_t result;        /* Result data (e.g. FLOP count)             */
    uint64_t cycles;        /* GPU cycle count                            */
    uint64_t timestamp;     /* Timestamp                                  */
    uint8_t  reserved[32];  /* Padding to 64 bytes (full cache line)      */
} CompletionData;

/* ========================================================================
 * GemmKernelArgs — Kernel argument block passed via mscratch
 *
 * Addresses are offsets from the shared memory base. The kernel reads
 * this structure pointer from CSR mscratch (0x340), which the host
 * sets via the DCR startup_arg register.
 * ======================================================================== */

typedef struct __attribute__((aligned(CACHE_LINE_SIZE))) {
    uint64_t A_addr;            /* Offset/address of matrix A (M x K)    */
    uint64_t B_addr;            /* Offset/address of matrix B (K x N)    */
    uint64_t C_addr;            /* Offset/address of matrix C (M x N)    */
    uint32_t M;                 /* Rows of A, rows of C                  */
    uint32_t N;                 /* Cols of B, cols of C                   */
    uint32_t K;                 /* Cols of A, rows of B                   */
    uint32_t lda;               /* Leading dimension of A                 */
    uint32_t ldb;               /* Leading dimension of B                 */
    uint32_t ldc;               /* Leading dimension of C                 */
    float    alpha;             /* Scalar multiplier for A*B              */
    float    beta;              /* Scalar multiplier for existing C       */
    uint64_t completion_addr;   /* Address for DCOH completion writeback  */
    uint8_t  pad[4];            /* Pad to 72 bytes                        */
} GemmKernelArgs;

/* ========================================================================
 * Memory layout offsets (must match host-side layout)
 * ======================================================================== */

#define ARGS_OFFSET         0x0000  /* GemmKernelArgs                    */
#define COMPLETION_OFFSET   0x0040  /* CompletionData                    */
#define MATRIX_BASE         0x1000  /* First matrix (4KB aligned)        */

#endif /* GEMM_ARGS_H */
