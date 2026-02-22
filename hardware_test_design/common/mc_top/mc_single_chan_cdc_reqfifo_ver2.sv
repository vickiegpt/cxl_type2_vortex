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


// Copyright 2024 Intel Corporation.
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

module mc_single_chan_cdc_reqfifo_ver2
  import ddr_mc_top_common_pkg::*;
#(
  parameter REG_ON_REQFIFO_OUTPUT_EN = 1,  // includes ram init and register staging
  parameter REG_ON_REQFIFO_INPUT_EN  = 1,
  parameter MC_RAM_INIT_W_ZERO_EN    = 0,  // includes ram init with no register staging

  parameter REQFIFO_DEPTH_WIDTH     = 6,
  parameter REQFIFO_DATA_WIDTH      = 675
 )
(
  input logic ipclk,
  input logic ipresetn,  // active low

  input logic i_mc_baseaddr_cl_valid,
  input logic i_ram_init_done_ipclk,

  input logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_ADDR_WIDTH-1:0] i_mc_baseaddr_cl,

  input ddr_mc_top_common_pkg::t_reqfifo_data    i_ip2reqfifo_new_req_ipclk,

  output logic  o_mem_cntrl_ready_post_ram_init_ipclk,  // active high
  output logic  o_cdc_reqfifo_full_ipclk,
  output logic  o_cdc_reqfifo_empty_ipclk,

  output logic [REQFIFO_DEPTH_WIDTH-1:0] o_cdc_reqfifo_fill_level_ipclk,

  input logic emifclk,
  input logic emifresetn,  // active low
  input logic i_from_rmw_clear_reqfifo_write_valid_emifclk,
  input logic i_from_rmw_clear_reqfifo_read_valid_emifclk,
  input logic i_from_rmw_memory_ready_emifclk,
  input logic i_rmw2reqfifo_ren_emifclk,

  output logic o_clocked_reqfifo_rdempty_emifclk,
  output logic o_real_reqfifo_rdempty_emifclk,

  output ddr_mc_top_common_pkg::t_reqfifo_data    o_reqfifo2rmw_new_req_emifclk,

  /* signals for ram_init block
  */
  input logic i_ram_init_wr_en_emifclk,
  input logic i_ram_init_done_emifclk,
  input logic i_rmw2raminit_ren_emifclk,

  input logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] i_ram_init_addr_emifclk,
  input logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    i_ram_init_wr_id_emifclk
);

// ================================================================================================
ddr_mc_top_common_pkg::t_reqfifo_data  cdc_reqfifo_din_intf_ipclk;
ddr_mc_top_common_pkg::t_reqfifo_data  cdc_reqfifo_din_intf_comb;
ddr_mc_top_common_pkg::t_reqfifo_data  cdc_reqfifo_dout_intf_comb;

logic [REQFIFO_DEPTH_WIDTH-1:0] reqfifo_wrusedw_ipclk;
logic [REQFIFO_DATA_WIDTH-1:0]  reqfifo_data_in_ipclk;
logic                           reqfifo_wen_ipclk;
logic                           reqfifo_wrfull_ipclk;
logic                           reqfifo_wrfull_ipclk_tmp;
logic                           reqfifo_wrempty_ipclk;

logic [REQFIFO_DATA_WIDTH-1:0] reqfifo_data_out_emifclk;
logic                          reqfifo_ren_emifclk;
logic                          reqfifo_rdempty_emifclk;

logic  write_or_read_active;

// ================================================================================================
/* mc2iafu_ready_eclk = ~reqfifo_full_eclk & ram_init_done_eclk & mc_baseaddr_cl_vld;
*/
assign o_mem_cntrl_ready_post_ram_init_ipclk = ( ~reqfifo_wrfull_ipclk )
                                               & i_ram_init_done_ipclk
                                               & i_mc_baseaddr_cl_valid;

// ================================================================================================

logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH:0] i_ip2reqfifo_new_req_address;

assign i_ip2reqfifo_new_req_address = i_ip2reqfifo_new_req_ipclk.address - i_mc_baseaddr_cl[ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0];

