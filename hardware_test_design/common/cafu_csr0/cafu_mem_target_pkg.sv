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


package cafu_mem_target_pkg;
    
    localparam  CL_ADDR_MSB = 51;
    localparam  CL_ADDR_LSB = 6;    
    
    typedef logic [CL_ADDR_MSB:CL_ADDR_LSB]        Cl_Addr_t;
    
    typedef struct packed {
        logic [CL_ADDR_MSB:28]  Addr;
        logic [CL_ADDR_MSB:28]  Size;
        logic [3:0]             IW;
        logic [3:0]             IG;
    }  hdm_mem_base_t;  //used for address decode in fabric_slice 
    
    typedef enum logic {
       TARGET_HOST_MEM     = 1'b0,
       TARGET_DEV_MEM      = 1'b1
    } fabric_target_dcd_e;    
    
    function automatic fabric_target_dcd_e fabric_target_dcd_f;
        input Cl_Addr_t        Addr;
        input hdm_mem_base_t   Base;
    
        localparam ADDRMATCH1  = 'h0_0000_0004;
        localparam ADDRMATCH2  = 'h0_0000_0005;
    
        logic [CL_ADDR_MSB:28]      shifted_addr;
    
        //shifted_addr = Addr << 22; //since CL Addr, shift 22 instead of 28
        shifted_addr = Addr[CL_ADDR_MSB:28];
    
        if ( (shifted_addr[CL_ADDR_MSB:28] <   (Base.Addr + Base.Size) )
           & (shifted_addr[CL_ADDR_MSB:28] >=  Base.Addr)
           )
            fabric_target_dcd_f = TARGET_DEV_MEM;
        else
            fabric_target_dcd_f = TARGET_HOST_MEM;  
    
    endfunction    
    

endpackage
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcfvyPIUI8rDEWPQYUbUAQpZ/EPMu0LVxNuvJMqF4FrVdzWkJXmNi5Q8hFUzFBM1Cl4qPejtJKnL6Y99YuCREk/fdXjkppaFkoaW7tj7W/ObYfAbbpdG7RoN+uXHJBKpXJi8EqX1C2S1H0+P4axv7x/2Cu54U/Aogd3IQNy1bO9yKx7UnqbTt0ENyeyIhoEP5ESE9NlDDr2Z8KsF6hKwecjutd/I2Pc1v0yoGSPUEtI5B5Ofn6TUVASK/PwiVoeUK8Pr0veeJCO0RDGFvtMJxhepmOqqNQ/O4k+NX4Iq8EZY+XIkaV8qhLmg6thDfXepulzm7/4H6yM55v8uZzZ/H4lnGsmOOgFNuR2Flp4utKp/Sv7VvlF60unRWIn9ecp3sEpnwB86NV5IhGQbcyk0P12s+ZGCYRVCJfXnOxuUKiQaoawrn4wbx8b0lKoomRVwxtduk43IrUPJPph6472PThS/Nx/r/xF5p1/Mk7rcAFyrn7nj7xF+CDHaG4Aby+Zs7RKSLuiDyxVKI+ksTlK27HQStl2tUvtNuzpIfNU7AuWkUCcnF2+8czHJVmoQc6IEjBXyg9UamRWHlwEP/7eS8FZ0maOTBHI/6t1QfOnFtvwskK4S8GcGfnJ2py8Gn/NIwkbWCEpmKq5dA1Z5tNyly32PkRonKSH4Lcwn6MBJglDY/3AaEdbv9uwnyCCOkBSXdulAJFQz0nCRZ6u4Jz3XCIYfLzrp+IXHaKb8Lt/L/SpKbUwNddG9axcV3ezTJzd/yu2W+9UdTpgLbTtNeS7WhQRC"
`endif