/**
 * load_kernel.h
 *
 * Header-only utility for loading Vortex GPU kernel binaries into
 * shared memory. Used by host-side test code (test_gemm_coherent.cpp).
 *
 * Usage:
 *   #include "load_kernel.h"
 *
 *   // Load .bin file at the kernel code region offset in shared memory
 *   size_t sz = load_kernel_binary("../kernels/gemm_kernel.bin",
 *                                  shared_mem_base, KERNEL_CODE_OFFSET);
 *   if (sz == 0) { // handle error or fallback to simulation }
 */

#ifndef LOAD_KERNEL_H
#define LOAD_KERNEL_H

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cerrno>

/**
 * Kernel code region offset within the GPU's address space.
 * The Vortex PC is initialized to 0x80000000 by DCR startup_addr.
 * When using shared memory, the kernel binary must be placed at
 * this offset from the shared memory base.
 */
static constexpr uint64_t KERNEL_CODE_OFFSET = 0x80000000ULL;

/**
 * Maximum kernel binary size (16 MB).
 * Prevents loading unreasonably large files.
 */
static constexpr size_t KERNEL_MAX_SIZE = 16 * 1024 * 1024;

/**
 * Load a raw kernel binary (.bin) file into shared memory.
 *
 * @param path          Path to the .bin file (e.g. "../kernels/gemm_kernel.bin")
 * @param memory_base   Base pointer of the shared memory region
 * @param offset        Byte offset within shared memory to load at
 *                      (typically KERNEL_CODE_OFFSET or a remapped address)
 * @param memory_size   Total size of the shared memory region (for bounds check)
 * @param verbose       Print status messages
 *
 * @return  Number of bytes loaded, or 0 on failure.
 */
static inline size_t load_kernel_binary(
    const char *path,
    uint8_t    *memory_base,
    uint64_t    offset,
    size_t      memory_size,
    bool        verbose = false)
{
    FILE *fp = fopen(path, "rb");
    if (!fp) {
        if (verbose)
            fprintf(stderr, "[load_kernel] Cannot open '%s': %s\n",
                    path, strerror(errno));
        return 0;
    }

    /* Get file size */
    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    if (file_size <= 0) {
        fprintf(stderr, "[load_kernel] Empty or unreadable file: '%s'\n", path);
        fclose(fp);
        return 0;
    }

    if ((size_t)file_size > KERNEL_MAX_SIZE) {
        fprintf(stderr, "[load_kernel] File too large: %ld bytes (max %zu)\n",
                file_size, KERNEL_MAX_SIZE);
        fclose(fp);
        return 0;
    }

    /* Bounds check against shared memory region */
    if (offset + (size_t)file_size > memory_size) {
        fprintf(stderr, "[load_kernel] Kernel binary (%ld bytes at offset 0x%lx) "
                "exceeds memory region (%zu bytes)\n",
                file_size, (unsigned long)offset, memory_size);
        fclose(fp);
        return 0;
    }

    /* Load binary into shared memory */
    uint8_t *dest = memory_base + offset;
    size_t nread = fread(dest, 1, (size_t)file_size, fp);
    fclose(fp);

    if (nread != (size_t)file_size) {
        fprintf(stderr, "[load_kernel] Short read: %zu of %ld bytes\n",
                nread, file_size);
        return 0;
    }

    if (verbose) {
        printf("[load_kernel] Loaded %zu bytes from '%s' at offset 0x%lx\n",
               nread, path, (unsigned long)offset);

        /* Print first 16 bytes as a sanity check */
        printf("[load_kernel] First 16 bytes: ");
        for (size_t i = 0; i < 16 && i < nread; i++)
            printf("%02x ", dest[i]);
        printf("\n");
    }

    return nread;
}

/**
 * Verify that a loaded kernel binary starts with valid RISC-V instructions.
 *
 * Checks that the first word is not all zeros or all ones (which would
 * indicate an empty or erased flash region).
 *
 * @param memory_base   Base pointer of the shared memory region
 * @param offset        Offset where the kernel was loaded
 * @return true if the binary looks like valid code
 */
static inline bool verify_kernel_loaded(
    const uint8_t *memory_base,
    uint64_t       offset)
{
    uint32_t first_word;
    memcpy(&first_word, memory_base + offset, sizeof(first_word));

    /* A valid RV64 instruction should not be 0x00000000 or 0xFFFFFFFF */
    if (first_word == 0x00000000 || first_word == 0xFFFFFFFF) {
        fprintf(stderr, "[load_kernel] Invalid first instruction: 0x%08x\n",
                first_word);
        return false;
    }

    return true;
}

#endif /* LOAD_KERNEL_H */
