/**
 * lock_kernel.c
 *
 * Vortex GPU RISC-V kernel implementing three CXL lock test scenarios:
 *   1. FetchAdd Total Order - concurrent amoadd.d on shared counter
 *   2. Dekker Ordering      - store-buffer litmus test (GPU = Thread B)
 *   3. Mutex Contention     - ticket lock acquire/release
 *
 * All atomics use RISC-V AMO instructions which travel through the
 * CXL.cache coherent fabric, testing real cross-device synchronization.
 *
 * Compile:
 *   riscv64-linux-gnu-gcc -march=rv64imafdc -mabi=lp64d \
 *       -nostdlib -nostartfiles -O2 -ffreestanding -c lock_kernel.c
 */

#include "vx_intrinsics.h"
#include "lock_args.h"

/* ========================================================================
 * RISC-V Atomic Memory Operations (AMO)
 *
 * These generate real AMO instructions that go through the CXL fabric
 * when accessing CXL device memory — equivalent to CUDA atomicAdd_system.
 * ======================================================================== */

/* Atomic fetch-and-add (64-bit): returns old value */
static inline uint64_t amo_fetch_add_d(volatile uint64_t* addr, uint64_t val) {
    uint64_t result;
    __asm__ __volatile__ (
        "amoadd.d.aqrl %0, %1, (%2)"
        : "=r"(result)
        : "r"(val), "r"(addr)
        : "memory"
    );
    return result;
}

/* Atomic load (64-bit) via amoadd.d with 0 — non-destructive read */
static inline uint64_t amo_load_d(volatile uint64_t* addr) {
    uint64_t result;
    __asm__ __volatile__ (
        "amoadd.d.aq %0, zero, (%1)"
        : "=r"(result)
        : "r"(addr)
        : "memory"
    );
    return result;
}

/* Atomic store: plain store + fence (RISC-V doesn't have amo_store) */
static inline void amo_store_d(volatile uint64_t* addr, uint64_t val) {
    *addr = val;
    __asm__ __volatile__ ("fence rw, rw" ::: "memory");
}

/* Full memory fence (iorw, iorw) — equivalent to __threadfence_system */
static inline void full_fence(void) {
    __asm__ __volatile__ ("fence iorw, iorw" ::: "memory");
}

/* ========================================================================
 * Test 1: FetchAdd Total Order
 *
 * Each GPU thread does fetch_add(1) on a shared counter and records
 * the returned value. After all threads complete, the host verifies
 * that all values are unique and form a contiguous range — proving
 * per-location total ordering at the CXL Completer.
 * ======================================================================== */

static void test_fetchadd(LockTestArgs* args) {
    uint32_t gtid = vx_global_tid();
    uint32_t n_hw_threads = vx_num_hw_threads();

    volatile uint64_t* counter = (volatile uint64_t*)args->counter_addr;
    volatile uint64_t* values  = (volatile uint64_t*)args->values_addr;
    uint64_t iters = args->iterations;

    /* Only use the requested number of GPU threads */
    if (gtid >= args->gpu_threads) return;

    /* Grid-stride loop: each thread does 'iters' fetch_add operations */
    for (uint64_t i = 0; i < iters; i++) {
        uint64_t val = amo_fetch_add_d(counter, 1);
        /* Store the obtained value for host-side verification */
        values[gtid * iters + i] = val;
    }

    vx_fence();
}

/* ========================================================================
 * Test 2: Dekker's Cross-Device Ordering
 *
 * GPU acts as Thread B in the classic store-buffer litmus test:
 *   Thread A (CPU):  x = 1;  fence;  read y
 *   Thread B (GPU):  y = 1;  fence;  read x
 *
 * If both read 0, Sequential Consistency is violated.
 * We iterate and record what the GPU saw for each iteration.
 *
 * The host synchronizes iterations by writing flag_x/flag_y to 0
 * between rounds and using a simple protocol:
 *   - GPU waits for args->flag_y_addr to be 0 (reset by host)
 *   - GPU writes y=1, fence, reads x
 *   - GPU stores result in gpu_saw_x[iter]
 * ======================================================================== */

static void test_dekker(LockTestArgs* args) {
    uint32_t gtid = vx_global_tid();

    /* Only thread 0 participates in Dekker test (single GPU thread) */
    if (gtid != 0) return;

    volatile uint64_t* flag_x     = (volatile uint64_t*)args->flag_x_addr;
    volatile uint64_t* flag_y     = (volatile uint64_t*)args->flag_y_addr;
    volatile uint64_t* gpu_saw_x  = (volatile uint64_t*)args->gpu_saw_x_addr;
    uint64_t iters = args->iterations;

    for (uint64_t i = 0; i < iters; i++) {
        /* Thread B: write y = 1 */
        amo_store_d(flag_y, 1);

        /* Full fence — ensure y=1 is visible before reading x */
        full_fence();

        /* Thread B: read x */
        uint64_t saw_x = amo_load_d(flag_x);

        /* Record what we saw */
        gpu_saw_x[i] = saw_x;

        /* Wait for host to reset flags for next iteration */
        while (amo_load_d(flag_y) != 0) {
            /* Spin until host resets y to 0 */
        }
    }

    vx_fence();
}

/* ========================================================================
 * Test 3: Ticket Lock Mutex Contention
 *
 * GPU threads compete with CPU threads for a ticket lock.
 * Lock state is in CXL shared memory:
 *   - next_ticket: atomic fetch_add to get a ticket
 *   - now_serving: spin until our ticket matches
 *
 * In the critical section, each thread increments a shared counter.
 * After all threads complete, counter should equal total iterations.
 * ======================================================================== */

static void test_mutex(LockTestArgs* args) {
    uint32_t gtid = vx_global_tid();

    if (gtid >= args->gpu_threads) return;

    volatile uint64_t* now_serving = (volatile uint64_t*)args->now_serving_addr;
    volatile uint64_t* next_ticket = (volatile uint64_t*)args->next_ticket_addr;
    volatile uint64_t* counter     = (volatile uint64_t*)args->counter_addr;
    uint64_t iters = args->iterations;

    for (uint64_t i = 0; i < iters; i++) {
        /* Acquire: get ticket via atomic fetch_add through CXL */
        uint64_t my_ticket = amo_fetch_add_d(next_ticket, 1);

        /* Spin until our ticket is being served */
        while (1) {
            full_fence();
            uint64_t current = amo_load_d(now_serving);
            if (current == my_ticket) break;
        }

        /* === Critical Section === */
        /* Read-modify-write the shared counter (non-atomic is fine under lock) */
        uint64_t val = *counter;
        *counter = val + 1;
        full_fence();

        /* Release: increment now_serving to hand lock to next waiter */
        amo_fetch_add_d(now_serving, 1);
        full_fence();
    }

    vx_fence();
}

/* ========================================================================
 * kernel_main — Entry point (called from crt0.S with args in a0)
 * ======================================================================== */

void kernel_main(LockTestArgs* args) {
    switch (args->test_type) {
    case LOCK_TEST_FETCHADD:
        test_fetchadd(args);
        break;
    case LOCK_TEST_DEKKER:
        test_dekker(args);
        break;
    case LOCK_TEST_MUTEX:
        test_mutex(args);
        break;
    default:
        break;
    }

    /* Signal completion (only thread 0) */
    if (vx_global_tid() == 0 && args->completion_addr != 0) {
        volatile uint32_t* comp = (volatile uint32_t*)args->completion_addr;
        *comp = LOCK_COMPLETION_MAGIC;
        vx_fence();
    }
}
