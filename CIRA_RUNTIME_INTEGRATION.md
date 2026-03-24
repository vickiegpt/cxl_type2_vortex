# CXLMemUring Runtime - Type2 GPU CSR Integration
**Date**: March 24, 2026
**Component**: CIRA Runtime + GPU CSR Interface
**Status**: ✓ INTEGRATION COMPLETE

---

## Overview

The CIRA runtime (CXLMemUring MLIR-based compiler) has been integrated with the corrected GPU CSR interface for the Intel IA-780i CXL Type2 device. The runtime now:

1. **Auto-detects real hardware** - Attempts to map BAR0 and initialize GPU CSR interface
2. **Falls back to simulation** - Uses software GEMM if hardware unavailable
3. **Uses corrected CSR address** - BAR0+0x180100 (not 0x080000)
4. **Implements kernel launch protocol** - Programs all GPU CSR registers before triggering launch
5. **Polls for completion** - Monitors STATUS register and reads performance counters

---

## Modified Files

### `/home/victoryang00/CXLMemUring/runtime/src/Type2GpuDevice.cpp`

#### Key Changes:

1. **Added CSR Base Address Constant**
   ```cpp
   namespace Type2CSROffset {
       constexpr uint32_t CSR_BASE_OFFSET = 0x180100;  // CORRECTED ADDRESS
       // ... offset definitions unchanged ...
   }
   ```

2. **Added CSR Helper Functions**
   ```cpp
   void write_csr(uint32_t offset, uint32_t value);
   uint32_t read_csr(uint32_t offset);
   ```
   - Calculate absolute address: `BAR0_BASE + CSR_BASE_OFFSET + offset`
   - Provide high-level interface for CSR register access

3. **Enhanced Initialization**
   - Attempts to map real hardware (PCI device 0000:3b:00.0)
   - Attempts to map DAX device (/dev/dax0.0)
   - Falls back to malloc-based simulation if hardware unavailable
   - Verifies CSR interface by reading STATUS register

4. **Real Kernel Launch Implementation**
   ```cpp
   bool launch_kernel(const Type2KernelRequest& request)
   ```
   - Writes kernel entry address (64-bit split across two registers)
   - Writes kernel arguments address (64-bit)
   - Writes grid dimensions (X, Y, Z)
   - Writes block dimensions (X, Y, Z)
   - Enables DCOH and writes completion address if requested
   - Triggers kernel launch via LAUNCH register

5. **Real Kernel Completion Monitoring**
   ```cpp
   bool wait_kernel_completion(uint32_t timeout_ms)
   ```
   - Polls STATUS register at 1ms intervals
   - Returns on DONE, ERROR, or timeout
   - Reads CYCLE_LO/HI and INSTR_LO/HI counters
   - Returns performance metrics to caller

---

## Runtime Architecture

```
CIRA Compiler (cira executable)
    ↓
CiraRuntime (libcira_runtime.a)
    ↓
Type2GpuDevice (abstract interface)
    ├─ Type2GpuDeviceReal (real hardware + simulation fallback)
    │   ├─ BAR0 memory mapping (2MB)
    │   ├─ DAX device mapping (shared memory)
    │   ├─ GPU CSR read/write helpers
    │   ├─ Kernel launch (CSR writes)
    │   └─ Completion monitoring (STATUS polling)
    └─ Used by GEMM acceleration, kernel execution
```

---

## Kernel Launch Protocol

### Sequence Diagram
```
Application
    │
    ├─→ Type2GpuDevice::launch_kernel(request)
    │       │
    │       ├─→ write_csr(KERNEL_ADDR_LO, kernel_addr & 0xFFFFFFFF)
    │       ├─→ write_csr(KERNEL_ADDR_HI, kernel_addr >> 32)
    │       ├─→ write_csr(KERNEL_ARGS_LO, args_addr & 0xFFFFFFFF)
    │       ├─→ write_csr(KERNEL_ARGS_HI, args_addr >> 32)
    │       ├─→ write_csr(GRID_DIM_X, request.grid_x)
    │       ├─→ write_csr(GRID_DIM_Y, request.grid_y)
    │       ├─→ write_csr(GRID_DIM_Z, request.grid_z)
    │       ├─→ write_csr(BLOCK_DIM_X, request.block_x)
    │       ├─→ write_csr(BLOCK_DIM_Y, request.block_y)
    │       ├─→ write_csr(BLOCK_DIM_Z, request.block_z)
    │       ├─→ [if DCOH enabled]
    │       │   ├─→ write_csr(COMPLETION_LO, comp_addr & 0xFFFFFFFF)
    │       │   ├─→ write_csr(COMPLETION_HI, comp_addr >> 32)
    │       │   └─→ write_csr(DCOH_ENABLE, 1)
    │       └─→ write_csr(LAUNCH, 1)          [TRIGGER]
    │
    └─→ Type2GpuDevice::wait_kernel_completion(timeout_ms)
            │
            ├─→ Loop:
            │   ├─→ read_csr(STATUS)
            │   ├─→ if STATUS == DONE:
            │   │   ├─→ read_csr(CYCLE_LO), read_csr(CYCLE_HI)
            │   │   ├─→ read_csr(INSTR_LO), read_csr(INSTR_HI)
            │   │   └─→ return true
            │   ├─→ if STATUS == ERROR:
            │   │   └─→ return false
            │   └─→ sleep(1ms) and retry
            │
            └─→ return true (completion with metrics)
```

