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


module altera_emif_arch_fm_buf_udir_df_i # (
   parameter OCT_CONTROL_WIDTH = 1,
   parameter CALIBRATED_OCT = 1
) (
   input  logic i,
   input  logic ibar,
   output logic o,
   input  logic oct_termin
);
   timeunit 1ns;
   timeprecision 1ps;
   
   generate
      if (CALIBRATED_OCT) 
      begin : cal_oct   
         tennm_io_ibuf  # (
            .differential_mode ("true")
         ) ibuf (
            .i(i),
            .ibar(ibar),
            .o(o),
            .term_in(oct_termin),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );
      end else 
      begin : no_oct
         tennm_io_ibuf  # (
            .differential_mode ("true")
         ) ibuf (
            .i(i),
            .ibar(ibar),
            .o(o),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );      
      end
   endgenerate      
endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqgNlkpvnUEhN5d78wBUwf3+7UtkoNDIM7+hsNS6LxrsN6ByCvE8up/cEZyvhBhP2vI8gPCh3UFJ2/ByU86ZxbGdQiyuySaDH7QoiIVxnCfPHG8ZmO12pmy2+7u5jTgvqFBMhAW75KgH6RsT4JXRvPxEbU6KqsMXrwSaGppVvwkmhNXQ6pJ6hboMVfOHIiVc0VdWc5YnuFEl3EXLSxDlL53QSvoMGqC/GLMqVpHE9OdLKfjOaVYHpI1scUPc7bShK8ieS86guTjVtQv/pLdbtkHhzP4Db2XIWHrBMAjAQ+bR1+NYQrSMjkG3RZC7TLpm+PWvRvaB925jyr+lX2gIdV4VvUzAnl5vGvRgRDRVPiWr7uScNbmQasZAiLVorlWMN9pVRfvje57r2aZKuDSU6m838qeQzGlBAQadJpd7a9SbnWNiOvdjFGOJD855pb12UludRcbN/p3T2BUnTUGu0ltYnANxYAWVQuuGS70md66ejz5XyHgjl7whyjswpObsqE5GezUhXoOH2PTZjMErkATBHBM9iaHPKywRNSf7nr4VthWV6icE4fQQlQFWIoonx+u4+svFiKwGLlFaaIqDY3Ibb+FALi1tceBipIkEN1xJ4ekfhBvblIg21bj+SE1KnpfmXjqMHETFnBzDuSL6as0Uc5UkgrCayQRXgUuuiC+upclMDaVNVO200OhU+J8QfeSjdCYhqwy9Q9NeRgQNM0i7ktXcPJtWAPNaSf9TNYUXSRPaFWrLsuF8+7tipIGHNNuT2ADG37i7xY6nyZOaZXp9"
`endif