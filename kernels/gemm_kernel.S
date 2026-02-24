/**
 * gemm_kernel.S
 *
 * Hand-optimized RV64 GEMM kernel for the Vortex SIMT GPU.
 *
 * Optimizations over the C version:
 *   - Direct FPU register allocation (fa0-fa7 for accumulators)
 *   - K-loop unrolled 4x for instruction-level parallelism
 *   - fmadd.s fused multiply-add (single-cycle on Vortex FPU)
 *   - CSR reads inlined (no function call overhead)
 *   - Minimal register pressure — fits in caller-saved regs
 *
 * ABI: Called by crt0.S with a0 = pointer to GemmKernelArgs
 */

    .text
    .globl  kernel_main
    .type   kernel_main, @function
    .align  2

kernel_main:
    /* ================================================================
     * Prologue — save callee-saved registers
     * ================================================================ */
    addi    sp, sp, -64
    sd      s0, 0(sp)
    sd      s1, 8(sp)
    sd      s2, 16(sp)
    sd      s3, 24(sp)
    sd      s4, 32(sp)
    sd      s5, 40(sp)
    sd      s6, 48(sp)
    sd      s7, 56(sp)

    /* a0 = GemmKernelArgs pointer (from crt0.S) */
    mv      s0, a0              /* s0 = args base pointer */

    /* ================================================================
     * Load kernel arguments from the args struct
     *
     * GemmKernelArgs layout (offsets):
     *   0x00: A_addr (uint64)
     *   0x08: B_addr (uint64)
     *   0x10: C_addr (uint64)
     *   0x18: M      (uint32)
     *   0x1C: N      (uint32)
     *   0x20: K      (uint32)
     *   0x24: lda    (uint32)
     *   0x28: ldb    (uint32)
     *   0x2C: ldc    (uint32)
     *   0x30: alpha   (float)
     *   0x34: beta    (float)
     * ================================================================ */
    ld      s1, 0(s0)           /* s1 = A_addr */
    ld      s2, 8(s0)           /* s2 = B_addr */
    ld      s3, 16(s0)          /* s3 = C_addr */
    lwu     s4, 24(s0)          /* s4 = M */
    lwu     s5, 28(s0)          /* s5 = N */
    lwu     s6, 32(s0)          /* s6 = K */
    lwu     a1, 36(s0)          /* a1 = lda */
    lwu     a2, 40(s0)          /* a2 = ldb */
    lwu     a3, 44(s0)          /* a3 = ldc */
    flw     fa6, 48(s0)         /* fa6 = alpha */
    flw     fa7, 52(s0)         /* fa7 = beta */

    /* ================================================================
     * Compute global thread ID (inlined CSR reads)
     *
     *   gtid = core_id * (num_warps * num_threads)
     *        + warp_id * num_threads
     *        + thread_id
     * ================================================================ */
    csrr    t0, 0xCC0           /* t0 = thread_id */
    csrr    t1, 0xCC1           /* t1 = warp_id */
    csrr    t2, 0xCC2           /* t2 = core_id */
    csrr    t3, 0xFC0           /* t3 = num_threads */
    csrr    t4, 0xFC1           /* t4 = num_warps */
    csrr    t5, 0xFC2           /* t5 = num_cores */

    /* total_hw_threads = num_cores * num_warps * num_threads */
    mulw    s7, t5, t4          /* s7 = num_cores * num_warps */
    mulw    s7, s7, t3          /* s7 = total hw threads (stride) */

    /* gtid = core_id*(num_warps*num_threads) + warp_id*num_threads + tid */
    mulw    t6, t4, t3          /* t6 = num_warps * num_threads */
    mulw    t2, t2, t6          /* t2 = core_id * (nw*nt) */
    mulw    t1, t1, t3          /* t1 = warp_id * num_threads */
    addw    t0, t0, t1          /* t0 = thread_id + warp_id*nt */
    addw    t0, t0, t2          /* t0 = global_tid */

    /* total_elements = M * N */
    mulw    t6, s4, s5          /* t6 = M * N = total_elements */

    /* ================================================================
     * Grid-stride loop: for (idx = gtid; idx < total_elements; idx += stride)
     * ================================================================ */
    mv      a4, t0              /* a4 = idx (current element index) */

