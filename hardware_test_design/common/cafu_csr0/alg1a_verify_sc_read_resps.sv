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

module alg1a_verify_sc_read_resps
    import ccv_afu_pkg::*;
    import cafu_common_pkg::*;
(
  input logic clk,
  input logic reset_n,    // active low reset

  /*  signals for read only mode to skip error recordings
  */
  input logic reads_only_mode_enable,
  
  /*  signals from configuration and debug registers
  */
  input logic [31:0] address_increment_reg,
  input logic [63:0] byte_mask_reg,
  input logic        force_disable_afu,               // active high
  input logic [8:0]  NAI,
  input logic [7:0]  number_of_address_increments_reg,
  input logic        single_transaction_per_set,        // active high
  input logic [37:0] RAI,
  input logic [2:0]  pattern_size_reg,
  
  /*   signals from the top level FSM
   */
  input logic [51:0]  current_X_in,
  input logic [31:0]  current_P_in,
  input logic         clear_errors_in,    // active high, should be top level FSM set_to_busy
  
  /*  signals from the Algorithm 1a self checking verify
      read phase
  */
  input logic enable_in,
  input logic i_mwae_busy,
  
  /* signals to ccv afu top-level FSM and debug registers
  */
  output logic record_error_flag_out,
  output logic slverr_received,
  output logic poison_received,

  output logic [7:0]  error_addr_increment,
  output logic [31:0] error_expected_pattern,
  output logic [31:0] error_received_pattern,
  output logic [51:0] error_address,
  output logic [5:0]  error_byte_offset,
  output logic        error_found_out,

  /*  signals to the Algorithm 1a self checking verify
      read phase
  */
  output logic busy_out,

  /* signals for AXI-MM read address channel
  */
  input  cafu_common_pkg::t_cafu_axi4_rd_resp_ch      read_resp_chan,
  output cafu_common_pkg::t_cafu_axi4_rd_resp_ready   rready
);
    
// =================================================================================================
typedef enum logic [3:0] {
  IDLE              = 'd0,
  START             = 'd1,
  CHECK_COUNT       = 'd2,
  START_ERROR       = 'd3,
  COLLECT_ERROR_1   = 'd4,
  COLLECT_ERROR_2   = 'd5,
  RECORD_ERROR      = 'd6,
  PRECOMPLETE       = 'd7,
  COMPLETE          = 'd8,
  AWAIT_REQ         = 'd9,
  AWAIT_RSP         = 'd10,
  CHECK_COUNT_2     = 'd11
} alg_1a_scv_rsp_fsm_enum;

alg_1a_scv_rsp_fsm_enum   state;
alg_1a_scv_rsp_fsm_enum   next_state;

// =================================================================================================
logic        initialize;
logic        pipe_7_error_found;
logic [8:0]  pipe_8_response_count;
logic        start_error_gathering;
logic [51:0] error_addr;
logic        error_addr_valid;
logic        set_to_not_busy;
logic [8:0]  NAI_clkd;
logic [8:0]  total_num_responses;

logic                              pipe_1_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0] pipe_1_data;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]   pipe_1_id;

cafu_common_pkg::t_cafu_axi4_resp_encoding  pipe_1_resp;
cafu_common_pkg::t_cafu_axi4_ruser          pipe_1_ruser;

logic                              pipe_2_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]   pipe_2_id;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0] pipe_2_data;
logic                              pipe_2_slverr;
logic                              pipe_2_poison;

logic                               pipe_3_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]    pipe_3_N;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_3_data;
logic [31:0]                        pipe_3_NpP;
logic                               pipe_3_slverr;
logic                               pipe_3_poison;

logic                               pipe_4_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]    pipe_4_N;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_4_data;
logic [31:0]                        pipe_4_NpP;
logic [31:0]                        pipe_4_RP32;
logic [15:0]                        pipe_4_RP16;
logic [7:0]                         pipe_4_RP8;
logic                               pipe_4_slverr;
logic                               pipe_4_poison;

logic                               pipe_5_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]    pipe_5_N;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_5_data;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_5_ERP;
logic [31:0]                        pipe_5_NpP;
logic                               pipe_5_slverr;
logic                               pipe_5_poison;
logic [511:0] ERP;

