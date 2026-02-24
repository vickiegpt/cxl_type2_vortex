/**
 * crt0.S
 *
 * Minimal C runtime startup for Vortex GPU kernels.
 *
 * This runs at the entry point (PC = 0x80000000, set by DCR startup_addr).
 * Every hardware thread executes this code simultaneously.
 *
 * Startup sequence:
 *   1. Set per-thread stack pointer (unique per global_tid)
 *   2. Read kernel args pointer from mscratch (set by host via DCR startup_arg)
 *   3. Call kernel_main(args)
 *   4. On return: loop forever (thread exits when TMC mask clears it)
 *
 * Stack layout:
 *   sp = _stack_base - (global_tid + 1) * STACK_SIZE
 *   Each thread gets STACK_SIZE (4KB) of private stack space.
 */

    .text
    .globl  _start
    .type   _start, @function
    .align  2

    /* Per-thread stack size (4KB) */
    .equ    STACK_SIZE, 4096

_start:
    /* ================================================================
     * Step 1: Compute global thread ID
     *
     *   gtid = core_id * (num_warps * num_threads)
     *        + warp_id * num_threads
     *        + thread_id
     * ================================================================ */
    csrr    t0, 0xCC0           /* t0 = thread_id */
    csrr    t1, 0xCC1           /* t1 = warp_id */
    csrr    t2, 0xCC2           /* t2 = core_id */
    csrr    t3, 0xFC0           /* t3 = num_threads (per warp) */
    csrr    t4, 0xFC1           /* t4 = num_warps (per core) */

    /* threads_per_core = num_warps * num_threads */
    mul     t5, t4, t3          /* t5 = num_warps * num_threads */

    /* gtid = core_id * threads_per_core + warp_id * num_threads + thread_id */
    mul     t2, t2, t5          /* t2 = core_id * threads_per_core */
    mul     t1, t1, t3          /* t1 = warp_id * num_threads */
    add     t0, t0, t1          /* t0 += warp_id * num_threads */
    add     t0, t0, t2          /* t0 = global_tid */

    /* ================================================================
     * Step 2: Set per-thread stack pointer
     *
     *   sp = _stack_base - (global_tid + 1) * STACK_SIZE
     *
     * This gives each thread a unique, non-overlapping stack region
     * growing downward from _stack_base.
     * ================================================================ */
    la      t1, _stack_base     /* t1 = stack base address */
    addi    t2, t0, 1           /* t2 = global_tid + 1 */
    li      t3, STACK_SIZE
    mul     t2, t2, t3          /* t2 = (gtid + 1) * STACK_SIZE */
    sub     sp, t1, t2          /* sp = _stack_base - offset */

    /* Clear frame pointer */
    mv      fp, zero

    /* ================================================================
     * Step 3: Read kernel args pointer from mscratch
     *
     * The host writes the kernel args address to the DCR startup_arg
     * register, which the Vortex RTL loads into mscratch before
     * starting execution.
     * ================================================================ */
    csrr    a0, 0x340           /* a0 = mscratch = kernel args pointer */

    /* ================================================================
     * Step 4: Call kernel_main(args)
     *
     * a0 = pointer to GemmKernelArgs (or generic kernel args struct)
     * ================================================================ */
    call    kernel_main

    /* ================================================================
     * Step 5: Thread exit
     *
     * After kernel_main returns, the thread has no more work.
     * Issue ecall to signal completion to the Vortex runtime,
     * then spin in a tight loop as a safety net.
     * ================================================================ */
    ecall

.Lhalt:
    j       .Lhalt              /* Should never reach here */

    .size   _start, .-_start
