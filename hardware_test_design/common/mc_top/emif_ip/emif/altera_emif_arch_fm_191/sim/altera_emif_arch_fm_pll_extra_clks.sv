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



////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Expose extra core clocks from IOPLL
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////
module altera_emif_arch_fm_pll_extra_clks #(
   parameter PLL_NUM_OF_EXTRA_CLKS = 0,
   parameter DIAG_SIM_REGTEST_MODE = 0
) (
   input  logic                                               pll_locked,            
   input  logic [8:0]                                         pll_c_counters,        
   output logic                                               pll_extra_clk_0,       
   output logic                                               pll_extra_clk_1,
   output logic                                               pll_extra_clk_2,
   output logic                                               pll_extra_clk_3,
   output logic                                               pll_extra_clk_diag_ok
);
   timeunit 1ns;
   timeprecision 1ps;
   
   logic [3:0] pll_extra_clks;
   
   // Extra core clocks to user logic.
   // These clocks are unrelated to EMIF core clock domains. The feature is intended as a
   // way to reuse EMIF PLL to generate core clocks for designs in which physical PLLs are scarce.
   assign pll_extra_clks   = pll_c_counters[8:5];
   assign pll_extra_clk_0  = pll_extra_clks[0];
   assign pll_extra_clk_1  = pll_extra_clks[1];
   assign pll_extra_clk_2  = pll_extra_clks[2];
   assign pll_extra_clk_3  = pll_extra_clks[3];
   
   // In internal test mode, generate additional counters clocked by the extra clocks
   generate
      genvar i;
      
      if (DIAG_SIM_REGTEST_MODE && PLL_NUM_OF_EXTRA_CLKS > 0) begin: test_mode
         logic [PLL_NUM_OF_EXTRA_CLKS-1:0] pll_extra_clk_diag_done;
      
         for (i = 0; i < PLL_NUM_OF_EXTRA_CLKS; ++i)
         begin : extra_clk
            logic [9:0] counter;

            always_ff @(posedge pll_extra_clks[i] or negedge pll_locked) begin
               if (~pll_locked) begin	
                  counter <= '0;
                  pll_extra_clk_diag_done[i] <= 1'b0;
               end else begin
                  if (~counter[9]) begin
                     counter <= counter + 1'b1;
                  end
                  pll_extra_clk_diag_done[i] <= counter[9];
               end
            end         
         end
         
         assign pll_extra_clk_diag_ok = &pll_extra_clk_diag_done;
         
      end else begin : normal_mode
         assign pll_extra_clk_diag_ok = 1'b1;
      end
   endgenerate
   
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqgYVnD3OHwQ6Ye1B4P+AIS9JO8HW8QpQpeS/sWhOdDkdJODVd+J3Y/J4r77cvdzu34gomlbnr+k4zIXwEuOEQRt6FCjLfkN81yvkPr+Q0eCU8Ra8+0PAXfoUaIlW8kCygLjRaP809ftQzVl+KXyZaEjrb0xfloF2PpB2fuLokJjeTVXfNrl6kPUwAeMnTMCh2hBz9W8ousgv54e5vwgAUszqmFCZjukBz/zmW2wfnJNRb608S+fHHrNaJwpHZ2+9cxCRdo9jpPnP/mrpM9RzWE5u5HaRU88opBuG/hB+qmZZO6wPnZp0RNpXNe0uLj7W2N3gr2zLt1+mmwlMznm0PqTka5fNbll7po5cYJ1n6k+klWbmAoJOkakjOcXz3SGAk7+FcG1GftTsJ2oneXTgGIy71emu1D6Z2Gs4DLCCoE4UWAwLr/U32hsLOoDLuZHHXF2J45pQgEN6vzKGzfIC8JtfO41EV8YjP4x3MJD57B4fRMTjjXpuQnEjTmCsErzRPBFZww1s3rSX1W/2xKJt5cjQI5IFP9v2YNmPSV9NHTo8mwHfip08hZD/AbTJ5Js+eJUZ9JUCiGnvPpV9VLA0ssOxkKLLfn8HRxOZjQw+vIfafiwS8GGPEIKtZnx+AE1qf8RFb1yRtghb0mvzzJX/QDowZetlKWk3t2FYO8AmXwhI39I1G2udawrq1j2IUB5qV4973tJjPy8epM9F+0Jua2OKQOiYAJltK5a9C2tAa1YMv5c4YQbdXXG3ExWJyBmeTs6vmI1EpYpmanFfKLLMVTs"
`endif