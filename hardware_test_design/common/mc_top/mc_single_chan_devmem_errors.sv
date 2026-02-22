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

module mc_single_chan_devmem_errors
  import ddr_mc_top_common_pkg::*;
  import mc_ecc_pkg::*;
(
  input logic ipclk,
  input logic ipresetn,
  input logic rchan_rspfifo_rdempty_ipclk,

  input ddr_mc_top_common_pkg::t_rchan_rspfifo_data     rchan_rspfifo_dout_data_intf_ipclk,
  input ddr_mc_top_common_pkg::t_rchan_rspfifo_ecc      rchan_rspfifo_dout_ecc_intf_ipclk,

  output logic [mc_ecc_pkg::MC_ERR_CNT_WIDTH-1:0] mc_err_cnt_ipclk
);

// ================================================================================================
/* only want to collect ECC to be counted if rchan_cdc_rspfifo rdempty is low
*/
logic collect_ecc;

assign collect_ecc = rchan_rspfifo_dout_data_intf_ipclk.read_resp_valid
                   & ~rchan_rspfifo_rdempty_ipclk;

// ================================================================================================
/* Add register stage for timing
*/
mc_ecc_pkg::mc_devmem_if_t     mc_devmem_if_ipclk;

always_ff @(posedge ipclk)
begin
   mc_devmem_if_ipclk.RdDataValid     <= (~ipresetn | ~collect_ecc) ? 1'b0 : rchan_rspfifo_dout_data_intf_ipclk.read_resp_valid;
   mc_devmem_if_ipclk.RdDataECC.Valid <= (~ipresetn | ~collect_ecc) ? 1'b0 : rchan_rspfifo_dout_ecc_intf_ipclk.ecc_err_valid;
   mc_devmem_if_ipclk.RdDataECC.DBE   <= (~ipresetn | ~collect_ecc) ? 8'd0 : rchan_rspfifo_dout_ecc_intf_ipclk.ecc_err_fatal;
   mc_devmem_if_ipclk.RdDataECC.SBE   <= (~ipresetn | ~collect_ecc) ? 8'd0 : ( rchan_rspfifo_dout_ecc_intf_ipclk.ecc_err_corrected
                                                                             | rchan_rspfifo_dout_ecc_intf_ipclk.ecc_err_syn_e );
end

// ================================================================================================
mc_devmem_top    mc_devmem_top_inst
(
        .clk          ( ipclk ),
        .rst          ( ~ipresetn ),
        .mc_devmem_if ( mc_devmem_if_ipclk ),  
        .mc_err_cnt   (   mc_err_cnt_ipclk )   
);

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3TjBsWIjOVO9JeF/wO1ekKk1KFVqbTd0fddup7YC9odipVgulynEZrsbemqBsoUKOoAIz+sRZKHbsTnw6+yh1x7Rp2uLf5EHXmEfDGDrDEy9j6o7JYIjGDiIQeTACCkP/0h7vJy4j5mb6aiGRZ0rtGCmsP6+Z0xKpKbmJNTWqxC7wQAVkx4y4FfQlpCOk15Kq5la8FvK4u+K5Xbne6rCx0w/VTO9SynF2QllCLu9h9qpxvqZLt/bcsTmM8S72bdOqYPOcZnm58DF0PDox4VF1mt74hSYePHiJlfd9EXBQfVIhliJSgbodCJwiPxAJo61oYTc2GQS107JctWWHkNBGT2ICmf9Tx61DEE1y3Nc+g98IlgJ9D+hgsL2eCdXjvOhvvwg4gLKoBDmfHn6X6K8DaE+jL/2eBGYmAV/8ICFL5Sognx6aEq9acj6BQT9g8DLRZMuNUocBNCRd0ZrxKLMD7wvAMuY9j5BMWZh73y/Z5byJGG0s6Od/yS5imgUSLY/KlfEleHqDd9+2AjQHsTXGzKB+YGPfjBs2avlnv3KK+GndUlDK6XLOLYakQj6XFOTJ785XsVg2vjiWWhg9c8beTZnN1NJKhcxEt4t+GoQxdH0poIs3CuJBIcvRaEc/bfe+zDGZs6I/KInVVHdOF4KW0F2ghD4cRerqgyk8GeGTog5BcM1WZcK28TqmCj5MJFnrfGcZLGeV2vkceQLB8b51sVOpKhVrzOOcHqWR+n0l3P3sWk26XqlTfWnNPwaikn0DIAao1NK2tTzndfJVTWSQmi"
`endif