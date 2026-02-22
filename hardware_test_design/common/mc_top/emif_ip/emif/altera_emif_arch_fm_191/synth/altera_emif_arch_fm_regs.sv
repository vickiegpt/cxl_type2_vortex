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



///////////////////////////////////////////////////////////////////////////////
// This module handles the creation of a conditional register stage.
// This module may be used to implement a synchronizer (with properly selected
// REGISTER value)
///////////////////////////////////////////////////////////////////////////////

// The following ensures that the register stage isn't synthesized into
// RAM-based shift-regs (especially if customer logic implements another follow-on
// pipeline stage). RAM-based shift-regs can degrade timing for C2P/P2C transfers.
(* altera_attribute = "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *)

 module altera_emif_arch_fm_regs #(
   parameter REGISTER       = 0,
   parameter WIDTH          = 0
) (
   input  logic              clk,
   input  logic              reset_n,
   input  logic [WIDTH-1:0]  data_in,
   output logic [WIDTH-1:0]  data_out
) /* synthesis dont_merge */;
   timeunit 1ns;
   timeprecision 1ps;

   generate
      genvar stage;

      if (REGISTER == 0) begin : no_reg
         assign data_out = data_in;
      end else begin : regs
         logic [WIDTH-1:0] sr_out [(REGISTER > 0 ? REGISTER-1 : 0):0];

         assign data_out = sr_out[REGISTER-1];

         for (stage = 0; stage < REGISTER; stage = stage + 1)
         begin : stage_gen
            always_ff @(posedge clk or negedge reset_n) begin
               if (~reset_n) begin
                  sr_out[stage] <= '0;
               end else begin
                  sr_out[stage] <= (stage == 0) ? data_in : sr_out[stage-1];
               end
            end
         end
      end
   endgenerate
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqjU7AKxnSjq0aAnpKtPlWivcVkkYPPKFQTup50htj+ZZ4EujNSVMPQPrO1TBGkZaXtDq9zPc+wgdrczva4lsqlTjF40DT3JPa+6yd097FqVKDuVaTHGUm83P4PujS1FjfyUpMzBbGHHbSe1Vu4wXRnpqefh1WvmN/5p0vFkAG11Z3YNLpc+U1crji8UrPQf2Zy7Qyj/6EkuEZw2APBHeR92j+oAvRXH0e0NAwyl0PdPVcrjgfKqH2E9xPb2a2+aiuWRI6w0TFOe2QhO7a4+TdCmomzrtprC5FF/uMZNy7pwEpdv3+XDipAI4gZrWW+G+bfD+oAGBFuIbiE4VhJKEAoQTHVKrS2qfke9KQbTccjuaqLomg/oOgZwNlVn48Vpcc57VjbQvla/kqQidS9VQ8zyWC9/4zUPGeR9sAGFsOz20xLwaDRJezOlM4A6VBkrrlkRqGLnr0Khpaa1YfHY1+eC+dQV7GZf50ZUjBeHdHKtYGB3QCx7heTFc5he6v4xBD9D0Uz5bPyS7YZaam1uPOUVvgTxnVfukqiENOp994UMHBGjGtxRF41lOvqLaqUrfOnS8jouQ7yjPjCdKcAF27vG6ikL8rv4e9BsukZpD7rD9tXE8MizAvt9QfufKfLj/krLO8ouW88HGSLsXKhrTmbio9NZujzxg9jQB+gC3hVJCKg/CpmgXMa+lDT8e9mvzlyUY+uhE9IsZxU+SKYkpL4JpbVkbWp2Vt6BtRLr6Ovo9/MLCYf6qDyLFMgyswFdDnm48NiRLUlAvPRDeb0F8UDY"
`endif