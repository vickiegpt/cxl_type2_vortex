/**
 * linker.ld
 *
 * Linker script for Vortex GPU kernels.
 *
 * Memory map:
 *   0x80000000  Kernel image (.text, .rodata, .data) — contiguous for objcopy
 *   0x9E000000  BSS region (NOLOAD — not included in binary)
 *   0x9F000000  Stack base (grows downward, per-thread)
 *
 * The kernel binary is loaded at 0x80000000 by the host (via AXI to
 * the Vortex instruction cache). All loadable sections are placed
 * contiguously so that objcopy -O binary produces a compact image.
 */

ENTRY(_start)

MEMORY
{
    /* All loadable sections go here (contiguous for small binary output) */
    KERNEL (rwx) : ORIGIN = 0x80000000, LENGTH = 480M

    /* BSS is NOLOAD — not part of the binary image */
    BSS    (rw)  : ORIGIN = 0x9E000000, LENGTH = 16M
}

SECTIONS
{
    /* ================================================================
     * Code sections — entry point at 0x80000000
     * ================================================================ */
    .text : ALIGN(4)
    {
        *(.text._start)        /* Entry point first */
        *(.text .text.*)
    } > KERNEL

    .rodata : ALIGN(8)
    {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } > KERNEL

    /* ================================================================
     * Data sections — immediately after code (contiguous)
     * ================================================================ */
    .data : ALIGN(8)
    {
        __data_start = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        __data_end = .;
    } > KERNEL

    /* ================================================================
     * BSS — NOLOAD, not included in the binary image
     * ================================================================ */
    .bss (NOLOAD) : ALIGN(8)
    {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } > BSS

    /* ================================================================
     * Stack base symbol — per-thread stacks grow downward from here
     *
     * crt0.S computes: sp = _stack_base - (global_tid + 1) * STACK_SIZE
     * ================================================================ */
    _stack_base = 0x9F000000;

    /* Discard unwanted sections */
    /DISCARD/ :
    {
        *(.eh_frame)
        *(.comment)
        *(.note.*)
    }
}
