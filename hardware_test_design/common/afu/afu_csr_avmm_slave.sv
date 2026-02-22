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




module afu_csr_avmm_slave(
 
// AVMM Slave Interface
   input               clk,
   input               reset_n,
   input  logic [31:0] writedata,
   input  logic        read,
   input  logic        write,
   input  logic [3:0]  byteenable,
   output logic [31:0] readdata,
   output logic        readdatavalid,
   input  logic [31:0] address,
   output logic        waitrequest
);


 logic [31:0] csr_test_reg;
 logic [31:0] mask ;

 assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0; 
 assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0; 
 assign mask[23:16] = byteenable[2]? 8'hFF:8'h0; 
 assign mask[31:24] = byteenable[3]? 8'hFF:8'h0; 
 
//Write logic
always @(posedge clk) begin
    if (!reset_n) begin
        csr_test_reg  <= 32'h0;
        
    end
    else begin
        if (write && (address == 32'h0)) begin 
           csr_test_reg <= writedata & mask;
        end
        else begin
           csr_test_reg <= csr_test_reg;
        end        
    end    
end 

//Read logic
always @(posedge clk) begin
    if (!reset_n) begin
        readdata  <= 32'h0;
    end
    else begin
        if (read && (address == 32'h0)) begin 
           readdata <= csr_test_reg & mask;
        end
        else begin
           readdata  <= 32'h0;
        end        
    end    
end 



//Control Logic
enum int unsigned { IDLE = 0,WRITE = 2, READ = 4 } state, next_state;

always_comb begin : next_state_logic
   next_state = IDLE;
      case(state)
      IDLE    : begin 
                   if( write ) begin
                       next_state = WRITE;
                   end
                   else begin
                     if (read) begin  
                       next_state = READ;
                     end
                     else begin
                       next_state = IDLE;
                     end
                   end 
                end
      WRITE     : begin
                   next_state = IDLE;
                end
      READ      : begin
                   next_state = IDLE;
                end
      default : next_state = IDLE;
   endcase
end


always_comb begin
   case(state)
   IDLE    : begin
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   WRITE     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b0;
             end
   READ     : begin 
               waitrequest  = 1'b0;
               readdatavalid= 1'b1;
             end
   default : begin 
               waitrequest  = 1'b1;
               readdatavalid= 1'b0;
             end
   endcase
end

always_ff@(posedge clk) begin
   if(~reset_n)
      state <= IDLE;
   else
      state <= next_state;
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzpNTr13ZTJkr5ZeOo3mKnRwlKqGuSRvpQUEcryjA55OC9aza3yrwH6weJnvex6+suFo9nW00HCOZKXdB0optMro/DjeuF5I2ncYaWEPjyHYdObGjVEGTNH+4XdJK5CMbSY2zO8pzOxhdeVKtqEnB/YWcHIYoyFtCshzCvUAkO+KAU8HzZwOlKKlHcltTNKiY0Kb6nNii68fn7eDMWBeYZ6lJtyoCQeuL7LgJ6q4ugZK7FdJxeB519pXO5XJu7D367jkRSx9h3pzXRFS9oOGr5MrpvyUb8cFe77/VYZDUyciifSdr3h1gisTlqEF0jiSADQFLb51UbFfPMbiU0ImbpGvxJUafOTa9/L6S2nqtL5hgcnetukHEa3NSuHEVLufUnHaSzgNvDqC2Jba6AtlG5sL4d7XMh5ZlPAzK/tJRbqklVr5jqjxa7UuKE63YWl/5ZqKqsPqKWQjGiJHAqDSdA+tyGBt5HF///AH1BU1jTTals6tkaf+XdvG5r2Y6/Pb+zgeW4kYO0gdPM1L9pTnDRW/BBiYmtlndO5kiWN9Ye3iR2sOIJnB79BjtgeZV1weaO8l6lK8o9pE7akAiS6vNzyu2aecfURPpQRBxSklbdrCwds2qN/qYPwDHvVS7iFm4kBrpqfTHrJpwLqfQ2XWwTQ/6ywGV6fNValrADTAgCswuotrX30+E4ub6Zj4Xv3AcT1Z21mo4GzZrnfgsAZBuOw3ls5UQV+WCSf2c1dBoXhbrZqLw8vMRRa7Cq0BbQlAqRIoSgyYEVpkPChonNjh9vow"
`endif