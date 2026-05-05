# IA-780i CXL Type 2 Delay Buffer

CXL Type 2 accelerator on Intel Agilex 7 FPGA (IA-780i platform) with a Vortex
RV64 SIMT GPU and configurable memory latency injection. PCI `0000:ad:00.0`,
device `8086:0DDB`.

## Architecture Overview

```
 ┌─────────────────────────────────────────────────────────────────────┐
 │  Host CPU                                                          │
 │    ├─ MMIO (BAR0 CSR writes)  ──── CXL.io / PIO ────┐             │
 │    ├─ Memory load/store       ──── CXL.mem ──────────┤             │
 │    └─ Cache coherency         ──── CXL.cache ────────┤             │
 └──────────────────────────────────────────────────────┼─────────────┘
                          PCIe/CXL 16-lane link         │
 ┌──────────────────────────────────────────────────────┼─────────────┐
 │  Intel CXL IP  (intel_rtile_cxl_top)                 │             │
 │    ├─ PCIe TLP decode ──────────────────────────────┐│             │
 │    ├─ DVSEC registers (CXLCap, CXLCtl, Ranges)     ││             │
 │    ├─ HDM Decoder (HPA → DPA translation)           ││             │
 │    └─ Mailbox, Device Status, Component Regs        ││             │
 ├─────────────────────────────────────────────────────┘│             │
 │                                                      │             │
 │  ┌──── PIO AVMM bus (125 MHz, 64-bit) ──────────────┤             │
 │  │                                                   │             │
 │  ▼                                                   │             │
 │  ex_default_csr_top                                  │             │
 │    └─ ex_default_csr_avmm_slave                      │             │
 │         ├─ Vortex GPU CSRs (0x100–0x148)             │             │
 │         └─ launch trigger, status, perf counters     │             │
 │              │                                       │             │
 │              ▼                                       │             │
 │  ┌── afu_top ────────────────────────────────────────┤             │
 │  │                                                   │             │
 │  │   vortex_gpu_wrapper                              │             │
 │  │     └─ Vortex GPU core (RV64 SIMT)               │             │
 │  │          ├─ Port 0 (host mem) ─── tied off        │             │
 │  │          └─ Port 1 (dev mem)  ───┐                │             │
 │  │                                  │                │             │
 │  │   axi_mc_arbiter ◄──────────────┘                │             │
 │  │     ├─ m0: HDM Ch1 (CXL.mem from IP) ◄───────────┘             │
 │  │     ├─ m1: GPU Port 1 (Vortex AXI)                             │
 │  │     └─ s:  merged → MC Channel 1                               │
 │  │              │                                                  │
 │  │   [Delay Buffer]  ◄── Channel 0 only, configurable latency     │
 │  │              │                                                  │
 │  └──────────────┤                                                  │
 │                 ▼                                                   │
 │  mc_top                                                            │
 │    ├─ mc_single_chan_hdm_axi_fsm (AXI → EMIF AVMM)                │
 │    ├─ ECC encode/decode (Altera ECC IP)                            │
 │    ├─ CDC FIFOs (ip_clk ↔ emif_clk)                               │
 │    └─ EMIF DDR4-2666 (dual channel, 32GB each)                    │
 │         ├─ dram0: Channel 0 (host CXL.mem + delay buffer)         │
 │         └─ dram1: Channel 1 (host CXL.mem + GPU shared)           │
 └────────────────────────────────────────────────────────────────────┘
```

## Module Hierarchy

```
cxltyp2_ed.sv                         Top (PCIe PHY, RTile PLL, CXL IP)
 └─ ed_top_wrapper_typ2.sv            Endpoint wrapper
     ├─ ex_default_csr_top             CSR decoder (AVMM → registers)
     │   └─ ex_default_csr_avmm_slave  Register file (DVSEC + Vortex GPU)
     ├─ afu_top                        Application Function Unit
     │   ├─ vortex_gpu_wrapper          Vortex RV64 SIMT GPU
     │   │   └─ Vortex core             2 AXI ports (port 0 tied off)
     │   └─ axi_mc_arbiter             2-to-1 AXI mux (host + GPU → MC)
     ├─ mc_top                         Memory controller
     │   ├─ mc_single_chan_hdm_axi_fsm  Per-channel AXI→AVMM FSM
     │   ├─ mc_devmem_top              Error monitoring (SBE/DBE/Poison)
     │   └─ mc_emif_avmm               EMIF DDR4 instantiation
     └─ cafu_csr0_cfg                  CXL Feature CSR (mem_enable, etc.)
```

## Data Flow Paths

