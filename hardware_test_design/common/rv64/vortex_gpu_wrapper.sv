// vortex_gpu_wrapper.sv
// Wrapper module for Vortex GPU integration with CXL Type2 Device infrastructure
// Provides CSR interface, kernel launch control, and AXI4-MM ports
// Integrates actual Vortex GPU core via Vortex_axi module
//
// Ported from FireSim CXL infrastructure to ia780i_type2_delay_buffer project

`include "vortex/VX_define.vh"

module vortex_gpu_wrapper
    import cxl_memuring_vortex_pkg::*;
    import VX_gpu_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // CSR interface (from MMIO controller)
    // CSR addresses aligned with userspace driver (vortex_cxl.h):
    // - 0x100: KERNEL_ADDR_LO   - 0x104: KERNEL_ADDR_HI
    // - 0x108: KERNEL_ARGS_LO   - 0x10C: KERNEL_ARGS_HI
    // - 0x110: GRID_DIM_X       - 0x114: GRID_DIM_Y       - 0x118: GRID_DIM_Z
    // - 0x11C: BLOCK_DIM_X      - 0x120: BLOCK_DIM_Y      - 0x124: BLOCK_DIM_Z
    // - 0x128: LAUNCH (write 1) - 0x12C: STATUS (read)
    // - 0x130: CYCLE_LO         - 0x134: CYCLE_HI
    // - 0x138: INSTR_LO         - 0x13C: INSTR_HI
    input  logic        csr_valid,
    input  logic        csr_write,
    input  logic [11:0] csr_addr,
    input  logic [63:0] csr_wdata,
    output logic        csr_ready,
    output logic [63:0] csr_rdata,

    // Kernel launch interface (from Kernel Launcher)
    input  logic                kernel_launch_valid,
    input  vortex_kernel_args_t kernel_args,
    output logic                kernel_launch_ready,
    output logic                kernel_done,
    output logic [31:0]         kernel_status,

    // Performance counter output
    output vortex_perf_counters_t perf_counters,

    // AXI4-MM Master Port 0 (Host Memory via CAFU Port0)
    output logic [3:0]   m_axi_port0_awid,
    output logic [63:0]  m_axi_port0_awaddr,
    output logic [7:0]   m_axi_port0_awlen,
    output logic [2:0]   m_axi_port0_awsize,
    output logic [1:0]   m_axi_port0_awburst,
    output logic         m_axi_port0_awlock,
    output logic [3:0]   m_axi_port0_awcache,
    output logic [2:0]   m_axi_port0_awprot,
    output logic         m_axi_port0_awvalid,
    input  logic         m_axi_port0_awready,
    output logic [511:0] m_axi_port0_wdata,
    output logic [63:0]  m_axi_port0_wstrb,
    output logic         m_axi_port0_wlast,
    output logic         m_axi_port0_wvalid,
    input  logic         m_axi_port0_wready,
    input  logic [3:0]   m_axi_port0_bid,
    input  logic [1:0]   m_axi_port0_bresp,
    input  logic         m_axi_port0_bvalid,
    output logic         m_axi_port0_bready,
    output logic [3:0]   m_axi_port0_arid,
    output logic [63:0]  m_axi_port0_araddr,
    output logic [7:0]   m_axi_port0_arlen,
    output logic [2:0]   m_axi_port0_arsize,
    output logic [1:0]   m_axi_port0_arburst,
    output logic         m_axi_port0_arlock,
    output logic [3:0]   m_axi_port0_arcache,
    output logic [2:0]   m_axi_port0_arprot,
    output logic         m_axi_port0_arvalid,
    input  logic         m_axi_port0_arready,
    input  logic [3:0]   m_axi_port0_rid,
    input  logic [511:0] m_axi_port0_rdata,
    input  logic [1:0]   m_axi_port0_rresp,
    input  logic         m_axi_port0_rlast,
    input  logic         m_axi_port0_rvalid,
    output logic         m_axi_port0_rready,

    // AXI4-MM Master Port 1 (Device Memory via CAFU Port1)
    output logic [3:0]   m_axi_port1_awid,
    output logic [63:0]  m_axi_port1_awaddr,
    output logic [7:0]   m_axi_port1_awlen,
    output logic [2:0]   m_axi_port1_awsize,
    output logic [1:0]   m_axi_port1_awburst,
    output logic         m_axi_port1_awlock,
    output logic [3:0]   m_axi_port1_awcache,
    output logic [2:0]   m_axi_port1_awprot,
    output logic         m_axi_port1_awvalid,
    input  logic         m_axi_port1_awready,
    output logic [511:0] m_axi_port1_wdata,
    output logic [63:0]  m_axi_port1_wstrb,
    output logic         m_axi_port1_wlast,
    output logic         m_axi_port1_wvalid,
    input  logic         m_axi_port1_wready,
    input  logic [3:0]   m_axi_port1_bid,
    input  logic [1:0]   m_axi_port1_bresp,
    input  logic         m_axi_port1_bvalid,
    output logic         m_axi_port1_bready,
    output logic [3:0]   m_axi_port1_arid,
    output logic [63:0]  m_axi_port1_araddr,
    output logic [7:0]   m_axi_port1_arlen,
    output logic [2:0]   m_axi_port1_arsize,
    output logic [1:0]   m_axi_port1_arburst,
    output logic         m_axi_port1_arlock,
    output logic [3:0]   m_axi_port1_arcache,
    output logic [2:0]   m_axi_port1_arprot,
    output logic         m_axi_port1_arvalid,
    input  logic         m_axi_port1_arready,
    input  logic [3:0]   m_axi_port1_rid,
    input  logic [511:0] m_axi_port1_rdata,
    input  logic [1:0]   m_axi_port1_rresp,
    input  logic         m_axi_port1_rlast,
    input  logic         m_axi_port1_rvalid,
    output logic         m_axi_port1_rready
);

    //=========================================================================
    // CSR Address Definitions (matching userspace driver vortex_cxl.h)
    //=========================================================================

    // Base address for Vortex CSRs
    localparam logic [11:0] CSR_BASE            = 12'h100;

    // Configuration registers
    localparam logic [11:0] REG_KERNEL_ADDR_LO  = 12'h100;  // Kernel entry point (low)
    localparam logic [11:0] REG_KERNEL_ADDR_HI  = 12'h104;  // Kernel entry point (high)
    localparam logic [11:0] REG_KERNEL_ARGS_LO  = 12'h108;  // Kernel args pointer (low)
    localparam logic [11:0] REG_KERNEL_ARGS_HI  = 12'h10C;  // Kernel args pointer (high)
    localparam logic [11:0] REG_GRID_DIM_X      = 12'h110;  // Grid dimension X
    localparam logic [11:0] REG_GRID_DIM_Y      = 12'h114;  // Grid dimension Y
    localparam logic [11:0] REG_GRID_DIM_Z      = 12'h118;  // Grid dimension Z
    localparam logic [11:0] REG_BLOCK_DIM_X     = 12'h11C;  // Block dimension X
    localparam logic [11:0] REG_BLOCK_DIM_Y     = 12'h120;  // Block dimension Y
    localparam logic [11:0] REG_BLOCK_DIM_Z     = 12'h124;  // Block dimension Z
    localparam logic [11:0] REG_LAUNCH          = 12'h128;  // Launch trigger (write 1)
    localparam logic [11:0] REG_STATUS          = 12'h12C;  // Status register (read)
    localparam logic [11:0] REG_CYCLE_LO        = 12'h130;  // Cycle counter (low)
    localparam logic [11:0] REG_CYCLE_HI        = 12'h134;  // Cycle counter (high)
    localparam logic [11:0] REG_INSTR_LO        = 12'h138;  // Instruction counter (low)
    localparam logic [11:0] REG_INSTR_HI        = 12'h13C;  // Instruction counter (high)
    localparam logic [11:0] REG_DOORBELL        = 12'h040;  // Doorbell register

    // Status values
    localparam logic [7:0] STATUS_IDLE          = 8'h00;
    localparam logic [7:0] STATUS_RUNNING       = 8'h01;
    localparam logic [7:0] STATUS_DONE          = 8'h02;
    localparam logic [7:0] STATUS_ERROR         = 8'hFF;

    //=========================================================================
    // CSR Register File
    //=========================================================================

    // Configuration registers
    logic [63:0] reg_kernel_addr;       // Kernel entry point
    logic [63:0] reg_kernel_args;       // Kernel arguments pointer
    logic [31:0] reg_grid_dim_x;        // Grid X dimension
    logic [31:0] reg_grid_dim_y;        // Grid Y dimension
    logic [31:0] reg_grid_dim_z;        // Grid Z dimension
    logic [31:0] reg_block_dim_x;       // Block X dimension
    logic [31:0] reg_block_dim_y;       // Block Y dimension
    logic [31:0] reg_block_dim_z;       // Block Z dimension

    // Status registers
    logic [7:0]  reg_status;
    logic [63:0] reg_cycles;
    logic [63:0] reg_instrs;

    // Vortex GPU core signals
    logic        vx_busy;
    logic        vx_reset;
    logic        vx_launch_trigger;

    // DCR (Device Control Register) interface to Vortex core
    logic                         dcr_wr_valid;
    logic [VX_DCR_ADDR_WIDTH-1:0] dcr_wr_addr;
    logic [VX_DCR_DATA_WIDTH-1:0] dcr_wr_data;

    // Vortex AXI signals (from Vortex_axi module)
    localparam AXI_DATA_WIDTH = 512;
    localparam AXI_ADDR_WIDTH = 48;
    // AXI_TID_WIDTH must be >= (NUM_PORTS_IN_BITS + READ_TAG_WIDTH)
    // For safe operation with Vortex's tag buffer, use 16 bits
    localparam AXI_TID_WIDTH  = 16;
    localparam AXI_NUM_BANKS  = 1;

    // AXI interface arrays for Vortex_axi
    wire                            vx_axi_awvalid [AXI_NUM_BANKS];
    wire                            vx_axi_awready [AXI_NUM_BANKS];
    wire [AXI_ADDR_WIDTH-1:0]       vx_axi_awaddr [AXI_NUM_BANKS];
    wire [AXI_TID_WIDTH-1:0]        vx_axi_awid [AXI_NUM_BANKS];
    wire [7:0]                      vx_axi_awlen [AXI_NUM_BANKS];
    wire [2:0]                      vx_axi_awsize [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_awburst [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_awlock [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_awcache [AXI_NUM_BANKS];
    wire [2:0]                      vx_axi_awprot [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_awqos [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_awregion [AXI_NUM_BANKS];

    wire                            vx_axi_wvalid [AXI_NUM_BANKS];
    wire                            vx_axi_wready [AXI_NUM_BANKS];
    wire [AXI_DATA_WIDTH-1:0]       vx_axi_wdata [AXI_NUM_BANKS];
    wire [AXI_DATA_WIDTH/8-1:0]     vx_axi_wstrb [AXI_NUM_BANKS];
    wire                            vx_axi_wlast [AXI_NUM_BANKS];

    wire                            vx_axi_bvalid [AXI_NUM_BANKS];
    wire                            vx_axi_bready [AXI_NUM_BANKS];
    wire [AXI_TID_WIDTH-1:0]        vx_axi_bid [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_bresp [AXI_NUM_BANKS];

    wire                            vx_axi_arvalid [AXI_NUM_BANKS];
    wire                            vx_axi_arready [AXI_NUM_BANKS];
    wire [AXI_ADDR_WIDTH-1:0]       vx_axi_araddr [AXI_NUM_BANKS];
    wire [AXI_TID_WIDTH-1:0]        vx_axi_arid [AXI_NUM_BANKS];
    wire [7:0]                      vx_axi_arlen [AXI_NUM_BANKS];
    wire [2:0]                      vx_axi_arsize [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_arburst [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_arlock [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_arcache [AXI_NUM_BANKS];
    wire [2:0]                      vx_axi_arprot [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_arqos [AXI_NUM_BANKS];
    wire [3:0]                      vx_axi_arregion [AXI_NUM_BANKS];

    wire                            vx_axi_rvalid [AXI_NUM_BANKS];
    wire                            vx_axi_rready [AXI_NUM_BANKS];
    wire [AXI_DATA_WIDTH-1:0]       vx_axi_rdata [AXI_NUM_BANKS];
    wire                            vx_axi_rlast [AXI_NUM_BANKS];
    wire [AXI_TID_WIDTH-1:0]        vx_axi_rid [AXI_NUM_BANKS];
    wire [1:0]                      vx_axi_rresp [AXI_NUM_BANKS];

    //=========================================================================
    // Kernel Launch Control State Machine
    //=========================================================================

    logic kernel_running;
    logic [31:0] kernel_timeout_counter;
    logic launch_pending;
    logic use_kernel_args;  // Flag to indicate kernel_args should be used

    // DCR write state machine for configuring Vortex
    typedef enum logic [3:0] {
        DCR_IDLE,
        DCR_WRITE_PC_LO,
        DCR_WRITE_PC_HI,
        DCR_WRITE_WARPS,
        DCR_WRITE_THREADS,
        DCR_START,
        DCR_RUNNING,
        DCR_DONE
    } dcr_state_t;

    dcr_state_t dcr_state;

    //=========================================================================
    // Unified CSR and Kernel Launch Register File
    // All register writes consolidated into single always block
    //=========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // CSR registers
            reg_kernel_addr <= 64'h0;
            reg_kernel_args <= 64'h0;
            reg_grid_dim_x  <= 32'h1;
            reg_grid_dim_y  <= 32'h1;
            reg_grid_dim_z  <= 32'h1;
            reg_block_dim_x <= 32'h1;
            reg_block_dim_y <= 32'h1;
            reg_block_dim_z <= 32'h1;
            reg_status      <= STATUS_IDLE;
            reg_cycles      <= 64'h0;
            reg_instrs      <= 64'h0;
            csr_ready       <= 1'b0;
            csr_rdata       <= 64'h0;
            vx_launch_trigger <= 1'b0;
            // Kernel launch control
            kernel_running <= 1'b0;
            kernel_done <= 1'b0;
            kernel_status <= 32'h0;
            kernel_launch_ready <= 1'b1;
            vx_reset <= 1'b1;
            kernel_timeout_counter <= 32'h0;
            launch_pending <= 1'b0;
            use_kernel_args <= 1'b0;
            dcr_state <= DCR_IDLE;
            dcr_wr_valid <= 1'b0;
            dcr_wr_addr <= '0;
            dcr_wr_data <= '0;
        end else begin
            // Default pulse signals
            csr_ready <= 1'b0;
            vx_launch_trigger <= 1'b0;
            kernel_done <= 1'b0;
            dcr_wr_valid <= 1'b0;

            //=================================================================
            // CSR Interface Handling
            //=================================================================
            if (csr_valid && !csr_ready) begin
                csr_ready <= 1'b1;

                if (csr_write) begin
                    // Write to CSR (matching vortex_cxl.h addresses)
                    case (csr_addr)
                        REG_KERNEL_ADDR_LO: reg_kernel_addr[31:0]  <= csr_wdata[31:0];
                        REG_KERNEL_ADDR_HI: reg_kernel_addr[63:32] <= csr_wdata[31:0];
                        REG_KERNEL_ARGS_LO: reg_kernel_args[31:0]  <= csr_wdata[31:0];
                        REG_KERNEL_ARGS_HI: reg_kernel_args[63:32] <= csr_wdata[31:0];
                        REG_GRID_DIM_X:     reg_grid_dim_x         <= csr_wdata[31:0];
                        REG_GRID_DIM_Y:     reg_grid_dim_y         <= csr_wdata[31:0];
                        REG_GRID_DIM_Z:     reg_grid_dim_z         <= csr_wdata[31:0];
                        REG_BLOCK_DIM_X:    reg_block_dim_x        <= csr_wdata[31:0];
                        REG_BLOCK_DIM_Y:    reg_block_dim_y        <= csr_wdata[31:0];
                        REG_BLOCK_DIM_Z:    reg_block_dim_z        <= csr_wdata[31:0];
                        REG_LAUNCH: begin
                            if (csr_wdata[0]) begin
                                vx_launch_trigger <= 1'b1;
                            end
                        end
                        default: ;  // Ignore writes to read-only registers
                    endcase
                end else begin
                    // Read from CSR
                    case (csr_addr)
                        REG_KERNEL_ADDR_LO: csr_rdata <= {32'h0, reg_kernel_addr[31:0]};
                        REG_KERNEL_ADDR_HI: csr_rdata <= {32'h0, reg_kernel_addr[63:32]};
                        REG_KERNEL_ARGS_LO: csr_rdata <= {32'h0, reg_kernel_args[31:0]};
                        REG_KERNEL_ARGS_HI: csr_rdata <= {32'h0, reg_kernel_args[63:32]};
                        REG_GRID_DIM_X:     csr_rdata <= {32'h0, reg_grid_dim_x};
                        REG_GRID_DIM_Y:     csr_rdata <= {32'h0, reg_grid_dim_y};
                        REG_GRID_DIM_Z:     csr_rdata <= {32'h0, reg_grid_dim_z};
                        REG_BLOCK_DIM_X:    csr_rdata <= {32'h0, reg_block_dim_x};
                        REG_BLOCK_DIM_Y:    csr_rdata <= {32'h0, reg_block_dim_y};
                        REG_BLOCK_DIM_Z:    csr_rdata <= {32'h0, reg_block_dim_z};
                        REG_STATUS:         csr_rdata <= {56'h0, reg_status};
                        REG_CYCLE_LO:       csr_rdata <= {32'h0, reg_cycles[31:0]};
                        REG_CYCLE_HI:       csr_rdata <= {32'h0, reg_cycles[63:32]};
                        REG_INSTR_LO:       csr_rdata <= {32'h0, reg_instrs[31:0]};
                        REG_INSTR_HI:       csr_rdata <= {32'h0, reg_instrs[63:32]};
                        default:            csr_rdata <= 64'h0;
                    endcase
                end
            end

            //=================================================================
            // Kernel Launch Interface Handling
            //=================================================================
            if (kernel_launch_valid && kernel_launch_ready && !kernel_running) begin
                // Copy args from kernel_launch interface
                reg_kernel_addr <= kernel_args.pc_start;
                reg_kernel_args <= kernel_args.kernel_param_ptr;
                reg_grid_dim_x  <= {16'h0, kernel_args.grid_x};
                reg_grid_dim_y  <= {16'h0, kernel_args.grid_y};
                reg_grid_dim_z  <= {16'h0, kernel_args.grid_z};
                reg_block_dim_x <= {16'h0, kernel_args.block_x};
                reg_block_dim_y <= {16'h0, kernel_args.block_y};
                reg_block_dim_z <= {16'h0, kernel_args.block_z};
                launch_pending <= 1'b1;
                kernel_launch_ready <= 1'b0;
                use_kernel_args <= 1'b1;
            end

            // CSR launch trigger (registers already set via CSR writes)
            if (vx_launch_trigger && !kernel_running && !launch_pending) begin
                launch_pending <= 1'b1;
                kernel_launch_ready <= 1'b0;
                use_kernel_args <= 1'b0;
            end

            //=================================================================
            // DCR Configuration State Machine
            //=================================================================
            case (dcr_state)
                DCR_IDLE: begin
                    if (launch_pending) begin
                        launch_pending <= 1'b0;
                        dcr_state <= DCR_WRITE_PC_LO;
                        vx_reset <= 1'b0;  // Release reset
                        reg_status <= STATUS_RUNNING;
                        kernel_running <= 1'b1;
                        reg_cycles <= 64'h0;
                        reg_instrs <= 64'h0;
                    end
                end

                DCR_WRITE_PC_LO: begin
                    dcr_wr_valid <= 1'b1;
                    dcr_wr_addr <= VX_DCR_ADDR_WIDTH'(12'h001);  // DCR_BASE_STARTUP_ADDR0
                    dcr_wr_data <= reg_kernel_addr[31:0];
                    dcr_state <= DCR_WRITE_PC_HI;
                end

                DCR_WRITE_PC_HI: begin
                    dcr_wr_valid <= 1'b1;
                    dcr_wr_addr <= VX_DCR_ADDR_WIDTH'(12'h002);  // DCR_BASE_STARTUP_ADDR1
                    dcr_wr_data <= reg_kernel_addr[63:32];
                    dcr_state <= DCR_WRITE_WARPS;
                end

                DCR_WRITE_WARPS: begin
                    dcr_wr_valid <= 1'b1;
                    dcr_wr_addr <= VX_DCR_ADDR_WIDTH'(12'h003);  // DCR_BASE_MPM_CLASS
                    dcr_wr_data <= 32'h0;
                    dcr_state <= DCR_START;
                end

                DCR_START: begin
                    dcr_state <= DCR_RUNNING;
                    kernel_timeout_counter <= 32'h0;
                end

                DCR_RUNNING: begin
                    kernel_timeout_counter <= kernel_timeout_counter + 1;
                    reg_cycles <= reg_cycles + 1;

                    if (!vx_busy) begin
                        dcr_state <= DCR_DONE;
                    end else if (kernel_timeout_counter == 32'hFFFFFFFF) begin
                        dcr_state <= DCR_DONE;
                        reg_status <= STATUS_ERROR;
                    end
                end

                DCR_DONE: begin
                    kernel_running <= 1'b0;
                    kernel_done <= 1'b1;
                    kernel_launch_ready <= 1'b1;
                    vx_reset <= 1'b1;
                    if (reg_status != STATUS_ERROR) begin
                        reg_status <= STATUS_DONE;
                    end
                    kernel_status <= {24'h0, reg_status};
                    dcr_state <= DCR_IDLE;
                end

                default: dcr_state <= DCR_IDLE;
            endcase
        end
    end

    //=========================================================================
    // Vortex GPU Core Instantiation (Vortex_axi)
    //=========================================================================

    Vortex_axi #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_TID_WIDTH  (AXI_TID_WIDTH),
        .AXI_NUM_BANKS  (AXI_NUM_BANKS)
    ) vortex_core (
        .clk            (clk),
        .reset          (vx_reset),

        // AXI Write Address
        .m_axi_awvalid  (vx_axi_awvalid),
        .m_axi_awready  (vx_axi_awready),
        .m_axi_awaddr   (vx_axi_awaddr),
        .m_axi_awid     (vx_axi_awid),
        .m_axi_awlen    (vx_axi_awlen),
        .m_axi_awsize   (vx_axi_awsize),
        .m_axi_awburst  (vx_axi_awburst),
        .m_axi_awlock   (vx_axi_awlock),
        .m_axi_awcache  (vx_axi_awcache),
        .m_axi_awprot   (vx_axi_awprot),
        .m_axi_awqos    (vx_axi_awqos),
        .m_axi_awregion (vx_axi_awregion),

        // AXI Write Data
        .m_axi_wvalid   (vx_axi_wvalid),
        .m_axi_wready   (vx_axi_wready),
        .m_axi_wdata    (vx_axi_wdata),
        .m_axi_wstrb    (vx_axi_wstrb),
        .m_axi_wlast    (vx_axi_wlast),

        // AXI Write Response
        .m_axi_bvalid   (vx_axi_bvalid),
        .m_axi_bready   (vx_axi_bready),
        .m_axi_bid      (vx_axi_bid),
        .m_axi_bresp    (vx_axi_bresp),

        // AXI Read Address
        .m_axi_arvalid  (vx_axi_arvalid),
        .m_axi_arready  (vx_axi_arready),
        .m_axi_araddr   (vx_axi_araddr),
        .m_axi_arid     (vx_axi_arid),
        .m_axi_arlen    (vx_axi_arlen),
        .m_axi_arsize   (vx_axi_arsize),
        .m_axi_arburst  (vx_axi_arburst),
        .m_axi_arlock   (vx_axi_arlock),
        .m_axi_arcache  (vx_axi_arcache),
        .m_axi_arprot   (vx_axi_arprot),
        .m_axi_arqos    (vx_axi_arqos),
        .m_axi_arregion (vx_axi_arregion),

        // AXI Read Data
        .m_axi_rvalid   (vx_axi_rvalid),
        .m_axi_rready   (vx_axi_rready),
        .m_axi_rdata    (vx_axi_rdata),
        .m_axi_rlast    (vx_axi_rlast),
        .m_axi_rid      (vx_axi_rid),
        .m_axi_rresp    (vx_axi_rresp),

        // DCR Interface
        .dcr_wr_valid   (dcr_wr_valid),
        .dcr_wr_addr    (dcr_wr_addr),
        .dcr_wr_data    (dcr_wr_data),

        // Status
        .busy           (vx_busy)
    );

    //=========================================================================
    // AXI Port Routing (Vortex AXI -> CAFU Ports)
    // All Vortex memory accesses go to Port1 (Device Memory / HDM)
    //=========================================================================

    // Connect Vortex AXI[0] to Port1 (Device Memory)
    // Note: Internal AXI_TID_WIDTH is 16 bits, port IDs are 4 bits
    // Truncate outgoing IDs, zero-extend incoming IDs
    assign m_axi_port1_awvalid = vx_axi_awvalid[0];
    assign vx_axi_awready[0]   = m_axi_port1_awready;
    assign m_axi_port1_awaddr  = {{(64-AXI_ADDR_WIDTH){1'b0}}, vx_axi_awaddr[0]};
    assign m_axi_port1_awid    = vx_axi_awid[0][3:0];  // Truncate to 4 bits
    assign m_axi_port1_awlen   = vx_axi_awlen[0];
    assign m_axi_port1_awsize  = vx_axi_awsize[0];
    assign m_axi_port1_awburst = vx_axi_awburst[0];
    assign m_axi_port1_awlock  = vx_axi_awlock[0][0];
    assign m_axi_port1_awcache = vx_axi_awcache[0];
    assign m_axi_port1_awprot  = vx_axi_awprot[0];

    assign m_axi_port1_wvalid  = vx_axi_wvalid[0];
    assign vx_axi_wready[0]    = m_axi_port1_wready;
    assign m_axi_port1_wdata   = vx_axi_wdata[0];
    assign m_axi_port1_wstrb   = vx_axi_wstrb[0];
    assign m_axi_port1_wlast   = vx_axi_wlast[0];

    assign vx_axi_bvalid[0]    = m_axi_port1_bvalid;
    assign m_axi_port1_bready  = vx_axi_bready[0];
    assign vx_axi_bid[0]       = {{(AXI_TID_WIDTH-4){1'b0}}, m_axi_port1_bid};  // Zero-extend
    assign vx_axi_bresp[0]     = m_axi_port1_bresp;

    assign m_axi_port1_arvalid = vx_axi_arvalid[0];
    assign vx_axi_arready[0]   = m_axi_port1_arready;
    assign m_axi_port1_araddr  = {{(64-AXI_ADDR_WIDTH){1'b0}}, vx_axi_araddr[0]};
    assign m_axi_port1_arid    = vx_axi_arid[0][3:0];  // Truncate to 4 bits
    assign m_axi_port1_arlen   = vx_axi_arlen[0];
    assign m_axi_port1_arsize  = vx_axi_arsize[0];
    assign m_axi_port1_arburst = vx_axi_arburst[0];
    assign m_axi_port1_arlock  = vx_axi_arlock[0][0];
    assign m_axi_port1_arcache = vx_axi_arcache[0];
    assign m_axi_port1_arprot  = vx_axi_arprot[0];

    assign vx_axi_rvalid[0]    = m_axi_port1_rvalid;
    assign m_axi_port1_rready  = vx_axi_rready[0];
    assign vx_axi_rdata[0]     = m_axi_port1_rdata;
    assign vx_axi_rlast[0]     = m_axi_port1_rlast;
    assign vx_axi_rid[0]       = {{(AXI_TID_WIDTH-4){1'b0}}, m_axi_port1_rid};  // Zero-extend
    assign vx_axi_rresp[0]     = m_axi_port1_rresp;

    //=========================================================================
    // Port0 (Host Memory) - Unused by Vortex, tie off
    //=========================================================================

    assign m_axi_port0_awvalid = 1'b0;
    assign m_axi_port0_awaddr  = 64'h0;
    assign m_axi_port0_awid    = 4'h0;
    assign m_axi_port0_awlen   = 8'h0;
    assign m_axi_port0_awsize  = 3'b0;
    assign m_axi_port0_awburst = 2'b0;
    assign m_axi_port0_awlock  = 1'b0;
    assign m_axi_port0_awcache = 4'h0;
    assign m_axi_port0_awprot  = 3'h0;

    assign m_axi_port0_wvalid  = 1'b0;
    assign m_axi_port0_wdata   = 512'h0;
    assign m_axi_port0_wstrb   = 64'h0;
    assign m_axi_port0_wlast   = 1'b0;

    assign m_axi_port0_bready  = 1'b1;

    assign m_axi_port0_arvalid = 1'b0;
    assign m_axi_port0_araddr  = 64'h0;
    assign m_axi_port0_arid    = 4'h0;
    assign m_axi_port0_arlen   = 8'h0;
    assign m_axi_port0_arsize  = 3'b0;
    assign m_axi_port0_arburst = 2'b0;
    assign m_axi_port0_arlock  = 1'b0;
    assign m_axi_port0_arcache = 4'h0;
    assign m_axi_port0_arprot  = 3'h0;

    assign m_axi_port0_rready  = 1'b1;

    //=========================================================================
    // Performance Counter Collection
    //=========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            perf_counters.cycles       <= 64'h0;
            perf_counters.instrs       <= 64'h0;
            perf_counters.mem_reads    <= 64'h0;
            perf_counters.mem_writes   <= 64'h0;
            perf_counters.cache_hits   <= 64'h0;
            perf_counters.cache_misses <= 64'h0;
            perf_counters.branch_taken <= 64'h0;
            perf_counters.branch_not_taken <= 64'h0;
        end else begin
            if (kernel_running) begin
                perf_counters.cycles <= perf_counters.cycles + 1;

                // Count AXI transactions
                if (vx_axi_arvalid[0] && vx_axi_arready[0]) begin
                    perf_counters.mem_reads <= perf_counters.mem_reads + 1;
                end
                if (vx_axi_awvalid[0] && vx_axi_awready[0]) begin
                    perf_counters.mem_writes <= perf_counters.mem_writes + 1;
                end
            end

            // Reset counters when new kernel starts
            if (vx_launch_trigger || (kernel_launch_valid && kernel_launch_ready)) begin
                perf_counters.cycles       <= 64'h0;
                perf_counters.instrs       <= 64'h0;
                perf_counters.mem_reads    <= 64'h0;
                perf_counters.mem_writes   <= 64'h0;
                perf_counters.cache_hits   <= 64'h0;
                perf_counters.cache_misses <= 64'h0;
                perf_counters.branch_taken <= 64'h0;
                perf_counters.branch_not_taken <= 64'h0;
            end
        end
    end

endmodule
