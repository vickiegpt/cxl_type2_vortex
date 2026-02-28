/**
 * probe_bar0.cpp  —  Safe, incremental BAR0 probe for CXL Type2 device.
 *
 * Avoids full-BAR scans that cause PCIe completion timeouts / MCE crashes.
 * Uses SIGBUS/SIGSEGV handler + setjmp to survive bad MMIO reads.
 *
 * Usage:
 *   g++ -std=c++17 -O2 -o probe_bar0 probe_bar0.cpp && sudo ./probe_bar0
 */

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <csetjmp>
#include <csignal>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

static constexpr const char* BAR0_PATH = "/sys/bus/pci/devices/0000:ad:00.0/resource0";
static constexpr const char* BAR2_PATH = "/sys/bus/pci/devices/0000:ad:00.0/resource2";
static constexpr size_t BAR0_SIZE = 2 * 1024 * 1024;
static constexpr size_t BAR2_SIZE = 128 * 1024;

// DVSEC Register Locator offsets (from lspci -vvv)
static constexpr uint32_t CXL_COMP_OFF = 0x150000;
static constexpr uint32_t CXL_DEV_OFF  = 0x180000;

// ---- safe-read machinery ----
static sigjmp_buf jmpbuf;
static volatile sig_atomic_t in_probe = 0;

static void fault_handler(int sig) {
    if (in_probe)
        siglongjmp(jmpbuf, sig);
    _exit(128 + sig);
}

// Attempt a single 32-bit MMIO read; returns false if it faulted.
static bool safe_rd32(volatile uint32_t* base, uint32_t byte_off, uint32_t* out) {
    in_probe = 1;
    if (sigsetjmp(jmpbuf, 1) != 0) {
        in_probe = 0;
        return false;  // faulted
    }
    asm volatile("lfence" ::: "memory");
    *out = base[byte_off / 4];
    asm volatile("lfence" ::: "memory");
    in_probe = 0;
    return true;
}

