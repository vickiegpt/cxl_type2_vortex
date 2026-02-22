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


///
///  INTEL CONFIDENTIAL
///
///  Copyright 2022 Intel Corporation All Rights Reserved.
///
///  The source code contained or described herein and all documents related
///  to the source code ("Material") are owned by Intel Corporation or its
///  suppliers or licensors. Title to the Material remains with Intel
///  Corporation or its suppliers and licensors. The Material contains trade
///  secrets and proprietary and confidential information of Intel or its
///  suppliers and licensors. The Material is protected by worldwide copyright
///  and trade secret laws and treaty provisions. No part of the Material may
///  be used, copied, reproduced, modified, published, uploaded, posted,
///  transmitted, distributed, or disclosed in any way without Intel's prior
///  express written permission.
///
///  No license under any patent, copyright, trade secret or other intellectual
///  property right is granted to or conferred upon you by disclosure or
///  delivery of the Materials, either expressly, by implication, inducement,
///  estoppel or otherwise. Any license under such intellectual property rights
///  must be express and approved by Intel in writing.
///

`ifndef CFGPKG_v12
`define CFGPKG_v12

package ed_rtlgen_pkg_v12;

function automatic logic [7:0] f_sai_sb_to_cr (
   input logic [7:0] sai_sb
);
   if (sai_sb[0] == 1) begin 
      f_sai_sb_to_cr =  ({2'b00, 3'b000, sai_sb[3:1]});
   end
   else begin 
      if (sai_sb[7:1] > 7'b0000111 && sai_sb[7:1] < 7'b0111111) begin
         f_sai_sb_to_cr =  ({2'b00, sai_sb[6:1]});
      end
      else begin 
         f_sai_sb_to_cr = ({2'b00, 6'b111111});
      end
   end  
endfunction : f_sai_sb_to_cr

// @@copy for common_afu_pkg@@start
typedef enum logic [3:0] {
    MRD   = 4'h0,
    MWR   = 4'h1,
    IORD  = 4'h2,
    IOWR  = 4'h3,
    CFGRD = 4'h4,
    CFGWR = 4'h5,
    CRRD  = 4'h6,
    CRWR  = 4'h7
} cfg_opcode_t;

localparam CR_REQ_ADDR_LEN = 48;
localparam CR_REQ_ADDR_HI = 47;

localparam CR_MEM_ADDR_HI = 47;
typedef struct packed { // 48
    logic [CR_MEM_ADDR_HI:0] offset;
} cfg_addr_mem_t;

localparam CR_IO_ADDR_HI = 15;
typedef struct packed { // 32+16=48
    logic [31:0] pad;
    logic [CR_IO_ADDR_HI:0] offset;
} cfg_addr_io_t;

localparam CR_CFG_ADDR_HI = 11;
typedef struct packed { // 36+12=48
    logic [35:0] pad;
    logic [CR_CFG_ADDR_HI:0] offset;
} cfg_addr_cfg_t;

localparam CR_MSG_ADDR_HI = 15;
typedef struct packed { // 32+16=48
    logic [31:0] pad;
    logic [CR_MSG_ADDR_HI:0] offset;
} cfg_addr_msg_t;

localparam CR_CR_ADDR_HI = 15;
typedef struct packed { // 32+16=48
    logic [31:0] pad;
    logic [CR_CR_ADDR_HI:0] offset;
} cfg_addr_cr_t;

typedef union packed { // All structs must be 48
    cfg_addr_mem_t mem;
    cfg_addr_io_t  io;
    cfg_addr_cfg_t cfg;
    cfg_addr_msg_t  msg;
    cfg_addr_cr_t  cr;
} cfg_addr_t;

typedef struct packed { 
    logic        valid;
    cfg_opcode_t opcode;
    cfg_addr_t   addr;
    logic  [7:0] be;
    logic [63:0] data;
    logic [7:0] sai;
    logic  [7:0] fid;
    logic [2:0] bar;
} cfg_req_64bit_t;

typedef struct packed {
    logic        read_valid;
    logic        read_miss;
    logic        write_valid;
    logic        write_miss;
    logic        sai_successfull;
    logic [63:0] data;
} cfg_ack_64bit_t;
// @@copy for common_afu_pkg@@end

// for 32bit bus
typedef struct packed { 
    logic        valid;
    cfg_opcode_t opcode;
    cfg_addr_t   addr;
    logic  [3:0] be;
    logic [31:0] data;
    logic [7:0] sai;
    logic  [7:0] fid;
    logic [2:0] bar;
} cfg_req_32bit_t;

typedef struct packed {
    logic        read_valid;
    logic        read_miss;
    logic        write_valid;
    logic        write_miss;
    logic        sai_successfull;
    logic [31:0] data;
} cfg_ack_32bit_t;

// for 8bit bus
typedef struct packed { 
    logic        valid;
    cfg_opcode_t opcode;
    cfg_addr_t   addr;
    logic  [0:0] be;
    logic  [7:0] data;
    logic [7:0] sai;
    logic  [7:0] fid;
    logic [2:0] bar;
} cfg_req_8bit_t;

typedef struct packed {
    logic        read_valid;
    logic        read_miss;
    logic        write_valid;
    logic        write_miss;
    logic        sai_successfull;
    logic  [7:0] data;
} cfg_ack_8bit_t;

// ==========================================================================
// Merge ack from multiple CR banks
typedef struct packed {
   logic treg_trdy; 
   logic treg_cerr;   
   logic treg_rdata;
} cr_bank_ack_t;

// ==========================================================================

endpackage: ed_rtlgen_pkg_v12

`endif
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "wJaiUQVZA/rvovcoNOJGlBO6DCGE7ABmqgUXUj8zOr5pW/RmuJpy7vfokaAGTtwq7+XXhIASoNO8/1w9gnglJEDZAsQE6bSIxKANtOiBndjIysDudBOHQoche6DbKrf0181Y+vNClaBJNBy9zgI5I3EE0VBTuEeshhmDbDjf57ZnCzhiTrhBeqKS6mAbx69qZGB02C/X/b0jY2bRWmm+DMoF7+OPN51M+D5t4T3g+aJyHSS9BLW0BffxhtZFiRJdOyadkByhUJFaLqRPfTuKR5+7EsblU/l7YQ5XRkxNiACggVyQlsvl7/iRZPMO/yJG0UzWCP/VPk1r9yB8rk9JsYwyzLU3mOxvtDSZS4q5M7FLNGJi+vjXZD4dH7x8+6Y18X3T7nGt6PPlds/Pa8TW6xXFkR9B6Hl3+5mD0QxeblpVCTjqaKoFOb2+emwDGCFM4JGvZn8joaJ5MbsVHNZYnXFK2CbqJxh6FnTwfz3M0u9sI5WAvdzDN7qUCLFFDNnOhTe521NYMfhAJrzuZa9DpQrlhV/XFs75rEt0chpKiaIUQpJJENW9m92M2dGziBT2FWt/9jsClm1wWRv4V+3g+b6Q63q2kL7ess4A3jusaPgU6PNc+Am/KS9cvY8+M/AnA0HXss9UZzpTV2BqOGZiZJLaBsmQb8gWSAzNCddfpxwtVomOR50EDoyD2ceFWTRiAAIwFPpiL3/bzFRMVOOOpiarvjNsyEfvVd1mGhTcufXqiUII11zTe43Wjjz+MkWWJ2y4UMUzfRXBqoERQ1La2c56IVOnbo0YBgA9VMzzq4BFla5ig0OUdpwtOf9AbmrNGPWGY3d4FyJhBD9cHtRobV/pnwTxNH2N0MK1zOj5/L/jGWfdFp8bKGjUTjcVz4mfR4SMZPD+Fy0l2zKl/Fe/F4io94oTbNSBo29Mj2uMLI0tRjXgOyON1aol6gj4iztG8xCfmXddHo1QOLNRqRn5oUn0yk+qEIZ6H2OlVutBJf4rN9u8hfQ5iTHkFViwcMLs"
`endif