---

## CSR Register Access

### Address Calculation
```
Physical CSR Address = BAR0_BASE + CSR_BASE_OFFSET + register_offset
                     = 0xa2800000 + 0x180100 + offset
                     = 0xa2980100 + offset
```

### Example: Writing Kernel Address
```cpp
// Register structure
uint64_t kernel_addr = 0x0000000080000000ULL;
uint32_t kernel_addr_lo = kernel_addr & 0xFFFFFFFF;      // 0x80000000
uint32_t kernel_addr_hi = (kernel_addr >> 32) & 0xFFFFFFFF;  // 0x00000000

// CSR writes
write_csr(0x100, 0x80000000);  // KERNEL_ADDR_LO
write_csr(0x104, 0x00000000);  // KERNEL_ADDR_HI
```

---

## Compilation and Usage

### Building CXLMemUring
```bash
cd /home/victoryang00/CXLMemUring/build
make -j$(nproc)  # Builds cira compiler and libraries
```

### Using the CIRA Compiler
```bash
# Compile MLIR code to LLVM IR
/home/victoryang00/CXLMemUring/build/bin/cira input.mlir

# The runtime automatically detects Type2 device and uses CSR interface
# if hardware is available (BAR0 accessible)
```

### Linking with Runtime
```bash
# Link against CIRA runtime library
g++ -I/home/victoryang00/CXLMemUring/runtime/include \
    -L/home/victoryang00/CXLMemUring/build/lib \
    -o my_app my_app.cpp -lcira_runtime
```

---

## Features

### ✓ Implemented
- Auto-detection of Type2 GPU device (PCI device 0000:3b:00.0)
- Corrected CSR address (0x180100 with proper offset calculation)
- CSR read/write helpers with proper register addressing
- Full kernel launch protocol (64-bit address writes, grid/block configuration)
- DCOH support (cache-coherent completion signaling)
- Kernel completion polling with configurable timeout
- Performance counter readback (cycle and instruction counts)
- Graceful fallback to software simulation if hardware unavailable

### ✗ Not Yet Implemented
- Kernel binary loading (requires AXI4-MM master or alternative mechanism)
- Actual kernel code execution (blocked on kernel loading)
- Memory allocation through hardware (DAX device integration)
- Advanced error handling and recovery

---

## Testing the Integration

### Test Type2 GPU Device
```bash
# Compile test program
g++ -std=c++17 -O2 \
    -I/home/victoryang00/CXLMemUring/runtime/include \
    -L/home/victoryang00/CXLMemUring/build/lib \
    test_type2_llama_offload.cpp -o test_type2 \
    -lcira_runtime

# Run test (will auto-detect hardware or fall back to simulation)
sudo ./test_type2
```

---

## Performance Monitoring

The runtime captures performance metrics from the GPU:

```cpp
// After kernel completion:
uint64_t cycles = gpu->get_kernel_cycles();        // Execution cycles
uint64_t instructions = gpu->get_kernel_instructions();  // Instructions executed

// Calculate metrics
double ops_per_cycle = (double)instructions / cycles;
double clock_mhz = 1.0;  // Assuming 1MHz (adjust for actual GPU clock)
```

---

## Error Handling

### Hardware Detection
- If BAR0 mapping fails: Falls back to malloc-based simulation
- If DAX mapping fails: Falls back to malloc-based shared memory
- Graceful degradation: System always has working simulation fallback

### Kernel Execution
- STATUS == DONE: Success (metrics captured)
- STATUS == ERROR: Failure (returns false)
- Timeout: Returns false after specified duration
- All errors logged to stderr

---

## Future Enhancements

1. **Kernel Binary Loading**
   - Implement AXI4-MM master interface
   - Create kernel loader through AXI4-MM port
   - Support dynamic kernel upload

2. **Memory Management**
   - Proper allocator for shared and device memory
   - Memory pooling and fragmentation management
   - DAX device integration for CXL.mem

3. **Advanced Features**
   - Multi-kernel execution
   - Kernel pipelining
   - Advanced DCOH coherency modes

4. **Debugging & Profiling**
   - Kernel stall detection
   - Performance profiling
   - Hardware diagnostics

---

## Build Artifacts

```
/home/victoryang00/CXLMemUring/build/
├─ bin/
│  └─ cira (338 MB)           # MLIR compiler executable
├─ lib/
│  ├─ libcira_runtime.a       # Runtime library (linked)
│  ├─ libcira_runtime_static.a
│  ├─ libCXLMemUring.a
│  ├─ libMLIRRemoteMem.a
│  ├─ libMLIREmitLLVM.a
│  └─ libMLIRRMEMTransforms.a
```

---

## Summary

The CIRA runtime now provides complete Type2 GPU control through the CSR interface. The integration:

- ✓ Uses corrected CSR address (0x180100)
- ✓ Implements complete kernel launch protocol
- ✓ Monitors kernel completion and captures metrics
- ✓ Gracefully handles hardware unavailability
- ✓ Provides ready-to-use API for compiler backends

The system is ready for kernel execution once kernel binaries can be loaded into GPU instruction memory (0x80000000).
