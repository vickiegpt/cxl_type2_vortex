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

module ex_default_csr_top (
    input  logic        csr_avmm_clk,
    input  logic        csr_avmm_rstn,  
    output logic        csr_avmm_waitrequest,  
    output logic [63:0] csr_avmm_readdata,
    output logic        csr_avmm_readdatavalid,
    input  logic [63:0] csr_avmm_writedata,
    input  logic        csr_avmm_poison,
    input  logic [21:0] csr_avmm_address,
    input  logic        csr_avmm_write,
    input  logic        csr_avmm_read, 
    input  logic [7:0]  csr_avmm_byteenable,
    output logic [31:0] read_delay
);

//CSR block

   ex_default_csr_avmm_slave ex_default_csr_avmm_slave_inst(
       .clk          (csr_avmm_clk),
       .reset_n      (csr_avmm_rstn),
       .writedata    (csr_avmm_writedata),
       .read         (csr_avmm_read),
       .write        (csr_avmm_write),
       .poison       (csr_avmm_poison),
       .byteenable   (csr_avmm_byteenable),
       .readdata     (csr_avmm_readdata),
       .readdatavalid(csr_avmm_readdatavalid),
       .address      ({10'h0,csr_avmm_address}),
       .waitrequest  (csr_avmm_waitrequest),
       .read_delay   (read_delay)
   );

//USER LOGIC Implementation 
//
//


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL7kZJTVlyQBokD016H8UrYF0OjYwSq0++NZ1eivWIC2Hqmqcd5ZAt+Cn8iC3rO3ro6Jw141SXryNleBBAQhTDEOomrs5PGiRWkAOfNxzDiSOaiw9mZFkrTXdWolky5qyk8iug+kaLOCR+DTQsEYxu4d0YBH6di8RFB5LdFnQKOjKVLcJL8DAg1tHPOQLgZzNLglZBUDbd6Hu48lhoF/8NxmmKPo62+Ul3vsqGrEcC36yP2DlY/nqMSHNbow5B5gIgnO6bjjEVYGwFJfEIB3G3zfuvv4zTpD1wsyezuAqoaHTba/9m/FoMsh9Z+jEFOBZ/ms9Hq9lzOUhhPXNcysrGwLEePXEV12T2+2ubYf0Xsz+kghba7UIxwXU52WKJ953BwrSriEnKsm2OuLVNJdQRujBL6fjVKa9p+aDVzl5Tok3WelDZ8b9hKKAMTz7dxu0qgzCCYaXNYnqYHvRxJnhLD/pJhBP83si+WzLYMfhJaXPKtKNtoSIY+tf/RpUbdhSbORNEmT6EpWgPRg1d2RuKYtv0xgb4mwdP1+yGA3ie64Axwf+6kGCzmxUkd4BsMNySF26s/0b9oFQj4dDkf15vk+adcijNtB5mDIUk9l7H3ztOOIbv0E90AS+4tQ/wDuNIku/TfGdVpq9/X/j3+ql2ao8IIiuTUK0s92aOm9/1OkSqWIBbTuzw9RwLVTpWxC77AfxqJbLsYj6MF8bEb0cQo7r53z8YNRn2r9IUZg2OjTMIuEtPAke1pRm0foF1qVUVvy8LyWFTwpBRN2WWqhgr6c"
`endif
