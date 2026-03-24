/**
 * probe_gpu_csr.cpp - Comprehensive GPU CSR probing without recompilation
 * Tests to understand the current RTL behavior and identify the root cause
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <chrono>

static constexpr size_t BAR0_SIZE = 0x200000;
static volatile uint32_t *bar;

static uint32_t rd32(uint32_t off) { return bar[off / 4]; }
static void wr32(uint32_t off, uint32_t v) { bar[off / 4] = v; }

int main() {
    printf("=== GPU CSR Comprehensive Diagnostic ===\n\n");

    int fd = open("/sys/bus/pci/devices/0000:3b:00.0/resource0", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open BAR0"); return 1; }
    bar = (volatile uint32_t *)mmap(NULL, BAR0_SIZE, PROT_READ | PROT_WRITE,
                                     MAP_SHARED, fd, 0);
    if (bar == MAP_FAILED) { perror("mmap"); close(fd); return 1; }

    // Test 1: Baseline - read known-working address
    printf("[Test 1] Baseline - Known Working Address\n");
    uint32_t cxl_cap = rd32(0x151000);
    printf("  CXL CM Cap (0x151000): 0x%08x\n", cxl_cap);
    if (cxl_cap != 0x03110001) {
        printf("  ERROR: Baseline failed! Something's wrong with BAR0 access.\n");
        return 1;
    }
    printf("  PASS: BAR0 MMIO working\n\n");

    // Test 2: GPU CSR range sweep - find if ANY address responds
    printf("[Test 2] GPU CSR Range Sweep (0x080000-0x081000)\n");
    printf("  Looking for ANY non-zero reads...\n");
    bool found_any = false;
    for (uint32_t off = 0x080000; off < 0x081000; off += 4) {
        uint32_t val = rd32(off);
        if (val != 0) {
            printf("    0x%06x: 0x%08x ← NON-ZERO FOUND!\n", off, val);
            found_any = true;
        }
    }
    if (!found_any) {
        printf("  Result: All zeros in entire GPU CSR range (0x080000-0x081000)\n");
        printf("  Hypothesis: Address decode failing OR GPU wrapper not responding\n\n");
    }

    // Test 3: Write-readback pattern test
    printf("[Test 3] Write Pattern Tests\n");
    struct {
        uint32_t off;
        uint32_t val;
        const char *name;
    } patterns[] = {
        {0x080110, 0xAAAAAAAA, "AAAA pattern"},
        {0x080110, 0x55555555, "5555 pattern"},
        {0x080110, 0xDEADBEEF, "DEADBEEF"},
        {0x080110, 0x00000001, "Single bit"},
        {0x080114, 0x12345678, "Different offset"},
    };

    for (auto &p : patterns) {
        wr32(p.off, p.val);
        usleep(10000);  // 10ms delay for potential CDC
        uint32_t rb = rd32(p.off);
        printf("  Offset 0x%06x (%s): wrote 0x%08x, read 0x%08x %s\n",
               p.off, p.name, p.val, rb, (rb == p.val) ? "✓" : "✗");
    }
    printf("\n");

    // Test 4: Multiple reads to same address
    printf("[Test 4] Multiple Consecutive Reads (Same Address)\n");
    uint32_t test_addr = 0x080110;
    wr32(test_addr, 0x12345678);
    usleep(10000);

    printf("  Writing 0x12345678 to 0x%06x\n", test_addr);
    printf("  Five consecutive reads:\n");
    for (int i = 0; i < 5; i++) {
        uint32_t val = rd32(test_addr);
        printf("    Read %d: 0x%08x\n", i+1, val);
        usleep(1000);
    }
    printf("\n");

    // Test 5: CXL register read-modify-write (sanity check that writes work)
    printf("[Test 5] CXL Register Write Test (Sanity Check)\n");
    uint32_t cxl_addr = 0x150004;  // Some CXL config offset
    uint32_t before = rd32(cxl_addr);
    printf("  CXL reg 0x%06x before: 0x%08x\n", cxl_addr, before);

    // Try to write (may or may not work depending on register)
    wr32(cxl_addr, 0x11111111);
    usleep(10000);
    uint32_t after = rd32(cxl_addr);
    printf("  After write of 0x11111111: 0x%08x\n", after);
    if (before != after) {
        printf("  INFO: Some CXL registers ARE writable\n");
    } else {
        printf("  INFO: Register not writable (read-only or write-protected)\n");
    }
    printf("\n");

    // Test 6: Address space probing - test different address ranges
    printf("[Test 6] Address Range Probing\n");
    struct {
        uint32_t off;
        const char *name;
    } ranges[] = {
        {0x000000, "CAFU CSR base"},
        {0x010000, "0x010000"},
        {0x080000, "GPU CSR base"},
        {0x080110, "GPU GRID_DIM_X"},
        {0x08FF00, "GPU CSR end"},
        {0x100000, "Middle of BAR0"},
        {0x150000, "CXL Comp Reg"},
        {0x151000, "CXL CM Cap"},
        {0x180000, "CXL Device Reg"},
        {0x1F0000, "Near BAR0 end"},
    };

    printf("  Range\t\tName\t\t\tRead Value\n");
    printf("  ------\t------\t\t\t----------\n");
    for (auto &r : ranges) {
        uint32_t val = rd32(r.off);
        printf("  0x%06x\t%-20s\t0x%08x\n", r.off, r.name, val);
    }
    printf("\n");

    // Test 7: Timing analysis - check if delayed reads work
    printf("[Test 7] Timing Analysis - Delayed Reads\n");
    printf("  Writing 0xTESTVAL to 0x080110...\n");
    wr32(0x080110, 0x11223344);

    uint32_t delays[] = {100, 1000, 10000, 100000};  // us
    for (auto delay_us : delays) {
        usleep(delay_us);
        uint32_t val = rd32(0x080110);
        printf("    After %6u us delay: 0x%08x\n", delay_us, val);
    }
    printf("\n");

    // Test 8: Summary and hypothesis
    printf("[Test 8] Diagnosis Summary\n");
    bool gpu_responds = false;

    // Re-test GPU CSR responsiveness
    wr32(0x080110, 0xDEADBEEF);
    usleep(100000);
    if (rd32(0x080110) == 0xDEADBEEF) {
        gpu_responds = true;
    }

    if (gpu_responds) {
        printf("  ✓ GPU CSR IS responding to writes!\n");
        printf("  Next steps: Check write timing, register encoding, etc.\n");
    } else {
        printf("  ✗ GPU CSR NOT responding (all zeros)\n");
        printf("  Root cause likely one of:\n");
        printf("    1. Address decode failing (pio_gpu_hit never asserted)\n");
        printf("    2. CSR handshake broken (csr_valid never asserted)\n");
        printf("    3. GPU wrapper not instantiated/synthesized\n");
        printf("    4. Clock/reset to GPU CSR not working\n");
    }

    munmap((void *)bar, BAR0_SIZE);
    close(fd);
    return 0;
}
