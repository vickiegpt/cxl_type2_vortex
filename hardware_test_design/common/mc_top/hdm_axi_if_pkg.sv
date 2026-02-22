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


// Copyright 2024 Intel Corporation.
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

package hdm_axi_if_pkg;
  import ddr_mc_top_common_pkg::*;  // import to use protocol specific enumuration structs

// ================================================================================================
   localparam HDM_AXI_AWADDR_BW = 64;  // using bits 51:6 of 64-bits, 5:0 are zeros for byte alignment
   localparam HDM_AXI_AWUSER_BW = 1;
   localparam HDM_AXI_AWID_BW   = 12;

   localparam HDM_AXI_WDATA_BW = 512;
   localparam HDM_AXI_WSTRB_BW = HDM_AXI_WDATA_BW / 8;

   localparam HDM_AXI_BUSER_BW = 1;
   localparam HDM_AXI_BID_BW   = 12;

   localparam HDM_AXI_ARADDR_BW = 64;  // using bits 51:6 of 64-bits, 5:0 are zeros for byte alignment
   localparam HDM_AXI_ARUSER_BW = 1;
   localparam HDM_AXI_ARID_BW   = 12;
  
   localparam HDM_AXI_RDATA_BW = 512;
   localparam HDM_AXI_RID_BW   = 12;
   
// ================================================================================================
   typedef struct packed {
      logic [7:0][7:0] ecc;
    } t_hdm_axi_wuser;
	
// ================================================================================================
   typedef struct packed {
      logic [7:0][7:0] ecc;
    } t_hdm_axi_ruser;

// ================================================================================================
   typedef struct packed {
     logic [HDM_AXI_AWADDR_BW-1:0] awaddr; 
	 logic [HDM_AXI_AWID_BW-1:0]   awid;
     logic [HDM_AXI_AWUSER_BW-1:0] awuser;
     logic                         awvalid;
		
     logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] awlen;		
     logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           awregion;
     logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_AWATOP_WIDTH-1:0]           awatop;	 
	 
     ddr_mc_top_common_pkg::t_mctop_axi4_burst_encoding        awburst;
     ddr_mc_top_common_pkg::t_mctop_axi4_awcache_encoding      awcache;	 
     ddr_mc_top_common_pkg::t_mctop_axi4_lock_encoding         awlock;
     ddr_mc_top_common_pkg::t_mctop_axi4_prot_encoding         awprot;
     ddr_mc_top_common_pkg::t_mctop_axi4_qos_encoding          awqos;
     ddr_mc_top_common_pkg::t_mctop_axi4_burst_size_encoding   awsize;
   } t_hdm_axi_wr_addr_ch;

   typedef logic t_hdm_axi_wr_addr_chan_ready;
   
// ================================================================================================
   typedef struct packed {
     logic [HDM_AXI_WDATA_BW-1:0] wdata;	 
     logic                        wlast;
     logic [HDM_AXI_WSTRB_BW-1:0] wstrb;
     t_hdm_axi_wuser              wuser;
     logic                        wvalid; 
   } t_hdm_axi_wr_data_ch;

   typedef logic t_hdm_axi_wr_data_chan_ready;
   
// ================================================================================================
   typedef struct packed {
     logic [HDM_AXI_BID_BW-1:0]   bid;
     logic [HDM_AXI_BUSER_BW-1:0] buser;
     logic                        bvalid;
	 
     ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding   bresp;
   } t_hdm_axi_wr_resp_ch;

   typedef logic t_hdm_axi_wr_resp_chan_ready;

