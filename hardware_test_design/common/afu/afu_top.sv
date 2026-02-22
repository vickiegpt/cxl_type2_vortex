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




`include "vortex/VX_define.vh"

module afu_top

import ddr_mc_top_common_pkg::*;
import cxl_memuring_vortex_pkg::*;
(
    
`ifdef ENABLE_1_SLICE   

    output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	


`elsif ENABLE_4_SLICE   // MC_CHANNEL=4

  output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_1_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_2_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_3_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]   ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	

//Channel-1
     /* write address channel
      */
  input logic          ip2hdm_aximm1_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm1_awid       ,       
  input logic  [51:0]  ip2hdm_aximm1_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm1_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm1_awregion   ,       
  input logic          ip2hdm_aximm1_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm1_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm1_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm1_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm1_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm1_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm1_awlock     ,      
  output  logic          hdm2ip_aximm1_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm1_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm1_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm1_wstrb      ,           
  input logic          ip2hdm_aximm1_wlast      ,           
  input logic          ip2hdm_aximm1_wuser      ,           
  output logic           hdm2ip_aximm1_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm1_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm1_bid        ,
  output  logic          hdm2ip_aximm1_buser      ,
  output  logic [1:0]    hdm2ip_aximm1_bresp      ,
  input logic          ip2hdm_aximm1_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm1_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm1_arid       ,         
  input logic  [51:0]  ip2hdm_aximm1_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm1_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm1_arregion   ,         
  input logic          ip2hdm_aximm1_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm1_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm1_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm1_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm1_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm1_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm1_arlock     ,         
  output logic          hdm2ip_aximm1_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm1_rvalid     , 
  output  logic          hdm2ip_aximm1_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm1_rid        ,
  output  logic  [511:0] hdm2ip_aximm1_rdata      ,
  output  logic          hdm2ip_aximm1_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm1_rresp      ,
  input   logic          ip2hdm_aximm1_rready    ,  
    

//Channel-2
     /* write address channel
      */
  input logic          ip2hdm_aximm2_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm2_awid       ,       
  input logic  [51:0]  ip2hdm_aximm2_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm2_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm2_awregion   ,       
  input logic          ip2hdm_aximm2_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm2_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm2_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm2_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm2_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm2_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm2_awlock     ,      
  output  logic          hdm2ip_aximm2_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm2_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm2_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm2_wstrb      ,           
  input logic          ip2hdm_aximm2_wlast      ,           
  input logic          ip2hdm_aximm2_wuser      ,           
  output logic           hdm2ip_aximm2_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm2_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm2_bid        ,
  output  logic          hdm2ip_aximm2_buser      ,
  output  logic [1:0]    hdm2ip_aximm2_bresp      ,
  input logic          ip2hdm_aximm2_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm2_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm2_arid       ,         
  input logic  [51:0]  ip2hdm_aximm2_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm2_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm2_arregion   ,         
  input logic          ip2hdm_aximm2_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm2_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm2_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm2_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm2_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm2_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm2_arlock     ,         
  output logic          hdm2ip_aximm2_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm2_rvalid     , 
  output  logic          hdm2ip_aximm2_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm2_rid        ,
  output  logic  [511:0] hdm2ip_aximm2_rdata      ,
  output  logic          hdm2ip_aximm2_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm2_rresp      ,
  input   logic          ip2hdm_aximm2_rready     ,

//Channel-3
     /* write address channel
      */
  input logic          ip2hdm_aximm3_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm3_awid       ,       
  input logic  [51:0]  ip2hdm_aximm3_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm3_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm3_awregion   ,       
  input logic          ip2hdm_aximm3_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm3_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm3_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm3_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm3_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm3_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm3_awlock     ,      
  output  logic          hdm2ip_aximm3_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm3_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm3_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm3_wstrb      ,           
  input logic          ip2hdm_aximm3_wlast      ,           
  input logic          ip2hdm_aximm3_wuser      ,           
  output logic           hdm2ip_aximm3_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm3_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm3_bid        ,
  output  logic          hdm2ip_aximm3_buser      ,
  output  logic [1:0]    hdm2ip_aximm3_bresp      ,
  input logic          ip2hdm_aximm3_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm3_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm3_arid       ,         
  input logic  [51:0]  ip2hdm_aximm3_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm3_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm3_arregion   ,         
  input logic          ip2hdm_aximm3_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm3_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm3_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm3_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm3_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm3_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm3_arlock     ,         
  output logic          hdm2ip_aximm3_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm3_rvalid     , 
  output  logic          hdm2ip_aximm3_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm3_rid        ,
  output  logic  [511:0] hdm2ip_aximm3_rdata      ,
  output  logic          hdm2ip_aximm3_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm3_rresp      ,
  input   logic          ip2hdm_aximm3_rready   ,  
  

   `else

  output  logic  [4:0]     mc2ip_0_sr_status,               //HDM controller status
  output  logic  [4:0]     mc2ip_1_sr_status,               //HDM controller status
//Channel-0
     /* write address channel
      */
  input logic          ip2hdm_aximm0_awvalid    ,       
  input logic  [7:0]   ip2hdm_aximm0_awid       ,       
  input logic  [51:0]  ip2hdm_aximm0_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm0_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm0_awregion   ,       
  input logic          ip2hdm_aximm0_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm0_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm0_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm0_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm0_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm0_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm0_awlock     ,      
  output  logic          hdm2ip_aximm0_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm0_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm0_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm0_wstrb      ,           
  input logic          ip2hdm_aximm0_wlast      ,           
  input logic          ip2hdm_aximm0_wuser      ,           
  output logic           hdm2ip_aximm0_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm0_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm0_bid        ,
  output  logic          hdm2ip_aximm0_buser      ,
  output  logic [1:0]    hdm2ip_aximm0_bresp      ,
  input logic          ip2hdm_aximm0_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm0_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm0_arid       ,         
  input logic  [51:0]  ip2hdm_aximm0_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm0_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm0_arregion   ,         
  input logic          ip2hdm_aximm0_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm0_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm0_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm0_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm0_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm0_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm0_arlock     ,         
  output logic          hdm2ip_aximm0_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm0_rvalid     , 
  output  logic          hdm2ip_aximm0_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm0_rid        ,
  output  logic  [511:0] hdm2ip_aximm0_rdata      ,
  output  logic          hdm2ip_aximm0_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm0_rresp      ,
  input   logic          ip2hdm_aximm0_rready    ,     
	

