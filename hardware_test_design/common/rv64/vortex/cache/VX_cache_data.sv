// Copyright © 2019-2023
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`include "VX_cache_define.vh"

module VX_cache_data import VX_gpu_pkg::*; #(
    // Size of cache in bytes
    parameter CACHE_SIZE        = 1024,
    // Size of line inside a bank in bytes
    parameter LINE_SIZE         = 16,
    // Number of banks
    parameter NUM_BANKS         = 1,
    // Number of associative ways
    parameter NUM_WAYS          = 1,
    // Size of a word in bytes
    parameter WORD_SIZE         = 1,
    // Enable cache writeable
    parameter WRITE_ENABLE      = 1,
    // Enable cache writeback
    parameter WRITEBACK         = 0,
    // Enable dirty bytes on writeback
    parameter DIRTY_BYTES       = 0
) (
    input wire                          clk,
    input wire                          reset,
    // inputs
    input wire                          init,
    input wire                          fill,
    input wire                          flush,
    input wire                          read,
    input wire                          write,
    input wire [`CS_LINE_SEL_BITS-1:0]  line_idx,
    input wire [`CS_WAY_SEL_WIDTH-1:0]  evict_way,
    input wire [NUM_WAYS-1:0]           tag_matches,
    input wire [`CS_WORDS_PER_LINE-1:0][`CS_WORD_WIDTH-1:0] fill_data,
    input wire [`CS_WORD_WIDTH-1:0]     write_word,
    input wire [WORD_SIZE-1:0]          write_byteen,
    input wire [`UP(`CS_WORD_SEL_BITS)-1:0] word_idx,
    input wire [`CS_WAY_SEL_WIDTH-1:0]  way_idx_r,
    // Deferred write-on-hit inputs (from pipeline st1 - breaks tag_matches critical path)
    input wire                          write_hit,
    input wire [`CS_LINE_SEL_BITS-1:0]  write_hit_idx,
    input wire [`CS_WAY_SEL_WIDTH-1:0]  write_hit_way,
    input wire [`CS_WORD_WIDTH-1:0]     write_hit_word,
    input wire [`UP(`CS_WORD_SEL_BITS)-1:0] write_hit_widx,
    input wire [WORD_SIZE-1:0]          write_hit_byteen,
    // outputs
    output wire [`CS_LINE_WIDTH-1:0]    read_data,
    output wire [LINE_SIZE-1:0]         evict_byteen
);
    `UNUSED_PARAM (WORD_SIZE)

    wire [`CS_WORDS_PER_LINE-1:0][WORD_SIZE-1:0] write_mask;
    for (genvar i = 0; i < `CS_WORDS_PER_LINE; ++i) begin : g_write_mask
        wire word_en = (`CS_WORDS_PER_LINE == 1) || (word_idx == i);
        assign write_mask[i] = write_byteen & {WORD_SIZE{word_en}};
    end

    if (DIRTY_BYTES != 0) begin : g_dirty_bytes

        wire [NUM_WAYS-1:0][LINE_SIZE-1:0] byteen_rdata;

        for (genvar i = 0; i < NUM_WAYS; ++i) begin : g_byteen_store
            wire [LINE_SIZE-1:0] byteen_wdata = {LINE_SIZE{write}}; // only asserted on writes
            wire [LINE_SIZE-1:0] byteen_wren = {LINE_SIZE{init || fill || flush}} | write_mask;
            wire byteen_write = ((fill || flush) && ((NUM_WAYS == 1) || (evict_way == i)))
                             || (write && tag_matches[i])
                             || init;
            wire byteen_read  = fill || flush;

            VX_sp_ram #(
                .DATAW (LINE_SIZE),
                .WRENW (LINE_SIZE),
                .SIZE  (`CS_LINES_PER_BANK),
                .OUT_REG (1),
                .RDW_MODE ("R")
            ) byteen_store (
                .clk   (clk),
                .reset (reset),
                .read  (byteen_read),
                .write (byteen_write),
                .wren  (byteen_wren),
                .addr  (line_idx),
                .wdata (byteen_wdata),
                .rdata (byteen_rdata[i])
            );
        end

        assign evict_byteen = byteen_rdata[way_idx_r];

    end else begin : g_no_dirty_bytes
        `UNUSED_VAR (init)
        `UNUSED_VAR (flush)
        assign evict_byteen = '1; // update whole line
    end

    wire [NUM_WAYS-1:0][`CS_WORDS_PER_LINE-1:0][`CS_WORD_WIDTH-1:0] line_rdata;

    // Compute write-on-hit byte mask from st1 signals
    wire [`CS_WORDS_PER_LINE-1:0][WORD_SIZE-1:0] write_hit_mask;
    for (genvar i = 0; i < `CS_WORDS_PER_LINE; ++i) begin : g_write_hit_mask
        wire word_en = (`CS_WORDS_PER_LINE == 1) || (write_hit_widx == i);
        assign write_hit_mask[i] = write_hit_byteen & {WORD_SIZE{word_en}};
    end

    for (genvar i = 0; i < NUM_WAYS; ++i) begin : g_data_store

        localparam WRENW = WRITE_ENABLE ? LINE_SIZE : 1;

        // Fill write (st0) - no tag_matches dependency
        wire fill_write = fill && ((NUM_WAYS == 1) || (evict_way == i));

        // Deferred write-on-hit (st1) - uses registered way index, breaks critical path
        wire hit_write = write_hit && ((NUM_WAYS == 1) || (write_hit_way == i)) && WRITE_ENABLE;

        wire [`CS_WORDS_PER_LINE-1:0][`CS_WORD_WIDTH-1:0] line_wdata;
        wire [WRENW-1:0] line_wren;
        wire [`CS_LINE_SEL_BITS-1:0] line_waddr;

        if (WRITE_ENABLE) begin : g_wren
            // Fill takes priority over deferred write-on-hit (safe for writethrough:
            // write data already sent to memory, and fill replaces the evicted line)
            assign line_wdata = fill_write ? fill_data : {`CS_WORDS_PER_LINE{write_hit_word}};
            assign line_wren  = fill_write ? {LINE_SIZE{1'b1}} : write_hit_mask;
            assign line_waddr = fill_write ? line_idx : write_hit_idx;
        end else begin : g_no_wren
            `UNUSED_VAR (write_hit_word)
            `UNUSED_VAR (write_hit_mask)
            assign line_wdata = fill_data;
            assign line_wren  = 1'b1;
            assign line_waddr = line_idx;
        end

        wire line_write = fill_write || hit_write;

        wire line_read = read || ((fill || flush) && WRITEBACK);

        VX_dp_ram #(
            .DATAW (`CS_LINE_WIDTH),
            .SIZE  (`CS_LINES_PER_BANK),
            .WRENW (WRENW),
            .OUT_REG (1),
            .RDW_MODE ("R")
        ) data_store (
            .clk   (clk),
            .reset (reset),
            .read  (line_read),
            .write (line_write),
            .wren  (line_wren),
            .waddr (line_waddr),
            .raddr (line_idx),
            .wdata (line_wdata),
            .rdata (line_rdata[i])
        );
    end

    assign read_data = line_rdata[way_idx_r];

endmodule
