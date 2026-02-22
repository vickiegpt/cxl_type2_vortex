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

/*  Page 603 of CXL 2.0 Spec

PatternSize: Defines what size (in bytes) of P or B to use starting from 
least significant byte. As an example, if this is programmed to 3b011, 
only the lower 3 bytes of P or B registers will be used as a pattern. 
This will be programmed consistently with the ByteMask field and the base
address.
*/

module pattern_reduce_by_pattern_size
(
   input [2:0]           pattern_size_reg_in,
   input [31:0]          pattern_in,

   output logic [31:0]   pattern_out
);


always_comb
begin
  case( pattern_size_reg_in )
    // 3'b100 : pattern_out = pattern_in;
    3'b011  : pattern_out = {8'd0, pattern_in[23:0]};
    3'b010  : pattern_out = {16'd0, pattern_in[15:0]};
    3'b001  : pattern_out = {24'd0, pattern_in[7:0]};
    3'b000  : pattern_out = 32'd0;
    default : pattern_out = pattern_in;
  endcase
end



endmodule


`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcc+XJ3zvCUQreg1IB07Uma5+77pbcIeN7GCYURAcW6w+O8Ozch2fFYSvG97FNkPo/QrhELy6rELAj3QasmZWb6mUuNNR5cKToAphs4YLdRJXnukHQyBHkLWOacvLlPsm3gzonxCDM4dFXrLIUS9aiWFTXWvR8ReeRD0sFv1auUjNnpnOWPd/tClUNkQpJAMzV3eoJKWhLkR3SCpZiQisgXeER3ZG56NLe3N2Y4K39Gs7H8cIv9IRATyL2mpzk0InTE4ThwkltuTlQPOZu/89imYEaBv6I//oz1FXBgNTDRDgmH/prz5rqbPCt0WRH3gQgK9BiScEpEnjOFKWIc86pCgBBAX/iIjqFRiX+2GtvtqhAqh55BILIAUDxVWYkrlIZLqdroL5Pff3HjW/IfVml6xfbVvYGxDd8jLo/2dlI8+NX61P+aOfNW9zBWoZeMwl26aF6VM6NPaawEycqkerbLfMiJj3DeBByb4d9T2TF8AHX4p7u+CKaykB21sQKXrv0YR1J5BtaTzEm6d3snKdExOR8zQRtBjE52C0EZsxE5nUdVwV8hY8JkB+jJK3XiO92XRDHB+U/59g3ZyysU2Vu40Uz2AfRXnD2Fbx7utY7XMThd415Ch3yGLRsktFsNZCAEUSyLVJ4jnGqWMr2pGy9U19LytaraXiY2E2gebmzPDXkfvBDVp5kylfhA2KVhNmSMatUDu8dyJPVYbnWH5kWB4inmoiwE6xR1q5vL9PsbxeH1TA+pUMdaI/fyolaZsCbGBsdU5u3VJfD6IWo8jGmIC"
`endif