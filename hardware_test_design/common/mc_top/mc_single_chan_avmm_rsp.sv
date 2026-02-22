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

module mc_single_chan_avmm_rsp
  import ddr_mc_top_common_pkg::*;
(
  input logic emifclk,                         // EMIF User Clock
  input logic emifresetn,                      // EMIF reset
  input logic emif_avmm_1_axi_0,
  input logic ram_init_done_del1_emifclk, 

  /* read id fifo and write id from EMIF AVMM FSM
  */
  input logic                                                     from_avmm_fsm_valid_write_id_emifclk,
  input logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] from_avmm_fsm_write_id_emifclk,
  input logic                                                     from_avmm_fsm_valid_read_id_emifclk,
  input logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] from_avmm_fsm_read_id_emifclk,
 
  /* AVMM signals from EMIF
  */
  input logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] from_emif_avmm_readdata_emifclk,
 
  input logic from_emif_avmm_readdatavalid_emifclk,

  /* write responses
  */
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] avmm_wr_rsp_id_emifclk,
 
  output logic avmm_wr_rsp_valid_emifclk,
 
  /* read responses
  */
  output logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_DATA_WIDTH-1:0] avmm_rd_rsp_data_emifclk,
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    avmm_rd_rsp_id_emifclk,

  output logic avmm_rd_rsp_id_fifo_almost_full_emifclk,
  output logic avmm_rd_rsp_valid_emifclk
);

// ================================================================================================
/* handle write responses in one cycle
*/
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] avmm_wr_rsp_id_comb;

logic avmm_wr_rsp_valid_comb;

assign avmm_wr_rsp_id_comb = ~emif_avmm_1_axi_0
                             ? '0
                             : from_avmm_fsm_valid_write_id_emifclk
                               ? from_avmm_fsm_write_id_emifclk
                               : avmm_wr_rsp_id_emifclk;

assign avmm_wr_rsp_valid_comb = ~emif_avmm_1_axi_0
                                ? 1'b0
                                : from_avmm_fsm_valid_write_id_emifclk;

always_ff @( posedge emifclk )
begin
  avmm_wr_rsp_valid_emifclk <= ~emifresetn ? 1'b0 : avmm_wr_rsp_valid_comb;
     avmm_wr_rsp_id_emifclk <= ~emifresetn ?  '0  : avmm_wr_rsp_id_comb;
end
 
// ================================================================================================ 
/* Handle the read IDs - 
   for AVMM, all transactions go out in-order of arrival
   for AXI, transactions can go out-of-order from arrival
*/
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] rd_id_fifo_q;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] rd_id_fifo_din;

logic [7:0]  rd_id_fifo_usedw;

logic rd_if_fifo_wen;
logic rd_id_fifo_empty;
logic rd_id_fifo_rd_enable;
logic rd_id_fifo_full;

assign rd_if_fifo_wen = emif_avmm_1_axi_0 & from_avmm_fsm_valid_read_id_emifclk;

assign rd_id_fifo_din = from_avmm_fsm_read_id_emifclk;

assign rd_id_fifo_rd_enable = emif_avmm_1_axi_0 & from_emif_avmm_readdatavalid_emifclk;

fifo_12b_256w_show_ahead     HdmReadIDAttrFifo
(
     .clock(   emifclk              ),
     .aclr(   ~emifresetn           ),
     .wrreq(   rd_if_fifo_wen       ),
     .data(    rd_id_fifo_din       ),
     .rdreq(   rd_id_fifo_rd_enable ),
     .q(       rd_id_fifo_q         ),
     .full(    rd_id_fifo_full      ),
     .usedw(   rd_id_fifo_usedw     ),
     .empty(   rd_id_fifo_empty     )
);

// ================================================================================================ 
logic rd_id_fifo_almost_full;

assign rd_id_fifo_almost_full = ( rd_id_fifo_usedw >= 'd248 );

always_ff @( posedge emifclk )
begin
   avmm_rd_rsp_id_fifo_almost_full_emifclk <= ~emifresetn ? 1'b0 : rd_id_fifo_almost_full;
end

// ================================================================================================ 
assign avmm_rd_rsp_valid_emifclk = from_emif_avmm_readdatavalid_emifclk;

assign avmm_rd_rsp_id_emifclk = rd_id_fifo_q;

assign avmm_rd_rsp_data_emifclk = from_emif_avmm_readdata_emifclk;

// ================================================================================================  
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL5iyL1V3YID4BYqlnTIJdWvmJF+EN5pCRMWhOND84SJeMdPA9bATO88XZ4+E30E2MM23qWdwXyfmxhNeoQpj3HQrh5n68J4GEmqsDg3a1B7YR4mKjZ95gqmGictSSMbaoUB5w/J4VAYHoS2DVfS+O6h3qayyGs7nrp/I8kTjusXaGcO4+6W3H/BTxZiexLi+N8/ZVob3JUKHhpQBUVs8HrHJvkPSG8dcJ+nixUFXYO2HtaN2Dkol0AkMpS3+tiZ6eGtYBEYHoZNPCj/TVqDMg50ukCJuL2t6TWACj0GcB15ZiFZ5WOqk9Msgq85hexuxAsVYL/D1ZKCx82arFVFM1aPwfpOrl0MKXuKSNMROGny3zASI8I73Ywl8acYSE9NPMbJdGJXhAuTuaiuTAa1EnfRlFmJfsftZ4NvrKGsHDjXK4DN3ogBbSRNyXgpQgYAsK5fBg9YEC4Z/fMKNr7CJm3jBREnQjYUO15AS/yP/Ji0lUj77T0f4Sj0va0RE+yXncS8z41qegshJdnLlt/cO0qtbyjQ5nM2qhETDo/qms5j3zrBtkTJ1sgQkOhuczdXKj4/CgQFrL9ytoyi1pEFykE/8p8vjLLlehEVra5MqqtAwkhpfQCaUWb8R99SqfyTT0P+z9p8iqYea1myywSbhPeukT6gLj3L2c2GK5DLeMPqROqWUR5oMNh4FBnaE1Ujp8D10dV6QAFZVbAAkMrPZQsugZFdM+35my/bl9JpdY6TuD7p+lQpYbCh70CGGFMlRaVjagF0cptDdak0fye3y540"
`endif