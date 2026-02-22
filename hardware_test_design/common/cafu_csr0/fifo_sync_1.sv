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

module fifo_sync_1
#(
   parameter DATA_WIDTH = 16,
   parameter FIFO_DEPTH = 16,
   parameter PTR_WIDTH  = 4,
   parameter THRESHOLD  = 10
)
(
  input                  clk,
  input                  reset_n,
  input [DATA_WIDTH-1:0] i_data,
  input                  i_write_enable,
  input                  i_read_enable,
  input                  i_clear_fifo,  // should come from top level set to busy
  
  output logic [DATA_WIDTH-1:0] o_data,
  output logic                  o_empty,
  output logic                  o_full,
  output logic [PTR_WIDTH-1:0]  o_count,
  output logic                  o_thresh
);

logic [DATA_WIDTH-1:0] fifo_ram [FIFO_DEPTH-1:0];

logic [PTR_WIDTH-1:0] write_ptr;
logic [PTR_WIDTH-1:0] read_ptr;


always_comb
begin
    o_empty  = (o_count == 0);
    o_full   = (o_count == (FIFO_DEPTH-1));
    o_thresh = (o_count > (THRESHOLD-1));
end


always_ff @( posedge clk )
begin
  if( (reset_n == 1'b0) 
    | (i_clear_fifo == 1'b1) ) begin
                               o_count <= 'd0;
  end
  else if( (o_full == 1'b0)
         & (i_write_enable == 1'b1)
         & (o_empty == 1'b0)
         & (i_read_enable == 1'b1) ) begin
                               o_count <= o_count;
  end
  else if( (o_full == 1'b0)
         & (i_write_enable == 1'b1) ) begin
                               o_count <= o_count + 'd1;
  end
  else if( (o_empty == 1'b0)
         & (i_read_enable == 1'b1) ) begin
                               o_count <= o_count - 'd1;
  end
  else                         o_count <= o_count;
end


always_ff @( posedge clk )
begin
  if( (reset_n == 1'b0) 
    | (i_clear_fifo == 1'b1) ) begin
                               o_data <= 'd0;
  end
  else if( (o_empty == 1'b0)
         & (i_read_enable == 1'b1) ) begin
                               o_data <= fifo_ram[read_ptr];
  end
  else                         o_data <= o_data;
end


always_ff @( posedge clk )
begin
  if( (o_full == 1'b0)
    & (i_write_enable == 1'b1) ) begin
                               fifo_ram[write_ptr] <= i_data;
  end
  else                         fifo_ram[write_ptr] <= fifo_ram[write_ptr];
end


always_ff @( posedge clk )
begin
  if( (reset_n == 1'b0) 
    | (i_clear_fifo == 1'b1) ) begin
                               write_ptr <= 'd0;
  end
  else if( (o_full == 1'b0)
         & (i_write_enable == 1'b1) ) begin  
                               write_ptr <= write_ptr + 'd1;
  end
  else                         write_ptr <= write_ptr;
end


always_ff @( posedge clk )
begin
  if( (reset_n == 1'b0) 
    | (i_clear_fifo == 1'b1) ) begin
                               read_ptr <= 'd0;
  end
  else if( (o_empty == 1'b0)
         & (i_read_enable == 1'b1) ) begin  
                               read_ptr <= read_ptr + 'd1;
  end
  else                         read_ptr <= read_ptr;
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcc7sgvXJ8TpuU+OGJeyS3BlljkL6NHQPaVskgd8gF0SUJct4lsi0Lj7IIf9igU50gC1g9G4V7EPt25ISL+ZJeooIl0ABMAlhyOwkvZ9k3ANeF+tMEXZl0Yk3YXV5h+czbazwH/uDSFUaZz3LfgabdpTOr4cywefwXicDJmgn6d8+n4vmZPGkzNwE5S0LQXFMmqIsDqMc/zPFB5kkZzGBvzeLRdzisVjicrYh1ZmmPjqo+6kFPsNzy7hYY2QOWyj3GRO50GVFqkRy0ff5O5saPmGKnCFFZR3VNjma+7rUyVTbIGdry0XoR5nG0Vs6KnMe2JBCezHf72/Swe8C7yE3iSrVKY88ck5W23AGWxvUGF0QtjvI2ZzoUtlrk86uEhLOU9Msn/8+pVAo0/78cudJrOfXev4u7yejfwMUjNbE2arbeXP2eaZyrJNz4ckJugfWtEAhVZHCkwR1g6ZEM0ePb/ZCbp48YjSDnatc//EMTb7Q0Ce6xhsQXHTlpyOyMBNr2czeEavUiLB4Blg3nVQmifO4LqXqNbL0uRJc2djqQKlnsMuIec0yJ55v7Nln/+i7MVN86l70kh0N8762f0bO9V9iRINkWXtzTUThRhC7ooAwNsKP5es3RuVrL2ilhACaqs6y3oPmZdx5oabL4Equs8cyKvsuWqCT4jKvb8tM5sMQ5Wis5pDNZPvXXwc5H6xzB9DTl2Kg6vY4oq63gY3k8/HZ/U3kxCX4efHehBofe4g+KVmobpADXGYHHnQXDzCnVDFS2vFhGZRI2eEM4nppZ2O"
`endif