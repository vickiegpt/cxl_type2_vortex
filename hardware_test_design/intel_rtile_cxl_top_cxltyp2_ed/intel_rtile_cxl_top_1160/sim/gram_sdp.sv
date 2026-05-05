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
// Module Name:         gram_sdp.v
// Description:
//
// ***************************************************************************
// gram_sdp.v: Generic simple dual port RAM with one write port and one read port
//
// Generic dual port RAM. This module helps to keep your HDL code architecture
// independent.
//
//
// This module makes use of synthesis tool's automatic RAM recognition feature.
// It can infer distributed as well as block RAM. The type of inferred RAM
// depends on GRAM_STYLE and mode.
// RAM. There are three supported values for GRAM_STYLE.
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
//        clk __________|\           |
//                      |/           |
//                      +------------+
//
// You can override parameters to customize RAM.
//

module gram_sdp
  import gbl_pkg::*;
#(
  parameter BUS_SIZE_ADDR = 4,                  // number of bits of address bus
  parameter BUS_SIZE_DATA = 32,                 // number of bits of data bus
  parameter GRAM_MODE =     2'd3,               // GRAM read mode
  parameter GRAM_STYLE =    gbl_pkg::GRAM_AUTO  // GRAM_AUTO, GRAM_BLCK, GRAM_DIST
)
(
  input logic                     clk,   // input   clock
  input logic                     we,    // input   write enable
  input logic [BUS_SIZE_ADDR-1:0] waddr, // input   write address with configurable width
  input logic [BUS_SIZE_DATA-1:0] din,   // input   write data with configurable width
  input logic [BUS_SIZE_ADDR-1:0] raddr, // input   read address with configurable width

  output logic [BUS_SIZE_DATA-1:0] dout  // output  write data with configurable width
);

  //localparam RAM_BLOCK_TYPE = GRAM_STYLE==gbl_pkg::GRAM_BLCK
  //                          ? "M20K"
  //                          : GRAM_STYLE==gbl_pkg::GRAM_DIST
  //                            ? "MLAB"
  //                            : "AUTO";

//Add directive to don't care the behavior of read/write same address
//This allows Quartus to choose an MLAB for smaller RAMs in S10
//This may not be required in FalconMesa!
(*ramstyle= GRAM_STYLE*) logic [BUS_SIZE_DATA-1:0] ram [(2**BUS_SIZE_ADDR)-1:0];

// mw: Start timescale test
/*synthesis translate_off */
initial
begin
  $display("mw: printing the timescale upon entry into gram_sdp.");
  $printtimescale(); // mw: added to observe timescale upon entry into gram_sdp
  $display("mw: printing the array parameters for RAM detection in gram_sdp.");
  $display("mw: from gram_sdp, inside hierarchy %m with array params: %4d x %4d and GRAM_MODE=%2d",BUS_SIZE_ADDR,BUS_SIZE_DATA,GRAM_MODE);
end
/*synthesis translate_on */
// mw: End timescale test


`ifndef CXLDCOH_RAM
  // If it's not the case that this is being run with Leucadia (LCD) RAM replacements
  // then use the TBF generate statement, previously in place, as-is, with GRAM_MODE cases 0,1,2,3
  generate if( GRAM_MODE == 0 ) // asynchronous read
  begin : gen_GEN_ASYN_READ

          always_ff @(posedge clk)
          begin
            if(we) ram[waddr]<=din; // synchronous write the RAM
          end

           always_comb
           begin
             dout = ram[raddr];
           end

  end
  else if( GRAM_MODE == 1 ) // synchronous read (rd, data valid next cyc)
  begin : gen_GEN_SYN_READ

     /*synthesis translate_off */
       logic driveX; // simultaneous access detected. Drive X on output
     /*synthesis translate_on */

          always_ff @(posedge clk)
          begin
            if(we) ram[waddr] <= din; // synchronous write the RAM
          end

          always_ff @(posedge clk)
          begin
            /* synthesis translate_off */
            if(driveX) dout <= 'hx;
            else
            /* synthesis translate_on */
                       dout <= ram[raddr];
          end

          /*synthesis translate_off */
          always_comb
          begin
            driveX = 0;

            if( (raddr == waddr) && we) driveX  = 1;
            else                        driveX  = 0;
          end
          /*synthesis translate_on */
  end
  else if( GRAM_MODE == 2 ) // False synchronous read, buffer output
  begin : gen_GEN_FALSE_SYN_READ

        logic [BUS_SIZE_DATA-1:0] ram_dout;

           always_comb
           begin
             ram_dout = ram[raddr];
             /*synthesis translate_off */
             if( (raddr == waddr) && we) ram_dout = 'hx;
             /*synthesis translate_on */
           end

           always @(posedge clk)
           begin
             if (we) ram[waddr]<=din; // synchronous write the RAM
           end

           always @(posedge clk)
           begin
             dout <= ram_dout;
           end

  end
  else begin : gen_GEN_SYN_READ_BUF_OUTPUT          // synchronous read, buffer output (rd, data valid 2nd cycle after)

             logic [BUS_SIZE_DATA-1:0] ram_dout;

     /*synthesis translate_off */
       logic driveX; // simultaneous access detected. Drive X on output
     /*synthesis translate_on */

           always_ff @(posedge clk)
           begin
             if(we) ram[waddr]<=din; // synchronous write the RAM
           end

           always_ff @(posedge clk)
           begin
             ram_dout <= ram[raddr];
           end

           always_ff @(posedge clk)
           begin
             /*synthesis translate_off */
             if(driveX) dout <= 'hx;
             else
             /*synthesis translate_on */
                       dout <= ram_dout;
           end

           /*synthesis translate_off */
           always_ff @(posedge clk)
           begin
              if( (raddr == waddr) && we) driveX <= 1;
              else                        driveX <= 0;
           end
           /*synthesis translate_on */

  end
  endgenerate

`else
  // ------------------------------------------------------------------------------------------------------------------------
  // We are defined as Leucadia (LCD) and we are using LCD RAMs, so we want to replace the RAM call that was previously made
  //  for TBF with a Leucadia replacement RAM that was created using memlister (for TSMC N5 arrays) by Vijay Gullapalli for
  //  our use in the BBS in the Leucadia ASIC.
  // ------------------------------------------------------------------------------------------------------------------------

  // ------------------------------------------------------------------------------------------------------------------------
  // First, we generate the code to instantiate the new RAM based on the dimensions of the array.
  // These RAMS are only used once.  They are self-contained to handle the depth and width of the former TBF RAM in a
  //  single instance.
  // ------------------------------------------------------------------------------------------------------------------------
  generate

  logic [4:0]   RSCOUT                ;
  logic         RSCIN       = 1'b0    ;
  logic         RSCEN       = 1'b0    ;
  logic         RSCRST      = 1'b0    ;
  logic         RSCLK       = 1'b0    ;
  logic         FISO        = 1'b0    ;
  logic [2:0]   WA          = 3'b100  ; // mw: Value of 3'b100 provided by Vijay in vcs.ucli file from Outlook email sent 6/8/20
  logic [2:0]   WPULSE      = 3'b000  ;
  logic [1:0]   RA          = 2'b00   ;
  logic [3:0]   RM          = 4'b0100 ; // mw: Value of 4'b0100 provided by Vijay in vcs.ucli file from Outlook email sent 6/8/20

  if (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 88 )
    begin: bbs_16x88
    //generate
      saculs0g4l2p16x88m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x88_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]      ),
          .QB       (ram_dout       ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       (din            ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_16x88

  if (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 96 )
    begin: bbs_16x96
    //generate
      saculs0g4l2p16x96m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x96_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_16x96

  if (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 102)
    begin: bbs_16x102
    //generate
      saculs0g4l2p16x102m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x102_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_16x102

  if (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 63 )
    begin: bbs_32x63w64
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p32x64m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_5x63_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_32x63w64

  if (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 64 ) // mw: Added for growth, required for 32x63
    begin: bbs_32x64
    //generate
      saculs0g4u2p32x64m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_5x64_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_32x64

  if (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 94 )
    begin: bbs_32x94
    //generate
      saculs0g4l2p32x94m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_5x94_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_32x94


  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 21 )
    begin: bbs_64x21w22
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p64x22m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x21_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_64x21w22

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 22 ) // mw: Added for growth, required for 64x21
    begin: bbs_64x22
    //generate
      saculs0g4u2p64x22m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x22_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_64x22

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 28 )
    begin: bbs_64x28
    //generate
      saculs0g4u2p64x28m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x28_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x28

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 41 )
    begin: bbs_64x41w42
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p64x42m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x41_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({1'b0,din} ),
        //.DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x41w42

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 42 ) // mw: Added for growth, required for 64x41
    begin: bbs_64x42
    //generate
      saculs0g4u2p64x42m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x42_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
        //.DA       ({1'b0,din} ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x42

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 93 ) // mw: Added for growth, required for 64x94
    begin: bbs_64x93w94
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4l2p64x94m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x93_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_64x93w94

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 94 )
    begin: bbs_64x94
    //generate
      saculs0g4l2p64x94m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x94_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_64x94

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 26 )
    begin: bbs_128x26
    //generate
      saculs0g4u2p128x26m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x26_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_128x26

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 35 )
    begin: bbs_128x35w36
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p128x36m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x35_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x35w36

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 36 )
    begin: bbs_128x36
    //generate
      saculs0g4u2p128x36m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x36_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x36

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 67 ) // mw: Added for growth, required for 128x68
    begin: bbs_128x67w68
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p128x68m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x67_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x67w68

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 68 )
    begin: bbs_128x68
    //generate
      saculs0g4u2p128x68m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x68_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x68

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 89 )
    begin: bbs_128x89w90
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p128x90m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x89_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x89w90

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 90 ) // mw: Added for growth, required for 128x89
    begin: bbs_128x90
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p128x90m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x90_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_128x89w90

  if (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 4  )
    begin: bbs_256x4w8
    //generate

      logic [3:0]   pad;  // padding to match data to RAM width

      saculs0g4u2p256x8m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_8x4_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad[3:0],ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({4'h0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+4{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_256x4w8

  if (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 8  )
    begin: bbs_256x8
    //generate
      saculs0g4u2p256x8m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_8x8_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_256x8

  if (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 67 ) // mw: Added for growth, required for 256x68
    begin: bbs_256x67w68
    //generate

      logic   pad;  // padding to match data to RAM width

      saculs0g4u2p256x68m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_8x67_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout} ),
        //.QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
          .DA       ({1'b0,din}     ),
        //.DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_256x67w68

  if (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 68 )
    begin: bbs_256x68
    //generate
      saculs0g4u2p256x68m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_8x68_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout} ),
          .QB       (ram_dout       ),
          // Inputs
          .ADRA     (waddr          ),
        //.DA       ({1'b0,din}     ),
          .DA       (din            ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we             ),
          .MEA      ('1             ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk            ),
          .RME      ('0             ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM             ),
          .TEST_RNM ('0             ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0             ),
          .BC0      ('0             ),
          .BC1      ('0             ),
          .BC2      ('0             ),
          .ADRB     (raddr          ),
          .MEB      ('1             ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0             ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0             )
        );
    end // bbs_256x68

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 6  )
    begin: bbs_512x6w8
    //generate

      logic [1:0]   pad;  // padding to match data to RAM width

      saculs0g4l2p512x8m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x6_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad[1:0],ram_dout}),
        //.QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({2'b00,din}),
        //.DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA+2{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x6w8

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 9  )
    begin: bbs_512x9
    //generate
      saculs0g4l2p512x9m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x9_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x9

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 11 )
    begin: bbs_512x11
    //generate
      saculs0g4u2p512x11m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x11_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x11

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 12 )
    begin: bbs_512x12
    //generate
      saculs0g4u2p512x12m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x12_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x12

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 16 )
    begin: bbs_512x16
    //generate
      saculs0g4u2p512x16m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x16_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x16

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 25 )
    begin: bbs_512x25
    //generate
      saculs0g4u2p512x25m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x25_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x25

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 33 ) // mw: Added for growth, required for 512x34
    begin: bbs_512x33w34
    //generate

      logic   pad;  // padding to temporarily match data to existing RAM width

      saculs0g4u2p512x34m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x33_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       ({pad,ram_dout}),
        //.QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({1'b0,din} ),
        //.DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x33w34

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 34 )
    begin: bbs_512x34
    //generate
      saculs0g4u2p512x34m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x34_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
        //.QB       ({pad,ram_dout}),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
        //.DA       ({1'b0,din} ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x34

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 49 )
    begin: bbs_512x49
    //generate
      saculs0g4u2p512x49m4b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_9x49_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_512x49

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 53 )
    begin: bbs_512x53w54
    //generate

      logic   pad;  // padding to match data to RAM width

      sacrls0g4u2p512x54m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x53_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         ({pad,ram_dout}),
        //.QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
          .DA         ({1'b0,din} ),
        //.DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x53w54

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 54 ) // mw: Added for growth, required for 512x53
    begin: bbs_512x54
    //generate
      sacrls0g4u2p512x54m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x54_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
        //.QB         ({pad,ram_dout}),
          .QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
        //.DA         ({1'b0,din} ),
          .DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x54

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 72 )
    begin: bbs_512x72
    //generate
      sacrls0g4u2p512x72m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x72_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x72

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 82 )
    begin: bbs_512x82
    //generate
      sacrls0g4u2p512x82m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x82_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x82

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 86 )
    begin: bbs_512x86
    //generate
      sacrls0g4u2p512x86m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x86_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x86

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 107)
    begin: bbs_512x107w108
    //generate

      logic   pad;  // padding to match data to RAM width

      sacrls0g4u2p512x108m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x107_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         ({pad,ram_dout}),
        //.QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
          .DA         ({1'b0,din} ),
        //.DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA+1{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x107w108

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 108) // mw: Added for growth, required for 512x107
    begin: bbs_512x108
    //generate
      sacrls0g4u2p512x108m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x108_d1w1
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
        //.QB         ({pad,ram_dout}),
          .QB         (ram_dout   ),
          // Inputs
          .ADRA       (waddr      ),
        //.DA         ({1'b0,din} ),
          .DA         (din        ),
          .WEMA       ({BUS_SIZE_DATA{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x108

  if (BUS_SIZE_ADDR == 10 & BUS_SIZE_DATA == 17 )
    begin: bbs_1024x17
    //generate
      sasuls0g4u2p1024x17m16b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_10x17_d1w1
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout   ),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din        ),
          .WEMA     ({BUS_SIZE_DATA{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_1024x17

  // ========================================================================================================================
  // Width-Coupling (only) RAMs
  // ========================================================================================================================

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_8x601
  //  NOTE: Depth is doubled; Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 3  & BUS_SIZE_DATA == 601)
    begin: bbs_8x601
    //generate

      logic [8:0]   pad;  // padding to match data to RAM width.

      saculs0g4l2p16x122m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_3x601_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       ({pad[8:0],ram_dout[600:488]}),
          // Inputs
          .ADRA     ({1'b0,waddr}),
          .DA       ({9'h000,din[600:488]}),
          .WEMA     ({122{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     ({1'b0,raddr}),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x122m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_3x601_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[487:366]),
          // Inputs
          .ADRA     ({1'b0,waddr}),
          .DA       (din[487:366]),
          .WEMA     ({122{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     ({1'b0,raddr}),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x122m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_3x601_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[365:244]),
          // Inputs
          .ADRA     ({1'b0,waddr}),
          .DA       (din[365:244]),
          .WEMA     ({122{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     ({1'b0,raddr}),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x122m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_3x601_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[243:122]),
          // Inputs
          .ADRA     ({1'b0,waddr}),
          .DA       (din[243:122]),
          .WEMA     ({122{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     ({1'b0,raddr}),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x122m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_3x601_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[121:0]),
          // Inputs
          .ADRA     ({1'b0,waddr}),
          .DA       (din[121:0] ),
          .WEMA     ({122{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     ({1'b0,raddr}),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_8x601

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_16x512
  //  NOTE: Width is split between four equal 128 bit RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 512)
    begin: bbs_16x512
    //generate
      saculs0g4l2p16x128m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x512_d1w4_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[BUS_SIZE_DATA-1:3*(BUS_SIZE_DATA/4)]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[BUS_SIZE_DATA-1:3*(BUS_SIZE_DATA/4)]),
          .WEMA     ({128{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x128m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x512_d1w4_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[3*(BUS_SIZE_DATA/4)-1:2*(BUS_SIZE_DATA/4)]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[3*(BUS_SIZE_DATA/4)-1:2*(BUS_SIZE_DATA/4)]),
          .WEMA     ({128{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x128m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x512_d1w4_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[2*(BUS_SIZE_DATA/4)-1:BUS_SIZE_DATA/4]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[2*(BUS_SIZE_DATA/4)-1:BUS_SIZE_DATA/4]),
          .WEMA     ({128{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p16x128m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_4x512_d1w4_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[BUS_SIZE_DATA/4-1:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[BUS_SIZE_DATA/4-1:0]),
          .WEMA     ({128{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_16x512

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_64x520
  //  NOTE: Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 520)
    begin: bbs_64x520
    //generate
      saculs0g4l2p64x104m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x520_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       (ram_dout[5*BUS_SIZE_DATA/5-1:4*BUS_SIZE_DATA/5]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[5*BUS_SIZE_DATA/5-1:4*BUS_SIZE_DATA/5]),
          .WEMA     ({104{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x104m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x520_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[4*BUS_SIZE_DATA/5-1:3*BUS_SIZE_DATA/5]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[4*BUS_SIZE_DATA/5-1:3*BUS_SIZE_DATA/5]),
          .WEMA     ({104{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x104m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x520_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[3*BUS_SIZE_DATA/5-1:2*BUS_SIZE_DATA/5]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[3*BUS_SIZE_DATA/5-1:2*BUS_SIZE_DATA/5]),
          .WEMA     ({104{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x104m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x520_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[2*BUS_SIZE_DATA/5-1:BUS_SIZE_DATA/5]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[2*BUS_SIZE_DATA/5-1:BUS_SIZE_DATA/5]),
          .WEMA     ({104{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x104m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x520_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[BUS_SIZE_DATA/5-1:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[BUS_SIZE_DATA/5-1:0] ),
          .WEMA     ({104{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x520

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_64x586
  //  NOTE: Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 586)
    begin: bbs_64x586
    //generate

      logic [3:0]   pad;  // padding to match data to RAM width.

      saculs0g4l2p64x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x586_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       ({pad[3:0],ram_dout[585:472]}),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({4'h0,din[585:472]}),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x586_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[471:354]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[471:354]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x586_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[353:236]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[353:236]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x586_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[235:118]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[235:118]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4l2p64x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x586_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[117:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[117:0] ),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x586

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_64x594
  //  NOTE: Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 594)
    begin: bbs_64x594
    //generate

      logic [5:0]   pad;  // padding to match data to RAM width.

      saculs0g4u2p64x120m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x594_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       ({pad[5:0],ram_dout[593:480]}),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({6'h00,din[593:480]}),
          .WEMA     ({120{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p64x120m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x594_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[479:360]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[479:360]),
          .WEMA     ({120{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p64x120m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x594_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[359:240]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[359:240]),
          .WEMA     ({120{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p64x120m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x594_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[239:120]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[239:120]),
          .WEMA     ({120{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p64x120m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_6x594_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[119:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[119:0] ),
          .WEMA     ({120{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_64x594

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_128x521
  //  NOTE: Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 521)
    begin: bbs_128x521
    //generate

      logic [8:0]   pad;  // padding to match data to RAM width.

      saculs0g4u2p128x106m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x521_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       ({pad[8:0],ram_dout[520:424]}),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({9'h000,din[520:424]}),
          .WEMA     ({106{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x106m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x521_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[423:318]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[423:318]),
          .WEMA     ({106{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x106m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x521_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[317:212]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[317:212]),
          .WEMA     ({106{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x106m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x521_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[211:106]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[211:106]),
          .WEMA     ({106{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x106m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x521_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[105:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[105:0] ),
          .WEMA     ({106{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_128x521

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_128x586
  //  NOTE: Width is split between five RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 586)
    begin: bbs_128x586
    //generate

      logic [3:0]   pad;  // padding to match data to RAM width.

      saculs0g4u2p128x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x586_d1w5_4
        (
          // Outputs
          .RSCOUT   (RSCOUT[4]  ),
          .QB       ({pad[3:0],ram_dout[585:472]}),
          // Inputs
          .ADRA     (waddr      ),
          .DA       ({4'h0,din[585:472]}),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x586_d1w5_3
        (
          // Outputs
          .RSCOUT   (RSCOUT[3]  ),
          .QB       (ram_dout[471:354]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[471:354]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x586_d1w5_2
        (
          // Outputs
          .RSCOUT   (RSCOUT[2]  ),
          .QB       (ram_dout[353:236]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[353:236]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x586_d1w5_1
        (
          // Outputs
          .RSCOUT   (RSCOUT[1]  ),
          .QB       (ram_dout[235:118]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[235:118]),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );

      saculs0g4u2p128x118m2b1w1c1p0d0l1rm4rw11e10zh0h0ms0mg0
        DC_1r1w1c_7x586_d1w5_0
        (
          // Outputs
          .RSCOUT   (RSCOUT[0]  ),
          .QB       (ram_dout[117:0]),
          // Inputs
          .ADRA     (waddr      ),
          .DA       (din[117:0] ),
          .WEMA     ({118{1'b1}}),
          .WEA      (we         ),
          .MEA      ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .CLK      (clk        ),
          .RME      ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RM       (RM         ),
          .TEST_RNM ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .LS       ('0         ),
          .BC0      ('0         ),
          .BC1      ('0         ),
          .BC2      ('0         ),
          .ADRB     (raddr      ),
          .MEB      ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .RSCIN    (RSCIN      ),
          .RSCEN    (RSCEN      ),
          .RSCRST   (RSCRST     ),
          .RSCLK    (RSCLK      ),
          .FISO     (FISO       ),
          .WA       (WA[2:0]    ),
          .WPULSE   (WPULSE[2:0]),
          .RA       (RA[1:0]    ),
          .TEST1    ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLK).
          .TESTRWM  ('0         )
        );
    end // bbs_128x586

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_512x513
  //  NOTE: Width is split between three RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 513)
    begin: bbs_512x513
    //generate

      logic [2:0]   pad;  // padding to match data to RAM width.

      sacrls0g4u2p512x172m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x513_d1w3_2
        (
          // Outputs
          .RSCOUT     (RSCOUT[2]  ),
          .QB         ({pad[2:0],ram_dout[512:344]}),
          // Inputs
          .ADRA       (waddr      ),
          .DA         ({3'b000,din[512:344]}),
          .WEMA       ({172{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );

      sacrls0g4u2p512x172m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x513_d1w3_1
        (
          // Outputs
          .RSCOUT     (RSCOUT[1]  ),
          .QB         (ram_dout[343:172]),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din[343:172]),
          .WEMA       ({172{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );

      sacrls0g4u2p512x172m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x513_d1w3_0
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         (ram_dout[171:0]),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din[171:0]),
          .WEMA       ({172{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x513

  // ------------------------------------------------------------------------------------------------------------------------
  // bbs_512x528
  //  NOTE: Width is split between three RAMs
  // ------------------------------------------------------------------------------------------------------------------------

  if (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 528)
    begin: bbs_512x528
    //generate

      sacrls0g4u2p512x176m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x528_d1w3_2
        (
          // Outputs
          .RSCOUT     (RSCOUT[2]  ),
          .QB         (ram_dout[527:352]),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din[527:352]),
          .WEMA       ({176{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );

      sacrls0g4u2p512x176m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x528_d1w3_1
        (
          // Outputs
          .RSCOUT     (RSCOUT[1]  ),
          .QB         (ram_dout[351:176]),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din[351:176]),
          .WEMA       ({176{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );

      sacrls0g4u2p512x176m2b4w1c1p0d0l1rm4rw11zh0h0ms0mg0
        DC_1r1w2c_9x528_d1w3_0
        (
          // Outputs
          .RSCOUT     (RSCOUT[0]  ),
          .QB         (ram_dout[175:0]),
          // Inputs
          .ADRA       (waddr      ),
          .DA         (din[175:0] ),
          .WEMA       ({176{1'b1}}),
          .WEA        (we         ),
          .MEA        ('1         ),  // Memory Enable input (wr). When the Memory Enable input is Logic High, the memory is enabled and write operations can be performed using ADRA and WEA.
          .RSCIN      (RSCIN      ),
          .RSCEN      (RSCEN      ),
          .RSCRST     (RSCRST     ),
          .RSCLK      (RSCLK      ),
          .FISO       (FISO       ),
          .CLKA       (clk        ),
          .TEST1A     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKA).
          .TEST_RNMA  ('0         ),  // When this pin is high, memory will go in idle state and bit-lines are pre-charged high. ATPG mode should be turned off in this mode.
          .RMEA       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMA        ('0         ),
          .RA         (RA[1:0]    ),
          .WA         (WA[2:0]    ),
          .WPULSE     (WPULSE[2:0]),
          .LS         ('0         ),
          .ADRB       (raddr      ),
          .MEB        ('1         ),  // Memory Enable input (rd). When the Memory Enable input is Logic High, the memory is enabled and read operations can be performed using ADRB.
          .CLKB       (clk        ),
          .TEST1B     ('0         ),  // When TEST1=1, the memory self time circuitry is bypassed, and the memory timing is controlled by the external clock signal (CLKB).
          .RMEB       ('0         ),  // Read-Write Margin Enable Input. This input selects between the default Read-Write margin setting (RME=0), and the external pin Read-Write margin setting (RME=1).
          .RMB        ('0         )
        );
    end // bbs_512x528


  // ------------------------------------------------------------------------------------------------------------------------
  // Next we generate the common code to handle the GRAM_MODE being either:
  //  type 1 (dout fed directly from the ram_dout (QB) output, or
  //  type 3 (dout fed from a cycle-delayed buffer stage of ram_dout (QB) output
  // All of the above instance generations use this same logic.
  // ------------------------------------------------------------------------------------------------------------------------

  if (  (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 88 )
      | (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 96 )
      | (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 102)
      | (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 63 )
      | (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 64 ) // mw: Added for growth, required for 32x63
      | (BUS_SIZE_ADDR == 5  & BUS_SIZE_DATA == 94 )
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 21 )
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 22 ) // mw: Added for growth, required for 64x21
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 28 )
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 41 )
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 42 ) // mw: Added for growth, required for 64x41
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 93 ) // mw: Added for growth, required for 64x94
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 94 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 26 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 35 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 36 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 67 ) // mw: Added for growth, required for 128x68
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 68 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 89 )
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 90 ) // mw: Added for growth, required for 128x89
      | (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 4  )
      | (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 8  )
      | (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 67 ) // mw: Added for growth, required for 256x68
      | (BUS_SIZE_ADDR == 8  & BUS_SIZE_DATA == 68 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 6  )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 9  )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 11 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 12 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 16 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 25 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 33 ) // mw: Added for growth, required for 512x34
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 34 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 49 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 53 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 54 ) // mw: Added for growth, required for 512x53
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 72 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 82 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 86 )
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 107)
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 108) // mw: Added for growth, required for 512x107
      | (BUS_SIZE_ADDR == 10 & BUS_SIZE_DATA == 17 )
    // Width-Coupling (only) RAMs
      | (BUS_SIZE_ADDR == 3  & BUS_SIZE_DATA == 601)
      | (BUS_SIZE_ADDR == 4  & BUS_SIZE_DATA == 512)
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 520)
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 586)
      | (BUS_SIZE_ADDR == 6  & BUS_SIZE_DATA == 594)
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 521)
      | (BUS_SIZE_ADDR == 7  & BUS_SIZE_DATA == 586)
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 513)
      | (BUS_SIZE_ADDR == 9  & BUS_SIZE_DATA == 528)
     )
    begin: common_ram_code
      if (GRAM_MODE == 3)
        begin: SYN_READ_STG_DLY
          always @(posedge clk)
            begin
              dout <= ram_dout; // Create an additional stage of flop
              /*synthesis translate_off */
              if(driveX)
                dout <= 'hx;
              if(raddr==waddr && we)
                driveX <= 1;
              else
                driveX <= 0;
              /*synthesis translate_on */
            end
        end   // (GRAM_MODE == 3)
      else  // (GRAM_MODE == 1)
      //mw:RAM fix attempt:begin: SYN_READ
      //mw:RAM fix attempt:  always_comb
      //mw:RAM fix attempt:    begin
      //mw:RAM fix attempt:      dout = ram_dout;
      //mw:RAM fix attempt:      /* synthesis translate_off */
      //mw:RAM fix attempt:      if(driveX)
      //mw:RAM fix attempt:        dout <= 'hx;
      //mw:RAM fix attempt:      if(raddr==waddr && we)
      //mw:RAM fix attempt:        driveX  = 1;
      //mw:RAM fix attempt:      else
      //mw:RAM fix attempt:        driveX  = 0;
      //mw:RAM fix attempt:      /* synthesis translate_on */
      //mw:RAM fix attempt:    end // always_comb
      //mw:RAM fix attempt:end   // (GRAM_MODE == 1)
        begin : SYN_READ  // synchronous read (rd, data valid next cyc)
          /* synthesis translate_off */
          always @(posedge clk)
            begin
              if(raddr==waddr && we)
                driveX <= 1;
              else
                driveX <= 0;
            end
          /* synthesis translate_on */
          always @(*)
            begin
          /*synthesis translate_off */
              if(driveX == 1)
                dout = 'hx;
              else
          /*synthesis translate_on */
                dout = ram_dout;
            end
        end
    end // common_ram_code

  // ------------------------------------------------------------------------------------------------------------------------
  // Else if the Leucadia instances are not detected, then generate the old tbf RAM logic as a fallback
  // ------------------------------------------------------------------------------------------------------------------------
  else
    begin: tbf_ram
    //generate
      case (GRAM_MODE)
      //0: begin : GEN_ASYN_READ                    // asynchronous read
      ////-----------------------------------------------------------------------
      //    always @(posedge clk)
      //    begin
      //      if (we)
      //        ram[waddr]<=din; // synchronous write the RAM
      //    end
      //
      //     always @(*) dout = ram[raddr];
      //   end
        1: begin : GEN_SYN_READ                     // synchronous read (rd, data valid next cyc)
        //-----------------------------------------------------------------------
            always @(posedge clk)
             begin
                    if (we)
                      ram[waddr]<=din; // synchronous write the RAM

                                                    /* synthesis translate_off */
                    if(driveX)
                            dout <= 'hx;
                    else                            /* synthesis translate_on */
                            dout <= ram[raddr];
             end
                                                    /*synthesis translate_off */
             always @(*)
             begin
                    driveX = 0;

                    if(raddr==waddr && we)
                            driveX  = 1;
                    else    driveX  = 0;

             end                                    /*synthesis translate_on */

           end
      //2: begin : GEN_FALSE_SYN_READ               // False synchronous read, buffer output
      ////-----------------------------------------------------------------------
      //   always @(*)
      //     begin
      //            ram_dout = ram[raddr];
      //                                            /*synthesis translate_off */
      //            if(raddr==waddr && we)
      //            ram_dout = 'hx;                 /*synthesis translate_on */
      //     end
      //     always @(posedge clk)
      //     begin
      //            if (we)
      //              ram[waddr]<=din; // synchronous write the RAM
      //
      //            dout <= ram_dout;
      //     end
      //   end
        3: begin : GEN_SYN_READ_BUF_OUTPUT          // synchronous read, buffer output (rd, data valid 2nd cycle after)
        //-----------------------------------------------------------------------
        // `ifdef SIM_MODE  - let Quartus figure out what to use.
           always @(posedge clk)
                begin
                      if (we)
                        ram[waddr]<=din; // synchronous write the RAM

                       ram_dout<= ram[raddr];
                       dout    <= ram_dout;
                                                       /*synthesis translate_off */
                       if(driveX)
                            dout    <= 'hx;
                       if(raddr==waddr && we)
                               driveX <= 1;
                       else    driveX <= 0;            /*synthesis translate_on */
                end
        //  `else   // PAR_MODE
        //      a10_ram_sdp_wysiwyg #(
        //          .BUS_SIZE_ADDR  (BUS_SIZE_ADDR),
        //          .BUS_SIZE_DATA  (BUS_SIZE_DATA),
        //          .RAM_BLOCK_TYPE (RAM_BLOCK_TYPE)
        //      )
        //      inst_a10_ram_sdp_wysiwyg
        //      (
        //          .clock     ( clk),
        //          .data      ( din),
        //          .rdaddress ( raddr),
        //          .wraddress ( waddr),
        //          .wren      ( we),
        //          .q         ( dout)
        //      );
        //
        //  `endif
           end
      endcase
    end  // tbf_ram
    endgenerate
`endif

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aIciUKhSvB0to+VFU3mqWzoDilzfxlaOSKKWOpX5Up5IO6lfv+YygJD4i+CA+8xOu/l8TICo6c7WDksnYjaSNIaP5cVeXhBPsZeUwIXCkoiMklQBri7iQ0qWpB+AE4EvviyDk52ca6dTEfBf97/Ueb15oeTDpOr9GeX6AEBUqMACg3/DDlwE0HP0sZ75j8WO7+4gfVYcUqebYXVY0RVe20E8Rh9R6Qtg1EwdYxQUe0p/5tOgc8QVRsIx3HfLYFcp4hVxX6LFYGnWRb75TLz2F56cYWCeQ88ZDb2A789YrIBW79ea0nUIMQob8rPBuQpzFYusRkNjFZA341pN6cBTyK6dXLHllJz/epJMjsdWK9a0JO+MUdXTcac7GYT3KPVAmFjcGOzsOmdsix+8E8P9stOghEQx2Dijf1fevobrYzy0bW5OEy+KW9Kd0+8nVLXt0ALUdaghrm+RieO/Mr0YeCAmle8D5aadqzYQCZWZqKsOVA6yjZas9xTGirhPhOVOKuFFlupTAjSBqRrbdnmZgev6LQvf2tFlHDyGzda7osGgxcsot3izqsWS45sx+YsGCaeALCSBm2ruKxgjdN+aBfTPkpREa13xELhVSyg44LzZVewsLT1ZBSCZWmS13K+MDAvpaE5Ff0wny/UJu5XNrai6g0R+TZXwIl0ejJiu8UQgcSrdFGa1D2hJsOBmFD5xix9GRzXo7zk4Z+ul/3VApqaJ5H+MDB3SAvrRB030gZEUOsaoaatuYzANM6TV/ZwWIu/vwDTZGKJ+ylJrHtQk8Os"
`endif