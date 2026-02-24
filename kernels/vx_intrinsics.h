/**
 * vx_intrinsics.h
 *
 * Vortex RISC-V GPU intrinsics for kernel development.
 *
 * Provides portable C/inline-asm macros for accessing Vortex-specific
 * CSRs and custom instructions. Compilable with:
 *   riscv64-unknown-elf-gcc -march=rv64imafdc -mabi=lp64d
 *
 * Vortex CSR map (from RTL VX_types.vh):
 *   0xCC0  thread_id    (per-warp thread index)
 *   0xCC1  warp_id      (per-core warp index)
 *   0xCC2  core_id      (global core index)
 *   0xFC0  num_threads  (threads per warp)
 *   0xFC1  num_warps    (warps per core)
 *   0xFC2  num_cores    (total cores)
 *   0x340  mscratch     (kernel args pointer, loaded by DCR startup_arg)
 */

#ifndef VX_INTRINSICS_H
#define VX_INTRINSICS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* ========================================================================
 * CSR read/write helpers
 * ======================================================================== */

#define VX_CSR_READ(csr, result)                                        \
    __asm__ __volatile__ ("csrr %0, " #csr : "=r"(result))

#define VX_CSR_WRITE(csr, value)                                        \
    __asm__ __volatile__ ("csrw " #csr ", %0" :: "r"(value))

/* ========================================================================
 * Thread / warp / core identification
 * ======================================================================== */

/* Thread index within the warp (0 .. num_threads-1) */
static inline uint32_t vx_thread_id(void) {
    uint32_t val;
    VX_CSR_READ(0xCC0, val);
    return val;
}

/* Warp index within the core (0 .. num_warps-1) */
static inline uint32_t vx_warp_id(void) {
    uint32_t val;
    VX_CSR_READ(0xCC1, val);
    return val;
}

/* Core index (0 .. num_cores-1) */
static inline uint32_t vx_core_id(void) {
    uint32_t val;
    VX_CSR_READ(0xCC2, val);
    return val;
}

/* ========================================================================
 * Hardware capability CSRs
 * ======================================================================== */

/* Number of threads per warp */
static inline uint32_t vx_num_threads(void) {
    uint32_t val;
    VX_CSR_READ(0xFC0, val);
    return val;
}

/* Number of warps per core */
static inline uint32_t vx_num_warps(void) {
    uint32_t val;
    VX_CSR_READ(0xFC1, val);
    return val;
}

/* Number of cores */
static inline uint32_t vx_num_cores(void) {
    uint32_t val;
    VX_CSR_READ(0xFC2, val);
    return val;
}

/* ========================================================================
 * Kernel arguments pointer (from DCR startup_arg → mscratch)
 * ======================================================================== */

/* Returns the kernel arguments pointer set by the host via DCR */
static inline void* vx_kernel_arg(void) {
    uint64_t val;
    VX_CSR_READ(0x340, val);  /* mscratch */
    return (void*)val;
}

/* ========================================================================
 * Global thread ID — unique ID across all cores/warps/threads
 *
 *   global_tid = core_id * (num_warps * num_threads)
 *              + warp_id * num_threads
 *              + thread_id
 * ======================================================================== */

static inline uint32_t vx_global_tid(void) {
    uint32_t tid = vx_thread_id();
    uint32_t wid = vx_warp_id();
    uint32_t cid = vx_core_id();
    uint32_t nt  = vx_num_threads();
    uint32_t nw  = vx_num_warps();
    return cid * (nw * nt) + wid * nt + tid;
}

/* Total number of hardware threads across all cores */
static inline uint32_t vx_num_hw_threads(void) {
    return vx_num_cores() * vx_num_warps() * vx_num_threads();
}

/* ========================================================================
 * Thread Mask Control (TMC)
 *
 * Sets the active thread mask for the current warp.
 * Only threads with corresponding bit set in 'mask' will execute.
 * Encoded as CSR write to Vortex custom CSR.
 * ======================================================================== */

static inline void vx_tmc(uint32_t mask) {
    /* Vortex TMC: csrw 0xCC4, mask */
    VX_CSR_WRITE(0xCC4, mask);
}

/* ========================================================================
 * Barrier (SFU instruction)
 *
 * Vortex barrier: synchronize 'count' warps at barrier 'id'.
 * Encoded as: .insn r CUSTOM_0, 0, 0, x0, rs1(id), rs2(count)
 * The SFU (Special Function Unit) handles the synchronization.
 * ======================================================================== */

static inline void vx_barrier(uint32_t id, uint32_t count) {
    /* Encode as a custom-0 R-type instruction:
     * opcode  = 0x0B (CUSTOM_0)
     * funct3  = 0
     * funct7  = 0 (barrier sub-op)
     * rd      = x0
     * rs1     = id
     * rs2     = count
     */
    __asm__ __volatile__ (
        ".insn r 0x0B, 0, 0, x0, %0, %1"
        :
        : "r"(id), "r"(count)
        : "memory"
    );
}

/* ========================================================================
 * Fence / memory ordering
 * ======================================================================== */

static inline void vx_fence(void) {
    __asm__ __volatile__ ("fence" ::: "memory");
}

#ifdef __cplusplus
}
#endif

#endif /* VX_INTRINSICS_H */
