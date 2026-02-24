/**
 * sim_main.cpp
 * Verilator simulation main for Vortex GPU Wrapper
 * Uses external clock driving for reliable simulation
 */

#include <verilated.h>
#include <verilated_fst_c.h>
#include <memory>
#include <cstdio>

// Include the Verilator-generated header
#include "Vtb_vortex_gpu_wrapper.h"

// Simulation parameters
constexpr uint64_t MAX_SIM_TIME = 100000;  // Maximum simulation cycles
constexpr bool ENABLE_TRACE = true;

int main(int argc, char** argv) {
    // Initialize Verilator context
    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    contextp->commandArgs(argc, argv);
    contextp->traceEverOn(ENABLE_TRACE);

    // Create DUT instance
    const std::unique_ptr<Vtb_vortex_gpu_wrapper> dut{new Vtb_vortex_gpu_wrapper{contextp.get()}};

    // Create trace file
    std::unique_ptr<VerilatedFstC> trace;
    if (ENABLE_TRACE) {
        trace.reset(new VerilatedFstC);
        dut->trace(trace.get(), 99);  // Trace 99 levels of hierarchy
        trace->open("trace.fst");
        printf("Trace enabled: trace.fst\n");
    }

    printf("========================================\n");
    printf("Vortex GPU Wrapper Verilator Simulation\n");
    printf("========================================\n");

    // Main simulation loop - drive clock externally
    // Clock period is 4 time units (2 units high, 2 units low)
    while (!contextp->gotFinish() && contextp->time() < MAX_SIM_TIME) {
        contextp->timeInc(1);
        dut->eval();

        if (trace) {
            trace->dump(contextp->time());
        }
    }

    // Final evaluation
    dut->final();

    printf("\nSimulation completed at time %lu\n", contextp->time());

    // Cleanup
    if (trace) {
        trace->close();
    }

    return 0;
}
