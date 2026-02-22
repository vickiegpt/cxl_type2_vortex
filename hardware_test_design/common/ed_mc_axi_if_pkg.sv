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
 /* structs for bit widths
  
    APRIL 14 2023 - these are set based on Darren's current CXL IP HAS draft ch3.3 values
 */

package ed_mc_axi_if_pkg;
  import cafu_common_pkg::*;  // import to use protocol specific enumuration structs
  import ed_cxlip_top_pkg::*;

// ================================================================================================
 /* structs for bit widths
  
    APRIL 14 2023 - these are set based on Darren's current CXL IP HAS draft ch3.3 values
 */
// @@copy for common_afu_pkg@@start
  localparam MC_AXI_WAC_REGION_BW  =  4; // awregion
  localparam MC_AXI_WAC_ADDR_BW    = 52; // awaddr  - using bits 51:6 of 64-bits, also grabbing the lower 6 bits?
  localparam MC_AXI_WAC_USER_BW    =  1; // awuser
  localparam MC_AXI_WAC_ID_BW      =  8; // awid    - feb2024 - changed from 12
  localparam MC_AXI_WAC_BLEN_BW    = 10; // awlen
  
  localparam MC_AXI_WDC_DATA_BW = 512; // wwdata
  localparam MC_AXI_WDC_USER_BW =  1;  // wuser  // currently only poison
  
  localparam MC_AXI_WDC_STRB_BW = MC_AXI_WDC_DATA_BW / 8; // wstrb
  
  localparam MC_AXI_WRC_ID_BW   =  8; // bid   - feb2024 - changed from 12
  localparam MC_AXI_WRC_USER_BW =  1; // buser
  
  localparam MC_AXI_RAC_REGION_BW  =  4; // arregion
  localparam MC_AXI_RAC_ID_BW      =  8; // arid    - feb2024 - changed from 12
  localparam MC_AXI_RAC_ADDR_BW    = 52; // araddr  - using bits 51:6 of 64-bits, also grabbing the lower 6 bits?
  localparam MC_AXI_RAC_BLEN_BW    = 10; // arlen
  localparam MC_AXI_RAC_USER_BW    =  1; // aruser
  
  localparam MC_AXI_RRC_ID_BW        =   8; // rid   - feb2024 - changed from 12
  localparam MC_AXI_RRC_DATA_BW      = 512; // rdata
  localparam MC_EMIF_AMM_RRC_DATA_BW = 576; // rdata from EMIF AMM.

// ================================================================================================
// struct for read response channel response field
// ================================================================================================
  typedef struct packed {
	logic poison;
  } t_rd_rsp_user;

  localparam MC_AXI_RRC_USER_BW = $bits( t_rd_rsp_user );
  
// ================================================================================================
// AXI signals from BBS to MC
// ================================================================================================
  typedef struct packed {
    cafu_common_pkg::t_cafu_axi4_wr_resp_ready   bready;
    cafu_common_pkg::t_cafu_axi4_rd_resp_ready   rready;
	
	logic [MC_AXI_WAC_ID_BW-1:0]                 awid;
	logic [MC_AXI_WAC_ADDR_BW-1:0]               awaddr;
	logic [MC_AXI_WAC_BLEN_BW-1:0]               awlen;
	cafu_common_pkg::t_cafu_axi4_burst_size_encoding   awsize;
	cafu_common_pkg::t_cafu_axi4_burst_encoding        awburst;
	cafu_common_pkg::t_cafu_axi4_prot_encoding         awprot;
	cafu_common_pkg::t_cafu_axi4_qos_encoding          awqos;
	logic                                        awvalid;
	cafu_common_pkg::t_cafu_axi4_awcache_encoding      awcache;
	cafu_common_pkg::t_cafu_axi4_lock_encoding         awlock;
	logic [MC_AXI_WAC_REGION_BW-1:0]             awregion;
	logic [MC_AXI_WAC_USER_BW-1:0]               awuser;
	
    logic [MC_AXI_WDC_DATA_BW-1:0] wdata;
	logic [MC_AXI_WDC_STRB_BW-1:0] wstrb;
	logic                          wlast;
	logic                          wvalid;
	logic [MC_AXI_WDC_USER_BW-1:0] wuser; // currently only poison
	
	logic [MC_AXI_RAC_ID_BW-1:0]                 arid;
	logic [MC_AXI_RAC_ADDR_BW-1:0]               araddr;
	logic [MC_AXI_RAC_BLEN_BW-1:0]               arlen;
    cafu_common_pkg::t_cafu_axi4_burst_size_encoding   arsize;
    cafu_common_pkg::t_cafu_axi4_burst_encoding        arburst;
    cafu_common_pkg::t_cafu_axi4_prot_encoding         arprot;
    cafu_common_pkg::t_cafu_axi4_qos_encoding          arqos;
	logic                                        arvalid;
    cafu_common_pkg::t_cafu_axi4_arcache_encoding      arcache;
    cafu_common_pkg::t_cafu_axi4_lock_encoding         arlock;
    logic [MC_AXI_RAC_REGION_BW-1:0]             arregion;
    logic [MC_AXI_RAC_USER_BW-1:0]               aruser;
  } t_to_mc_axi4;
  
  localparam TO_MC_AXI4_BW = $bits(t_to_mc_axi4);
  
