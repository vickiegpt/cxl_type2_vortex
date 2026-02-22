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
// Creation Date : Feb, 2023
// Description   : SBCNT/DBCNT 

package mc_ecc_pkg;

// @@copy for common_afu_pkg@@start
typedef struct packed {
    logic [15:0] mc1_status;  // RO/V
    logic [15:0] mc0_status;  // RO/V
} DDRMC_MC_STATUS_t;

typedef struct packed {
    logic  [2:0] reset_needed;  // RO/V
    logic  [0:0] mailbox_if_ready;  // RO/V
    logic  [1:0] media_status;  // RO/V
    logic  [0:0] fw_halt;  // RO/V
    logic  [0:0] device_fatal;  // RO/V
} DDRMC_new_CXL_MEM_DEV_STATUS_t;

localparam MC_STATUS_T_BW      = $bits( DDRMC_MC_STATUS_t );
localparam MEM_DEV_STATUS_T_BW = $bits( DDRMC_new_CXL_MEM_DEV_STATUS_t );
// @@copy for common_afu_pkg@@end

//-------------------------
//------ Dev Mem Interfaces
//-------------------------

 typedef struct packed {
    logic [7:0]                      SBE;
    logic [7:0]                      DBE;
    logic                            Valid;
 } mc_rddata_ecc_t;

  typedef enum logic [1:0] {
    M2S_METAVALUE_INVALID       = 2'b00,
    M2S_METAVALUE_RSVD1         = 2'b01,
    M2S_METAVALUE_ANY           = 2'b10,
    M2S_METAVALUE_SHARED        = 2'b11
  } M2S_MetaValue_e;

  typedef enum logic [1:0] {
    M2S_METAFIELD_META0         = 2'b00,
    M2S_METAFIELD_RSVD1         = 2'b01,
    M2S_METAFIELD_RSVD2         = 2'b10,
    M2S_METAFIELD_NOOP          = 2'b11
  } M2S_MetaField_e;

// @@copy for common_afu_pkg@@start 
localparam  CL_ADDR_MSB = 51;
localparam  CL_ADDR_LSB = 6;
typedef logic [CL_ADDR_MSB:CL_ADDR_LSB]        Cl_Addr_t;
// @@copy for common_afu_pkg@@end 

typedef struct packed {
    logic [255:0]   Data1;
    logic [255:0]   Data0;
} DataCL_t;

typedef struct packed {
        DataCL_t                     Data;
        logic [3:0]                  EventTriggerB;
        M2S_MetaValue_e              MetaValue;
        M2S_MetaField_e              MetaField;
        logic                        Poison;
} dev_mem_rd_data_t;


 typedef struct packed {
    mc_rddata_ecc_t                  RdDataECC;
    logic                            RdDataValid;
 } mc_devmem_if_t;

// @@copy for common_afu_pkg@@start 
 typedef struct packed {
    Cl_Addr_t                        DevAddr;            //46
    logic [32:0]                     SBECnt;             //33
    logic [32:0]                     DBECnt;             //33
    logic [32:0]                     PoisonRtnCnt;       //33
    logic                            NewSBE;          
    logic                            NewDBE;
    logic                            NewPoisonRtn;
    logic                            NewPartialWr;
 } mc_err_cnt_t;

localparam MC_ERR_CNT_WIDTH = $bits( mc_err_cnt_t ); //149;
// @@copy for common_afu_pkg@@end 

endpackage : mc_ecc_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL6CCFlY4EEnNCEuSFFElAKuk7dqttBnqXz9VE08+VX5X2ryrroTKqkxHoPUzQw8Kuuvd8F2VeNXjqWmfvkQKquh5crFtxqO8cku0ISli3a/tePgATq1SJgCdorlufENDansuDd4rlVN20ZrjlrN4xijf7m2L4wSuM7N2xDviH95OnSdNIYR79yg13oJ27px1vw/pvFTLSjKIZmbqNf4YoJOMXKE+S5zVuHizAryIS15qT121RAe4vQtsKS9mj3Wsz7nmIi7BPXS+BEvz7SVfK9HR3ZXu3yx4PS0XOw/K9B5LbVUvyodliJEyzzKZAR1ncjfKEsNAUFG+9cej0g4bsNMnVwcW1FMlpQM65bLoA7wdxBleRM2Xh61meTludCudS73hR+PYE6kdxc7ioVEw/FSVVN2pqieN2nOGWa0tltogaREp8C4tzIPH3XApEvldWCeAhFOdwvr33HEa5h3+/jV2g5lyr7UHNgxLzG0+MrS0l7s+7yKAy4s6D5ybJ336YXfBH+pH3WPtGlP8OzQc9Y4ikZEaGQQRV68nSV0GO38W5sDxEfPKXGGIxbxLtvSsL4snWnYDNoOu0yTanbVvmJgCJl8A/yf8CQsvOu2LKAiWl9SmBSaOdlXIEcVUP54CJmH+UH58TmCV+xwIgVJYDyUz2we+uBEgur3Nd6+tkXRjTulBmQ+kX2Vg+8nyUPc0zMh0Bx3D8Ok9WXpboZQquP23rA1DjadZUGZbT8Dx9jNEbxBMuVTwzutg2t8PfuKTNAqm2dVK0hbms2KADvceySy"
`endif