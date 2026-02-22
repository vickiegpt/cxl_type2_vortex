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


// ***************************************************************************
//                               INTEL CONFIDENTIAL
//
//        Copyright (C) 2008-2011 Intel Corporation All Rights Reserved.
//
// The source code contained or described herein and all  documents related to
// the  source  code  ("Material")  are  owned  by  Intel  Corporation  or its
// suppliers  or  licensors.    Title  to  the  Material  remains  with  Intel
// Corporation or  its suppliers  and licensors.  The Material  contains trade
// secrets  and  proprietary  and  confidential  information  of  Intel or its
// suppliers and licensors.  The Material is protected  by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may be
// used,   copied,   reproduced,   modified,   published,   uploaded,  posted,
// transmitted,  distributed,  or  disclosed  in any way without Intel's prior
// express written permission.
//
// No license under any patent,  copyright, trade secret or other intellectual
// property  right  is  granted  to  or  conferred  upon  you by disclosure or
// delivery  of  the  Materials, either expressly, by implication, inducement,
// estoppel or otherwise.  Any license under such intellectual property rights
// must be express and approved by Intel in writing.
//
// Engineer:            Yoanna Baumgartner, Mark Wolski
// Create Date:         Fri Jul 29 14:45:50 PDT 2011
// Module Name:         gram_sdp_be.v
// Project:             TBF/LVF 
// Description:
//
// ***************************************************************************
// gram_sdp_be.v: Generic simple dual port RAM with one write port and one read port
// qigang.wang@intel.com Copyright Intel 2008
// edited by pratik marolia on 3/15/2010
// edited by yoanna baumgartner on 1/23/2018
// Created 2008Oct16
// referenced Arthur's VHDL version
//
// Generic dual port RAM. This module helps to keep your HDL code architecture
// independent. 
//
// This module makes use of synthesis tool's automatic RAM recognition feature.
// It can infer distributed as well as block RAM. The type of inferred RAM
// depends on GRAM_STYLE and mode. 
// GRAM_AUTO : Let the tool to decide 
// GRAM_BLCK : Use block RAM
// GRAM_DIST : Use distributed RAM
// 
// Diagram of GRAM:
//
//           +---+      +------------+     +------+
//   raddr --|1/3|______|            |     | 2/3  |
//           |>  |      |            |-----|      |-- dout
//           +---+      |            |     |>     |
//        din __________|   RAM      |     +------+
//      waddr __________|            |
//        we  __________|            |
//        be  __________|            |
//        clk __________|\           |
//                      |/           |
//                      +------------+
//
// You can override parameters to customize RAM.
//

module gram_sdp_be
  import gbl_pkg::*;
#(
  parameter BUS_SIZE_ADDR = 4,                  // number of bits of address bus
  parameter BUS_SIZE_DATA = 32,                 // number of bits of data bus.  Must be multiple of 8.
  parameter GRAM_MODE =     2'd3,               // GRAM read mode defaults to Buffered read, 2 cycle delay. (1 or 3 only !!!!!)
  parameter BUS_SIZE_BE =   BUS_SIZE_DATA/8,    // Number of ByteEnables. Use default.
  parameter GRAM_STYLE =    gbl_pkg::GRAM_AUTO  // GRAM_AUTO, GRAM_BLCK, GRAM_DIST
 )
(
  input  logic                         clk,    // input   clock
  input  logic                         we,     // input   write enable
  input  logic [BUS_SIZE_BE-1:0]       be,     // input   write ByteEnables
  input  logic [BUS_SIZE_ADDR-1:0]     waddr,  // input   write address with configurable width
  input  logic [BUS_SIZE_DATA-1:0]     din,    // input   write data with configurable width
  input  logic [BUS_SIZE_ADDR-1:0]     raddr,  // input   read address with configurable width
  output logic [BUS_SIZE_DATA-1:0]     dout    // output  write data with configurable width
);

//Add directive to don't care the behavior of read/write same address
(*ramstyle=GRAM_STYLE*) reg [BUS_SIZE_BE-1:0][7:0] ram [(2**BUS_SIZE_ADDR)-1:0];  //ram divided into bytes.

reg [BUS_SIZE_DATA-1:0] ram_dout;

// mw: Start timescale test
/*synthesis translate_off */
reg                     driveX;         // simultaneous access detected. Drive X on output

