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


//------------------------------------------------------------
// Copyright 2023 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//------------------------------------------------------------
module intel_cxl_afu_pio_mux (
	
    input				    clk,
    input				    rstn,
    input   logic  [0:0]    afu_pio_select,         //afu_pio_select==1  ?  select  afu  else  pio
    input   logic  [0:0]    pio_tx_st_eop,                                                     
    input   logic  [127:0]  pio_tx_st_header,                                                  
    input   logic  [255:0]  pio_tx_st_payload,                                                 
    input   logic  [0:0]    pio_tx_st_sop,                                                     
    input   logic  [0:0]    pio_tx_st_hvalid,                                                  
    input   logic  [0:0]    pio_tx_st_dvalid,                                                  
    input   logic  [0:0]    afu_tx_st_eop,                                                     
    input   logic  [127:0]  afu_tx_st_header,                                                  
    input   logic  [512:0]  afu_tx_st_payload,                                                 
    input   logic  [0:0]    afu_tx_st_sop,                                                     
    input   logic  [0:0]    afu_tx_st_hvalid,                                                  
    input   logic  [0:0]    afu_tx_st_dvalid,                                                  
    output  logic  [0:0]    avst_tx_st0_eop_o,                                                 
    output  logic  [127:0]  avst_tx_st0_header_o,                                              
    output  logic  [255:0]  avst_tx_st0_payload_o,                                             
    output  logic  [0:0]    avst_tx_st0_sop_o,                                                 
    output  logic  [0:0]    avst_tx_st0_hvalid_o,                                              
    output  logic  [0:0]    avst_tx_st0_dvalid_o,                                              
    output  logic  [0:0]    avst_tx_st0_ready_i,                                               
    output  logic  [0:0]    avst_tx_st1_eop_o,                                                 
    output  logic  [127:0]  avst_tx_st1_header_o,                                              
    output  logic  [255:0]  avst_tx_st1_payload_o,                                             
    output  logic  [0:0]    avst_tx_st1_sop_o,                                                 
    output  logic  [0:0]    avst_tx_st1_hvalid_o,                                              
    output  logic  [0:0]    avst_tx_st1_dvalid_o                                               
);


always_ff@(posedge clk) begin

	if(afu_pio_select) begin
		avst_tx_st0_eop_o   	<= 1'b0;
		avst_tx_st0_header_o	<= afu_tx_st_header;
		avst_tx_st0_payload_o	<= afu_tx_st_payload[255:0];
		avst_tx_st0_sop_o   	<= afu_tx_st_sop;
		avst_tx_st0_hvalid_o	<= afu_tx_st_hvalid;
		avst_tx_st0_dvalid_o	<= afu_tx_st_dvalid; 
		avst_tx_st1_eop_o   	<= afu_tx_st_eop; 
		avst_tx_st1_header_o	<= 128'h0; 
		avst_tx_st1_payload_o	<= afu_tx_st_payload[511:256]; 
		avst_tx_st1_sop_o   	<= 1'h0; 
		avst_tx_st1_hvalid_o	<= 1'h0; 
		avst_tx_st1_dvalid_o	<= afu_tx_st_dvalid; 
	end
	else begin
		avst_tx_st0_eop_o   	<= pio_tx_st_eop;
		avst_tx_st0_header_o	<= pio_tx_st_header;
		avst_tx_st0_payload_o	<= pio_tx_st_payload;
		avst_tx_st0_sop_o   	<= pio_tx_st_sop;
		avst_tx_st0_hvalid_o	<= pio_tx_st_hvalid;
		avst_tx_st0_dvalid_o	<= pio_tx_st_dvalid; 
		avst_tx_st1_eop_o   	<= 1'h0; 
		avst_tx_st1_header_o	<= 128'h0; 
		avst_tx_st1_payload_o	<= 256'h0; 
		avst_tx_st1_sop_o   	<= 1'h0; 
		avst_tx_st1_hvalid_o	<= 1'h0; 
		avst_tx_st1_dvalid_o	<= 1'h0; 
	end
end //always


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzpUGf1BL1z8xlskOHt0eEg4MmDj19MqJlwnsnI5r5Sk3CSecHJILccgf0YxUalt6j2jrOqSiUr25LTAr4yXWwirR280STyzUQrCEjAY1jjCWR5IUKDe75XkLnZsizSM5xwujVlHOA4XGvVsYSahi0IW6BPJYt9ESRV5/V5Ef2O2zDmgbqfBg1woX5ZUabLW2vgTpvyYme+u2OMRxoysedSOUYpJLUY2McxeiJXEC5tR7P3g+33/5RAUFTKcw6xN6e3COIrx8vNVgydQ2uRxoBSTXxeJBF1ZIFiXXm3xbMrlTVar6a6Zbz720450q7uAgwx+AIk6lvfGgvKlo2RNNGyeqD8VLeNxh4x3ZU9W2HJdYAeQi+xYzdYH5kJEkGOBVBWVn8CIPJadWuyPERbEDQMg2MO0jtAmiMvXsT2+JBXQCBgDmefboFSm4ntiuD2+QoHsql1itjyRJ5lN95sFJO/vqdV1hOY8Zjc3FVh9r4GzsXKUiHCLEpPIMJGZde+mGIGKe2uodvU06tu7PxXGuQ2IiC0v6+pmbwZcWNZQFIt0HBWeqGAZUn21x9d1y1ticUCkTtFYG7bkCdrFV40K/qwKKu6AztCquAhUwDFfHxuMG/8959QFEoTHjuqcv9acaWbXb/es/TrY9cNKOpY4N2xoHDgANlo3vxLlZLt9Lo6G+JEvwifYB25djoaI4iyjcDEUmH5Shck8tSrdfaQgOGt+CjHvsohYx72hAoGALcIlZi0XKByE7VjH9U9G7S3Ds00AnxBiHEDdZwXT3kbt9ro7"
`endif