//Channel-1
     /* write address channel
      */
  input logic          ip2hdm_aximm1_awvalid    ,       
  input logic  [7:0]  ip2hdm_aximm1_awid       ,       
  input logic  [51:0]  ip2hdm_aximm1_awaddr     ,       
  input logic  [9:0]   ip2hdm_aximm1_awlen      ,       
  input logic  [3:0]   ip2hdm_aximm1_awregion   ,       
  input logic          ip2hdm_aximm1_awuser     ,       
  input logic  [2:0]   ip2hdm_aximm1_awsize     ,      
  input logic  [1:0]   ip2hdm_aximm1_awburst    ,      
  input logic  [2:0]   ip2hdm_aximm1_awprot     ,      
  input logic  [3:0]   ip2hdm_aximm1_awqos      ,      
  input logic  [3:0]   ip2hdm_aximm1_awcache    ,      
  input logic  [1:0]   ip2hdm_aximm1_awlock     ,      
  output  logic          hdm2ip_aximm1_awready    ,
     /* write data channel
      */
  input logic          ip2hdm_aximm1_wvalid     ,          
  input logic  [511:0] ip2hdm_aximm1_wdata      ,           
  input logic  [63:0]  ip2hdm_aximm1_wstrb      ,           
  input logic          ip2hdm_aximm1_wlast      ,           
  input logic          ip2hdm_aximm1_wuser      ,           
  output logic           hdm2ip_aximm1_wready  	 ,
     /* write response channel
      */
  output  logic          hdm2ip_aximm1_bvalid     ,
  output  logic [7:0]    hdm2ip_aximm1_bid        ,
  output  logic          hdm2ip_aximm1_buser      ,
  output  logic [1:0]    hdm2ip_aximm1_bresp      ,
  input logic          ip2hdm_aximm1_bready     ,               
     /* read address channel
      */
  input logic          ip2hdm_aximm1_arvalid    ,         
  input logic  [7:0]  ip2hdm_aximm1_arid       ,         
  input logic  [51:0]  ip2hdm_aximm1_araddr     ,         
  input logic  [9:0]   ip2hdm_aximm1_arlen      ,         
  input logic  [3:0]   ip2hdm_aximm1_arregion   ,         
  input logic          ip2hdm_aximm1_aruser     ,         
  input logic  [2:0]   ip2hdm_aximm1_arsize     ,         
  input logic  [1:0]   ip2hdm_aximm1_arburst    ,         
  input logic  [2:0]   ip2hdm_aximm1_arprot     ,         
  input logic  [3:0]   ip2hdm_aximm1_arqos      ,         
  input logic  [3:0]   ip2hdm_aximm1_arcache    ,         
  input logic  [1:0]   ip2hdm_aximm1_arlock     ,         
  output logic          hdm2ip_aximm1_arready    , 
     /* read response channel
      */
  output  logic          hdm2ip_aximm1_rvalid     , 
  output  logic          hdm2ip_aximm1_rlast     , 
  output  logic  [7:0]   hdm2ip_aximm1_rid        ,
  output  logic  [511:0] hdm2ip_aximm1_rdata      ,
  output  logic          hdm2ip_aximm1_ruser      ,
  output  logic  [1:0]   hdm2ip_aximm1_rresp      ,
  input   logic          ip2hdm_aximm1_rready    ,  
    

`endif

  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][4:0] mc_status,
  /* only supporting the axi4 for HDM memory traffic to/from IP
   */
  /* External MC_TOP <--> CXL-IP - write address channels
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_awvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ID_BW-1:0]     ip2hdm_aximm_awid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_ADDR_BW-1:0]   ip2hdm_aximm_awaddr,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_BLEN_BW-1:0]   ip2hdm_aximm_awlen,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_REGION_BW-1:0] ip2hdm_aximm_awregion,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WAC_USER_BW-1:0]   ip2hdm_aximm_awuser,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_awsize,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_awburst,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_awprot,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_awqos,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_awcache,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_awlock,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_awready,   
  /* External MC_TOP <--> CXL-IP - write data channel
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_DATA_BW-1:0] ip2hdm_aximm_wdata,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_STRB_BW-1:0] ip2hdm_aximm_wstrb,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_wlast,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WDC_USER_BW-1:0] ip2hdm_aximm_wuser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_wready,		  
  /* External MC_TOP <--> CXL-IP - write response channel
   */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_bvalid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0]   hdm2ip_aximm_bid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_USER_BW-1:0] hdm2ip_aximm_buser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_bresp,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_bready,  
  /* External MC_TOP <--> CXL-IP - read address channel
   */
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        ip2hdm_aximm_arvalid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ID_BW-1:0]     ip2hdm_aximm_arid,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_ADDR_BW-1:0]   ip2hdm_aximm_araddr,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_BLEN_BW-1:0]   ip2hdm_aximm_arlen,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_REGION_BW-1:0] ip2hdm_aximm_arregion,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RAC_USER_BW-1:0]   ip2hdm_aximm_aruser,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_SIZE_WIDTH-1:0]   ip2hdm_aximm_arsize,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_BURST_WIDTH-1:0]  ip2hdm_aximm_arburst,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_PROT_WIDTH-1:0]   ip2hdm_aximm_arprot,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_QOS_WIDTH-1:0]    ip2hdm_aximm_arqos,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_CACHE_WIDTH-1:0]  ip2hdm_aximm_arcache,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_LOCK_WIDTH-1:0]   ip2hdm_aximm_arlock,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                        hdm2ip_aximm_arready,  
  /* External MC_TOP <--> CXL-IP - read response channel
   */
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rvalid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      hdm2ip_aximm_rlast,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0]   hdm2ip_aximm_rid,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_DATA_BW-1:0] hdm2ip_aximm_rdata,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_USER_BW-1:0] hdm2ip_aximm_ruser,
  input logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0][ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_rresp,
   output logic [ddr_mc_top_common_pkg::MCTOP_MC_CHANNEL-1:0]                                                      ip2hdm_aximm_rready


, input ip2hdm_clk
, input ip2hdm_reset_n
, input [31:0] read_delay
);




//Passthrough User can implement the AFU logic here 

`ifdef ENABLE_1_SLICE   

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
//Channel-0
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;
 
 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

