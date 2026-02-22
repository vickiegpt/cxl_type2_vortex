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


// $File: //acds/rel/25.1/ip/iconnect/avalon_st/altera_avalon_dc_fifo/altera_dcfifo_synchronizer_bundle.v $
// $Revision: #1 $
// $Date: 2025/02/06 $
// $Author: psgswbuild $
//-------------------------------------------------------------------------------

`timescale 1 ns / 1 ns
module altera_dcfifo_synchronizer_bundle(
                                     clk,
                                     reset_n,
                                     din,
                                     dout
                                     );
   parameter WIDTH = 1;
   parameter DEPTH = 3;   
   parameter retiming_reg_en = 0;

   input clk;
   input reset_n;
   input [WIDTH-1:0] din;
   output [WIDTH-1:0] dout;
   
   genvar i;
   
   generate
      for (i=0; i<WIDTH; i=i+1)
        begin : sync
           altera_std_synchronizer_nocut #(.depth(DEPTH), .retiming_reg_en(retiming_reg_en))
                                   u (
                                      .clk(clk), 
                                      .reset_n(reset_n), 
                                      .din(din[i]), 
                                      .dout(dout[i])
                                      );
        end
   endgenerate
   
endmodule 

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "SFf2DuiD7DvcEuC7rgGW/CdpEqYHwfxImek22u+n+pFjetMy2z8Log4TqKB4U52wh2V2qr0NdcAm6JyxYirlboiS3XWLVGXKqmi2JML3Wyy3gQ7NJeL8uuzU7eI8UAI5z+RnwgkpFO9iolKjX/TN6M2VYafMvtKkhuT5Am/PMJeXXJJltndTpFWBS6P/y59HBzBvpLKi4o+PWG+7P18GuUOrhsTa14eol4Lv3hkdKeet1+QVLVeTH/dKtAM69C/MO2d+3eNRs9dVuCPwFkxe9Jo2c8lTzzRW/YNn//XLiSfC8FI/N3YEzI4jEeNU7RuOPwqoxzH5Fla8YqbFDUmmj8LhFWZ1v+5/EUHVxzX6oBBAiQ6e3vFvZpObhwgg7vxYGVX4YIMPkWkkzkEB4Jk/9Tq0EGId5TPKJ4i3XYs9GlI9CFRc7RM70kOos0pj4IERHBJFOtW+/x5IlBAXYDktBTmQy1iKwirc25YchEGyqClIExHsTZEjfbdxezESzKuxDl41JG/Ecab6saKrmS+W0T0j3Jjn3uJNb681vFGmhaqN1F4ik1chRVqIXMoIX+XG1ECaL6iMHWTnDfZLw4Bmysg6fpIrL51uburo71J5pNRQhAVKgogOuDTJLLq+SG/moZoYTQ/IdV9MTKFU1XvRr9oj8Az9yyho97g+0521p5LlRK5SxfiLE4Hsl3EuGhDsuyOeeuGdPRQTHOfKDoOtzqudtB8O1j6jTlrk4+hewHM0bPAsPsw9DWxOPvNMXvG28VRKmM34M8WgOjptPx1RwQhHynP4wJzlOrOBtMAo/9E6vx08qWt6hIS21Jt/Ba66dKsvhVxlJpFGfoFR7X/P069/czbik5QPxV2vgTuU6Wf2PWTiPHn7cAEIPUMN6FIYG9tXJ2kjQ+iGd+NLLX0k97Xj7H0f/2X8/11tEhd9eYw5mhFxHhkFtXGXJ2rtih8riKNtj96CPcM2e/1bdx0FwR8soLMoJt45DIvg3JvvzlTGxApOkWoD1cEVOnygvNFG"
`endif