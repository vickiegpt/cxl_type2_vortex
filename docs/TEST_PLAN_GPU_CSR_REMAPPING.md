# GPU CSR Remapping Test Plan

**Date:** March 23, 2026
**Objective:** Verify that GPU CSR registers are accessible through BAR0+0x080000-0x08013C address range via address remapping

## Overview

The GPU CSR registers (KERNEL_ADDR, GRID_DIM_X, etc.) are implemented at vendor CSR addresses 0x000100-0x00013C in `ex_default_csr_avmm_slave.sv`.

The remapping logic in `ed_top_wrapper_typ2.sv` converts BAR0+0x080000-0x08FFFF accesses to 0x000000-0x0000FFFF, enabling GPU CSR access at BAR0+0x080000-0x08013C.

## Test Execution Flow

### Phase 1: CSR Read/Write Verification (simple_csr_test)
**File:** `tests/simple_csr_test.cpp`

Test basic CSR operations:
1. Read GRID_DIM_X register (offset 0x110)
   - Expected: 0x00000001 (default value after reset)
2. Write GRID_DIM_X = 0x42
3. Read back GRID_DIM_X
   - Expected: 0x00000042 ✓ PASS if non-zero
4. Test GRID_DIM_Y, GRID_DIM_Z similar writes
5. Test LAUNCH register write (pulse trigger)

**Command:**
```bash
cd /root/ia780i_type2_delay_buffer
sudo ./tests/simple_csr_test
```

**Success Criteria:**
- All CSR reads return non-zero values (not 0x00000000)
- CSR writes stick (readback matches written value)
- No hang or crash

### Phase 2: Kernel Launch via CSR (test_kernel_launch)
**File:** `tests/test_kernel_launch`

Verify kernel launch mechanism still works with remapped CSR:
```bash
sudo ./tests/test_kernel_launch
```

**Expected:** 3/3 tests pass (DCOH completion signaling is already verified)

### Phase 3: GPU GEMM Kernel Loading (gemm_with_loader)
**File:** `tests/gemm_with_loader`

Load real GPU kernel and verify execution:
```bash
# First check if kernels directory exists
ls -la kernels/
sudo ./tests/gemm_with_loader
```

**Success Criteria:**
- Kernel loads without error
- GEMM kernel executes (status becomes DONE)
- Performance metrics printed

### Phase 4: Type2 Snoop with Real Kernel (type2_snoop_test)
**File:** `tests/type2_snoop_test`

Verify snoop coherency with real GPU computation:
```bash
sudo ./tests/type2_snoop_test
```

**Success Criteria:**
- All 14 snoop tests pass
- Snoop latency measurements valid

### Phase 5: Comprehensive GEMM Benchmark
**File:** `tests/gemm_realdev_bench`

Run full performance benchmark:
```bash
sudo ./tests/gemm_realdev_bench 2>&1 | tee gemm_realdev_bench_$(date +%s).log
```

**Success Criteria:**
- GEMM operations complete successfully
- Performance within expected range
- Type2 snoop coherency maintained

## Rollback Plan

If tests fail with remapping enabled:
1. Revert ed_top_wrapper_typ2.sv changes (git checkout)
2. Recompile previous bitstream
3. Diagnose root cause

## Notes

- Bitstream compilation takes ~57 minutes
- Flash to FPGA takes ~10 minutes
- Each test phase takes 1-5 minutes
- Full test cycle: ~3-4 hours
- Tests must run as root (GPU CSR via /dev/mem)
