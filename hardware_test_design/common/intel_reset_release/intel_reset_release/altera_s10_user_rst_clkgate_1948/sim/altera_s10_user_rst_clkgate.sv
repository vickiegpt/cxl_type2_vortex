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


`timescale 1 ns / 1 ns
module altera_s10_user_rst_clkgate (
	output logic ninit_done
);

	localparam USER_RESET_DELAY = 0;
	
	initial begin
		#0 ninit_done = 1;
		#1 ninit_done = 0;
	end
					
	
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "/aLchxHVwkZfPxnMHo5eDsORRShAk5VGMvYpW3tmafdYxu7uVXq/xch3zUSJ8cYn3TX0Uwo0jBVcB9VGd1qJq6m2O1+3Np3g+sbXtM5vIr+yYFmgIVatqIFHqx6AQNxQgoVRyrbac9JCkLwrg6M0uH/ZASaiAVpNzPaMh5/Zg1v90CHwDvc2JL/FZNSTWESE37gnwdSUnmGhApTBcEC+iVKu9LeevfONucpOUlQyjyaetl3I2Vmm27XZqVqa2szmguj608jhACoCgW3oo/C863ue3hURe8bUgSCSnSttZT4YaxFNPAAADn5cS5bSHekNbhXJ0Rq+lrmiXadR/HwKjsX7njVaxcKN7UdcF7+D0ZMm0kv/mXJMSCe8GS9SIoRgY9ePd2xvkoOuUbTlqG1IymYgjDk8o39iKA8YsT4EzwmtFtB2aZOlSJaREWdKk6PRg+cvc/zQFKQJAXBUkka4w11dPny41SN8p2UKMg11iYp705pK2QEqp0asXsZqZylkWdBCveHqnAhZWrrEe2kG19PnlCaNLDOy64XNh1sCKDDBlC/eMJP19X/oOQjkzhRxGFeOgnCzdR6xklOFluBxATctKY5InUmgr2SwoRIAySldEvZ2t6GEdf1kmIBzgmIe/Nk+Aa0tP5l3ScZK93JiTBTaUevvlhkgT97M4VUOc3TEuwR+p+btABLqCrgO0ivXbGHbMog9QLhqLKDT61aETKTezboShRL5XxUH5XMIwNxF9+ktABp75dD646l3uDXW0Q04Kjwnqnchh6c2W0cAUPFDcp1EwbEhaJssUoGTg28lEv+2JufER2mRKWB2Rn94oenTi9XdhdROScUs7mZo0pB+ulCUxIy6t6PGiFcGhD9DhK9sD4PeB/ZoD6InGzGDdw1pwSZzKeVdF9rnIgQ0enfTI4NOxJ545Q6Lc/VhZMG5T7ncXUp+96U/NEXrbqqqPuErK7+5pCMs0dTOHRQEaxqfAMYKMM+HoL0qMlGnomZdKEPgHQp7Yig5wtMgiQaN"
`endif