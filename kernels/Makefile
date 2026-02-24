# =============================================================================
# Makefile — Vortex GPU GEMM kernel cross-compilation
#
# Builds RV64 kernel binaries for the Vortex SIMT processor.
#
# Targets:
#   all           Build gemm_kernel.elf + .bin (default)
#   asm           Build from hand-optimized assembly (gemm_kernel.S)
#   dump          Generate disassembly listing
#   hex           Generate hex dump
#   clean         Remove build artifacts
#
# Usage:
#   make                      # Build C kernel (default)
#   make KERNEL_SRC=asm       # Build assembly kernel
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

# Output names
TARGET  = gemm_kernel

# Source selection: 'c' (default) or 'asm'
KERNEL_SRC ?= c

ifeq ($(KERNEL_SRC),asm)
    KERNEL_OBJ = gemm_kernel_asm.o
else
    KERNEL_OBJ = gemm_kernel.o
endif

OBJECTS = crt0.o $(KERNEL_OBJ)

# =============================================================================
# Targets
# =============================================================================

.PHONY: all asm dump hex clean check-toolchain info

all: check-toolchain $(TARGET).bin $(TARGET).hex
	@echo ""
	@echo "Build complete:"
	@echo "  $(TARGET).elf  — Linked ELF binary"
	@echo "  $(TARGET).bin  — Raw binary (load at 0x80000000)"
	@echo "  $(TARGET).hex  — Hex dump"
	@$(SIZE) $(TARGET).elf

asm:
	$(MAKE) KERNEL_SRC=asm

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

# Compile C kernel
gemm_kernel.o: gemm_kernel.c vx_intrinsics.h gemm_args.h
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile assembly kernel
gemm_kernel_asm.o: gemm_kernel.S
	$(AS) $(ASFLAGS) -c -o $@ $<

# Compile CRT startup
crt0.o: crt0.S
	$(AS) $(ASFLAGS) -c -o $@ $<

# Link ELF
$(TARGET).elf: $(OBJECTS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

# Generate raw binary (stripped, loadable at 0x80000000)
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@
	@echo "Binary size: $$(wc -c < $@) bytes"

# Generate Intel HEX
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $@

# Disassembly listing
dump: $(TARGET).elf
	$(OBJDUMP) -d -M no-aliases -S $< > $(TARGET).dump
	@echo "Disassembly written to $(TARGET).dump"
	@echo "--- First 80 lines ---"
	@head -80 $(TARGET).dump

# Print build info
info:
	@echo "Toolchain:    $(CC)"
	@echo "Architecture: $(ARCH)"
	@echo "ABI:          $(ABI)"
	@echo "Kernel src:   $(KERNEL_SRC)"
	@echo "Objects:      $(OBJECTS)"

clean:
	rm -f *.o $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump
