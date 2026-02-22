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
///////////////////////////////////////////////////////////////////////

module afu_ate_comparator #( parameter DATA_WIDTH = 512'd512  )(
   input                             rtl_clk,
   input           [DATA_WIDTH-1:0]  dataa,
   input           [DATA_WIDTH-1:0]  datab,
   input     logic                   enable,
   output    logic                   eq
   );

 
 generate  
      if(DATA_WIDTH < 4) begin
          always @(posedge rtl_clk) begin
            if(!enable) begin
               eq <= 1'b0;
             end
             else begin
               eq <= (dataa == datab);
             end
          end
        end else begin
          localparam WIDTH_BY_4=DATA_WIDTH/4;
          wire eq0,eq1,eq2,eq3;
          afu_ate_comparator #(.DATA_WIDTH(WIDTH_BY_4)) c0 (.rtl_clk(rtl_clk),
                                                       .dataa(dataa[WIDTH_BY_4-1:0]),
                                                       .datab(datab[WIDTH_BY_4-1:0]),
                                                       .enable(enable),
                                                       .eq(eq0)
                                                      );
          afu_ate_comparator #(.DATA_WIDTH(WIDTH_BY_4)) c1 (.rtl_clk(rtl_clk),
                                                       .dataa(dataa[2*WIDTH_BY_4-1:WIDTH_BY_4]),
                                                       .datab(datab[2*WIDTH_BY_4-1:WIDTH_BY_4]),
                                                       .enable(enable),
                                                       .eq(eq1)
                                                      );
          afu_ate_comparator #(.DATA_WIDTH(WIDTH_BY_4)) c2 (.rtl_clk(rtl_clk),
                                                       .dataa(dataa[3*WIDTH_BY_4-1:2*WIDTH_BY_4]),
                                                       .datab(datab[3*WIDTH_BY_4-1:2*WIDTH_BY_4]),
                                                       .enable(enable),
                                                       .eq(eq2)
                                                      );
          afu_ate_comparator #(.DATA_WIDTH(WIDTH_BY_4)) c3 (.rtl_clk(rtl_clk),
                                                       .dataa(dataa[4*WIDTH_BY_4-1:3*WIDTH_BY_4]),
                                                       .datab(datab[4*WIDTH_BY_4-1:3*WIDTH_BY_4]),
                                                       .enable(enable),
                                                       .eq(eq3)
                                                      );
        always  @(posedge rtl_clk) begin
           if(!enable) begin
              eq <= 1'b0;
            end
            else begin
              eq <= eq0 & eq1 & eq2 & eq3;
            end
        end                                                               
        end
endgenerate 

    

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3UzpK46ZKZIX4pNVYt2yGUbBHXaZl1KJpkEBnoRAx2PVBdKdFbxUKZC9Djpj+n66J2SEepfuwdbpTRmgc3Dxd+5Jy28B0yNEbMLmgoQQRi5Hddvczsof/Xv+7j1ufYMXs0QcftVUqsnzZuBfZ7Gw7fgs63G7lw3g60HR+iMryrMc3+U0ZFUlJQ15DEv8ogBqbEXbZOdyRtQ6e3HwMN1xslBdMONT5E2QoyYhxFBt5RCdntUFUFntr0sPfIh69tA2Hv4e3YsDkDA66dkcd4kONK25H8dF6E6IuA6GXZ7gycQvedhhTKy2mfdctIyJ/y1sqNzNE0Jp7CvtY9nI16ik30/ekZC9TYf8+h2v+Z//Ksc/rq0petx4jOkKIQB/qkrd9wGNRnHU/MP7qazm77hYF7135NnsJfGru5E5FxbGFlK1IT9c5M7m5N5azRH50ClOXt3KrS2zNIXhOLO/hhtCx5+CvVaqkUeTcMCngrT+2vUIk0jgBX4IUP/RYAZcGCqjjMmAHxrbeeJF/QBpgY9n9YxEooiDh20ch1eYhi0EBc5yKb+jmpXZQ2JcQjZ7r+Ox2CYn4BMf6fUAJ0IdND+c5u1jkB7I6PVr7bP4vYtfsB9HjBQH2r0ZuXEBrEn/Ju9Casi+WJYU27Aly1c0SOYNnTf3QlZvfYDeWkDXjyEzrfQgWZLmH0ViSFzizYUgXZK81+8RE+O5z4Q6QcaNva02eiwDoihECHjLgLDvmdIB4Glty+uCJWEiVli82Jd3JfwPdySeg4O67XBmIEXeVlkvfrvUh"
`endif