// ================================================================================================
/* clocking input struct for timing
*/
generate if( REG_ON_REQFIFO_INPUT_EN == 1 )
begin : gen_reg_reqfifo_input_on

    always_comb
    begin
      cdc_reqfifo_din_intf_comb = '0;

    if( o_mem_cntrl_ready_post_ram_init_ipclk )
    begin
      cdc_reqfifo_din_intf_comb.write         = i_ip2reqfifo_new_req_ipclk.write;
      cdc_reqfifo_din_intf_comb.partial_write = i_ip2reqfifo_new_req_ipclk.partial_write;
      cdc_reqfifo_din_intf_comb.read          = i_ip2reqfifo_new_req_ipclk.read;
      cdc_reqfifo_din_intf_comb.wr_id         = i_ip2reqfifo_new_req_ipclk.wr_id;
      cdc_reqfifo_din_intf_comb.rd_id         = i_ip2reqfifo_new_req_ipclk.rd_id;
      cdc_reqfifo_din_intf_comb.address       = i_ip2reqfifo_new_req_address[ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0];
      cdc_reqfifo_din_intf_comb.req_mdata     = i_ip2reqfifo_new_req_ipclk.req_mdata;
      cdc_reqfifo_din_intf_comb.write_ras_sbe = i_ip2reqfifo_new_req_ipclk.write_ras_sbe;
      cdc_reqfifo_din_intf_comb.write_ras_dbe = i_ip2reqfifo_new_req_ipclk.write_ras_dbe;
      cdc_reqfifo_din_intf_comb.write_poison  = i_ip2reqfifo_new_req_ipclk.write_poison;
      cdc_reqfifo_din_intf_comb.byteenable    = i_ip2reqfifo_new_req_ipclk.byteenable;
      cdc_reqfifo_din_intf_comb.writedata     = i_ip2reqfifo_new_req_ipclk.writedata;
    end
    end

    always_ff @( posedge ipclk )
    begin
         cdc_reqfifo_din_intf_ipclk <= cdc_reqfifo_din_intf_comb;
    end

end
else begin : gen_reg_reqfifo_input_off

    assign cdc_reqfifo_din_intf_comb.write         = i_ip2reqfifo_new_req_ipclk.write;
    assign cdc_reqfifo_din_intf_comb.partial_write = i_ip2reqfifo_new_req_ipclk.partial_write;
    assign cdc_reqfifo_din_intf_comb.read          = i_ip2reqfifo_new_req_ipclk.read;
    assign cdc_reqfifo_din_intf_comb.wr_id         = i_ip2reqfifo_new_req_ipclk.wr_id;
    assign cdc_reqfifo_din_intf_comb.rd_id         = i_ip2reqfifo_new_req_ipclk.rd_id;
    assign cdc_reqfifo_din_intf_comb.address       = i_ip2reqfifo_new_req_address[ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0];
    assign cdc_reqfifo_din_intf_comb.req_mdata     = i_ip2reqfifo_new_req_ipclk.req_mdata;
    assign cdc_reqfifo_din_intf_comb.write_ras_sbe = i_ip2reqfifo_new_req_ipclk.write_ras_sbe;
    assign cdc_reqfifo_din_intf_comb.write_ras_dbe = i_ip2reqfifo_new_req_ipclk.write_ras_dbe;
    assign cdc_reqfifo_din_intf_comb.write_poison  = i_ip2reqfifo_new_req_ipclk.write_poison;
    assign cdc_reqfifo_din_intf_comb.byteenable    = i_ip2reqfifo_new_req_ipclk.byteenable;
    assign cdc_reqfifo_din_intf_comb.writedata     = i_ip2reqfifo_new_req_ipclk.writedata;

    assign cdc_reqfifo_din_intf_ipclk = cdc_reqfifo_din_intf_comb;

end
endgenerate

localparam REQFIFO_DATA_FIFO_VS_STRUCT_DIFF = REQFIFO_DATA_WIDTH - ddr_mc_top_common_pkg::MC_LOCAL_REQFIFO_DATA_BW;
logic [REQFIFO_DATA_FIFO_VS_STRUCT_DIFF-1:0] upper_bits_zeros;
assign upper_bits_zeros = '0;

assign reqfifo_data_in_ipclk = {upper_bits_zeros, cdc_reqfifo_din_intf_ipclk};

// ================================================================================================
/* write_or_read_active for reqfifo_wen
*/
generate if( REG_ON_REQFIFO_INPUT_EN == 1 )
begin : gen_reg_reqfifo_wen_on

    always_ff @( posedge ipclk )
    begin
           if( ~ipresetn )                             write_or_read_active <= 1'b0;
      else if( o_mem_cntrl_ready_post_ram_init_ipclk ) write_or_read_active <= i_ip2reqfifo_new_req_ipclk.write | i_ip2reqfifo_new_req_ipclk.read;
      else                                             write_or_read_active <= write_or_read_active;
    end

end
else begin : gen_reg_reqfifo_wen_on

    assign write_or_read_active = i_ip2reqfifo_new_req_ipclk.write | i_ip2reqfifo_new_req_ipclk.read;

