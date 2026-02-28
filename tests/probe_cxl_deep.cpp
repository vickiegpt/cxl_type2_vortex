/**
 * probe_cxl_deep.cpp — Deep probe of CXL mailbox & component registers.
 *
 * Probes:
 *   1. CXL Device Register block (BAR0+0x180000): capability array decode
 *   2. CXL Primary Mailbox (BAR0+0x180060): full register dump + Identify cmd
 *   3. CXL Component Registers (BAR0+0x150000 and +0x151000)
 *   4. PCIe config mirror region (BAR0+0x0E0000)
 *   5. Other live regions found in page scan
 *
 * Usage:
 *   g++ -std=c++17 -O2 -o probe_cxl_deep probe_cxl_deep.cpp
 *   sudo ./probe_cxl_deep
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
static constexpr size_t BAR0_SIZE = 2 * 1024 * 1024;

// DVSEC offsets
static constexpr uint32_t CXL_COMP_BASE = 0x150000;
static constexpr uint32_t CXL_DEV_BASE  = 0x180000;

// CXL Device Capability IDs (CXL 3.0 Table 8-73)
static const char* cxl_cap_name(uint16_t id) {
    switch (id) {
        case 0x0000: return "Device Cap Array";
        case 0x0001: return "Device Status";
        case 0x0002: return "Primary Mailbox";
        case 0x0003: return "Secondary Mailbox";
        case 0x4000: return "Memory Device Status";
        case 0x4001: return "Memory Device (HDM)";
        default:     return "Unknown";
    }
}

// ---- safe-read machinery ----
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

static uint32_t rd32(volatile uint32_t* b, uint32_t off) {
    uint32_t v = 0; safe_rd32(b, off, &v); return v;
}

static void wr32(volatile uint32_t* b, uint32_t off, uint32_t val) {
    b[off / 4] = val;
    asm volatile("sfence" ::: "memory");
}

static volatile uint32_t* map_bar(const char* path, size_t sz) {
    int fd = open(path, O_RDWR | O_SYNC);
    if (fd < 0) { perror(path); return nullptr; }
    auto* p = (volatile uint32_t*)mmap(nullptr, sz, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);
    return (p == MAP_FAILED) ? nullptr : p;
}

// Hex dump a region
static void hexdump(volatile uint32_t* base, uint32_t start, uint32_t len, const char* label) {
    printf("\n--- %s (0x%06X, %u bytes) ---\n", label, start, len);
    for (uint32_t off = 0; off < len; off += 16) {
        printf("  +0x%04X:", off);
        for (int i = 0; i < 4; i++) {
            uint32_t v = 0;
            bool ok = safe_rd32(base, start + off + i*4, &v);
            if (ok) printf(" %08X", v);
            else    printf(" ########");
        }
        printf("\n");
    }
}

// ============================================================
// CXL Mailbox registers (CXL 3.0 §8.2.8.4)
// Offsets relative to mailbox capability start
// ============================================================
struct MboxRegs {
    uint32_t cap;           // +0x00: Mailbox Capability
    uint32_t ctrl;          // +0x04: Mailbox Control
    uint32_t cmd;           // +0x08: Mailbox Command
    uint32_t cmd_hi;        // +0x0C: (upper 32 bits)
    uint32_t status;        // +0x10: Mailbox Status
    uint32_t status_hi;     // +0x14
    uint32_t bg_cmd_status; // +0x18: Background Command Status
    uint32_t bg_cmd_hi;     // +0x1C
    // +0x20: Command Payload (up to payload_size)
};

static void decode_mbox_cap(uint32_t cap) {
    printf("    Payload Size: %u bytes\n", 1u << ((cap >> 0) & 0x1F));
    printf("    MB Doorbell Int Capable: %u\n", (cap >> 5) & 1);
    printf("    BG Cmd Int Capable: %u\n", (cap >> 6) & 1);
    printf("    Multi-Headed: %u\n", (cap >> 7) & 1);
}

static void decode_mbox_status(uint32_t lo, uint32_t hi) {
    printf("    Background Op: %u\n", (lo >> 0) & 1);
    printf("    Doorbell: %u\n", (lo >> 0) & 1);  // bit in ctrl actually
    printf("    Return Code: 0x%04X\n", hi & 0xFFFF);
}

static bool mbox_send_cmd(volatile uint32_t* bar0, uint32_t mbox_off,
                          uint16_t opcode, uint32_t payload_len,
                          const void* payload_in, void* payload_out,
                          uint32_t out_len) {
    // Wait for doorbell to clear
    for (int i = 0; i < 1000; i++) {
        uint32_t ctrl = rd32(bar0, mbox_off + 0x04);
        if (!(ctrl & 1)) goto ready;
        usleep(1000);
    }
    printf("  ERROR: Mailbox doorbell stuck\n");
    return false;

ready:
    // Write payload
    if (payload_in && payload_len > 0) {
        const uint32_t* p = (const uint32_t*)payload_in;
        for (uint32_t i = 0; i < payload_len; i += 4)
            wr32(bar0, mbox_off + 0x20 + i, p[i/4]);
    }

    // Write Command register: opcode[15:0], payload_length[36:16] (in cmd_hi)
    uint32_t cmd_lo = opcode;
    uint32_t cmd_hi = (payload_len & 0x1FFFFF);
    wr32(bar0, mbox_off + 0x08, cmd_lo);
    wr32(bar0, mbox_off + 0x0C, cmd_hi);

    // Ring doorbell
    wr32(bar0, mbox_off + 0x04, 1);

    // Wait for completion (doorbell clear)
    for (int i = 0; i < 5000; i++) {
        uint32_t ctrl = rd32(bar0, mbox_off + 0x04);
        if (!(ctrl & 1)) goto done;
        usleep(1000);
    }
    printf("  ERROR: Mailbox command timeout\n");
    return false;

done:
    // Read status
    uint32_t st_lo = rd32(bar0, mbox_off + 0x10);
    uint32_t st_hi = rd32(bar0, mbox_off + 0x14);
    uint16_t ret_code = st_hi & 0xFFFF;
    printf("  Mailbox return code: 0x%04X (%s)\n", ret_code,
           ret_code == 0 ? "Success" :
           ret_code == 1 ? "Background Cmd Started" :
           ret_code == 2 ? "Invalid Input" :
           ret_code == 3 ? "Unsupported" :
           ret_code == 4 ? "Internal Error" : "Other");

    // Read output payload length
    uint32_t out_cmd_hi = rd32(bar0, mbox_off + 0x0C);
    uint32_t resp_len = out_cmd_hi & 0x1FFFFF;
    printf("  Response payload length: %u bytes\n", resp_len);

    if (payload_out && resp_len > 0) {
        uint32_t to_read = resp_len < out_len ? resp_len : out_len;
        uint32_t* p = (uint32_t*)payload_out;
        for (uint32_t i = 0; i < to_read; i += 4)
            p[i/4] = rd32(bar0, mbox_off + 0x20 + i);
    }
    return ret_code == 0;
}

int main() {
    struct sigaction sa{};
    sa.sa_handler = fault_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGBUS,  &sa, nullptr);
    sigaction(SIGSEGV, &sa, nullptr);

    printf("============================================================\n");
    printf("CXL Deep Probe — Mailbox & Component Registers\n");
    printf("============================================================\n");

    volatile uint32_t* bar0 = map_bar(BAR0_PATH, BAR0_SIZE);
    if (!bar0) return 1;
    printf("BAR0 mapped at %p\n", (void*)bar0);

    // ================================================================
    // 1. CXL Device Capability Array decode
    // ================================================================
    printf("\n========== CXL Device Capabilities (BAR0+0x%X) ==========\n", CXL_DEV_BASE);
    uint32_t cap_hdr_lo = rd32(bar0, CXL_DEV_BASE + 0x0);
    uint32_t cap_count  = rd32(bar0, CXL_DEV_BASE + 0x4);

    uint16_t array_cap_id = cap_hdr_lo & 0xFFFF;
    uint8_t  array_ver    = (cap_hdr_lo >> 16) & 0xFF;
    printf("  Cap Array: ID=0x%04X (%s), Version=%d, Count=%u\n",
           array_cap_id, cxl_cap_name(array_cap_id), array_ver, cap_count);

    // Each cap header entry is 16 bytes starting at +0x10
    struct CapEntry { uint16_t id; uint8_t ver; uint32_t offset; uint32_t length; };
    CapEntry caps[16];
    int ncaps = cap_count < 16 ? cap_count : 16;

    for (int i = 0; i < ncaps; i++) {
        uint32_t base = CXL_DEV_BASE + 0x10 + i * 0x10;
        uint32_t w0 = rd32(bar0, base + 0x0);
        uint32_t w1 = rd32(bar0, base + 0x4);
        uint32_t w2 = rd32(bar0, base + 0x8);

        caps[i].id     = w0 & 0xFFFF;
        caps[i].ver    = (w0 >> 16) & 0xFF;
        caps[i].offset = w1;
        caps[i].length = w2;

        printf("\n  Cap[%d]: ID=0x%04X (%s), Ver=%d\n",
               i, caps[i].id, cxl_cap_name(caps[i].id), caps[i].ver);
        printf("    Offset: 0x%X (abs: 0x%X)\n", caps[i].offset,
               CXL_DEV_BASE + caps[i].offset);
        printf("    Length: 0x%X (%u bytes)\n", caps[i].length, caps[i].length);
    }

    // ================================================================
    // 2. Device Status capability
    // ================================================================
    for (int i = 0; i < ncaps; i++) {
        if (caps[i].id == 0x0001) {
            uint32_t abs = CXL_DEV_BASE + caps[i].offset;
            printf("\n========== Device Status (BAR0+0x%X) ==========\n", abs);
            hexdump(bar0, abs, caps[i].length, "Device Status");
            uint32_t ds0 = rd32(bar0, abs);
            uint32_t ds1 = rd32(bar0, abs + 4);
            printf("  Event Status: 0x%08X\n", ds0);
            printf("  Device State: 0x%08X\n", ds1);
        }
    }

    // ================================================================
    // 3. Memory Device Status
    // ================================================================
    for (int i = 0; i < ncaps; i++) {
        if (caps[i].id == 0x4000) {
            uint32_t abs = CXL_DEV_BASE + caps[i].offset;
            printf("\n========== Memory Device Status (BAR0+0x%X) ==========\n", abs);
            hexdump(bar0, abs, caps[i].length, "Memory Device Status");
        }
    }

    // ================================================================
    // 4. Primary Mailbox — full register dump and Identify command
    // ================================================================
    for (int i = 0; i < ncaps; i++) {
        if (caps[i].id == 0x0002) {
            uint32_t mbox_abs = CXL_DEV_BASE + caps[i].offset;
            printf("\n========== Primary Mailbox (BAR0+0x%X, len=0x%X) ==========\n",
                   mbox_abs, caps[i].length);

            // Dump mailbox control registers (first 0x20 bytes)
            hexdump(bar0, mbox_abs, 0x20, "Mailbox Control Regs");

            uint32_t mbox_cap = rd32(bar0, mbox_abs + 0x00);
            printf("\n  Mailbox Capability: 0x%08X\n", mbox_cap);
            decode_mbox_cap(mbox_cap);

            uint32_t mbox_ctrl = rd32(bar0, mbox_abs + 0x04);
            printf("  Mailbox Control: 0x%08X (doorbell=%u)\n", mbox_ctrl, mbox_ctrl & 1);

            uint32_t mbox_status_lo = rd32(bar0, mbox_abs + 0x10);
            uint32_t mbox_status_hi = rd32(bar0, mbox_abs + 0x14);
            printf("  Mailbox Status:  0x%08X_%08X\n", mbox_status_hi, mbox_status_lo);

            // Attempt Identify command (opcode 0x0001)
            printf("\n  --- Sending Identify command (opcode 0x0001) ---\n");
            uint8_t identify_resp[256] = {};
            bool ok = mbox_send_cmd(bar0, mbox_abs, 0x0001, 0,
                                    nullptr, identify_resp, sizeof(identify_resp));
            if (ok) {
                printf("\n  Identify Response:\n");
                // CXL 3.0 §8.2.9.8.1 Identify Memory Device output
                uint64_t total_cap = *(uint64_t*)(identify_resp + 0);
                uint64_t volatile_cap = *(uint64_t*)(identify_resp + 8);
                uint64_t persistent_cap = *(uint64_t*)(identify_resp + 16);
                printf("    Total Capacity:      0x%016lX (%lu MB)\n",
                       total_cap, total_cap / (1024*1024));
                printf("    Volatile Capacity:   0x%016lX (%lu MB)\n",
                       volatile_cap, volatile_cap / (1024*1024));
                printf("    Persistent Capacity: 0x%016lX (%lu MB)\n",
                       persistent_cap, persistent_cap / (1024*1024));

                // Hex dump full response
                printf("\n    Raw response (first 128 bytes):\n");
                for (int j = 0; j < 128; j += 16) {
                    printf("    +0x%02X:", j);
                    for (int k = 0; k < 16; k++)
                        printf(" %02X", identify_resp[j+k]);
                    printf("\n");
                }
            } else {
                printf("  Identify command failed or unsupported\n");
                // Dump first 64 bytes of payload area anyway
                hexdump(bar0, mbox_abs + 0x20, 64, "Mailbox Payload (raw)");
            }

            // Try Get Supported Features (opcode 0x0500) — CXL 3.0
            printf("\n  --- Sending Get Supported Logs (opcode 0x0400) ---\n");
            uint8_t logs_resp[256] = {};
            ok = mbox_send_cmd(bar0, mbox_abs, 0x0400, 0,
                               nullptr, logs_resp, sizeof(logs_resp));
            if (ok) {
                uint16_t num_logs = *(uint16_t*)(logs_resp);
                printf("    Number of logs: %u\n", num_logs);
                for (int l = 0; l < num_logs && l < 8; l++) {
                    uint8_t* entry = logs_resp + 4 + l * 24;
                    printf("    Log[%d]: UUID = ", l);
                    for (int b = 0; b < 16; b++) printf("%02X", entry[b]);
                    printf(", size = %u\n", *(uint32_t*)(entry + 16));
                }
            }
        }
    }

    // ================================================================
    // 5. CXL Component Registers
    // ================================================================
    printf("\n========== CXL Component Registers ==========\n");

    // First 256 bytes at 0x150000
    hexdump(bar0, CXL_COMP_BASE, 0x100, "Component Regs base (0x150000)");

    // Live data found at 0x151000
    printf("\n--- Component Regs +0x1000 (0x151000) ---\n");
    hexdump(bar0, CXL_COMP_BASE + 0x1000, 0x100, "CXL.cache/mem Link Caps? (0x151000)");

    // CXL DVSEC for CXL.cache/mem: scan a bit wider
    hexdump(bar0, CXL_COMP_BASE + 0x1000, 0x200,
            "Component +0x1000..+0x1200");

    // ================================================================
    // 6. Probe other live regions from page scan
    // ================================================================
    printf("\n========== Other Live Regions ==========\n");

    // PCIe config mirror
    hexdump(bar0, 0x0E0000, 0x100, "PCIe config mirror (0x0E0000)");

    // Mystery regions
    uint32_t mystery[] = {0x0FA000, 0x11A000, 0x11B000, 0x11C000, 0x11D000};
    for (auto off : mystery) {
        char label[64];
        snprintf(label, sizeof(label), "Live region 0x%06X", off);
        hexdump(bar0, off, 0x40, label);
    }

    munmap(const_cast<uint32_t*>(bar0), BAR0_SIZE);

    printf("\n============================================================\n");
    printf("Deep probe complete.\n");
    printf("============================================================\n");
    return 0;
}
