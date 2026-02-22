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


module altera_emif_arch_fm_buf_udir_se_o #(
   parameter OCT_CONTROL_WIDTH = 1,
   parameter CALIBRATED_OCT = 1
) (
   input  logic i,
   output logic o,
   input  logic oe,
   input  logic oct_termin
);
   timeunit 1ns;
   timeprecision 1ps;

   generate
      if (CALIBRATED_OCT) 
      begin : cal_oct
         tennm_io_obuf obuf (
            .i(i),
            .o(o),
            .term_in(oct_termin),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .obar(),
            .oe(oe),
            .dynamicterminationcontrol(),
            .devoe()
            );    
      end else 
      begin : no_oct
         tennm_io_obuf obuf (
            .i(i),
            .o(o),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .obar(),
            .oe(oe),
            .dynamicterminationcontrol(),
            .devoe()
            );    
      end
   endgenerate
endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqjygksovWmHCaOQPrY7H88Bt3cXXNRoIe8goYL5eH4SjpsaW6TIJi39P1LnhEGChAVOYM6oG7U5hHNY1nMy9TKszPYsRM86ocChxoah7cjBCn9TblYYJGNtgVL+Bv1SaegNpX9Fo8GeowhlejH2vdRIaIxVFwwdK0v7VDc3hrpJqew3rUbfkFU1wR9khuCWLMidl3u4W+s2QsUAsk012uEdhpgzrYqgboCOttA6+dsRMGheiT9UAPn7CcrW93lF6/q2O/IM/Q+w4Q6X59HPnlhRuFhosbh++3V7Sz/ecW6Tv0Nv1bxzXSjvmOxfu7zWJSlE9k2Izy2mtcYkutDefhEK6bUhCOuHXwFAkRlCyw9pRtDWeMfN76dFvemse8GLG5ilVxI0SV5ikz3/UnbQPpiXxsoOc5MCFw0luyStNRXso0ZKcgN1yiwpU2J9T109NjgLEa9GQMFAK6ufALFtSL2rEs+cn1FPqRQ19pXKYypX2tsQED33WUx3wJgKQzosjP4HGVdgRG8otXGJiWJYYneAH9o6lMZFVh/9LC6zH/16lDfHp2V6/+r0DT93Yq3CDc7EEwMnwAjeYOeDet3+ZPy4WDYcHTXPR/g1D19T2LPuNLG9lmGXipEGGAIFzOIlbD8vILEmxHKvAocPjH+dqxvQQcKyy1zEY+9oxKG98Me4P2kxN/juB9Wi3cswrFLqJ48S0LDi5mqZR19GWmXWN5BwCsV+NcAHivrN3dCpNhHDo7A4EJkY1lpbwiDpgboDUpmBl0NX0Bk+GYnXWANKjFV1"
`endif