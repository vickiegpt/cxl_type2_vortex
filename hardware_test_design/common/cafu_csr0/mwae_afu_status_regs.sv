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

module mwae_afu_status_regs
//   import ccv_afu_cfg_pkg::*;
   import tmp_cafu_csr0_cfg_pkg::*;
   import ccv_afu_pkg::*;
(
  input clk,
  input reset_n,                //  active low
  input i_mwea_top_level_fsm_busy,
  input i_alg_1a_execute_busy,
  input i_alg_1a_verify_sc_busy,
  input i_alg_1a_verify_nsc_busy,
  input i_alg_1b_execute_busy,
  input i_alg_1b_verify_sc_busy,
  input i_alg_1b_verify_nsc_busy,
  input i_alg_2_execute_busy,

  input [7:0]  i_current_loop_number,
  input [3:0]  i_current_set_number,
  input [31:0] i_current_base_pattern,
  input [51:0] i_current_base_address,

  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS1_t device_afu_status_1_reg,
  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_AFU_STATUS2_t device_afu_status_2_reg
);


always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 ) 
  begin
       device_afu_status_1_reg.afu_busy               <= 1'b0;
       device_afu_status_1_reg.alg_execute_busy       <= 1'b0;
       device_afu_status_1_reg.alg_verify_nsc_busy    <= 1'b0;
       device_afu_status_1_reg.alg_verify_sc_busy     <= 1'b0;
       device_afu_status_1_reg.loop_number            <= 'd0;
       device_afu_status_1_reg.set_number             <= 'd0;
       device_afu_status_1_reg.current_base_pattern   <= 'd0;
  end
  else begin
       device_afu_status_1_reg.afu_busy               <= i_mwea_top_level_fsm_busy;
       device_afu_status_1_reg.alg_execute_busy       <= i_alg_1a_execute_busy;
       device_afu_status_1_reg.alg_verify_nsc_busy    <= i_alg_1a_verify_nsc_busy;
       device_afu_status_1_reg.alg_verify_sc_busy     <= i_alg_1a_verify_sc_busy;
       device_afu_status_1_reg.loop_number            <= i_current_loop_number;
       device_afu_status_1_reg.set_number             <= i_current_set_number;
       device_afu_status_1_reg.current_base_pattern   <= i_current_base_pattern;
  end
end

always_ff @( posedge clk )
begin
  if( reset_n == 1'b0 )  device_afu_status_2_reg.current_base_address <= 'd0;
  else                   device_afu_status_2_reg.current_base_address <= i_current_base_address;
end


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcesRj67AL8cIYf5LnVwbzF2Iaj89NyeIyNe0DgSDi1xZ1Jsdyp+1kMSX76z8/9fPru7dMvB1rQdzn8uC/F7rzri+/JIBDUeFO5C7qphr+QCeRe8dUJLfZpCx//tSYIhywu56QoDhJcPZZiSn2kKHVvKw9kedUOggRvak2mNKQo7oPkse5jO0nR9u3YP+yEeaPfEs5XxxSmcz0JwLga3hesLF8ZW/emSVfxyfGmvAUAd8UNvF8hXt/qJ4i7b7snijq3ca68Oq0TZH7/m3XP6/urXwNXXcB2JHl8uwQqOyr1dSECRE3dNSjIyvhk60BrxuSUjKIc236o89uasnupDQ0v4qaehZs7wOEyyebXdEifrHh5/tY/qYe4B39+wnHwwHD1vEDaFSGLlyr5lsa63Bp0zG00LOof0t5ejmdEAerG+1MmJIyz/nleXyRxHsf+NdJ6teg0Y1XV9MTfU/bk/QH0uHN91Y6i9AyzhYocHK0PhvWbqMeee/byP0rVjKa3OfwLSmYaMEe2BsxUmT5ZFWcM211ZR8n5Em3mMvLyn8qWHTMmn1dBG/9I5cvzUkyS3eHJ59pyAguLKSkTrYRMVTIkxSVdIibfpGxnUme+6ZXvSVN/yquKAcPsEWxf6+HM7GHsS3T2J/eCa2PEn88RlBl48rogy/+nQ88tzrVDTBSJkKcrmyEfNlTnCPJbJYX1GRVhgtdwTWuAVr5YMZ1wkMcQoRcrJV3qJuT842AGBu5EdV752VAI8xZUwT5zvyfkkrvYII/yo47bboinuvQPBKeLD"
`endif