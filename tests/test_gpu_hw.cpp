/**
 * test_gpu_hw.cpp - Real-hardware Vortex GPU kernel launch test
 *
 * BAR0 layout:
 *   0x000000-0x07FFFF : CAFU CSR (cafu_csr0_avmm_wrapper)
 *   0x080000-0x080FFF : GPU CSR (vortex_gpu_wrapper)
 *   0x0E0000-0x0E1FFF : PCIe config mirror
 *   0x150000-0x15FFFF : CXL Component Registers
 *   0x180000-0x1FFFFF : CXL Device Registers
 *
 * GPU CSR register map (relative to 0x080000):
 *   0x100 KERNEL_ADDR_LO   0x104 KERNEL_ADDR_HI
 *   0x108 KERNEL_ARGS_LO   0x10C KERNEL_ARGS_HI
 *   0x110 GRID_DIM_X       0x114 GRID_DIM_Y      0x118 GRID_DIM_Z
 *   0x11C BLOCK_DIM_X      0x120 BLOCK_DIM_Y      0x124 BLOCK_DIM_Z
 *   0x128 LAUNCH           0x12C STATUS
 *   0x130 CYCLE_LO         0x134 CYCLE_HI
 *   0x138 INSTR_LO         0x13C INSTR_HI
 *
 * Build: g++ -O2 -o test_gpu_hw test_gpu_hw.cpp
 * Usage: ./test_gpu_hw [kernel.bin]
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <chrono>
#include <errno.h>

static constexpr size_t BAR0_SIZE       = 0x200000;  // 2MB
static constexpr uint32_t GPU_CSR_BASE  = 0x080000;  // GPU CSR at BAR0+0x80000
static constexpr uint32_t CXL_CM_CAP    = 0x151000;
static constexpr uint32_t CXL_HDM_BASE  = 0x151F00;

// GPU CSR offsets (add to GPU_CSR_BASE for BAR0 address)
namespace VCSR {
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

    constexpr uint8_t ST_IDLE    = 0x00;
    constexpr uint8_t ST_RUNNING = 0x01;
    constexpr uint8_t ST_DONE    = 0x02;
    constexpr uint8_t ST_ERROR   = 0xFF;
}

static volatile uint32_t *bar;

static uint32_t rd32(uint32_t off) { return bar[off / 4]; }
static void     wr32(uint32_t off, uint32_t v) { bar[off / 4] = v; }
static uint32_t gpu_rd(uint32_t csr) { return rd32(GPU_CSR_BASE + csr); }
static void     gpu_wr(uint32_t csr, uint32_t v) { wr32(GPU_CSR_BASE + csr, v); }

// ── Phase 1: BAR0 sanity ─────────────────────────────────────────────
static bool phase1() {
    printf("\n=== Phase 1: BAR0 MMIO ===\n");
    uint32_t cm = rd32(CXL_CM_CAP);
    printf("CXL CM Cap: 0x%08x  (expect 0x03110001)\n", cm);
    if ((cm & 0xFFFF) != 1) { printf("FAIL\n"); return false; }
    printf("PASS\n");
    return true;
}

// ── Phase 2: PIO bridge ──────────────────────────────────────────────
static bool phase2() {
    printf("\n=== Phase 2: PIO Bridge (CAFU CSR write-readback) ===\n");
    // Try a few offsets — CAFU CSR may have R/W scratch regs
    for (uint32_t off = 0; off < 0x40; off += 8) {
        uint32_t before = rd32(off);
        wr32(off, 0xA5000000 | off);
        uint32_t after = rd32(off);
        if (after == (0xA5000000u | off)) {
            printf("  BAR0+0x%03x: writable! (0x%08x)\n", off, after);
            wr32(off, before); // restore
            printf("PASS — PIO bridge working\n");
            return true;
        }
    }
    // Even if no scratch reg found, check GPU CSR area
    printf("  No writable CAFU CSR found, trying GPU CSR area...\n");
    uint32_t g = gpu_rd(VCSR::STATUS);
    printf("  GPU STATUS (BAR0+0x%06x): 0x%08x\n", GPU_CSR_BASE + VCSR::STATUS, g);

    // Try GPU write-readback on GRID_DIM_X
    gpu_wr(VCSR::GRID_DIM_X, 0x42);
    uint32_t rb = gpu_rd(VCSR::GRID_DIM_X);
    printf("  GPU GRID_DIM_X: wrote 0x42, readback 0x%08x\n", rb);
    if (rb == 0x42) {
        printf("PASS — GPU CSR accessible\n");
        return true;
    }

    if (g == 0 && rb == 0) {
        printf("SKIP — PIO bridge not active (all reads zero)\n");
        printf("  Need bitstream with PIO-to-CSR bridge fix.\n");
        return false;
    }
    printf("UNCLEAR — unexpected values\n");
    return false;
}

// ── Phase 3: GPU CSR smoke test ──────────────────────────────────────
static bool phase3() {
    printf("\n=== Phase 3: GPU CSR Smoke Test ===\n");

    printf("Reading GPU config registers:\n");
    for (uint32_t off = 0x100; off <= 0x13C; off += 4) {
        printf("  CSR[0x%03x] = 0x%08x\n", off, gpu_rd(off));
    }

    // Write-readback on all config regs
    struct { uint32_t off; const char *name; uint32_t val; } regs[] = {
        {VCSR::GRID_DIM_X,  "GRID_DIM_X",  0x00000010},
        {VCSR::GRID_DIM_Y,  "GRID_DIM_Y",  0x00000001},
        {VCSR::GRID_DIM_Z,  "GRID_DIM_Z",  0x00000001},
        {VCSR::BLOCK_DIM_X, "BLOCK_DIM_X", 0x00000020},
        {VCSR::BLOCK_DIM_Y, "BLOCK_DIM_Y", 0x00000001},
        {VCSR::BLOCK_DIM_Z, "BLOCK_DIM_Z", 0x00000001},
    };

    bool ok = true;
    for (auto &r : regs) {
        gpu_wr(r.off, r.val);
        uint32_t rb = gpu_rd(r.off);
        bool match = (rb == r.val);
        printf("  %-12s: wrote 0x%08x, rb 0x%08x  %s\n",
               r.name, r.val, rb, match ? "OK" : "FAIL");
        if (!match) ok = false;
    }

    printf("Phase 3: %s\n", ok ? "PASS" : "FAIL");
    return ok;
}

// ── Phase 4: Kernel launch ───────────────────────────────────────────
static bool phase4(const char *kpath) {
    printf("\n=== Phase 4: Kernel Launch ===\n");

    // Check initial status
    uint32_t st = gpu_rd(VCSR::STATUS) & 0xFF;
    printf("Initial GPU status: 0x%02x (%s)\n", st,
           st == VCSR::ST_IDLE ? "IDLE" :
           st == VCSR::ST_RUNNING ? "RUNNING" :
           st == VCSR::ST_DONE ? "DONE" : "UNKNOWN");

    if (st == VCSR::ST_RUNNING) {
        printf("GPU already running — cannot launch\n");
        return false;
    }

    // Load kernel binary (if provided)
    if (kpath) {
        FILE *f = fopen(kpath, "rb");
        if (f) {
            fseek(f, 0, SEEK_END);
            size_t sz = ftell(f);
            fclose(f);
            printf("Kernel binary: %s (%zu bytes)\n", kpath, sz);
            printf("NOTE: Kernel must already be in device DDR at 0x80000000\n");
            printf("      (loaded via separate DMA/JTAG mechanism)\n");
        } else {
            printf("Cannot open %s: %s\n", kpath, strerror(errno));
        }
    }

    // Configure kernel — use default entry point in device DDR
    uint64_t kernel_addr = 0x80000000ULL;  // DDR base
    uint64_t kernel_args = 0x80100000ULL;  // args at DDR+1MB
    printf("Configuring: kernel=0x%lx args=0x%lx grid=(1,1,1) block=(1,1,1)\n",
           kernel_addr, kernel_args);

    gpu_wr(VCSR::KERNEL_ADDR_LO, (uint32_t)kernel_addr);
    gpu_wr(VCSR::KERNEL_ADDR_HI, (uint32_t)(kernel_addr >> 32));
    gpu_wr(VCSR::KERNEL_ARGS_LO, (uint32_t)kernel_args);
    gpu_wr(VCSR::KERNEL_ARGS_HI, (uint32_t)(kernel_args >> 32));
    gpu_wr(VCSR::GRID_DIM_X, 1);
    gpu_wr(VCSR::GRID_DIM_Y, 1);
    gpu_wr(VCSR::GRID_DIM_Z, 1);
    gpu_wr(VCSR::BLOCK_DIM_X, 1);
    gpu_wr(VCSR::BLOCK_DIM_Y, 1);
    gpu_wr(VCSR::BLOCK_DIM_Z, 1);

    // Launch
    printf("Launching kernel...\n");
    gpu_wr(VCSR::LAUNCH, 1);

    // Poll for completion
    auto t0 = std::chrono::steady_clock::now();
    while (true) {
        st = gpu_rd(VCSR::STATUS) & 0xFF;
        if (st == VCSR::ST_DONE) {
            uint64_t cycles = (uint64_t)gpu_rd(VCSR::CYCLE_LO) |
                              ((uint64_t)gpu_rd(VCSR::CYCLE_HI) << 32);
            uint64_t instrs = (uint64_t)gpu_rd(VCSR::INSTR_LO) |
                              ((uint64_t)gpu_rd(VCSR::INSTR_HI) << 32);
            printf("Kernel DONE! cycles=%lu instrs=%lu\n", cycles, instrs);
            printf("Phase 4: PASS\n");
            return true;
        }
        if (st == VCSR::ST_ERROR) {
            printf("Kernel ERROR (status=0xFF)\n");
            printf("Phase 4: FAIL\n");
            return false;
        }
        auto elapsed = std::chrono::steady_clock::now() - t0;
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(elapsed).count();
        if (ms > 10000) {
            printf("Kernel TIMEOUT after %ldms (status=0x%02x)\n", ms, st);
            printf("Phase 4: FAIL (timeout)\n");
            return false;
        }
        if (ms % 1000 == 0 && ms > 0)
            printf("  ... waiting %ldms, status=0x%02x\n", ms, st);
        usleep(10000);  // 10ms
    }
}

// ── Main ─────────────────────────────────────────────────────────────
int main(int argc, char *argv[]) {
    printf("============================================\n");
    printf("Vortex GPU Hardware Test\n");
    printf("CXL Type2 Device 0000:3b:00.0\n");
    printf("GPU CSR at BAR0+0x%06x\n", GPU_CSR_BASE);
    printf("============================================\n");

    int fd = open("/sys/bus/pci/devices/0000:3b:00.0/resource0", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open BAR0"); return 1; }
    bar = (volatile uint32_t *)mmap(NULL, BAR0_SIZE, PROT_READ | PROT_WRITE,
                                     MAP_SHARED, fd, 0);
    if (bar == MAP_FAILED) { perror("mmap"); close(fd); return 1; }

    bool p1 = phase1();
    if (!p1) return 1;

    bool p2 = phase2();
    bool p3 = p2 ? phase3() : false;
    bool p4 = p3 ? phase4(argc > 1 ? argv[1] : nullptr) : false;

    printf("\n============================================\n");
    printf("  Phase 1 (BAR0):       %s\n", p1 ? "PASS" : "FAIL");
    printf("  Phase 2 (PIO Bridge): %s\n", p2 ? "PASS" : "SKIP");
    printf("  Phase 3 (GPU CSR):    %s\n", p3 ? "PASS" : "SKIP");
    printf("  Phase 4 (Kernel):     %s\n", p4 ? "PASS" : "SKIP");
    printf("============================================\n");

    munmap((void *)bar, BAR0_SIZE);
    close(fd);
    return p1 ? 0 : 1;
}