static volatile uint32_t* map_bar(const char* path, size_t size) {
    int fd = open(path, O_RDWR | O_SYNC);
    if (fd < 0) { perror(path); return nullptr; }
    auto* p = static_cast<volatile uint32_t*>(
        mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
    close(fd);
    if (p == MAP_FAILED) { perror("mmap"); return nullptr; }
    return p;
}

// Read a set of offsets safely and print results.
static void probe_offsets(volatile uint32_t* base, const char* label,
                          const uint32_t* offs, int n) {
    printf("\n--- %s ---\n", label);
    printf("%-8s  %-10s  %s\n", "Offset", "Value", "Status");
    for (int i = 0; i < n; i++) {
        uint32_t val = 0;
        bool ok = safe_rd32(base, offs[i], &val);
        if (!ok)
            printf("0x%06X  **FAULT**   SIGBUS/SIGSEGV\n", offs[i]);
        else if (val == 0xFFFFFFFF)
            printf("0x%06X  0xFFFFFFFF  (UR / unmapped)\n", offs[i]);
        else if (val == 0)
            printf("0x%06X  0x00000000  (zero)\n", offs[i]);
        else
            printf("0x%06X  0x%08X  <-- live data\n", offs[i], val);
    }
}

int main() {
    // Install fault handlers
    struct sigaction sa{};
    sa.sa_handler = fault_handler;
    sa.sa_flags = 0;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGBUS,  &sa, nullptr);
    sigaction(SIGSEGV, &sa, nullptr);

    printf("============================================================\n");
    printf("CXL Type2 Safe BAR0 Probe\n");
    printf("Device: 0000:ad:00.0\n");
    printf("============================================================\n");

    // ---- Map BAR0 ----
    volatile uint32_t* bar0 = map_bar(BAR0_PATH, BAR0_SIZE);
    if (!bar0) return 1;
    printf("BAR0 mapped at %p (2 MB)\n", (void*)bar0);

    // ================================================================
    // 1. Vendor CSR space — first 512 bytes (safe, always mapped in BAR)
    // ================================================================
    {
        uint32_t offsets[128];
        for (int i = 0; i < 128; i++) offsets[i] = i * 4;
        probe_offsets(bar0, "BAR0 first 512 bytes (vendor CSR)", offsets, 128);
    }

    // ================================================================
    // 2. CXL Component Registers at BAR0 + 0x150000
    //    (CXL spec: capability header, HDM decoder, link, etc.)
    //    Only read first 64 dwords (256 bytes).
    // ================================================================
    {
        uint32_t offsets[64];
        for (int i = 0; i < 64; i++) offsets[i] = CXL_COMP_OFF + i * 4;
        probe_offsets(bar0, "CXL Component Regs (BAR0+0x150000, 256B)", offsets, 64);
    }

    // ================================================================
    // 3. CXL Device Registers at BAR0 + 0x180000
    //    (CXL spec: device cap array, device status, mailbox)
    //    Only read first 64 dwords (256 bytes).
    // ================================================================
    {
        uint32_t offsets[64];
        for (int i = 0; i < 64; i++) offsets[i] = CXL_DEV_OFF + i * 4;
        probe_offsets(bar0, "CXL Device Regs (BAR0+0x180000, 256B)", offsets, 64);
    }

    // ================================================================
    // 4. Spot-check a few more BAR0 pages to find live regions
    //    Read only dword 0 of each 4KB page to avoid mass faults.
    // ================================================================
    {
        printf("\n--- BAR0 page-0 scan (first dword of each 4KB page) ---\n");
        int live = 0, fault = 0;
        for (uint32_t page = 0; page < BAR0_SIZE; page += 0x1000) {
            uint32_t val = 0;
            bool ok = safe_rd32(bar0, page, &val);
            if (!ok) {
                if (fault < 5) printf("  [0x%06X] FAULT\n", page);
                fault++;
            } else if (val != 0 && val != 0xFFFFFFFF) {
                printf("  [0x%06X] = 0x%08X  <-- live\n", page, val);
                live++;
            }
            // stop early if we hit faults — the rest is likely unmapped too
            if (fault > 10) {
                printf("  ... too many faults, stopping page scan\n");
                break;
            }
        }
        printf("  Live pages: %d, Faults: %d\n", live, fault);
    }

    // ================================================================
    // 5. Write/readback test at safe vendor offsets
    // ================================================================
    {
        printf("\n--- Write/readback test (vendor CSR 0x110) ---\n");
        uint32_t orig = 0;
        if (safe_rd32(bar0, 0x110, &orig)) {
            bar0[0x110/4] = 0xCAFEBABE;
            asm volatile("sfence; lfence" ::: "memory");
            uint32_t rb = 0;
            safe_rd32(bar0, 0x110, &rb);
            bar0[0x110/4] = orig;  // restore
            printf("  Write 0xCAFEBABE -> read 0x%08X  %s\n",
                   rb, rb == 0xCAFEBABE ? "PASS" : "FAIL");
        } else {
            printf("  Read faulted, skipping write test\n");
        }
    }

    munmap(const_cast<uint32_t*>(bar0), BAR0_SIZE);

    // ================================================================
    // 6. BAR2 quick probe (128KB)
    // ================================================================
    printf("\n=== BAR2 Probe (128KB) ===\n");
    volatile uint32_t* bar2 = map_bar(BAR2_PATH, BAR2_SIZE);
    if (bar2) {
        printf("BAR2 mapped at %p\n", (void*)bar2);
        // Read first 64 dwords
        {
            uint32_t offsets[64];
            for (int i = 0; i < 64; i++) offsets[i] = i * 4;
            probe_offsets(bar2, "BAR2 first 256 bytes", offsets, 64);
        }
        // Page-0 scan
        {
            printf("\n--- BAR2 page-0 scan ---\n");
            int live = 0, fault = 0;
            for (uint32_t page = 0; page < BAR2_SIZE; page += 0x1000) {
                uint32_t val = 0;
                bool ok = safe_rd32(bar2, page, &val);
                if (!ok) { fault++; if (fault <= 3) printf("  [0x%06X] FAULT\n", page); }
                else if (val != 0 && val != 0xFFFFFFFF)
                    printf("  [0x%06X] = 0x%08X\n", page, val);
                else live++;
                if (fault > 5) { printf("  ... faults, stopping\n"); break; }
            }
            printf("  Mapped pages: %d, Faults: %d\n", live, fault);
        }
        // Write test
        {
            printf("\n--- BAR2 write/readback (offset 0x0) ---\n");
            uint32_t orig = 0;
            if (safe_rd32(bar2, 0, &orig)) {
                bar2[0] = 0xDEADC0DE;
                asm volatile("sfence; lfence" ::: "memory");
                uint32_t rb = 0;
                safe_rd32(bar2, 0, &rb);
                bar2[0] = orig;
                printf("  Write 0xDEADC0DE -> read 0x%08X  %s\n",
                       rb, rb == 0xDEADC0DE ? "PASS" : "FAIL");
            }
        }
        munmap(const_cast<uint32_t*>(bar2), BAR2_SIZE);
    } else {
        printf("  Failed to map BAR2\n");
    }

    printf("\n============================================================\n");
    printf("Probe complete (no crash = success).\n");
    printf("============================================================\n");
    return 0;
}
