#include <cstdint>
#include <cstdio>
#include <cstring>
#include <csetjmp>
#include <csignal>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

static sigjmp_buf jmpbuf;
static volatile sig_atomic_t in_test = 0;

static void fault_handler(int sig) {
    if (in_test)
        siglongjmp(jmpbuf, sig);
    _exit(128 + sig);
}

int main() {
    struct sigaction sa{};
    sa.sa_handler = fault_handler;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGBUS, &sa, nullptr);
    sigaction(SIGSEGV, &sa, nullptr);

    printf("=== Quick DAX Memory Test ===\n");

    int fd = open("/dev/dax12.0", O_RDWR);
    if (fd < 0) { perror("open /dev/dax12.0"); return 1; }

    size_t size = 2 * 1024 * 1024; // 2MB (aligned to page)
    void* p = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (p == MAP_FAILED) { perror("mmap"); close(fd); return 1; }

    printf("Mapped /dev/dax12.0 at %p (2MB)\n", p);
    volatile uint64_t* mem = static_cast<volatile uint64_t*>(p);

    // Test 1: Basic write + read
    in_test = 1;
    if (sigsetjmp(jmpbuf, 1) != 0) {
        printf("[FAIL] SIGBUS on memory access — HDM decoder not routing\n");
        munmap(p, size);
        close(fd);
        return 1;
    }

    printf("Test 1: Write 0xDEADBEEFCAFEBABE to offset 0...\n");
    mem[0] = 0xDEADBEEFCAFEBABEULL;
    asm volatile("sfence" ::: "memory");
    asm volatile("lfence" ::: "memory");
    uint64_t val = mem[0];
    in_test = 0;

    printf("  Read back: 0x%016lX\n", val);
    if (val == 0xDEADBEEFCAFEBABEULL)
        printf("  [PASS] Write/readback OK!\n");
    else
        printf("  [FAIL] Mismatch (expected 0xDEADBEEFCAFEBABE)\n");

    // Test 2: Pattern fill
    printf("Test 2: Pattern fill (64 qwords)...\n");
    in_test = 1;
    if (sigsetjmp(jmpbuf, 1) != 0) {
        printf("[FAIL] SIGBUS during pattern fill\n");
        munmap(p, size);
        close(fd);
        return 1;
    }

    for (int i = 0; i < 64; i++)
        mem[i] = 0x1234567800000000ULL | i;
    asm volatile("sfence" ::: "memory");

    int pass = 0, fail = 0;
    for (int i = 0; i < 64; i++) {
        asm volatile("lfence" ::: "memory");
        uint64_t expected = 0x1234567800000000ULL | i;
        if (mem[i] == expected)
            pass++;
        else {
            printf("  [FAIL] offset %d: got 0x%016lX expected 0x%016lX\n",
                   i, (uint64_t)mem[i], expected);
            fail++;
        }
    }
    in_test = 0;
    printf("  Pattern: %d pass, %d fail\n", pass, fail);

    printf("\n=== Result: %s ===\n",
           (fail == 0) ? "CXL.mem WORKING" : "FAILURES DETECTED");

    munmap(p, size);
    close(fd);
    return fail > 0 ? 1 : 0;
}
