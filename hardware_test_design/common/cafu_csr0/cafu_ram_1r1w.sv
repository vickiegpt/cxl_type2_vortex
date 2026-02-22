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
// Description: Generic RAM with one read port and one write port
//

module cafu_ram_1r1w (clk,     // input   clock
                      we,      // input   write enable
                      waddr,   // input   write address with configurable width
                      din,     // input   write data with configurable width
                      raddr,   // input   read address with configurable width
                      dout     // output  write data with configurable width
                     );

parameter BUS_SIZE_ADDR = 4;                  // number of bits of address bus
parameter BUS_SIZE_DATA = 32;                 // number of bits of data bus
parameter GRAM_STYLE    = "no_rw_check";


input                           clk;
input                           we;
input   [BUS_SIZE_ADDR-1:0]     waddr;
input   [BUS_SIZE_DATA-1:0]     din;
input   [BUS_SIZE_ADDR-1:0]     raddr;
output  [BUS_SIZE_DATA-1:0]     dout;

//Add directive to don't care the behavior of read/write same address
(*ramstyle= GRAM_STYLE*) reg [BUS_SIZE_DATA-1:0] ram [(2**BUS_SIZE_ADDR)-1:0];

reg [BUS_SIZE_DATA-1:0] dout;
reg [BUS_SIZE_DATA-1:0] ram_dout;
/*synthesis translate_off */
reg                     driveX;         // simultaneous access detected. Drive X on output
/*synthesis translate_on */


always_ff @(posedge clk)
begin
   if( we ) ram[waddr] <= din;  // synchronous RAM write

   ram_dout<= ram[raddr];
   dout    <= ram_dout;
                                            /*synthesis translate_off */
   if(driveX) dout <= 'hx;

   if( (raddr==waddr) && we) driveX <= 1;
   else                      driveX <= 0;            /*synthesis translate_on */
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcc/B0CvoN74+R/BzZCAMY0Z2i+tpsy+t/4s4VrCY6xjETiLgwxidu6YAp0ihDxJxupkvPo2Mro0BgUXCr/hpZwI/IR4R0Px+PHbD2pZhaIbxUorHLqAnxO17WhFT6EyB/rp5ezS7Hq5bj07FqbG/1mTBBvM++/yROR+3nL96FwrNXIji4+Ugrkzk/rrSXVZlDYR+mwa9yde0uEfm5EPbmbhWKCL32c2WP2X9ipcORnhT9x474qCdgPF7T5swMJX5gGs+qg9BfNqpM7rvjn+qgjCMOrfTPbv4LL0zxNS2JcbKpN2/4dXajADBpTDIY+z+36vIAKi9xU7jwp16F93LOTkyJ/VtpU1guTgD4cv/EQu15ftnmNnPaLKY6oo4cZx3TmBE1axll2clmRyl+a0mnksVP5e4TiGnKYD6R3EpJcpz8IGcn1yYV488ouv5AIA2uozGpR4VmBWQ7Yb3mmEkIvji217Z6BF6jfreOtlLQRfXMEhWrjXVn1iaZqsDjOUMCs+46E1mEtvjgLhNKHBKH8/xYvg31BhGcQUoah4RiO2CtqPdQMVngswtRbg4HvAvpF9S7fhnQsXFZ85I1vs+kopkC/oN3QWQyDfwdF3TC6+ZDt3srAzYFlUZEej676MSXMziYIhVGNHM74bhGSHTez1FvM+zsUeERMlsqU44UuaojQbmfZF3NdKytEn0FNNa00+hnHoxyngWUCdcqg/Iz6AoNHMQeJNXsIvlPqvGEhaw0ORS20XkQscsOTyM2hCscaKO8hzMCx1xOR/qiJaQbtJ"
`endif