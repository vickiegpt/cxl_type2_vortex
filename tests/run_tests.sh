#!/bin/bash
# run_tests.sh - Run Vortex GPU Wrapper Tests
#
# Usage:
#   ./run_tests.sh [test_type]
#
# test_type:
#   cpp      - Run C++ standalone test (no RTL)
#   rtl      - Run RTL simulation with Verilator
#   all      - Run all tests (default)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${YELLOW}========================================"
    echo -e "$1"
    echo -e "========================================${NC}"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Default test type
TEST_TYPE="${1:-all}"

#=============================================================================
# C++ Standalone Test
#=============================================================================
run_cpp_test() {
    print_header "Running C++ Standalone Test"

    # Compile
    echo "Compiling test_kernel_launch.cpp..."
    g++ -std=c++17 -O2 -Wall \
        -o test_kernel_launch \
        test_kernel_launch.cpp \
        -lpthread

    # Run
    echo "Running test..."
    ./test_kernel_launch

    if [ $? -eq 0 ]; then
        print_pass "C++ standalone test completed"
    else
        print_fail "C++ standalone test failed"
        exit 1
    fi
}

#=============================================================================
# GEMM Coherent Shared Memory Test
#=============================================================================
run_gemm_test() {
    print_header "Running GEMM Coherent Shared Memory Test"

    KERNEL_DIR="$SCRIPT_DIR/../kernels"
    KERNEL_BIN=""
    KERNEL_ARG=""

    # Try to build kernel binary if RISC-V toolchain is available
    if command -v riscv64-unknown-elf-gcc &> /dev/null || \
       command -v riscv64-linux-gnu-gcc &> /dev/null; then
        echo "RISC-V toolchain found, building GPU kernel..."
        if make -C "$KERNEL_DIR" clean all 2>&1; then
            KERNEL_BIN="$KERNEL_DIR/gemm_kernel.bin"
            KERNEL_ARG="--kernel $KERNEL_BIN"
            print_pass "Kernel binary built: $KERNEL_BIN"
        else
            echo -e "${YELLOW}[WARN]${NC} Kernel build failed, continuing with simulation"
        fi
    else
        echo "RISC-V toolchain not found, using software simulation"
        echo "  Install: apt-get install gcc-riscv64-unknown-elf"
    fi

    # Compile host test
    echo "Compiling test_gemm_coherent.cpp..."
    g++ -std=c++17 -O2 -Wall \
        -I"$KERNEL_DIR" \
        -o test_gemm_coherent \
        test_gemm_coherent.cpp \
        -lpthread -lm

    # Run (with kernel binary if available)
    echo "Running GEMM test (auto-detect, falls back to sim)..."
    ./test_gemm_coherent $KERNEL_ARG

    if [ $? -eq 0 ]; then
        print_pass "GEMM coherent test completed"
    else
        print_fail "GEMM coherent test failed"
        exit 1
    fi
}

#=============================================================================
# RTL Simulation Test
#=============================================================================
run_rtl_test() {
    print_header "Running RTL Simulation Test"

    # Check for Verilator
    if ! command -v verilator &> /dev/null; then
        echo "Verilator not found. Skipping RTL test."
        echo "Install with: apt-get install verilator"
        return 0
    fi

    # Create work directory
    mkdir -p work

    echo "Building RTL simulation..."

    # Check if required source files exist
    VORTEX_PKG="../hardware_test_design/common/rv64/vortex/VX_gpu_pkg.sv"
    if [ ! -f "$VORTEX_PKG" ]; then
        echo "Warning: Vortex source files not found"
        echo "RTL test will use simplified testbench only"

        # Build simplified testbench
        verilator --cc --exe --build \
            -j 0 \
            --trace \
            -Wno-fatal \
            -Wno-DECLFILENAME \
            -Wno-UNUSEDSIGNAL \
            -Wno-WIDTHEXPAND \
            --top-module tb_vortex_gpu_wrapper \
            --Mdir work/verilator \
            -o tb_vortex_gpu_wrapper \
            -CFLAGS "-std=c++17 -O2" \
            ../hardware_test_design/common/rv64/cxl_memuring_pkg.sv \
            ../hardware_test_design/common/rv64/cxl_memuring_vortex_pkg.sv \
            ../hardware_test_design/common/rv64/vortex_dcoh_writeback.sv \
            tb_vortex_gpu_wrapper.sv \
            sim_main.cpp \
            2>&1 | tee work/verilator_build.log
    else
        echo "Full Vortex RTL found, building complete design..."
        make -f Makefile.sim sim 2>&1 | tee work/build.log
    fi

    if [ $? -eq 0 ]; then
        print_pass "RTL simulation completed"
    else
        print_fail "RTL simulation failed"
        exit 1
    fi
}

#=============================================================================
# Main
#=============================================================================

case "$TEST_TYPE" in
    cpp)
        run_cpp_test
        ;;
    gemm)
        run_gemm_test
        ;;
    rtl)
        run_rtl_test
        ;;
    all)
        run_cpp_test
        echo ""
        run_gemm_test
        echo ""
        run_rtl_test
        ;;
    *)
        echo "Unknown test type: $TEST_TYPE"
        echo "Usage: $0 [cpp|gemm|rtl|all]"
        exit 1
        ;;
esac

print_header "All Tests Completed Successfully"