`elsif ENABLE_4_SLICE   

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
 assign   mc2ip_1_sr_status      =  mc_status[1]                   ;
 assign   mc2ip_2_sr_status      =  mc_status[2]                   ;
 assign   mc2ip_3_sr_status      =  mc_status[3]                   ;


//Channel-0
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;
 
 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

//Channel-1
 assign ip2hdm_aximm_awid    [1] = ip2hdm_aximm1_awid ;
 assign ip2hdm_aximm_awaddr  [1] = ip2hdm_aximm1_awaddr ;
 assign ip2hdm_aximm_awlen   [1] = ip2hdm_aximm1_awlen ;
 assign ip2hdm_aximm_awregion[1] = ip2hdm_aximm1_awregion ;
 assign ip2hdm_aximm_awuser  [1] = ip2hdm_aximm1_awuser ;
 assign ip2hdm_aximm_awsize  [1] = ip2hdm_aximm1_awsize  ;
 assign ip2hdm_aximm_awburst [1] = ip2hdm_aximm1_awburst ;
 assign ip2hdm_aximm_awprot  [1] = ip2hdm_aximm1_awprot  ;
 assign ip2hdm_aximm_awqos   [1] = ip2hdm_aximm1_awqos   ;
 assign ip2hdm_aximm_awcache [1] = ip2hdm_aximm1_awcache ;
 assign ip2hdm_aximm_awlock  [1] = ip2hdm_aximm1_awlock  ;
 assign ip2hdm_aximm_awvalid [1] = ip2hdm_aximm1_awvalid;
 assign ip2hdm_aximm_wdata   [1] = ip2hdm_aximm1_wdata ;
 assign ip2hdm_aximm_wstrb   [1] = ip2hdm_aximm1_wstrb ;
 assign ip2hdm_aximm_wlast   [1] = ip2hdm_aximm1_wlast ;
 assign ip2hdm_aximm_wuser   [1] = ip2hdm_aximm1_wuser ;
 assign ip2hdm_aximm_wvalid  [1] = ip2hdm_aximm1_wvalid;
 assign ip2hdm_aximm_bready  [1] = ip2hdm_aximm1_bready ;
 assign ip2hdm_aximm_arid    [1] = ip2hdm_aximm1_arid ;
 assign ip2hdm_aximm_araddr  [1] = ip2hdm_aximm1_araddr ;
 assign ip2hdm_aximm_arlen   [1] = ip2hdm_aximm1_arlen ;
 assign ip2hdm_aximm_arregion[1] = ip2hdm_aximm1_arregion ;
 assign ip2hdm_aximm_aruser  [1] = ip2hdm_aximm1_aruser ;
 assign ip2hdm_aximm_arsize  [1] = ip2hdm_aximm1_arsize ;
 assign ip2hdm_aximm_arburst [1] = ip2hdm_aximm1_arburst ;
 assign ip2hdm_aximm_arprot  [1] = ip2hdm_aximm1_arprot  ;
 assign ip2hdm_aximm_arqos   [1] = ip2hdm_aximm1_arqos  ;
 assign ip2hdm_aximm_arcache [1] = ip2hdm_aximm1_arcache ;
 assign ip2hdm_aximm_arlock  [1] = ip2hdm_aximm1_arlock ;
 assign ip2hdm_aximm_arvalid [1] = ip2hdm_aximm1_arvalid;
 
 assign hdm2ip_aximm1_awready    =  hdm2ip_aximm_awready[1] ;
 assign hdm2ip_aximm1_wready     =  hdm2ip_aximm_wready [1] ;
 assign hdm2ip_aximm1_bvalid     =  hdm2ip_aximm_bvalid [1] ;
 assign hdm2ip_aximm1_bid        =  hdm2ip_aximm_bid    [1] ;
 assign hdm2ip_aximm1_buser      =  hdm2ip_aximm_buser  [1] ;
 assign hdm2ip_aximm1_bresp      =  hdm2ip_aximm_bresp  [1] ;
 assign hdm2ip_aximm1_arready    =  hdm2ip_aximm_arready[1] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm1_rvalid     =  hdm2ip_aximm_rvalid [1] ;
 assign hdm2ip_aximm1_rlast      =  hdm2ip_aximm_rlast  [1] ;
 assign hdm2ip_aximm1_rid        =  hdm2ip_aximm_rid    [1] ;
 assign hdm2ip_aximm1_rdata      =  hdm2ip_aximm_rdata  [1] ;
 assign hdm2ip_aximm1_ruser      =  hdm2ip_aximm_ruser  [1] ;
 assign hdm2ip_aximm1_rresp      =  hdm2ip_aximm_rresp  [1] ;
 assign ip2hdm_aximm_rready  [1] = ip2hdm_aximm1_rready ;
`endif


