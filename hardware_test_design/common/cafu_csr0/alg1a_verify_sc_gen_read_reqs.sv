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

module alg1a_verify_sc_gen_read_reqs
    import ccv_afu_pkg::*;
#(
   parameter FIFO_PTR_WIDTH = 4
)
(
  input logic clk,
  input logic reset_n,    // active low reset

  /* signals to/from ccv afu top-level FSM
  */
  input logic enable_in,       // active high

  /*  signals from configuration and debug registers  
  */
  input logic [31:0] address_increment_reg,
  input logic        force_disable_afu,                 // active high
  input logic [8:0]  NAI,
  input logic [7:0]  number_of_address_increments_reg,
  input logic        single_transaction_per_set,         // active high
  input logic [37:0] RAI,

  /*   signals from the top level FSM
   */
  input [51:0] current_X_in,

  /*  signals to/from the Algorithm 1a self checking verify
      reponse phase
  */
  output logic busy_flag_out,             // active high
  output logic start_response_phase_out,  // active high
  input  logic response_phase_busy_flag,  // active high, flag that response count < NAI

  /* signals to/from axi read channel control / send read reqs fsm
  */
  output logic [FIFO_PTR_WIDTH-1:0]  fifo_count,
  output logic                       fifo_empty,
  output logic [8:0]                 fifo_out_N,
  output logic [51:0]                fifo_out_addr,
   input logic                       fifo_pop,
  output logic                       o_set_to_not_busy,
  output logic                       o_set_to_busy
);
    
/*
        enum type for the FSM of the Algorithm 1a, verify self-checking read phase
*/
typedef enum logic [2:0] {
  IDLE               = 3'h0,
  START              = 3'h1,
  WAIT_ON_N          = 3'h2,
  WAIT_ON_RESPONSES  = 3'h3,
  COMPLETE           = 3'h4
} alg_1a_scv_rp_fsm_enum;

alg_1a_scv_rp_fsm_enum   state;
alg_1a_scv_rp_fsm_enum   next_state;

logic set_to_busy;
logic set_to_not_busy;
    
logic pipe_1_valid;
logic pipe_2_valid;
logic pipe_3_valid;
    
logic [8:0]     pipe_1_N;
logic [8:0]     pipe_2_N;
logic [8:0]     pipe_3_N;

logic [51:0]    pipe_2_YN;
logic [51:0]    pipe_3_addr;

logic        fifo_full;
logic        fifo_thresh;

