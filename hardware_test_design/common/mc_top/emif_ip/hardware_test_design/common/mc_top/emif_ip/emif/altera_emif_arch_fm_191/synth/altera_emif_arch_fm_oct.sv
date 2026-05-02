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



module altera_emif_arch_fm_oct #(
   parameter PHY_CALIBRATED_OCT = 0
) (
   input  logic oct_rzqin, 
   output logic oct_termin 
);
   localparam OCT_USER_OCT = "A_OCT_USER_OCT_OFF";

   generate if (PHY_CALIBRATED_OCT == 1) begin
     tennm_termination term_inst (
       .req_recal (1'b0),
       .ack_recal (/*open*/),
       .rzqin     (oct_rzqin),
       .serdataout(oct_termin)
     );
   end
   endgenerate

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqh464lxByeCgqcY5hWNVyRYeqEshjg19t1vNkODjR7GzmJpBMJ3S/S2FcI7eHdV4OqRf7aJWOmyKdDA6dnDFUYglodw3ddkA2xs/L9h4Iu4GILhL8HBCPl5uYWFIlv1uaj3sml80u2LU7NKPsQEo5E88TDiuddIdKi5ngFPCUkJJWHmgMr4Be8JDWTB9K2S4SKZSa9AixeyxBAxn0RylbbpDQhf2CBsLs+clWscYr5v1l6g2IPEgExud7sc4pGw7KC7DlJ2PR0OVVWP1zkkm6+v08qX7C5SRLKiFhmNL7skGgAT6oy3tiWMmGxFIExp/RvX89t+FiobbZuF4a4ZHVBe4eJu62O7VC/jNKMuM3xA44izHCjYMHeRb3al4KdChW1uvmJwYrLjFJgpxAz+zPTQeLGnIiJVnCq1KGyQ/B9eddIbabz9pGh4DEMlp7S3zpHoX8VrPy3lv4yKW+WaRwE8EPi/MNzTF7iK9zCRDgYtkv4LWytsVcGYiehwd18a7ZTj68XclS8NTWlmRVw2jOjo8s96jwP9ghUhpNN+X9FJYTmdyvzlqujLyjTciffeFsTvYJHi+KfFi+96WxvK5IScQ9QI4lPAmjCD5xk6zSkQ3rt35FlaCVScgeJSdRZyDRYgwwydygk1aYk2XAoaicUL4XQX/PSjIrAwwz4fNLIeYr7kU5xpxEQp4OftJDg06FKi5C2L3Wc5TkreVzAnPTzX9P3k4o5LuK0Rm+kKZujBWulj4lwGhB65hwUvzt6UcdBftfB4kSfBiZWGQs3KPWBC"
`endif