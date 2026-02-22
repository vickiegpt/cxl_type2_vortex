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


module altera_emif_arch_fm_buf_bdir_se #(
   parameter OCT_CONTROL_WIDTH = 1,
   parameter HPRX_CTLE_EN = "off",
   parameter HPRX_OFFSET_CAL = "false",
   parameter CALIBRATED_OCT = 1
) (
   inout  tri   io,
   output logic ibuf_o,
   input  logic obuf_i,
   input  logic obuf_oe,
   input  logic obuf_dtc,
   input  logic oct_termin
);
   timeunit 1ns;
   timeprecision 1ps;
   
   generate
      if (CALIBRATED_OCT) 
      begin : cal_oct
         tennm_io_ibuf # (
            .hprx_ctle_en (HPRX_CTLE_EN),
            .hprx_offset_cal (HPRX_OFFSET_CAL)
         ) ibuf (
            .i(io),
            .o(ibuf_o),
            .term_in(oct_termin),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .ibar()
            );
            
         tennm_io_obuf obuf (
            .i(obuf_i),
            .o(io),
            .oe(obuf_oe),
            .term_in(oct_termin),
            .dynamicterminationcontrol(obuf_dtc),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .obar(),
            .devoe()
            );
      end else 
      begin : no_oct
         tennm_io_ibuf # (
            .hprx_ctle_en (HPRX_CTLE_EN),
            .hprx_offset_cal (HPRX_OFFSET_CAL)
         ) ibuf (
            .i(io),
            .o(ibuf_o),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol(),
            .ibar()
         );
            
         tennm_io_obuf obuf (
            .i(obuf_i),
            .o(io),
            .oe(obuf_oe),
            .dynamicterminationcontrol(),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .obar(),
            .devoe()
            );      
      end
   endgenerate            
endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqj9NSS6JMBSj4mtmNHhdBuwKunfwfjPH1k1M2HseQz/t4mLqfXgZqXy9DjZx5OKmyfsmbDdIKMrkdAIMnHhGhZz1Jivgf4vg2QV6nF1+b894oaQThvAfXe8+hJvaGnjqKvZibA+UWtRdjdL5Mztds4JcvbTW/W37sc/wiARhmeE71W9j629p04fMBMDJlpzKcswloxwRRDHl1B6+lOFQjSEOcHJOkDHZC14e2KU6UPAWmxHh9f3ce6Rjr+daN9Y0ChIDxaQOXBTuHWVsHsrO6psbyEN30wKM+gU5zMWS0PjYwLGyktA5zSGlyWlLLDPAij0vfvieJw4fKYQvabONx2mU1rqwMEpZaLJ3Nn+PUY80S6wzcQwvAl153UXy4XaZJuKjPRF6HYGhW/mN1JIllHFvwF2/2RnlYUoeyIkYYiVX2NwO6nQqHlgzhmWN83UNsu+sClitYtwrovHD4D47+54xsophKjOP7b/Dfv1QpEzKu2QkCy26FT7noB+ddejp2eE7sNaD6/IBfAkwpOPNJL8QZyV3hLnCjfRsw0+D+IcKr7+tZcBM0xon2EKq5EyFEbb9zOSrUsB7owicMP/WEB4TptQDxDbWN1zTwjUG6qnj4GxZ3AOzg0z9xBVN8IjccM1R/NWnz4Xr3mUp7+FWMlWCEX4d/g4TmixYgfjDM6vgxJqxEZkhW2j7/DlunfL2odXbwKxyU+qL4NOquWhOUaFrMFayUZBW8VvCqn15N51q7NBqYF+e/SpS0yJDW7Yp+SXI4Ul1d7hNQrvmVZvls/R"
`endif