//Channel-2
 assign ip2hdm_aximm_awid    [2] = ip2hdm_aximm2_awid ;
 assign ip2hdm_aximm_awaddr  [2] = ip2hdm_aximm2_awaddr ;
 assign ip2hdm_aximm_awlen   [2] = ip2hdm_aximm2_awlen ;
 assign ip2hdm_aximm_awregion[2] = ip2hdm_aximm2_awregion ;
 assign ip2hdm_aximm_awuser  [2] = ip2hdm_aximm2_awuser ;
 assign ip2hdm_aximm_awsize  [2] = ip2hdm_aximm2_awsize  ;
 assign ip2hdm_aximm_awburst [2] = ip2hdm_aximm2_awburst ;
 assign ip2hdm_aximm_awprot  [2] = ip2hdm_aximm2_awprot  ;
 assign ip2hdm_aximm_awqos   [2] = ip2hdm_aximm2_awqos   ;
 assign ip2hdm_aximm_awcache [2] = ip2hdm_aximm2_awcache ;
 assign ip2hdm_aximm_awlock  [2] = ip2hdm_aximm2_awlock  ;
 assign ip2hdm_aximm_awvalid [2] = ip2hdm_aximm2_awvalid;
 assign ip2hdm_aximm_wdata   [2] = ip2hdm_aximm2_wdata ;
 assign ip2hdm_aximm_wstrb   [2] = ip2hdm_aximm2_wstrb ;
 assign ip2hdm_aximm_wlast   [2] = ip2hdm_aximm2_wlast ;
 assign ip2hdm_aximm_wuser   [2] = ip2hdm_aximm2_wuser ;
 assign ip2hdm_aximm_wvalid  [2] = ip2hdm_aximm2_wvalid;
 assign ip2hdm_aximm_bready  [2] = ip2hdm_aximm2_bready ;
 assign ip2hdm_aximm_arid    [2] = ip2hdm_aximm2_arid ;
 assign ip2hdm_aximm_araddr  [2] = ip2hdm_aximm2_araddr ;
 assign ip2hdm_aximm_arlen   [2] = ip2hdm_aximm2_arlen ;
 assign ip2hdm_aximm_arregion[2] = ip2hdm_aximm2_arregion ;
 assign ip2hdm_aximm_aruser  [2] = ip2hdm_aximm2_aruser ;
 assign ip2hdm_aximm_arsize  [2] = ip2hdm_aximm2_arsize ;
 assign ip2hdm_aximm_arburst [2] = ip2hdm_aximm2_arburst ;
 assign ip2hdm_aximm_arprot  [2] = ip2hdm_aximm2_arprot  ;
 assign ip2hdm_aximm_arqos   [2] = ip2hdm_aximm2_arqos  ;
 assign ip2hdm_aximm_arcache [2] = ip2hdm_aximm2_arcache ;
 assign ip2hdm_aximm_arlock  [2] = ip2hdm_aximm2_arlock ;
 assign ip2hdm_aximm_arvalid [2] = ip2hdm_aximm2_arvalid;
 
 assign hdm2ip_aximm2_awready    =  hdm2ip_aximm_awready[2] ;
 assign hdm2ip_aximm2_wready     =  hdm2ip_aximm_wready [2] ;
 assign hdm2ip_aximm2_bvalid     =  hdm2ip_aximm_bvalid [2] ;
 assign hdm2ip_aximm2_bid        =  hdm2ip_aximm_bid    [2] ;
 assign hdm2ip_aximm2_buser      =  hdm2ip_aximm_buser  [2] ;
 assign hdm2ip_aximm2_bresp      =  hdm2ip_aximm_bresp  [2] ;
 assign hdm2ip_aximm2_arready    =  hdm2ip_aximm_arready[2] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm2_rvalid     =  hdm2ip_aximm_rvalid [2] ;
 assign hdm2ip_aximm2_rlast      =  hdm2ip_aximm_rlast  [2] ;
 assign hdm2ip_aximm2_rid        =  hdm2ip_aximm_rid    [2] ;
 assign hdm2ip_aximm2_rdata      =  hdm2ip_aximm_rdata  [2] ;
 assign hdm2ip_aximm2_ruser      =  hdm2ip_aximm_ruser  [2] ;
 assign hdm2ip_aximm2_rresp      =  hdm2ip_aximm_rresp  [2] ;
 assign ip2hdm_aximm_rready  [2] = ip2hdm_aximm2_rready ;