### Path 1 — PIO: Host CPU → BAR0 CSR Registers

Host MMIO read/write to BAR0 for GPU configuration and control.

```
Host CPU store/load
 → PCIe TLP (BAR0 target)
 → Intel CXL IP PIO engine
 → AVMM bus (125 MHz, 64-bit data, byte-enable)
     address[21:0], writedata[63:0], readdata[63:0]
 → ex_default_csr_top
 → ex_default_csr_avmm_slave
     ├─ decode address → register select
     ├─ write: latch to register FF
     └─ read:  drive readdata from register/status
 → AVMM response → PIO completion TLP → Host
```

**Bus:** AVMM, 64-bit, `ip2csr_avmm_clk` (125 MHz)

### Path 2 — CXL.mem: Host CPU → Device DDR

Host load/store to HPA range [0x180000000000, +16GB) via CXL.mem protocol.

```
Host CPU load/store to HPA
 → CXL.mem request TLP over PCIe/CXL link
 → Intel CXL IP HDM Decoder
     HPA [51:6] → DPA translation (base/size/interleave)
 → HDM AXI interface (ip2hdm_aximm channels)
     AXI4: 512-bit data, 52-bit address, 8-bit ID
 → afu_top
     ├─ Channel 0: [delay buffer] → mc_top ch0 → EMIF dram0
     └─ Channel 1: axi_mc_arbiter (m0=host, m1=GPU) → mc_top ch1 → EMIF dram1
 → mc_single_chan_hdm_axi_fsm
     AXI4 → AVMM conversion, ECC insertion
 → EMIF DDR4-2666 SDRAM
 → Read data + ECC check → response FIFO → CXL completion → Host
```

**Bus:** AXI4, 512-bit (64B cache line), `ip2hdm_clk` (~545 MHz SIP)

### Path 3 — GPU Kernel Launch: CSR → Vortex GPU

Host writes CSR registers, then triggers kernel execution.

```
Host writes BAR0 CSRs:
  0x100: KERNEL_ADDR   ← entry point (0x80000000)
  0x108: KERNEL_ARGS   ← pointer to arg struct in shared mem
  0x110: GRID_DIM_X    ← grid dimensions
  0x114: GRID_DIM_Y
  0x118: GRID_DIM_Z
  0x11C: BLOCK_DIM_X   ← block dimensions
  0x120: BLOCK_DIM_Y
  0x124: BLOCK_DIM_Z
  0x140: COMPLETION_LO  ← DCOH completion address
  0x144: COMPLETION_HI
  0x148: DCOH_ENABLE    ← enable completion writeback

Host writes BAR0 + 0x128 = 1:
  → ex_default_csr_avmm_slave.LAUNCH register
  → vx_launch_trigger pulse (1 cycle)
  → vortex_gpu_wrapper starts execution
  → Vortex core fetches kernel binary from shared memory
  → Threads execute GEMM (grid-stride loop)
  → vx_fence() to flush stores
  → DCOH writeback: CompletionData.magic = 0xDEADBEEF

Host polls:
  BAR0 + 0x12C (STATUS): 0x00=IDLE, 0x01=RUNNING, 0x02=DONE, 0xFF=ERROR
  or polls completion→magic in shared memory (DCOH)
```

### Path 4 — GPU Memory Access: Vortex → DDR

GPU threads read/write device DDR through AXI Port 1.

```
Vortex GPU core (executing kernel threads)
 → AXI Port 1 (device memory, 512-bit, 4-bit ID)
 → axi_mc_arbiter
     m1 input (GPU): ID[7:0] = {1'b1, 3'b0, gpu_id[3:0]}
     m0 input (host HDM Ch1): ID[7] = 0
     Arbitration: priority/round-robin between host and GPU
 → s output → mc_top Channel 1
 → mc_single_chan_hdm_axi_fsm
 → ECC encode → EMIF dram1 → DDR4 SDRAM
 → Response: ID[7] demuxes back to GPU (1) or host (0)
```

**Shared address space:** Both host and GPU access the same DDR via Channel 1.
GPU Port 0 (host memory access) is tied off — not used in this design.

### Path 5 — DCOH Completion: GPU → Host Notification

Cache-coherent completion signaling without polling CSR.

```
GPU kernel finishes computation
 → Writes CompletionData struct to shared memory:
     .status    = 0 (success)
     .result    = FLOP count
     .cycles    = cycle counter
     .timestamp = timer value
     .magic     = 0xDEADBEEF  ← written last (release semantics)
 → Write flows through AXI Port 1 → MC → DDR
 → CXL.mem coherency ensures host CPU sees updated cache line
 → Host polling loop detects magic == 0xDEADBEEF
     (or host uses mwait/monitor on the cache line)
```