end
endgenerate


assign reqfifo_wen_ipclk = write_or_read_active & o_mem_cntrl_ready_post_ram_init_ipclk;

// ================================================================================================
/* width = 650; depth=64 -> quartus generated clock domain crossing (cdc) ram-based fifo
*/
reqfifo  reqfifo_inst
(
    .wrclk ( ipclk ),
    .rdclk ( emifclk ),
    .aclr  ( ~ipresetn ),

    .wrreq   ( reqfifo_wen_ipclk        ),
    .data    ( reqfifo_data_in_ipclk    ),
    .wrusedw ( reqfifo_wrusedw_ipclk    ),
    .wrfull  ( reqfifo_wrfull_ipclk_tmp ),
    .wrempty ( reqfifo_wrempty_ipclk    ),

    .rdreq   ( reqfifo_ren_emifclk      ),
    .q       ( reqfifo_data_out_emifclk ),
    .rdempty ( reqfifo_rdempty_emifclk  )
);


assign reqfifo_wrfull_ipclk = reqfifo_wrfull_ipclk_tmp
                            | ( reqfifo_wrusedw_ipclk >= 'd62 );

assign o_cdc_reqfifo_full_ipclk = reqfifo_wrfull_ipclk;

assign o_cdc_reqfifo_empty_ipclk = reqfifo_wrempty_ipclk;

assign o_cdc_reqfifo_fill_level_ipclk = reqfifo_wrusedw_ipclk;

assign o_real_reqfifo_rdempty_emifclk = reqfifo_rdempty_emifclk;

// look ahead fifo, so REN confirms reception of output
assign cdc_reqfifo_dout_intf_comb = reqfifo_rdempty_emifclk
                                    ? '0
                                    : ddr_mc_top_common_pkg::t_reqfifo_data'( reqfifo_data_out_emifclk[ddr_mc_top_common_pkg::MC_LOCAL_REQFIFO_DATA_BW-1:0] );

// ================================================================================================
/* logic to read from reqfifo on emifclk
*/
assign reqfifo_ren_emifclk = i_rmw2reqfifo_ren_emifclk;

// ================================================================================================
/* clocking of the cdc_reqfifo_dout_intf_comb output from the reqfifo based on down stream ready
   captured in the reqfifo_ren pulsing
*/
  // generate if( REG_ON_REQFIFO_OUTPUT_EN == 1 )
  //begin : gen_reg_on_reqfifo_output_on_and_ram_init_on
    /* creating a staged version of the cdc_reqfIfo's empty flag for aligning to front of the new
       packet out of the cdc_reqfifo down the pipeline
       Used by emif-axi but not emif-avmm
    */
    logic prev_reqfifo_rdempty_emifclk;
    logic prev_reqfifo_rdempty_comb;
    logic      reqfifo_rdempty_comb;

    assign prev_reqfifo_rdempty_comb = i_from_rmw_memory_ready_emifclk ? reqfifo_rdempty_emifclk : prev_reqfifo_rdempty_emifclk;

    assign reqfifo_rdempty_comb = i_from_rmw_memory_ready_emifclk ? prev_reqfifo_rdempty_emifclk : o_clocked_reqfifo_rdempty_emifclk;

    always_ff @( posedge emifclk )
    begin
           prev_reqfifo_rdempty_emifclk <= ~emifresetn ? 1'b1 : prev_reqfifo_rdempty_comb;
      o_clocked_reqfifo_rdempty_emifclk <= ~emifresetn ? 1'b1 : reqfifo_rdempty_comb;
    end

    logic mem_write_emifclk;
    logic mem_write_comb;

    always_comb
    begin
      if( ~i_ram_init_done_emifclk )
      begin
                if( i_rmw2raminit_ren_emifclk )                    mem_write_comb = i_ram_init_wr_en_emifclk;
           else if( i_from_rmw_clear_reqfifo_write_valid_emifclk ) mem_write_comb = 1'b0;
           else                                                    mem_write_comb = mem_write_emifclk;
      end
      else begin
                if( reqfifo_ren_emifclk )                          mem_write_comb = cdc_reqfifo_dout_intf_comb.write;
           else if( i_from_rmw_clear_reqfifo_write_valid_emifclk ) mem_write_comb = 1'b0;
           else                                                    mem_write_comb = mem_write_emifclk;
      end
    end

    always_ff @( posedge emifclk ) mem_write_emifclk <= ~emifresetn ? 1'b0 : mem_write_comb;

    logic mem_read_emifclk;
    logic mem_read_comb;

    assign mem_read_comb = ~i_ram_init_done_emifclk
                            ? 1'b0
                            : reqfifo_ren_emifclk
                              ? cdc_reqfifo_dout_intf_comb.read
                              : i_from_rmw_clear_reqfifo_read_valid_emifclk
                                ? 1'b0
                                : mem_read_emifclk;

    always_ff @( posedge emifclk ) mem_read_emifclk <= ~emifresetn ? 1'b0 : mem_read_comb;

    logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] mem_address_emifclk;
    logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] mem_address_comb;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] mem_writedata_emifclk;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] mem_writedata_comb;

    logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_BE_WIDTH-1:0] mem_byteenable_emifclk;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_BE_WIDTH-1:0] mem_byteenable_comb;

    logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] mem_wr_id_emifclk;
    logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] mem_wr_id_comb;
    logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] mem_rd_id_emifclk;
    logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] mem_rd_id_comb;

    logic [ddr_mc_top_common_pkg::MCTOP_MC_MDATA_WIDTH-1:0] mem_req_mdata_emifclk;
    logic [ddr_mc_top_common_pkg::MCTOP_MC_MDATA_WIDTH-1:0] mem_req_mdata_comb;

    logic mem_write_partial_emifclk;
    logic mem_write_partial_comb;
    logic mem_write_poison_emifclk;
    logic mem_write_poison_comb;
    logic mem_write_ras_dbe_emifclk;
    logic mem_write_ras_dbe_comb;
    logic mem_write_ras_sbe_emifclk;
    logic mem_write_ras_sbe_comb;

  always_comb
  begin
    mem_address_comb = mem_address_emifclk;
    mem_wr_id_comb   = mem_wr_id_emifclk;

      if( i_ram_init_done_emifclk & reqfifo_ren_emifclk )
      begin
           mem_address_comb = cdc_reqfifo_dout_intf_comb.address;
           mem_wr_id_comb   = cdc_reqfifo_dout_intf_comb.wr_id;
      end
      else if( ~i_ram_init_done_emifclk & i_rmw2raminit_ren_emifclk )
      begin
           mem_address_comb = i_ram_init_addr_emifclk;
           mem_wr_id_comb   = i_ram_init_wr_id_emifclk;
    end
  end

  assign mem_write_partial_comb = ~i_ram_init_done_emifclk
                                  ? 1'b0
                                  : reqfifo_ren_emifclk
                                    ? cdc_reqfifo_dout_intf_comb.partial_write
                                    : mem_write_partial_emifclk;

    assign mem_byteenable_comb = ~i_ram_init_done_emifclk
                                 ? '1
                                 : reqfifo_ren_emifclk
                                   ? cdc_reqfifo_dout_intf_comb.byteenable
                                   : mem_byteenable_emifclk;

    assign mem_write_poison_comb = ~i_ram_init_done_emifclk
                                   ? 1'b0
                                   : reqfifo_ren_emifclk
                                     ? cdc_reqfifo_dout_intf_comb.write_poison
                                     : mem_write_poison_emifclk;

    assign mem_write_ras_sbe_comb = ~i_ram_init_done_emifclk
                                    ? 1'b0
                                    : reqfifo_ren_emifclk
                                      ? cdc_reqfifo_dout_intf_comb.write_ras_sbe
                                      : mem_write_ras_sbe_emifclk;

    assign mem_write_ras_dbe_comb = ~i_ram_init_done_emifclk
                                    ? 1'b0
                                    : reqfifo_ren_emifclk
                                      ? cdc_reqfifo_dout_intf_comb.write_ras_dbe
                                      : mem_write_ras_dbe_emifclk;

    assign mem_rd_id_comb = ~i_ram_init_done_emifclk
                            ? '0
                            : reqfifo_ren_emifclk
                              ? cdc_reqfifo_dout_intf_comb.rd_id
                              : mem_rd_id_emifclk;

    assign mem_writedata_comb = ~i_ram_init_done_emifclk
                                ? '0
                                : reqfifo_ren_emifclk
                                  ? cdc_reqfifo_dout_intf_comb.writedata
                                  : mem_writedata_emifclk;

    assign mem_req_mdata_comb = ~i_ram_init_done_emifclk
                                ? '0
                                : reqfifo_ren_emifclk
                                  ? cdc_reqfifo_dout_intf_comb.req_mdata
                                  : mem_req_mdata_emifclk;


    always_ff @( posedge emifclk )
    begin
      mem_write_ras_dbe_emifclk <= mem_write_ras_dbe_comb;
      mem_write_ras_sbe_emifclk <= mem_write_ras_sbe_comb;
      mem_byteenable_emifclk    <= mem_byteenable_comb;    // need reset to zero here?
      mem_address_emifclk       <= mem_address_comb;       // need reset to zero here?
      mem_wr_id_emifclk         <= mem_wr_id_comb;         // need reset to zero here?
      mem_writedata_emifclk     <= mem_writedata_comb;
      mem_req_mdata_emifclk     <= mem_req_mdata_comb;
      mem_rd_id_emifclk         <= mem_rd_id_comb;

      mem_write_partial_emifclk <= ~emifresetn ? 1'b0 : mem_write_partial_comb;
      mem_write_poison_emifclk  <= ~emifresetn ? 1'b0 : mem_write_poison_comb;
    end

    always_comb
    begin
       o_reqfifo2rmw_new_req_emifclk.write         = mem_write_emifclk;
       o_reqfifo2rmw_new_req_emifclk.partial_write = mem_write_partial_emifclk;
       o_reqfifo2rmw_new_req_emifclk.read          = mem_read_emifclk;
       o_reqfifo2rmw_new_req_emifclk.wr_id         = mem_wr_id_emifclk;
       o_reqfifo2rmw_new_req_emifclk.rd_id         = mem_rd_id_emifclk;
       o_reqfifo2rmw_new_req_emifclk.address       = mem_address_emifclk;
       o_reqfifo2rmw_new_req_emifclk.req_mdata     = mem_req_mdata_emifclk;
       o_reqfifo2rmw_new_req_emifclk.write_ras_sbe = mem_write_ras_sbe_emifclk;
       o_reqfifo2rmw_new_req_emifclk.write_ras_dbe = mem_write_ras_dbe_emifclk;
       o_reqfifo2rmw_new_req_emifclk.write_poison  = mem_write_poison_emifclk;
       o_reqfifo2rmw_new_req_emifclk.byteenable    = mem_byteenable_emifclk;
       o_reqfifo2rmw_new_req_emifclk.writedata     = mem_writedata_emifclk;
    end

  //end // : gen_reg_on_reqfifo_output_on_and_ram_init_on
  //else if (MC_RAM_INIT_W_ZERO_EN == 1)
  //begin : gen_reg_on_reqfifo_output_off_and_ram_init_on
  //end // : gen_reg_on_reqfifo_output_off_and_ram_init_on
  //else begin : gen_reg_on_reqfifo_output_off_and_ram_init_off
  //end // : gen_reg_on_reqfifo_output_off_and_ram_init_off

  // not supporting the unclocked variations unless needed or requested !!!!!!!!!!!!!!!!!!!

