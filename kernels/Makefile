# =============================================================================
# Makefile — Vortex GPU kernel cross-compilation
#
# Builds RV64 kernel binaries for the Vortex SIMT processor.
#
# Targets:
#   all           Build gemm_kernel + spmv_kernel .elf/.bin (default)
#   gemm          Build only GEMM kernel
#   spmv          Build only SpMV kernel
#   dump          Generate disassembly listings
#   clean         Remove build artifacts
#
# Usage:
#   make                      # Build all kernels
#   make spmv                 # Build SpMV kernel only
#   make CROSS_COMPILE=riscv64-linux-gnu-   # Use Linux toolchain
# =============================================================================

# Toolchain prefix — try riscv64-unknown-elf- first, fall back to riscv64-linux-gnu-
CROSS_COMPILE ?= $(shell \
    if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then \
        echo "riscv64-unknown-elf-"; \
    elif command -v riscv64-linux-gnu-gcc >/dev/null 2>&1; then \
        echo "riscv64-linux-gnu-"; \
    else \
        echo "riscv64-unknown-elf-"; \
    fi)

CC      = $(CROSS_COMPILE)gcc
AS      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE    = $(CROSS_COMPILE)size

# Architecture flags
ARCH    = rv64imafdc
ABI     = lp64d
MARCH   = -march=$(ARCH) -mabi=$(ABI)

# Compiler flags
CFLAGS  = $(MARCH) -nostdlib -nostartfiles -ffreestanding -O2 \
          -Wall -Wextra -Wno-unused-parameter \
          -fno-builtin -fno-common -ffunction-sections -fdata-sections \
          -I.

ASFLAGS = $(MARCH) -nostdlib -nostartfiles -ffreestanding -I.

# Linker flags
LDFLAGS = $(MARCH) -nostdlib -nostartfiles -T linker.ld \
          -Wl,--gc-sections -Wl,--print-memory-usage

# =============================================================================
# Targets
# =============================================================================

.PHONY: all gemm spmv prefetch_chain prefetch_hash prefetch_stream prefetch_all asm dump clean check-toolchain info

all: check-toolchain gemm spmv prefetch_all

gemm: check-toolchain gemm_kernel.bin gemm_kernel.hex
	@echo ""
	@echo "GEMM build complete:"
	@echo "  gemm_kernel.bin  — Raw binary (load at 0x80000000)"
	@$(SIZE) gemm_kernel.elf

spmv: check-toolchain spmv_kernel.bin spmv_kernel.hex
	@echo ""
	@echo "SpMV build complete:"
	@echo "  spmv_kernel.bin  — Raw binary (load at 0x80000000)"
	@$(SIZE) spmv_kernel.elf

asm:
	$(MAKE) KERNEL_SRC=asm gemm

# Check that the cross-compiler is available
check-toolchain:
	@if ! command -v $(CC) >/dev/null 2>&1; then \
		echo "ERROR: RISC-V cross-compiler not found: $(CC)"; \
		echo ""; \
		echo "Install one of:"; \
		echo "  apt-get install gcc-riscv64-unknown-elf     # bare-metal"; \
		echo "  apt-get install gcc-riscv64-linux-gnu       # Linux toolchain"; \
		echo ""; \
		echo "Or set CROSS_COMPILE:"; \
		echo "  make CROSS_COMPILE=riscv64-linux-gnu-"; \
		exit 1; \
	fi

# =============================================================================
# GEMM kernel
# =============================================================================

gemm_kernel.o: gemm_kernel.c vx_intrinsics.h gemm_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

gemm_kernel_asm.o: gemm_kernel.S
	$(AS) $(ASFLAGS) -c -o $@ $<

# =============================================================================
# SpMV kernel
# =============================================================================

spmv_kernel.o: spmv_kernel.c vx_intrinsics.h spmv_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

# =============================================================================
# Prefetch kernels (CIRA)
# =============================================================================

prefetch_all: check-toolchain prefetch_chain prefetch_hash prefetch_stream

prefetch_chain: check-toolchain prefetch_chain_kernel.bin prefetch_chain_kernel.hex
	@echo ""
	@echo "Prefetch Chain build complete:"
	@$(SIZE) prefetch_chain_kernel.elf

prefetch_hash: check-toolchain prefetch_hash_kernel.bin prefetch_hash_kernel.hex
	@echo ""
	@echo "Prefetch Hash build complete:"
	@$(SIZE) prefetch_hash_kernel.elf

prefetch_stream: check-toolchain prefetch_stream_kernel.bin prefetch_stream_kernel.hex
	@echo ""
	@echo "Prefetch Stream build complete:"
	@$(SIZE) prefetch_stream_kernel.elf

prefetch_chain_kernel.o: prefetch_chain_kernel.c vx_intrinsics.h prefetch_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

prefetch_hash_kernel.o: prefetch_hash_kernel.c vx_intrinsics.h prefetch_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

prefetch_stream_kernel.o: prefetch_stream_kernel.c vx_intrinsics.h prefetch_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

prefetch_chain_kernel.elf: crt0.o prefetch_chain_kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ crt0.o prefetch_chain_kernel.o

prefetch_hash_kernel.elf: crt0.o prefetch_hash_kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ crt0.o prefetch_hash_kernel.o

prefetch_stream_kernel.elf: crt0.o prefetch_stream_kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ crt0.o prefetch_stream_kernel.o

# =============================================================================
# Common: CRT startup
# =============================================================================

crt0.o: crt0.S
	$(AS) $(ASFLAGS) -c -o $@ $<

# =============================================================================
# Linking
# =============================================================================

# GEMM kernel source selection
KERNEL_SRC ?= c
ifeq ($(KERNEL_SRC),asm)
    GEMM_OBJ = gemm_kernel_asm.o
else
    GEMM_OBJ = gemm_kernel.o
endif

gemm_kernel.elf: crt0.o $(GEMM_OBJ) linker.ld
	$(LD) $(LDFLAGS) -o $@ crt0.o $(GEMM_OBJ)

spmv_kernel.elf: crt0.o spmv_kernel.o linker.ld
	$(LD) $(LDFLAGS) -o $@ crt0.o spmv_kernel.o

# =============================================================================
# Binary generation
# =============================================================================

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
	@echo "Binary size: $$(wc -c < $@) bytes"

%.hex: %.elf
	$(OBJCOPY) -O ihex $< $@

# =============================================================================
# Debugging
# =============================================================================

dump: gemm_kernel.elf spmv_kernel.elf prefetch_chain_kernel.elf prefetch_hash_kernel.elf prefetch_stream_kernel.elf
	$(OBJDUMP) -d -M no-aliases -S gemm_kernel.elf > gemm_kernel.dump
	$(OBJDUMP) -d -M no-aliases -S spmv_kernel.elf > spmv_kernel.dump
	$(OBJDUMP) -d -M no-aliases -S prefetch_chain_kernel.elf > prefetch_chain_kernel.dump
	$(OBJDUMP) -d -M no-aliases -S prefetch_hash_kernel.elf > prefetch_hash_kernel.dump
	$(OBJDUMP) -d -M no-aliases -S prefetch_stream_kernel.elf > prefetch_stream_kernel.dump
	@echo "Disassembly written to *.dump"

info:
	@echo "Toolchain:    $(CC)"
	@echo "Architecture: $(ARCH)"
	@echo "ABI:          $(ABI)"

clean:
	rm -f *.o *.elf *.bin *.hex *.dump
