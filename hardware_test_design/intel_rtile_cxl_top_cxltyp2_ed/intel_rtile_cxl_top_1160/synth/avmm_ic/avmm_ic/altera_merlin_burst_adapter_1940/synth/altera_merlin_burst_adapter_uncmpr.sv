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


// (C) 2001-2012 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any output
// files any of the foregoing (including device programming or simulation
// files), and any associated documentation or information are expressly subject
// to the terms and conditions of the Altera Program License Subscription
// Agreement, Altera MegaCore Function License Agreement, or other applicable
// license agreement, including, without limitation, that your use is for the
// sole purpose of programming logic devices manufactured by Altera and sold by
// Altera or its authorized distributors.  Please refer to the applicable
// agreement for further details.


// $Id: //acds/main/ip/merlin/altera_merlin_burst_adapter/altera_merlin_burst_adapter.sv#68 $
// $Revision: #68 $
// $Date: 2014/01/23 $

`timescale 1 ns / 1 ns

// -------------------------------------------------------
// Adapter for uncompressed transactions only. This adapter will
// typically be used to adapt burst length for non-bursting 
// wide to narrow Avalon links.
// -------------------------------------------------------
module altera_merlin_burst_adapter_uncompressed_only
#(
    parameter 
    PKT_BYTE_CNT_H  = 5,
    PKT_BYTE_CNT_L  = 0,
    PKT_BYTEEN_H    = 83,
    PKT_BYTEEN_L    = 80,
    ST_DATA_W       = 84,
    ST_CHANNEL_W    = 8
)
(
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                           sink0_valid,
    input  [ST_DATA_W-1 : 0]        sink0_data,
    input  [ST_CHANNEL_W-1 : 0]     sink0_channel,
    input                           sink0_startofpacket,
    input                           sink0_endofpacket,
    output reg                      sink0_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output reg                      source0_valid,
    output reg [ST_DATA_W-1    : 0] source0_data,
    output reg [ST_CHANNEL_W-1 : 0] source0_channel,
    output reg                      source0_startofpacket,
    output reg                      source0_endofpacket,
    input                           source0_ready
);
    localparam
        PKT_BYTE_CNT_W = PKT_BYTE_CNT_H - PKT_BYTE_CNT_L + 1,
        NUM_SYMBOLS    = PKT_BYTEEN_H - PKT_BYTEEN_L + 1;

    wire [PKT_BYTE_CNT_W - 1 : 0] num_symbols_sig = NUM_SYMBOLS[PKT_BYTE_CNT_W - 1 : 0];

    always_comb begin : source0_data_assignments
        source0_valid         = sink0_valid;
        source0_channel       = sink0_channel;
        source0_startofpacket = sink0_startofpacket;
        source0_endofpacket   = sink0_endofpacket;

        source0_data          = sink0_data;
        source0_data[PKT_BYTE_CNT_H : PKT_BYTE_CNT_L] = num_symbols_sig;

        sink0_ready = source0_ready;
    end

endmodule



`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "STbanMqy8UpvYjUJXR/AuKniYmV/XZ0zJn/xzMvub2v72ixIJ7RUF/NrPoLZm9VpGYB+6/h3sGK2eBCGD8WgzYV4s04rwJV/gFlBTxheWC+sVCOTbBzPz91EJjQVEkx36RN/HJdQoD8GpU5YEjaU0qB+68AKbYYQBDCCuFskkWV1Ncy+T+wBSgFHyoxeoiMh9z1OKFVWiKp5JLyFZLmSp4sAD90mao8g5EAIvtCteI8LAJEadAMZkK9Oqs9ut6jRpqCtWBTdsG2hRazWeRxfKfouYWotb5kn+ZZ8+6pCEyIgPcJm9SPy04ydInA6jRl1cGfkugQHyYtI0nohx3gx3Sq3qrwFVp4UO5/AktEwcVsul1rOz+WAiEb3qOxhO65bSm1B6EHtFL5RCk9G6E4a6BQhP5Hw7XKuPrS1YFv2Ihj0+afgn2SiEafhy38WLhdFeduznHx5ECN/igGn42/GxdbEToa/FvMgGdYiXAmz+9HITcXcZS02E5lVTqIuarFrjJ3la2a+IXtNh8/uthtlOXchmax/uJXDoJEzWATAK7mfJYq2Zk/lChKK9fVgt7GQqdJ/QKbGNb4COoO+Ot0XSn6SrkD8U2LA3LDV/gODkogGC9c+bCVKLGkHdVGYZZTUmWxeiJg8t6ksoQZFRWnYlbTHjFQi4Yis0pp6cCw0Z2anvZXiU6/6SYCGIF9TWWFb5EWRC2zUu78J8U43EymEH7DJq2B0fHuCaIUZmm/BXGofAH6LcHEDk2Pygomq5aBtdMgu8qJ3HsPbM9XM2wSR/crBaFKl/qgtshVVV9nDxqc92+RMBsoJzcQppUFKqaZYnSMUT7rP3X4e8WInr4+Dxd8niEMAjgS8Pe6FGct7MLEL2H1zeQEVDRjfOCCo7CF3aRKrxSQHK9dYSaXgSJS/0PY73Hvsc7T21XJQC5m6MPwHZOEnsUfQ2Pl6MyLeEljd2pRqSasJE0v36xiDjYTHjsOgxyguAxkUsvGDHVZ0l9a+V6Gb6mIGrN+afgFrKeXT"
`endif