`endif

//Channel-3
 assign ip2hdm_aximm_awid    [3] = ip2hdm_aximm3_awid ;
 assign ip2hdm_aximm_awaddr  [3] = ip2hdm_aximm3_awaddr ;
 assign ip2hdm_aximm_awlen   [3] = ip2hdm_aximm3_awlen ;
 assign ip2hdm_aximm_awregion[3] = ip2hdm_aximm3_awregion ;
 assign ip2hdm_aximm_awuser  [3] = ip2hdm_aximm3_awuser ;
 assign ip2hdm_aximm_awsize  [3] = ip2hdm_aximm3_awsize  ;
 assign ip2hdm_aximm_awburst [3] = ip2hdm_aximm3_awburst ;
 assign ip2hdm_aximm_awprot  [3] = ip2hdm_aximm3_awprot  ;
 assign ip2hdm_aximm_awqos   [3] = ip2hdm_aximm3_awqos   ;
 assign ip2hdm_aximm_awcache [3] = ip2hdm_aximm3_awcache ;
 assign ip2hdm_aximm_awlock  [3] = ip2hdm_aximm3_awlock  ;
 assign ip2hdm_aximm_awvalid [3] = ip2hdm_aximm3_awvalid;
 assign ip2hdm_aximm_wdata   [3] = ip2hdm_aximm3_wdata ;
 assign ip2hdm_aximm_wstrb   [3] = ip2hdm_aximm3_wstrb ;
 assign ip2hdm_aximm_wlast   [3] = ip2hdm_aximm3_wlast ;
 assign ip2hdm_aximm_wuser   [3] = ip2hdm_aximm3_wuser ;
 assign ip2hdm_aximm_wvalid  [3] = ip2hdm_aximm3_wvalid;
 assign ip2hdm_aximm_bready  [3] = ip2hdm_aximm3_bready ;
 assign ip2hdm_aximm_arid    [3] = ip2hdm_aximm3_arid ;
 assign ip2hdm_aximm_araddr  [3] = ip2hdm_aximm3_araddr ;
 assign ip2hdm_aximm_arlen   [3] = ip2hdm_aximm3_arlen ;
 assign ip2hdm_aximm_arregion[3] = ip2hdm_aximm3_arregion ;
 assign ip2hdm_aximm_aruser  [3] = ip2hdm_aximm3_aruser ;
 assign ip2hdm_aximm_arsize  [3] = ip2hdm_aximm3_arsize ;
 assign ip2hdm_aximm_arburst [3] = ip2hdm_aximm3_arburst ;
 assign ip2hdm_aximm_arprot  [3] = ip2hdm_aximm3_arprot  ;
 assign ip2hdm_aximm_arqos   [3] = ip2hdm_aximm3_arqos  ;
 assign ip2hdm_aximm_arcache [3] = ip2hdm_aximm3_arcache ;
 assign ip2hdm_aximm_arlock  [3] = ip2hdm_aximm3_arlock ;
 assign ip2hdm_aximm_arvalid [3] = ip2hdm_aximm3_arvalid;
 
 assign hdm2ip_aximm3_awready    =  hdm2ip_aximm_awready[3] ;
 assign hdm2ip_aximm3_wready     =  hdm2ip_aximm_wready [3] ;
 assign hdm2ip_aximm3_bvalid     =  hdm2ip_aximm_bvalid [3] ;
 assign hdm2ip_aximm3_bid        =  hdm2ip_aximm_bid    [3] ;
 assign hdm2ip_aximm3_buser      =  hdm2ip_aximm_buser  [3] ;
 assign hdm2ip_aximm3_bresp      =  hdm2ip_aximm_bresp  [3] ;
 assign hdm2ip_aximm3_arready    =  hdm2ip_aximm_arready[3] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm3_rvalid     =  hdm2ip_aximm_rvalid [3] ;
 assign hdm2ip_aximm3_rlast      =  hdm2ip_aximm_rlast  [3] ;
 assign hdm2ip_aximm3_rid        =  hdm2ip_aximm_rid    [3] ;
 assign hdm2ip_aximm3_rdata      =  hdm2ip_aximm_rdata  [3] ;
 assign hdm2ip_aximm3_ruser      =  hdm2ip_aximm_ruser  [3] ;
 assign hdm2ip_aximm3_rresp      =  hdm2ip_aximm_rresp  [3] ;
 assign ip2hdm_aximm_rready  [3] = ip2hdm_aximm3_rready ;
`endif


 `else // 2_SLICE

 assign   mc2ip_0_sr_status      =  mc_status[0]                   ;
 assign   mc2ip_1_sr_status      =  mc_status[1]                   ;


//Channel-0 : Passthrough (Host HDM traffic)
 assign ip2hdm_aximm_awid    [0] = ip2hdm_aximm0_awid ;
 assign ip2hdm_aximm_awaddr  [0] = ip2hdm_aximm0_awaddr ;
 assign ip2hdm_aximm_awlen   [0] = ip2hdm_aximm0_awlen ;
 assign ip2hdm_aximm_awregion[0] = ip2hdm_aximm0_awregion ;
 assign ip2hdm_aximm_awuser  [0] = ip2hdm_aximm0_awuser ;
 assign ip2hdm_aximm_awsize  [0] = ip2hdm_aximm0_awsize  ;
 assign ip2hdm_aximm_awburst [0] = ip2hdm_aximm0_awburst ;
 assign ip2hdm_aximm_awprot  [0] = ip2hdm_aximm0_awprot  ;
 assign ip2hdm_aximm_awqos   [0] = ip2hdm_aximm0_awqos   ;
 assign ip2hdm_aximm_awcache [0] = ip2hdm_aximm0_awcache ;
 assign ip2hdm_aximm_awlock  [0] = ip2hdm_aximm0_awlock  ;
 assign ip2hdm_aximm_awvalid [0] = ip2hdm_aximm0_awvalid;
 assign ip2hdm_aximm_wdata   [0] = ip2hdm_aximm0_wdata ;
 assign ip2hdm_aximm_wstrb   [0] = ip2hdm_aximm0_wstrb ;
 assign ip2hdm_aximm_wlast   [0] = ip2hdm_aximm0_wlast ;
 assign ip2hdm_aximm_wuser   [0] = ip2hdm_aximm0_wuser ;
 assign ip2hdm_aximm_wvalid  [0] = ip2hdm_aximm0_wvalid;
 assign ip2hdm_aximm_bready  [0] = ip2hdm_aximm0_bready ;
 assign ip2hdm_aximm_arid    [0] = ip2hdm_aximm0_arid ;
 assign ip2hdm_aximm_araddr  [0] = ip2hdm_aximm0_araddr ;
 assign ip2hdm_aximm_arlen   [0] = ip2hdm_aximm0_arlen ;
 assign ip2hdm_aximm_arregion[0] = ip2hdm_aximm0_arregion ;
 assign ip2hdm_aximm_aruser  [0] = ip2hdm_aximm0_aruser ;
 assign ip2hdm_aximm_arsize  [0] = ip2hdm_aximm0_arsize ;
 assign ip2hdm_aximm_arburst [0] = ip2hdm_aximm0_arburst ;
 assign ip2hdm_aximm_arprot  [0] = ip2hdm_aximm0_arprot  ;
 assign ip2hdm_aximm_arqos   [0] = ip2hdm_aximm0_arqos  ;
 assign ip2hdm_aximm_arcache [0] = ip2hdm_aximm0_arcache ;
 assign ip2hdm_aximm_arlock  [0] = ip2hdm_aximm0_arlock ;
 assign ip2hdm_aximm_arvalid [0] = ip2hdm_aximm0_arvalid;

 assign hdm2ip_aximm0_awready    =  hdm2ip_aximm_awready[0] ;
 assign hdm2ip_aximm0_wready     =  hdm2ip_aximm_wready [0] ;
 assign hdm2ip_aximm0_bvalid     =  hdm2ip_aximm_bvalid [0] ;
 assign hdm2ip_aximm0_bid        =  hdm2ip_aximm_bid    [0] ;
 assign hdm2ip_aximm0_buser      =  hdm2ip_aximm_buser  [0] ;
 assign hdm2ip_aximm0_bresp      =  hdm2ip_aximm_bresp  [0] ;
 assign hdm2ip_aximm0_arready    =  hdm2ip_aximm_arready[0] ;
 `ifndef DELAY_BUFFER_EN
 assign hdm2ip_aximm0_rvalid     =  hdm2ip_aximm_rvalid [0] ;
 assign hdm2ip_aximm0_rlast      =  hdm2ip_aximm_rlast  [0] ;
 assign hdm2ip_aximm0_rid        =  hdm2ip_aximm_rid    [0] ;
 assign hdm2ip_aximm0_rdata      =  hdm2ip_aximm_rdata  [0] ;
 assign hdm2ip_aximm0_ruser      =  hdm2ip_aximm_ruser  [0] ;
 assign hdm2ip_aximm0_rresp      =  hdm2ip_aximm_rresp  [0] ;
 assign ip2hdm_aximm_rready  [0] = ip2hdm_aximm0_rready ;
