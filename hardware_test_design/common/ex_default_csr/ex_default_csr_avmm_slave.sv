// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any output
// files from any of the foregoing (including device programming or simulation
// files), and any associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License Subscription
// Agreement, Altera IP License Agreement, or other applicable
// license agreement, including, without limitation, that your use is for the
// sole purpose of programming logic devices manufactured by Altera and sold by
// Altera or its authorized distributors.  Please refer to the applicable
// agreement for further details.


// Copyright 2023 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

module ex_default_csr_avmm_slave(

// AVMM Slave Interface
   input               clk,
   input               reset_n,
   input  logic [63:0] writedata,
   input  logic        read,
   input  logic        write,
   input  logic [7:0]  byteenable,
   output logic [63:0] readdata,
   output logic        readdatavalid,
   input  logic [31:0] address,
   input  logic        poison,
   output logic        waitrequest,
   output logic [31:0] read_delay,

   // Vortex GPU CSR interface (directly accessible from host MMIO)
   // Launch trigger — active for one cycle when host writes 1 to REG_LAUNCH
   output logic        vx_launch_trigger,
   // Configuration registers — stable between launches
   output logic [63:0] vx_kernel_addr,
   output logic [63:0] vx_kernel_args,
   output logic [31:0] vx_grid_dim_x,
   output logic [31:0] vx_grid_dim_y,
   output logic [31:0] vx_grid_dim_z,
   output logic [31:0] vx_block_dim_x,
   output logic [31:0] vx_block_dim_y,
   output logic [31:0] vx_block_dim_z,
   // Status feedback from GPU core
   input  logic [7:0]  vx_status,
   input  logic [63:0] vx_cycles,
   input  logic [63:0] vx_instrs
);

 // ===================================================================
 // Original test register (address 0x000)
 // ===================================================================

 logic [31:0] csr_test_reg;
 assign read_delay = csr_test_reg;

 logic [63:0] mask ;
 logic config_access;

 assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0;
 assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0;
 assign mask[23:16] = byteenable[2]? 8'hFF:8'h0;
 assign mask[31:24] = byteenable[3]? 8'hFF:8'h0;
 assign mask[39:32] = byteenable[4]? 8'hFF:8'h0;
 assign mask[47:40] = byteenable[5]? 8'hFF:8'h0;
 assign mask[55:48] = byteenable[6]? 8'hFF:8'h0;
 assign mask[63:56] = byteenable[7]? 8'hFF:8'h0;
 assign config_access = address[21];

 // ===================================================================
 // Vortex GPU CSR Registers (addresses 0x100-0x14C)
 // Matching userspace driver vortex_cxl.h
 // ===================================================================

 // Vortex CSR byte addresses
 localparam [21:0] REG_KERNEL_ADDR_LO = 22'h100;
 localparam [21:0] REG_KERNEL_ADDR_HI = 22'h104;
 localparam [21:0] REG_KERNEL_ARGS_LO = 22'h108;
 localparam [21:0] REG_KERNEL_ARGS_HI = 22'h10C;
 localparam [21:0] REG_GRID_DIM_X     = 22'h110;
 localparam [21:0] REG_GRID_DIM_Y     = 22'h114;
 localparam [21:0] REG_GRID_DIM_Z     = 22'h118;
 localparam [21:0] REG_BLOCK_DIM_X    = 22'h11C;
 localparam [21:0] REG_BLOCK_DIM_Y    = 22'h120;
 localparam [21:0] REG_BLOCK_DIM_Z    = 22'h124;
 localparam [21:0] REG_LAUNCH         = 22'h128;
 localparam [21:0] REG_STATUS         = 22'h12C;
 localparam [21:0] REG_CYCLE_LO       = 22'h130;
 localparam [21:0] REG_CYCLE_HI       = 22'h134;
 localparam [21:0] REG_INSTR_LO       = 22'h138;
 localparam [21:0] REG_INSTR_HI       = 22'h13C;
 localparam [21:0] REG_DEV_ID         = 22'h000;

 // Device identification
 localparam [31:0] VORTEX_DEV_ID      = 32'h56585432;  // "VXT2" in ASCII

 // Internal register file
 logic [31:0] reg_kernel_addr_lo;
 logic [31:0] reg_kernel_addr_hi;
 logic [31:0] reg_kernel_args_lo;
 logic [31:0] reg_kernel_args_hi;
 logic [31:0] reg_grid_dim_x;
 logic [31:0] reg_grid_dim_y;
 logic [31:0] reg_grid_dim_z;
 logic [31:0] reg_block_dim_x;
 logic [31:0] reg_block_dim_y;
 logic [31:0] reg_block_dim_z;

 // Export configuration to GPU core
 assign vx_kernel_addr = {reg_kernel_addr_hi, reg_kernel_addr_lo};
 assign vx_kernel_args = {reg_kernel_args_hi, reg_kernel_args_lo};
 assign vx_grid_dim_x  = reg_grid_dim_x;
 assign vx_grid_dim_y  = reg_grid_dim_y;
 assign vx_grid_dim_z  = reg_grid_dim_z;
 assign vx_block_dim_x = reg_block_dim_x;
 assign vx_block_dim_y = reg_block_dim_y;
 assign vx_block_dim_z = reg_block_dim_z;

 // Address decode helper — is this a Vortex CSR access?
 wire vortex_access = (address[21:0] >= 22'h100) && (address[21:0] <= 22'h13C)
                      && !config_access;

