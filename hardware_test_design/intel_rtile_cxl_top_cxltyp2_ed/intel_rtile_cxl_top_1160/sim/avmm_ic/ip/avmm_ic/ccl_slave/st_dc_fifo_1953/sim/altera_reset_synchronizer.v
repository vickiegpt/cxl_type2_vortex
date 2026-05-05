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


// $Id: //acds/rel/25.1/ip/iconnect/merlin/altera_reset_controller/altera_reset_synchronizer.v#1 $
// $Revision: #1 $
// $Date: 2025/02/06 $

// -----------------------------------------------
// Reset Synchronizer
// -----------------------------------------------
`timescale 1 ns / 1 ns

module altera_reset_synchronizer
#(
    parameter ASYNC_RESET = 1,
    parameter DEPTH       = 2
)
(
    input   reset_in /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R101" */,

    input   clk,
    output  reset_out
);

    // -----------------------------------------------
    // Synchronizer register chain. We cannot reuse the
    // standard synchronizer in this implementation 
    // because our timing constraints are different.
    //
    // Instead of cutting the timing path to the d-input 
    // on the first flop we need to cut the aclr input.
    // 
    // We omit the "preserve" attribute on the final
    // output register, so that the synthesis tool can
    // duplicate it where needed.
    // -----------------------------------------------
    (*preserve*) reg [DEPTH-1:0] altera_reset_synchronizer_int_chain;
    reg altera_reset_synchronizer_int_chain_out;

    generate if (ASYNC_RESET) begin

        // -----------------------------------------------
        // Assert asynchronously, deassert synchronously.
        // -----------------------------------------------
        always @(posedge clk or posedge reset_in) begin
            if (reset_in) begin
                altera_reset_synchronizer_int_chain <= {DEPTH{1'b1}};
                altera_reset_synchronizer_int_chain_out <= 1'b1;
            end
            else begin
                altera_reset_synchronizer_int_chain[DEPTH-2:0] <= altera_reset_synchronizer_int_chain[DEPTH-1:1];
                altera_reset_synchronizer_int_chain[DEPTH-1] <= 0;
                altera_reset_synchronizer_int_chain_out <= altera_reset_synchronizer_int_chain[0];
            end
        end

        assign reset_out = altera_reset_synchronizer_int_chain_out;
     
    end else begin

        // -----------------------------------------------
        // Assert synchronously, deassert synchronously.
        // -----------------------------------------------
        always @(posedge clk) begin
            altera_reset_synchronizer_int_chain[DEPTH-2:0] <= altera_reset_synchronizer_int_chain[DEPTH-1:1];
            altera_reset_synchronizer_int_chain[DEPTH-1] <= reset_in;
            altera_reset_synchronizer_int_chain_out <= altera_reset_synchronizer_int_chain[0];
        end

        assign reset_out = altera_reset_synchronizer_int_chain_out;
 
    end
    endgenerate

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "STbanMqy8UpvYjUJXR/AuKniYmV/XZ0zJn/xzMvub2v72ixIJ7RUF/NrPoLZm9VpGYB+6/h3sGK2eBCGD8WgzYV4s04rwJV/gFlBTxheWC+sVCOTbBzPz91EJjQVEkx36RN/HJdQoD8GpU5YEjaU0qB+68AKbYYQBDCCuFskkWV1Ncy+T+wBSgFHyoxeoiMh9z1OKFVWiKp5JLyFZLmSp4sAD90mao8g5EAIvtCteI8GDKuDA/EcYWhcLpBVol1d8ZO6rAgSJPM4EU6HTvkB2Rtr0QMrGlFePBz+4cEUobJG8UF4AFzrNWrjft5uM89cQWWq6VatVTuqnpJo+XPeLxC57phXY+o5asMIhbcuSCCbe/zFA0GN9xEXZ4euIjKHUse1NadCtPg9V0/3FfP/PDQBXWlLH3uMu2yKzNdkTpjwdJG5Y9KeWSWjmyGtI14cXm2dimoJ4aNBeZaOnCXMgCh9uUwQRAwm2hNBtlLEF5cH3J+v7WfBcdgNRZznbl+iB4tXyMbTAMyrcqSwG0yRk6nz3KktXmGmZ5MDjOOLdaQ+Jo0K9Z/6/Il7U4IGi/YxRaDQXDUAkZKZfuxpGOpliZLgWa7ecHblknr6gHYtivCN7Bp/lXbJGxAvj4JusCCIq/Q/vrzQrGk4E1TuFMig44Q8BalqhZRPeNiOM1YWFXIeRBN4nZrAz80rR9XoyOG2yFI1cuX2LcJRez/1xAG0QSm5ZsUtM4YMG5hZDTxFHmIGohyay3mty0vGxSCNj6VFYyyC24bjmShUaGcIf2EOe+nczPybDHbM25mxSmWgvOExD+mwdZJpmORz9jT7Eg/Ua2l/DmUlIC8zwboxWm5Oa5HNAVrYFSnlb5HW9XmMdrYES7xDNwzQfaSfZkoJwET56Y64J3gvCJ6UehQall/DZGwpB3GN48C28ftdgh5zlRalsaLFgAxUEntXZG34B/5Sec8PDMfizkk9b3evwqfPzDk8r+k9cYgQTq2Zv+5xJ3g6GjtELpFFIB36E3oeSOVK"
`endif