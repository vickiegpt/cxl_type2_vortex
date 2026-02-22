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
/*
  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder
*/

`ifndef CCV_AFU_ALG1A_PKG_VH
`define CCV_AFU_ALG1A_PKG_VH

package ccv_afu_alg1a_pkg;

//-------------------------
//------ Parameters
//-------------------------

typedef enum logic [1:0] {
  MODE_IDLE        = 2'd0,
  MODE_EXECUTE     = 2'd1,
  MODE_VERIFY_SC   = 2'd2,
  MODE_VERIFY_NSC  = 2'd3
} alg1a_mode_enum;

typedef enum logic [3:0] {
  AXI_WR_IDLE            = 4'd0,
//  AXI_WR_WAIT_TIL_4      = 4'd1,
  AXI_WR_WAIT_TIL_NOT_EMPTY = 4'd1,
  AXI_WR_FIRST_POP       = 4'd2,
  AXI_WR_FIRST_AWVALID   = 4'd3,
  AXI_WR_FIRST_AWREADY   = 4'd4,
  AXI_WR_NEXT_AWREADY    = 4'd5,
  AXI_WR_NEXT_AWVALID    = 4'd6,
  AXI_WR_LAST_AWREADY    = 4'd7,
  AXI_WR_LAST_AWVALID    = 4'd8,
  AXI_WR_LAST_WREADY     = 4'd9,
  AXI_WR_LAST_WVALID     = 4'd10,

  AXI_WR_FIRST_WAIT              = 4'd11,
  AXI_WR_FIRST_AWREADY_PLUS_POP2 = 4'd12
} alg1a_exe_axi_write_fsm_enum;

endpackage: ccv_afu_alg1a_pkg
`endif
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcfF05N+R1n8gTIYHl2IsESFnMCzklxadb1yP+kyQ0gBsNTlwyOETEcFy7OrPI5Ix0oJFYFA2aL0y06LaOVfHxEfWWNEjd+DmzqrI2d1wCIVvBVDvvqcMIiFg7himREUor3E2gc+koV17Uci4PH9ngv+lDLXCLZ1X2NTI9IgOuStyEIbA8vO2kg84+16eVOMrYqvGQec3Ped7pQzWECNUpr+VpacgZ8QXQYj/cc1JmddSR65VD0+PRTw4Q7WcYhZtc3bqbyS5bipeqKS7AR9QUIEYz8+aRZGDY7PjXaTqe5rKLCg3sVV0lOYYBE75fGNpRJMjXy4UstemjJob3amGnMvbWj51mMlVfIQ0xdORmkLc9Qq3a87gKC/MP825S0qLs9i0Et3l7RVvAOYAC5ZRejRK5tABBnNtGegDKpHyttTlfjEhkeatISPpshURTz2KeA0RcdFAKfuklRj6lsIPV44RPP+bmi3swr5d+PqBovwd4Rtw23lG0e855gJA0xZrl2pPvSLMZ4rFEa5XAqQ6RkSUsk3XeSOOv57R6DSB44PlFjNHRuUJebwwGHbzLg6aQGh2jPS532pwjda/ZCbx5CuTSPZgZvMnhadAql8dS3BEZ31sCaAp0LOPnC8Hg36beyu8Zh5qePsbp7zUWnl4LXkNjNx946f77zBT4ONBjbEQvR260DtyeoJ0knLSOxdRx3atuVcs5PIx+xxNJkjuPFrGXAfXQan7DZ4NDn7tY5haVPdGMDzcvfN7mhZ2YNSkv6SWFKDY127+J03dVnNDtvB"
`endif