// ================================================================================================
   typedef struct packed {
     logic [HDM_AXI_ARADDR_BW-1:0] araddr;
     logic [HDM_AXI_ARID_BW-1:0]   arid;
     logic [HDM_AXI_ARUSER_BW-1:0] aruser;
     logic                         arvalid;	 
	 
     logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] arlen;
     logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_REGION_WIDTH-1:0]           arregion;

     ddr_mc_top_common_pkg::t_mctop_axi4_burst_encoding        arburst;
     ddr_mc_top_common_pkg::t_mctop_axi4_arcache_encoding      arcache;
	 ddr_mc_top_common_pkg::t_mctop_axi4_lock_encoding         arlock;
     ddr_mc_top_common_pkg::t_mctop_axi4_prot_encoding         arprot;
     ddr_mc_top_common_pkg::t_mctop_axi4_qos_encoding          arqos;
     ddr_mc_top_common_pkg::t_mctop_axi4_burst_size_encoding   arsize;                       
   } t_hdm_axi_rd_addr_ch;

   typedef logic t_hdm_axi_rd_addr_chan_ready;

// ================================================================================================
   typedef struct packed {
     logic [HDM_AXI_RDATA_BW-1:0] rdata;
     logic [HDM_AXI_RID_BW-1:0]   rid;
	 logic                        rlast;
     t_hdm_axi_ruser              ruser;
     logic                        rvalid;	 
	 
     ddr_mc_top_common_pkg::t_mctop_axi4_resp_encoding   rresp;
   } t_hdm_axi_rd_resp_ch;

   typedef logic t_hdm_axi_rd_resp_chan_ready;

// ================================================================================================
   localparam HDM_AXI_WUSER_t_BW = $bits( t_hdm_axi_wuser );
   localparam HDM_AXI_RUSER_t_BW = $bits( t_hdm_axi_ruser );
   
   localparam HDM_AXI_WR_ADDR_CH_t_BW = $bits( t_hdm_axi_wr_addr_ch );
   localparam HDM_AXI_RD_ADDR_CH_t_BW = $bits( t_hdm_axi_rd_addr_ch );
   localparam HDM_AXI_WR_DATA_CH_t_BW = $bits( t_hdm_axi_wr_data_ch );
   localparam HDM_AXI_WR_RESP_CH_t_BW = $bits( t_hdm_axi_wr_resp_ch );
   localparam HDM_AXI_RD_RESP_CH_t_BW = $bits( t_hdm_axi_rd_resp_ch );
   
// ================================================================================================
endpackage : hdm_axi_if_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL6bxJqdQoHfBwTLtBQPqNfJ6CSz48Z8SNSGEuE5wqZPL+pUK82M3JskQihkfRDWSKYKnWCYH8n0UHehj3NnmtbLPN89NA5z3IecaxUz1udYtt/xKvFldF2ZyNKLaENFTKjujsCs/oiJgDunf2Zitbf8LaEyptCDAYDtRDdMFDzpq0fLk+JanjdTMnAsthK1ITMPC2GXZXdLTmouLcyVk3UzYHVKXxAil2LwuK+7g6qeosLpw0CqsV+J3V2dldrX1Rg43Jdpt2sS5FXeusZgmxvnLmAQaVr2DzVqUpirNqgNOWQz8amaZBU2Acm/sy+4l405/DIzcAoYBUvf1HlNOPytPN8drD878meGSjR7EIytVdBC7jm5cZgWuY+4r8y95rGNYvSvXQJ8RPfi5E/YC0BOrOcNnf3SkaUSstOv2ftHy6rDxLwl1CYcv7rw0yjxp/DdnMxEqqErjysT2rU0oo01tXe6NY/MgEjlZ/YcN2l6CwQNlnV0Qfyq0sMOPYhzYbg+MEpKClADf5a3XDAqxeHLPAL7BZAqHHGDhcFA9bVKWbq2xfz/0Md+oSG27bKe9zAg8gtwHrMiZK+W88vDJLCenAKgysfCZSs9jEsGki0zh4WxzcxejHQWhuOugZil01WixgNogVgyE+98VG7/ZCZ2nhs4N0xiL9Y8zZm2hLdDI9yCWf9HFjAk1Nh3sIPPPqOu4mRii03f5bMnSjvUT/KX2aPNAmu3anyqFa39H7rb+i5W/wGinIRquqxJ/0eZ3hgoMTbvEfhFjZzEFPhxVi52"
`endif