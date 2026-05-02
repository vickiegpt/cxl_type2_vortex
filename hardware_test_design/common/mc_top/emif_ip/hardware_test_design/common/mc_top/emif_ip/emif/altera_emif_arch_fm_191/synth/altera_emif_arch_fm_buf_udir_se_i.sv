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


module altera_emif_arch_fm_buf_udir_se_i #(
   parameter OCT_CONTROL_WIDTH = 1,
   parameter CALIBRATED_OCT = 1
) (
   input  logic i,
   input  logic oct_termin,
   output logic o
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
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .ibar(),
            .dynamicterminationcontrol()
            );    
      end else 
      begin : no_oct
         tennm_io_ibuf ibuf(
            .i(i),
            .o(o),
            .seriesterminationcontrol(),
            .parallelterminationcontrol(),
            .ibar(),
            .dynamicterminationcontrol()
            );
      end
   endgenerate
endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqhx5ryrpzGEVDI6F4/+mJtSs3bBn4yTJPM8uXjqzlJUOTz6MgSG6dym5CLBrNZZR+oJlN7JIpfHv5+qulgsipGbEv6ych7MTXSOt5sJVsMO4RakOxVvPLpVj+ccaPVjlrde+edpWMGUfhIThd7bqZwWLPCAPJo/99Pdki/4kq7WhkPTukWz5qA959b1tSgi2MNzjL1ng4cleq8O/hGg+4GdmrAFjuYtDJhT/qd8uJoh8m9sUxWFYG8FiL6LOILHUnCbNl7y80/Ay7LyWSzd7WBYvdjOlKU+qwyX95DFBwuBenm+jRPVfWzHM8T7h/+dMoWxrrPTcHFdnjNK/ZxXe7S8wGP9JJqcqxhim/mD1fxOlZw4539N4g42/jJHRw+OCCJNijnMbiss6aZnGb+xPpYcURP+h831mbcsh4fGoczDHyOZGxjalSZMhBj41niI9zwKdZReeU0b9zq7SbfgeQoPgn8HOqtXAVeFh5YAgHXiYS4asYSUDy9mkL2ckCnBLQAyAzpIi9eRynunaBz8wQkomM0smrlJQLFKMUWfzj9fDvsA0YsRCI9bAVzwD+4TzsCG8fJ+19O4jAuUmjO6+9kxGF+R50EL401AY2/O1JaTg9D5ZhX4eLIR8ApgYzQYIJ0soeRxTyRtHfa5jy0eZC0DPG7TOFlmqdPYeAIcm6Fg0Lu6R/e39b0xpJ92HRsYpzyBEky9i6o6bDjsFVRh6O/SHH1zs3LSKEr7NwFFxfWZbcFIPoPYnnj5H9Mt88fC6amDqT1chMlGgGT3934E80Uj"
`endif