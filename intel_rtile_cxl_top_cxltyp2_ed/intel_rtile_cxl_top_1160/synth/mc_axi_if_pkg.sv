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

package mc_axi_if_pkg;
  import afu_axi_if_pkg::*;  // import to use protocol specific enumuration structs
  import cxlip_top_pkg::*;

// ================================================================================================
 /* structs for bit widths
  
    APRIL 14 2023 - these are set based on Darren's current CXL IP HAS draft ch3.3 values
 */
// @@copy for common_mctop_pkg@@start
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
    afu_axi_if_pkg::t_axi4_wr_resp_ready   bready;
    afu_axi_if_pkg::t_axi4_rd_resp_ready   rready;
	
	logic [MC_AXI_WAC_ID_BW-1:0]                 awid;
	logic [MC_AXI_WAC_ADDR_BW-1:0]               awaddr;
	logic [MC_AXI_WAC_BLEN_BW-1:0]               awlen;
	afu_axi_if_pkg::t_axi4_burst_size_encoding   awsize;
	afu_axi_if_pkg::t_axi4_burst_encoding        awburst;
	afu_axi_if_pkg::t_axi4_prot_encoding         awprot;
	afu_axi_if_pkg::t_axi4_qos_encoding          awqos;
	logic                                        awvalid;
	afu_axi_if_pkg::t_axi4_awcache_encoding      awcache;
	afu_axi_if_pkg::t_axi4_lock_encoding         awlock;
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
    afu_axi_if_pkg::t_axi4_burst_size_encoding   arsize;
    afu_axi_if_pkg::t_axi4_burst_encoding        arburst;
    afu_axi_if_pkg::t_axi4_prot_encoding         arprot;
    afu_axi_if_pkg::t_axi4_qos_encoding          arqos;
	logic                                        arvalid;
    afu_axi_if_pkg::t_axi4_arcache_encoding      arcache;
    afu_axi_if_pkg::t_axi4_lock_encoding         arlock;
    logic [MC_AXI_RAC_REGION_BW-1:0]             arregion;
    logic [MC_AXI_RAC_USER_BW-1:0]               aruser;
  } t_to_mc_axi4;
  
  localparam TO_MC_AXI4_BW = $bits(t_to_mc_axi4);
  
// ================================================================================================
  typedef struct packed {
    afu_axi_if_pkg::t_axi4_wr_addr_ready   awready;
    afu_axi_if_pkg::t_axi4_wr_data_ready    wready;
    afu_axi_if_pkg::t_axi4_rd_addr_ready   arready;
	
	logic [MC_AXI_WRC_ID_BW-1:0]           bid;
	afu_axi_if_pkg::t_axi4_resp_encoding   bresp;
	logic                                  bvalid;
	logic [MC_AXI_WRC_USER_BW-1:0]         buser;
	
	logic [MC_AXI_RRC_ID_BW-1:0]           rid;
	logic [MC_AXI_RRC_DATA_BW-1:0]         rdata;
	afu_axi_if_pkg::t_axi4_resp_encoding   rresp;
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
        afu_axi_if_pkg::t_axi4_rd_addr_ready   arready;
        logic                                  rd_id_fifo_almost_full;

        logic [MC_AXI_RRC_ID_BW-1:0]           rid;
        logic [MC_EMIF_AMM_RRC_DATA_BW-1:0]    rdata;
        afu_axi_if_pkg::t_axi4_resp_encoding   rresp;
        logic                                  rvalid;
        logic                                  rlast;
    //logic [MC_AXI_RRC_USER_BW-1:0]         ruser;
        t_rd_rsp_user                          ruser;
  } t_from_mc_axi4_rchan;

  localparam FROM_MC_AXI4_RCHAN_BW = $bits(t_from_mc_axi4_rchan);

// ================================================================================================
  typedef struct packed {

    afu_axi_if_pkg::t_axi4_wr_addr_ready   awready;
    afu_axi_if_pkg::t_axi4_wr_data_ready    wready;

        logic [MC_AXI_WRC_ID_BW-1:0]           bid;
        afu_axi_if_pkg::t_axi4_resp_encoding   bresp;
        logic                                  bvalid;
        logic [MC_AXI_WRC_USER_BW-1:0]         buser;
  } t_from_mc_axi4_bchan;

  localparam FROM_MC_AXI4_BCHAN_BW = $bits(t_from_mc_axi4_bchan);

  // ================================================================================================
  typedef struct packed {
    logic [MC_AXI_RRC_ID_BW-1:0]           rid;
    logic [MC_AXI_RRC_DATA_BW-1:0]         rdata;
    afu_axi_if_pkg::t_axi4_resp_encoding   rresp;
    logic                                  rvalid;
	  logic                                rlast;
    t_rd_rsp_user                          ruser;
  } t_mc_rdrsp_axi4;
// @@copy for common_mctop_pkg@@end

// ================================================================================================
endpackage : mc_axi_if_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aLkHlwOZ1TqYHspHhudnW+cWjOuWlJuw7SaNLziMfaiXWgRVzDyIWejVTYjL4ThwTDNwcRoTYV419MwQRnrRx0xuPVZlQpU2hRmjE5O1kenPmyA1Y4AMunTmFmXRsKl4LyRejmOfmR7d3f0NhiLdaldEkq1+zagvsQgeCSsFPOuMYnXboVWb+Q+VLzS6uO9KiS3vYy6pFo8LKXd2K4yFWW9nq2DoNBCagm4IJIq8X2CGzI9mYCk89K9JrrvMUpd1E/+DWNha/A3dUtWRHLpgGYv8v1yX0UOfheEshayhVB3t0NCuJnqPiCZeyWF1raIJM/kx4zgSw+skf03KCZ1Qp+MFPbL/TY4FZVqw1Y0WRvoBWhnQWilNoo38n/pOLtFUBwL+6IwKD6wodfmy2tIUjbBwXX+ZLMTiue6d2sA8upZf8rhEHMIT/gTL+8FbcFFspIV3Q7si74ovfJiqux/C6R0asJitmDxAtvi9Zz5bEYrqJaBoXwVAfQYZN8V0MgPXDCjwi2leC2xAtHAwH9Q8yCB4sdWQZXEa5iVFbp9opgXdpYkxTEmK/G/LsTgeMG6fg5ZsIS6w/TYshKEONRy1RZhIJmws6vYXnwZQgNlqPgYF9mbXA4Bmfwo5ZmR2Q4r0DK9c4ZFIaOHh9gogrjKf1rLKx9eErUaOakuEELLrlWgydNETjDWsNxw/eaHl9Ymb6a46nmpZDX0sZb0OW1BV4XG+fdnYCm6tBTza7zbjZuFlXlMtvPhj/8OY/53s+Zo5xj6H2I6PcZMtEIDUCPkDXzz"
`endif