`endif

//=========================================================================
// Channel-1 : Intercepted by Vortex GPU Wrapper
//
// - CXL IP channel 1 AXI -> AXI-to-CSR bridge -> GPU wrapper CSR (host control)
// - GPU wrapper Port1 -> MC channel 1 (GPU device memory access)
// - GPU wrapper Port0 -> tied off (unused)
//=========================================================================

// GPU wrapper internal signals
logic        gpu_csr_valid;
logic        gpu_csr_write;
logic [11:0] gpu_csr_addr;
logic [63:0] gpu_csr_wdata;
logic        gpu_csr_ready;
logic [63:0] gpu_csr_rdata;

logic        gpu_kernel_done;
logic [31:0] gpu_kernel_status;

vortex_perf_counters_t gpu_perf_counters;

// Dummy kernel launch interface (not used - CSR-driven launch)
vortex_kernel_args_t   dummy_kernel_args;
assign dummy_kernel_args = '0;

//=========================================================================
// AXI-to-CSR Bridge: CXL IP channel 1 -> GPU wrapper CSR
// Converts single-beat AXI write/read to CSR interface
//=========================================================================

typedef enum logic [2:0] {
    AXI_CSR_IDLE,
    AXI_CSR_WRITE_DATA,
    AXI_CSR_WRITE_RESP,
    AXI_CSR_READ_WAIT,
    AXI_CSR_READ_RESP
} axi_csr_state_t;

axi_csr_state_t axi_csr_state;
logic [7:0]  axi_csr_saved_id;
logic [11:0] axi_csr_saved_addr;

always_ff @(posedge ip2hdm_clk or negedge ip2hdm_reset_n) begin
    if (!ip2hdm_reset_n) begin
        axi_csr_state    <= AXI_CSR_IDLE;
        gpu_csr_valid    <= 1'b0;
        gpu_csr_write    <= 1'b0;
        gpu_csr_addr     <= 12'h0;
        gpu_csr_wdata    <= 64'h0;
        axi_csr_saved_id <= 8'h0;
        axi_csr_saved_addr <= 12'h0;
        // AXI slave responses
        hdm2ip_aximm1_awready <= 1'b0;
        hdm2ip_aximm1_wready  <= 1'b0;
        hdm2ip_aximm1_bvalid  <= 1'b0;
        hdm2ip_aximm1_bid     <= 8'h0;
        hdm2ip_aximm1_buser   <= 1'b0;
        hdm2ip_aximm1_bresp   <= 2'b00;
        hdm2ip_aximm1_arready <= 1'b0;
        hdm2ip_aximm1_rvalid  <= 1'b0;
        hdm2ip_aximm1_rlast   <= 1'b0;
        hdm2ip_aximm1_rid     <= 8'h0;
        hdm2ip_aximm1_rdata   <= 512'h0;
        hdm2ip_aximm1_ruser   <= 1'b0;
        hdm2ip_aximm1_rresp   <= 2'b00;
    end else begin
        // Default: deassert handshake signals
        hdm2ip_aximm1_awready <= 1'b0;
        hdm2ip_aximm1_wready  <= 1'b0;
        hdm2ip_aximm1_arready <= 1'b0;
        gpu_csr_valid         <= 1'b0;

        case (axi_csr_state)
            AXI_CSR_IDLE: begin
                hdm2ip_aximm1_bvalid <= 1'b0;
                hdm2ip_aximm1_rvalid <= 1'b0;

                if (ip2hdm_aximm1_awvalid) begin
                    // AXI Write Address phase
                    hdm2ip_aximm1_awready <= 1'b1;
                    axi_csr_saved_id   <= ip2hdm_aximm1_awid;
                    axi_csr_saved_addr <= ip2hdm_aximm1_awaddr[11:0];
                    axi_csr_state      <= AXI_CSR_WRITE_DATA;
                end else if (ip2hdm_aximm1_arvalid) begin
                    // AXI Read Address phase
                    hdm2ip_aximm1_arready <= 1'b1;
                    axi_csr_saved_id   <= ip2hdm_aximm1_arid;
                    axi_csr_saved_addr <= ip2hdm_aximm1_araddr[11:0];
                    // Issue CSR read
                    gpu_csr_valid <= 1'b1;
                    gpu_csr_write <= 1'b0;
                    gpu_csr_addr  <= ip2hdm_aximm1_araddr[11:0];
                    axi_csr_state <= AXI_CSR_READ_WAIT;
                end
            end

            AXI_CSR_WRITE_DATA: begin
                if (ip2hdm_aximm1_wvalid) begin
                    hdm2ip_aximm1_wready <= 1'b1;
                    // Issue CSR write
                    gpu_csr_valid <= 1'b1;
                    gpu_csr_write <= 1'b1;
                    gpu_csr_addr  <= axi_csr_saved_addr;
                    gpu_csr_wdata <= ip2hdm_aximm1_wdata[63:0];
                    axi_csr_state <= AXI_CSR_WRITE_RESP;
                end
            end

            AXI_CSR_WRITE_RESP: begin
                if (gpu_csr_ready && !hdm2ip_aximm1_bvalid) begin
                    // Assert B response, hold until bready handshake
                    hdm2ip_aximm1_bvalid <= 1'b1;
                    hdm2ip_aximm1_bid    <= axi_csr_saved_id;
                    hdm2ip_aximm1_bresp  <= 2'b00;  // OKAY
                    hdm2ip_aximm1_buser  <= 1'b0;
                end
                if (hdm2ip_aximm1_bvalid && ip2hdm_aximm1_bready) begin
                    // B handshake complete
                    hdm2ip_aximm1_bvalid <= 1'b0;
                    axi_csr_state        <= AXI_CSR_IDLE;
                end
            end

            AXI_CSR_READ_WAIT: begin
                if (gpu_csr_ready) begin
                    // Send read response
                    hdm2ip_aximm1_rvalid <= 1'b1;
                    hdm2ip_aximm1_rlast  <= 1'b1;
                    hdm2ip_aximm1_rid    <= axi_csr_saved_id;
                    hdm2ip_aximm1_rdata  <= {448'h0, gpu_csr_rdata};
                    hdm2ip_aximm1_rresp  <= 2'b00;  // OKAY
                    hdm2ip_aximm1_ruser  <= 1'b0;
                    axi_csr_state        <= AXI_CSR_READ_RESP;
                end
            end

            AXI_CSR_READ_RESP: begin
                if (ip2hdm_aximm1_rready) begin
                    hdm2ip_aximm1_rvalid <= 1'b0;
                    axi_csr_state        <= AXI_CSR_IDLE;
                end
            end

            default: axi_csr_state <= AXI_CSR_IDLE;
        endcase
    end
end

//=========================================================================
// GPU Port1 intermediate wires (GPU wrapper outputs -> MC channel 1)
//=========================================================================

logic [3:0]   gpu_p1_awid;
logic [63:0]  gpu_p1_awaddr;
logic [7:0]   gpu_p1_awlen;
logic [2:0]   gpu_p1_awsize;
logic [1:0]   gpu_p1_awburst;
logic         gpu_p1_awlock;
logic [3:0]   gpu_p1_awcache;
logic [2:0]   gpu_p1_awprot;
logic         gpu_p1_awvalid;

logic [511:0] gpu_p1_wdata;
logic [63:0]  gpu_p1_wstrb;
logic         gpu_p1_wlast;
logic         gpu_p1_wvalid;

logic         gpu_p1_bready;

logic [3:0]   gpu_p1_arid;
logic [63:0]  gpu_p1_araddr;
logic [7:0]   gpu_p1_arlen;
logic [2:0]   gpu_p1_arsize;
logic [1:0]   gpu_p1_arburst;
logic         gpu_p1_arlock;
logic [3:0]   gpu_p1_arcache;
logic [2:0]   gpu_p1_arprot;
logic         gpu_p1_arvalid;

logic         gpu_p1_rready;

//=========================================================================
// Vortex GPU Wrapper Instance
//=========================================================================

vortex_gpu_wrapper vortex_gpu_inst (
    .clk                    (ip2hdm_clk),
    .rst_n                  (ip2hdm_reset_n),

    // CSR interface (from AXI-to-CSR bridge above)
    .csr_valid              (gpu_csr_valid),
    .csr_write              (gpu_csr_write),
    .csr_addr               (gpu_csr_addr),
    .csr_wdata              (gpu_csr_wdata),
    .csr_ready              (gpu_csr_ready),
    .csr_rdata              (gpu_csr_rdata),

    // Kernel launch interface (unused - using CSR-driven launch)
    .kernel_launch_valid    (1'b0),
    .kernel_args            (dummy_kernel_args),
    .kernel_launch_ready    (),
    .kernel_done            (gpu_kernel_done),
    .kernel_status          (gpu_kernel_status),

    // Performance counters
    .perf_counters          (gpu_perf_counters),

    // AXI Port 0 (Host Memory) - unused, tied off inside wrapper
    .m_axi_port0_awid       (),
    .m_axi_port0_awaddr     (),
    .m_axi_port0_awlen      (),
    .m_axi_port0_awsize     (),
    .m_axi_port0_awburst    (),
    .m_axi_port0_awlock     (),
    .m_axi_port0_awcache    (),
    .m_axi_port0_awprot     (),
    .m_axi_port0_awvalid    (),
    .m_axi_port0_awready    (1'b1),
    .m_axi_port0_wdata      (),
    .m_axi_port0_wstrb      (),
    .m_axi_port0_wlast      (),
    .m_axi_port0_wvalid     (),
    .m_axi_port0_wready     (1'b1),
    .m_axi_port0_bid        (4'h0),
    .m_axi_port0_bresp      (2'b00),
    .m_axi_port0_bvalid     (1'b0),
    .m_axi_port0_bready     (),
    .m_axi_port0_arid       (),
    .m_axi_port0_araddr     (),
    .m_axi_port0_arlen      (),
    .m_axi_port0_arsize     (),
    .m_axi_port0_arburst    (),
    .m_axi_port0_arlock     (),
    .m_axi_port0_arcache    (),
    .m_axi_port0_arprot     (),
    .m_axi_port0_arvalid    (),
    .m_axi_port0_arready    (1'b1),
    .m_axi_port0_rid        (4'h0),
    .m_axi_port0_rdata      (512'h0),
    .m_axi_port0_rresp      (2'b00),
    .m_axi_port0_rlast      (1'b0),
    .m_axi_port0_rvalid     (1'b0),
    .m_axi_port0_rready     (),

    // AXI Port 1 (Device Memory) -> MC channel 1 via intermediate wires
    .m_axi_port1_awid       (gpu_p1_awid),
    .m_axi_port1_awaddr     (gpu_p1_awaddr),
    .m_axi_port1_awlen      (gpu_p1_awlen),
    .m_axi_port1_awsize     (gpu_p1_awsize),
    .m_axi_port1_awburst    (gpu_p1_awburst),
    .m_axi_port1_awlock     (gpu_p1_awlock),
    .m_axi_port1_awcache    (gpu_p1_awcache),
    .m_axi_port1_awprot     (gpu_p1_awprot),
    .m_axi_port1_awvalid    (gpu_p1_awvalid),
    .m_axi_port1_awready    (hdm2ip_aximm_awready[1]),
    .m_axi_port1_wdata      (gpu_p1_wdata),
    .m_axi_port1_wstrb      (gpu_p1_wstrb),
    .m_axi_port1_wlast      (gpu_p1_wlast),
    .m_axi_port1_wvalid     (gpu_p1_wvalid),
    .m_axi_port1_wready     (hdm2ip_aximm_wready[1]),
    .m_axi_port1_bid        (hdm2ip_aximm_bid[1][3:0]),
    .m_axi_port1_bresp      (hdm2ip_aximm_bresp[1]),
    .m_axi_port1_bvalid     (hdm2ip_aximm_bvalid[1]),
    .m_axi_port1_bready     (gpu_p1_bready),
    .m_axi_port1_arid       (gpu_p1_arid),
    .m_axi_port1_araddr     (gpu_p1_araddr),
    .m_axi_port1_arlen      (gpu_p1_arlen),
    .m_axi_port1_arsize     (gpu_p1_arsize),
    .m_axi_port1_arburst    (gpu_p1_arburst),
    .m_axi_port1_arlock     (gpu_p1_arlock),
    .m_axi_port1_arcache    (gpu_p1_arcache),
    .m_axi_port1_arprot     (gpu_p1_arprot),
    .m_axi_port1_arvalid    (gpu_p1_arvalid),
    .m_axi_port1_arready    (hdm2ip_aximm_arready[1]),
    .m_axi_port1_rid        (hdm2ip_aximm_rid[1][3:0]),
    .m_axi_port1_rdata      (hdm2ip_aximm_rdata[1]),
    .m_axi_port1_rresp      (hdm2ip_aximm_rresp[1]),
    .m_axi_port1_rlast      (hdm2ip_aximm_rlast[1]),
    .m_axi_port1_rvalid     (hdm2ip_aximm_rvalid[1]),
    .m_axi_port1_rready     (gpu_p1_rready)
);

//=========================================================================
// GPU Port1 -> MC Channel 1 signal assignments
//=========================================================================

// Write address channel (GPU -> MC)
assign ip2hdm_aximm_awid    [1] = {4'h0, gpu_p1_awid};
assign ip2hdm_aximm_awaddr  [1] = gpu_p1_awaddr[51:0];
assign ip2hdm_aximm_awlen   [1] = {2'b00, gpu_p1_awlen};
assign ip2hdm_aximm_awregion[1] = 4'h0;
assign ip2hdm_aximm_awuser  [1] = 1'b1;   // target_hdm = 1 (device memory)
assign ip2hdm_aximm_awsize  [1] = gpu_p1_awsize;
assign ip2hdm_aximm_awburst [1] = gpu_p1_awburst;
assign ip2hdm_aximm_awprot  [1] = gpu_p1_awprot;
assign ip2hdm_aximm_awqos   [1] = 4'h0;
assign ip2hdm_aximm_awcache [1] = gpu_p1_awcache;
assign ip2hdm_aximm_awlock  [1] = {1'b0, gpu_p1_awlock};
assign ip2hdm_aximm_awvalid [1] = gpu_p1_awvalid;

// Write data channel (GPU -> MC)
assign ip2hdm_aximm_wdata   [1] = gpu_p1_wdata;
assign ip2hdm_aximm_wstrb   [1] = gpu_p1_wstrb;
assign ip2hdm_aximm_wlast   [1] = gpu_p1_wlast;
assign ip2hdm_aximm_wuser   [1] = 1'b0;
assign ip2hdm_aximm_wvalid  [1] = gpu_p1_wvalid;

// Write response channel (MC -> GPU)
assign ip2hdm_aximm_bready  [1] = gpu_p1_bready;

// Read address channel (GPU -> MC)
assign ip2hdm_aximm_arid    [1] = {4'h0, gpu_p1_arid};
assign ip2hdm_aximm_araddr  [1] = gpu_p1_araddr[51:0];
assign ip2hdm_aximm_arlen   [1] = {2'b00, gpu_p1_arlen};
assign ip2hdm_aximm_arregion[1] = 4'h0;
assign ip2hdm_aximm_aruser  [1] = 1'b1;   // target_hdm = 1 (device memory)
assign ip2hdm_aximm_arsize  [1] = gpu_p1_arsize;
assign ip2hdm_aximm_arburst [1] = gpu_p1_arburst;
assign ip2hdm_aximm_arprot  [1] = gpu_p1_arprot;
assign ip2hdm_aximm_arqos   [1] = 4'h0;
assign ip2hdm_aximm_arcache [1] = gpu_p1_arcache;
assign ip2hdm_aximm_arlock  [1] = {1'b0, gpu_p1_arlock};
assign ip2hdm_aximm_arvalid [1] = gpu_p1_arvalid;

// Read response channel (MC -> GPU)
assign ip2hdm_aximm_rready  [1] = gpu_p1_rready;

`ifndef DELAY_BUFFER_EN
// Channel 1 CXL IP responses are driven by AXI-to-CSR bridge FSM above
// Channel 1 MC responses go directly to GPU wrapper via hdm2ip_aximm_*[1]
`endif


`endif