## BAR0 Register Map

| Offset | Region | Access |
|--------|--------|--------|
| `0x000000` | Vendor CSR space (AVMM slave) | R/W |
| `0x0E0000` | PCIe config space mirror | R |
| `0x150000` | CXL Component Registers (HDM decoder) | R/W |
| `0x180000` | CXL Device Registers (status, mailbox) | R/W |

### Vortex GPU CSR Registers (BAR0 + offset)

| Offset | Name | Width | Access | Description |
|--------|------|-------|--------|-------------|
| 0x100 | KERNEL_ADDR_LO | 32 | R/W | Kernel entry point [31:0] |
| 0x104 | KERNEL_ADDR_HI | 32 | R/W | Kernel entry point [63:32] |
| 0x108 | KERNEL_ARGS_LO | 32 | R/W | Kernel args pointer [31:0] |
| 0x10C | KERNEL_ARGS_HI | 32 | R/W | Kernel args pointer [63:32] |
| 0x110 | GRID_DIM_X | 32 | R/W | Grid dimension X |
| 0x114 | GRID_DIM_Y | 32 | R/W | Grid dimension Y |
| 0x118 | GRID_DIM_Z | 32 | R/W | Grid dimension Z |
| 0x11C | BLOCK_DIM_X | 32 | R/W | Block dimension X |
| 0x120 | BLOCK_DIM_Y | 32 | R/W | Block dimension Y |
| 0x124 | BLOCK_DIM_Z | 32 | R/W | Block dimension Z |
| 0x128 | LAUNCH | 32 | W | Write 1 to trigger kernel |
| 0x12C | STATUS | 8 | R | 0x00=IDLE 0x01=RUNNING 0x02=DONE 0xFF=ERROR |
| 0x130 | CYCLE_LO | 32 | R | Cycle counter [31:0] |
| 0x134 | CYCLE_HI | 32 | R | Cycle counter [63:32] |
| 0x138 | INSTR_LO | 32 | R | Instruction counter [31:0] |
| 0x13C | INSTR_HI | 32 | R | Instruction counter [63:32] |
| 0x140 | COMPLETION_LO | 32 | R/W | Completion address [31:0] |
| 0x144 | COMPLETION_HI | 32 | R/W | Completion address [63:32] |
| 0x148 | DCOH_ENABLE | 32 | R/W | Enable DCOH completion writeback |

## Clock Domains

| Domain | Frequency | Signals | Usage |
|--------|-----------|---------|-------|
| SIP | ~545 MHz | `ip2hdm_clk` | HDM AXI, core datapath |
| CSR | 125 MHz | `ip2csr_avmm_clk` | BAR0 PIO, register access |
| CAFU | 125 MHz | `ip2cafu_avmm_clk` | CXL feature CSR access |
| EMIF | DDR-dependent | `emif_usr_clk` | DDR4 controller |
| JTAG | 33 MHz | `altera_reserved_tck` | Debug |

CDC crossings use async FIFOs: CSR↔AXI, AXI↔EMIF.

## Shared Memory Layout (DAX/Hugepage)

```
 Offset         Content                  Alignment
 ─────────────  ───────────────────────  ──────────
 0x00000000     GemmKernelArgs (72B)     64B (cache line)
 0x00000040     CompletionData (64B)     64B (cache line)
 0x00001000     Matrix A (M*K floats)    4KB
 0x00001000+A   Matrix B (K*N floats)    4KB
 0x00001000+A+B Matrix C (M*N floats)    4KB
   ...
 0x80000000     Kernel binary (.bin)     4B (instruction aligned)
```

## Delay Buffer

The device name "delay buffer" refers to a configurable read latency injection
on HDM Channel 0. The `read_delay` register controls the depth of a FIFO-based
delay stage in `afu_top`, allowing characterization of CXL.mem latency impact
on application performance.

- Channel 0: Host CXL.mem traffic passes through delay buffer → dram0
- Channel 1: Direct path (no delay) shared between host CXL.mem and GPU → dram1

## CXL.mem Enable (RTL Fix)

BIOS sets `config_lock=1` (write-once latch) before the OS can enable CXL.mem
in the DVSEC control register. The RTL fix forces `mem_enable=1` at reset:

- `cafu_csr0_cfg_pkg.sv`: `MEM_ENABLE_RESET = 1'b1` (was `1'b0`)
- `cafu_csr0_cfg.sv`: FF reset value `1'h1` (was `1'h0`)
- Effect: `CXLCtl = 0x0007` (Cache+ IO+ Mem+) at power-on