initial
begin
//$display("mw: printing the timescale upon entry into gram_sdp.");
//$printtimescale(); // mw: added to observe timescale upon entry into gram_sdp
  $display("mw: printing the array parameters for RAM detection in gram_sdp_be.");
  $display("mw: from gram_sdp_be, inside hierarchy %m with array params: %4d x %4d",BUS_SIZE_ADDR,BUS_SIZE_DATA);
end
/*synthesis translate_on */
// mw: End timescale test

generate if( GRAM_MODE == 1 )
begin : GEN_SYN_READ                     // synchronous read (rd, data valid next cycle) 

  always_ff @(posedge clk)
  begin
    if( we )
    begin
      for(int i=0; i < (BUS_SIZE_DATA/8); i++) 
      begin
        if( be[i] )
        begin
          ram[waddr][i]  <= din[7+(8*i)-:8]; 
        end
      end
    end
  end

  always_ff @(posedge clk)
  begin
                    /* synthesis translate_off */
    if(driveX)
       dout <= 'hx;
    else            /* synthesis translate_on */
       dout<= ram[raddr];
  end

  /* synthesis translate_off */
    always_comb
    begin
      driveX = 0;

      if( (raddr == waddr) & we ) driveX  = 1;
      else                        driveX  = 0;
    end
  /*synthesis translate_on */

end
else if( GRAM_MODE == 3 )  // synchronous read, buffer output (rd, data valid 2nd cycle after)
begin : GEN_SYN_READ_BUF_OUTPUT

  always_ff @(posedge clk)
  begin
    if( we )
    begin
      for(int i=0; i < (BUS_SIZE_DATA/8); i++) 
      begin
        if( be[i] )
        begin
          ram[waddr][i]  <= din[7+(8*i)-:8]; 
        end
      end
    end
  end

  always_ff @(posedge clk)
  begin
                    /* synthesis translate_off */
    if(driveX)
       dout <= 'hx;
    else            /* synthesis translate_on */
       dout <= ram_dout;    //buffer ram output
  end

  always_ff @(posedge clk)
  begin
    ram_dout <= ram[raddr];
  end

  /* synthesis translate_off */
    always_ff @(posedge clk)
    begin
      //driveX = 0;

      if( (raddr == waddr) & we ) driveX  = 1;
      else                        driveX  = 0;
    end
  /*synthesis translate_on */

end
endgenerate

 
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aJX0lR3p5xmD24Jw6DokcCC+M0ehts4olfvpyHI4MGLvpNU8+tXnJ3rQyICHoKbxqek/mDk8w0z7sVVbqv2JhnvzHzLQQ+mE9YDi6gZf11AIvRQWnK7f3yMgvdNGU9AhiPTQzwU3LgSK5NbH+4FhAYErmGk17YDiCCrlsagMlhanxpJJyPoFpqLS0USGTtwxYLnJeLzVc6SsRYm9YGDZqnGm46YqsTskqfwur4JLa3MnVLErWexnEyghJkB89vKz5C5cpDIaTIEgGn/uQPfdGWVC9bsSzFABHzwnVarwuGBGfkiTl3XnOGq23l1bcs1QU5e2pvr13KcsGYMAOAtqAVabpH9TuiZcTV4oOxeWSkMAl0TneJqzbBOTtaUUpU/dB9AXS20U2bd9zdUurMEzdzbe63WC7leoi+njF81wjUGRcXPUMNJlTu6r0BUTnTLUv28XTAu3RJ/L1EzEhftiSsj8zJ2Slrs2cLqWGzotLkk9fUDfHUm/GGBHofiMnvxwSMguxE68tC1x+Jw5cQnxUUiOYvQwh0mepQLYgnYlBEbbC80foG5axT9DOHUVtQp2+zqaferglU4uc+pS6YtyyUeKNrNy1uamD1xUECO0OZzLKXO/OR/gdWFh5AIZ4eP3FvuYLalx/zzwQwhEUDcvsSjEh/gcy+p8ujN8qfknNK2R3wG7TtDBFKeLBNuPcTzQeLwmCQLfazi2DXdJVL3XttaTRIYDMkIbRKWy4ZeTJe2qfZn/pnxt9Uzeim4pQwHf6mvj6yei1HdQ52XXM3/bFNm"
`endif