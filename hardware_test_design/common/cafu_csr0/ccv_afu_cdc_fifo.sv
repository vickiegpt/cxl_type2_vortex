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
///////////////////////////////////////////////////////////////////////

import cafu_common_pkg::*;

module ccv_afu_cdc_fifo (
    input 	rst				, 
    input 	clk				,
    input 	sbr_clk_i				,
    input 	sbr_rstb_i				,
    input 	treg_np					,
    input 	cafu_common_pkg::cafu_cfg_req_64bit_t 	treg_req	, //from EP
    input 	cafu_common_pkg::cafu_cfg_ack_64bit_t 	treg_ack	, //from CFG
    output 	cafu_common_pkg::cafu_cfg_req_64bit_t 	treg_req_fifo 	,
    output 	cafu_common_pkg::cafu_cfg_ack_64bit_t 	treg_ack_fifo 
    );

  logic 		valid_reg 		;
  logic 		treg_np_reg 		;
  logic 		fifo_SH_wr_en		;
  logic [143:0] 	fifo_SH_in 		;
  logic [143:0] 	fifo_SH_out 		;
  logic 		empty_fifo_SH 		;
  cafu_common_pkg::cafu_cfg_req_64bit_t 	treg_req_pipe [2:0] 	;
  cafu_common_pkg::cafu_cfg_ack_64bit_t 	treg_ack_pipe [2:0]		;
  logic 		fifo_HS_wr_en		;
  logic 		empty_fifo_HS 		;
  logic [68:0] 		fifo_HS_in		;
  logic [68:0] 		fifo_HS_out		;
  
always@(posedge sbr_clk_i)
begin
    if(~sbr_rstb_i) begin 
        valid_reg <= 1'b0 ;
        treg_np_reg <= 1'b0 ;
    end 
    else begin  
        valid_reg <= treg_req.valid ; 
        treg_np_reg <= treg_np ;
    end
end
  
  assign fifo_SH_wr_en = (treg_req.valid  & ~valid_reg) || (treg_req.valid & (treg_np ^ treg_np_reg));
  
   assign fifo_SH_in = {treg_req.valid, treg_req.opcode , treg_req.addr, treg_req.be, treg_req.data , treg_req.sai, treg_req.fid,treg_req.bar} ;
   //assign treg_req_pipe[0] =  ~empty_fifo_SH ? fifo_SH_out : '0  ;
   assign {treg_req_fifo.valid, treg_req_fifo.opcode , treg_req_fifo.addr, treg_req_fifo.be, treg_req_fifo.data , treg_req_fifo.sai, treg_req_fifo.fid,treg_req_fifo.bar}  =  treg_req_pipe[2] ;
  
   
always@(posedge clk)
begin
    if(rst)
    begin 
        treg_req_pipe[0] <= '0 ;
        treg_req_pipe[1] <= '0 ;
        treg_req_pipe[2] <= '0 ;
    end
    else begin 
        treg_req_pipe[0] <=  ~empty_fifo_SH ? fifo_SH_out : '0  ;
        treg_req_pipe[1] <= treg_req_pipe[0] ;
        treg_req_pipe[2] <= treg_req_pipe[1] ;
    end