//Terminating extented capability header
localparam EX_CAP_HEADER  = 32'h00010023;
localparam EX_CAP_HEADER1 = 32'h00801E98;


//Write logic
always @(posedge clk) begin
    if (!reset_n) begin
        csr_test_reg       <= 32'h20;
        reg_kernel_addr_lo <= 32'h0;
        reg_kernel_addr_hi <= 32'h0;
        reg_kernel_args_lo <= 32'h0;
        reg_kernel_args_hi <= 32'h0;
        reg_grid_dim_x     <= 32'h1;
        reg_grid_dim_y     <= 32'h1;
        reg_grid_dim_z     <= 32'h1;
        reg_block_dim_x    <= 32'h1;
        reg_block_dim_y    <= 32'h1;
        reg_block_dim_z    <= 32'h1;
        vx_launch_trigger  <= 1'b0;
    end
    else begin
        // Default: clear pulse
        vx_launch_trigger <= 1'b0;

        if (write && ~poison) begin
            // Original test register
            if (address[21:0] == 22'h0000) begin
                csr_test_reg <= (writedata[31:0] & mask[31:0]) | (csr_test_reg & ~mask[31:0]);
            end
            else if (address[20:0] == 21'h00E08 && config_access) begin
                csr_test_reg <= writedata & mask;
            end
            // Vortex GPU CSR writes
            else if (!config_access) begin
                case (address[21:0])
                    REG_KERNEL_ADDR_LO: reg_kernel_addr_lo <= (writedata[31:0] & mask[31:0]) | (reg_kernel_addr_lo & ~mask[31:0]);
                    REG_KERNEL_ADDR_HI: reg_kernel_addr_hi <= (writedata[31:0] & mask[31:0]) | (reg_kernel_addr_hi & ~mask[31:0]);
                    REG_KERNEL_ARGS_LO: reg_kernel_args_lo <= (writedata[31:0] & mask[31:0]) | (reg_kernel_args_lo & ~mask[31:0]);
                    REG_KERNEL_ARGS_HI: reg_kernel_args_hi <= (writedata[31:0] & mask[31:0]) | (reg_kernel_args_hi & ~mask[31:0]);
                    REG_GRID_DIM_X:     reg_grid_dim_x     <= (writedata[31:0] & mask[31:0]) | (reg_grid_dim_x     & ~mask[31:0]);
                    REG_GRID_DIM_Y:     reg_grid_dim_y     <= (writedata[31:0] & mask[31:0]) | (reg_grid_dim_y     & ~mask[31:0]);
                    REG_GRID_DIM_Z:     reg_grid_dim_z     <= (writedata[31:0] & mask[31:0]) | (reg_grid_dim_z     & ~mask[31:0]);
                    REG_BLOCK_DIM_X:    reg_block_dim_x    <= (writedata[31:0] & mask[31:0]) | (reg_block_dim_x    & ~mask[31:0]);
                    REG_BLOCK_DIM_Y:    reg_block_dim_y    <= (writedata[31:0] & mask[31:0]) | (reg_block_dim_y    & ~mask[31:0]);
                    REG_BLOCK_DIM_Z:    reg_block_dim_z    <= (writedata[31:0] & mask[31:0]) | (reg_block_dim_z    & ~mask[31:0]);
                    REG_LAUNCH: begin
                        if (writedata[0])
                            vx_launch_trigger <= 1'b1;
                    end
                    // REG_STATUS, REG_CYCLE_*, REG_INSTR_* are read-only
                    default: ;
                endcase
            end
        end
    end
end

//Read logic
always @(posedge clk) begin
    if (!reset_n) begin
        readdata  <= 64'h0;
    end
    else begin
        if (read) begin
            // Original test register
            if (address[21:0] == 22'h0) begin
                readdata <= {32'h0, csr_test_reg & mask[31:0]};
            end
            // Extended capability headers (config space)
            else if (address[20:0] == 21'h00E00 && config_access) begin
                readdata <= {EX_CAP_HEADER} & mask;
            end
            else if (address[20:0] == 21'h00E04 && config_access) begin
                readdata <= {EX_CAP_HEADER1} & mask;
            end
            else if (address[20:0] == 21'h00E08 && config_access) begin
                readdata <= csr_test_reg & mask;
            end
            // Vortex GPU CSR reads
            else if (!config_access) begin
                case (address[21:0])
                    REG_KERNEL_ADDR_LO: readdata <= {32'h0, reg_kernel_addr_lo} & mask;
                    REG_KERNEL_ADDR_HI: readdata <= {32'h0, reg_kernel_addr_hi} & mask;
                    REG_KERNEL_ARGS_LO: readdata <= {32'h0, reg_kernel_args_lo} & mask;
                    REG_KERNEL_ARGS_HI: readdata <= {32'h0, reg_kernel_args_hi} & mask;
                    REG_GRID_DIM_X:     readdata <= {32'h0, reg_grid_dim_x}     & mask;
                    REG_GRID_DIM_Y:     readdata <= {32'h0, reg_grid_dim_y}     & mask;
                    REG_GRID_DIM_Z:     readdata <= {32'h0, reg_grid_dim_z}     & mask;
                    REG_BLOCK_DIM_X:    readdata <= {32'h0, reg_block_dim_x}    & mask;
                    REG_BLOCK_DIM_Y:    readdata <= {32'h0, reg_block_dim_y}    & mask;
                    REG_BLOCK_DIM_Z:    readdata <= {32'h0, reg_block_dim_z}    & mask;
                    REG_LAUNCH:         readdata <= 64'h0;  // Write-only
                    REG_STATUS:         readdata <= {56'h0, vx_status}          & mask;
                    REG_CYCLE_LO:       readdata <= {32'h0, vx_cycles[31:0]}   & mask;
                    REG_CYCLE_HI:       readdata <= {32'h0, vx_cycles[63:32]}  & mask;
                    REG_INSTR_LO:       readdata <= {32'h0, vx_instrs[31:0]}   & mask;
                    REG_INSTR_HI:       readdata <= {32'h0, vx_instrs[63:32]}  & mask;
                    default:            readdata <= 64'h0;
                endcase
            end
            else begin
                readdata <= 64'h0;
            end
        end
    end
end


//Control Logic
enum int unsigned { IDLE = 0,WRITE = 2, READ = 4 } state, next_state;

always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin
                   if( write ) begin
                       next_state = WRITE;
                   end
                   else begin
                     if (read) begin
                       next_state = READ;
                     end
                     else begin
                       next_state = IDLE;
                     end
                   end
                end
      WRITE     : begin
                   next_state = IDLE;
                end
      READ      : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end


always_comb begin
   case(state)
   IDLE    : begin
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   WRITE     : begin
               waitrequest  = 1'b0;
               readdatavalid= 1'b0;
             end
   READ     : begin
               waitrequest  = 1'b0;
               readdatavalid= 1'b1;
             end
   default : begin
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

endmodule
