/**
 * debug_bar0.cpp - Probe BAR0 to find which registers respond
 * Tests various BAR0 offsets to understand PIO bridge routing
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

static constexpr size_t BAR0_SIZE = 0x200000;  // 2MB

static volatile uint32_t *bar;

static uint32_t rd32(uint32_t off) { return bar[off / 4]; }
static void     wr32(uint32_t off, uint32_t v) { bar[off / 4] = v; }

int main() {
    printf("=== BAR0 Debug Probe ===\n");

    int fd = open("/sys/bus/pci/devices/0000:3b:00.0/resource0", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open BAR0"); return 1; }
    bar = (volatile uint32_t *)mmap(NULL, BAR0_SIZE, PROT_READ | PROT_WRITE,
                                     MAP_SHARED, fd, 0);
    if (bar == MAP_FAILED) { perror("mmap"); close(fd); return 1; }

    // Test 1: CXL CM Cap (known working)
    printf("\n[Test 1] CXL CM Cap @ 0x151000 (known working)\n");
    uint32_t cm = rd32(0x151000);
    printf("  Read: 0x%08x\n", cm);

    // Test 2: Probe GPU CSR base and nearby areas
    printf("\n[Test 2] GPU CSR area (0x080000-0x080200)\n");
    for (uint32_t off = 0x080000; off <= 0x080200; off += 0x100) {
        uint32_t val = rd32(off);
        printf("  BAR0+0x%06x: 0x%08x\n", off, val);
    }

    // Test 3: Try write to GPU CSR GRID_DIM_X (0x080110)
    printf("\n[Test 3] Write-readback to BAR0+0x080110 (GPU GRID_DIM_X)\n");
    printf("  Writing 0xDEADBEEF...\n");
    wr32(0x080110, 0xDEADBEEF);
    usleep(100000);  // Wait 100ms
    uint32_t rb = rd32(0x080110);
    printf("  Readback: 0x%08x (expect 0xDEADBEEF if writable)\n", rb);

    // Test 4: Probe other potential CSR areas
    printf("\n[Test 4] Probe other BAR0 ranges\n");
    struct {
        uint32_t off;
        const char *desc;
    } probes[] = {
        {0x000000, "CAFU CSR base"},
        {0x001000, "CAFU CSR +0x1000"},
        {0x010000, "Unknown +0x10000"},
        {0x040000, "Unknown +0x40000"},
        {0x050000, "Unknown +0x50000"},
        {0x150000, "CXL Comp Regs"},
        {0x151000, "CXL CM Cap"},
        {0x180000, "CXL Device Regs"},
        {0x0A0000, "Unknown +0xA0000"},
    };
    for (auto &p : probes) {
        uint32_t val = rd32(p.off);
        printf("  0x%06x (%s): 0x%08x\n", p.off, p.desc, val);
    }

    // Test 5: Check for any non-zero values in GPU area
    printf("\n[Test 5] Scan GPU area for non-zero reads\n");
    bool found_nonzero = false;
    for (uint32_t off = 0x080000; off < 0x081000; off += 4) {
        uint32_t val = rd32(off);
        if (val != 0) {
            printf("  BAR0+0x%06x: 0x%08x ← NON-ZERO\n", off, val);
            found_nonzero = true;
        }
    }
    if (!found_nonzero) {
        printf("  (all zeros in 0x080000-0x081000)\n");
    }

    munmap((void *)bar, BAR0_SIZE);
    close(fd);
    return 0;
}