end
		    
  //ccv_afu_cdc_fifo_vcd #(
  //      .SYNC                   (0),   
  //                                     
  //      .IN_DATAWIDTH           (144), 
  //      .OUT_DATAWIDTH          (144), 
  //      .ADDRWIDTH              (3),  
  //      .FULL_DURING_RST        (0),   
  //      .FWFT_ENABLE            (1),   
  //      .FREQ_IMPROVE           (0),   
  //                                     
  //      .USE_ASYNC_RST          (1))    
  //iosf_to_cfg_fifo_vcd (
  //      .rst                    (~sbr_rstb_i),                    
  //      .wr_clock               (sbr_clk_i),              
  //      .rd_clock               (clk), 
  //      .wr_en                  (fifo_SH_wr_en),  
  //      .rd_en                  (~empty_fifo_SH), 
  //      .din                    (fifo_SH_in), 
  //      .prog_full_offset       (3'd0), 
  //      .prog_empty_offset      (3'd0), 
  //      .full                   (fifo_full1), 
  //      .empty                  (empty_fifo_SH),
  //      .dout                   (fifo_SH_out), 
  //      .prog_full              (), 
  //      .prog_empty             (), 
  //      .underflow              (), 
  //      .overflow               (),  
  //      .word_cnt_rd_side       (), 
  //      .word_cnt_wr_side       ());  
	
	iosf_to_cfg_fifo_vcd_ED     iosf_to_cfg_fifo (
		.data    (fifo_SH_in),    //   input,  width = 144,  fifo_input.datain
		.wrreq   (fifo_SH_wr_en),   //   input,    width = 1,            .wrreq
		.rdreq   (~empty_fifo_SH),   //   input,    width = 1,            .rdreq
		.wrclk   (sbr_clk_i),   //   input,    width = 1,            .wrclk
		.rdclk   (clk),   //   input,    width = 1,            .rdclk
		.aclr    (~sbr_rstb_i),    //   input,    width = 1,            .aclr
		.q       (fifo_SH_out),       //  output,  width = 144, fifo_output.dataout
		.rdempty (empty_fifo_SH), //  output,    width = 1,            .rdempty
		.wrfull  (fifo_full1)   //  output,    width = 1,            .wrfull
	);		
	
 
  always@(posedge clk) begin
    if(rst) begin
	  treg_ack_pipe[0] <= '0 ;
	  treg_ack_pipe[1] <= '0 ;
	  treg_ack_pipe[2] <= '0 ;
	end else begin
      treg_ack_pipe[0] <= {treg_ack.read_valid,treg_ack.read_miss,treg_ack.write_valid,treg_ack.write_miss,treg_ack.sai_successfull,treg_ack.data} ;
      treg_ack_pipe[1] <= treg_ack_pipe[0];
      treg_ack_pipe[2] <= treg_ack_pipe[1];
    end
  end

 
 
  assign fifo_HS_wr_en = treg_ack_pipe[2].read_valid | treg_ack_pipe[2].write_valid;
  
  assign fifo_HS_in = treg_ack_pipe[2] ;
  assign {treg_ack_fifo.read_valid,treg_ack_fifo.read_miss,treg_ack_fifo.write_valid,treg_ack_fifo.write_miss,treg_ack_fifo.sai_successfull,treg_ack_fifo.data}  = ~empty_fifo_HS ? fifo_HS_out : 69'd0 ; ;
  
 // ccv_afu_cdc_fifo_vcd #(
 //       .SYNC                   (0),   
 //                                      
 //       .IN_DATAWIDTH           (69),  
 //       .OUT_DATAWIDTH          (69),  
 //       .ADDRWIDTH              (3),  
 //       .FULL_DURING_RST        (0),   
 //       .FWFT_ENABLE            (1),   
 //       .FREQ_IMPROVE           (0),   
 //                                      
 //       .USE_ASYNC_RST          (1))    
 // cfg_to_iosf_fifo_vcd (
 //       .rst                    (~sbr_rstb_i),                    
 //       .wr_clock               (clk),              
 //       .rd_clock               (sbr_clk_i), 
 //       .wr_en                  (fifo_HS_wr_en),  
 //       .rd_en                  (~empty_fifo_HS), 
 //       .din                    (fifo_HS_in), 
 //       .prog_full_offset       (3'd0), 
 //       .prog_empty_offset      (3'd0), 
 //       .full                   (fifo_full2), 
 //       .empty                  (empty_fifo_HS),
 //       .dout                   (fifo_HS_out), 
 //       .prog_full              (), 
 //       .prog_empty             (), 
 //       .underflow              (), 
 //       .overflow               (), 
 //       .word_cnt_rd_side       (), 
 //       .word_cnt_wr_side       () );

		  
		cfg_to_iosf_fifo_vcd_ED	 cfg_to_iosf_fifo (
		.data    (fifo_HS_in),    //   input,  width = 69,  fifo_input.datain
		.wrreq   (fifo_HS_wr_en),   //   input,   width = 1,            .wrreq
		.rdreq   (~empty_fifo_HS),   //   input,   width = 1,            .rdreq
		.wrclk   (clk),   //   input,   width = 1,            .wrclk
		.rdclk   (sbr_clk_i),   //   input,   width = 1,            .rdclk
		.aclr    (~sbr_rstb_i),    //   input,   width = 1,            .aclr
		.q       (fifo_HS_out),       //  output,  width = 69, fifo_output.dataout
		.rdempty (empty_fifo_HS), //  output,   width = 1,            .rdempty
		.wrfull  (fifo_full2)   //  output,   width = 1,            .wrfull
	);	
		  
  endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tce1AlAE2DZAjPEdnuZCahcmKshOm78kw2um21YO2swgaHFEgROE64Oa1DCkE7tZzFDMfx+c1hRCHx5nwQ7GAO33USCYebJ31owBvktGgjQGTB8E3/6VudXmfYfQ/Fw2ad2eCHvzzAfl1lbXscm4IntsEtW9FHBLVuPcjUfoHtph+mXJRw8/WmSCPE2oE8teGVJs8iDhntm1P/vVFfnWlL4yQwEpwkBoWzLRT28+zTxeEzIPi3XzGa76tCrD90nIpxaC7kEJX4yBpY5kIDuo/mu3KJJGx8AK7Z7trjGauIIN4wpSBjxvCMe1bjEFjROnBqmWvS8snfoj16xrI3/1JcIfJ9q46iYhqox48LRQD/A3ECbWq6hk13IL6+/FwdNNUDo2Muxjg0ekAlegRvEiBLgOyEvTU7EYKeC4YPq/ulx2s4+aLX64V7UMMututzQLUdQ+dGW4kHvRG32RA4xjyCc9nIwJ5PF4hhM30rop2Npxc0MFlSQbn4Cl7JEtCLv+bEhJBB9BaXDHsbFV/xQZ4vj/V+7u75yP/cpvY1OmLIfr/nJwkQk7u/9R+BurwwkCGeRbmu9KMfqo/kUwpGdBjBe6tvHhrq6o+GyeesVMIlK9vHGDO7eTq5YvARP9YTmWTm9iZ2+h1++oSGh/k24XxSI6GIp/v4Db3rojnEDlzWdLDL1q2zyfsA3o4o9YqmlkJxpW2tvq/fytiSHv2TClwEzmNONtaJutB2MJOx0BA5m7sJjKpwpoHvkQXJQvDIvsgHuixPL1ZvmAEA9foujU2wrD"
`endif