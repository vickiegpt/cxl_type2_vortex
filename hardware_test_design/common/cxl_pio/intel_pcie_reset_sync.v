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


// (C) 2001-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporat's design                tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any output
// files any of the foregoing (including device programming or simulation
// files), and any associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License Subscription
// Agreement, Altera MegaCore Function License Agreement, or other applicable
// license agreement, including, without limitation, that your use is for the
// sole purpose of programming logic devices manufactured by Altera and sold by
// Altera or its authorized distributors.  Please refer to the applicable
// agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

//`default_nettype none

module intel_pcie_reset_sync #(
  parameter                  WIDTH_RST              = 1
) (
  input                      clk,
  input                      rst_n,
  output [WIDTH_RST-1:0]     srst_n
);

  wire                       sync_rst_n;

  reg   [WIDTH_RST-1:0]      sync_rst_n_r /* synthesis dont_merge */;
  reg   [WIDTH_RST-1:0]      sync_rst_n_rr /* synthesis dont_merge */;

  assign srst_n              = sync_rst_n_rr;

  intel_std_synchronizer_nocut sync (.clk (clk), .reset_n (rst_n), .din (1'b1), .dout (sync_rst_n) );

  always @(posedge clk) begin
    sync_rst_n_r             <= {(WIDTH_RST){sync_rst_n}};
    sync_rst_n_rr            <= {(WIDTH_RST){sync_rst_n_r}};
  end 


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL5fQFHvFHwcpEafWUkLakmgcOJ7fvZJkJ5kNX/Ni8gqiV8AuAtxBDla3Ul49a8PiMim5lT8AGAK7Cp1HPn8kKtYRdqihmmaW5CEVIlMUKwe6IBfFiyO/UcCr2ZHxZLy7WEdEIcdnYzrrz5BW5f4hqtj9PN/gYNh4DVi/4hWgLEIOxibrAmoMzS8DI1l3BUf7FdMMQzbHc75XbybG980JFlLLLYfZTVcATIayazRoILP2oKigDC53qkebyTxIsobQ5XHj0UaJ2o7UEEXhHOmVUWMoS0lkHh8nXye06hVawsPcvOTEWFT1QfK4teyfTfyrAoQL2sUIXgN2gNeubAj+KRRf1/jsYJBJlrBPXGHcMBsil+ba7yVSORmBLJ1mXzHMtqJljd8fNMvmlOWCXJsF7Hw9j01uRoEC3vgMuSuKIGqHqpD1o1dfDn2svF9t3vDzUPdBUBksRxIhjLIMl2l+ZI2Cue4MKuCtjJgmN29gfb1AOxz6NbXeCt40FI2Nh9L95OLWn2Fc79o2dkAk8uDYnG9HodjDlR0TXYx2kfjXgn33d1PkUOsWnzooS+hCtBhzsNtsXaXaiR0wCIostS/wKHtVt9cFYPCn9O1afnJhghL1GpRUON7TFjf9/bFW7VrlIRiw9g2/kM6vPm6+8nZh40jS3NywOsc92FvSMDGsyc8JS2eDoQPI0ONL/N+/P1fHgjUM1im7fsc6GyPaDMCIcsyyRzck3cPaH+lfiekPSOBMxlI0vleBq0BiXM7N58a0tm/pE1te8HVEH8WUgh35IvU"
`endif