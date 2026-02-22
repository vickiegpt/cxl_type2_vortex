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


// Copyright 2022 Intel Corporation.
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

module alg_1a_calc_error_address
(
  input clk,
  input reset_n,            // active low reset
  input i_error_found,      // active high
  input i_force_disable,    // active high

  input [51:0] i_current_X,
  input [8:0]  i_error_N,
  input [37:0] i_RAI,

  output logic [51:0] o_result,
  output logic        o_complete_flag
);

/*
        enum type for the FSM of the Algorithm 1a, verify self-checking read phase
*/
typedef enum logic [2:0] {
  IDLE              = 3'h0,
  START             = 3'h1,
  ADD_RAI           = 3'h2,
  ADD_X             = 3'h3,
  COMPLETE          = 3'h4,
  WAIT_FOR_CLEAR    = 3'h5
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

logic add_with_RAI;
logic add_with_X;
logic clock_N;
logic set_to_zero;

logic [8:0]  count;
logic [51:0] reg_a;
logic [8:0]  reg_N;

/* ==========================================================================
*/
always_ff @( posedge clk )
begin : register_state
       if( reset_n == 1'b0 )          state <= IDLE;
  else if( i_force_disable == 1'b1 )  state <= IDLE;
  else                                state <= next_state;
end

/* ==========================================================================
*/
always_comb
begin : comb_next_state
  set_to_zero     = 1'b0;
  add_with_RAI    = 1'b0;
  add_with_X      = 1'b0;
  o_complete_flag = 1'b0;
  clock_N         = 1'b0;

  case( state )
    IDLE :
    begin
      if( i_error_found == 1'b0 )
      begin
                          next_state = IDLE;
      end
      else begin
                          next_state = START;
                             clock_N = 1'b1;
      end
    end

    START :
    begin
                         set_to_zero = 1'b1;
                          next_state = ADD_RAI;
    end

    ADD_RAI :
    begin
      if( count < reg_N )
      begin
                        add_with_RAI = 1'b1;
                          next_state = ADD_RAI;
      end
      else begin
                          next_state = ADD_X;
      end
    end

    ADD_X :
    begin
                          add_with_X = 1'b1;
                          next_state = COMPLETE;
    end

    COMPLETE :
    begin
                     o_complete_flag = 1'b1;
                          next_state = WAIT_FOR_CLEAR;
    end

    WAIT_FOR_CLEAR :
    begin
      if( i_error_found == 1'b1 ) next_state = WAIT_FOR_CLEAR;
      else                        next_state = IDLE;
    end

    default :             next_state = IDLE;
  endcase
end

/* ==========================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 ) reg_N <= 'd0;
  else if( clock_N == 1'b1 ) reg_N <= i_error_N;
  else                       reg_N <= reg_N;
end

/* ==========================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      count <= 'd0;
  else if( set_to_zero == 1'b1 )  count <= 'd0;
  else if( add_with_RAI == 1'b1 ) count <= count + 'd1;
  else                            count <= count;
end

/* ==========================================================================
*/
always_ff @( posedge clk )
begin
       if( reset_n == 1'b0 )      reg_a <= 'd0;
  else if( set_to_zero == 1'b1 )  reg_a <= 'd0;
  else if( add_with_RAI == 1'b1 ) reg_a <= {14'd0, i_RAI};
  else if( add_with_X == 1'b1 )   reg_a <= i_current_X;
  else                            reg_a <= 'd0;
end

/* ==========================================================================
*/
always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 ) o_result <= 'd0;
  else                  o_result <=  o_result + reg_a;
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "H28SokgVWsMEbsewOIobYg9pBFjA48KHaAEU8jnFjr19ZVcf7zxwr1qgeikvIPWbYe5F3BX1vbrT/M2lLADkbST366cEjMXnT4HRkQWQ81m/UAy8jzLTSlxpm2CjvqtRu6LzlgqoQ9tEytIBif0O6mplcsTrXeCdUOP8ISSHe/Pu3IX1sj8UTcucdk28+KaLAfsWU8FHUUN8FSeAmeZVM8l3ibAmLv28zUQmeJhVKS+OjaZzxSu1RXhbb8C+s1DWXc8N1SiEDnAxpMUifN3vTnf37ZxKpLwQD5PRp6YP/09fCOSnnTRwtn/fYZWr2hb7UU1aW/7xW8TKUeAWxp69ndeypuxxtn0Uk0dun4/GVip9wRo7Hn1OSrVi6VJn39ggMf7ddDlghsuRKkuA8UUL9Oc++FMgjQHj8TdaBYnmdKFnUuTyfyKKM3ND5X2fOBKYYD3zEmFg5p+cv9lWDxqe4+Br3oc2q7hbeyqRd9OK8izPCF9Cu4VkYP9rv+vMFsjBQ3pr8Ji4Esw5MCP4UkoM6s8jALDljZzh4VQHzs4IdDFsmNgjg5s/5LxgCfYJhTYGNd/59++B5pM0L/TEBcwSq/pKz5az65OiDsvmXv3042SkYlmy/oYc0L6zf56oVI/utH0XVAGPklz9k4Alf1q0KzS0+OEwJG3O+F7Xk79rZddg1BPoy1W+tSueG1/AUXZIbu1rAJ2YgTzQo64WhdzNYFUCOq2zkHigV9tM7Lb7ilPSd8zKnEZ9UuUI8XqPiyrAtlf68UEMK9swJST6yGKIRJuBXUYp2fDQeo1a6DYNY9kVtcyPIbuLQlzME3B3s0pK4l1KJ6OoBK4J5e4EItlB6vbIxWrGzipc9jSaj0tXPCbR1u1UdUDY1BqmKcJsh8InAQOn29lP0j4XfGRgAQCIWLXyJPaziI4FIsWC+6BGWW7dJYdDnXXOQTN2c9N5+s2N4fmtg6OrxNytBkr96BHq8cg28oEecuQnhbXi8+L1Vr/WE1hD0+PtqEfDvqQmD1nz"
`endif