//end
//endgenerate

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3TwK6eAgapsO+BZqaxZO0W1lJ4k70FCBV07CmkpYLKe7lbS9gkYjeTkmN3yxYtsYezbsgHX6DpRfQS6F+Ck6mlrJGr4YDCVcOTMpB6oTMZeduwy10l45GqqS9EbHiPVlfK1wTTxKwmbqm0XNraKP/Qdtz2BzFaFb5feftF8tlBlF1HYdwph254JxrwuAGNhszAnZU/YOXy8uE90WtGo0o5sPpKywej4kuBle8MOx6sdlowu960pSHWdvz4So9RRfmu/lbpCg7Y2Zp4n7t8KJCHOOuO17JG4dwBN2d22si5HICVE9tt9YTOeM6+xj0ASp8Dc+aKkUM8vRN73l9IQ4M/0hnPOCTmKWTEGeBe9c+ru0eu6yddFTcHyQlTT0khAIDu43l3zApPPFkpfkHNAVGI8Cp5+R12f3c6XbIzIXxSGQPsMXVC7rCFphL0Oz6sgk8Qjsffm0o928btFELWo9/eGblUtWnE/VCLh1LpvbFEiZ9294RwD/bT0XwbCmThoSOHTau9NGcusx7C0Miu0gNn1ZYsrQgD2+2WijkZkf+jXheyqdwjXFQmrF6coYeDCVDlJKOBLZ/x1p4ppPWUwFl8CFdD7VLK8uUB7M5j+S87ZOyCd/jxlIIN4GhUbdy+0l73SbxJgbqdeGtYycac3z58alaM2X3ipwqAFGPXNqs3cm3nl4tjSnoFR8YQhi6D7GEkDhzbTPzuPwx4LRGFnJibRqYKd+8kC5J+cJJA6YfwmbXSZC2DF0vvZkiONp2P8ls9taaAWLw64pWATt+1x0ZMK"
`endif