.Lloop_outer:
    bgeu    a4, t6, .Ldone      /* if idx >= total_elements, exit */

    /* row = idx / N,  col = idx % N */
    divuw   a5, a4, s5          /* a5 = row = idx / N */
    remuw   a6, a4, s5          /* a6 = col = idx % N */

    /* Bounds check: row < M && col < N (defensive) */
    bgeu    a5, s4, .Lnext      /* skip if row >= M */
    bgeu    a6, s5, .Lnext      /* skip if col >= N */

    /* ================================================================
     * Dot product: acc = sum_{k=0}^{K-1} A[row*lda+k] * B[k*ldb+col]
     *
     * Compute base pointers:
     *   A_row_ptr = A_addr + (row * lda) * 4
     *   B_col_base = B_addr + col * 4
     *   C_elem_ptr = C_addr + (row * ldc + col) * 4
     * ================================================================ */

    /* A_row_ptr = A_addr + row * lda * 4 */
    mulw    t1, a5, a1          /* t1 = row * lda */
    slli    t1, t1, 2           /* t1 = row * lda * 4 (byte offset) */
    add     t1, s1, t1          /* t1 = &A[row * lda] */

    /* B_col_base = B_addr + col * 4 */
    slli    t2, a6, 2           /* t2 = col * 4 */
    add     t2, s2, t2          /* t2 = &B[col] */

    /* B row stride = ldb * 4 */
    slli    t3, a2, 2           /* t3 = ldb * 4 */

    /* C_elem_ptr = C_addr + (row * ldc + col) * 4 */
    mulw    t4, a5, a3          /* t4 = row * ldc */
    addw    t4, t4, a6          /* t4 = row * ldc + col */
    slli    t4, t4, 2           /* t4 *= 4 */
    add     t4, s3, t4          /* t4 = &C[row*ldc + col] */

    /* Initialize accumulator */
    fmv.w.x fa0, zero          /* fa0 = 0.0 (accumulator) */

    /* K-loop with 4x unrolling */
    mv      t5, s6              /* t5 = K (remaining iterations) */
    mv      a7, t1              /* a7 = A pointer (walks along row) */
    mv      t0, t2              /* t0 = B pointer (walks down column) */

    /* Check if K >= 4 for unrolled loop */
    li      t1, 4
    bltu    t5, t1, .Lk_tail

.Lk_unrolled:
    /* Iteration 0 */
    flw     fa1, 0(a7)          /* fa1 = A[row*lda + k+0] */
    flw     fa2, 0(t0)          /* fa2 = B[(k+0)*ldb + col] */
    fmadd.s fa0, fa1, fa2, fa0  /* acc += A * B */

    /* Iteration 1 */
    flw     fa3, 4(a7)          /* fa3 = A[row*lda + k+1] */
    add     t1, t0, t3          /* t1 = B ptr + ldb*4 (next B row) */
    flw     fa4, 0(t1)          /* fa4 = B[(k+1)*ldb + col] */
    fmadd.s fa0, fa3, fa4, fa0  /* acc += A * B */

    /* Iteration 2 */
    flw     fa1, 8(a7)          /* fa1 = A[row*lda + k+2] */
    add     t1, t1, t3          /* t1 = B ptr + 2*ldb*4 */
    flw     fa2, 0(t1)          /* fa2 = B[(k+2)*ldb + col] */
    fmadd.s fa0, fa1, fa2, fa0  /* acc += A * B */

    /* Iteration 3 */
    flw     fa3, 12(a7)         /* fa3 = A[row*lda + k+3] */
    add     t1, t1, t3          /* t1 = B ptr + 3*ldb*4 */
    flw     fa4, 0(t1)          /* fa4 = B[(k+3)*ldb + col] */
    fmadd.s fa0, fa3, fa4, fa0  /* acc += A * B */

    /* Advance pointers and counter */
    addi    a7, a7, 16          /* A ptr += 4 floats */
    slli    t1, t3, 2           /* t1 = 4 * ldb * 4 */
    add     t0, t0, t1          /* B ptr += 4 * ldb * 4 */
    addi    t5, t5, -4          /* K_remaining -= 4 */

    li      t1, 4
    bgeu    t5, t1, .Lk_unrolled

.Lk_tail:
    /* Handle remaining K iterations (0..3) */
    beqz    t5, .Lk_done

.Lk_scalar:
    flw     fa1, 0(a7)          /* fa1 = A[...] */
    flw     fa2, 0(t0)          /* fa2 = B[...] */
    fmadd.s fa0, fa1, fa2, fa0  /* acc += A * B */

    addi    a7, a7, 4           /* A ptr += 1 float */
    add     t0, t0, t3          /* B ptr += ldb * 4 */
    addi    t5, t5, -1
    bnez    t5, .Lk_scalar

.Lk_done:
    /* ================================================================
     * Apply alpha/beta: C[row][col] = alpha * acc + beta * C[row][col]
     * ================================================================ */
    fmul.s  fa0, fa6, fa0       /* fa0 = alpha * acc */
    flw     fa5, 0(t4)          /* fa5 = C[row*ldc + col] (old value) */
    fmadd.s fa0, fa7, fa5, fa0  /* fa0 = beta * C_old + alpha*acc */
    fsw     fa0, 0(t4)          /* Store result */

.Lnext:
    addw    a4, a4, s7          /* idx += stride (total_hw_threads) */
    j       .Lloop_outer

.Ldone:
    /* ================================================================
     * Epilogue — memory fence and return
     * ================================================================ */
    fence                       /* Ensure all stores are visible */

    ld      s0, 0(sp)
    ld      s1, 8(sp)
    ld      s2, 16(sp)
    ld      s3, 24(sp)
    ld      s4, 32(sp)
    ld      s5, 40(sp)
    ld      s6, 48(sp)
    ld      s7, 56(sp)
    addi    sp, sp, 64
    ret

    .size   kernel_main, .-kernel_main
