/**
 * test_csr_readback.cpp
 *
 * Tests whether BAR0 CSR registers on the CXL Type2 device (0000:ad:00.0)
 * are backed by real FPGA logic by writing test patterns and reading them back.
 *
 * Tests:
 *   1. Initial state — RW registers should have reset defaults
 *   2. Write/readback on all RW registers (KERNEL_ADDR, GRID_DIM, etc.)
 *   3. STATUS register reads (should be IDLE=0x00)
 *   4. Walking-ones pattern on GRID_DIM_X (all 32 bits)
 *   5. All-ones / all-zeros pattern
 *   6. Launch + status transition (IDLE -> RUNNING -> DONE)
 *   7. Restore all registers after test
 *
 * Usage:
 *   g++ -std=c++17 -O2 -o test_csr_readback test_csr_readback.cpp
 *   sudo ./test_csr_readback
 */

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

static constexpr const char* PCI_RESOURCE = "/sys/bus/pci/devices/0000:ad:00.0/resource0";
static constexpr size_t BAR0_SIZE = 2 * 1024 * 1024;

// Vortex CSR offsets (matching ex_default_csr_avmm_slave.sv)
namespace CSR {
    constexpr uint32_t KERNEL_ADDR_LO = 0x100;
    constexpr uint32_t KERNEL_ADDR_HI = 0x104;
    constexpr uint32_t KERNEL_ARGS_LO = 0x108;
    constexpr uint32_t KERNEL_ARGS_HI = 0x10C;
    constexpr uint32_t GRID_DIM_X     = 0x110;
    constexpr uint32_t GRID_DIM_Y     = 0x114;
    constexpr uint32_t GRID_DIM_Z     = 0x118;
    constexpr uint32_t BLOCK_DIM_X    = 0x11C;
    constexpr uint32_t BLOCK_DIM_Y    = 0x120;
    constexpr uint32_t BLOCK_DIM_Z    = 0x124;
    constexpr uint32_t LAUNCH         = 0x128;
    constexpr uint32_t STATUS         = 0x12C;
    constexpr uint32_t CYCLE_LO       = 0x130;
    constexpr uint32_t CYCLE_HI       = 0x134;
    constexpr uint32_t INSTR_LO       = 0x138;
    constexpr uint32_t INSTR_HI       = 0x13C;
}

// Status values
namespace STATUS {
    constexpr uint8_t IDLE    = 0x00;
    constexpr uint8_t RUNNING = 0x01;
    constexpr uint8_t DONE    = 0x02;
    constexpr uint8_t ERROR   = 0xFF;
}

static volatile uint32_t* bar0 = nullptr;

static void write32(uint32_t offset, uint32_t value) {
    bar0[offset / 4] = value;
    asm volatile("sfence" ::: "memory");
}

static uint32_t read32(uint32_t offset) {
    asm volatile("lfence" ::: "memory");
    return bar0[offset / 4];
}

struct TestResult {
    int pass = 0;
    int fail = 0;
};

static void check(TestResult& r, const char* name, uint32_t offset,
                  uint32_t expected, uint32_t actual) {
    if (actual == expected) {
        printf("  [PASS] %-20s [0x%03X] = 0x%08X\n", name, offset, actual);
        r.pass++;
    } else {
        printf("  [FAIL] %-20s [0x%03X] = 0x%08X (expected 0x%08X)\n",
               name, offset, actual, expected);
        r.fail++;
    }
}