logic                               pipe_6_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]    pipe_6_N;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_6_data;
logic [31:0]                        pipe_6_NpP;
logic [63:0]                        pipe_6_compare_result;
logic                               pipe_6_slverr;
logic                               pipe_6_poison;
logic [63:0] compare_z;

logic                               pipe_7_valid;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]    pipe_7_N;
logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]  pipe_7_data;
logic [63:0]                        pipe_7_compare_result;
logic [31:0]                        pipe_7_NpP;
logic                               pipe_7_slverr;
logic                               pipe_7_poison;

logic [31:0] pipe_8_error_pattern;
logic [5:0]  pipe_8_error_byte_offset;
logic [5:0]  byte_offset;
logic        byte_offset_valid;
logic [31:0] first_error_found;
logic        fef_valid;

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           NAI_clkd <= 'd0;
  else if( force_disable_afu == 1'b1 ) NAI_clkd <= 'd0;
  else if( enable_in == 1'b1 )         NAI_clkd <= NAI;
  else                                 NAI_clkd <= NAI_clkd;
end

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )           total_num_responses <= 'd0;
  else if( force_disable_afu == 1'b1 ) total_num_responses <= 'd0;
  else if( enable_in == 1'b1 )         total_num_responses <= NAI + 'd1;
  else                                 total_num_responses <= total_num_responses;
end

// =================================================================================================
always_ff @ ( posedge clk )
begin
       if( reset_n == 1'b0 )         busy_out <= 1'b0;
  else if( initialize == 1'b1 )      busy_out <= 1'b1;
  else if( set_to_not_busy == 1'b1 ) busy_out <= 1'b0;
  else                               busy_out <= busy_out;
end

// =================================================================================================
/* ready flag to the axi-mm read response channel
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                      rready <= 1'b0;
  else if( initialize == 1'b1 )                   rready <= 1'b1;
  else if( pipe_8_response_count < (NAI_clkd+1) ) rready <= rready;
  else                                            rready <= 1'b0;
end

// =================================================================================================
/* pipe stage 1 - clock the read response channel
 */
always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 ) 
    | ( rready  == 1'b0 )
    )
  begin
    pipe_1_valid <= 1'b0;
    pipe_1_resp  <= eresp_CAFU_OKAY;
    pipe_1_ruser <= 'd0;
    pipe_1_id    <= 'd0;
    pipe_1_data  <= 'd0;
  end
  else begin
    pipe_1_valid <= read_resp_chan.rvalid;
    pipe_1_resp  <= read_resp_chan.rresp;
    pipe_1_ruser <= read_resp_chan.ruser;
    pipe_1_id    <= read_resp_chan.rid;
    pipe_1_data  <= read_resp_chan.rdata;
  end
end

// =================================================================================================
/* pipe stage 2 - 
 *   decide if a valid read response has arrived
 *   decide if a valid packet continues down the pipeline
 */
always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 ) 
    | ( rready  == 1'b0 )
    )
  begin
    pipe_2_valid <= 1'b0;
    pipe_2_id    <=  'd0;
    pipe_2_data  <=  'd0;
  end
  else begin
    pipe_2_valid <= pipe_1_valid;
    pipe_2_id    <= pipe_1_id;
    pipe_2_data  <= pipe_1_data;
  end
end

// =================================================================================================
/* pipe stage 2 - 
   Have to monitor rresp for a SLVERR.
   Have to monitor ruser for poison.
   If received, treat like an error and record all errors the same except for patterns.
*/
always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    | ( clear_errors_in == 1'b1 )
    )
  begin
    pipe_2_slverr <= 1'b0;
    pipe_2_poison <= 1'b0;
  end
  else begin
       pipe_2_slverr <= ( pipe_1_valid == 1'b1 ) & ( pipe_1_resp  == eresp_CAFU_SLVERR );
       pipe_2_poison <= ( pipe_1_valid == 1'b1 ) & ( pipe_1_ruser.poison == 1'b1 );
  end
end

// =================================================================================================
/* pipe stage 3 - 
 *   the ID is the N, added to current_P (the base pattern of the set) to
 *   calcualte the Pattern that was written out with this ID
 */
always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    )
  begin
    pipe_3_valid  <= 1'b0;
    pipe_3_NpP    <=  'd0;
    pipe_3_N      <=  'd0;
    pipe_3_data   <=  'd0;
    pipe_3_slverr <= 1'b0;
    pipe_3_poison <= 1'b0;
  end
  else if( pipe_2_valid == 1'b1 )
  begin
    pipe_3_valid  <= pipe_2_valid;
    pipe_3_NpP    <= pipe_2_id + current_P_in;
    pipe_3_N      <= pipe_2_id;
    pipe_3_data   <= pipe_2_data;
    pipe_3_slverr <= pipe_2_slverr;
    pipe_3_poison <= pipe_2_poison;
  end
  else begin
    pipe_3_valid  <= pipe_2_valid;
    pipe_3_NpP    <= pipe_3_NpP;
    pipe_3_N      <= pipe_3_N;
    pipe_3_data   <= pipe_3_data;
    pipe_3_slverr <= pipe_3_slverr;
    pipe_3_poison <= pipe_3_poison;
  end
end

// =================================================================================================
/* pipe stage 4 - 
 */
always_ff @( posedge clk )
begin
  if(      reset_n == 1'b0 )    pipe_4_valid <= 1'b0;
  else if( rready == 1'b0 )     pipe_4_valid <= 1'b0;
  else                          pipe_4_valid <= pipe_3_valid;
end

/* the expected pattern processed by the parameter size field
 */
always_ff @( posedge clk )
begin
  if(      reset_n == 1'b0 )        pipe_4_RP32 <= 'd0;
  else if( rready == 1'b0 )         pipe_4_RP32 <= 'd0;
  else if( pipe_3_valid == 1'b1 )
  begin
    if( pattern_size_reg == 'd4 )   pipe_4_RP32 <= pipe_3_NpP;
    else                            pipe_4_RP32 <= 'd0;
  end
  else                              pipe_4_RP32 <= pipe_4_RP32;
end

always_ff @( posedge clk )
begin
  if(      reset_n == 1'b0 )        pipe_4_RP16 <= 'd0;
  else if( rready == 1'b0 )         pipe_4_RP16 <= 'd0;
  else if( pipe_3_valid == 1'b1 )
  begin
    if( pattern_size_reg == 'd2 )   pipe_4_RP16 <= pipe_3_NpP[15:0];
    else                            pipe_4_RP16 <= 'd0;
  end
  else                              pipe_4_RP16 <= pipe_4_RP16;
end

always_ff @( posedge clk )
begin
  if(      reset_n == 1'b0 )        pipe_4_RP8 <= 'd0;
  else if( rready == 1'b0 )         pipe_4_RP8 <= 'd0;
  else if( pipe_3_valid == 1'b1 )
  begin
    if( pattern_size_reg == 'd1 )   pipe_4_RP8 <= pipe_3_NpP[7:0];
    else                            pipe_4_RP8 <= 'd0;
  end
  else                              pipe_4_RP8 <= pipe_4_RP8;
end

always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    )
  begin
    pipe_4_NpP    <= 'd0;
    pipe_4_N      <= 'd0;
    pipe_4_data   <= 'd0;
    pipe_4_slverr <= 'd0;
    pipe_4_poison <= 'd0;
  end
  else if( pipe_3_valid == 1'b1 )
  begin
    pipe_4_NpP    <= pipe_3_NpP;
    pipe_4_N      <= pipe_3_N;
    pipe_4_data   <= pipe_3_data;
    pipe_4_slverr <= pipe_3_slverr;
    pipe_4_poison <= pipe_3_poison;
  end
  else begin
    pipe_4_NpP    <= pipe_4_NpP;
    pipe_4_N      <= pipe_4_N;
    pipe_4_data   <= pipe_4_data;
    pipe_4_slverr <= pipe_4_slverr;
    pipe_4_poison <= pipe_4_poison;
  end
end

// =================================================================================================
/* pipe stage 5 - 
 *   the expected pattern processed by the parameter size field
 *   then processed and expanded by the byte mask field
 */

pattern_expand_by_byte_mask_ver2     inst_pattern_expand_pipe_5
(
   .byte_mask_reg_in    ( byte_mask_reg    ),
   .pattern_size_reg_in ( pattern_size_reg ),
   .pattern32_in        ( pipe_4_RP32      ),
   .pattern16_in        ( pipe_4_RP16      ),
   .pattern8_in         ( pipe_4_RP8       ),
   .pattern_out         ( ERP              )
);


always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    )
  begin
    pipe_5_valid  <= 1'b0;
    pipe_5_slverr <= 1'b0;
    pipe_5_poison <= 1'b0;
    pipe_5_ERP    <=  'd0;
    pipe_5_NpP    <=  'd0;
    pipe_5_N      <=  'd0;
    pipe_5_data   <=  'd0;
  end
  else if( pipe_4_valid == 1'b1 )
  begin
    pipe_5_valid  <= pipe_4_valid;
    pipe_5_slverr <= pipe_4_slverr;
    pipe_5_poison <= pipe_4_poison;
    pipe_5_ERP    <= ERP;
    pipe_5_NpP    <= pipe_4_NpP;
    pipe_5_N      <= pipe_4_N;
    pipe_5_data   <= pipe_4_data;
  end
  else   begin
    pipe_5_valid  <= pipe_4_valid;
    pipe_5_slverr <= pipe_5_slverr;
    pipe_5_poison <= pipe_5_poison;
    pipe_5_ERP    <= pipe_5_ERP;
    pipe_5_NpP    <= pipe_5_NpP;
    pipe_5_N      <= pipe_5_N;
    pipe_5_data   <= pipe_5_data;
  end
end

// =================================================================================================
/* pipe stage 6 - 
 *  Compare the signal pipe_5_ERP (expected pattern for the ID) with
 *    pipe_5_data (received data of patterns). Then reduce by the byte
 *    mask field to 1 bit per byte:
 *          1 for error/mismatch
 *          0 for no error/mismatch
 */
verify_sc_compare       inst_compare_pipe_6
(
    .received_in        ( pipe_5_data ),
    .expected_in        ( pipe_5_ERP ),
    .byte_mask_reg_in   ( byte_mask_reg ),
    .compare_out        ( compare_z )
);


always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    )
  begin
    pipe_6_valid          <= 1'b0;
    pipe_6_slverr         <= 1'b0;
    pipe_6_poison         <= 1'b0;
    pipe_6_NpP            <=  'd0;
    pipe_6_N              <=  'd0;
    pipe_6_data           <=  'd0;
    pipe_6_compare_result <=  'd0;
  end
  else if( pipe_5_valid == 1'b1 )
  begin
    pipe_6_valid          <= pipe_5_valid;
    pipe_6_slverr         <= pipe_5_slverr;
    pipe_6_poison         <= pipe_5_poison;
    pipe_6_NpP            <= pipe_5_NpP;
    pipe_6_N              <= pipe_5_N;
    pipe_6_data           <= pipe_5_data;
    pipe_6_compare_result <= compare_z;
  end
  else begin
    pipe_6_valid          <= pipe_5_valid;
    pipe_6_slverr         <= pipe_6_slverr;
    pipe_6_poison         <= pipe_6_poison;
    pipe_6_NpP            <= pipe_6_NpP;
    pipe_6_N              <= pipe_6_N;
    pipe_6_data           <= pipe_6_data;
    pipe_6_compare_result <= pipe_6_compare_result;
  end
end

// =================================================================================================
/* pipe stage 7 - 
 *   detect if an error (a mismatch between expected and received patterns) has occured
 */
always_ff @( posedge clk )
begin
  if(      reset_n == 1'b0 ) pipe_7_valid <= 1'b0;
  else if( rready == 1'b0 )  pipe_7_valid <= 1'b0;
  else                       pipe_7_valid <= pipe_6_valid;
end

always_ff @( posedge clk )
begin
  if( ( reset_n == 1'b0 )
    | ( rready  == 1'b0 )
    )
  begin
    pipe_7_slverr <= 1'b0;
    pipe_7_poison <= 1'b0;
  end
  else if( pipe_6_valid == 1'b1 ) 
  begin
    pipe_7_slverr <= pipe_6_slverr | pipe_7_slverr;
    pipe_7_poison <= pipe_6_poison | pipe_7_poison;
  end
  else begin
    pipe_7_slverr <= pipe_7_slverr;
    pipe_7_poison <= pipe_7_poison;
  end
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            pipe_7_error_found <= 1'b0;
  else if( clear_errors_in ==1'b1 )     pipe_7_error_found <= 1'b0;
  else if( pipe_6_valid == 1'b1 )       pipe_7_error_found <= |pipe_6_compare_result;
  else                                  pipe_7_error_found <= pipe_7_error_found;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            pipe_7_compare_result <= 'd0;
  else if( clear_errors_in == 1'b1 )    pipe_7_compare_result <= 'd0;
  else if( pipe_7_error_found == 1'b1 ) pipe_7_compare_result <= pipe_7_compare_result;
  else if( pipe_6_valid == 1'b1 )       pipe_7_compare_result <= pipe_6_compare_result;
  else                                  pipe_7_compare_result <= pipe_7_compare_result;
end


always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 )
  begin
    pipe_7_NpP  <= 'd0;
    pipe_7_N    <= 'd0;
    pipe_7_data <= 'd0;
  end
  else if( pipe_7_error_found == 1'b1 )
  begin
    pipe_7_NpP  <= pipe_7_NpP;
    pipe_7_N    <= pipe_7_N;
    pipe_7_data <= pipe_7_data;
  end
  else if( pipe_6_valid == 1'b1 )
  begin
    pipe_7_NpP  <= pipe_6_NpP;
    pipe_7_N    <= pipe_6_N;
    pipe_7_data <= pipe_6_data;
  end
  else begin
    pipe_7_NpP  <= pipe_7_NpP;
    pipe_7_N    <= pipe_7_N;
    pipe_7_data <= pipe_7_data;
  end
end

// =================================================================================================
/* pipe stage 8 - handle response count and record errors
 *   figure out the byte offset from the compare result mask and send to debug registers
 *   if an error is found, extract the first error found and send it to debug registers
 *   if an error is found,  calulate the address of the error
 */
verify_sc_index_byte_offset     inst_index_offset_pipe_8
(
    .clk                    ( clk                   ),
    .reset_n                ( reset_n               ),
    .compare_mask_in        ( pipe_7_compare_result ),
    .enable                 ( start_error_gathering ),
    .byte_offset_out        ( byte_offset           )
);


verify_sc_extract_error_pattern     inst_vsceep
(
    .clk                     ( clk                   ),
    .reset_n                 ( reset_n               ),
    .data_in                 ( pipe_7_data           ),
    .compare_mask_in         ( pipe_7_compare_result ),
    .pattern_size_reg_in     ( pattern_size_reg      ),
    .enable_in               ( start_error_gathering ),
    .first_error_pattern_out ( first_error_found     )
);


alg_1a_calc_error_address   inst_calc_error_address
(
  .clk             ( clk                ),
  .reset_n         ( reset_n            ),
  .i_error_found   ( pipe_7_error_found ),
  .i_force_disable ( force_disable_afu  ),
  .i_current_X     ( current_X_in       ),
  .i_error_N       ( pipe_6_N[8:0]      ),
  .i_RAI           ( RAI                ),
  .o_result        ( error_addr         ),
  .o_complete_flag ( error_addr_valid   )
);


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            pipe_8_response_count <= 'd0;
  else if( clear_errors_in == 1'b1 )    pipe_8_response_count <= 'd0;
  else if( enable_in == 1'b1 )          pipe_8_response_count <= 'd0;
  else if( pipe_7_valid == 1'b1 )       pipe_8_response_count <= pipe_8_response_count + 'd1;
  else                                  pipe_8_response_count <= pipe_8_response_count;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            pipe_8_error_byte_offset <= 'd0;
  else if( clear_errors_in == 1'b1)     pipe_8_error_byte_offset <= 'd0;
  else if( pipe_7_error_found == 1'b0 ) pipe_8_error_byte_offset <= 'd0;
  else                                  pipe_8_error_byte_offset <= byte_offset;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )              pipe_8_error_pattern <= 'd0;
  else if( clear_errors_in == 1'b1)       pipe_8_error_pattern <= 'd0;
  else if( pipe_7_error_found == 1'b0 )   pipe_8_error_pattern <= 'd0;
  else                                    pipe_8_error_pattern <= first_error_found;
end


always_comb
begin
  error_addr_increment   = pipe_7_N[7:0];
  error_expected_pattern = pipe_7_NpP;
  error_received_pattern = pipe_8_error_pattern;
  error_address          = error_addr; //pipe_8_error_address;
  error_byte_offset      = pipe_8_error_byte_offset;
  error_found_out        = pipe_7_error_found;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      slverr_received <= 'd0;
  else if( i_mwae_busy == 1'b0 )  slverr_received <= 'd0;
  else if( state == PRECOMPLETE ) slverr_received <= pipe_7_slverr;
  else                            slverr_received <= slverr_received;
end


always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      poison_received <= 'd0;
  else if( i_mwae_busy == 1'b0 )  poison_received <= 'd0;
  else if( state == PRECOMPLETE ) poison_received <= pipe_7_poison;
  else                            poison_received <= poison_received;
end

// =================================================================================================
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= COMPLETE;   // so that set_to_not_busy happens
  else                                  state <= next_state;
end

// =================================================================================================
always_comb
begin
  initialize            = 1'b0;
  record_error_flag_out = 1'b0;
  start_error_gathering = 1'b0;
  set_to_not_busy       = 1'b0;

  case( state ) 
    IDLE :
    begin
        if( enable_in == 1'b1 )                             next_state = START;
        else                                                next_state = IDLE;

        if( enable_in == 1'b1 )                             initialize = 1'b1;
    end
    
    START :
    begin
                                                            next_state = CHECK_COUNT;
    end
    
    CHECK_COUNT :
    begin
        if( ( pipe_7_error_found == 1'b1 )
		  & ( reads_only_mode_enable == 1'b0 )
		  )
        begin
                                                            next_state = START_ERROR;
        end
        else if( single_transaction_per_set == 1'b1 )
        begin
           if( pipe_8_response_count == 'd0 )               next_state = CHECK_COUNT;
           else                                             next_state = PRECOMPLETE;
        end
        else if( pipe_8_response_count < (NAI_clkd+1) )     next_state = CHECK_COUNT;
        else                                                next_state = PRECOMPLETE;
    end
    
    START_ERROR :
    begin
                                                            next_state = COLLECT_ERROR_1;
                                                 start_error_gathering = 1'b1;
    end

    COLLECT_ERROR_1 :
    begin
                                                            next_state = COLLECT_ERROR_2;
    end

    COLLECT_ERROR_2 :
    begin
        if( error_addr_valid == 1'b1 )                      next_state = RECORD_ERROR; 
        else                                                next_state = COLLECT_ERROR_2;
    end
    
    RECORD_ERROR :
    begin
                                                 record_error_flag_out = 1'b1;
                                                            next_state = PRECOMPLETE;
    end

    PRECOMPLETE :
    begin
                                                            next_state = COMPLETE;
    end
    
    COMPLETE :
    begin
                                                       set_to_not_busy = 1'b1;
                                                            next_state = IDLE;
    end

    default :                                               next_state = IDLE;
  endcase
end
    

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdZKWmtHgudA5aQK0TvfpByLLR9s+wClFW53uNtl8TUlg6Toj9pV/gyCfUkSLSvT+2Dic68+h10K/qvlm4tp0kDw1Lk7DBAaQqEokujxM7s9t4Q12EhAmNiE8XDtWOiCyztfIfCwVeWyElLYOI8cyeGxyYgG1XG2Ludcx05O/SJo5vlDkCSWUqtVF33C6tYVhABD9eHbrVpZAw+HMVAP2nmZPFABPB+zccn9rKx6I9apidzd7r+Picg5Xsj7/GawuOmiVuiL1OX/kSclEY5vmEIfprtyDAm+0Gd/WsVyhJ7T9TToly8mMCWe1IOQzGT/o1FvcPUwXWDlQGWB7Qs9eJOq0bdKgXpz6ARz7tRc9vdktcaVxgKb524ELAjCFKN+egt1lYVSXxunT0+N4xEhUrYMM0yM157kklz/u/KI6jlQjdhl4LYT5mHxBCoZZ96uEH/WK0jio/doyoX5xZHvi1cgPbd7RfyAZoPFEjVdZDhAZfZv7+ADegZZhZIfsMCc8YRr9Ke/UCKzEdtX6c+AoPHxb6BzmsEdbUUPblQ8Onk8aOCJ5KVfJ7gI6mIebXjprVRPIwxPCa2wWqFYABntolxI3ZDSX0CObWB5sF/3+kGVT+XHkDeBsV1td7iSgRy2TJe3ufs0aRcb12d+rOhtTJ+b3NiBh4Zd0BsdEjx7lvD353a+3NpvGmJb1WvIOGCeVpSw/kYGzbxykt5KFPkk7gN5HHPObjfV6H64a273iwfSLtomF3lN8IlR6MG+ffGSgI1Up6lIY6Dm/H2MbHigm6g"
`endif