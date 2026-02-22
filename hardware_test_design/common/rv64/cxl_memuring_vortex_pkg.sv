// cxl_memuring_vortex_pkg.sv
// CXLMemUring Vortex GPU Extensions
//
// This package extends cxl_memuring_pkg with Vortex GPU-specific
// descriptor fields, CSRs, and helper functions.

`ifndef CXL_MEMURING_VORTEX_PKG_SV
`define CXL_MEMURING_VORTEX_PKG_SV

`include "cxl_memuring_pkg.sv"

package cxl_memuring_vortex_pkg;

    import cxl_memuring_pkg::*;

    // ============================================================================
    // Vortex GPU Parameters
    // ============================================================================

    parameter int VORTEX_NUM_SMS = 4;           // Number of streaming multiprocessors
    parameter int VORTEX_CORES_PER_SM = 4;      // SIMT cores per SM
    parameter int VORTEX_WARP_SIZE = 32;        // Threads per warp
    parameter int VORTEX_MAX_WARPS_PER_SM = 8;  // Max warps per SM
    parameter int VORTEX_L1_SIZE = 16384;       // L1 cache size per SM (16KB)
    parameter int VORTEX_L2_SIZE = 262144;      // L2 cache size (256KB)
    parameter int VORTEX_SHARED_MEM_SIZE = 32768; // Shared memory per SM (32KB)

    // Derived parameters
    parameter int VORTEX_TOTAL_CORES = VORTEX_NUM_SMS * VORTEX_CORES_PER_SM; // 16
    parameter int VORTEX_MAX_THREADS = VORTEX_NUM_SMS * VORTEX_CORES_PER_SM *
                                        VORTEX_WARP_SIZE * VORTEX_MAX_WARPS_PER_SM; // 4096

    // ============================================================================
    // Vortex CSR Registers (extend BAR0 address map)
    // ============================================================================

    // Vortex capability registers (read-only)
    // NOTE: Relocated to 0x300+ to avoid conflicts with cxl_memuring_pkg CSR space
    localparam logic [11:0] CSR_VX_NUM_SM           = 12'h300;
    localparam logic [11:0] CSR_VX_NUM_CORES_PER_SM = 12'h304;
    localparam logic [11:0] CSR_VX_WARP_SIZE        = 12'h308;
    localparam logic [11:0] CSR_VX_MAX_THREADS      = 12'h30C;
    localparam logic [11:0] CSR_VX_L1_CACHE_SIZE    = 12'h310;
    localparam logic [11:0] CSR_VX_L2_CACHE_SIZE    = 12'h314;
    localparam logic [11:0] CSR_VX_SHARED_MEM_SIZE  = 12'h318;

    // Vortex configuration registers
    localparam logic [11:0] CSR_VX_SCHED_MODE       = 12'h320;  // Scheduler mode
    localparam logic [11:0] CSR_VX_STREAM_MAP       = 12'h324;  // Queue->Stream mapping
    localparam logic [11:0] CSR_VX_PORT_AFFINITY    = 12'h328;  // Default port affinity
    localparam logic [11:0] CSR_VX_KERNEL_ENTRY     = 12'h32C;  // Kernel entry point
    localparam logic [11:0] CSR_VX_CONST_BASE       = 12'h330;  // Constant memory base
    localparam logic [11:0] CSR_VX_CONST_SIZE       = 12'h338;  // Constant memory size

    // Vortex runtime registers
    localparam logic [11:0] CSR_VX_KERNEL_START     = 12'h340;  // Write 1 to launch
    localparam logic [11:0] CSR_VX_KERNEL_DONE      = 12'h344;  // Kernel completion
    localparam logic [11:0] CSR_VX_GRID_DIM_X       = 12'h348;  // Grid dimension X
    localparam logic [11:0] CSR_VX_GRID_DIM_Y       = 12'h34C;  // Grid dimension Y
    localparam logic [11:0] CSR_VX_GRID_DIM_Z       = 12'h350;  // Grid dimension Z
    localparam logic [11:0] CSR_VX_BLOCK_DIM_X      = 12'h354;  // Block dimension X
    localparam logic [11:0] CSR_VX_BLOCK_DIM_Y      = 12'h358;  // Block dimension Y
    localparam logic [11:0] CSR_VX_BLOCK_DIM_Z      = 12'h35C;  // Block dimension Z
    localparam logic [11:0] CSR_VX_KERNEL_PARAM_PTR = 12'h360;  // Kernel parameters
    localparam logic [11:0] CSR_VX_SHARED_MEM_ALLOC = 12'h368;  // Allocated shared mem

    // Vortex performance counters
    localparam logic [11:0] CSR_VX_PERF_CYCLES          = 12'h380;
    localparam logic [11:0] CSR_VX_PERF_COMPUTE_CYCLES  = 12'h388;
    localparam logic [11:0] CSR_VX_PERF_IDLE_CYCLES     = 12'h390;
    localparam logic [11:0] CSR_VX_PERF_MEMORY_STALLS   = 12'h398;
    localparam logic [11:0] CSR_VX_PERF_WARP_DIVERGENCE = 12'h3A0;
    localparam logic [11:0] CSR_VX_PERF_L1_HITS         = 12'h3A8;
    localparam logic [11:0] CSR_VX_PERF_L1_MISSES       = 12'h3B0;
    localparam logic [11:0] CSR_VX_PERF_L2_HITS         = 12'h3B8;
    localparam logic [11:0] CSR_VX_PERF_L2_MISSES       = 12'h3C0;
    localparam logic [11:0] CSR_VX_PERF_AXI_READS       = 12'h3C8;
    localparam logic [11:0] CSR_VX_PERF_AXI_WRITES      = 12'h3D0;

    // ============================================================================
    // Vortex Scheduler Modes
    // ============================================================================

    typedef enum logic [7:0] {
        VX_SCHED_FIFO       = 8'h00,  // First-in-first-out
        VX_SCHED_ROUND_ROBIN = 8'h01,  // Round robin
        VX_SCHED_PRIORITY   = 8'h02   // Priority-based
    } vx_sched_mode_e;

    // ============================================================================
    // Vortex GPU Extension Flags
    // ============================================================================

    // Add to existing sqe_flags_t
    typedef struct packed {
        logic sync;           // Bit 0
        logic fence;          // Bit 1
        logic notify;         // Bit 2
        logic async;          // Bit 3
        logic prefetch_en;    // Bit 4
        logic fault_tolerant; // Bit 5
        logic use_gpu;        // Bit 6: Route to Vortex GPU
        logic reserved;       // Bit 7
    } sqe_flags_vx_t;

    // ============================================================================
    // Vortex Extended Submission Queue Entry (256 bytes)
    // ============================================================================

    typedef struct packed {
        // ===== Common Fields (160 bytes) =====
        // Header (16 bytes)
        opcode_e      opcode;
        sqe_flags_vx_t flags;          // Extended flags
        logic [15:0]  kernel_id;       // Kernel ID for multi-kernel support
        logic [31:0]  sched_priority;  // Scheduling priority
        logic [63:0]  user_data;

        // Memory pointers (64 bytes)
        logic [63:0]  base_ptr;        // A[] base
        logic [63:0]  index_ptr;       // B[] index array
        logic [63:0]  out_ptr;         // Output buffer
        logic [63:0]  cond_ptr;        // C[] condition data
        logic [63:0]  aux_ptr_0;       // D[] auxiliary
        logic [63:0]  aux_ptr_1;       // E[] auxiliary
        logic [63:0]  aux_ptr_2;       // F[] auxiliary
        logic [63:0]  aux_ptr_3;       // G[] auxiliary

        // Access pattern (32 bytes)
        cond_op_e     cond_op;
        logic [23:0]  reserved_cond;
        logic [31:0]  threshold;       // Threshold (float/int bitcast)
        logic [31:0]  func_op;         // Function operation
        logic [31:0]  func_arg;        // Function argument

        // Loop specification (32 bytes)
        logic [31:0]  loop_i_beg;
        logic [31:0]  loop_i_end;
        logic [31:0]  loop_i_stride;
        logic [31:0]  reserved_loop_i;
        logic [63:0]  loop_j_ptr;      // CSR-style pointer
        logic [31:0]  loop_k_beg;
        logic [31:0]  loop_k_end;

        // Element metadata (16 bytes)
        logic [15:0]  elem_sz;
        logic [15:0]  stride;
        logic [31:0]  mte_tag;
        logic [63:0]  completion_addr;

        // ===== GPU-Specific Fields (64 bytes) =====
        // Grid configuration (16 bytes)
        logic [15:0]  grid_x;
        logic [15:0]  grid_y;
        logic [15:0]  grid_z;
        logic [15:0]  reserved_grid;
        logic [63:0]  grid_reserved;

        // Block configuration (16 bytes)
        logic [15:0]  block_x;
        logic [15:0]  block_y;
        logic [15:0]  block_z;
        logic [15:0]  reserved_block;
        logic [63:0]  block_reserved;

        // Memory configuration (16 bytes)
        logic [31:0]  shared_mem_bytes;
        logic [31:0]  l1_cache_hint;   // 0=default, 1=prefer shared, 2=prefer L1
        logic [31:0]  port_affinity;   // 0=auto, 1=Port0, 2=Port1
        logic [31:0]  reserved_mem;

        // Kernel parameters (16 bytes)
        logic [63:0]  kernel_param_ptr;
        logic [31:0]  kernel_param_size;
        logic [31:0]  stream_event;

        // ===== Reserved (32 bytes) =====
        logic [255:0] reserved;

    } sqe_vx_t;

    // ============================================================================
    // Vortex Kernel Parameter Block
    // ============================================================================

    // This structure is allocated in device memory and pointed to by kernel_param_ptr
    typedef struct packed {
        // Packed descriptor fields for GPU kernel consumption
        logic [63:0]  base_ptr;
        logic [63:0]  index_ptr;
        logic [63:0]  out_ptr;
        logic [63:0]  cond_ptr;
        logic [63:0]  aux_ptr_0;
        logic [63:0]  aux_ptr_1;

        logic [31:0]  loop_i_beg;
        logic [31:0]  loop_i_end;
        logic [31:0]  loop_i_stride;
        logic [31:0]  threshold;
        logic [31:0]  func_op;
        logic [31:0]  elem_sz;

        logic [127:0] reserved;
    } vx_kernel_params_t; // 128 bytes

    // ============================================================================
    // Vortex GPU Capabilities
    // ============================================================================

    typedef struct packed {
        logic [15:0]  num_sms;
        logic [15:0]  num_cores_per_sm;
        logic [15:0]  warp_size;
        logic [15:0]  max_warps_per_sm;
        logic [31:0]  max_threads;
        logic [31:0]  l1_cache_size;
        logic [31:0]  l2_cache_size;
        logic [31:0]  shared_mem_size;
        logic [127:0] reserved;
    } vx_capabilities_t; // 64 bytes

    // ============================================================================
    // Vortex Kernel Arguments (for kernel launcher interface)
    // ============================================================================

    typedef struct packed {
        logic [63:0] pc_start;          // Kernel entry point
        logic [31:0] num_warps;         // Number of warps to launch
        logic [31:0] num_threads;       // Total threads
        logic [15:0] grid_x, grid_y, grid_z;
        logic [15:0] block_x, block_y, block_z;
        logic [63:0] kernel_param_ptr;  // Pointer to kernel parameters
    } vortex_kernel_args_t;

    // ============================================================================
    // Vortex Performance Counters
    // ============================================================================

    typedef struct packed {
        logic [63:0] cycles;            // Execution cycles
        logic [63:0] instrs;            // Instructions executed
        logic [63:0] mem_reads;         // Memory read operations
        logic [63:0] mem_writes;        // Memory write operations
        logic [63:0] cache_hits;        // Cache hits
        logic [63:0] cache_misses;      // Cache misses
        logic [63:0] branch_taken;      // Branches taken
        logic [63:0] branch_not_taken;  // Branches not taken
    } vortex_perf_counters_t;

    // ============================================================================
    // Helper Functions (Vortex Extensions)
    // ============================================================================

    // Calculate total number of threads in grid
    function automatic logic [31:0] calc_total_threads(sqe_vx_t sqe);
        logic [31:0] total;
        total = sqe.grid_x * sqe.grid_y * sqe.grid_z *
                sqe.block_x * sqe.block_y * sqe.block_z;
        return total;
    endfunction

    // Calculate number of warps
    function automatic logic [31:0] calc_num_warps(sqe_vx_t sqe);
        logic [31:0] total_threads;
        total_threads = calc_total_threads(sqe);
        return (total_threads + VORTEX_WARP_SIZE - 1) / VORTEX_WARP_SIZE;
    endfunction

    // Validate GPU descriptor
    function automatic logic is_valid_vx_sqe(sqe_vx_t sqe);
        // Check basic validity
        if (sqe.opcode == OPCODE_NOP) return 1'b1;

        // Check GPU-specific fields
        if (sqe.flags.use_gpu) begin
            // Grid dimensions must be non-zero
            if (sqe.grid_x == 0 || sqe.block_x == 0) return 1'b0;

            // Total threads must not exceed max
            if (calc_total_threads(sqe) > VORTEX_MAX_THREADS) return 1'b0;

            // Shared memory must fit
            if (sqe.shared_mem_bytes > VORTEX_SHARED_MEM_SIZE) return 1'b0;
        end

        return 1'b1;
    endfunction

    // Determine optimal grid size for given N elements
    function automatic logic [15:0] calc_optimal_grid_x(logic [31:0] N, logic [15:0] block_x);
        return (N + block_x - 1) / block_x;
    endfunction

    // Check if address should route to CAFU Port0 (Host) or Port1 (Device)
    function automatic logic route_to_host_mem(logic [63:0] addr, logic [31:0] port_affinity);
        if (port_affinity == 1) return 1'b1;      // Force Port0
        if (port_affinity == 2) return 1'b0;      // Force Port1
        return addr[40];                          // Auto: check address bit
    endfunction

    // Calculate memory footprint for GPU kernel
    function automatic logic [63:0] calc_vx_memory_footprint(sqe_vx_t sqe);
        logic [63:0] total_threads;
        logic [63:0] footprint;

        total_threads = calc_total_threads(sqe);
        footprint = total_threads * sqe.elem_sz;

        // Add shared memory
        footprint += sqe.shared_mem_bytes * sqe.grid_x * sqe.grid_y * sqe.grid_z;

        return footprint;
    endfunction

    // Determine if kernel has divergent branches (heuristic)
    function automatic logic has_divergence(sqe_vx_t sqe);
        // If condition is ALWAYS, no divergence
        if (sqe.cond_op == COND_ALWAYS) return 1'b0;

        // If using conditional operations, likely divergence
        return 1'b1;
    endfunction

    // Calculate expected L1 cache pressure
    function automatic logic [31:0] calc_l1_pressure(sqe_vx_t sqe);
        logic [63:0] working_set;
        logic [31:0] pressure;

        // Estimate working set size per SM
        working_set = calc_total_threads(sqe) / VORTEX_NUM_SMS * sqe.elem_sz;

        // Pressure = working_set / L1_size (as percentage)
        pressure = (working_set * 100) / VORTEX_L1_SIZE;

        return pressure;
    endfunction

    // Recommend cache hint based on access pattern
    function automatic logic [31:0] recommend_cache_hint(sqe_vx_t sqe);
        logic [31:0] pressure;
        pressure = calc_l1_pressure(sqe);

        if (pressure > 150) begin
            return 2;  // Prefer L1 (data exceeds shared mem capacity)
        end else if (pressure < 50) begin
            return 1;  // Prefer shared memory (data fits comfortably)
        end else begin
            return 0;  // Default
        end
    endfunction

    // ============================================================================
    // Vortex Kernel Opcodes (Embedded in func_op field)
    // ============================================================================

    typedef enum logic [31:0] {
        VX_FUNC_INDIRECT_LOAD       = 32'h0000,  // A[B[i]]
        VX_FUNC_CONDITIONAL_LOAD    = 32'h0001,  // if (C[i] > thresh) A[i]
        VX_FUNC_NESTED_INDIRECT     = 32'h0002,  // A[B[C[i]]]
        VX_FUNC_GATHER_SCATTER      = 32'h0003,  // Gather + scatter
        VX_FUNC_REDUCTION_SUM       = 32'h0010,  // Sum reduction
        VX_FUNC_REDUCTION_MAX       = 32'h0011,  // Max reduction
        VX_FUNC_REDUCTION_MIN       = 32'h0012,  // Min reduction
        VX_FUNC_GRAPH_BFS           = 32'h0020,  // Graph BFS
        VX_FUNC_GRAPH_DFS           = 32'h0021,  // Graph DFS
        VX_FUNC_SPMV_CSR            = 32'h0030,  // SpMV (CSR format)
        VX_FUNC_SPMV_COO            = 32'h0031,  // SpMV (COO format)
        VX_FUNC_CUSTOM_0            = 32'h1000,  // User-defined kernel 0
        VX_FUNC_CUSTOM_1            = 32'h1001,  // User-defined kernel 1
        VX_FUNC_CUSTOM_2            = 32'h1002,  // User-defined kernel 2
        VX_FUNC_CUSTOM_3            = 32'h1003   // User-defined kernel 3
    } vx_func_op_e;

    // ============================================================================
    // Vortex LSU (Load-Store Unit) Interface
    // ============================================================================

    typedef struct packed {
        logic        valid;
        logic [63:0] addr;
        logic [2:0]  op;           // 0=LD, 1=ST, 2=ATOMIC_ADD, etc.
        logic [511:0] wdata;
        logic [63:0] wmask;        // Byte mask
        logic [7:0]  tid;          // Thread ID
        logic [3:0]  warp_id;      // Warp ID
    } vx_lsu_req_t;

    typedef struct packed {
        logic        valid;
        logic [511:0] rdata;
        logic        error;
        logic [7:0]  tid;
        logic [3:0]  warp_id;
    } vx_lsu_rsp_t;

    // ============================================================================
    // Assertions and Checks
    // ============================================================================

    // Check descriptor size
    function automatic logic check_sqe_vx_size();
        return $bits(sqe_vx_t) == 256 * 8;  // 256 bytes = 2048 bits
    endfunction

endpackage : cxl_memuring_vortex_pkg

`endif // CXL_MEMURING_VORTEX_PKG_SV
