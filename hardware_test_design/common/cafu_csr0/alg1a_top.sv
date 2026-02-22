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
///////////////////////////////////////////////////////////////////////
`include "ccv_afu_globals.vh.iv"

module alg1a_top
    import ccv_afu_pkg::*;
    import ccv_afu_alg1a_pkg::*;
    import cafu_common_pkg::*;
(
  input logic clk,
  input logic reset_n,    // active low reset

  /*  signals for latency mode
  */
  input logic i_latency_mode_enable,
  input logic i_writes_only_mode_enable,
  input logic i_reads_only_mode_enable,

  output logic [19:0] extended_loop_count,

  /* signals to/from ccv afu top-level FSM
  */
   input logic i_enable,                                  // active high
   input logic i_mwae_busy,                               // active high
   input logic i_mwae_set_to_busy,                        // active high
  output logic o_alg1a_busy,                              // active high
  output logic o_execute_phase_busy,                      // active high
  output logic o_execute_response_slverr_received,        // active high
  output logic o_verify_sc_phase_busy,                    // active high
  output logic o_verify_sc_record_error,                  // active high
  output logic o_verify_sc_response_poison_received,      // active high
  output logic o_verify_sc_response_slverr_received,      // active high

  /*  AXI-MM interface channels
  */  
  output cafu_common_pkg::t_cafu_axi4_wr_addr_ch      o_from_execute_axi_wr_addr,
  output cafu_common_pkg::t_cafu_axi4_wr_data_ch      o_from_execute_axi_wr_data,
  output cafu_common_pkg::t_cafu_axi4_wr_resp_ready   o_from_execute_axi_bready,
   input cafu_common_pkg::t_cafu_axi4_wr_addr_ready   i_to_execute_axi_awready,
   input cafu_common_pkg::t_cafu_axi4_wr_data_ready   i_to_execute_axi_wready,
   input cafu_common_pkg::t_cafu_axi4_wr_resp_ch      i_to_execute_axi_wr_resp,

  output cafu_common_pkg::t_cafu_axi4_rd_addr_ch     o_from_verify_sc_axi_rd_addr,
  output cafu_common_pkg::t_cafu_axi4_rd_resp_ready  o_from_verify_sc_axi_rready,
   input cafu_common_pkg::t_cafu_axi4_rd_addr_ready  i_to_verify_sc_axi_arready,
   input cafu_common_pkg::t_cafu_axi4_rd_resp_ch     i_to_verify_sc_axi_rd_resp,

  /* signals to ccv afu top-level FSM and debug registers
   */
  output logic [7:0]  o_error_addr_increment,
  output logic [31:0] o_error_expected_pattern,
  output logic [31:0] o_error_received_pattern,
  output logic [51:0] o_error_address,
  output logic [5:0]  o_error_byte_offset,

  /*  signals from configuration and debug registers
  */
  input logic [31:0] i_addr_increment_value_reg,
  input logic [2:0]  i_algorithm_reg,
  input logic [31:0] i_base_pattern_reg,
  input logic [51:0] i_base_start_address_reg,
  input logic [51:0] i_base_write_back_address_reg,
  input logic [63:0] i_byte_mask_reg,
  input logic        i_force_disable_reg,                   // active high
  input logic        i_mode_single_transaction_multi_loop,  // active high
  input logic        i_mode_single_transaction_one_loop,    // active high
  input logic        i_mode_single_transaction_per_set,     // active high
  input logic [7:0]  i_number_address_increments_reg,
  input logic [7:0]  i_number_loops_reg,
  input logic [7:0]  i_number_sets_reg,
  input logic        i_pattern_parameter_reg,
  input logic [2:0]  i_pattern_size_reg,
  input logic [37:0] i_real_address_increment,
  input logic [37:0] i_real_set_offset,
  input logic [8:0]  i_real_total_transactions_per_set,
  input logic        i_self_checking_enabled_reg,
  input logic [31:0] i_set_offset_reg,
  input logic [2:0]  i_verify_read_semantics_cache_reg,
  input logic [3:0]  i_write_semantics_cache_reg,

  output logic [31:0] o_alg1a_fsm_current_P,
  output logic [51:0] o_alg1a_fsm_current_X,
  output logic [9:0]  o_loop_count,
  output logic [4:0]  o_set_count
);

/* =======================================================================================
*/
logic enable_execute_stage;
logic enable_verify_sc_stage;
logic verify_sc_stage_busy;
logic verify_sc_stage_error_found;
logic enable_verify_sc_response_phase;
logic verify_sc_response_phase_busy;
logic enable_verify_nsc_stage;
logic verify_nsc_stage_busy;
logic alg1a_set_to_busy;
logic alg1a_set_to_not_busy;
logic enable_execute_response_phase;
logic execute_response_phase_busy;

logic [51:0] current_Z;

/* ======================================================================================= inject bad bit
   this should not be synthesized, just for verification  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   grabbing from the environment variables
      ERROR_PATTERN_ENABLE
      ERROR_PATTERN_LOOP
      ERROR_PATTERN_SET
      ERROR_PATTERN_N
      ERROR_PATTERN_BYTE
      ERROR_PATTERN_BIT
   set by sourcing the script error_patterns_script.sh
*/
`ifdef INCLUDE_TESTING_INJECT_BAD_BIT

  logic [511:0] data_with_bad_bit;

  testing_inject_pattern   inst_inject_bad_bit
  (
    .clk     ( clk ),
    .reset_n ( reset_n ),
    .i_loop  ( o_loop_count[7:0] ),
    .i_set   ( o_set_count[3:0]  ),
    .i_data  ( i_to_verify_sc_axi_rd_resp.rdata    ),
    .i_id    ( i_to_verify_sc_axi_rd_resp.rid[7:0] ),
    .i_valid ( i_to_verify_sc_axi_rd_resp.rvalid   ),
    .o_data  ( data_with_bad_bit )
  );

  cafu_common_pkg::t_cafu_axi4_rd_resp_ch    to_verify_sc_axi_rd_resp;

  always_comb
  begin
    to_verify_sc_axi_rd_resp.rvalid = i_to_verify_sc_axi_rd_resp.rvalid;
    to_verify_sc_axi_rd_resp.rid    = i_to_verify_sc_axi_rd_resp.rid;
    to_verify_sc_axi_rd_resp.rdata  = data_with_bad_bit;
    to_verify_sc_axi_rd_resp.rresp  = i_to_verify_sc_axi_rd_resp.rresp;
    to_verify_sc_axi_rd_resp.rlast  = i_to_verify_sc_axi_rd_resp.rlast;
    to_verify_sc_axi_rd_resp.ruser  = i_to_verify_sc_axi_rd_resp.ruser;
  end
