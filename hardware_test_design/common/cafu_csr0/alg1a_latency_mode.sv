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
`include "ccv_afu_globals.vh.iv"

module alg1a_latency_mode
  import ccv_afu_pkg::*;
  import cafu_common_pkg::*;
#(
   parameter READSORWRITES = 0  // 0 for read reqs, 1 for write reqs
 )
(
  input logic clk,
  input logic reset_n,    // active low reset

  /* signals from ccv afu config register space
  */
  input logic i_forceful_disable,
  input logic i_latency_mode,

  /* signals from gen axi reqs
     same enable to send read reqs or send write reqs
  */ 
  input logic i_enable,       // active high
  input logic i_set_not_busy, // active high
 
  /*  AXI-MM interface channels
  */
   input cafu_common_pkg::t_cafu_axi4_wr_addr_ch      i_from_execute_axi_wr_addr,  
  output cafu_common_pkg::t_cafu_axi4_wr_addr_ch          o_to_cxlip_axi_wr_addr,

   input cafu_common_pkg::t_cafu_axi4_wr_addr_ready   i_from_cxlip_axi_awready,
  output cafu_common_pkg::t_cafu_axi4_wr_addr_ready   o_to_execute_axi_awready,  

   input cafu_common_pkg::t_cafu_axi4_wr_data_ch      i_from_execute_axi_wr_data,
  output cafu_common_pkg::t_cafu_axi4_wr_data_ch          o_to_cxlip_axi_wr_data,
 
   input cafu_common_pkg::t_cafu_axi4_wr_data_ready   i_from_cxlip_axi_wready, 
  output cafu_common_pkg::t_cafu_axi4_wr_data_ready   o_to_execute_axi_wready,
 
   input cafu_common_pkg::t_cafu_axi4_rd_addr_ch      i_from_verify_sc_axi_rd_addr,
  output cafu_common_pkg::t_cafu_axi4_rd_addr_ch            o_to_cxlip_axi_rd_addr,
 
   input cafu_common_pkg::t_cafu_axi4_rd_addr_ready     i_from_cxlip_axi_arready,
  output cafu_common_pkg::t_cafu_axi4_rd_addr_ready   o_to_verify_sc_axi_arready,

  input logic i_from_cxlip_axi_wr_resp_bvalid,
  input logic i_from_cxlip_axi_rd_resp_rvalid
);

// ================================================================================================
logic pulse_ready;
logic pulse_valid;
logic initialize;
logic axi_req_valid;
logic axi_rsp_valid;
logic axi_addr_ready;

// ================================================================================================
/* toggle the AXI write signals to/from the IP
*/
generate if( READSORWRITES == 1 ) // execute/writes mode
begin
  always_comb
  begin
    o_to_cxlip_axi_wr_addr.awaddr   = i_from_execute_axi_wr_addr.awaddr;
    //o_to_cxlip_axi_wr_addr.awatop   = i_from_execute_axi_wr_addr.awatop;
    o_to_cxlip_axi_wr_addr.awburst  = i_from_execute_axi_wr_addr.awburst;
    o_to_cxlip_axi_wr_addr.awcache  = i_from_execute_axi_wr_addr.awcache;
    o_to_cxlip_axi_wr_addr.awid     = i_from_execute_axi_wr_addr.awid;
    o_to_cxlip_axi_wr_addr.awlen    = i_from_execute_axi_wr_addr.awlen;
    o_to_cxlip_axi_wr_addr.awlock   = i_from_execute_axi_wr_addr.awlock;
    o_to_cxlip_axi_wr_addr.awprot   = i_from_execute_axi_wr_addr.awprot;
    o_to_cxlip_axi_wr_addr.awqos    = i_from_execute_axi_wr_addr.awqos;
    o_to_cxlip_axi_wr_addr.awsize   = i_from_execute_axi_wr_addr.awsize;
    o_to_cxlip_axi_wr_addr.awregion = i_from_execute_axi_wr_addr.awregion;
    o_to_cxlip_axi_wr_addr.awuser   = i_from_execute_axi_wr_addr.awuser;
    o_to_cxlip_axi_wr_addr.awvalid  = i_latency_mode ? pulse_valid : i_from_execute_axi_wr_addr.awvalid;
	
    o_to_execute_axi_awready = i_latency_mode ? pulse_ready : i_from_cxlip_axi_awready;
	
    o_to_cxlip_axi_wr_data.wdata  = i_from_execute_axi_wr_data.wdata;
    o_to_cxlip_axi_wr_data.wlast  = i_from_execute_axi_wr_data.wlast;
    o_to_cxlip_axi_wr_data.wstrb  = i_from_execute_axi_wr_data.wstrb;
    o_to_cxlip_axi_wr_data.wuser  = i_from_execute_axi_wr_data.wuser;
    o_to_cxlip_axi_wr_data.wvalid = i_latency_mode ? pulse_valid : i_from_execute_axi_wr_data.wvalid;

    o_to_execute_axi_wready = i_latency_mode ? pulse_ready : i_from_cxlip_axi_wready;
  end
end
else begin  // verify/reads mode

  assign o_to_cxlip_axi_wr_addr   = '0;
  assign o_to_execute_axi_awready = '0;
  assign o_to_cxlip_axi_wr_data   = '0;
  assign o_to_execute_axi_wready  = '0;

end
endgenerate

// ================================================================================================
/* toggle the AXI read signals to/from the IP
*/
generate if( READSORWRITES == 0 ) // verify/reads mode
begin
  always_comb
  begin
    o_to_verify_sc_axi_arready = i_latency_mode ? pulse_ready : i_from_cxlip_axi_arready;

    o_to_cxlip_axi_rd_addr.araddr   = i_from_verify_sc_axi_rd_addr.araddr;
    o_to_cxlip_axi_rd_addr.arburst  = i_from_verify_sc_axi_rd_addr.arburst;
    o_to_cxlip_axi_rd_addr.arcache  = i_from_verify_sc_axi_rd_addr.arcache;
    o_to_cxlip_axi_rd_addr.arid     = i_from_verify_sc_axi_rd_addr.arid;
    o_to_cxlip_axi_rd_addr.arlen    = i_from_verify_sc_axi_rd_addr.arlen;
    o_to_cxlip_axi_rd_addr.arlock   = i_from_verify_sc_axi_rd_addr.arlock;
    o_to_cxlip_axi_rd_addr.arprot   = i_from_verify_sc_axi_rd_addr.arprot;
    o_to_cxlip_axi_rd_addr.arqos    = i_from_verify_sc_axi_rd_addr.arqos;
    o_to_cxlip_axi_rd_addr.arregion = i_from_verify_sc_axi_rd_addr.arregion;
    o_to_cxlip_axi_rd_addr.arsize   = i_from_verify_sc_axi_rd_addr.arsize;
    o_to_cxlip_axi_rd_addr.aruser   = i_from_verify_sc_axi_rd_addr.aruser;
    o_to_cxlip_axi_rd_addr.arvalid  = i_latency_mode ? pulse_valid : i_from_verify_sc_axi_rd_addr.arvalid;
  end
end
else begin  // execute/writes mode

  assign o_to_verify_sc_axi_arready = '0;
  assign o_to_cxlip_axi_rd_addr     = '0;

end
endgenerate

// ================================================================================================
generate if( READSORWRITES == 0 ) // verify/reads mode
begin

  assign axi_req_valid = i_from_verify_sc_axi_rd_addr.arvalid;

  assign axi_rsp_valid = i_from_cxlip_axi_rd_resp_rvalid;

  assign axi_addr_ready = i_from_cxlip_axi_arready;

end
else begin  // execute/writes mode
  
  assign axi_req_valid = i_from_execute_axi_wr_addr.awvalid;

  assign axi_rsp_valid = i_from_cxlip_axi_wr_resp_bvalid;

  assign axi_addr_ready = i_from_cxlip_axi_awready;

end
endgenerate

// ================================================================================================
typedef enum logic [1:0] {
  IDLE              = 'd0,
  WAIT_READY        = 'd1,
  WAIT_REQ_VALID    = 'd2,
  WAIT_RSP_VALID    = 'd3
} fsm_enum;

fsm_enum   state;
fsm_enum   next_state;

// ================================================================================================
always_ff @( posedge clk )
begin
  state <= ~reset_n
           ? IDLE
           : i_forceful_disable
             ? IDLE
             : next_state;
end

// ================================================================================================
always_comb
begin
  initialize  = 1'b0;
  pulse_ready = 1'b0;
  pulse_valid = 1'b0;

  case( state )
    IDLE :
    begin
      if( i_enable & i_latency_mode )
      begin
	                                             next_state = WAIT_REQ_VALID;
	                                             initialize = 1'b1;
      end
      else begin
	                                             next_state = IDLE;
      end
    end
    
    WAIT_REQ_VALID :
    begin
      if( i_forceful_disable | i_set_not_busy )
      begin
	                                             next_state = IDLE;
      end
      else if( axi_req_valid )
	  begin
	                                             next_state = WAIT_READY;
										        pulse_valid = 1'b1;
	  end
	  else begin
	                                             next_state = WAIT_REQ_VALID;
	  end
    end

    WAIT_READY :
    begin
      if( i_forceful_disable | i_set_not_busy )
      begin
	                                             next_state = IDLE;
      end
      else if( ~axi_addr_ready )
      begin
	                                             next_state = WAIT_READY;
      end
      else begin
	                                             next_state = WAIT_RSP_VALID;
	                                            pulse_ready = 1'b1;
      end
    end

    WAIT_RSP_VALID :
    begin
      if( i_forceful_disable | i_set_not_busy )
      begin
	                                             next_state = IDLE;
      end
      else if( ~axi_rsp_valid )
      begin
	                                             next_state = WAIT_RSP_VALID;
      end
      else begin
	                                             next_state = WAIT_REQ_VALID;
      end
    end

    default :
    begin
	                                             next_state = IDLE;
    end
  endcase
end


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcczUofJf1dA3nONomZjaQ6X8gz09M91e6ZWMnYWeA2+9+zJuMiJA8qZx2nuXGzn+uex4gp9ULbU9Gt/Zyag5j+6NpeIMSLU4ll1Z2mnM0/y2eMxpY9wJ61sLXkv/BUwkbG/S/yFp4h+B0TVEKNdgAfDWBzfF8fawJuEVdrZ0SaoTxlb2ijSw9oqJ2wVUnr9Am5fnvqsr9V76VjbFynkoooC9/mF+XmNEta/FdhW1LiW+6eKy1Jt7MN1ZiT7Fi/z0m6FpMjW1P0T8Fzo8jUVdvnTMrGQDVk7z8fns+spuxvZisWqF19Vw2vwFmtyKfmwMMrajqbWEmo9mLmvePyKSYmXZCmSkslig63b329YKfQl5g2mYoEAxl/c3EKXSRwncSeT55FKJCJ+wcoLMzxb3bfJ0Jp0KF7w3xhdgMvD18DFAB7JobhD0OLD9B1Qy62yrs7H+ZES8ejfmAeGADqulG260TP8MWKZOP5W31ESRSSflshHEOtU8DA4LKy5d1EXyW14GtHcRrzOazeileOURpnrexi6U8RaQZ/eM5/YMbQCnMN2oxtwLbKMqVYSw90Cx9HCb/HmfZ5LCfkw2SvSSXKgdjuYhffpcM1b8CY1pQ1a4m83e4+ApH2yxVqR7nI0A/K9dMu5itPTxKkOMdyHIKifcjTb3m8si8+NAZ11Rur2N0x0wHrH/LSlGaCmXC7l4Zm/FJtCrhVwP92I3D3jn9cqfpCWXzr0kYXIx0MOHCtLQgrV0DHaALh8nxSCCORGR+v3KMJD2yNag9pYO0So72As"
`endif