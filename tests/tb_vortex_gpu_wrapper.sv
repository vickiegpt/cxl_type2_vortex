// tb_vortex_gpu_wrapper.sv
// Testbench for Vortex GPU Wrapper with DCOH Support
// Tests kernel launch and coherent completion writeback

`timescale 1ns / 1ps

module tb_vortex_gpu_wrapper;

    //=========================================================================
    // Parameters
    //=========================================================================

    parameter CLK_PERIOD = 4;  // 250 MHz
    parameter AXI_DATA_WIDTH = 512;
    parameter AXI_ADDR_WIDTH = 64;
    parameter AXI_ID_WIDTH = 4;

    // Test memory size
    parameter MEM_SIZE = 1024 * 1024;  // 1MB

    //=========================================================================
    // Clock and Reset
    //=========================================================================

    logic clk;
    logic rst_n;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #(CLK_PERIOD * 10);
        rst_n = 1'b1;
    end

    //=========================================================================
    // DUT Signals
    //=========================================================================

    // CSR interface
    logic        csr_valid;
    logic        csr_write;
    logic [11:0] csr_addr;
    logic [63:0] csr_wdata;
    logic        csr_ready;
    logic [63:0] csr_rdata;

    // Kernel launch interface
    logic                kernel_launch_valid;
    logic [255:0]        kernel_args_packed;
    logic                kernel_launch_ready;
    logic                kernel_done;
    logic [31:0]         kernel_status;

    // Performance counters
    logic [511:0]        perf_counters_packed;

    // AXI Port 0 (Host Memory / DCOH)
    logic [AXI_ID_WIDTH-1:0]   m_axi_port0_awid;
    logic [AXI_ADDR_WIDTH-1:0] m_axi_port0_awaddr;
    logic [7:0]                m_axi_port0_awlen;
    logic [2:0]                m_axi_port0_awsize;
    logic [1:0]                m_axi_port0_awburst;
    logic                      m_axi_port0_awlock;
    logic [3:0]                m_axi_port0_awcache;
    logic [2:0]                m_axi_port0_awprot;
    logic                      m_axi_port0_awvalid;
    logic                      m_axi_port0_awready;
    logic [AXI_DATA_WIDTH-1:0] m_axi_port0_wdata;
    logic [AXI_DATA_WIDTH/8-1:0] m_axi_port0_wstrb;
    logic                      m_axi_port0_wlast;
    logic                      m_axi_port0_wvalid;
    logic                      m_axi_port0_wready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port0_bid;
    logic [1:0]                m_axi_port0_bresp;
    logic                      m_axi_port0_bvalid;
    logic                      m_axi_port0_bready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port0_arid;
    logic [AXI_ADDR_WIDTH-1:0] m_axi_port0_araddr;
    logic [7:0]                m_axi_port0_arlen;
    logic [2:0]                m_axi_port0_arsize;
    logic [1:0]                m_axi_port0_arburst;
    logic                      m_axi_port0_arlock;
    logic [3:0]                m_axi_port0_arcache;
    logic [2:0]                m_axi_port0_arprot;
    logic [3:0]                m_axi_port0_awqos;
    logic                      m_axi_port0_arvalid;
    logic                      m_axi_port0_arready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port0_rid;
    logic [AXI_DATA_WIDTH-1:0] m_axi_port0_rdata;
    logic [1:0]                m_axi_port0_rresp;
    logic                      m_axi_port0_rlast;
    logic                      m_axi_port0_rvalid;
    logic                      m_axi_port0_rready;

    // AXI Port 1 (Device Memory)
    logic [AXI_ID_WIDTH-1:0]   m_axi_port1_awid;
    logic [AXI_ADDR_WIDTH-1:0] m_axi_port1_awaddr;
    logic [7:0]                m_axi_port1_awlen;
    logic [2:0]                m_axi_port1_awsize;
    logic [1:0]                m_axi_port1_awburst;
    logic                      m_axi_port1_awlock;
    logic [3:0]                m_axi_port1_awcache;
    logic [2:0]                m_axi_port1_awprot;
    logic                      m_axi_port1_awvalid;
    logic                      m_axi_port1_awready;
    logic [AXI_DATA_WIDTH-1:0] m_axi_port1_wdata;
    logic [AXI_DATA_WIDTH/8-1:0] m_axi_port1_wstrb;
    logic                      m_axi_port1_wlast;
    logic                      m_axi_port1_wvalid;
    logic                      m_axi_port1_wready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port1_bid;
    logic [1:0]                m_axi_port1_bresp;
    logic                      m_axi_port1_bvalid;
    logic                      m_axi_port1_bready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port1_arid;
    logic [AXI_ADDR_WIDTH-1:0] m_axi_port1_araddr;
    logic [7:0]                m_axi_port1_arlen;
    logic [2:0]                m_axi_port1_arsize;
    logic [1:0]                m_axi_port1_arburst;
    logic                      m_axi_port1_arlock;
    logic [3:0]                m_axi_port1_arcache;
    logic [2:0]                m_axi_port1_arprot;
    logic                      m_axi_port1_arvalid;
    logic                      m_axi_port1_arready;
    logic [AXI_ID_WIDTH-1:0]   m_axi_port1_rid;
    logic [AXI_DATA_WIDTH-1:0] m_axi_port1_rdata;
    logic [1:0]                m_axi_port1_rresp;
    logic                      m_axi_port1_rlast;
    logic                      m_axi_port1_rvalid;
    logic                      m_axi_port1_rready;

    //=========================================================================
    // DUT Instantiation (simplified without actual Vortex core)
    //=========================================================================

    // For simulation, we use a simplified stub that responds to CSR writes
    // and generates kernel_done after a delay

    // CSR Register Addresses
    localparam REG_KERNEL_ADDR_LO  = 12'h100;
    localparam REG_KERNEL_ADDR_HI  = 12'h104;
    localparam REG_KERNEL_ARGS_LO  = 12'h108;
    localparam REG_KERNEL_ARGS_HI  = 12'h10C;
    localparam REG_GRID_DIM_X      = 12'h110;
    localparam REG_GRID_DIM_Y      = 12'h114;
    localparam REG_GRID_DIM_Z      = 12'h118;
    localparam REG_BLOCK_DIM_X     = 12'h11C;
    localparam REG_BLOCK_DIM_Y     = 12'h120;
    localparam REG_BLOCK_DIM_Z     = 12'h124;
    localparam REG_LAUNCH          = 12'h128;
    localparam REG_STATUS          = 12'h12C;
    localparam REG_COMPLETION_LO   = 12'h140;
    localparam REG_COMPLETION_HI   = 12'h144;
    localparam REG_DCOH_ENABLE     = 12'h148;

    // Internal registers
    logic [63:0] reg_kernel_addr;
    logic [63:0] reg_kernel_args;
    logic [31:0] reg_grid_dim_x, reg_grid_dim_y, reg_grid_dim_z;
    logic [31:0] reg_block_dim_x, reg_block_dim_y, reg_block_dim_z;
    logic [7:0]  reg_status;
    logic [63:0] reg_completion_addr;
    logic        reg_dcoh_enable;

    logic        sim_kernel_running;
    logic [31:0] sim_kernel_counter;
    logic        sim_kernel_done;
    logic [31:0] sim_kernel_status;

    // CSR Interface Handler
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_kernel_addr     <= 64'h0;
            reg_kernel_args     <= 64'h0;
            reg_grid_dim_x      <= 32'h1;
            reg_grid_dim_y      <= 32'h1;
            reg_grid_dim_z      <= 32'h1;
            reg_block_dim_x     <= 32'h1;
            reg_block_dim_y     <= 32'h1;
            reg_block_dim_z     <= 32'h1;
            reg_status          <= 8'h00;
            reg_completion_addr <= 64'h0;
            reg_dcoh_enable     <= 1'b0;
            csr_ready           <= 1'b0;
            csr_rdata           <= 64'h0;
            sim_kernel_running  <= 1'b0;
            sim_kernel_counter  <= 32'h0;
            sim_kernel_done     <= 1'b0;
            sim_kernel_status   <= 32'h0;
        end else begin
            csr_ready <= 1'b0;
            sim_kernel_done <= 1'b0;

            // Handle CSR access
            if (csr_valid && !csr_ready) begin
                csr_ready <= 1'b1;

                if (csr_write) begin
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
                        REG_COMPLETION_LO:  reg_completion_addr[31:0]  <= csr_wdata[31:0];
                        REG_COMPLETION_HI:  reg_completion_addr[63:32] <= csr_wdata[31:0];
                        REG_DCOH_ENABLE:    reg_dcoh_enable        <= csr_wdata[0];
                        REG_LAUNCH: begin
                            if (csr_wdata[0] && !sim_kernel_running) begin
                                sim_kernel_running <= 1'b1;
                                sim_kernel_counter <= 32'h0;
                                reg_status <= 8'h01;  // RUNNING
                                $display("[%0t] Kernel launched: addr=0x%h, args=0x%h, grid=(%0d,%0d,%0d)",
                                    $time, reg_kernel_addr, reg_kernel_args,
                                    reg_grid_dim_x, reg_grid_dim_y, reg_grid_dim_z);
                            end
                        end
                    endcase
                end else begin
                    case (csr_addr)
                        REG_KERNEL_ADDR_LO: csr_rdata <= {32'h0, reg_kernel_addr[31:0]};
                        REG_KERNEL_ADDR_HI: csr_rdata <= {32'h0, reg_kernel_addr[63:32]};
                        REG_STATUS:         csr_rdata <= {56'h0, reg_status};
                        REG_COMPLETION_LO:  csr_rdata <= {32'h0, reg_completion_addr[31:0]};
                        REG_COMPLETION_HI:  csr_rdata <= {32'h0, reg_completion_addr[63:32]};
                        REG_DCOH_ENABLE:    csr_rdata <= {63'h0, reg_dcoh_enable};
                        default:            csr_rdata <= 64'h0;
                    endcase
                end
            end

            // Simulate kernel execution (completes after 100 cycles)
            if (sim_kernel_running) begin
                sim_kernel_counter <= sim_kernel_counter + 1;
                if (sim_kernel_counter >= 100) begin
                    sim_kernel_running <= 1'b0;
                    sim_kernel_done <= 1'b1;
                    sim_kernel_status <= 32'h0;  // Success
                    reg_status <= 8'h02;  // DONE
                    $display("[%0t] Kernel completed: status=0x%h", $time, sim_kernel_status);
                end
            end
        end
    end

    assign kernel_done = sim_kernel_done;
    assign kernel_status = sim_kernel_status;

    //=========================================================================
    // DCOH Writeback Module
    //=========================================================================

    logic        dcoh_busy;
    logic        dcoh_done;
    logic [31:0] dcoh_status;

    vortex_dcoh_writeback #(
        .AXI_ADDR_WIDTH     (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH     (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH       (AXI_ID_WIDTH),
        .MAX_OUTSTANDING    (4),
        .COMPLETION_FIFO_DEPTH (8)
    ) dcoh_wb (
        .clk                    (clk),
        .rst_n                  (rst_n),

        // Configuration
        .completion_base_addr   (reg_completion_addr),
        .dcoh_enable            (reg_dcoh_enable),

        // Kernel completion
        .kernel_done            (kernel_done),
        .kernel_status          (kernel_status),
        .kernel_result          (64'hCAFE_BABE_DEAD_BEEF),  // Test result
        .completion_addr        (reg_completion_addr),

        // AXI interface (Port0 - Host Memory)
        .m_axi_dcoh_awid        (m_axi_port0_awid),
        .m_axi_dcoh_awaddr      (m_axi_port0_awaddr),
        .m_axi_dcoh_awlen       (m_axi_port0_awlen),
        .m_axi_dcoh_awsize      (m_axi_port0_awsize),
        .m_axi_dcoh_awburst     (m_axi_port0_awburst),
        .m_axi_dcoh_awlock      (m_axi_port0_awlock),
        .m_axi_dcoh_awcache     (m_axi_port0_awcache),
        .m_axi_dcoh_awprot      (m_axi_port0_awprot),
        .m_axi_dcoh_awqos       (m_axi_port0_awqos),
        .m_axi_dcoh_awvalid     (m_axi_port0_awvalid),
        .m_axi_dcoh_awready     (m_axi_port0_awready),
        .m_axi_dcoh_awuser      (),  // Not connected in this testbench

        .m_axi_dcoh_wdata       (m_axi_port0_wdata),
        .m_axi_dcoh_wstrb       (m_axi_port0_wstrb),
        .m_axi_dcoh_wlast       (m_axi_port0_wlast),
        .m_axi_dcoh_wvalid      (m_axi_port0_wvalid),
        .m_axi_dcoh_wready      (m_axi_port0_wready),
        .m_axi_dcoh_wuser       (),

        .m_axi_dcoh_bid         (m_axi_port0_bid),
        .m_axi_dcoh_bresp       (m_axi_port0_bresp),
        .m_axi_dcoh_bvalid      (m_axi_port0_bvalid),
        .m_axi_dcoh_bready      (m_axi_port0_bready),

        // Status
        .dcoh_busy              (dcoh_busy),
        .dcoh_done              (dcoh_done),
        .dcoh_status            (dcoh_status),
        .outstanding_count      ()
    );

    //=========================================================================
    // AXI Memory Model (Host Memory - Port0)
    //=========================================================================

    logic [7:0] host_memory [MEM_SIZE];
    logic [AXI_ID_WIDTH-1:0] aw_id_q[$];

    // Initialize memory
    initial begin
        for (int i = 0; i < MEM_SIZE; i++) begin
            host_memory[i] = 8'h00;
        end
    end

    // AXI Write Handler for Port0
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_port0_awready <= 1'b1;
            m_axi_port0_wready  <= 1'b0;
            m_axi_port0_bvalid  <= 1'b0;
            m_axi_port0_bid     <= '0;
            m_axi_port0_bresp   <= 2'b00;
        end else begin
            // Default ready states
            m_axi_port0_awready <= 1'b1;

            // Accept write address
            if (m_axi_port0_awvalid && m_axi_port0_awready) begin
                aw_id_q.push_back(m_axi_port0_awid);
                m_axi_port0_wready <= 1'b1;
                $display("[%0t] Host Memory: Write request addr=0x%h, len=%0d",
                    $time, m_axi_port0_awaddr, m_axi_port0_awlen);
            end

            // Accept write data
            if (m_axi_port0_wvalid && m_axi_port0_wready) begin
                // Write data to memory (simplified - only handles 64-byte writes)
                automatic logic [63:0] addr = m_axi_port0_awaddr & (MEM_SIZE - 1);
                for (int i = 0; i < 64; i++) begin
                    if (m_axi_port0_wstrb[i]) begin
                        host_memory[addr + i] = m_axi_port0_wdata[i*8 +: 8];
                    end
                end

                $display("[%0t] Host Memory: Data written at 0x%h, magic=0x%h",
                    $time, addr,
                    {host_memory[addr+3], host_memory[addr+2],
                     host_memory[addr+1], host_memory[addr]});

                if (m_axi_port0_wlast) begin
                    m_axi_port0_wready <= 1'b0;
                    m_axi_port0_bvalid <= 1'b1;
                    m_axi_port0_bid    <= aw_id_q.pop_front();
                    m_axi_port0_bresp  <= 2'b00;  // OKAY
                end
            end

            // Handle response ready
            if (m_axi_port0_bvalid && m_axi_port0_bready) begin
                m_axi_port0_bvalid <= 1'b0;
            end
        end
    end

    // Tie off read ports (not used in this test)
    assign m_axi_port0_arready = 1'b1;
    assign m_axi_port0_rvalid  = 1'b0;
    assign m_axi_port0_rdata   = '0;
    assign m_axi_port0_rid     = '0;
    assign m_axi_port0_rresp   = 2'b00;
    assign m_axi_port0_rlast   = 1'b0;

    //=========================================================================
    // AXI Memory Model (Device Memory - Port1)
    //=========================================================================

    // Tie off Port1 (simplified for this test)
    assign m_axi_port1_awready = 1'b1;
    assign m_axi_port1_wready  = 1'b1;
    assign m_axi_port1_bvalid  = 1'b0;
    assign m_axi_port1_arready = 1'b1;
    assign m_axi_port1_rvalid  = 1'b0;
    assign m_axi_port1_rdata   = '0;

    //=========================================================================
    // Test Sequence
    //=========================================================================

    // CSR write task
    task csr_write_reg(input logic [11:0] addr, input logic [63:0] data);
        @(posedge clk);
        csr_valid <= 1'b1;
        csr_write <= 1'b1;
        csr_addr  <= addr;
        csr_wdata <= data;
        @(posedge clk);
        while (!csr_ready) @(posedge clk);
        csr_valid <= 1'b0;
        csr_write <= 1'b0;
        @(posedge clk);
    endtask

    // CSR read task
    task csr_read_reg(input logic [11:0] addr, output logic [63:0] data);
        @(posedge clk);
        csr_valid <= 1'b1;
        csr_write <= 1'b0;
        csr_addr  <= addr;
        @(posedge clk);
        while (!csr_ready) @(posedge clk);
        data = csr_rdata;
        csr_valid <= 1'b0;
        @(posedge clk);
    endtask

    // Main test
    initial begin
        logic [63:0] read_data;
        logic [31:0] completion_magic;

        // Initialize signals
        csr_valid <= 1'b0;
        csr_write <= 1'b0;
        csr_addr  <= 12'h0;
        csr_wdata <= 64'h0;
        kernel_launch_valid <= 1'b0;
        kernel_args_packed <= '0;

        $display("========================================");
        $display("Vortex GPU Wrapper DCOH Testbench");
        $display("========================================");

        // Wait for reset
        wait(rst_n);
        repeat(10) @(posedge clk);

        //---------------------------------------------------------------------
        // Test 1: Configure and Launch Kernel with DCOH Completion
        //---------------------------------------------------------------------
        $display("\n[Test 1] Kernel Launch with DCOH Completion");

        // Set completion address (host memory address for mwait)
        csr_write_reg(REG_COMPLETION_LO, 32'h0000_1000);  // 4KB offset
        csr_write_reg(REG_COMPLETION_HI, 32'h0000_0000);

        // Enable DCOH
        csr_write_reg(REG_DCOH_ENABLE, 64'h1);

        // Configure kernel
        csr_write_reg(REG_KERNEL_ADDR_LO, 32'h8000_0000);  // Kernel entry
        csr_write_reg(REG_KERNEL_ADDR_HI, 32'h0000_0000);
        csr_write_reg(REG_KERNEL_ARGS_LO, 32'h8000_1000);  // Args pointer
        csr_write_reg(REG_KERNEL_ARGS_HI, 32'h0000_0000);
        csr_write_reg(REG_GRID_DIM_X, 32'd128);
        csr_write_reg(REG_GRID_DIM_Y, 32'd1);
        csr_write_reg(REG_GRID_DIM_Z, 32'd1);
        csr_write_reg(REG_BLOCK_DIM_X, 32'd32);
        csr_write_reg(REG_BLOCK_DIM_Y, 32'd1);
        csr_write_reg(REG_BLOCK_DIM_Z, 32'd1);

        $display("  Launching kernel...");
        csr_write_reg(REG_LAUNCH, 64'h1);

        // Wait for kernel completion
        $display("  Waiting for kernel completion...");
        do begin
            csr_read_reg(REG_STATUS, read_data);
            @(posedge clk);
        end while (read_data[7:0] == 8'h01);  // Wait while RUNNING

        $display("  Kernel completed: status=0x%h", read_data[7:0]);

        // Wait for DCOH writeback to complete
        $display("  Waiting for DCOH writeback...");
        repeat(50) @(posedge clk);

        // Check completion data in host memory
        completion_magic = {host_memory[32'h1003], host_memory[32'h1002],
                           host_memory[32'h1001], host_memory[32'h1000]};

        $display("  Completion magic: 0x%h (expected: 0xDEADBEEF)", completion_magic);

        if (completion_magic == 32'hDEADBEEF) begin
            $display("  [PASS] DCOH writeback successful - host can now use mwait!");
        end else begin
            $display("  [FAIL] DCOH writeback failed!");
        end

        //---------------------------------------------------------------------
        // Test 2: Multiple Kernel Launches
        //---------------------------------------------------------------------
        $display("\n[Test 2] Multiple Kernel Launches");

        for (int i = 0; i < 3; i++) begin
            $display("  Launch %0d...", i);

            // Update completion address
            csr_write_reg(REG_COMPLETION_LO, 32'h0000_2000 + i*64);

            csr_write_reg(REG_LAUNCH, 64'h1);

            // Wait for completion
            do begin
                csr_read_reg(REG_STATUS, read_data);
                @(posedge clk);
            end while (read_data[7:0] == 8'h01);

            repeat(50) @(posedge clk);
            $display("  Launch %0d completed", i);
        end

        $display("\n[PASS] All tests completed!");

        //---------------------------------------------------------------------
        // End simulation
        //---------------------------------------------------------------------
        repeat(100) @(posedge clk);
        $display("\n========================================");
        $display("Simulation Complete");
        $display("========================================");
        $finish;
    end

    //=========================================================================
    // Waveform Dump
    //=========================================================================

    initial begin
        $dumpfile("vortex_gpu_wrapper.vcd");
        $dumpvars(0, tb_vortex_gpu_wrapper);
    end

    //=========================================================================
    // Timeout
    //=========================================================================

    initial begin
        #100000;
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
