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


module avst4to1_ss_tlp_hdr_decode (
//
// PLD IF
//
  input                   pld_clk,                                   // Clock (Core)
  input                   pld_rst_n,
  
  input                   tlp_valid,
  input                   tlp_sop,
  input [127:0]           tlp_hdr,
  
  output logic            func_num_val,
  output logic            bcast_msg,
  output logic [7:0]      func_num,
  
  output logic            mem_addr_val,
  output logic            mem_64b_addr,
  output logic [63:0]     mem_addr,
  
  output logic [1:0]      tlp_crd_type                            // // credit type: 00-P, 01-NP, 10-CPL, 11-ERR
 
);
//----------------------------------------------------------------------------//


logic [63:0]  mem_tlp_hdr_dw1_3;


assign mem_addr = mem_tlp_hdr_dw1_3;

// S0 segment
always @(posedge pld_clk)
begin
   if (~pld_rst_n)
     begin
       bcast_msg <= 1'b0;
       func_num_val <= 1'b0;
       mem_addr_val <= 1'b0;
       mem_64b_addr <= 1'b0;
       
       func_num[7:0] <= 8'd0;
       
       tlp_crd_type[1:0] <= 2'b11; //ERR
       mem_tlp_hdr_dw1_3[63:0] <= {2{32'hBAAD_BAAD}};
     end
   else
     begin
        if (tlp_valid & tlp_sop)
          begin
            if (~tlp_hdr[127])
              begin
                // get header info
                case (tlp_hdr[124:121])
                4'hd: // Deferred Memory Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b0;
                    mem_addr_val <= 1'b1;
                    tlp_crd_type[1:0] <= 2'b01; //NP
                    
                    if (tlp_hdr[125]) // 64 bit
                      begin
                        mem_64b_addr <= 1'b1;
                        mem_tlp_hdr_dw1_3[63:0] <= tlp_hdr[63:0];
                      end
                    else              // 32 bit
                      begin
                        mem_64b_addr <= 1'b0;
                        mem_tlp_hdr_dw1_3[31:0] <= tlp_hdr[63:32];
                        mem_tlp_hdr_dw1_3[63:32] <= 32'hBAAD_BAAD;
                      end
                  end
                4'h8, 4'h9, 4'ha, 4'hb: // Message Request
                  begin //brocast from root complex/local 
                    if (tlp_hdr[122:120] == 3'b100 | tlp_hdr[122:120] == 3'b011 | tlp_hdr[122:120] == 3'b010 | tlp_hdr[122:120] == 3'b000)
                      func_num_val <= 1'b1;
                    else
                      func_num_val <= 1'b0;
                      
                    if (tlp_hdr[122:120] == 3'b001)
                      mem_addr_val <= 1'b1;
                    else
                      mem_addr_val <= 1'b0;
                    
                    if (tlp_hdr[122:120] == 3'b011)
                      bcast_msg <= 1'b1;
                    else
                      bcast_msg <= 1'b0;
                    
                    if (tlp_hdr[122:120] == 3'b100 | tlp_hdr[122:120] == 3'b011 | tlp_hdr[122:120] == 3'b000)
                      func_num[7:0] <= 8'd0;
                    else
                      func_num[7:0] <= tlp_hdr[55:48];
                    
                    tlp_crd_type[1:0] <= 2'b00; //P
                    if (tlp_hdr[125]) // 64 bit
                      begin
                        mem_64b_addr <= 1'b1;
                        mem_tlp_hdr_dw1_3[63:0] <= tlp_hdr[63:0];
                      end
                    else             // 32 bit
                      begin
                        mem_64b_addr <= 1'b0;
                        mem_tlp_hdr_dw1_3[31:0] <= tlp_hdr[63:32];
                        mem_tlp_hdr_dw1_3[63:32] <= 32'hBAAD_BAAD;
                      end
                  end
                4'h6, 4'h7: // AtomicOp Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b0;
                    mem_addr_val <= 1'b1;
                    
                    tlp_crd_type[1:0] <= 2'b01; //NP
                    if (tlp_hdr[125]) // 64 bit
                      begin
                        mem_64b_addr <= 1'b1;
                        mem_tlp_hdr_dw1_3[63:0] <= tlp_hdr[63:0];
                      end
                    else                    // 32 bit
                      begin
                        mem_64b_addr <= 1'b0;
                        mem_tlp_hdr_dw1_3[31:0] <= tlp_hdr[63:32];
                        mem_tlp_hdr_dw1_3[63:32] <= 32'hBAAD_BAAD;
                      end
                  end
                4'h5: // Completion Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b1;
                    mem_addr_val <= 1'b0;
                    mem_64b_addr <= 1'b0;
                    
                    func_num[7:0] <= tlp_hdr[55:48];
                    
                    tlp_crd_type[1:0] <= 2'b10; //CPL
                    mem_tlp_hdr_dw1_3[63:0] <= {2{32'hBAAD_BAAD}};
                  end
                4'h2: // Configuration Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b1;
                    mem_addr_val <= 1'b0;
                    mem_64b_addr <= 1'b0;
                    
                    func_num[7:0] <= tlp_hdr[55:48];
                    
                    tlp_crd_type[1:0] <= 2'b01; //NP
                    mem_tlp_hdr_dw1_3[63:0] <= {2{32'hBAAD_BAAD}};
                  end
                4'h1: // IO Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b0;
                    mem_addr_val <= 1'b1;
                    mem_64b_addr <= 1'b0;
                    
                    tlp_crd_type[1:0] <= 2'b01; //NP
                    mem_tlp_hdr_dw1_3[31:0] <= tlp_hdr[63:32];
                    mem_tlp_hdr_dw1_3[63:32] <= 32'hBAAD_BAAD;
                  end
                4'h0: // Memory Request
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b0;
                    mem_addr_val <= 1'b1;
                    if (tlp_hdr[126])     // write
                      tlp_crd_type[1:0] <= 2'b00; //P
                    else                  // read
                      tlp_crd_type[1:0] <= 2'b01; //NP
                    
                    if (tlp_hdr[125]) // 64 bit
                      begin
                        mem_64b_addr <= 1'b1;
                        mem_tlp_hdr_dw1_3[63:0] <= tlp_hdr[63:0];
                      end
                    else              // 32 bit
                      begin
                        mem_64b_addr <= 1'b0;
                        mem_tlp_hdr_dw1_3[31:0] <= tlp_hdr[63:32];
                        mem_tlp_hdr_dw1_3[63:32] <= 32'hBAAD_BAAD;
                      end
                  end
                default: // NA
                  begin
                    bcast_msg <= 1'b0;
                    func_num_val <= 1'b0;
                    mem_addr_val <= 1'b0;
                    mem_64b_addr <= 1'b0;
                    
                    tlp_crd_type[1:0] <= 2'b11;
                    mem_tlp_hdr_dw1_3[63:0] <= {2{32'hBAAD_BAAD}};
                  end
                endcase
              end
            else // prefix
              begin
                bcast_msg <= 1'b0;
                func_num_val <= 1'b0;
                mem_addr_val <= 1'b0;
                mem_64b_addr <= 1'b0;
                
                tlp_crd_type[1:0] <= 2'b11;
              end
          end
          else begin
             bcast_msg <= 1'b0;
             func_num_val <= 1'b0;
             mem_addr_val <= 1'b0;
             mem_64b_addr <= 1'b0;
          end
     end
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdBDRva7WRXoBgfwjL2LfV1Mzpbnx7472X5DVwJpIQsBf5s69gcvpkh5cm5BG4xH28zbD3ifeekHdNV4ZgPUedJr7SwHHVVgTnRm+VZ7iF2Gi7YEhZ6HzPn1y07Qqqp/mvqk7cYB0/oDK3z1wqTlrGj98OF8k/HE2HlV9OqfJk9CDDSayIbo3GZW8ej7C0Mcez/FvJonVLfcBKLhPsVKrY7SzcB+g+OuAdlZJmPQoHBPqNe6QpCeAY2zWPBVtR8wWgzMASB60Nl8qJg7ZNadLf3BVlPs7xzqVR0bhA5fwMGErNBcP70RZ0Cd++1aSaHJsft0hWeQQoEgmkxhmoMgXwI+eo9UNjckY0pkGYt9DpemYgfhmecuz6ZpBavrJRDcpC8XGxH0O0MC7iA8ysM4zKuGgeXPmS5FUiMmeOvjDZQ/vAUWVddYbRxZJ1f52Zdd0E0JouX9BUCfIevHKyHA8Ggvr8cpiQEMkGCamL4278Iz6B55v5iQh76mNSSd6aHaRaGkyCETBA585FbaKQP+inccCI/FcWCmIIRApsjWP6eH8nsoRgiTmF5lY95DvnZlFFdA9DC2iKgdylZUa21Nm3N4dTD73IO1W7n30/s2WT+gg6/snNx/HU1cKVdBIUsayuBdsslz/aXtph1ruCkMkxsH4zD968pnh+ZEYXQZ2/soV1U82ILhF8fKh0iBLo2SMHOkNTyN8qb5ZFfRe+iuupDjp+1oHZ/+DiD+1z2ocwiiXsk5U0lxgHeveOyE9nH+o6sVEUZ36OByvOTUOgml9dg"
`endif