typedef struct packed {
  logic          rlast      ;
  logic  [7:0]   rid        ;
  logic  [511:0] rdata      ;
  logic          ruser      ;
  logic  [1:0]   rresp      ;
} axi_r_ch_t;

`ifdef DELAY_BUFFER_EN
  `ifdef ENABLE_1_SLICE
    // TODO
  `elsif ENABLE_4_SLICE
    // TODO
  `else // 2_SLICE
    // Channel 0: delay buffer for host HDM traffic (CXL IP <-> MC)
    axi_r_ch_t r_ch_in_0, r_ch_out_0;

    assign r_ch_in_0.rlast = hdm2ip_aximm_rlast[0];
    assign r_ch_in_0.rid   = hdm2ip_aximm_rid[0];
    assign r_ch_in_0.rdata = hdm2ip_aximm_rdata[0];
    assign r_ch_in_0.ruser = hdm2ip_aximm_ruser[0];
    assign r_ch_in_0.rresp = hdm2ip_aximm_rresp[0];

    assign hdm2ip_aximm0_rlast = r_ch_out_0.rlast;
    assign hdm2ip_aximm0_rid   = r_ch_out_0.rid;
    assign hdm2ip_aximm0_rdata = r_ch_out_0.rdata;
    assign hdm2ip_aximm0_ruser = r_ch_out_0.ruser;
    assign hdm2ip_aximm0_rresp = r_ch_out_0.rresp;

    axi_r db_0 (
      .clock (ip2hdm_clk),
      .reset (~ip2hdm_reset_n),

      .io_read_delay      (read_delay),

      .io_axi_r_in_valid  (hdm2ip_aximm_rvalid[0]),
      .io_axi_r_in_bits   (r_ch_in_0),
      .io_axi_r_in_ready  (ip2hdm_aximm_rready[0]),

      .io_axi_r_out_valid (hdm2ip_aximm0_rvalid),
      .io_axi_r_out_bits  (r_ch_out_0),
      .io_axi_r_out_ready (ip2hdm_aximm0_rready)
      );

    // Channel 1: No delay buffer - GPU wrapper owns this channel
    // MC read responses go directly to GPU wrapper via hdm2ip_aximm_*[1]
    // CXL IP ch1 read responses are driven by AXI-to-CSR bridge FSM
  `endif
`endif // DELAY_BUFFER_EN

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzoCJqlGacsSZq+MA+0AkxsVB7+Qi85U+bx42IAMMjTCr8jTioJW8zxCoJPKkFi4LaH7JXgvDrZ+XQcQys+OdlGlNQg/zIC8aN4+pId1uzlJtKvhyd4bmB6Z4BVJwDTMo/iVt8awxghVi5x1jInkxuxfh3V0HYP5Amcq7UhQDx886GQUluSUzRhw8XmWogYCeRjhH23Sw7CJvcpvJZ8kSPLiRBu6a/B72d/FMKXnZexLXT9gnD9WHBjc5xDus87NDe8o3wpYNFXNRFKzKqz093Emgs9SNj8JAo3CGhFi/zhZF3VXlo+DNSmATRtWj1WtvRyYc6EKpGEuBriYGhpt/+tAD45tCB1SQ4cdptEfEKgx1xpk4lUJGvY+Fm1uyDkWwE3ycjnSZ4TJeVOz26nLZ5rJDy3x3u2N2jIbv72OwDvw8O6eSec7hHk4pdmEo27nWABJaj0b3NmoklchE7NvV50SFMoOMST549MnzZZ3nhTRsZGDFgdlB0rUKolzwF2pF/yqRG+kNvoOGjxtjAX7FJN+jObSeASNRISeUjz7ygDq5spxUeZGZG2PynYPfH3lmN1fX+km1ghr4nbtewAjUBbpQum1Lri3DUDPy+npg0lvXKTYUPDMu0ry1mcD0i397jcPODt0YbDKbcOzfN7X3y4vxef1GHicp1Xc0eOqpoQ9m/JZvUvVuR77NZnrWuoEOINhmhUU2UpGipOtksNXcsLwNHWZx4XAtn8NMB1T7Y7411FulV/Dy+TcdluOFpXZkbfiPirGuE1i1+XJx6/12okh"
`endif
