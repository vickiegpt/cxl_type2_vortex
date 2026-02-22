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

module mwae_error_injection_regs
    import ccv_afu_pkg::*;
//   import ccv_afu_cfg_pkg::*;
   import tmp_cafu_csr0_cfg_pkg::*;
(
  input clk,
  input reset_n,

  `ifdef INCLUDE_POISON_INJECTION
         input [2:0] algorithm_reg,
         input       force_disable_afu,
         input       i_cache_poison_inject_busy,
  `endif

  output tmp_cafu_csr0_cfg_pkg::tmp_new_DEVICE_ERROR_INJECTION_t   new_device_error_injection_reg
);

logic cache_poison_busy;

`ifdef INCLUDE_POISON_INJECTION
  always_ff @( posedge clk )
  begin
         if( reset_n == 1'b0 )           cache_poison_busy <= 1'b0;
//    else if( algorithm_reg == 'd0 )      cache_poison_busy <= 1'b0;
    else if( force_disable_afu == 1'b1 ) cache_poison_busy <= 1'b0;
    else                                 cache_poison_busy <= i_cache_poison_inject_busy;
  end
`else
      assign cache_poison_busy = 1'b0;
`endif

assign new_device_error_injection_reg.CachePoisonInjectionBusy = cache_poison_busy;
//assign new_device_error_injection_reg.MemPoisonInjectionBusy   = 1'b0;
//assign new_device_error_injection_reg.IOPoisonInjectionBusy    = 1'b0;
//assign new_device_error_injection_reg.CacheMemCRCInjectionBusy = 1'b0;

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tce7guEyhP/RayyEcXgUQAJHUGZm3buyCasP3Jyo/xlDxws4/0yAsptYQqE13Ayq9mjH0VzB3RcoNscrUVOA6Wj1GQeiF6DJTTjit9vtvIxpIrixsPxqjdzaA0IBWki4gnqtcUt8bv1IJ3rkGs02z1rn57pYUXgMbZ1HmNUQJGcgqdlqMxX2jtYSc4P5j58S5+i9+FoZPc6IK/Pw7rhxR86h2JKdFJRqZ5GteoY+n9SRXUfikRqAPcFELwi8Fn9P3YpRowZOaod4nCPp5mxYd1X3r//a2KXreHfVkX+JB8IsiPiZBRQdCDJLgasmvklk/ExBD1oSCksNtm264ZsTZO0Q0KYKhC0EzKAv0EwdPB2wmSUqlnPpdLNClbaBW2wSrcRsWETPRD2HUXaw8VzKRH9dr8/bposaf1W4QMo42I576ZFrxyMNamgHtNb6mc3xebw4SoUFiD5yYDPoN02eTbgGA9Q1eWeYVRQiyIHJZ7BgSTcEMOohLzJ7Xt9Xu9bTA1x/zk70VN6xepGqWciz6TSnNpxCAJPvmChaEN9rFxaQ+KG0Zhzu4vkmPjCmLK5IU3A74CrXvDSFQy3Mwl3tfTItI9pYei734h5Flx9rhzI94XatKYN8oNx7F1Ao70l009i6QXMPYIvs9xdc18bLrToWSvYnf1iXZg03oQFNhuttALc9EhvZURs3KUeYiJRI0OqbALj+zgH9AxhOGTs+zcRMVS5aOdN6ISCDv/dc3A+2d14yzl0JskFk3OQjUXl9JLJQsqDoXdOcwot2qwgiCEim"
`endif