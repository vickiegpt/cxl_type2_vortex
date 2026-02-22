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


// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//------------------------------------------------------------
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
//------------------------------------------------------------
///////////////////////////////////////////////////////////////////////
// 
// $Date: 2012-03-21 
// $Revision: 1 
//------------------------------------------------------------

//`timescale 1ns / 1ps

// `define SINGLE_CLK_FIFO
module avst4to1_ss_scfifo_pipe_vcd #(
    parameter SYNC                  = 0,      //'1' value means synchronous FIFO, '0' value means asynchronous FIFO
                                              //When synchronous, user should write clock value only to wr_clock.                          
    parameter IN_DATAWIDTH          = 10,     //input data length. in asymmetric FIFO the input to output ratio should be an integer.      
    parameter OUT_DATAWIDTH         = 10,     //output data length.in asymmetric FIFO the input to output ratio should be an integer.      
    parameter ADDRWIDTH             = 8,      //2^ADDRWIDTH=FIFO depth. sets ram dimensions according to max(IN_DATAWIDTH,OUT_DATAWIDTH)   
    parameter FULL_DURING_RST       = 1,      //'1' value means that full flag is high during reset, '0' value means that full flag is low during reset.
    parameter FWFT_ENABLE           = 1,      //when FWFT_ENABLE mode,user should sample the output data with synchronized reset.
                                              // 1 = showahead mode; 0 = normal mode.
    parameter FREQ_IMPROVE          = 1,      // in order to improve design frequency, user should set this parameter to '1' value.Note: use this parameter only when truly necessary.
    parameter RD_PIPE               = 0,//1,
    parameter USE_ASYNC_RST         = 0,      // when clock is not availible during reset must set to 1
    parameter RAM_TYPE              = "MLAB", // "AUTO" or "MLAB" or "M20K".
    parameter UOFLOW_CHECKING       = "ON"    // "ON" = under/over flow checking; "OFF" = n0 under/over flow checking
    )
    
    (
    input  logic                    rst                 , //During reset and 4 cycles afterwards, no rd_en nor wr_en operations are allowed.
                                                          //Reset signal should be asserted for four cycles of rd_clock.
    input  logic                    wr_clock            , 
    input  logic                    rd_clock            , 
    input  logic                    wr_en               , 
    input  logic                    rd_en               , 
    input  logic[IN_DATAWIDTH-1:0]  din                 , 
    input  logic[ADDRWIDTH-1:0]     prog_full_offset    , //functional only for symmetric case
    input  logic[ADDRWIDTH-1:0]     prog_empty_offset   , //functional only for symmetric case
                                      //In order to prevent option of changing offset during a FIFO operation, 
                                      //insert offset values to each instantiation when mapping.
    output logic                    full                ,
    output logic                    empty               ,
    output logic[OUT_DATAWIDTH-1:0] dout                ,
    output logic                    prog_full           ,
    output logic                    prog_empty          ,
    output logic                    underflow           ,
    output logic                    overflow            ,
    output logic[ADDRWIDTH-1:0]     word_cnt_rd_side    ,  //functional only for symmetric case
    output logic[ADDRWIDTH-1:0]     word_cnt_wr_side       //functional only for symmetric case
);

localparam FIFO_WIDTH = (IN_DATAWIDTH < OUT_DATAWIDTH) ? OUT_DATAWIDTH : IN_DATAWIDTH;
localparam FWFT_ENABLE_I = (IN_DATAWIDTH > OUT_DATAWIDTH) ? 1 : FWFT_ENABLE;
localparam FIFO_DEPTH = 2**ADDRWIDTH;
localparam SHOWAHEAD = FWFT_ENABLE_I == 1 ? "ON" : "OFF";  // "ON" = showahead mode; "OFF" = normal mode.

localparam CLKS_SYNC = SYNC==1 ? "TRUE" : "FALSE";
localparam SYNC_DELAYPIPE = SYNC==1 ? 3 : 5;

localparam REG_RAM_OUT = SHOWAHEAD=="ON" ? "OFF" : "ON";

localparam INT_PROG_EMPTY = FIFO_DEPTH/4;
localparam INT_PROG_FULL  = (FIFO_DEPTH*3)/4;

logic aclr;
logic [3:0] sclr;

