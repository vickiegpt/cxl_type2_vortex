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


//------------------------------------------------------------
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
//------------------------------------------------------------

import cafu_common_pkg::*;
module intel_cxl_afu_cache_io_demux( 

    input					clk,
    input					rst,

    input					afu_cache_io_select, //afu_cache_io_select == 1 ? select io else cache
    //--to/from afu
    input   t_cafu_axi4_rd_addr_ch                   afu_axi_ar,
    output  t_cafu_axi4_rd_addr_ready                afu_axi_arready,    
    output  t_cafu_axi4_rd_resp_ch                   afu_axi_r,
    input   t_cafu_axi4_rd_resp_ready                afu_axi_rready, 
   
    input   t_cafu_axi4_wr_addr_ch                   afu_axi_aw,
    output  t_cafu_axi4_wr_addr_ready                afu_axi_awready,   
    input   t_cafu_axi4_wr_data_ch                   afu_axi_w,
    output  t_cafu_axi4_wr_data_ready                afu_axi_wready,    
    output  t_cafu_axi4_wr_resp_ch                   afu_axi_b,
    input   t_cafu_axi4_wr_resp_ready                afu_axi_bready,    

    //-- to/from cache
    output   t_cafu_axi4_rd_addr_ch                   afu_cache_axi_ar,
    input    t_cafu_axi4_rd_addr_ready                afu_cache_axi_arready,    
    input    t_cafu_axi4_rd_resp_ch                   afu_cache_axi_r,
    output   t_cafu_axi4_rd_resp_ready                afu_cache_axi_rready, 
   
    output   t_cafu_axi4_wr_addr_ch                   afu_cache_axi_aw,
    input    t_cafu_axi4_wr_addr_ready                afu_cache_axi_awready,   
    output   t_cafu_axi4_wr_data_ch                   afu_cache_axi_w,
    input    t_cafu_axi4_wr_data_ready                afu_cache_axi_wready,    
    input    t_cafu_axi4_wr_resp_ch                   afu_cache_axi_b,
    output   t_cafu_axi4_wr_resp_ready                afu_cache_axi_bready,    

    //-- to/from io
    output   t_cafu_axi4_rd_addr_ch                   afu_io_axi_ar,
    input    t_cafu_axi4_rd_addr_ready                afu_io_axi_arready,    
    input    t_cafu_axi4_rd_resp_ch                   afu_io_axi_r,
    output   t_cafu_axi4_rd_resp_ready                afu_io_axi_rready, 
   
    output   t_cafu_axi4_wr_addr_ch                   afu_io_axi_aw,
    input    t_cafu_axi4_wr_addr_ready                afu_io_axi_awready,   
    output   t_cafu_axi4_wr_data_ch                   afu_io_axi_w,
    input    t_cafu_axi4_wr_data_ready                afu_io_axi_wready,    
    input    t_cafu_axi4_wr_resp_ch                   afu_io_axi_b,
    output   t_cafu_axi4_wr_resp_ready                afu_io_axi_bready

);

    assign afu_io_axi_ar         = afu_cache_io_select ? afu_axi_ar             : 'h0  ;
    assign afu_io_axi_rready     = afu_cache_io_select ? afu_axi_rready         : 'h0  ;
    assign afu_io_axi_aw         = afu_cache_io_select ? afu_axi_aw             : 'h0  ;
    assign afu_io_axi_w          = afu_cache_io_select ? afu_axi_w              : 'h0  ;
    assign afu_io_axi_bready     = afu_cache_io_select ? afu_axi_bready         : 'h0  ;

    assign afu_axi_arready       = afu_cache_io_select ? afu_io_axi_arready     :  afu_cache_axi_arready  ;
    assign afu_axi_r             = afu_cache_io_select ? afu_io_axi_r           :  afu_cache_axi_r        ;
    assign afu_axi_awready       = afu_cache_io_select ? afu_io_axi_awready     :  afu_cache_axi_awready  ;
    assign afu_axi_wready        = afu_cache_io_select ? afu_io_axi_wready      :  afu_cache_axi_wready   ;
    assign afu_axi_b             = afu_cache_io_select ? afu_io_axi_b           :  afu_cache_axi_b        ;

    assign afu_cache_axi_ar      = afu_cache_io_select ? 'h0 : afu_axi_ar       ;
    assign afu_cache_axi_rready  = afu_cache_io_select ? 'h0 : afu_axi_rready   ;
    assign afu_cache_axi_aw      = afu_cache_io_select ? 'h0 : afu_axi_aw       ;
    assign afu_cache_axi_w       = afu_cache_io_select ? 'h0 : afu_axi_w        ;
    assign afu_cache_axi_bready  = afu_cache_io_select ? 'h0 : afu_axi_bready   ;

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzoxhbtHTzhiHnaxYAif5tyX1VBswuX2ZQzGPuEWg21l8eoEg1tjEztfkgX4uEr1y6L5H/XTOL55r2i1KJ+7U3zDwQ697H0+cDWlh7aOhZNZUrQw3OoTrK5eS/UsN4kxAspUWLUk0coqluKSEZYHz2VXbnznFQ15dVRUaCY5d8pmk8l9mJc+YDwBb0u+1sGHbtGx3OD/fc2Fgd6gUq5Af2Ix5rpysOYWR4fD7b1gXDk5HxUKt25QQSX7GEeFoq743Z7X2GR6nj4w225kYfDU343W5INC6O1Pshv4AUyhCrmdyhYpSWwsQ/plSDCx2bugfU4c/5gAepDkensSHXG4gJRs5NUhIBtA8TcozmB19xnkszun0NRPPFfUVmIVehi/79w/t5FGl9PJmR88teRSjulELd66lECMBurBSTAEcPyUtuWeO8MN5WBvinIBRwrnPnVNS1xWcXXxAd82y6rM1KTGREPFjeqwlfv/69sQMnck79TI9xHEBRDHjoDMpc3XS8yWEbVVMH0rtNPPG2vwFjRtSLyLKfeaIhMp9knsd2vv2ls14sDp7dBxXRsWuQiMAyv4UbSmxPr0kjDYQuqc/XEXNT9Evi80NP68A1J5chN6DX7zAq86SXUB8BdIuSZDIn7SffmdcHNGb8WaFsc9b2m9eYirnrBoREf4L0/x+tkzxeh+se8mARu+7G86M3HW6DGsWahQl29pyt7VSFFHcucMrrWq9lYgdeVjVNhcmBLj2Z1oAWcH+g8EEfZoF5uxvEqXASkR9bGcHRaLuGcN1MR3"
`endif