// Vortex GPU Configuration for FireSim CXL Integration
// Optimized for Intel Agilex 7 FPGA with CXL Type-2
// Target: Initial bringup with reduced resource usage

`ifndef VX_CONFIG_FIRESIM_VH
`define VX_CONFIG_FIRESIM_VH

// Core Configuration - Start with minimal config for bringup
`define NUM_CLUSTERS    1
`define NUM_CORES       4
`define NUM_WARPS       8
`define NUM_THREADS     32
`define NUM_BARRIERS    4

// Memory Configuration
`define MEM_BLOCK_SIZE  64
`define MEM_ADDR_WIDTH  64
`define MEM_DATA_WIDTH  512  // Match CAFU AXI width

// Cache Configuration
`define DCACHE_ENABLE
`define ICACHE_ENABLE
`define L1_LINE_SIZE    64
`define L2_ENABLE
`define L2_LINE_SIZE    64

// ISA Extensions
`define EXT_M_ENABLE    // Multiply/Divide
`define EXT_F_ENABLE    // Single-precision FP
`define EXT_D_ENABLE    // Double-precision FP

// Disable optional features for initial bringup
// `define EXT_TEX_ENABLE  // Texture unit
// `define EXT_OM_ENABLE   // Output merger
// `define EXT_RASTER_ENABLE // Rasterizer
`undef EXT_TCU_ENABLE   // Tensor Core Unit (not needed)

// Performance Features
`define PERF_ENABLE
`define GBAR_ENABLE     // Global barriers
`define SM_ENABLE       // Shared memory

// FPGA Optimizations
`define SYNTHESIS
`define FPGA_ALTERA
`define QUARTUS

// Debug (disable for production)
// `define DBG_TRACE_CORE_PIPELINE
// `define DBG_TRACE_MEM

`endif // VX_CONFIG_FIRESIM_VH