logic wr_clk;

    logic                    wr_en_reg  ; 
    logic                    rd_en_reg ;  
    logic[IN_DATAWIDTH-1:0]  din_reg ;   
    logic[IN_DATAWIDTH-1:0]  dout_wire ;   
    logic[IN_DATAWIDTH-1:0]  dout_fifo ;   
    logic[IN_DATAWIDTH-1:0]  dout_fifo_reg  /* synthesis preserve */; //adding this to improve timing   
    logic                    empty_wire;

    always@(posedge wr_clk) begin
        wr_en_reg <= wr_en ;
        din_reg <= din;
    end


    if(RD_PIPE == 0)begin
    assign rd_en_reg = rd_en ;
    end
    else begin
    always@(posedge wr_clk) begin
         rd_en_reg <= rd_en ;
    end
    end



    scfifo scfifo_component
      (
        .clock         (wr_clk     ),
        .data          (din        ),
        .rdreq         (rd_en_reg  ),
        .wrreq         (wr_en      ),
        .q             (dout       ),
        .empty         (empty      ),
        .sclr          (aclr       ),
        .usedw         (word_cnt_wr_side    ),
        .aclr          (1'b0       ),
        .full          (full       )
        );                       
    defparam
      scfifo_component.add_ram_output_register  = "ON",//"OFF",
      scfifo_component.enable_ecc  = "FALSE",
      scfifo_component.intended_device_family  = "Agilex 7",
      scfifo_component.lpm_hint  = "RAM_BLOCK_TYPE=M20K", //MLAB",
      scfifo_component.lpm_numwords  = FIFO_DEPTH,
      scfifo_component.lpm_showahead  = SHOWAHEAD,
      scfifo_component.lpm_type  = "scfifo",
      scfifo_component.lpm_width  = FIFO_WIDTH,
      scfifo_component.lpm_widthu  = ADDRWIDTH,
      scfifo_component.overflow_checking  = UOFLOW_CHECKING,
      scfifo_component.underflow_checking  = UOFLOW_CHECKING,
      scfifo_component.use_eab  = "ON";

assign aclr = sclr[3];

assign wr_clk = wr_clock;					

assign prog_empty = word_cnt_rd_side <= prog_empty_offset;
assign prog_full  = word_cnt_wr_side >= prog_full_offset;


always @(posedge wr_clock or posedge rst)
begin
  if (rst)
    sclr[3:0] <= 4'hf;
  else
    sclr[3:0] <= {sclr[2:0], 1'd0};
end

// synthesis translate_off

if (IN_DATAWIDTH < OUT_DATAWIDTH)
begin
    always_comb
    begin
      assert_ratio_error : assert ( OUT_DATAWIDTH % IN_DATAWIDTH == 0 ) 
        else $error("failed: invalid ratio! ratio should be integer (remainder is not allowed)");
    end
end
else
begin
  if (IN_DATAWIDTH > OUT_DATAWIDTH)
  begin
    always_comb                                                                
    begin                                                                      
      assert_ratio_error : assert ( IN_DATAWIDTH % OUT_DATAWIDTH == 0 ) 
      else $error("failed: invalid ratio! ratio should be integer (remainder is not allowed)");
    end
  end
  else 
  begin
    
  end
end
//synthesis translate_on


endmodule      
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tceBXt9cfSOg1mvLQn4kLwmGz4pBAdtEyWV/DCWd+JWXrsT6brYONCMU90QptO2EkDtt5o+lMXdKfOBoopP01oDJ6j6pT0No6HsKNxrQbLNDsNq4xWHEQssYW/yHzIyO2ro6sR1TXspwWNxjTIu3grsfvc0bTOQNDULctJgSC65mmwCDI62EulyIM2EXDOs9A97ZVA7KydhbMvH6gteDiFw7mmulr07nunkjSi0AjhLoBR+z2d5R8SzibyjVgJJyxIOdV4pXjt2CLQb+9jYmsNNCwItKEZq9BGokDAYQm1kiPcHXihKshLQWETTAtHU/kY8YMjOqYf2Qy7YDd8R1iR+2wN0UzNqNiAETc7NYBzRGsBmxW8wL3usizj9iU4ZFLgiVh05bdtitTRIpPZE/AdTvzgxugbPwRO4gF07Yj9dBDy5va/eg5ylIWOEKtDmakV7+6aesZM/6giQm2YVMJ1Szm3OvuP47pu6NBycRIuTiNrWlBFS2MNDuSgqQx+VbexXdj4u/y/3TRBpFmKxR2YS9D9aeS+F2VTv4/4lQz1iWckXL4F/Zru2kdpIbd8A53M+Gcxq9Y1aFwS3OwG9UQWi6a/Bh7Eu7ennFNRbK1JBLrH4zzTqqrEGvygRiuNcz11uSZus1GBKwOhBxxNRNgas12Grr7det+0QVHAhKPNYfgxuDvboxfSjoOLPo25mdU0lCGYvT5Xpfk6m8n581VZIh53mpGfSr2rbexf9Noc8+2iStN8J3BcqvjL5WgnJFGYBmzUL/h8EVPD+77CUqQBZl"
`endif