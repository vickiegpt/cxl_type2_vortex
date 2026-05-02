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


module altera_emif_arch_fm_buf_udir_df_o #(
   parameter OCT_CONTROL_WIDTH = 1,
   parameter CALIBRATED_OCT = 1
) (
   input  logic i,
   input  logic ibar,
   output logic o,
   output logic obar,
   input  logic oein,
   input  logic oeinb,
   input  logic oct_termin
);
   timeunit 1ns;
   timeprecision 1ps;

   localparam DCCEN = "true";

   logic pdiff_out_o;
   logic pdiff_out_obar;

   logic pdiff_out_oe;
   logic pdiff_out_oebar;

   tennm_pseudo_diff_out # (
      .feedthrough("true")
   ) pdiff_out (
      .i(i),
      .ibar(ibar),
      .o(pdiff_out_o),
      .obar(pdiff_out_obar),
      .oein(oein),
      .oebin(oeinb),
      .oeout(pdiff_out_oe),
      .oebout(pdiff_out_oebar),
      .dtcin(),
      .dtcbarin(),
      .dtc(),
      .dtcbar()
   );

   generate
      if (CALIBRATED_OCT)
      begin : cal_oct
         tennm_io_obuf # (
            .dccen(DCCEN)
         ) obuf (
            .i(pdiff_out_o),
            .o(o),
            .oe(pdiff_out_oe),
            .term_in(oct_termin),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .obar(),
            .devoe()
         );

         tennm_io_obuf # (
            .dccen(DCCEN)
         ) obuf_bar (
            .i(pdiff_out_obar),
            .o(obar),
            .oe(pdiff_out_oebar),
            .term_in(oct_termin),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .obar(),
            .devoe()
         );
      end else
      begin : no_oct
         tennm_io_obuf # (
            .dccen(DCCEN)
         ) obuf (
            .i(pdiff_out_o),
            .o(o),
            .oe(pdiff_out_oe),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .obar(),
            .devoe()
         );

         tennm_io_obuf # (
            .dccen(DCCEN)
         ) obuf_bar (
            .i(pdiff_out_obar),
            .o(obar),
            .oe(pdiff_out_oebar),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .obar(),
            .devoe()
         );
      end
   endgenerate

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqixQDyCdkaANhDSA7jIhlTAXN21UBiOlS/i8VO1bbWfajVEzjNqPDrTCnPK0YwmrBb7CGnRHVfWX13KeDtjEt+JRK300ieVpd3wv8Le4YeljzT4Ismq/9jOHO5HVKOTckVnniXt2mCBHqj5ApHK6ic6hV3be0Zn8ER6hzFd8RLAf0Ms1AmZfXrat0NJNBpdfbNUCluPkH1ivNTSW8Ns/yFkL/iklcuprOIPf8ZiuouOS7Y4njM1ZY9JGXek9lhR7C5GngUbhgvDW1bswf6mig0H51dPV0QVgazZzxO0CMldb9LmppxX+KRzqNqNK4cKIhQKetSMjoxZFG/6fNNobefsvmAkE4mmPGtmdB2pWJB87tBbPleFXXdh9BsD89shiaYAa9u6jZpozc0wIXroSaVZCUFgKloR1yx/lFVFlcGuwlC1uXEqsp7hATtwf6j7Gkir8vMnMD/gBiEZi6rk3c7Qy33/HuxTLD3s/cdWz9rVkgFRc3hQqcz7qF/ZJnhp9bX4sAQsgk+jhAl1a0U5Ny9+QH5oG5YoIcT1pASiOAr+K1n9cRmmqIjShoJ14Dbe04MqR2T+6Xrr7j1HvXf2kwpCMNVtFk4awlGrI4jiI8Mcdt4Ua6/j0c1oaskH49GP4/lIHH0xTzbFNyZfRYnNK82xSezWEbQggUKY7JpiIw68xjhzX8UnnyYtAGBcs8nS1A06JLXkmYFuvqlgezRAXRCazuidbj84wTwmdH+79xiAVqa+MA82PP6LKvDiwKnodV29wTHypXlPPVtoGj8Ozy+t"
`endif