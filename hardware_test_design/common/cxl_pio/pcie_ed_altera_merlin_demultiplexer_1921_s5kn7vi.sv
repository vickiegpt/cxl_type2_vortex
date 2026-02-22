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


// -------------------------------------
// Merlin Demultiplexer
//
// Asserts valid on the appropriate output
// given a one-hot channel signal.
// -------------------------------------

`timescale 1 ns / 1 ns

// ------------------------------------------
// Generation parameters:
//   output_name:         pcie_ed_altera_merlin_demultiplexer_1921_s5kn7vi
//   ST_DATA_W:           1267
//   ST_CHANNEL_W:        1
//   NUM_OUTPUTS:         1
//   VALID_WIDTH:         1
// ------------------------------------------

//------------------------------------------
// Message Supression Used
// QIS Warnings
// 15610 - Warning: Design contains x input pin(s) that do not drive logic
//------------------------------------------

// altera message_off 16753
module pcie_ed_altera_merlin_demultiplexer_1921_s5kn7vi
(
    // -------------------
    // Sink
    // -------------------
    input  [1-1      : 0]   sink_valid,
    input  [1267-1    : 0]   sink_data, // ST_DATA_W=1267
    input  [1-1 : 0]   sink_channel, // ST_CHANNEL_W=1
    input                         sink_startofpacket,
    input                         sink_endofpacket,
    output                        sink_ready,

    // -------------------
    // Sources 
    // -------------------
    output reg                      src0_valid,
    output reg [1267-1    : 0] src0_data, // ST_DATA_W=1267
    output reg [1-1 : 0] src0_channel, // ST_CHANNEL_W=1
    output reg                      src0_startofpacket,
    output reg                      src0_endofpacket,
    input                           src0_ready,


    // -------------------
    // Clock & Reset
    // -------------------
    (*altera_attribute = "-name MESSAGE_DISABLE 15610" *) // setting message suppression on clk
    input clk,
    (*altera_attribute = "-name MESSAGE_DISABLE 15610" *) // setting message suppression on reset
    input reset

);

    localparam NUM_OUTPUTS = 1;
    wire [NUM_OUTPUTS - 1 : 0] ready_vector;

    // -------------------
    // Demux
    // -------------------
    always @* begin
        src0_data          = sink_data;
        src0_startofpacket = sink_startofpacket;
        src0_endofpacket   = sink_endofpacket;
        src0_channel       = sink_channel >> NUM_OUTPUTS;

        src0_valid         = sink_channel[0] && sink_valid;

    end

    // -------------------
    // Backpressure
    // -------------------
    assign ready_vector[0] = src0_ready;

    assign sink_ready = |(sink_channel & ready_vector);

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL6oVlhRaSkUA8XQeagSDRQ+6q34N8dRzoiBusV3qHz54e8tk9UJr4ZNHYFYdUhDaQRPS/r/Yz4tvgkTSg+qQlCdzrH20jkWij3JzCR4/mwmoUOrfFpYTg4FoN6SWHUuX+1FskQGcrboyoj6ApBfVsl+DWx3kO5+MTqh/OG+o1eUL/HBm6UsJ+8cD7Z8QZwG/ZSfspPJNIzDaSP6RSrQ6farfUUK2mVNsAsZe2nTuEWSheoGPpMjh7V51ip7RrXuSWwIFBoU39FIvfO+kiy50JIzQHIClQ1CjVkbeYYezGuKJ+6jk3KBek18rKLab2SiUApo2mdkVBpM79jTdSTfOvv7yuOqXtcSZrSbzy9xLCg2ntOwv5g0AtYksq+ycEbPgbeUfw2Bq+Q3aj4K+bQyTz7YzAcOnnKDvrWJ/Mp+eTFkXOQTyWwVXz2w6TZIKEKV8BcX+SjYGAK1yT5DfF+dDTN5yaQ5CRtbz0Xk5DPk7YO731tITKz2GbDcfF7Tut8gtSfgv81YGDYO+L8jl1lRie0Y2f/J9Z4wXkgiGt14XpPakbrfktUucVHCVvdreQlwW23nbosaJXN2lF9lpX4PWw0K/CWcOW+tdM3gLcxdYsSBsDksawRq22q+t3FN49w2iASQWAJUlzyic+le7dqmRScF2svoaansZSEhE5PJXOrmddhOOKD50GjhXG25jVs6SKMRqZg2XfOoAEmqlRqbII4p6O2+5FeouNfe7O2NT57/wK7xnYjbOhzvLe/w3XQZGnq+JtDLJqOGX1d5xE3iQUE7"
`endif