## Kernel Driver

`cxl_type2_accel.c` registers the device as both CXL cache device and memory
device. Probe sequence:

1. `pcim_enable_device()` + `pci_set_master()`
2. Allocate `cxl_memdev_state` (embeds `cxl_dev_state` at offset 0)
3. Detect RCiEP topology → set `cxlds->rcd = true`
4. Read/enable DVSEC: Cache+ IO+ Mem+
5. Map component registers (BAR0+0x150000) for RAS
6. Register cache device: `devm_cxl_add_cachedev()` (128MB, 64B lines)
7. Set memory size: 16GB volatile
8. DPA partition setup: `cxl_mem_dpa_fetch()` + `cxl_dpa_setup()`
9. Register memory device: `devm_cxl_add_memdev()`

Additional kernel patches (applied):

| File | Fix |
|------|-----|
| `core/port.c` | `is_cxl_ep_device()` for cachedev endpoint detection |
| `core/pci.c` | Skip DVSEC ranges with base=0; early HDM enable when no ranges |
| `core/hdm.c` | Don't emulate decoders when no DVSEC ranges |
| `core/cdat.c` | Defer `gp_port` init after RCH early-return |
| `cxlmem.h` | `is_cxl_endpoint()` uses `is_cxl_ep_device()` |
| `acpi.c` | Synthetic root decoder for RCH dports without CFMWS |

## /dev/dax Path

```
cxl_acpi_probe()
 → cxl_inject_synthetic_cfmws()      Synthetic root decoder0.12
     HPA [0x180000000000, +16GB]      targeting RCH dport (pci0000:ad)
 → cxl_mem endpoint probe
 → cxl_hdm_decode_init()             HDM decoder enabled (no range validation)
 → decoder8.0 committed              DPA 0x0 → 16GB
 → cxl create-region                 region12 created
 → dax_cxl                           /dev/dax12.0 (devdax mode)
```

## GPU Kernel (GEMM)

Cross-compiled RV64 binary (`kernels/gemm_kernel.bin`, 824 bytes).

**Toolchain:** `riscv64-unknown-elf-gcc -march=rv64imafdc -mabi=lp64d`

**Entry point** (`crt0.S`):
1. Compute `global_tid = core_id * (warps * threads) + warp_id * threads + thread_id`
2. Set per-thread stack: `sp = _stack_base - (gtid+1) * 4096`
3. Read kernel args from CSR `mscratch` (0x340)
4. Call `kernel_main(args)`
5. `ecall` to signal completion

**GEMM kernel** (`gemm_kernel.c`): grid-stride loop, each thread computes
`C[row][col] = alpha * dot(A[row,:], B[:,col]) + beta * C[row][col]`.

**Thread mapping:** Block (8,4,1) = 32 threads/warp. Grid sized to cover
output matrix. Each thread strides by total thread count.

## Building & Testing

```bash
# Build GPU kernel (RV64 cross-compilation)
cd kernels && make

# Build GEMM coherency test
g++ -O2 -std=c++17 -o tests/test_gemm_coherent tests/test_gemm_coherent.cpp -lpthread

# Run (auto-detects real device, falls back to simulation)
./tests/test_gemm_coherent --dim 64 --verbose

# Force simulation mode
./tests/test_gemm_coherent --sim

# With kernel binary (real device)
./tests/test_gemm_coherent --kernel kernels/gemm_kernel.bin

# Build FPGA kernels
g++ -O2 -std=c++17 -o kernels/fpga/fpga_comprehensive_benchmark \
    kernels/fpga/fpga_comprehensive_benchmark.cpp

# Run benchmarks
cd benchmarks && bash run_benchmarks.sh
```

### Test programs

| Source | Purpose |
|--------|---------|
| `tests/probe_bar0.cpp` | Safe MMIO discovery with SIGBUS recovery |
| `tests/probe_cxl_deep.cpp` | CXL mailbox commands, capability decode |
| `tests/test_csr_readback.cpp` | Vortex CSR write/readback validation |
| `tests/test_kernel_launch.cpp` | Kernel launch + DCOH completion demo |
| `tests/test_gemm_coherent.cpp` | GEMM end-to-end test (real device or sim) |
| `tests/type2_snoop_protocol.cpp` | CXL Type 2 snoop protocol validation |
| `tests/gemm_realdev_bench.cpp` | GEMM performance benchmark on real device |
| `tests/phase1_validation.cpp` | Phase 1 CIRA hardware validation |
| `tests/cira_hw_test.cpp` | CIRA runtime hardware integration test |

