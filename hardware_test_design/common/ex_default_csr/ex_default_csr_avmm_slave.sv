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

module ex_default_csr_avmm_slave(
 
// AVMM Slave Interface
   input               clk,
   input               reset_n,
   input  logic [63:0] writedata,
   input  logic        read,
   input  logic        write,
   input  logic [7:0]  byteenable,
   output logic [63:0] readdata,
   output logic        readdatavalid,
   input  logic [31:0] address,
   input  logic        poison,
   output logic        waitrequest,
   output logic [31:0] read_delay
);


 logic [31:0] csr_test_reg;
 assign read_delay = csr_test_reg;

 logic [63:0] mask ;
 logic config_access; 

 assign mask[7:0]   = byteenable[0]? 8'hFF:8'h0; 
 assign mask[15:8]  = byteenable[1]? 8'hFF:8'h0; 
 assign mask[23:16] = byteenable[2]? 8'hFF:8'h0; 
 assign mask[31:24] = byteenable[3]? 8'hFF:8'h0; 
 assign mask[39:32] = byteenable[4]? 8'hFF:8'h0; 
 assign mask[47:40] = byteenable[5]? 8'hFF:8'h0; 
 assign mask[55:48] = byteenable[6]? 8'hFF:8'h0; 
 assign mask[63:56] = byteenable[7]? 8'hFF:8'h0; 
 assign config_access = address[21];  


//Terminating extented capability header
localparam EX_CAP_HEADER  = 32'h00010023;
localparam EX_CAP_HEADER1 = 32'h00801E98;


//Write logic
always @(posedge clk) begin
    if (!reset_n) begin
        csr_test_reg <= 32'h20;
    end
    else begin
        if (write && (address == 22'h0000) && ~poison) begin 
           csr_test_reg <= (writedata[31:0] & mask[31:0]) | (csr_test_reg & ~mask[31:0]);
        end
        else if (write && (address[20:0] == 21'h00E08) && config_access) begin
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
        if (read && (address[21:0] == 22'h0)) begin 
           readdata <= csr_test_reg & mask[31:0];
        end
        else if(read && (address[20:0] == 21'h00E00) && config_access) begin //In ED PF1 capability chain with HEADER E00 terminate here with data zero 
           readdata <= {EX_CAP_HEADER} & mask;
        end
        else if(read && (address[20:0] == 21'h00E04) && config_access) begin
           readdata <= {EX_CAP_HEADER1} & mask;
        end
        else if(read && (address[20:0] == 21'h00E08) && config_access) begin
           readdata <=  csr_test_reg & mask;
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
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL60VPv9pE47cpLZEE+MXPD8m5CCKpC40zV2gKg3GagopOYHpA3+Plk7AaC1US03hw+VbScEJ+JLSFgMYmNhO7xcIlhVXOH03H0L7qkmXpHOZnteYQQyGBLNYzG0ByjpgyI1BIxKBLgBtFlOTE+M3ULS06MBgcWneEHnZgvm0Zn8mwZm1MNEapTqiq5RlBc1mNrRPcD9V94uuLltbkEVlp6sXVOBzHKQOQV0UV1eqz+RTbKmm5QI3fP72HysoK3KAcekHuu5pBGdfAT/7zeHS5QVgi0GM1lg3PHgr7sgNjCrUIHN53nq84i3YMbGW+V88aB1CkPMwTSjV3fap4U/Y6vtOck7B5A4hj3qYN6F7w7kuBsKbt5Y97TaZW6UrLFj0DgQAYF1ElBgAje8+jMCcHV4peZYR9n9FFxnqF26J5GOSt6OJcSQjhz7IrHsFQLaCwmRu0vlGeJJWzQHH/2Fsbxeb2plFzuIkvoKDOWpZBmOXxzM0m9fcaQpH4Oe8qGOER9BAOdNWMsWFb87ZJbwBYwnQ8M/5LuUDi3799s+pSRjuVQfj2ELrjADKEAkUc+7zDwyP0UuAlc8FQddt+1CuI1sw/HYV3c9q55k7FODOaPLXNOf1q+7cu7qYiuae8kFX6eJMrTpfoHvjqi32p2KtJ3N6EZzKgE6VQlq2wRu7ZkHeubYGxNs1vB6uAAuATQyLko8q5OdpYC9btPXirqLf8UUbN6sTMWP8h3HTotRzca6M2aaXObMXcHm6WYOmsFqIButLe6pQk6kCH7D0oRd5vF3"
`endif
