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

module ex_default_csr_top (
    input  logic        csr_avmm_clk,
    input  logic        csr_avmm_rstn,
    output logic        csr_avmm_waitrequest,
    output logic [63:0] csr_avmm_readdata,
    output logic        csr_avmm_readdatavalid,
    input  logic [63:0] csr_avmm_writedata,
    input  logic        csr_avmm_poison,
    input  logic [21:0] csr_avmm_address,
    input  logic        csr_avmm_write,
    input  logic        csr_avmm_read,
    input  logic [7:0]  csr_avmm_byteenable,
    output logic [31:0] read_delay,

    // Vortex GPU control interface — active-high launch pulse
    output logic        vx_launch_trigger,
    // Configuration registers
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

//CSR block

   ex_default_csr_avmm_slave ex_default_csr_avmm_slave_inst(
       .clk          (csr_avmm_clk),
       .reset_n      (csr_avmm_rstn),
       .writedata    (csr_avmm_writedata),
       .read         (csr_avmm_read),
       .write        (csr_avmm_write),
       .poison       (csr_avmm_poison),
       .byteenable   (csr_avmm_byteenable),
       .readdata     (csr_avmm_readdata),
       .readdatavalid(csr_avmm_readdatavalid),
       .address      ({10'h0,csr_avmm_address}),
       .waitrequest  (csr_avmm_waitrequest),
       .read_delay   (read_delay),
       // Vortex GPU interface
       .vx_launch_trigger (vx_launch_trigger),
       .vx_kernel_addr    (vx_kernel_addr),
       .vx_kernel_args    (vx_kernel_args),
       .vx_grid_dim_x     (vx_grid_dim_x),
       .vx_grid_dim_y     (vx_grid_dim_y),
       .vx_grid_dim_z     (vx_grid_dim_z),
       .vx_block_dim_x    (vx_block_dim_x),
       .vx_block_dim_y    (vx_block_dim_y),
       .vx_block_dim_z    (vx_block_dim_z),
       .vx_status         (vx_status),
       .vx_cycles         (vx_cycles),
       .vx_instrs         (vx_instrs)
   );

endmodule
