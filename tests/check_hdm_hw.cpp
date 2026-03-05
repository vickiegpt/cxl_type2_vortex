#include <cstdint>
#include <cstdio>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <csetjmp>
#include <csignal>

static sigjmp_buf jmpbuf;
static volatile sig_atomic_t in_probe = 0;
static void fault_handler(int sig) {
    if (in_probe) siglongjmp(jmpbuf, sig);
    _exit(128 + sig);
}

static bool safe_rd32(volatile uint32_t* base, uint32_t off, uint32_t* out) {
    in_probe = 1;
    if (sigsetjmp(jmpbuf, 1) != 0) { in_probe = 0; return false; }
    asm volatile("lfence" ::: "memory");
    *out = base[off / 4];
    asm volatile("lfence" ::: "memory");
    in_probe = 0;
    return true;
}

int main() {
    struct sigaction sa{};
    sa.sa_handler = fault_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGBUS, &sa, nullptr);
    sigaction(SIGSEGV, &sa, nullptr);

    int fd = open("/sys/bus/pci/devices/0000:3b:00.0/resource0", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open BAR0"); return 1; }
    auto* bar0 = static_cast<volatile uint32_t*>(
        mmap(nullptr, 2*1024*1024, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0));
    close(fd);
    if (bar0 == MAP_FAILED) { perror("mmap"); return 1; }

    // Component register base at BAR0+0x150000
    // CXL CM header at +0x1000
    uint32_t comp_base = 0x150000;
    uint32_t cm_base = comp_base + 0x1000;

    printf("=== HDM Decoder HW Register Check ===\n\n");

    // Read capability array header
    uint32_t v;
    safe_rd32(bar0, cm_base, &v);
    printf("CXL CM Cap Header [0x%06X]: 0x%08X\n", cm_base, v);
    printf("  Cap ID: %d, Array Size: %d\n", v & 0xFFFF, (v >> 16) & 0xFFFF);

    // Read cap entries to find HDM
    int array_size = (v >> 16) & 0xFFFF;
    for (int i = 1; i <= array_size && i <= 16; i++) {
        safe_rd32(bar0, cm_base + i * 4, &v);
        int cap_id = v & 0xFFFF;
        int ptr = (v >> 16) & 0xFFFF;
        printf("  Cap[%d]: ID=%d, Ptr=0x%04X\n", i, cap_id, ptr);

        if (cap_id == 1) { // HDM Decoder
            printf("\n--- HDM Decoder Registers (at comp_base+0x1000+0x%04X) ---\n", ptr);
            uint32_t hdm_base = cm_base + ptr;

            // CXL_HDM_DECODER_CAP (offset 0x00)
            safe_rd32(bar0, hdm_base + 0x00, &v);
            printf("  HDM_DECODER_CAP  [+0x00]: 0x%08X\n", v);
            printf("    DecoderCount: %d, TargetCount: %d\n",
                   (v & 0xF) ? 1 << ((v & 0xF) - 1) : 0, (v >> 4) & 0xF);

            // CXL_HDM_DECODER_CTRL (offset 0x04) — global ctrl
            safe_rd32(bar0, hdm_base + 0x04, &v);
            printf("  HDM_GLOBAL_CTRL  [+0x04]: 0x%08X\n", v);
            printf("    Global Enable: %d, Poison on UR: %d\n",
                   v & 1, (v >> 1) & 1);

            // Decoder 0 registers
            // Base Low (0x10), Base High (0x14), Size Low (0x18), Size High (0x1C)
            // Ctrl (0x20), Target List Low (0x24)
            uint32_t d0_base_lo, d0_base_hi, d0_size_lo, d0_size_hi, d0_ctrl, d0_tgt;
            safe_rd32(bar0, hdm_base + 0x10, &d0_base_lo);
            safe_rd32(bar0, hdm_base + 0x14, &d0_base_hi);
            safe_rd32(bar0, hdm_base + 0x18, &d0_size_lo);
            safe_rd32(bar0, hdm_base + 0x1C, &d0_size_hi);
            safe_rd32(bar0, hdm_base + 0x20, &d0_ctrl);
            safe_rd32(bar0, hdm_base + 0x24, &d0_tgt);

            printf("\n  Decoder0:\n");
            printf("    Base:    0x%08X_%08X\n", d0_base_hi, d0_base_lo);
            printf("    Size:    0x%08X_%08X\n", d0_size_hi, d0_size_lo);
            printf("    Ctrl:    0x%08X\n", d0_ctrl);
            printf("      Committed: %d, Enable: %d, Lock: %d, HostOnly: %d\n",
                   (d0_ctrl >> 9) & 1, // COMMITTED bit
                   (d0_ctrl >> 10) & 1, // ENABLE bit (some impls)
                   (d0_ctrl >> 8) & 1,  // LOCK
                   (d0_ctrl >> 4) & 1); // HOSTONLY
            printf("    Targets: 0x%08X\n", d0_tgt);
        }
    }

    // Also check DVSEC memory range status
    printf("\n=== DVSEC Range Status (via config mirror) ===\n");
    uint32_t dvsec_base = 0x0E0000 + 0xF00; // DVSEC offset
    // Range1 Size Low (0xF18)
    safe_rd32(bar0, dvsec_base + 0x18, &v);
    printf("Range1 Size Low  [0x%06X]: 0x%08X (Active=%d, Valid=%d)\n",
           dvsec_base+0x18, v, (v>>1)&1, v&1);
    safe_rd32(bar0, dvsec_base + 0x1C, &v);
    printf("Range1 Size High [0x%06X]: 0x%08X\n", dvsec_base+0x1C, v);
    safe_rd32(bar0, dvsec_base + 0x20, &v);
    printf("Range1 Base Low  [0x%06X]: 0x%08X\n", dvsec_base+0x20, v);
    safe_rd32(bar0, dvsec_base + 0x24, &v);
    printf("Range1 Base High [0x%06X]: 0x%08X\n", dvsec_base+0x24, v);

    munmap(const_cast<uint32_t*>(bar0), 2*1024*1024);
    return 0;
}