## Device Setup

```bash
# Enable PCI device
echo 1 > /sys/bus/pci/devices/0000:ad:00.0/enable

# Enable bus master
setpci -s ad:00.0 COMMAND=0x0146

# Load kernel modules
modprobe cxl_acpi cxl_type2_accel

# Switch DAX to devdax mode (default may be system-ram)
daxctl reconfigure-device --mode=devdax dax12.0
```

## Repository Structure

```
hardware_test_design/
  cxltyp2_ed.sv                                Top-level (PCIe PHY + CXL IP)
  ed_top_wrapper_typ2.sv                        Endpoint wrapper (AFU + CSR + MC)
  cxltyp2_ed.qpf / cxltyp2_ed.qsf             Quartus project files
  flash_bitstream.sh                            FPGA programming script
  intel_rtile_cxl_top_cxltyp2_ed/             Intel CXL IP component
  common/afu/afu_top.sv                         AFU: GPU wrapper + AXI arbiter + delay buffer
  common/mc_top/mc_top.sv                       Memory controller (ECC + EMIF)
  common/mc_top/mc_single_chan_hdm_axi_fsm.sv  AXI→AVMM conversion FSM
  common/ex_default_csr/ex_default_csr_avmm_slave.sv  Register file
  common/cafu_csr0/cafu_csr0_cfg_pkg.sv         DVSEC reset values (mem_enable fix)
  common/cafu_csr0/cafu_csr0_cfg.sv             DVSEC register FFs

kernels/
  gemm_kernel.c                   SIMT GEMM kernel source
  crt0.S                          Thread startup (stack + entry)
  lock_kernel.c                   Spinlock kernel
  spmv_kernel.c                   SpMV kernel
  prefetch_chain_kernel.c         Prefetch chain kernel
  prefetch_hash_kernel.c          Prefetch hash kernel
  prefetch_stream_kernel.c        Prefetch stream kernel
  vx_intrinsics.h                 Vortex RISC-V intrinsics
  Makefile                        RV64 cross-compilation
  fpga/                           FPGA-targeted workload kernels
    fpga_comprehensive_benchmark.cpp
    fpga_workload_benchmark.cpp
    fpga_*_kernel.cpp             Per-workload FPGA kernels

runtime/
  cira_runtime.cpp / .h           CIRA host runtime
  mmio_ring_buffer.h              MMIO ring buffer for command dispatch
  completion_data.h               GPU→host completion struct

compiler/
  cira_dialect/                   MLIR CIRA dialect (ops, types, TableGen)
  cira_passes/                    Per-workload CIRA compiler passes
  profiling/                      CIRA profiler

benchmarks/
  mcf_cira.cpp                    MCF workload with CIRA instrumentation
  benchmark_results.csv           Collected benchmark data
  run_benchmarks.sh               Benchmark driver script
  llama/                          LLaMA inference benchmarks
    llama_unified_impl.cpp        Unified LLaMA implementation
    llama_unified_optimized.cpp   Optimized variant
    llama_optimized_core.h        Shared optimized primitives
    llama_benchmark_abc.cpp       ABC benchmark harness

tests/
  test_gemm_coherent.cpp          GEMM test (real device + DAX or simulation)
  probe_bar0.cpp                  BAR0 MMIO region discovery
  probe_cxl_deep.cpp              CXL mailbox + register decode
  test_csr_readback.cpp           Vortex CSR validation
  test_kernel_launch.cpp          Kernel launch + DCOH demo
  type2_snoop_protocol.cpp        CXL Type 2 snoop protocol test
  type2_snoop_test.cpp            Snoop interaction test
  gemm_realdev_bench.cpp          Real-device GEMM benchmark
  cira_hw_test.cpp                CIRA hardware integration test
  phase1_validation.cpp           Phase 1 hardware validation
  kernel_loader.cpp / .h          Kernel binary loader utility
  sim_main.cpp                    Simulation entry point
  tb_vortex_gpu_wrapper.sv        Vortex GPU wrapper testbench

scripts/
  bana_ci.sh                      CI script
  generate_benchmark_results.py   Benchmark result post-processing

docs/
  OPTIMIZATION_GUIDE.md           Performance tuning guide
  WORKLOAD_PORTING_GUIDE.md       Porting workloads to CIRA/FPGA
  LLAMA_CXL_TESTING_GUIDE.md      LLaMA CXL testing guide
  PHASE3_FPGA_DEPLOYMENT.md       FPGA deployment notes
  (+ additional session summaries and status reports)
```
