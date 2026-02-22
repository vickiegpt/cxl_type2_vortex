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


// Copyright 2024 Intel Corporation.
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
///////////////////////////////////////////////////////////////////////

/*
   This version aims to treat ram_init like it's a lookahead fifo
*/

module mc_single_chan_ram_init_ver2
  import ddr_mc_top_common_pkg::*;
#(
  parameter USE_ORIGINAL_RAM_INIT = 0,  // 0 - OFF; 1 - ON
  parameter MC_RAM_INIT_W_ZERO_EN = 1,  // 0 - OFF; 1 - ON
  parameter RST_REG_NUM           = 2
 )
(
  input logic                   emifclk,
  input logic                   emifresetn,
  input logic [RST_REG_NUM-1:0] emifresetn_reg,

  input logic emif_avmm_1_axi_0,
  input logic from_rmw_ren_emifclk,
  input logic from_rmw_memory_ready_emifclk,
  input logic from_emif_write_resp_valid_emifclk,
 
  output logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_emifclk,
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    ram_init_wr_id_emifclk,

  output logic ram_init_done_emifclk,
  output logic ram_init_done_del1_emifclk,
  output logic ram_init_wr_en_emifclk,
  output logic ram_init_addr_equals_final_addr_emifclk
);

// ================================================================================================
`ifdef SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY

   localparam FINAL_ADDR = 0;

   logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] start_addr;
   assign start_addr = '0;

`elsif SIM_MC_RAM_INIT_W_ZERO_PARTIAL_ONLY

   localparam FINAL_ADDR = ((2**(ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH)) - 1);

   logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] start_addr;
   assign start_addr = FINAL_ADDR - 'd128;

`else

   localparam FINAL_ADDR = ((2**(ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH)) - 1);

   logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] start_addr;
   assign start_addr = '0;

`endif

// ================================================================================================
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_comb;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_plus1;

logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_comb;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_plus1;

logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_comb;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_plus1;

logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] ram_init_wr_id_comb;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] ram_init_wr_id_plus1;

logic [2:0] sync_counter_comb;
logic [2:0] sync_counter_emifclk;
logic       sync_counter_equals_zero;

logic ram_init_done_comb;
logic ram_init_wr_en_comb;
logic ram_init_addr_equals_final_addr;
logic wr_req_count_equals_wr_resp_count;

// ================================================================================================
assign ram_init_addr_equals_final_addr_emifclk = ram_init_addr_equals_final_addr;

assign ram_init_addr_equals_final_addr = ( ram_init_addr_emifclk == FINAL_ADDR );

