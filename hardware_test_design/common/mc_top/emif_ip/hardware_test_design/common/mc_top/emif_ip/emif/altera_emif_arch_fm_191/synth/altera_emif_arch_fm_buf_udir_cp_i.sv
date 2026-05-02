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


module altera_emif_arch_fm_buf_udir_cp_i # (
   parameter OCT_CONTROL_WIDTH = 1,
   parameter CALIBRATED_OCT = 1
) (
   input  logic i,
   input  logic ibar,
   output logic o,
   output logic obar,
   input  logic oct_termin
);
   timeunit 1ns;
   timeprecision 1ps;
   
   generate
      if (CALIBRATED_OCT) 
      begin : cal_oct      
         tennm_io_ibuf ibuf(
            .i(i),
            .o(o),
            .term_in(oct_termin),
            .ibar(),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );
            
         tennm_io_ibuf ibuf_bar(
            .i(ibar),
            .o(obar),
            .term_in(oct_termin),
            .ibar(),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );
      end else 
      begin : no_oct
         tennm_io_ibuf ibuf(
            .i(i),
            .o(o),
            .ibar(),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );
            
         tennm_io_ibuf ibuf_bar(
            .i(ibar),
            .o(obar),
            .ibar(),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .dynamicterminationcontrol()
            );      
      end
   endgenerate
endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqiJjx6NcwW2g3AdiJVTIl6RrWaA7wLshHcYDlHvK5yeKaUcmq5cMoY5ktbM29ejMV1X4/ozX+1jHVcHduqRUNN+B5KTODzJzx/+S2Zp/eRn3bNPGzcOpXGkpMA1uBjhlAbCOxlwW1PmAes77py3Uazos0gCL5WATBiMGzYcB/iURjb40szhpS1PDDi7lYXWCepgpiiUV++Jd9gN3TIp5d6Jq5DnJZl8q0rHI+J6KVOT/LnGd+GIl0GfRHrdkwZ/2WKSEqEkObGun00QmNsOd08BlZZoRv2pGxdtsHManx+osmG5r4UjcYZgdOTVOHm/7pgbObc1jSPOr1KrvomiXPBh8t15Fg7rTpZaE/rn45K6aoRTQmka+1eWmfzl8ujCwrIv8YtByQ3g+OAVLp6Kj8rdimAXAndKHSmHP4A1Qt5u7qI4JX89pRuPTt7ExcUQjDkEdgVvr/ekIVRtSyVz2vwI8cyjUFlb1x0GbXJRqhDT7xEBRJKHCbnNCWrnPRA/dsnkcXK3EEo8StpizAxNtM8hbbeo1CRskt29jajYqlpIZuHF5IjY3Si56uAAyPL1ec/lBM5qJgchkfgpgye3wD8MdGAO4qxaYWta6+iaDeBoDu6MRX/LMlqek1Aze8bAcKCbQkz7vUSBOra/FUaQhqSIHnzy0m1eqlAkkNbhQq+3fOoEQ7RcvQw5a+AQQWg9BaIW2v7XY+n8VtZIll+VrvyP4mYUfH1Sseu2wtsPnybqszmMPh32+84cknkuIgXFo+OulRgLdR0e1pTBRSjGLFWz"
`endif