`endif

/* =======================================================================================
*/
alg_1a_top_level_fsm_sc_only     inst_alg_1a_top_fsm
(
    .clk (clk),
    .reset_n (reset_n),
    .enable_in (i_enable),  // from ccv afu top level fsm

  /*  signals from configuration and debug registersre
  */
    .address_set_offset_reg           ( i_set_offset_reg                ),
    .algorithm_reg                    ( i_algorithm_reg                 ),
    .base_pattern_reg                 ( i_base_pattern_reg              ),
    .base_start_address_reg           ( i_base_start_address_reg        ),
    .base_write_back_address_reg      ( i_base_write_back_address_reg   ),
    .enable_self_checking_reg         ( i_self_checking_enabled_reg     ),
    .force_disable_afu                ( i_force_disable_reg             ),
    .number_of_address_increments_reg ( i_number_address_increments_reg ),
    .number_of_loops_reg              ( i_number_loops_reg              ),
    .number_of_sets_reg               ( i_number_sets_reg               ),
    .pattern_parameter_reg            ( i_pattern_parameter_reg         ),

    .i_mode_single_transaction_multi_loop ( i_mode_single_transaction_multi_loop ),
    .i_mode_single_transaction_one_loop   ( i_mode_single_transaction_one_loop   ),

  /*  signals for latency mode
  */
    .writes_only_mode_enable( i_writes_only_mode_enable ),
    .reads_only_mode_enable(   i_reads_only_mode_enable ),

    .extended_loop_count( extended_loop_count ),

  /*  signals to/from the execute stage
  */
    .enable_execute_flag     ( enable_execute_stage ),
    .execute_slverr_received ( o_execute_response_slverr_received ),
    .execute_busy_flag       ( o_execute_phase_busy ),

  /*  signals to/from the self checking verify stage
  */
    .enable_sc_verify_flag      ( enable_verify_sc_stage      ),
    .sc_verify_busy_flag        ( o_verify_sc_phase_busy      ),
    .sc_verify_error_found_flag ( verify_sc_stage_error_found ),
    .sc_verify_poison_received  ( o_verify_sc_response_poison_received ),
    .sc_verify_slverr_received  ( o_verify_sc_response_slverr_received ),


  /*  output signals used across AFU
  */
    .current_P       ( o_alg1a_fsm_current_P           ),
    .current_X       ( o_alg1a_fsm_current_X           ),
    .current_Z       ( current_Z             ),
    .loop_count      ( o_loop_count          ),
    .set_count       ( o_set_count           ),
    .set_to_busy     ( alg1a_set_to_busy     ),
    .set_to_not_busy ( alg1a_set_to_not_busy ),
    .busy_flag       ( o_alg1a_busy          )
);

// =================================================================================================
logic single_transaction_per_set;

assign single_transaction_per_set = i_mode_single_transaction_multi_loop
                                  | i_mode_single_transaction_one_loop
                                  | i_mode_single_transaction_per_set;

alg1a_execute_top    inst_execute_top
(
  .clk (clk),
  .reset_n (reset_n),
 
  /* signals to/from ccv afu top-level FSM
  */
  .i_enable_exec_wr_reqs ( enable_execute_stage   ),
  .o_execute_busy        ( o_execute_phase_busy   ),
  .i_current_P           ( o_alg1a_fsm_current_P  ),
  .i_current_X           ( o_alg1a_fsm_current_X  ),

  /*  signals to/from configuration and debug registers
  */
  .o_execute_response_slverr_received ( o_execute_response_slverr_received ),
  .i_number_of_address_increments_reg ( i_number_address_increments_reg ),
  .i_single_transaction_per_set       ( single_transaction_per_set ),
  .i_write_semantics_cache_reg        ( i_write_semantics_cache_reg ),
  .i_address_increment_reg            ( i_addr_increment_value_reg ),
  .i_force_disable_afu                ( i_force_disable_reg ),
  .i_pattern_size_reg                 ( i_pattern_size_reg ),
  .i_latency_mode_req                 ( i_latency_mode_enable ),
  .i_byte_mask_reg                    ( i_byte_mask_reg ),
  .i_NAI                              ( i_real_total_transactions_per_set ),
  .i_RAI                              ( i_real_address_increment ), 

  /* signals to/from mwae top-level FSM
  */
  .i_mwae_set_to_busy ( i_mwae_set_to_busy ),

  /* signals for AXI-MM write address channel
  */
  .i_awready         ( i_to_execute_axi_awready   ),
  .o_write_addr_chan ( o_from_execute_axi_wr_addr ),

  /* signals for AXI-MM write data channel
  */
  .i_wready          ( i_to_execute_axi_wready    ),
  .o_write_data_chan ( o_from_execute_axi_wr_data ),
 
  /* signals for AXI-MM write responses channel
  */
  .o_bready          ( o_from_execute_axi_bready ),
  .i_write_resp_chan ( i_to_execute_axi_wr_resp  )
);

// =================================================================================================
alg1a_verify_sc_top  inst_verify_sc_top
(
  .clk (clk),
  .reset_n (reset_n),
 
  /* signals to/from mwae top-level FSM
  */
  .i_mwae_set_to_busy ( i_mwae_set_to_busy ),
  .i_mwae_busy        ( i_mwae_busy ),
  .o_verify_sc_busy   ( o_verify_sc_phase_busy ),

  /*  signals for read only mode to skip error recordings
  */
  .i_reads_only_mode_enable ( i_reads_only_mode_enable ),
 
  /*   signals to/from the alg1a top level FSM
  */
  .i_enable_verify_sc_gen_read_reqs ( enable_verify_sc_stage ),
  .i_clear_errors                   ( i_mwae_set_to_busy     ),
  .i_current_P                      ( o_alg1a_fsm_current_P  ),
  .i_current_X                      ( o_alg1a_fsm_current_X  ),

  /*  signals from configuration and debug registers  
  */
  .i_number_of_address_increments_reg ( i_number_address_increments_reg ),
  .i_verify_semantics_cache_reg       ( i_verify_read_semantics_cache_reg ),
  .i_single_transaction_per_set       ( single_transaction_per_set ),
  .i_address_increment_reg            ( i_addr_increment_value_reg ),
  .i_force_disable_afu                ( i_force_disable_reg ),
  .i_pattern_size_reg                 ( i_pattern_size_reg ),
  .i_byte_mask_reg                    ( i_byte_mask_reg ),
  .i_latency_mode                     ( i_latency_mode_enable ),
  .i_NAI                              ( i_real_total_transactions_per_set ),
  .i_RAI                              ( i_real_address_increment ), 
 
  /* signals to ccv afu top-level FSM and debug registers
  */
  .o_record_error_flag_out  ( o_verify_sc_record_error ),
  .o_poison_received        ( o_verify_sc_response_poison_received ),
  .o_slverr_received        ( o_verify_sc_response_slverr_received ),
  .o_error_expected_pattern ( o_error_expected_pattern ),
  .o_error_received_pattern ( o_error_received_pattern ),
  .o_error_addr_increment   ( o_error_addr_increment ),
  .o_error_byte_offset      ( o_error_byte_offset ),
  .o_error_found_out        ( verify_sc_stage_error_found ),
  .o_error_address          ( o_error_address ),

  /* signals for AXI-MM read address channel
  */
  `ifdef INCLUDE_TESTING_INJECT_BAD_BIT
    .i_read_resp_chan ( to_verify_sc_axi_rd_resp    ),
    .o_rready         ( o_from_verify_sc_axi_rready ),
  `else
    .i_read_resp_chan ( i_to_verify_sc_axi_rd_resp  ),
    .o_rready         ( o_from_verify_sc_axi_rready ),
  `endif  

  /* signals for AXI-MM read address channel
  */
  .i_arready        ( i_to_verify_sc_axi_arready   ),
  .o_read_addr_chan ( o_from_verify_sc_axi_rd_addr )
);


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdHZ+rVcBTwzFf7XrZo9oOabVCieSWUWYt6YJJOXhpVwrw7LcyLSqk/D7TkahrDH+X/mJ9qvJQPyoKi86mjSpadYjLP3AwMU941suwad2e1SIgyu1sU1VR3JKxIorICbTFrdN6Wj2ML2YagIpuRV/DZqBgQhNVE0TJ7ot+/hbBFj82GkXOYCXDMTePMvjsx9cBhSJtBnB4ssxgbEYX0WPCTrVWjNNF02sy8CiSEh+R5Zmy8tw/UO6eKahFfZ6ISPiy4fvu6BPNlrJrYHLyvQD4RAE4Sl57hom6aVci460zV4ZM+WGdZkWdicfy+X3tN4+BGWfz3IZB2KP6ut5hP2AyPgkDwQDQTu/9VreqUM+LJcpjZbSYaWTumfCXm60GViAjjBGT46KV7d3C4sztvj2kh3m6d10nvcu1KLD+HeR8dIGfimJO+PI5ZHQetYPJAHLtrcMnznyQ2+Z5EfWFWVEMZwv0Z6KRaxafP1rz3oPNTWTM36isX4sxoMI3vpkwNKDDC6EkdGTPz0y70NiMLCot7eW/Yko4cGfRPQ4XAxqoti75nq8aKH9jzi1owV5afo9O0lEzSQILkZ24tbBhdR+fQIiQLpp85dwRlJ792i6DLvsE6h+udvcx+OIhzCIwD+F84JhiAGf/6cf9v1V0SPbAxj8/evyoWLlBdxmhIYcJaQ3R7FylSBFlXm3ktisrFDtxiP2ddZBUNzaZeVauokeu/VqWyHoD+FXbCVFu1qoJHHOMfEzoIoTOwCO3v8SebjS7mKYJzsGyfV8x1PeWXB6Lb"
`endif