assign o_set_to_not_busy = set_to_not_busy;
assign o_set_to_busy     = set_to_busy;

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )            state <= IDLE;
  else if( force_disable_afu == 1'b1 )  state <= COMPLETE;   // so that set_to_not_busy pulses
  else                                  state <= next_state;
end

/*   ================================================================================================
*/    
always_comb
begin
  set_to_busy = 1'b0;
  set_to_not_busy = 1'b0;
  start_response_phase_out = 1'b0;

  case( state )
    IDLE :
    begin
      if( enable_in == 1'b1 )  next_state = START;
      else                     next_state = IDLE;

      if( enable_in == 1'b1 )  set_to_busy = 1'b1;
    end

    START :
    begin
          start_response_phase_out = 1'b1;
                        next_state = WAIT_ON_N;
    end

    WAIT_ON_N :
    begin
           if( force_disable_afu == 1'b1 )  next_state = COMPLETE;
      else if( pipe_1_N < NAI )             next_state = WAIT_ON_N;
      else                                  next_state = WAIT_ON_RESPONSES;
    end

    WAIT_ON_RESPONSES :
    begin
           if( force_disable_afu == 1'b1 )         next_state = COMPLETE;
      else if( response_phase_busy_flag == 1'b1 )  next_state = WAIT_ON_RESPONSES;
      else                                         next_state = COMPLETE;
    end

    COMPLETE :
    begin
             set_to_not_busy = 1'b1;
             next_state      = IDLE;
    end

    default :  next_state = IDLE;
  endcase
end

/*   ================================================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          busy_flag_out <= 1'b0;
  else if( set_to_busy == 1'b1 )      busy_flag_out <= 1'b1;
  else if( set_to_not_busy == 1'b1 )  busy_flag_out <= 1'b0;
  else                                busy_flag_out <= busy_flag_out;
end

/*   ================================================================================================  pipe stage 1
*/
/*
 *  valid that starts the "packet is valid" through the pipeline
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )                    pipe_1_valid <= 1'b0;
  else if( set_to_busy == 1'b1 )                pipe_1_valid <= 1'b1;
  else if( busy_flag_out == 1'b0 )              pipe_1_valid <= 1'b0;
  else if( single_transaction_per_set == 1'b1 ) pipe_1_valid <= 1'b0; // only pulse valid once
  else if( fifo_thresh == 1'b1 )                pipe_1_valid <= 1'b0;
  else if( pipe_1_N < NAI )                     pipe_1_valid <= 1'b1; // count less than NAI
  else                                          pipe_1_valid <= 1'b0;
end


/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_1_N <= 'd0;
  else if( set_to_busy == 1'b1 )      pipe_1_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_1_N <= 'd0;
  else if( fifo_thresh == 1 )         pipe_1_N <= pipe_1_N;
  else if( pipe_1_N < NAI )           pipe_1_N <= pipe_1_N + 'd1;
  else                                pipe_1_N <= pipe_1_N;
end

/*   ================================================================================================  pipe stage 2
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_valid <= 1'b0;
  else if( busy_flag_out == 1'b0 )    pipe_2_valid <= 1'b0;
  else                                pipe_2_valid <= pipe_1_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_2_N <= 'd0;
  else if( pipe_1_valid == 1'b0 )     pipe_2_N <= pipe_2_N;
  else                                pipe_2_N <= pipe_1_N;
end

/*
 *   N is used for address calculation, the looping variable that is multiplied
 *      by the address increment value
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_2_YN <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_2_YN <= 'd0;
  else if( pipe_1_valid == 1'b0 )     pipe_2_YN <= pipe_2_YN;
  else if( pipe_1_N == 'd0 )          pipe_2_YN <= 'd0;
  else                                pipe_2_YN <= pipe_2_YN + RAI;
end

/*   ================================================================================================  pipe stage 3
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_valid <= 1'b0;
  else if( busy_flag_out == 1'b0 )    pipe_3_valid <= 1'b0;
  else                                pipe_3_valid <= pipe_2_valid;
end

always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_N <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_3_N <= 'd0;
  else if( pipe_2_valid == 1'b0 )     pipe_3_N <= pipe_3_N;
  else                                pipe_3_N <= pipe_2_N;
end

/*
 *   add the ongoing address increment to the base address for the set
 */
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )          pipe_3_addr <= 'd0;
  else if( busy_flag_out == 1'b0 )    pipe_3_addr <= 'd0;
  else if( pipe_2_valid == 1'b0 )     pipe_3_addr <= pipe_3_addr;
  else                                pipe_3_addr <= pipe_2_YN + current_X_in;
end

/*   ================================================================================================  fifo
*/
fifo_sync_1
#(
   .DATA_WIDTH( (9+52) ),
   .FIFO_DEPTH( 16 ),
   .PTR_WIDTH( 4 ),
   .THRESHOLD( 10 )
)
inst_fifo
(
  .clk            ( clk ),
  .reset_n        ( reset_n ),
  .i_data         ( {pipe_3_N, pipe_3_addr} ),
  .i_write_enable ( pipe_3_valid ),
  .i_read_enable  ( fifo_pop     ),
  .i_clear_fifo   ( set_to_busy  ),
  .o_data         ( {fifo_out_N, fifo_out_addr} ),
  .o_empty        ( fifo_empty   ),
  .o_full         ( fifo_full    ),
  .o_count        ( fifo_count   ),
  .o_thresh       ( fifo_thresh  )
);


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcfcsFKXmKfB0sye5zhG0KDmIpmfe/22M4TRt1exXJTAgAh+RUE0/Qb21ehRQXPQQtAX5Rvze/yDEY2y+VCdStYKujfSh4qa8Bdtdws/4o0UOYF3mcXsCkZOsvSPhvFe5d/Fz1ogQbTUcYWDzAUl2Iwse2D0k9h0h4N5MusmnY5FBhlxm8PDxwc7K3Sxd245TAXxcut6k05db4f60clFzo9Tg2fsG2KJgSzt4I/bhcxnQdJmeIoga5Uc0WeBTqe7R1QI0FVi4Gxxr7BJmnaHuq3xXPwUxkimx4djSzHnGZsCrKJVn/bqL+OUlsKqK++IZGZ44BxCYKlwfiBqv4tB/GIgCXe4K8kKFezqk9TBaXuyy8GbOHdVucEyfy4fBhvBV+kAAC5QDq8nWYQD183DERJ8Y4WDs+KssMkG51ySoaV2h+AjOuqXhU3XUP83HJBnlZNXvj/l4E6L4khvTxLz3RO/cp1zt6ib5jGn9iKdTOW6IkymRMs61aJZsRcaN7yJsDNRTSUgjVy/1g0JjhMTJ58mj7cglCnqYz7YdaeKz5FHiYcnFcR+5Us/SICQxyWUHcLfX0Y28L7uftsFQ9IZfJk9EezjzdYr484msmUGeSZ9TAoAuhTai/QMaEkNwZHpmHmKqZduX6yX7RX2oqADV5DNBK4ptqmsDXkndG3ZBTs39QWAq4TwkUEKrC12SZw8xl+WEhryeWv/Xyzuu8VPdCALr2515A8ENL8BLGi3q3QPBIeJZvUuVCCnok7EpjgPc/J8plDpKyina0ak8MKGv5UJ"
`endif