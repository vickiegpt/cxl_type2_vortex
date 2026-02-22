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

module mc_single_chan_hdm2ip_axi_resp_chans
  import ddr_mc_top_common_pkg::*;
(
  input logic ipclk,
  input logic ipresetn,  // active low
  input logic i_bchan_rspfifo_rdempty_ipclk,
  input logic i_rchan_rspfifo_rdempty_ipclk,
 
  input ddr_mc_top_common_pkg::t_bchan_rspfifo_data   i_rspfifo2ip_new_write_resp_ipclk,
  input ddr_mc_top_common_pkg::t_rchan_rspfifo_data   i_rspfifo2ip_new_read_resp_ipclk,
 
  output logic o_toMC_hdm2ip_axi_bready,  // active high - IP ready for write responses
  output logic o_toMC_hdm2ip_axi_rready,  // active high - IP ready for read  responses
 
  /* External MC_TOP <--> BBS - write response channel
   */
  output logic                                                       hdm2ip_aximm_bvalid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0]   hdm2ip_aximm_bid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_USER_BW-1:0] hdm2ip_aximm_buser,
  output logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_bresp,
   input logic                                                       ip2hdm_aximm_bready,  
 
  /* External MC_TOP <--> BBS - read response channel
   */
  output logic                                                       hdm2ip_aximm_rvalid,
  output logic                                                       hdm2ip_aximm_rlast,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0]   hdm2ip_aximm_rid,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_DATA_BW-1:0] hdm2ip_aximm_rdata,
  output logic [ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_USER_BW-1:0] hdm2ip_aximm_ruser,
  output logic [ddr_mc_top_common_pkg::MCTOP_AFU_AXI_RESP_WIDTH-1:0] hdm2ip_aximm_rresp,
   input logic                                                       ip2hdm_aximm_rready
);

// ================================================================================================
/* handle the axi response channels ready signals
 */
assign o_toMC_hdm2ip_axi_bready = ip2hdm_aximm_bready;
assign o_toMC_hdm2ip_axi_rready = ip2hdm_aximm_rready;

// ================================================================================================
/* handle the axi response channels signals -> writes
 */
always_ff @( posedge ipclk )
begin
    hdm2ip_aximm_bvalid <= (~ipresetn | i_bchan_rspfifo_rdempty_ipclk) ? 1'b0 : i_rspfifo2ip_new_write_resp_ipclk.write_resp_valid;
	
    hdm2ip_aximm_bid    <= i_rspfifo2ip_new_write_resp_ipclk.write_id[ddr_mc_top_common_pkg::MCTOP_MC_AXI_WRC_ID_BW-1:0];
    hdm2ip_aximm_buser  <= i_rspfifo2ip_new_write_resp_ipclk.write_user;
    hdm2ip_aximm_bresp  <= i_rspfifo2ip_new_write_resp_ipclk.write_axi_resp;
end

// ================================================================================================
/* handle the axi response channels signals -> reads
 */
always_ff @( posedge ipclk )
begin
    hdm2ip_aximm_rvalid <= (~ipresetn | i_rchan_rspfifo_rdempty_ipclk) ? 1'b0 : i_rspfifo2ip_new_read_resp_ipclk.read_resp_valid;
    hdm2ip_aximm_rlast  <= (~ipresetn | i_rchan_rspfifo_rdempty_ipclk) ? 1'b0 : i_rspfifo2ip_new_read_resp_ipclk.read_resp_valid;
    hdm2ip_aximm_ruser  <= (~ipresetn | i_rchan_rspfifo_rdempty_ipclk) ? 1'b0 : i_rspfifo2ip_new_read_resp_ipclk.read_poison;	
	
	
    hdm2ip_aximm_rid    <= i_rspfifo2ip_new_read_resp_ipclk.read_id[ddr_mc_top_common_pkg::MCTOP_MC_AXI_RRC_ID_BW-1:0];
    hdm2ip_aximm_rdata  <= i_rspfifo2ip_new_read_resp_ipclk.read_data;
    hdm2ip_aximm_rresp  <= i_rspfifo2ip_new_read_resp_ipclk.read_axi_resp;
end

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "FXSRKOAKBLPA886OFzf7z9ske4ySKJSsErbyEmoApfVmAfyIoA1yGDkAU9G+2VpYKCLpOfnDV9Q6rGOzd2Xltl4WT/Q93M4BwRgsnRFNqW0YAarhezZ8nvZYJ2RlZh4HO5i818Bzt0CgTQ3O7fD/eLNzlMGc37uMc2jvocZpEPZpD34nPMDa8zICcNHV7niQnbhXiboQD1qVAMpc2B+R+yR7YOwvGx7RE0AbZ/CEuvT2DK2JTH+Zly0qwNnfgN9Hgmm+ZqXj/rYWR9NjAv4tZN7MlZ5M3pd8cyA6xnlznc4UCYtvTVzz8zhA/7N1CKwV97ai5vbsGBud7gnUwki5ETm2JNk50npoAKnT4Hu6ZT5LiO1waFMVQXQDFT+gH+41+L/dWtaeYNbzQuvkbgQ8e51dGvjt4xpyMmwx3ntpm3Ee2GaZiMUMr0qf6+U/CTl6SACDebKwi2biHFaOAH8E+UqF1B77nEO1Q9VmuS0R4aXLiQuB0Hpq/w+na76CtO5a9XhXUvureC9rXve8WMBhEujY5RxgVKcC1QtN+A1ogaagBij4Mzf/e5MGtNOGSBj2xtLpVmDqqyQlXjRk9uo/FOjI4QLHe3UFW9KzIA3CyCLdQHY9LIfHIXr46cU6xOEkRzq5FAjpqEYcpqs954fMczv35VV2JYITlsWtEpBU73qf6O8MPnyyNkEpgZhKRyu7MPfB5Hio3IL7FZ/ZTH3fE7oaD8JQ0WpChvZbkrO9grX6QFwAOPRJqnjtPiZ2c1G+/xufv6q9RBFNEdb0phYbcTxhw4c3Oe+JQUxg04w/UQZIoeWiZDcj2sd4bHnVqPcrmUcrJ5oCzDCf1bQXRQq3T7hqwspz5mAuXn7cEjnJB1m4TjdQV9YAxuHa/g6o1qR0sc4QjQB0zHxHL1Me6tIp9cngdyrXzvkrw5GwaeWILUKT2oMwcDED2pp9tsPpl04WN7mV8cRcbUEU8IRAVzyAL+lYpsTeXJ6oRcHp25ajYDG7Ijlcs3oh0GzOt5K6DJTz"
`endif