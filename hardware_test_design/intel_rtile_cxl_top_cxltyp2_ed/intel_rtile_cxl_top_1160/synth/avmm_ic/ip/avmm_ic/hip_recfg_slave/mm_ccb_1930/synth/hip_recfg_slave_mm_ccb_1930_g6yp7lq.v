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


// --------------------------------------
// Avalon-MM clock crossing bridge
//
// Clock crosses MM commands and responses with the
// help of asynchronous FIFOs.
//
// This bridge will stop emitting read commands when
// too many read commands are in flight to avoid 
// response FIFO overflow.
// --------------------------------------

`timescale 1 ns / 1 ns
module hip_recfg_slave_mm_ccb_1930_g6yp7lq 
#(
    parameter DATA_WIDTH            = 32,
    parameter SYMBOL_WIDTH          = 8,
    parameter HDL_ADDR_WIDTH        = 10,
    parameter BURSTCOUNT_WIDTH      = 1,

    parameter COMMAND_FIFO_DEPTH    = 4,
    parameter RESPONSE_FIFO_DEPTH   = 4,

    parameter ENABLE_RESPONSE       = 0,

    parameter MASTER_SYNC_DEPTH     = 2,
    parameter SLAVE_SYNC_DEPTH      = 2,
    parameter SYNC_RESET            = 0,

    // --------------------------------------
    // Derived parameters
    // --------------------------------------
    parameter BYTEEN_WIDTH = DATA_WIDTH / SYMBOL_WIDTH
)
(
    input                           s0_clk,
    input                           s0_reset,

    input                           m0_clk,
    input                           m0_reset,

    output                          s0_waitrequest,
    output [DATA_WIDTH-1:0]         s0_readdata,
    output                          s0_readdatavalid,
    output [1:0]                    s0_response,
    input  [BURSTCOUNT_WIDTH-1:0]   s0_burstcount,
    input  [DATA_WIDTH-1:0]         s0_writedata,
    input  [HDL_ADDR_WIDTH-1:0]     s0_address, 
    input                           s0_write,  
    input                           s0_read,  
    output                          s0_writeresponsevalid,
    input  [BYTEEN_WIDTH-1:0]       s0_byteenable,  
    input                           s0_debugaccess,

    input                           m0_waitrequest,
    input  [DATA_WIDTH-1:0]         m0_readdata,
    input                           m0_readdatavalid,
    input  [1:0]                    m0_response,
    output [BURSTCOUNT_WIDTH-1:0]   m0_burstcount,
    output [DATA_WIDTH-1:0]         m0_writedata,
    output [HDL_ADDR_WIDTH-1:0]     m0_address, 
    output                          m0_write,  
    input                           m0_writeresponsevalid,
    output                          m0_read,  
    output [BYTEEN_WIDTH-1:0]       m0_byteenable,
    output                          m0_debugaccess
);

    localparam CMD_WIDTH = BURSTCOUNT_WIDTH + DATA_WIDTH + HDL_ADDR_WIDTH 
                    + BYTEEN_WIDTH 
                    + 3;        // read, write, debugaccess

    localparam NUMSYMBOLS    = DATA_WIDTH / SYMBOL_WIDTH;
    // Pass 2 bits of resp + 1 bit of readdatavalid whne response is enabled
    localparam RSP_WIDTH     = ENABLE_RESPONSE ? (DATA_WIDTH+3) : DATA_WIDTH;
    localparam MAX_BURST     = (1 << (BURSTCOUNT_WIDTH-1));
    localparam COUNTER_WIDTH = log2ceil(RESPONSE_FIFO_DEPTH) + 1;
    localparam NON_BURSTING  = (MAX_BURST == 1);
    localparam BURST_WORDS_W = BURSTCOUNT_WIDTH;

    // --------------------------------------
    // Signals
    // --------------------------------------
    wire [CMD_WIDTH-1:0]     s0_cmd_payload;
    wire [CMD_WIDTH-1:0]     m0_cmd_payload;
    wire                     s0_cmd_valid;
    wire                     m0_cmd_valid;
    wire                     m0_internal_write;
    wire                     m0_internal_read;
    wire                     s0_cmd_ready;
    wire                     m0_cmd_ready;
    reg  [COUNTER_WIDTH-1:0] pending_read_count;
    wire [COUNTER_WIDTH-1:0] space_avail;
    wire                     stop_cmd;
    reg                      stop_cmd_r;
    wire                     m0_cmd_accepted;
    wire                     m0_rd_wr_valid;
    wire                     m0_rsp_ready;
    reg                      old_read;
    reg                      old_cmd;
    wire [BURST_WORDS_W-1:0] m0_burstcount_words;

    // --------------------------------------
    // Command FIFO
    // --------------------------------------
    (* altera_attribute = "-name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON" *) 
    hip_recfg_slave_mm_ccb_st_dc_fifo_1930_465h6hy #(
        .SYMBOLS_PER_BEAT (1),
        .BITS_PER_SYMBOL  (CMD_WIDTH),
        .FIFO_DEPTH       (COMMAND_FIFO_DEPTH),
        .WR_SYNC_DEPTH    (MASTER_SYNC_DEPTH),
        .RD_SYNC_DEPTH    (SLAVE_SYNC_DEPTH),
        .BACKPRESSURE_DURING_RESET (1),
        .SYNC_RESET         (SYNC_RESET)
    ) 
    cmd_fifo
    (
        .in_clk          (s0_clk),
        .in_reset_n      (~s0_reset),
        .out_clk         (m0_clk),
        .out_reset_n     (~m0_reset),

        .in_data         (s0_cmd_payload),
        .in_valid        (s0_cmd_valid),
        .in_ready        (s0_cmd_ready),

        .out_data        (m0_cmd_payload),
        .out_valid       (m0_cmd_valid),
        .out_ready       (m0_cmd_ready)

        
        
    );


    // Generation of internal reset synchronization
   reg internal_sclr;
   generate if (SYNC_RESET == 1) begin // rst_syncronizer
      always @ (posedge m0_clk) begin
         internal_sclr <= m0_reset;
      end
   end
   endgenerate

    // --------------------------------------
    // Command payload
    // --------------------------------------
    assign s0_waitrequest = ~s0_cmd_ready;
    assign s0_cmd_valid   = s0_write | s0_read;

    assign s0_cmd_payload = {s0_address, 
                             s0_burstcount, 
                             s0_read, 
                             s0_write, 
                             s0_writedata, 
                             s0_byteenable,
                             s0_debugaccess};
    assign {m0_address, 
            m0_burstcount, 
            m0_internal_read, 
            m0_internal_write,
            m0_writedata, 
            m0_byteenable,
            m0_debugaccess} = m0_cmd_payload;


    generate 
        if (ENABLE_RESPONSE) begin :RD_WR_ACCEPT
            assign m0_rd_wr_valid = m0_readdatavalid | m0_writeresponsevalid ;
            assign m0_cmd_ready = ~m0_waitrequest & 
                                  ~((m0_internal_read|m0_internal_write) & m0_cmd_valid  & stop_cmd_r & ~old_cmd);
            assign m0_write =  m0_internal_write & m0_cmd_valid & (~stop_cmd_r | old_cmd);
            assign m0_read  =  m0_internal_read  & m0_cmd_valid & (~stop_cmd_r | old_cmd);
            assign m0_cmd_accepted  = (m0_write | m0_read) & ~m0_waitrequest;
        end
        else begin : RD_ACCEPT
            assign m0_rd_wr_valid = m0_readdatavalid;
            assign m0_cmd_ready = ~m0_waitrequest & 
                                  ~(m0_internal_read & stop_cmd_r & ~old_read);
            assign m0_write =  m0_internal_write & m0_cmd_valid ;
            assign m0_read  =  m0_internal_read  & m0_cmd_valid & (~stop_cmd_r | old_read);
            assign m0_cmd_accepted  = m0_read & ~m0_waitrequest;
        end
    endgenerate

    // ---------------------------------------------
    // the non-bursting case
    // ---------------------------------------------
    generate if (NON_BURSTING)
    begin
      if (SYNC_RESET == 0) begin  
    
           always @(posedge m0_clk, posedge m0_reset) begin
               if (m0_reset) begin
                   pending_read_count <= 0;
               end
               else begin
                   if (m0_cmd_accepted & m0_rd_wr_valid)
                       pending_read_count <= pending_read_count;
                   else if (m0_rd_wr_valid)
                       pending_read_count <= pending_read_count - 1'd1;
                   else if (m0_cmd_accepted)
                       pending_read_count <= pending_read_count + 1'd1;
               end
           end
      end // async_rst0

      else begin 
           always @(posedge m0_clk) begin
               if (internal_sclr) begin
                   pending_read_count <= 0;
               end
               else begin
                   if (m0_cmd_accepted & m0_rd_wr_valid)
                       pending_read_count <= pending_read_count;
                   else if (m0_rd_wr_valid)
                       pending_read_count <= pending_read_count - 1'd1;
                   else if (m0_cmd_accepted)
                       pending_read_count <= pending_read_count + 1'd1;
               end
           end
      end // sync_rst0
    end // if non_bursting

    // ---------------------------------------------
    // the bursting case
    // ---------------------------------------------
    else begin
        // N responses for single read command
        // single reponse for N write commands
        // detect first  writes, load the wr count on first write and then
        // decrement
        // you know write is through once counter reaches 1
        reg  [BURST_WORDS_W-1:0] m0_wr_count;
        wire [BURST_WORDS_W-1:0] m0_wr_bursrcount;

        assign m0_wr_bursrcount = (m0_wr_count==1) ? 1 : 0 ;

        if (ENABLE_RESPONSE) begin : WR_RESP_COUNT
            assign m0_burstcount_words = m0_read ? m0_burstcount : m0_wr_bursrcount;
        end
        else begin : NO_WR_RESP_COUNTS
            assign m0_burstcount_words = m0_burstcount;
        end

      if (SYNC_RESET == 0 ) begin 
           always @ (posedge m0_clk, posedge m0_reset)
               if (m0_reset)
                   m0_wr_count <= 1;
               else if (m0_wr_count==1 && m0_write && ~m0_waitrequest)
                   m0_wr_count <= m0_burstcount;
               else if (m0_write && ~m0_waitrequest)
                   m0_wr_count <= m0_wr_count-1;

           always @(posedge m0_clk, posedge m0_reset) begin
               if (m0_reset) begin
                   pending_read_count <= 0;
               end
               else begin
                   if (m0_cmd_accepted & m0_rd_wr_valid)
                       pending_read_count <= pending_read_count +
                                               m0_burstcount_words - 1'd1;
                   else if (m0_rd_wr_valid)
                       pending_read_count <= pending_read_count - 1'd1;
                   else if (m0_cmd_accepted)
                       pending_read_count <= pending_read_count +
                                               m0_burstcount_words;  
               end
           end
      end // async_rst1
      else begin 
           always @ (posedge m0_clk)
               if (internal_sclr)
                   m0_wr_count <= 1;
               else if (m0_wr_count==1 && m0_write && ~m0_waitrequest)
                   m0_wr_count <= m0_burstcount;
               else if (m0_write && ~m0_waitrequest)
                   m0_wr_count <= m0_wr_count-1;

           always @(posedge m0_clk) begin
               if (internal_sclr) begin
                   pending_read_count <= 0;
               end
               else begin
                   if (m0_cmd_accepted & m0_rd_wr_valid)
                       pending_read_count <= pending_read_count +
                                               m0_burstcount_words - 1'd1;
                   else if (m0_rd_wr_valid)
                       pending_read_count <= pending_read_count - 1'd1;
                   else if (m0_cmd_accepted)
                       pending_read_count <= pending_read_count +
                                               m0_burstcount_words;  
               end
           end // @always
      end // sync_rst1


    end // else bursting
    endgenerate
    
    // in case of bursting, pening read count already calculates burst_count 
    // hence no need to add 2*MAX_BURST
    // fix this only for write-response mode for now
    generate 
        if (ENABLE_RESPONSE) begin : WITH_RESP_CALC
            assign stop_cmd = pending_read_count > space_avail;
        end
        else begin : NO_RSP_CALC
            assign stop_cmd = (pending_read_count + 2*MAX_BURST) > space_avail;
        end
    endgenerate
   
    generate
    if (SYNC_RESET == 0) begin // async_rst2
       always @(posedge m0_clk, posedge m0_reset) begin
           if (m0_reset) begin
               stop_cmd_r <= 1'b0;
               old_read   <= 1'b0;
               old_cmd    <= 1'b0;
           end
           else begin
               stop_cmd_r <= stop_cmd;
               old_read   <= m0_read & m0_waitrequest;
               old_cmd    <= (m0_write | m0_read) & m0_waitrequest;
           end
       end
     end // async_rst2

     else begin
       always @(posedge m0_clk) begin
           if (internal_sclr) begin
               stop_cmd_r <= 1'b0;
               old_read   <= 1'b0;
               old_cmd    <= 1'b0;
           end
           else begin
               stop_cmd_r <= stop_cmd;
               old_read   <= m0_read & m0_waitrequest;
               old_cmd    <= (m0_write | m0_read) & m0_waitrequest;
           end
       end
     end // sync_rst2
     endgenerate
    // --------------------------------------
    // Response FIFO
    // Contains : reponse, readdatavalid, readdata
    // Why readdatavalid acts as Control and Data here ???? ->
    // Avalon-MM has single response field. So FIFO will be written with
    // - readdatavalid | writeresponsevalid
    // But how do you detect - whether its Rd response or WR response on FIFO
    // Output ?????? We add readdatavalid along data used to detect RD vs WR
    // response
    //
    //
    // --------------------------------------
    wire [RSP_WIDTH-1:0] rsp_fifo_in,rsp_fifo_out;
    wire                 rsp_fifo_in_valid,rsp_fifo_out_valid;
    generate 
        if (ENABLE_RESPONSE) begin : WITH_RESP
            assign rsp_fifo_in = {m0_response,m0_readdatavalid,m0_readdata};
            assign rsp_fifo_in_valid = m0_readdatavalid | m0_writeresponsevalid;

            assign s0_readdata           = rsp_fifo_out[DATA_WIDTH-1:0];
            assign s0_response           = rsp_fifo_out[RSP_WIDTH-1:RSP_WIDTH-2];
            assign s0_readdatavalid      = rsp_fifo_out_valid & rsp_fifo_out[RSP_WIDTH-3];
            assign s0_writeresponsevalid = rsp_fifo_out_valid & (!rsp_fifo_out[RSP_WIDTH-3]);
        end
        else begin : NO_RESP
            assign rsp_fifo_in = m0_readdata;
            assign rsp_fifo_in_valid = m0_readdatavalid ;

            assign s0_readdata           = rsp_fifo_out;
            assign s0_response           = 2'b00;
            assign s0_readdatavalid      = rsp_fifo_out_valid ;
            assign s0_writeresponsevalid = 1'b0;
        end
    endgenerate 
       
    (* altera_attribute = "-name ALLOW_ANY_RAM_SIZE_FOR_RECOGNITION ON" *) 
    hip_recfg_slave_mm_ccb_st_dc_fifo_1930_hrcugta #(
        .SYMBOLS_PER_BEAT   (1),
        .BITS_PER_SYMBOL    (RSP_WIDTH),
        .FIFO_DEPTH         (RESPONSE_FIFO_DEPTH),
        .WR_SYNC_DEPTH      (SLAVE_SYNC_DEPTH),
        .RD_SYNC_DEPTH      (MASTER_SYNC_DEPTH),
        .USE_SPACE_AVAIL_IF (1),
        .SYNC_RESET         (SYNC_RESET)
    ) 
    rsp_fifo
    (
        .in_clk           (m0_clk),
        .in_reset_n       (~m0_reset),
        .out_clk          (s0_clk),
        .out_reset_n      (~s0_reset),

        .in_data          (rsp_fifo_in),
        .in_valid         (rsp_fifo_in_valid),

        // ------------------------------------
        // must never overflow, or we're in trouble
        // (we cannot backpressure the response)
        // ------------------------------------
        .in_ready         (m0_rsp_ready),

        .out_data         (rsp_fifo_out),
        .out_valid        (rsp_fifo_out_valid),
        .out_ready        (1'b1),

        .space_avail_data (space_avail)

    );

// synthesis translate_off
    always @(posedge m0_clk) begin
        if (~m0_rsp_ready & (m0_readdatavalid|m0_writeresponsevalid) ) begin
            $display("%t %m: internal error, response fifo overflow", $time);
        end

        if (pending_read_count > space_avail) begin
            $display("%t %m: internal error, too many pending reads/writes", $time);
        end
    end
// synthesis translate_on

    // --------------------------------------------------
    // Calculates the log2ceil of the input value
    // --------------------------------------------------
    function integer log2ceil;
        input integer val;
        integer i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1; 
            end
        end
    endfunction

endmodule  

