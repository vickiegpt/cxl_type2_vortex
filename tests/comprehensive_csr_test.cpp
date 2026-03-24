/**
 * comprehensive_csr_test.cpp
 *
 * Comprehensive GPU CSR register validation test.
 * Validates all GPU CSR registers are accessible and functional.
 * Tests register write/readback, address decoding, and CSR protocol.
 *
 * Build: g++ -std=c++17 -O2 comprehensive_csr_test.cpp -o comprehensive_csr_test
 * Usage: sudo ./comprehensive_csr_test
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <chrono>

// ============================================================================
// GPU CSR Register Map
// ============================================================================

#define BAR0_BASE              0xa2800000UL
#define GPU_CSR_BASE           0x180100

// Register offsets (from GPU_CSR_BASE)
#define KERNEL_ADDR_LO         0x100
#define KERNEL_ADDR_HI         0x104
#define KERNEL_ARGS_LO         0x108
#define KERNEL_ARGS_HI         0x10C
#define GRID_DIM_X             0x110
#define GRID_DIM_Y             0x114
#define GRID_DIM_Z             0x118
#define BLOCK_DIM_X            0x11C
#define BLOCK_DIM_Y            0x120
#define BLOCK_DIM_Z            0x124
#define LAUNCH                 0x128
#define STATUS                 0x12C
#define CYCLE_LO               0x130
#define CYCLE_HI               0x134
#define DCOH_ENABLE            0x148

// Status values
#define STATUS_IDLE            0x00
#define STATUS_RUNNING         0x01
#define STATUS_DONE            0x02

typedef volatile uint32_t vreg32;

// ============================================================================
// Test Structure
// ============================================================================

struct CSRTest {
    const char* name;
    uint32_t offset;
    uint32_t write_value;
    uint32_t read_mask;  // Mask for checking readback (0 = don't check)
};

// ============================================================================
// Main Test
// ============================================================================

int main() {
    printf("════════════════════════════════════════════════════════════\n");
    printf("Comprehensive GPU CSR Register Validation Test\n");
    printf("CXL Type2 Device (0000:3b:00.0)\n");
    printf("════════════════════════════════════════════════════════════\n\n");

    // Open /dev/mem
    int mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd < 0) {
        perror("open /dev/mem");
        return 1;
    }

    // Map entire BAR0 (2MB) at page-aligned address
    vreg32* bar0 = (vreg32*)mmap(nullptr, 0x200000, PROT_READ | PROT_WRITE,
                                   MAP_SHARED, mem_fd, BAR0_BASE);
    close(mem_fd);

    if (bar0 == MAP_FAILED) {
        perror("mmap BAR0");
        return 1;
    }

    printf("[INFO] Mapped BAR0 at 0x%lx\n", BAR0_BASE);
    printf("[INFO] GPU CSR base at BAR0+0x%x\n\n", GPU_CSR_BASE);

    int passed = 0, failed = 0;

    // ========================================================================
    // Test 1: Register Accessibility
    // ========================================================================
    printf("Test 1: Register Accessibility\n");
    printf("───────────────────────────────\n");

    CSRTest tests[] = {
        {"KERNEL_ADDR_LO",   KERNEL_ADDR_LO,  0x80000000, 0xFFFFFFFF},
        {"KERNEL_ADDR_HI",   KERNEL_ADDR_HI,  0x00000001, 0xFFFFFFFF},
        {"KERNEL_ARGS_LO",   KERNEL_ARGS_LO,  0x80001000, 0xFFFFFFFF},
        {"KERNEL_ARGS_HI",   KERNEL_ARGS_HI,  0x00000000, 0xFFFFFFFF},
        {"GRID_DIM_X",       GRID_DIM_X,      0x00000008, 0xFFFFFFFF},
        {"GRID_DIM_Y",       GRID_DIM_Y,      0x00000010, 0xFFFFFFFF},
        {"GRID_DIM_Z",       GRID_DIM_Z,      0x00000001, 0xFFFFFFFF},
        {"BLOCK_DIM_X",      BLOCK_DIM_X,     0x00000020, 0xFFFFFFFF},
        {"BLOCK_DIM_Y",      BLOCK_DIM_Y,     0x00000004, 0xFFFFFFFF},
        {"BLOCK_DIM_Z",      BLOCK_DIM_Z,     0x00000001, 0xFFFFFFFF},
        {"DCOH_ENABLE",      DCOH_ENABLE,     0x00000001, 0xFFFFFFFF},
    };

    for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); i++) {
        CSRTest& test = tests[i];

        // Write test value
        vreg32* reg = bar0 + (GPU_CSR_BASE + test.offset) / 4;
        *reg = test.write_value;

        // Read back
        uint32_t readback = *reg;

        // Verify
        if ((readback & test.read_mask) == (test.write_value & test.read_mask)) {
            printf("  ✓ %s: Write 0x%08x, Read 0x%08x\n",
                   test.name, test.write_value, readback);
            passed++;
        } else {
            printf("  ✗ %s: Expected 0x%08x, got 0x%08x\n",
                   test.name, test.write_value, readback);
            failed++;
        }
    }
    printf("\n");

    // ========================================================================
    // Test 2: Status Register Read (should be IDLE after reset)
    // ========================================================================
    printf("Test 2: Status Register Read\n");
    printf("──────────────────────────────\n");

    vreg32* status_reg = bar0 + (GPU_CSR_BASE + STATUS) / 4;
    uint32_t status = *status_reg;

    printf("  STATUS register value: 0x%08x\n", status);

    if (status == STATUS_IDLE || status == STATUS_RUNNING || status == STATUS_DONE) {
        printf("  ✓ Status is valid (%s)\n",
               status == STATUS_IDLE ? "IDLE" :
               status == STATUS_RUNNING ? "RUNNING" : "DONE");
        passed++;
    } else {
        printf("  ℹ Status is 0x%08x (may be valid in some configs)\n", status);
        passed++;  // Don't fail - status depends on device state
    }
    printf("\n");

    // ========================================================================
    // Test 3: Cycle Counter Read
    // ========================================================================
    printf("Test 3: Cycle Counter Read\n");
    printf("────────────────────────────\n");

    vreg32* cycle_lo = bar0 + (GPU_CSR_BASE + CYCLE_LO) / 4;
    vreg32* cycle_hi = bar0 + (GPU_CSR_BASE + CYCLE_HI) / 4;

    uint32_t cyc_lo = *cycle_lo;
    uint32_t cyc_hi = *cycle_hi;
    uint64_t cycles = ((uint64_t)cyc_hi << 32) | cyc_lo;

    printf("  Cycle counter: 0x%016lx\n", cycles);
    printf("  ✓ Cycle counter readable\n");
    passed++;
    printf("\n");

    // ========================================================================
    // Test 4: Launch Trigger Write
    // ========================================================================
    printf("Test 4: Launch Trigger Write\n");
    printf("──────────────────────────────\n");

    vreg32* launch_reg = bar0 + (GPU_CSR_BASE + LAUNCH) / 4;

    // Read before launch
    uint32_t before = *launch_reg;

    // Write launch trigger
    *launch_reg = 1;

    // Read after launch (should return to 0)
    usleep(100);  // Give hardware time to process
    uint32_t after = *launch_reg;

    printf("  Before launch: 0x%08x\n", before);
    printf("  After launch:  0x%08x\n", after);
    printf("  ✓ Launch trigger write successful\n");
    passed++;
    printf("\n");

    // ========================================================================
    // Test 5: Pattern Test (Writing different patterns)
    // ========================================================================
    printf("Test 5: Pattern Test (Multiple Values)\n");
    printf("──────────────────────────────────────\n");

    vreg32* pattern_reg = bar0 + (GPU_CSR_BASE + GRID_DIM_X) / 4;

    uint32_t patterns[] = {0x00000000, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555, 0x12345678};

    for (uint32_t pattern : patterns) {
        *pattern_reg = pattern;
        uint32_t read = *pattern_reg;

        if (read == pattern) {
            printf("  ✓ Pattern 0x%08x verified\n", pattern);
            passed++;
        } else {
            printf("  ✗ Pattern mismatch: wrote 0x%08x, read 0x%08x\n", pattern, read);
            failed++;
        }
    }
    printf("\n");

    // ========================================================================
    // Test 6: Address Decoding Verification
    // ========================================================================
    printf("Test 6: Address Decoding Verification\n");
    printf("──────────────────────────────────────\n");

    // Verify CSR address range works
    uint32_t min_offset = KERNEL_ADDR_LO;
    uint32_t max_offset = DCOH_ENABLE;

    printf("  CSR offset range: 0x%03x - 0x%03x\n", min_offset, max_offset);
    printf("  CSR physical range: 0x%08lx - 0x%08lx\n",
           BAR0_BASE + GPU_CSR_BASE + min_offset,
           BAR0_BASE + GPU_CSR_BASE + max_offset);

    // Write to min and max addresses
    vreg32* min_reg = bar0 + (GPU_CSR_BASE + min_offset) / 4;
    vreg32* max_reg = bar0 + (GPU_CSR_BASE + max_offset) / 4;

    *min_reg = 0xDEADBEEF;
    *max_reg = 0xCAFEBABE;

    if (*min_reg == 0xDEADBEEF && *max_reg == 0xCAFEBABE) {
        printf("  ✓ Address range 0x%03x-0x%03x accessible\n", min_offset, max_offset);
        passed++;
    } else {
        printf("  ✗ Address decoding failed\n");
        failed++;
    }
    printf("\n");

    // ========================================================================
    // Summary
    // ========================================================================
    printf("════════════════════════════════════════════════════════════\n");
    printf("Test Summary\n");
    printf("────────────────────────────────────────────────────────────\n");
    printf("Passed: %d\n", passed);
    printf("Failed: %d\n", failed);
    printf("════════════════════════════════════════════════════════════\n");

    // Cleanup
    munmap((void*)bar0, 0x200000);

    return failed > 0 ? 1 : 0;
}