// ================================================================================================
  typedef struct packed {
    cafu_common_pkg::t_cafu_axi4_wr_addr_ready   awready;
    cafu_common_pkg::t_cafu_axi4_wr_data_ready    wready;
    cafu_common_pkg::t_cafu_axi4_rd_addr_ready   arready;
	
	logic [MC_AXI_WRC_ID_BW-1:0]           bid;
	cafu_common_pkg::t_cafu_axi4_resp_encoding   bresp;
	logic                                  bvalid;
	logic [MC_AXI_WRC_USER_BW-1:0]         buser;
	
	logic [MC_AXI_RRC_ID_BW-1:0]           rid;
	logic [MC_AXI_RRC_DATA_BW-1:0]         rdata;
	cafu_common_pkg::t_cafu_axi4_resp_encoding   rresp;
	logic                                  rvalid;
	logic                                  rlast;
    //logic [MC_AXI_RRC_USER_BW-1:0]         ruser;
	t_rd_rsp_user                          ruser;
  } t_from_mc_axi4;
  
  localparam FROM_MC_AXI4_BW = $bits(t_from_mc_axi4);
  localparam FROM_MC_AXI4_BW_PARM = $bits(t_from_mc_axi4);
// @@copy for common_afu_pkg@@end
  
// ================================================================================================
  typedef struct packed {
        cafu_common_pkg::t_cafu_axi4_rd_addr_ready   arready;
        logic                                  rd_id_fifo_almost_full;

        logic [MC_AXI_RRC_ID_BW-1:0]           rid;
        logic [MC_EMIF_AMM_RRC_DATA_BW-1:0]    rdata;
        cafu_common_pkg::t_cafu_axi4_resp_encoding   rresp;
        logic                                  rvalid;
        logic                                  rlast;
    //logic [MC_AXI_RRC_USER_BW-1:0]         ruser;
        t_rd_rsp_user                          ruser;
  } t_from_mc_axi4_rchan;

  localparam FROM_MC_AXI4_RCHAN_BW = $bits(t_from_mc_axi4_rchan);

// ================================================================================================
  typedef struct packed {

    cafu_common_pkg::t_cafu_axi4_wr_addr_ready   awready;
    cafu_common_pkg::t_cafu_axi4_wr_data_ready    wready;

        logic [MC_AXI_WRC_ID_BW-1:0]           bid;
        cafu_common_pkg::t_cafu_axi4_resp_encoding   bresp;
        logic                                  bvalid;
        logic [MC_AXI_WRC_USER_BW-1:0]         buser;
  } t_from_mc_axi4_bchan;

  localparam FROM_MC_AXI4_BCHAN_BW = $bits(t_from_mc_axi4_bchan);

  // ================================================================================================
  typedef struct packed {
    logic [MC_AXI_RRC_ID_BW-1:0]           rid;
    logic [MC_AXI_RRC_DATA_BW-1:0]         rdata;
    cafu_common_pkg::t_cafu_axi4_resp_encoding   rresp;
    logic                                  rvalid;
	  logic                                  rlast;
    t_rd_rsp_user                          ruser;
  } t_mc_rdrsp_axi4;

// ================================================================================================
endpackage : ed_mc_axi_if_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aI+B1eKmxN3FUIhpL1a1qzcsVLLKJBCXFGJmWe1S92YB7rdbSPa4gCwY5+4kUDb6IojN4muj0PN+sTVTonSR4H0S+a5AkDbFPoEfzH2uYBy52IfAlKFF9rDYxD2YtFlp3TbKJR8oEAojnOFfOk/88xRKQcuDxhivwjH/Jtz5aChuOhZq0VT5XB80bicixxvTMCXoJg1u7LT7yi1jOKgp5sEDrjMEQ8GYQs42qfwWGdAAFyNlvoi+zeCVF+iJRQgbPG1X2SR8iyLkAZ/mfeJ16vE9KqZNsymaYdSIzree+TnJDTkFjC2KHKOOZxA51gEN9PuVeWRLRB1p1DTomUshO3VYHJlTEjUMhKM/gjkTzvJRdHDgiJBq2+CwmG6yF0cdviyAJU/tPp+EO6YaMAftTHj6jj/d6Om/7Ev4L878N8gToFE/KN/EpqaGAn5LX2EFwAKPzwJTB9GlfU+wEMcCmXa7RKosGrZnEilWtQcoxDLf5uL97NhWs+d3W87mFyCRHFZIYzThmpGUpz8S5yoChKxeVuX0exr3XwjJquC3W0vBTZ8Q9ut4i9wp7jF/MEG2hAOcd/2WNkcG1C+uVeyTR0kTUN5PCfzolzlgm6lmFmhQ8BAVqWfQ9kxzkdCgO4nIchDZLhHZCxYfUa95b9iSdoAomDPWw+Jbe/846odqeQxd7c1HhlrylT31DLpEJzB6kaDbPSFAxOy7NQxbaKLkHfcckEtcJzyBtQiHQfmprVFfE+2z45m5eq3/2bxFGapPk0kbkqEXmX1wpSWzF/SPfTx"
`endif