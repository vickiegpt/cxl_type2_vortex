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


// Copyright 2022 Intel Corporation.
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

module mwae_config_and_cxl_errors_reg
//   import ccv_afu_cfg_pkg::*;
   import tmp_cafu_csr0_cfg_pkg::*;
   import ccv_afu_pkg::*;
(
  input clk,
  input reset_n,                //  active low

  /* signal from mwae_top level fsm
  */
  input i_mwae_top_fsm_set_to_busy,   // active high
  input i_valid_illegal_config,       // active high
  input i_slverr_on_write_response,   // active high
  input i_slverr_on_read_response,    // active high
  input i_poison_on_read_response,    // active high

  input config_check_t   i_config_check_values,

  input unsupported_cache_flush_error,

  /* registers that are RW to hardware
  */
  output tmp_cafu_csr0_cfg_pkg::tmp_new_CONFIG_CXL_ERRORS_t        config_and_cxl_errors_reg
);

logic illegal_base_address;
logic illegal_protocol;
logic illegal_write_semantics;
logic illegal_eread_semantics;
logic illegal_vread_semantics;
logic illegal_pattern_size;

always_ff @( posedge clk )
begin
   if( reset_n == 1'b0 )
   begin
            illegal_base_address      <= 1'b0;
            illegal_protocol          <= 1'b0;
            illegal_write_semantics   <= 1'b0;
            illegal_eread_semantics   <= 1'b0;
            illegal_vread_semantics   <= 1'b0;
            illegal_pattern_size      <= 1'b0;
   end
   else if( i_mwae_top_fsm_set_to_busy == 1'b1 )
   begin
            illegal_base_address      <= 1'b0;
            illegal_protocol          <= 1'b0;
            illegal_write_semantics   <= 1'b0;
            illegal_eread_semantics   <= 1'b0;
            illegal_vread_semantics   <= 1'b0;
            illegal_pattern_size      <= 1'b0;
   end
   else if( i_valid_illegal_config == 1'b1 )
   begin
            illegal_base_address      <= i_config_check_values.illegal_base_address;
            illegal_protocol          <= i_config_check_values.illegal_protocol_value;
            illegal_write_semantics   <= i_config_check_values.illegal_write_semantics_value;
            illegal_eread_semantics   <= i_config_check_values.illegal_read_semantics_execute_value;
            illegal_vread_semantics   <= i_config_check_values.illegal_read_semantics_verify_value;
            illegal_pattern_size      <= i_config_check_values.illegal_pattern_size_value;
   end
   else begin
            illegal_base_address      <= illegal_base_address;
            illegal_protocol          <= illegal_protocol;
            illegal_write_semantics   <= illegal_write_semantics;
            illegal_eread_semantics   <= illegal_eread_semantics;
            illegal_vread_semantics   <= illegal_vread_semantics;
            illegal_pattern_size      <= illegal_pattern_size;
   end
end

`ifdef FLUSHCACHE_NOT_SUPPORTED
      assign config_and_cxl_errors_reg.illegal_cache_flush_call = unsupported_cache_flush_error;
`else
      assign config_and_cxl_errors_reg.illegal_cache_flush_call = 1'b0;
`endif

assign config_and_cxl_errors_reg.illegal_protocol               = illegal_protocol;
assign config_and_cxl_errors_reg.illegal_write_semantics        = illegal_write_semantics;
assign config_and_cxl_errors_reg.illegal_execute_read_semantics = illegal_eread_semantics;
assign config_and_cxl_errors_reg.illegal_verify_read_semantics  = illegal_vread_semantics;
assign config_and_cxl_errors_reg.illegal_pattern_size           = illegal_pattern_size;
assign config_and_cxl_errors_reg.illegal_base_address           = illegal_base_address;

logic poison;

always_ff @( posedge clk )
begin
        if( reset_n == 1'b0 )                    poison <= 1'b0;
   else if( i_mwae_top_fsm_set_to_busy == 1'b1 ) poison <= 1'b0;
   else if( i_poison_on_read_response == 1'b1 )  poison <= 1'b1;
   else                                          poison <= poison;
end

logic slverr_read;

always_ff @( posedge clk )
begin
        if( reset_n == 1'b0 )                    slverr_read <= 1'b0;
   else if( i_mwae_top_fsm_set_to_busy == 1'b1 ) slverr_read <= 1'b0;
   else if( i_slverr_on_read_response == 1'b1 )  slverr_read <= 1'b1;
   else                                          slverr_read <= slverr_read;
end

logic slverr_write;

always_ff @( posedge clk )
begin
        if( reset_n == 1'b0 )                    slverr_write <= 1'b0;
   else if( i_mwae_top_fsm_set_to_busy == 1'b1 ) slverr_write <= 1'b0;
   else if( i_slverr_on_write_response == 1'b1 ) slverr_write <= 1'b1;
   else                                          slverr_write <= slverr_write;
end

assign config_and_cxl_errors_reg.poison_on_read_response  = poison;
assign config_and_cxl_errors_reg.slverr_on_read_response  = slverr_read;
assign config_and_cxl_errors_reg.slverr_on_write_response = slverr_write;

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdJ5Q3RbozB/AFHOR/oeN2SvRMEk4J1CWZoN4ORyNiAtFvdQxa2T+GuiRLhCBv2nO2Ugs8UuRtqSVodX8TM1dvSzOeq8Y7W4TEk45ztumxh+DCqDeGm8Svk7U8ZNsPRpM53wyWsN5PiplBTy40ILbFzHldPz02h9U9HIduts/8nWqvq2EM9Ulggx3po2ciEtipirzxJvUZGqJK6BGtId00VFVCFoImRZJR/3nb7aS44m/qrJwkwxN6vIF3WfCC21/sYhqgFqbcazTxKua0Rkd1BI9lIsVfO2Id8KaTc+wXMdojU/lQcJQ3j8xIVpEeTvlcSfAy6ADjhUNdW3Hv7pkVwUP3kJJeR1avecK9GxIa7uEALFOo5YhjpoNbjPPidkbKf1Y3vxKv3AX8zG2YmRICsdXz3s6J6pJ9GMUi74GhQEFygtAtKG7qoHpUvuku3WcwrdJ/T3WEszz0pa/+Ive+vY787veLPVcX+RL+MTZYwfq+GMCGBemXDP/U/HQpkFvijsWOcjMxrdBZrEQKmbeCOaBYxD4juAbV8qB0yKiETkuO/4ios+MJKXy35KwxpwgOkX0oCtpe98QvmhoRlGAHE+kuIGl3oQ5XMSERNvBt4ta/zd1/G3YigdSl/EPc+JZTWNqbGtJR72FIVRXWCuaH81z1OCCBNlAA/sC1TM+TnxtOP9uGDxlL+/ShHLk7DRTKhMy2kuTnexoazNuyybyg34ROj5XIzgyW0rxKxuuQ+V2b02c1X9affSlRKxCWIMVn2f5XgIETDGEy0xmRFrcTU"
`endif