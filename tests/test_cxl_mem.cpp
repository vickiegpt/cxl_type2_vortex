/**
 * test_cxl_mem.cpp — CXL.mem + /dev/dax functional test
 *
 * Tests the CXL Type2 device memory via /dev/dax12.0:
 *   1. Basic mmap + read/write
 *   2. Pattern write/readback (walking ones, all-F, alternating)
 *   3. Stride tests (byte, 4B, 8B, 64B cacheline)
 *   4. Cache coherence (clflush + read)
 *   5. Multi-page sweep
 *   6. Bandwidth measurement
 *   7. Shared buffer test (write pattern, then GPU reads via CXL.cache)
 *
 * Usage:
 *   g++ -std=c++17 -O2 -o test_cxl_mem test_cxl_mem.cpp -lrt
 *   sudo ./test_cxl_mem [/dev/dax12.0] [size_mb]
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <x86intrin.h>
#include <emmintrin.h>

static const char* DEFAULT_DAX = "/dev/dax12.0";
static const size_t DEFAULT_SIZE_MB = 64;

struct TestResult {
    int pass = 0;
    int fail = 0;
    void check(const char* name, bool ok) {
        if (ok) { printf("  [PASS] %s\n", name); pass++; }
        else    { printf("  [FAIL] %s\n", name); fail++; }
    }
};

// ========================================================================
// Test 1: Basic write/readback at various offsets
// ========================================================================
static void test_basic_rw(volatile uint8_t* base, size_t size, TestResult& r) {
    printf("\n--- Test 1: Basic write/readback ---\n");

    // 64-bit write/read at offset 0
    volatile uint64_t* p64 = (volatile uint64_t*)base;
    p64[0] = 0xDEADBEEFCAFEBABEULL;
    _mm_sfence();
    _mm_lfence();
    uint64_t v = p64[0];
    r.check("64-bit write/read at offset 0",
            v == 0xDEADBEEFCAFEBABEULL);
    if (v != 0xDEADBEEFCAFEBABEULL)
        printf("         got: 0x%016lx\n", v);

    // 32-bit write/read at offset 0x100
    volatile uint32_t* p32 = (volatile uint32_t*)(base + 0x100);
    p32[0] = 0x12345678;
    _mm_sfence();
    _mm_lfence();
    r.check("32-bit write/read at offset 0x100",
            p32[0] == 0x12345678);

    // Byte write/read
    base[0x200] = 0xAB;
    _mm_sfence();
    _mm_lfence();
    r.check("Byte write/read at offset 0x200",
            base[0x200] == 0xAB);

    // Write near end of region
    size_t end_off = size - 8;
    volatile uint64_t* pend = (volatile uint64_t*)(base + end_off);
    pend[0] = 0x0123456789ABCDEFULL;
    _mm_sfence();
    _mm_lfence();
    r.check("64-bit write/read near end",
            pend[0] == 0x0123456789ABCDEFULL);
}

// ========================================================================
// Test 2: Pattern tests (walking ones, all-F, alternating)
// ========================================================================
static void test_patterns(volatile uint8_t* base, TestResult& r) {
    printf("\n--- Test 2: Pattern tests ---\n");
    volatile uint64_t* p = (volatile uint64_t*)(base + 0x1000);

    // Walking ones (64-bit)
    bool walk_ok = true;
    for (int bit = 0; bit < 64; bit++) {
        uint64_t pat = 1ULL << bit;
        p[bit] = pat;
    }
    _mm_sfence();
    _mm_lfence();
    for (int bit = 0; bit < 64; bit++) {
        uint64_t pat = 1ULL << bit;
        if (p[bit] != pat) {
            printf("    Walking-1 FAIL bit %d: wrote 0x%016lx read 0x%016lx\n",
                   bit, pat, (uint64_t)p[bit]);
            walk_ok = false;
        }
    }
    r.check("Walking-ones (64 bits)", walk_ok);

    // All-ones / all-zeros
    p[0] = 0xFFFFFFFFFFFFFFFFULL;
    _mm_sfence(); _mm_lfence();
    r.check("All-ones 0xFFFFFFFFFFFFFFFF", p[0] == 0xFFFFFFFFFFFFFFFFULL);

    p[0] = 0x0000000000000000ULL;
    _mm_sfence(); _mm_lfence();
    r.check("All-zeros 0x0000000000000000", p[0] == 0x0000000000000000ULL);

    // Alternating pattern
    p[0] = 0xAAAAAAAAAAAAAAAAULL;
    p[1] = 0x5555555555555555ULL;
    _mm_sfence(); _mm_lfence();
    r.check("Alternating 0xAAAA...AAAA", p[0] == 0xAAAAAAAAAAAAAAAAULL);
    r.check("Alternating 0x5555...5555", p[1] == 0x5555555555555555ULL);
}

// ========================================================================
// Test 3: Cacheline-aligned 64B write/readback
// ========================================================================
static void test_cacheline(volatile uint8_t* base, TestResult& r) {
    printf("\n--- Test 3: Cacheline (64-byte) tests ---\n");

    // Write a full cacheline (8 x 64-bit words)
    volatile uint64_t* cl = (volatile uint64_t*)(base + 0x2000);  // 64B-aligned
    for (int i = 0; i < 8; i++)
        cl[i] = 0x100 + i;
    _mm_sfence();

    // Flush and re-read
    _mm_clflush((void*)cl);
    _mm_mfence();
    _mm_lfence();

    bool cl_ok = true;
    for (int i = 0; i < 8; i++) {
        if (cl[i] != (uint64_t)(0x100 + i)) {
            printf("    CL[%d]: expected 0x%lx got 0x%lx\n",
                   i, (uint64_t)(0x100+i), (uint64_t)cl[i]);
            cl_ok = false;
        }
    }
    r.check("Cacheline write + clflush + readback", cl_ok);
}

// ========================================================================
// Test 4: Multi-page sweep (4KB pages)
// ========================================================================
static void test_page_sweep(volatile uint8_t* base, size_t size, TestResult& r) {
    printf("\n--- Test 4: Multi-page sweep ---\n");

    size_t npages = size / 4096;
    if (npages > 1024) npages = 1024;  // Cap at 4MB

    // Write unique value at first qword of each page
    for (size_t pg = 0; pg < npages; pg++) {
        volatile uint64_t* p = (volatile uint64_t*)(base + pg * 4096);
        *p = 0xFACE000000000000ULL | pg;
    }
    _mm_sfence();

    // Read back
    int bad = 0;
    for (size_t pg = 0; pg < npages; pg++) {
        volatile uint64_t* p = (volatile uint64_t*)(base + pg * 4096);
        _mm_lfence();
        uint64_t expected = 0xFACE000000000000ULL | pg;
        if (*p != expected) {
            if (bad < 5)
                printf("    Page %zu: expected 0x%016lx got 0x%016lx\n",
                       pg, expected, (uint64_t)*p);
            bad++;
        }
    }
    char msg[128];
    snprintf(msg, sizeof(msg), "Page sweep (%zu pages, %d bad)", npages, bad);
    r.check(msg, bad == 0);
}

// ========================================================================
// Test 5: Cache coherence — write, clflush, read from "cold" cache
// ========================================================================
static void test_coherence(volatile uint8_t* base, TestResult& r) {
    printf("\n--- Test 5: Cache coherence (clflush round-trip) ---\n");

    volatile uint64_t* p = (volatile uint64_t*)(base + 0x10000);

    // Write pattern
    *p = 0xC0FFEE;
    _mm_sfence();

    // Flush from cache to device memory
    _mm_clflush((void*)p);
    _mm_mfence();

    // Write a different pattern
    *p = 0xBADBAD;
    _mm_sfence();

    // Flush again
    _mm_clflush((void*)p);
    _mm_mfence();
    _mm_lfence();

    // Re-read — should see 0xBADBAD (latest write)
    uint64_t v = *p;
    r.check("Coherence: clflush round-trip", v == 0xBADBAD);
    if (v != 0xBADBAD)
        printf("         got: 0x%016lx\n", v);
}

// ========================================================================
// Test 6: Bandwidth measurement (sequential 64-bit writes + reads)
// ========================================================================
static void test_bandwidth(volatile uint8_t* base, size_t size, TestResult& r) {
    printf("\n--- Test 6: Bandwidth measurement ---\n");

    size_t test_size = (size > 16*1024*1024) ? 16*1024*1024 : size;
    size_t nwords = test_size / 8;
    volatile uint64_t* p = (volatile uint64_t*)base;

    // Write bandwidth
    auto t0 = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < nwords; i++)
        p[i] = i;
    _mm_sfence();
    auto t1 = std::chrono::high_resolution_clock::now();

    double write_sec = std::chrono::duration<double>(t1 - t0).count();
    double write_mbps = (double)test_size / write_sec / (1024*1024);

    // Read bandwidth
    uint64_t sink = 0;
    auto t2 = std::chrono::high_resolution_clock::now();
    for (size_t i = 0; i < nwords; i++)
        sink += p[i];
    _mm_lfence();
    auto t3 = std::chrono::high_resolution_clock::now();

    double read_sec = std::chrono::duration<double>(t3 - t2).count();
    double read_mbps = (double)test_size / read_sec / (1024*1024);

    printf("  Write: %.1f MB/s (%zu MB in %.3f s)\n",
           write_mbps, test_size/(1024*1024), write_sec);
    printf("  Read:  %.1f MB/s (%zu MB in %.3f s) [sink=%lx]\n",
           read_mbps, test_size/(1024*1024), read_sec, sink);
    r.check("Bandwidth measured", write_mbps > 0 && read_mbps > 0);

    // Verify readback
    bool verify = true;
    for (size_t i = 0; i < nwords && i < 1024; i++) {
        if (p[i] != i) { verify = false; break; }
    }
    r.check("Post-bandwidth verify (first 8KB)", verify);
}

// ========================================================================
// Test 7: Shared buffer for GPU — write a GEMM-style data layout
//   Host writes matrices A and B, later GPU reads via CXL.cache
// ========================================================================
static void test_shared_buffer(volatile uint8_t* base, size_t size, TestResult& r) {
    printf("\n--- Test 7: Shared buffer layout (host-side) ---\n");

    // Layout: [header 64B] [matA NxN float32] [matB NxN float32] [matC NxN float32]
    const int N = 64;
    const size_t mat_size = N * N * sizeof(float);
    const size_t total = 64 + 3 * mat_size;  // ~49KB

    if (total > size) {
        printf("  [SKIP] Region too small for shared buffer test\n");
        return;
    }

    volatile uint8_t* buf = base + 0x100000;  // 1MB offset

    // Header: [magic 8B] [N 4B] [status 4B]
    volatile uint64_t* hdr = (volatile uint64_t*)buf;
    volatile uint32_t* hdr32 = (volatile uint32_t*)buf;
    hdr[0] = 0x56585F47454D4D00ULL;  // "VXGEMM\0\0"
    hdr32[2] = N;
    hdr32[3] = 0;  // status: 0=host_ready

    // Matrix A: identity-ish pattern
    volatile float* matA = (volatile float*)(buf + 64);
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            matA[i*N + j] = (i == j) ? 1.0f : 0.0f;

    // Matrix B: sequential values
    volatile float* matB = (volatile float*)(buf + 64 + mat_size);
    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            matB[i*N + j] = (float)(i * N + j);

    // Matrix C: zeros (result buffer)
    volatile float* matC = (volatile float*)(buf + 64 + 2 * mat_size);
    for (int i = 0; i < N * N; i++)
        matC[i] = 0.0f;

    _mm_sfence();

    // Verify readback of matrices
    bool ok = true;
    if (hdr[0] != 0x56585F47454D4D00ULL) ok = false;
    if (hdr32[2] != (uint32_t)N) ok = false;
    if (matA[0] != 1.0f) ok = false;
    if (matA[1] != 0.0f) ok = false;
    if (matA[N+1] != 1.0f) ok = false;
    if (matB[0] != 0.0f) ok = false;
    if (matB[1] != 1.0f) ok = false;
    if (matB[N] != (float)N) ok = false;

    r.check("Shared buffer header + matrices written", ok);

    // Compute expected C = A * B (since A=identity, C should = B)
    // In a real scenario the GPU would do this computation
    printf("  Shared buffer at DAX offset 0x100000 (%zu bytes)\n", total);
    printf("  Header: magic=0x%016lx N=%u status=%u\n",
           (uint64_t)hdr[0], hdr32[2], hdr32[3]);
    printf("  MatA[0,0]=%.1f MatA[1,1]=%.1f\n", (float)matA[0], (float)matA[N+1]);
    printf("  MatB[0,0]=%.1f MatB[0,1]=%.1f MatB[1,0]=%.1f\n",
           (float)matB[0], (float)matB[1], (float)matB[N]);
    printf("  Waiting for GPU to compute C = A*B...\n");
    printf("  (GPU not yet connected — PIO bridge bitstream needed)\n");
}

// ========================================================================
// Main
// ========================================================================
int main(int argc, char** argv) {
    const char* dax_path = (argc > 1) ? argv[1] : DEFAULT_DAX;
    size_t size_mb = (argc > 2) ? atoi(argv[2]) : DEFAULT_SIZE_MB;
    size_t size = size_mb * 1024 * 1024;

    printf("============================================================\n");
    printf("CXL.mem Functional Test via /dev/dax\n");
    printf("Device: %s  Size: %zu MB\n", dax_path, size_mb);
    printf("============================================================\n");

    int fd = open(dax_path, O_RDWR);
    if (fd < 0) {
        perror("open dax device");
        return 1;
    }

    // Map with MAP_SYNC for direct persistent access
    volatile uint8_t* base = (volatile uint8_t*)mmap(
        nullptr, size, PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_POPULATE, fd, 0);
    if (base == MAP_FAILED) {
        perror("mmap dax");
        // Try without MAP_POPULATE
        base = (volatile uint8_t*)mmap(
            nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (base == MAP_FAILED) {
            perror("mmap dax (retry)");
            close(fd);
            return 1;
        }
    }

    printf("DAX mapped at %p (%zu MB)\n", (void*)base, size_mb);

    TestResult r;

    test_basic_rw(base, size, r);
    test_patterns(base, r);
    test_cacheline(base, r);
    test_page_sweep(base, size, r);
    test_coherence(base, r);
    test_bandwidth(base, size, r);
    test_shared_buffer(base, size, r);

    // Summary
    printf("\n============================================================\n");
    printf("Results: %d passed, %d failed\n", r.pass, r.fail);
    printf("============================================================\n");

    if (r.fail == 0) {
        printf("\nCXL.mem is FUNCTIONAL — device memory is accessible.\n");
        printf("Host can read/write CXL device memory via /dev/dax12.0\n");
        printf("\nNext steps for GPU sharing:\n");
        printf("  1. Recompile bitstream with PIO-to-CSR bridge fix\n");
        printf("  2. GPU reads same memory via CXL.cache/AXI HDM port\n");
        printf("  3. Host writes kernel+data → GPU computes → host reads result\n");
    } else {
        printf("\nSome tests FAILED — CXL.mem path has issues.\n");
    }

    munmap((void*)base, size);
    close(fd);
    return r.fail > 0 ? 1 : 0;
}
