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


// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//-----------------------------------------------------------------------------
//
// File: intel_std_synchronizer_nocut.v
//
// Abstract: Single bit clock domain crossing synchronizer. Exactly the same
//           as altera_std_synchronizer.v, except that the embedded false
//           path constraint is removed in this module. If you use this
//           module, you will have to apply the appropriate timing
//           constraints.
//
//           We expect to make this a standard Quartus atom eventually.
//
//           Composed of two or more flip flops connected in series.
//           Random metastable condition is simulated when the 
//           __ALTERA_STD__METASTABLE_SIM macro is defined.
//           Use +define+__ALTERA_STD__METASTABLE_SIM argument 
//           on the Verilog simulator compiler command line to 
//           enable this mode. In addition, define the macro
//           __ALTERA_STD__METASTABLE_SIM_VERBOSE to get console output 
//           with every metastable event generated in the synchronizer.
//
// Copyright (C) Altera Corporation 2009, All Rights Reserved
//-----------------------------------------------------------------------------

`timescale 1ns / 1ns

module intel_std_synchronizer_nocut (
                                clk, 
                                reset_n, 
                                din, 
                                dout
                                );

   parameter depth = 3; // This value must be >= 2 !
   parameter rst_value = 0;     
     
   input   clk;
   input   reset_n;    
   input   din;
   output  dout;
   
   // QuartusII synthesis directives:
   //     1. Preserve all registers ie. do not touch them.
   //     2. Do not merge other flip-flops with synchronizer flip-flops.
   // QuartusII TimeQuest directives:
   //     1. Identify all flip-flops in this module as members of the synchronizer 
   //        to enable automatic metastability MTBF analysis.

   (* altera_attribute = {"-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name SYNCHRONIZER_IDENTIFICATION FORCED; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON  "} *) reg din_s1;

   (* altera_attribute = {"-name ADV_NETLIST_OPT_ALLOWED NEVER_ALLOW; -name DONT_MERGE_REGISTER ON; -name PRESERVE_REGISTER ON"} *) reg [depth-2:0] dreg;    
   
   //synthesis translate_off
   initial begin
      if (depth <2) begin
         $display("%m: Error: synchronizer length: %0d less than 2.", depth);
      end
   end

   // the first synchronizer register is either a simple D flop for synthesis
   // and non-metastable simulation or a D flop with a method to inject random
   // metastable events resulting in random delay of [0,1] cycles
   
`ifdef __ALTERA_STD__METASTABLE_SIM

   reg[31:0]  RANDOM_SEED = 123456;      
   wire  next_din_s1;
   wire  dout;
   reg   din_last;
   reg          random;
   event metastable_event; // hook for debug monitoring

   initial begin
      $display("%m: Info: Metastable event injection simulation mode enabled");
   end
   
   always @(posedge clk) begin
      if (reset_n == 0)
        random <= $random(RANDOM_SEED);
      else
        random <= $random;
   end

   assign next_din_s1 = (din_last ^ din) ? random : din;   

   always @(posedge clk or negedge reset_n) begin
       if (reset_n == 0) 
         din_last <= (rst_value == 0)? 1'b0 : 1'b1;
       else
         din_last <= din;
   end

   always @(posedge clk or negedge reset_n) begin
       if (reset_n == 0) 
         din_s1 <= (rst_value == 0)? 1'b0 : 1'b1;
       else
         din_s1 <= next_din_s1;
   end
   
`else 

   //synthesis translate_on   
   generate if (rst_value == 0)
       always @(posedge clk or negedge reset_n) begin
           if (reset_n == 0) 
             din_s1 <= 1'b0;
           else
             din_s1 <= din;
       end
   endgenerate
   
   generate if (rst_value == 1)
       always @(posedge clk or negedge reset_n) begin
           if (reset_n == 0) 
             din_s1 <= 1'b1;
           else
             din_s1 <= din;
       end
   endgenerate
   //synthesis translate_off      

`endif

`ifdef __ALTERA_STD__METASTABLE_SIM_VERBOSE
   always @(*) begin
      if (reset_n && (din_last != din) && (random != din)) begin
         $display("%m: Verbose Info: metastable event @ time %t", $time);
         ->metastable_event;
      end
   end      
`endif

   //synthesis translate_on

   // the remaining synchronizer registers form a simple shift register
   // of length depth-1
   generate if (rst_value == 0)
      if (depth < 3) begin
         always @(posedge clk or negedge reset_n) begin
            if (reset_n == 0) 
              dreg <= {depth-1{1'b0}};            
            else
              dreg <= din_s1;
         end         
      end else begin
         always @(posedge clk or negedge reset_n) begin
            if (reset_n == 0) 
              dreg <= {depth-1{1'b0}};
            else
              dreg <= {dreg[depth-3:0], din_s1};
         end
      end
   endgenerate
   
   generate if (rst_value == 1)
      if (depth < 3) begin
         always @(posedge clk or negedge reset_n) begin
            if (reset_n == 0) 
              dreg <= {depth-1{1'b1}};            
            else
              dreg <= din_s1;
         end         
      end else begin
         always @(posedge clk or negedge reset_n) begin
            if (reset_n == 0) 
              dreg <= {depth-1{1'b1}};
            else
              dreg <= {dreg[depth-3:0], din_s1};
         end
      end
   endgenerate

   assign dout = dreg[depth-2];
   
endmodule 


                        
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL7kGQ0T9/NKN3riG7p2kFlXKZU4TnE2CtnHxUhJccJ1BWLHdy0vyVZuaHXBR47VZADOghMeZAeu0Kvou6ZfBx0EHtWbK21Rp9m5pJ+MNgjxpurG2+sTb/NEwo7GYr3vfmtoUWTk9vPRu8mGJxQHExf3vw/ENVmO7YHSjqyN7ZFGkP2TKRDbm1UdTgtA7cspuYuWi8tV0LE8D94T9ic2a0BYGYOKEr0N9VhHeGOP1ThvnhKPU57BFEw+Y8wHrurK9ppi34GcWyqh4F7CYOGTlulrFOUoqjQIweAAXYpeb1a2k9uz3yuUcftQNbvjwCZcWycqAIoICsOP99axvzV41Yhzwt9NKn1XIFhjlsOcLp8KJt9r/YvOHfeBKY9pV34kPSjYNpTGzVY3pNT3XAeAUg8qxlh5zrf78o6/0T0Cr42zpm+wz8cMciZRiAM/EDFe1mfIVZ1gv+0cEd+0xlN43YPnGeBgMDiZq3yTRZLUKPevBN3mTK0pSaGEHNazPCUR2r+HFkyNSQkS/3ojHI5B+JvRdWr71+4bz1h00wHm1qAeiG+2Nmr78o1r5X0NZ8BNSStdmZ4LnPT4+63XY8VrTlR8FB6tZQiWO9mmexdk1fL8qXCLmgfeQ2RYTPHRNrXAlaYo8kianouwwUqCxRdTW8rIHEH7k4uuquEt1EwPO4r58jloIo58+ppdj3q7X0sT06yJwN5HM+bAW7tdsuxUWKJTXPbblzVcPDKSI1xBDjEzbt3aNseItMu9IWgYiKrLA/ktoKpH+2NUoHdOnkUW6UpP"
`endif