assign sync_counter_equals_zero = ( sync_counter_emifclk == '0 );

assign wr_req_count_equals_wr_resp_count = ( write_req_counter_emifclk == write_resp_counter_emifclk );

assign write_req_counter_plus1 = ( write_req_counter_emifclk + 'd1 );

assign write_resp_counter_plus1 = ( write_resp_counter_emifclk + 'd1 );

assign ram_init_addr_plus1 = ( ram_init_addr_emifclk + 'd1 );

assign ram_init_wr_id_plus1 = ( ram_init_wr_id_emifclk + 'd1 );

// ================================================================================================ sync counter out of reset
assign sync_counter_comb = ( ram_init_done_emifclk | sync_counter_equals_zero )
                           ? '0
                           : ( sync_counter_emifclk - 3'b001 );

always_ff @( posedge emifclk )
begin
  sync_counter_emifclk <= ( ~emifresetn ) ? 3'b111 : sync_counter_comb;
end

// ================================================================================================ ram init done delay
generate if( MC_RAM_INIT_W_ZERO_EN == 1 )
begin : gen_done_delay_on

  always_ff @(posedge emifclk)
  begin
    ram_init_done_del1_emifclk <= ( ~emifresetn_reg[RST_REG_NUM-2] ) ? 1'b0 : ram_init_done_emifclk;
  end

end
else begin : gen_done_delay_off

  assign ram_init_done_del1_emifclk = 1'b1;

end
endgenerate

// ================================================================================================
generate if( (USE_ORIGINAL_RAM_INIT == 0) & (MC_RAM_INIT_W_ZERO_EN == 1) ) // ===================== ram init on, new
begin : gen_ram_init_on_new

  // ============================================================================================== handle the wr enable
  always_comb
  begin
    ram_init_wr_en_comb = ram_init_wr_en_emifclk;

         if( ram_init_done_emifclk )    ram_init_wr_en_comb = 1'b0;
    else if( sync_counter_equals_zero ) ram_init_wr_en_comb = 1'b1;
  end
  
  always_ff @(posedge emifclk) ram_init_wr_en_emifclk <= ( ~emifresetn ) ? 1'b0 : ram_init_wr_en_comb;

  // ============================================================================================== handle the id and address
  always_comb
  begin
      ram_init_wr_id_comb = ram_init_wr_id_emifclk;
      ram_init_addr_comb  = ram_init_addr_emifclk;

      if( from_rmw_ren_emifclk & ~ram_init_addr_equals_final_addr )
      begin
        ram_init_wr_id_comb = ram_init_wr_id_plus1;
        ram_init_addr_comb  = ram_init_addr_plus1;
      end
  end

  always_ff @(posedge emifclk) ram_init_wr_id_emifclk <= ( ~emifresetn ) ? '0 : ram_init_wr_id_comb;

  always_ff @(posedge emifclk) ram_init_addr_emifclk <= ( ~emifresetn ) ? start_addr : ram_init_addr_comb;

  // ============================================================================================== write request counter
  always_comb
  begin
    write_req_counter_comb = write_req_counter_emifclk;

    if( ~ram_init_done_emifclk & from_rmw_ren_emifclk )
    begin
      write_req_counter_comb = write_req_counter_plus1;
    end
  end

  always_ff @(posedge emifclk) write_req_counter_emifclk <= ( ~emifresetn ) ?'0 : write_req_counter_comb;

  // ============================================================================================== write response counter
  always_comb
  begin
    write_resp_counter_comb = write_resp_counter_emifclk;

    if( ~ram_init_done_emifclk & from_emif_write_resp_valid_emifclk )
    begin
      write_resp_counter_comb = write_resp_counter_plus1;
    end
  end

  always_ff @(posedge emifclk) write_resp_counter_emifclk <= ( ~emifresetn ) ? '0 : write_resp_counter_comb;

  // ============================================================================================== handle ram_init_done
  always_comb
  begin
    if( ram_init_addr_equals_final_addr & wr_req_count_equals_wr_resp_count )
    begin
      ram_init_done_comb = 1'b1;
    end
    else begin
      ram_init_done_comb = ram_init_done_emifclk;
    end
  end

  always_ff @(posedge emifclk) ram_init_done_emifclk  <= ( ~emifresetn ) ? 1'b0 : ram_init_done_comb;

end
else if( (USE_ORIGINAL_RAM_INIT == 1) & (MC_RAM_INIT_W_ZERO_EN == 1) ) // ========================= ram init on original
begin : gen_ram_init_on_old

  assign ram_init_addr_comb = '0;
  assign ram_init_wr_id_comb = '0;

  always_ff @(posedge emifclk)
  begin
    if( from_rmw_memory_ready_emifclk & ~ram_init_done_emifclk )
  begin
    ram_init_addr_emifclk  <= ram_init_addr_emifclk  + 'd1;
    ram_init_wr_id_emifclk <= ram_init_wr_id_emifclk + 'd1;
    end

    if (~emifresetn_reg[RST_REG_NUM-1])
  begin
    ram_init_addr_emifclk  <= '0;
    ram_init_wr_id_emifclk <= '0;
    end
  end

  `ifdef SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY // To skip whole or majority of memory initialization - used in t2ip but not t3ip

     always_ff @(posedge emifclk)
     begin
        ram_init_done_emifclk <= ~emifresetn
                                 ? 1'b0
                                 : ( from_rmw_memory_ready_emifclk & ( ram_init_addr_emifclk == '0 ))
                                   ? 1'b1
                                   : ram_init_done_emifclk;
     end

  `else

     always_ff @(posedge emifclk)
     begin
        ram_init_done_emifclk <= ~emifresetn
                                 ? 1'b0
                                 : ( from_rmw_memory_ready_emifclk & ram_init_addr_equals_final_addr )
                                   ? 1'b1
                                   : ram_init_done_emifclk;
     end

  `endif

  assign write_req_counter_comb = '0;
  assign write_req_counter_emifclk = '0;

  assign write_resp_counter_comb = '0;
  assign write_resp_counter_emifclk = '0;

  assign ram_init_wr_en_comb = 1'b0;
  assign ram_init_wr_en_emifclk = 1'b1;

  assign ram_init_done_comb = 1'b0;

end
else begin : gen_ram_init_off // ====================================================================================== ram init off

  assign ram_init_addr_comb = '0;
  assign ram_init_addr_emifclk = '0;

  assign ram_init_wr_id_comb = '0;
  assign ram_init_wr_id_emifclk = '0;

  assign write_req_counter_comb = '0;
  assign write_req_counter_emifclk = '0;

  assign write_resp_counter_comb = '0;
  assign write_resp_counter_emifclk = '0;

  assign ram_init_wr_en_comb = 1'b0;
  assign ram_init_wr_en_emifclk = 1'b0;

  assign ram_init_done_comb = 1'b1;
  assign ram_init_done_emifclk = 1'b1;

end
endgenerate

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3SOQ5Bcj54ejNABuTzc4s08bsInBV9nxbYmth3JF+T1ldu+TyrVsS7gpvBYCKWt53t99MoQRdDvOpBAfHNegfEWJuZcxS70EXk+zOyGA5P8JPa7OyH3VoYKYEWZOVYFJqiC33OLMM5V7Z7HdsSgtoUK68Yw01ohJPmNiVnzqkobpKGL1jBynL8oSncDUFc9CmJLyNRq7hHegw1QzH+X/5gGU5qkgQvekgMNpV+Ex2K6rZzuhLVfcaT+t4Eo567vQes7GFgicQbM9JnHklKj2e5b4XYpsjvZwOeREtdIxeJphdJ5QbLP3hSoZD924nQYXXxE/0Y7zZ9nUHnESViXlXBEMoRKpTkXNPpVYE5ZyXfOKfYhm398E0mC5scm6jQPG9OhJUMyE4cW6QkKoTmuJpAg/lIJ2MlV5kW1CvWiPZ9aBPqcc6zumRyGzkriK+5DyXGGHB/mNQ9jizRH2GC1T4luU1CKsRB+Ti7QLoDpWJgR6NXbpMZAYDOxNpi6QnXR4Xs1Pq0f4hLpX1qKWSYBuyXSYT3ORXh9blqa/3bVM+CXTH7qPmbVIcV715FJEezAx8KIijZf4dgM1naA0FrCkhYk5TG1Uv2Ytrl7/MS1ndvBMDgd7kD8bPb/RJ53dI+mG1CK5y0w04kugjcDlEUFxbAk3HH4FHILbM1l4xQuYvcl35upBjsUVy28pQ1bwaB8HUJh+qUQPEOgeT5ovAxH3R1flNCzCebaQFLVTBcRMsWFTrXh8e1+N8csutpQ3ARuXPvilTfU3h65M0H/Xc4xOvmj"
`endif