#include <cstdint>
#include <cstdio>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <csetjmp>
#include <csignal>

static sigjmp_buf jmpbuf;
static volatile sig_atomic_t in_probe = 0;
static void fault_handler(int sig) { if (in_probe) siglongjmp(jmpbuf, sig); _exit(128+sig); }
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
    if (fd < 0) { perror("open"); return 1; }
    auto* bar0 = static_cast<volatile uint32_t*>(
        mmap(nullptr, 2*1024*1024, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0));
    close(fd);
    if (bar0 == MAP_FAILED) { perror("mmap"); return 1; }

    // Component registers at BAR0+0x150000, CXL CM at +0x1000
    uint32_t cm = 0x150000 + 0x1000;
    uint32_t v;

    printf("=== CXL CM Capability Array (correct parsing) ===\n");
    safe_rd32(bar0, cm, &v);
    printf("Cap Array Header [0x%06X]: 0x%08X\n", cm, v);
    int cap_id_hdr = v & 0xFFFF;
    int array_size = (v >> 24) & 0xFF;
    printf("  Header ID: %d (expect 1), Array Size: %d\n", cap_id_hdr, array_size);

    for (int i = 1; i <= array_size; i++) {
        safe_rd32(bar0, cm + i*4, &v);
        int id = v & 0xFFFF;
        int ptr = (v >> 20) & 0xFFF;  // GENMASK(31,20) = bits[31:20]
        printf("  Cap[%d]: raw=0x%08X ID=%d Ptr=0x%03X (byte offset from CM base)\n",
               i, v, id, ptr);

        if (id == 5) { // HDM Decoder
            printf("\n--- HDM Decoder (at CM + 0x%03X) ---\n", ptr);
            uint32_t hdm = cm + ptr;

            // Read all HDM decoder registers
            const char* names[] = {
                "HDM_CAP", "HDM_GLOBAL_CTRL",
                "HDM_RSVD_08", "HDM_RSVD_0C",
                "DEC0_BASE_LO", "DEC0_BASE_HI",
                "DEC0_SIZE_LO", "DEC0_SIZE_HI",
                "DEC0_CTRL", "DEC0_TGT_LO",
                "DEC0_TGT_HI", "DEC0_RSVD_2C",
                "DEC0_DPA_SKIP_LO", "DEC0_DPA_SKIP_HI"
            };

            for (int r = 0; r < 14; r++) {
                safe_rd32(bar0, hdm + r*4, &v);
                printf("  [+0x%02X] %-20s = 0x%08X", r*4, names[r], v);

                if (r == 0) { // HDM_CAP
                    int cnt = v & 0xF;
                    int dec_count = cnt ? (1 << (cnt-1)) : 0;
                    printf(" (DecoderCount=%d, TargetCount=%d)",
                           dec_count, (v>>4)&0xF);
                } else if (r == 1) { // GLOBAL_CTRL
                    printf(" (Enable=%d, PoisonOnUR=%d)", v&1, (v>>1)&1);
                } else if (r == 8) { // DEC0_CTRL
                    printf(" (Committed=%d, Lock=%d, HostOnly=%d, IW=%d, IG=%d)",
                           (v>>9)&1, (v>>8)&1, (v>>4)&1,
                           v & 0xF, (v>>4) & 0xF);
                }
                printf("\n");
            }
        }
    }

    // DVSEC Range via PCI config space
    printf("\n=== DVSEC Range1 Status ===\n");
    uint32_t dv = 0x0E0F00;
    safe_rd32(bar0, dv + 0x0C, &v);
    printf("CXLCtl [F0C]: 0x%08X (Mem=%d)\n", v, (v>>2)&1);
    safe_rd32(bar0, dv + 0x14, &v);
    printf("FBLOCK [F14]: 0x%08X (config_lock=%d)\n", v, (v>>0)&1);
    safe_rd32(bar0, dv + 0x18, &v);
    printf("Range1 Size Lo [F18]: 0x%08X (Active=%d, Valid=%d, MemSize[27:0]=0x%X)\n",
           v, (v>>1)&1, v&1, v >> 28);
    safe_rd32(bar0, dv + 0x1C, &v);
    printf("Range1 Size Hi [F1C]: 0x%08X\n", v);
    safe_rd32(bar0, dv + 0x20, &v);
    printf("Range1 Base Lo [F20]: 0x%08X\n", v);
    safe_rd32(bar0, dv + 0x24, &v);
    printf("Range1 Base Hi [F24]: 0x%08X\n", v);

    munmap(const_cast<uint32_t*>(bar0), 2*1024*1024);
    return 0;
}