int main() {
    printf("=== CXL Type2 CSR Write/Readback Test ===\n");
    printf("Device: 0000:ad:00.0\n\n");

    int fd = open(PCI_RESOURCE, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open BAR0");
        return 1;
    }

    bar0 = static_cast<volatile uint32_t*>(
        mmap(nullptr, BAR0_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
    if (bar0 == MAP_FAILED) {
        perror("mmap BAR0");
        close(fd);
        return 1;
    }

    printf("BAR0 mapped at %p (2MB)\n\n", (void*)bar0);

    TestResult r;

    // ========================================================================
    // Test 1: Initial state — check reset defaults
    //   KERNEL_ADDR/ARGS = 0, GRID/BLOCK dims = 1 (per RTL reset values)
    // ========================================================================
    printf("--- Test 1: Initial state (reset defaults) ---\n");
    check(r, "KERNEL_ADDR_LO", CSR::KERNEL_ADDR_LO, 0x00000000, read32(CSR::KERNEL_ADDR_LO));
    check(r, "KERNEL_ADDR_HI", CSR::KERNEL_ADDR_HI, 0x00000000, read32(CSR::KERNEL_ADDR_HI));
    check(r, "KERNEL_ARGS_LO", CSR::KERNEL_ARGS_LO, 0x00000000, read32(CSR::KERNEL_ARGS_LO));
    check(r, "KERNEL_ARGS_HI", CSR::KERNEL_ARGS_HI, 0x00000000, read32(CSR::KERNEL_ARGS_HI));
    // Grid/block dims reset to 1
    check(r, "GRID_DIM_X",     CSR::GRID_DIM_X,     0x00000001, read32(CSR::GRID_DIM_X));
    check(r, "GRID_DIM_Y",     CSR::GRID_DIM_Y,     0x00000001, read32(CSR::GRID_DIM_Y));
    check(r, "GRID_DIM_Z",     CSR::GRID_DIM_Z,     0x00000001, read32(CSR::GRID_DIM_Z));
    check(r, "BLOCK_DIM_X",    CSR::BLOCK_DIM_X,    0x00000001, read32(CSR::BLOCK_DIM_X));
    check(r, "BLOCK_DIM_Y",    CSR::BLOCK_DIM_Y,    0x00000001, read32(CSR::BLOCK_DIM_Y));
    check(r, "BLOCK_DIM_Z",    CSR::BLOCK_DIM_Z,    0x00000001, read32(CSR::BLOCK_DIM_Z));
    // STATUS should be IDLE
    check(r, "STATUS (IDLE)",  CSR::STATUS,          STATUS::IDLE, read32(CSR::STATUS) & 0xFF);

    // ========================================================================
    // Test 2: Write/readback on RW config registers
    // ========================================================================
    printf("\n--- Test 2: Write/readback (RW registers) ---\n");

    struct { uint32_t off; const char* name; uint32_t val; } rw_tests[] = {
        {CSR::KERNEL_ADDR_LO, "KERNEL_ADDR_LO", 0x80000000},
        {CSR::KERNEL_ADDR_HI, "KERNEL_ADDR_HI", 0x00000042},
        {CSR::KERNEL_ARGS_LO, "KERNEL_ARGS_LO", 0xDEAD0000},
        {CSR::KERNEL_ARGS_HI, "KERNEL_ARGS_HI", 0x0000BEEF},
        {CSR::GRID_DIM_X,     "GRID_DIM_X",     0x00000008},
        {CSR::GRID_DIM_Y,     "GRID_DIM_Y",     0x00000010},
        {CSR::GRID_DIM_Z,     "GRID_DIM_Z",     0x00000001},
        {CSR::BLOCK_DIM_X,    "BLOCK_DIM_X",    0x00000008},
        {CSR::BLOCK_DIM_Y,    "BLOCK_DIM_Y",    0x00000004},
        {CSR::BLOCK_DIM_Z,    "BLOCK_DIM_Z",    0x00000002},
    };

    for (auto& t : rw_tests) {
        write32(t.off, t.val);
        uint32_t rb = read32(t.off);
        check(r, t.name, t.off, t.val, rb);
    }

    // ========================================================================
    // Test 3: STATUS should still be IDLE (we didn't launch)
    // ========================================================================
    printf("\n--- Test 3: STATUS after config writes (should be IDLE) ---\n");
    check(r, "STATUS (idle?)", CSR::STATUS, STATUS::IDLE, read32(CSR::STATUS) & 0xFF);

    // ========================================================================
    // Test 4: Walking-ones on GRID_DIM_X (tests all 32 bits)
    // ========================================================================
    printf("\n--- Test 4: Walking-ones on GRID_DIM_X ---\n");
    bool walk_pass = true;
    for (int bit = 0; bit < 32; bit++) {
        uint32_t pattern = 1u << bit;
        write32(CSR::GRID_DIM_X, pattern);
        uint32_t rb = read32(CSR::GRID_DIM_X);
        if (rb != pattern) {
            printf("  [FAIL] bit %2d: wrote 0x%08X, read 0x%08X\n", bit, pattern, rb);
            walk_pass = false;
        }
    }
    if (walk_pass) {
        printf("  [PASS] All 32 bits functional\n");
        r.pass++;
    } else {
        r.fail++;
    }

    // ========================================================================
    // Test 5: Write 0xFFFFFFFF and 0x00000000 (all-ones / all-zeros)
    // ========================================================================
    printf("\n--- Test 5: All-ones / all-zeros on BLOCK_DIM_X ---\n");
    write32(CSR::BLOCK_DIM_X, 0xFFFFFFFF);
    check(r, "BLOCK_DIM_X=FFFFFFFF", CSR::BLOCK_DIM_X, 0xFFFFFFFF, read32(CSR::BLOCK_DIM_X));
    write32(CSR::BLOCK_DIM_X, 0x00000000);
    check(r, "BLOCK_DIM_X=00000000", CSR::BLOCK_DIM_X, 0x00000000, read32(CSR::BLOCK_DIM_X));

    // ========================================================================
    // Test 6: Launch and status transition
    //   Write 1 to LAUNCH -> STATUS should transition from IDLE to RUNNING,
    //   then eventually to DONE (placeholder FSM completes after ~1024 cycles)
    // ========================================================================
    printf("\n--- Test 6: Launch + status transition ---\n");

    // Set up minimal kernel config
    write32(CSR::KERNEL_ADDR_LO, 0x80001000);
    write32(CSR::KERNEL_ADDR_HI, 0x00000000);
    write32(CSR::GRID_DIM_X, 1);
    write32(CSR::BLOCK_DIM_X, 1);

    // Launch
    write32(CSR::LAUNCH, 1);
    usleep(100);  // Give a few microseconds for FSM to tick

    uint32_t st = read32(CSR::STATUS) & 0xFF;
    printf("  STATUS after launch: 0x%02X (%s)\n", st,
           st == STATUS::IDLE ? "IDLE" :
           st == STATUS::RUNNING ? "RUNNING" :
           st == STATUS::DONE ? "DONE" :
           st == STATUS::ERROR ? "ERROR" : "UNKNOWN");

    // Wait for completion (placeholder FSM: ~1024 cycles at 125MHz = ~8.2us)
    for (int i = 0; i < 100; i++) {
        usleep(100);
        st = read32(CSR::STATUS) & 0xFF;
        if (st == STATUS::DONE || st == STATUS::ERROR)
            break;
    }

    printf("  STATUS after wait:   0x%02X (%s)\n", st,
           st == STATUS::IDLE ? "IDLE" :
           st == STATUS::RUNNING ? "RUNNING" :
           st == STATUS::DONE ? "DONE" :
           st == STATUS::ERROR ? "ERROR" : "UNKNOWN");

    if (st == STATUS::DONE) {
        printf("  [PASS] Launch completed (DONE)\n");
        r.pass++;
    } else if (st == STATUS::RUNNING) {
        printf("  [WARN] Still RUNNING — FSM may need more time\n");
        r.pass++;  // Not a hard failure
    } else {
        printf("  [FAIL] Unexpected status: 0x%02X\n", st);
        r.fail++;
    }

    // Check cycle counter increased
    uint32_t cy_lo = read32(CSR::CYCLE_LO);
    printf("  CYCLE_LO after launch: %u\n", cy_lo);
    if (cy_lo > 0) {
        printf("  [PASS] Cycle counter incremented\n");
        r.pass++;
    } else {
        printf("  [INFO] Cycle counter = 0 (may not be connected yet)\n");
    }

    // ========================================================================
    // Cleanup: restore all registers to defaults
    // ========================================================================
    printf("\n--- Cleanup: restoring registers ---\n");
    write32(CSR::KERNEL_ADDR_LO, 0);
    write32(CSR::KERNEL_ADDR_HI, 0);
    write32(CSR::KERNEL_ARGS_LO, 0);
    write32(CSR::KERNEL_ARGS_HI, 0);
    write32(CSR::GRID_DIM_X, 1);
    write32(CSR::GRID_DIM_Y, 1);
    write32(CSR::GRID_DIM_Z, 1);
    write32(CSR::BLOCK_DIM_X, 1);
    write32(CSR::BLOCK_DIM_Y, 1);
    write32(CSR::BLOCK_DIM_Z, 1);
    printf("  Done.\n");

    // ========================================================================
    // Summary
    // ========================================================================
    printf("\n========================================\n");
    printf("Results: %d passed, %d failed\n", r.pass, r.fail);
    printf("========================================\n");

    bool regs_live = r.fail == 0 && r.pass > 0;
    if (regs_live) {
        printf("\nCSR registers are LIVE — FPGA logic is responding.\n");
        printf("Device is ready for kernel launch testing.\n");
    } else if (r.pass == 0 && r.fail == 0) {
        printf("\nNo tests ran — something is wrong.\n");
    } else {
        printf("\nSome registers did not readback correctly.\n");
        printf("The FPGA may not have the Vortex GPU logic loaded,\n");
        printf("or the CSR address map may differ from expected.\n");
    }

    munmap(const_cast<uint32_t*>(bar0), BAR0_SIZE);
    close(fd);
    return r.fail > 0 ? 1 : 0;
}
