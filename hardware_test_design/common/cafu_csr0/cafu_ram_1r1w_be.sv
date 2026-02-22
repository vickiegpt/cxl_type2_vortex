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
// Description: Generic RAM with one read port and one write port.
//              Write port includes byte enables.
//

module cafu_ram_1r1w_be (clk,    // input   clock
                         we,     // input   write enable
                         be,     // input   write ByteEnables
                         waddr,  // input   write address with configurable width
                         din,    // input   write data with configurable width
                         raddr,  // input   read address with configurable width
                         dout    // output  write data with configurable width
                        );

parameter BUS_SIZE_ADDR = 4;                  // number of bits of address bus
parameter BUS_SIZE_DATA = 32;                 // number of bits of data bus
parameter BUS_SIZE_BE   = BUS_SIZE_DATA/8;
parameter GRAM_STYLE    = "no_rw_check, M20K";


input                           clk;
input                           we;
input   [BUS_SIZE_BE-1:0]       be;
input   [BUS_SIZE_ADDR-1:0]     waddr;
input   [BUS_SIZE_DATA-1:0]     din;
input   [BUS_SIZE_ADDR-1:0]     raddr;
output  [BUS_SIZE_DATA-1:0]     dout;

//Add directive to don't care the behavior of read/write same address
(*ramstyle=GRAM_STYLE*) reg [BUS_SIZE_BE-1:0][7:0] ram [(2**BUS_SIZE_ADDR)-1:0];  //ram divided into bytes.

reg [BUS_SIZE_ADDR-1:0] raddr_q;
reg [BUS_SIZE_DATA-1:0] dout;
reg [BUS_SIZE_DATA-1:0] ram_dout;
/*synthesis translate_off */
reg                     driveX;         // simultaneous access detected. Drive X on output
/*synthesis translate_on */


always_ff @(posedge clk)
begin
    if (we)
      for (int i=0; i < (BUS_SIZE_DATA/8); i++)
      begin
        if (be[i])
          ram[waddr][i]  <= din[7+(8*i)-:8];  // synchronous RAM write with byte enables
      end
    ram_dout<= ram[raddr];
    dout    <= ram_dout;
    /*synthesis translate_off */
    if(driveX)
      dout    <= 'hx;
    if( (raddr==waddr) && we )
      driveX <= 1;
    else
      driveX <= 0;
    /*synthesis translate_on */
end


endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcdaDnOCjEdtH9uELoU1HIsoeoWxxGkonc0okXTCr9YTpvXPVvzsa7CrCnq/dwB4d9lccR3tEs6dXenA27WbL5ejRKmB/BPfWzPKEpn/CqUHCqDK+rJ9NiWln7c1kLAnyvvDdfkuAmrQEJpkhXbBXcdThTrKghrLsVEUhUmk/VEoLriM4KZeoYjADBK1w0B8FRafmCs83FR5qgcfL8dX6tDMxfgnOcR+Aa3y64iED5jXD0LPXMTcI1j/e4NBmTHQEmtaq/DG0izjXaQ+yblXoKYLOwx4uKg5E3uHBL6Xo33QzL/lh/Qfpgnn+hhrZD+91oL4R8pJfpOulOkdy1KA5BOm4p3naj0yf0ZiZ6DDCKH1uk+EE7j9hOubUp9h6gIS1VuJo4nQ/qC/2Ki5OvPkBN0FpmMyg3crMN03Bi2uoXvzxdX3n/LAQiMH8IHOGfhzFqNZ31jhTPCrUQP4ifgBObpCRnTgnzBuG4RExK18wj9IwIzj40hyejiGrpUYhIK9/IHzYo/CDHw1sFHlB4LvytVZTiC/eemNjvO9dbyza5Uo+9PZ4LyFAN0qyDfOYCz5OcjtFLvPsDsJ+SQejXoNQ8ZMvOMceHn46pFHBJcrYSp9LYJCxhoefnhmMuYmyXSXAk1OOBV0kGWNkCbiNqLej8YDBi1j/BgOXwjg1G2DBor8Rzl35i0XRKNGUR1D9SY6IlUYLMAKy8wlEBumlPXQeIjSz/SJp09OAEMHXzB9CUPBB/JNAK7hpAGz2/pLljepfEdS/+v6HsIdp2h4HXo0T8CF"
`endif