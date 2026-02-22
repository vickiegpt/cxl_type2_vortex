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
/*
  Description   : FPGA CXL Compliance Engine Initiator AFU
                  Speaks to the AXI-to-CCIP+ translator.
                  This afu is the initiatior
                  The axi-to-ccip+ is the responder
*/

`ifndef CCV_AFU_PKG_VH
`define CCV_AFU_PKG_VH

package ccv_afu_pkg;

//-------------------------
//------ Parameters
//-------------------------
localparam CCV_AFU_DATA_WIDTH   =   512;
localparam CCV_AFU_ADDR_WIDTH   =   52;


typedef struct packed {
  logic illegal_base_address;
  logic illegal_protocol_value;
  logic illegal_write_semantics_value;
  logic illegal_read_semantics_execute_value;
  logic illegal_read_semantics_verify_value;
  logic illegal_pattern_size_value;
} config_check_t;


//-------------------------
//------ Parameters for Alg7
//-------------------------
typedef struct packed {
  logic [8:0]   axi_id;
  logic [51:0]  real_address;
  logic [511:0] extended_real_pattern;
} alg7_fifo_data_t;

localparam ALG7_FIFO_DATA_BW = $bits(alg7_fifo_data_t);
localparam ALG7_FIFO_DEPTH = 16;
localparam ALG7_FIFO_PTR_BW = $clog2(ALG7_FIFO_DEPTH);

//-------------------------
//------ write semantics cache
//------ CXL 2.0 Spec - Table 268
//-------------------------
typedef enum logic [3:0] {
   CCVAFU_WR_CACHE_USE_ITOMWR     = 'd0,  // Dirty Writes use ItoMWr, Clean Writes use CleanEvict
   CCVAFU_WR_CACHE_USE_MEMWR      = 'd1,  // Dirty Writes use MemWr, Clean Writes use CleanEvictNoData - not supported
   CCVAFU_WR_CACHE_USE_DIRTYEVICT = 'd2,  // Dirty Writes use DirtyEvict
   CCVAFU_WR_CACHE_USE_WOWRINV    = 'd3,  // Dirty Writes use WOWrInv
   CCVAFU_WR_CACHE_USE_WOWRINVF   = 'd4,  // Dirty Writes use WOWrInvF
   CCVAFU_WR_CACHE_USE_WRINV      = 'd5,  // Dirty Writes use WrInv
   CCVAFU_WR_CACHE_USE_CLFLUSH    = 'd6,  // Dirty Writes use ClFlush - not supported
   CCVAFU_WR_CACHE_USE_ANY        = 'd7   // Dirty Writes/Clean Writes can use any of CXL.cache supported opcodes. Device implementation specific
} t_ccvafu_wr_semantics;






endpackage: ccv_afu_pkg

`endif  // `define CCV_AFU_PKG_VH
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdaXJVKYReEASFXZFr9KkQrarV+/kiLy39VRJu9P7d9y2GvNtAOQtVsuxcniPNjKRyvI7hAJtCi/MRkS+gqydkuA9v46wQhAG3ajRiVzJsT8l7jyx/4W9kHyyToMT4Kd1wJ5xd0lTvigPgsMk0/1uIURwR6AuHICc4bGbta35OQ0Cyov9/Ru42qc82x8OV0jCulLQhGbnkL4DhBoi5cJZfKjVJpKv0AUBJKSasweGYML4zBeSo2FIBh73VwzAQr9TsRXIz5FNbh0jA6gwPhY99tQ7JY4YjBLMwSTpk7ufeBC7Hk5Q4HgZ/4sI67XwVRnKiBOLNmktyQAdcZN5bxaW91+ptv9TQB29eBjJYlIvCFJ9VBDL0y9X+DWcStIgs0CRFjaI33Hdde6+RJhFfYcm3CTruWcsytkruWYyzL9R5yKq3LKt98PgEwlNnQ+oD0zrOIRMWPUEDDn5NLDpR6gd/+XLTUCG8pm/293GtemZtLK6A1JgB14aRxPoDG+1UGx5fJ7b5c9vkLlGyG37hz6Fb1EhhNUKJpV2/YQxIhkxJrocUOLHdc05lVA8YjRILP/gmFEcebNiW86WEO8wRK8KngVpzhC1YIcJnEnbcqGEKyHrS7Z/jKIdxfpIKVb8IFOSvqmOR5k0DXhuI+YH6EPjiGN4UUwpNp/n/nOTdG9VuzyGou6NzeXigCk/aAO9SjgKH7PpYKoydsg7MkeYyF2CC8+95Ngr9hAVfxikiycUZNXkJ9Z5EczQj7nhpNuBWSEi3m5fo5YesNjBnNs0B3oMbM"
`endif