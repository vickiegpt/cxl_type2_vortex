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

module afu_atomic_test_engine
  import cafu_common_pkg::*;
  import tmp_cafu_csr0_cfg_pkg::*;
  import afu_ate_mem_target_pkg::*;
(
  input logic  rtl_clk,  //IP clk
  input logic  reset_n,  //IP reset
   
   
   /*
     AXI-MM interface - write address channel
   */
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ADDR_WIDTH-1:0]         awaddr, 
   output logic [cafu_common_pkg::CAFU_AFU_AXI_BURST_WIDTH-1:0]            awburst,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_CACHE_WIDTH-1:0]            awcache,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]           awid,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] awlen,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_LOCK_WIDTH-1:0]             awlock,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_QOS_WIDTH-1:0]              awqos,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_PROT_WIDTH-1:0]             awprot,
   input                                             awready,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_REGION_WIDTH-1:0]           awregion,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_SIZE_WIDTH-1:0]             awsize,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_AWATOP_WIDTH-1:0]           awatop,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_AWUSER_WIDTH-1:0]           awuser,
   output logic                                      awvalid,
   /*
     AXI-MM interface - write data channel
   */
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]         wdata,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]           wid,
   output logic                                      wlast,
   input                                             wready,
   output logic [(cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH/8)-1:0]     wstrb,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_WUSER_WIDTH-1:0]            wuser,
   output logic                                      wvalid,  
   /*
     AXI-MM interface - write response channel
   */ 
   input        [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]           bid,
   output logic                                      bready,
   input        [cafu_common_pkg::CAFU_AFU_AXI_RESP_WIDTH-1:0]             bresp,
   input        [cafu_common_pkg::CAFU_AFU_AXI_BUSER_WIDTH-1:0]            buser,
   input                                             bvalid,
   /*
     AXI-MM interface - read address channel
   */
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ADDR_WIDTH-1:0]         araddr,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_BURST_WIDTH-1:0]            arburst,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_CACHE_WIDTH-1:0]            arcache,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]           arid,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_MAX_BURST_LENGTH_WIDTH-1:0] arlen,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_LOCK_WIDTH-1:0]             arlock,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_PROT_WIDTH-1:0]             arprot,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_QOS_WIDTH-1:0]              arqos,
   input                                             arready,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_REGION_WIDTH-1:0]           arregion,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_SIZE_WIDTH-1:0]             arsize,
   output logic [cafu_common_pkg::CAFU_AFU_AXI_ARUSER_WIDTH-1:0]           aruser,
   output logic                                      arvalid,
   /*
     AXI-MM interface - read response channel
   */ 
   input       [cafu_common_pkg::CAFU_AFU_AXI_MAX_DATA_WIDTH-1:0]          rdata,
   input       [cafu_common_pkg::CAFU_AFU_AXI_MAX_ID_WIDTH-1:0]            rid,
   input                                             rlast,
   output logic                                      rready,
   input       [cafu_common_pkg::CAFU_AFU_AXI_RESP_WIDTH-1:0]              rresp,
   input       [cafu_common_pkg::CAFU_AFU_AXI_RUSER_WIDTH-1:0]             ruser,
   input                                             rvalid,
   
   /*
     From cfg to ATE
   */ 
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_CTRL_t            afu_ate_ctrl               ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_FORCE_DISABLE_t   afu_ate_force_disable      ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ENGINE_INITIATE_t        afu_ate_initiate           ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_ATTR_BYTE_EN_t           afu_ate_attr_byte_en       ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_TARGET_ADDRESS_t         afu_ate_target_address     ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_COMPARE_VALUE_0_t        afu_ate_compare_value_0    ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_COMPARE_VALUE_1_t        afu_ate_compare_value_1    ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_SWAP_VALUE_0_t           afu_ate_swap_value_0       ,
   input tmp_cafu_csr0_cfg_pkg::tmp_AFU_ATOMIC_TEST_SWAP_VALUE_1_t           afu_ate_swap_value_1       ,
  
   /*
     from cfg to ATE for decoding the host/device address
   */
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_GBL_CTRL_t                       hdm_dec_gbl_ctrl  ,
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_CTRL_t                           hdm_dec_ctrl      ,    
   input tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1HIGH_t                     dvsec_fbrange1high,
   input tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1LOW_t                      dvsec_fbrange1low ,
   input tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZHIGH_t                   fbrange1_sz_high  ,
   input tmp_cafu_csr0_cfg_pkg::tmp_DVSEC_FBRANGE1SZLOW_t                    fbrange1_sz_low   ,
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASEHIGH_t                       hdm_dec_basehigh  ,
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_BASELOW_t                        hdm_dec_baselow   ,
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZEHIGH_t                       hdm_dec_sizehigh  ,
   input tmp_cafu_csr0_cfg_pkg::tmp_HDM_DEC_SIZELOW_t                        hdm_dec_sizelow   ,

   
   /*
     From ATE to config
   */
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_ENGINE_STATUS_t      afu_ate_status            ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_0_t  afu_ate_read_data_value_0 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_1_t  afu_ate_read_data_value_1 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_2_t  afu_ate_read_data_value_2 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_3_t  afu_ate_read_data_value_3 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_4_t  afu_ate_read_data_value_4 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_5_t  afu_ate_read_data_value_5 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_6_t  afu_ate_read_data_value_6 ,
   output tmp_cafu_csr0_cfg_pkg::tmp_new_AFU_ATOMIC_TEST_READ_DATA_VALUE_7_t  afu_ate_read_data_value_7 


);

   localparam INCR                  = 2'b01;
   localparam WRAP                  = 2'b10;
   localparam CONST_M_AXI_AWID      = 11'hAB;
   localparam MAX_ADDR_AWSIZE5_WRAP = 7'd48;
   localparam MAX_ADDR_AWSIZE4_WRAP = 7'd56;
   localparam MAX_ADDR_AWSIZE3_WRAP = 7'd60;
   localparam MAX_ADDR_AWSIZE2_WRAP = 7'd62;
   localparam MAX_ADDR_AWSIZE1_WRAP = 7'd63;

   cafu_common_pkg::t_cafu_axi4_wr_addr_ch      afu_ate_axi_aw       ;
   cafu_common_pkg::t_cafu_axi4_wr_addr_ready   afu_ate_axi_awready  ;
   cafu_common_pkg::t_cafu_axi4_wr_data_ch      afu_ate_axi_w        ;
   cafu_common_pkg::t_cafu_axi4_wr_data_ready   afu_ate_axi_wready   ;
   cafu_common_pkg::t_cafu_axi4_wr_resp_ch      afu_ate_axi_b        ;
   cafu_common_pkg::t_cafu_axi4_wr_resp_ready   afu_ate_axi_bready   ;
   
   cafu_common_pkg::t_cafu_axi4_rd_addr_ch      afu_ate_axi_ar       ;
   cafu_common_pkg::t_cafu_axi4_rd_addr_ready   afu_ate_axi_arready  ;
   cafu_common_pkg::t_cafu_axi4_rd_resp_ch      afu_ate_axi_r        ;
   cafu_common_pkg::t_cafu_axi4_rd_resp_ready   afu_ate_axi_rready   ;
   
   
   logic [511:0] ate_write_data;
   logic [511:0] compare_data_aligned;
   logic [511:0] swap_data_aligned_to_compare;
   logic [511:0] swap_data_aligned;
   logic [63:0]  generated_byte_en;
   logic [63:0]  generated_byte_en_compare_op;
   logic [63:0]  generated_byte_en_swap_op;
   logic [2:0]   compare_en_cnt;
   logic         compare_en;
   logic         compare_pass;
   logic         afu_ate_init;
   logic         byte_en_cfg_fail;
   
   logic atomic_op_not_supported          ;
   logic atomic_burst_mode_illegal        ;
   logic start_ate                        ;
   logic force_disable                    ;
   logic ate_busy                         ;
   
   
    afu_ate_mem_target_pkg::hdm_mem_base_t     fme_hdm_mem_base;
    afu_ate_mem_target_pkg::Cl_Addr_t          axi_raddr, axi_waddr;
    logic                                      axi_rtarget_hdm, axi_wtarget_hdm;
    
    
    /*
    user csr to decode target for axi channels
    */
    assign axi_raddr = '0 ; //Read channel is not in use, afu_ate_target_address.target_address;
    assign axi_waddr = afu_ate_target_address.target_address; 
    
    always_ff @(posedge rtl_clk) begin
      if (hdm_dec_gbl_ctrl.dec_enable)
        begin
          fme_hdm_mem_base.Addr <= {hdm_dec_basehigh.mem_base_high[CL_ADDR_MSB-32:0], hdm_dec_baselow.mem_base_low};
          fme_hdm_mem_base.Size <= {hdm_dec_sizehigh.mem_size_high[CL_ADDR_MSB-32:0], hdm_dec_sizelow.mem_size_low};
          fme_hdm_mem_base.IW   <= hdm_dec_ctrl.interleave_ways;
          fme_hdm_mem_base.IG   <= hdm_dec_ctrl.interleave_granularity;
        end
      else
        begin
          fme_hdm_mem_base.Addr <= {dvsec_fbrange1high.memory_base_high[CL_ADDR_MSB-32:0], dvsec_fbrange1low.memory_base_low};
          fme_hdm_mem_base.Size <= {fbrange1_sz_high.memory_size[CL_ADDR_MSB-32:0], fbrange1_sz_low.memory_size_low};
          fme_hdm_mem_base.IW   <= 4'b0000;
          fme_hdm_mem_base.IG   <= 4'b0000;
        end
    end

    assign axi_rtarget_hdm = afu_ate_mem_target_pkg::fabric_target_dcd_f(axi_raddr,fme_hdm_mem_base);
    assign axi_wtarget_hdm = afu_ate_mem_target_pkg::fabric_target_dcd_f(axi_waddr,fme_hdm_mem_base);
   
    assign   awid                    =   afu_ate_axi_aw.awid;
    assign   awaddr                  =   afu_ate_axi_aw.awaddr;
    assign   awlen                   =   afu_ate_axi_aw.awlen;
    assign   awsize                  =   afu_ate_axi_aw.awsize;
    assign   awatop                  =   afu_ate_axi_aw.awatop;
    assign   awburst                 =   afu_ate_axi_aw.awburst;
    assign   awprot                  =   afu_ate_axi_aw.awprot;
    assign   awqos                   =   afu_ate_axi_aw.awqos;
    assign   awuser                  =   afu_ate_axi_aw.awuser;
    assign   awvalid                 =   afu_ate_axi_aw.awvalid;
    assign   awcache                 =   afu_ate_axi_aw.awcache;
    assign   awlock                  =   afu_ate_axi_aw.awlock;
    assign   awregion                =   afu_ate_axi_aw.awregion;
    assign   afu_ate_axi_awready     =   awready;

    assign   wdata                   =   afu_ate_axi_w.wdata;
    assign   wid                     =   '0;
    assign   wstrb                   =   afu_ate_axi_w.wstrb;
    assign   wlast                   =   afu_ate_axi_w.wlast;
    assign   wuser                   =   afu_ate_axi_w.wuser;
    assign   wvalid                  =   afu_ate_axi_w.wvalid;
    assign   afu_ate_axi_wready      =   wready;

    assign   afu_ate_axi_b.bid       =   bid;
    assign   afu_ate_axi_b.bresp     =   cafu_common_pkg::t_cafu_axi4_resp_encoding'(bresp);
    assign   afu_ate_axi_b.buser     =   buser;   
    assign   afu_ate_axi_b.bvalid    =   bvalid;
    assign   bready                  =   afu_ate_axi_bready;

    assign   arid                    =   afu_ate_axi_ar.arid;
    assign   araddr                  =   afu_ate_axi_ar.araddr;
    assign   arlen                   =   afu_ate_axi_ar.arlen;
    assign   arsize                  =   afu_ate_axi_ar.arsize;
    assign   arburst                 =   afu_ate_axi_ar.arburst;
    assign   arprot                  =   afu_ate_axi_ar.arprot;
    assign   arqos                   =   afu_ate_axi_ar.arqos;
    assign   aruser                  =   afu_ate_axi_ar.aruser;
    assign   arvalid                 =   afu_ate_axi_ar.arvalid;
    assign   arcache                 =   afu_ate_axi_ar.arcache;
    assign   arlock                  =   afu_ate_axi_ar.arlock;
    assign   arregion                =   afu_ate_axi_ar.arregion;
    assign   afu_ate_axi_arready     =   arready;

    assign   afu_ate_axi_r.rid       =   rid;
    assign   afu_ate_axi_r.rdata     =   rdata;
    assign   afu_ate_axi_r.rresp     =   cafu_common_pkg::t_cafu_axi4_resp_encoding'(rresp);
    assign   afu_ate_axi_r.rlast     =   rlast;
    assign   afu_ate_axi_r.ruser     =   cafu_common_pkg::t_cafu_axi4_ruser'(ruser); 
    assign   afu_ate_axi_r.rvalid    =   rvalid;
    assign   rready                  =   afu_ate_axi_rready;


   //---------------------------------------------
   //ATE FSM 
   //---------------------------------------------

   enum int unsigned { ATE_IDLE                  ,
                       ATE_WADDR_CHANNEL_READY   ,
                       ATE_WDATA_CHANNEL_READY   ,
                       ATE_RD_RSP_READY          ,
                       ATE_RD_RSP_WAIT           ,
                       ATE_WR_RSP_READY          ,
                       ATE_WR_RSP_WAIT           ,
                       ATE_OP_DONE               
                     } state, next_state;
                     
   always_ff@(posedge rtl_clk ) begin
     if(!reset_n)
        state <= ATE_IDLE;
     else
        state <= next_state;
   end
   
   always_comb begin : ae_next_state_logic
      case(state)
         ATE_IDLE                   : begin
                                         if(start_ate) begin
                                            next_state = ATE_WADDR_CHANNEL_READY;
                                         end
                                         else begin
                                            next_state = ATE_IDLE;
                                         end
                                      end
         ATE_WADDR_CHANNEL_READY    : begin
                                         if(afu_ate_axi_awready)  begin
                                            next_state = ATE_WDATA_CHANNEL_READY;
                                         end
                                         else begin
                                           if(force_disable) begin 
                                              next_state = ATE_IDLE;
                                           end 
                                           else begin
                                              next_state = ATE_WADDR_CHANNEL_READY;
                                           end 
                                         end
                                      end
         ATE_WDATA_CHANNEL_READY    : begin 
                                         if(afu_ate_axi_wready)  begin
                                            next_state = ATE_RD_RSP_READY;
                                         end
                                         else begin
                                           if(force_disable) begin 
                                              next_state = ATE_IDLE;
                                           end 
                                           else begin
                                              next_state = ATE_WDATA_CHANNEL_READY;
                                           end 
                                         end
                                      end
         ATE_RD_RSP_READY           : begin 
                                         if(force_disable) begin 
                                            next_state = ATE_IDLE;
                                         end 
                                         else begin
                                            next_state = ATE_RD_RSP_WAIT;
                                         end 
                                      end  
         ATE_RD_RSP_WAIT            : begin 
                                         if(afu_ate_axi_r.rvalid )  begin
                                           next_state = ATE_WR_RSP_READY;
                                         end
                                         else begin
                                            if(force_disable) begin 
                                               next_state = ATE_IDLE;
                                            end 
                                            else begin
                                               next_state = ATE_RD_RSP_WAIT;
                                            end 
                                         end
                                      end
         ATE_WR_RSP_READY           : begin 
                                         if(force_disable) begin 
                                            next_state = ATE_IDLE;
                                         end 
                                         else begin
                                            next_state = ATE_WR_RSP_WAIT;
                                         end 
                                      end
         ATE_WR_RSP_WAIT            : begin 
                                         if(afu_ate_axi_b.bvalid )  begin
                                           next_state = ATE_OP_DONE;
                                         end
                                         else begin
                                            if(force_disable) begin 
                                               next_state = ATE_IDLE;
                                            end 
                                            else begin
                                               next_state = ATE_WR_RSP_WAIT;
                                            end 
                                         end
                                      end 
         ATE_OP_DONE                : begin 
                                           next_state = ATE_IDLE;
                                      end
         default               : begin
                                      next_state = ATE_IDLE;
                                 end
      endcase
   end
    

   always_ff@(posedge rtl_clk ) begin
      if(!reset_n) begin
         //Write address channel
         afu_ate_axi_aw.awid                      <= '0;
         afu_ate_axi_aw.awaddr                    <= '0;
         afu_ate_axi_aw.awlen                     <= '0;
         afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
         afu_ate_axi_aw.awatop                    <= '0;
         afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
         afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
         afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
         afu_ate_axi_aw.awuser.target_hdm         <= '0;
         afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
         afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
         afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
         afu_ate_axi_aw.awvalid                   <= '0;
         afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
         afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
         afu_ate_axi_aw.awregion                  <= '0;
         
         //Write data channel
         afu_ate_axi_w.wdata                      <= '0;
         afu_ate_axi_w.wstrb                      <= '0;
         afu_ate_axi_w.wlast                      <= '0;
         afu_ate_axi_w.wuser                      <= '0;
         afu_ate_axi_w.wvalid                     <= '0;
                                                  
         //Write response channel                 
         afu_ate_axi_bready                       <= '0;
         
         //Read address channel is not required since we are not not issuing read for atomic compare swap
         afu_ate_axi_ar.arid                      <= '0;
         afu_ate_axi_ar.araddr                    <= '0;
         afu_ate_axi_ar.arlen                     <= '0;
         afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
         afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
         afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
         afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
         afu_ate_axi_ar.aruser                    <= '0;
         afu_ate_axi_ar.arvalid                   <= '0;
         afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
         afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
         afu_ate_axi_ar.arregion                  <= '0;
         
         //Read data/response channel 
         afu_ate_axi_rready                       <= '0;

      end
      else begin
         case(state)
            ATE_IDLE                   : begin
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0                            ;
                                            afu_ate_axi_aw.awaddr                    <= '0                            ;
                                            afu_ate_axi_aw.awlen                     <= '0                            ;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0);
                                            afu_ate_axi_aw.awatop                    <= '0                            ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)     ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA      ;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT              ;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0                            ;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0                            ; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'(0)      ; 
                                            afu_ate_axi_aw.awvalid                   <= '0                            ; 
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE   ;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL                  ;
                                            afu_ate_axi_aw.awregion                  <= '0                            ;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b0;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
            ATE_WADDR_CHANNEL_READY    : begin
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= CONST_M_AXI_AWID;
                                            afu_ate_axi_aw.awaddr                    <= {12'h0,afu_ate_target_address.target_address,afu_ate_ctrl.write_byte_offset};   
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(afu_ate_ctrl.write_burst_size);
                                            afu_ate_axi_aw.awatop                    <= afu_ate_ctrl.atomic_operation                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(afu_ate_ctrl.write_burst_mode);
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= axi_wtarget_hdm;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= afu_ate_ctrl.awuser_mode == 5'h1 ? 1'b1 : 1'b0 ; 
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= eWR_CAFU_M; 
                                            afu_ate_axi_aw.awvalid                   <=  1'b1;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0; //poison is tied to zero when atomic op initiates
                                            afu_ate_axi_w.wvalid                     <= '0;
                                            
                                            //Write response channel 
                                            afu_ate_axi_bready                       <= 1'b0;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
            ATE_WDATA_CHANNEL_READY    : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;   
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= ate_write_data;
                                            afu_ate_axi_w.wstrb                      <= afu_ate_attr_byte_en.atomic_attr_byte_enable;
                                            afu_ate_axi_w.wlast                      <= 1'b1;
                                            afu_ate_axi_w.wuser                      <= '0  ; //poison is tied to zero when atomic op initiates
                                            afu_ate_axi_w.wvalid                     <= 1'b1;
                                            
                                            //Write response channel 
                                            afu_ate_axi_bready                       <= 1'b0;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
         ATE_RD_RSP_READY              : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b0;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b1;

                                         end  
         ATE_RD_RSP_WAIT               : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b0 ;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= afu_ate_axi_r.rvalid ? 1'b0 : 1'b1 ;

                                         end
         ATE_WR_RSP_READY              : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b1;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
         ATE_WR_RSP_WAIT               : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= afu_ate_axi_b.bvalid ? 1'b0 : 1'b1;;
                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end 
         ATE_OP_DONE                   : begin 
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b0; 

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
         default                       : begin
                                            //Write address channel
                                            afu_ate_axi_aw.awid                      <= '0;
                                            afu_ate_axi_aw.awaddr                    <= '0;
                                            afu_ate_axi_aw.awlen                     <= '0;
                                            afu_ate_axi_aw.awsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'(0) ;
                                            afu_ate_axi_aw.awatop                    <= '0                             ;
                                            afu_ate_axi_aw.awburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'(0)      ;
                                            afu_ate_axi_aw.awprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_aw.awqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_aw.awuser.target_hdm         <= '0;
                                            afu_ate_axi_aw.awuser.AtomicSwapIfEM     <= '0;
                                            afu_ate_axi_aw.awuser.do_not_send_d2hreq <= '0; 
                                            afu_ate_axi_aw.awuser.opcode             <= cafu_common_pkg::t_cafu_axi4_awuser_opcode'('0); 
                                            afu_ate_axi_aw.awvalid                   <= '0;
                                            afu_ate_axi_aw.awcache                   <= ecache_aw_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_aw.awlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_aw.awregion                  <= '0;
                                            
                                            //Write data channel
                                            afu_ate_axi_w.wdata                      <= '0;
                                            afu_ate_axi_w.wstrb                      <= '0;
                                            afu_ate_axi_w.wlast                      <= '0;
                                            afu_ate_axi_w.wuser                      <= '0;
                                            afu_ate_axi_w.wvalid                     <= '0;
                                                                                     
                                            //Write response channel                 
                                            afu_ate_axi_bready                       <= 1'b0;

                                            
                                            //Read address channel is not required since we are not not issuing read for atomic compare swap
                                            afu_ate_axi_ar.arid                      <= '0;
                                            afu_ate_axi_ar.araddr                    <= '0;
                                            afu_ate_axi_ar.arlen                     <= '0;
                                            afu_ate_axi_ar.arsize                    <= cafu_common_pkg::t_cafu_axi4_burst_size_encoding'('0);
                                            afu_ate_axi_ar.arburst                   <= cafu_common_pkg::t_cafu_axi4_burst_encoding'('0);
                                            afu_ate_axi_ar.arprot                    <= eprot_CAFU_UNPRIV_NONSEC_DATA;
                                            afu_ate_axi_ar.arqos                     <= eqos_CAFU_BEST_EFFORT;
                                            afu_ate_axi_ar.aruser                    <= '0;
                                            afu_ate_axi_ar.arvalid                   <= '0;
                                            afu_ate_axi_ar.arcache                   <= ecache_ar_CAFU_DEVICE_BUFFERABLE;
                                            afu_ate_axi_ar.arlock                    <= elock_CAFU_NORMAL;
                                            afu_ate_axi_ar.arregion                  <= '0;
                                            
                                            //Read data/response channel 
                                            afu_ate_axi_rready                       <= 1'b0;

                                         end
         endcase
      end
   end


   /*
     Illegal SW configuaration for ATE
   */
   assign atomic_op_not_supported                = (afu_ate_ctrl.atomic_operation != 6'h31 && afu_ate_ctrl.atomic_operation != 6'h30);
   
   assign atomic_burst_mode_illegal              = (afu_ate_ctrl.atomic_operation == 6'h31 && ((afu_ate_ctrl.write_burst_mode != INCR )  & (afu_ate_ctrl.write_burst_mode != WRAP ))) ||
                                                   (afu_ate_ctrl.atomic_operation == 6'h30 && ((afu_ate_ctrl.write_burst_mode != INCR )  & (afu_ate_ctrl.write_burst_mode == WRAP )))      ; 

   assign start_ate                              = afu_ate_init & !atomic_op_not_supported & !atomic_burst_mode_illegal & !ate_busy & !byte_en_cfg_fail ;

   assign force_disable                          = afu_ate_force_disable.force_disable;
   
   assign ate_busy                               = (state == ATE_IDLE) ? 1'b0 : 1'b1;
   
   /*                                        
     WRITE DATA gen based on the afu_ate_ctrl.write_burst_mode,afu_ate_ctrl.write_byte_offset,afu_ate_ctrl.write_burst_size
   */
   assign compare_data_aligned          = {afu_ate_compare_value_1.compare_value_1,afu_ate_compare_value_0.compare_value_0} << (((afu_ate_ctrl.write_byte_offset))*8);
   
   assign swap_data_aligned_to_compare  = {afu_ate_swap_value_1.swap_value_1,afu_ate_swap_value_0.swap_value_0} << ((afu_ate_ctrl.write_byte_offset)*8) ;
                           
   assign swap_data_aligned             =  afu_ate_ctrl.write_burst_mode == INCR ?  swap_data_aligned_to_compare <<  ((2**(afu_ate_ctrl.write_burst_size-1))*8) 
                                                                                  : swap_data_aligned_to_compare >>  ((2**(afu_ate_ctrl.write_burst_size-1))*8) ;
   
   assign ate_write_data                = afu_ate_ctrl.atomic_operation == 6'h31 ? (swap_data_aligned | compare_data_aligned) : afu_ate_ctrl.atomic_operation == 6'h30 ? swap_data_aligned_to_compare : '0 ;

    
   assign generated_byte_en_compare_op  =  afu_ate_ctrl.write_burst_size == 5 ? 
                                              ((afu_ate_ctrl.write_burst_mode ==INCR) ?
                                                 (({{32{1'b0}},{32{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                                 (({{32{1'b1}},{32{1'b0}}}) >> (MAX_ADDR_AWSIZE5_WRAP-afu_ate_ctrl.write_byte_offset))) :
                                           afu_ate_ctrl.write_burst_size == 4 ? 
                                            ((afu_ate_ctrl.write_burst_mode ==INCR) ?
                                                 (({{48{1'b0}},{16{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                                 (({{16{1'b1}},{48{1'b0}}}) >> (MAX_ADDR_AWSIZE4_WRAP-afu_ate_ctrl.write_byte_offset))) :
                                           afu_ate_ctrl.write_burst_size == 3 ? 
                                              ((afu_ate_ctrl.write_burst_mode ==INCR) ?
                                                 (({{56{1'b0}},{8{1'b1}} })<< (afu_ate_ctrl.write_byte_offset)) :
                                                 (({{8{1'b1} },{56{1'b0}}}) >> (MAX_ADDR_AWSIZE3_WRAP-afu_ate_ctrl.write_byte_offset))) :
                                           afu_ate_ctrl.write_burst_size == 2 ? 
                                              ((afu_ate_ctrl.write_burst_mode ==INCR) ?
                                                 (({{60{1'b0}},{4{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                                 (({{4{1'b1} },{60{1'b0}}}) >> (MAX_ADDR_AWSIZE2_WRAP-afu_ate_ctrl.write_byte_offset))) :
                                           afu_ate_ctrl.write_burst_size == 1 ? 
                                              ((afu_ate_ctrl.write_burst_mode ==INCR) ?
                                                 (({{62{1'b0}},{2{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) : 
                                                 (({{2{1'b1} },{62{1'b0}}}) >> (MAX_ADDR_AWSIZE1_WRAP-afu_ate_ctrl.write_byte_offset))) : 
                                              {64{1'b0}};


   assign generated_byte_en_swap_op    = afu_ate_ctrl.write_burst_size == 3 ?
                                            (({{56{1'b0}},{8{1'b1}} })<< (afu_ate_ctrl.write_byte_offset)) :
                                         afu_ate_ctrl.write_burst_size == 2 ?
                                            (({{60{1'b0}},{4{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                         afu_ate_ctrl.write_burst_size == 1 ?
                                            (({{62{1'b0}},{2{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                         afu_ate_ctrl.write_burst_size == 0 ?
                                            (({{63{1'b0}},{1{1'b1}}}) << (afu_ate_ctrl.write_byte_offset)) :
                                            {64{1'b0}};  

   assign generated_byte_en  = afu_ate_ctrl.atomic_operation == 6'h31 ? generated_byte_en_compare_op : afu_ate_ctrl.atomic_operation == 6'h30 ? generated_byte_en_swap_op : '0;
 

   afu_ate_comparator #( .DATA_WIDTH(512'd64)  )
    afu_ate_comparator_uu(
     .rtl_clk(rtl_clk                                      ),
     .dataa  (afu_ate_attr_byte_en.atomic_attr_byte_enable ),
     .datab  (generated_byte_en                            ),
     .enable (compare_en                                   ),
     .eq     (compare_pass                                 )
   );

   assign compare_en   = (compare_en_cnt != 3'h0) ? 1'b1 : 1'b0;
   assign afu_ate_init = (compare_en_cnt == 3'h1) ? 1'b1 : 1'b0;
   assign byte_en_cfg_fail = !compare_pass;  

 
   always @(posedge rtl_clk) begin
      if(!reset_n) begin
         compare_en_cnt <= '0;
      end
      else begin
         if(afu_ate_initiate.initiate_transaction == 1'b1) begin
            compare_en_cnt <= 3'h5;
         end
         else if(compare_en_cnt == '0) begin
            compare_en_cnt <= 3'h0;
         end 
         else begin   
            compare_en_cnt <= compare_en_cnt - 3'h1;
         end 
      end
   end
   
   
   
   always_ff @(posedge rtl_clk) begin
      if(!reset_n) begin
        afu_ate_read_data_value_0 <= '0 ;
        afu_ate_read_data_value_1 <= '0 ;
        afu_ate_read_data_value_2 <= '0 ;
        afu_ate_read_data_value_3 <= '0 ;
        afu_ate_read_data_value_4 <= '0 ;
        afu_ate_read_data_value_5 <= '0 ;
        afu_ate_read_data_value_6 <= '0 ;
        afu_ate_read_data_value_7 <= '0 ;
      end
      else begin
        if( afu_ate_axi_r.rvalid & (afu_ate_axi_r.rid == CONST_M_AXI_AWID) & (afu_ate_axi_r.rresp == eresp_CAFU_OKAY)) begin
            afu_ate_read_data_value_0 <= afu_ate_axi_r.rdata[63:0]    ;
            afu_ate_read_data_value_1 <= afu_ate_axi_r.rdata[127:64]  ;
            afu_ate_read_data_value_2 <= afu_ate_axi_r.rdata[191:128] ;
            afu_ate_read_data_value_3 <= afu_ate_axi_r.rdata[255:192] ;
            afu_ate_read_data_value_4 <= afu_ate_axi_r.rdata[319:256] ;
            afu_ate_read_data_value_5 <= afu_ate_axi_r.rdata[383:320] ;
            afu_ate_read_data_value_6 <= afu_ate_axi_r.rdata[447:384] ;
            afu_ate_read_data_value_7 <= afu_ate_axi_r.rdata[511:448] ;
        end
        else begin
          afu_ate_read_data_value_0  <= afu_ate_read_data_value_0;
          afu_ate_read_data_value_1  <= afu_ate_read_data_value_1;
          afu_ate_read_data_value_2  <= afu_ate_read_data_value_2;
          afu_ate_read_data_value_3  <= afu_ate_read_data_value_3;
          afu_ate_read_data_value_4  <= afu_ate_read_data_value_4;
          afu_ate_read_data_value_5  <= afu_ate_read_data_value_5;
          afu_ate_read_data_value_6  <= afu_ate_read_data_value_6;
          afu_ate_read_data_value_7  <= afu_ate_read_data_value_7;
        end
      end
    end
      
   always_ff @(posedge rtl_clk) begin
      if(!reset_n) begin
        afu_ate_status <= '0;
      end
      else begin
         afu_ate_status.atomic_test_engine_busy <= ate_busy;
         
         if(afu_ate_init) begin
           afu_ate_status.cofig_error_status <= ( atomic_op_not_supported | atomic_burst_mode_illegal | ate_busy | byte_en_cfg_fail);
         end
         else begin
           afu_ate_status.cofig_error_status <= afu_ate_status.cofig_error_status;
         end
         
         if(afu_ate_axi_r.rvalid) begin
           afu_ate_status.slverr_on_read_response <=  ((afu_ate_axi_r.rresp != 'h0) | (afu_ate_axi_r.rid != CONST_M_AXI_AWID)) ? 1'b1 : 1'b0 ;
         end
         else begin
           afu_ate_status.slverr_on_read_response <= afu_ate_status.slverr_on_read_response;
         end 

          if(afu_ate_axi_r.rvalid) begin
            afu_ate_status.atomic_swap_success <=  afu_ate_axi_r.ruser.AtomicSwapSuccess;
          end
          else begin
            afu_ate_status.atomic_swap_success <= afu_ate_status.atomic_swap_success;
          end
         
         if(afu_ate_axi_b.bvalid) begin
           afu_ate_status.slverr_on_write_response <=  ((afu_ate_axi_b.bresp != 'h0) | (afu_ate_axi_b.bid != CONST_M_AXI_AWID)) ? 1'b1 : 1'b0 ;
         end
         else begin
           afu_ate_status.slverr_on_write_response <= afu_ate_status.slverr_on_write_response;
         end 

         //Currently not implemented will implement future
         afu_ate_status.read_data_timeout_error <= '0;
      end
   end
   
 

endmodule





`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "osvEnW2fOZy+hTAFgpB6qCKl1JvF4ZMF6nvTShx+aOLwY2zbxI2NHps4d1a04Mku7n/VJVNrAGvV17JR/ig1Ero/WSZjglXgRRvVNck9uy2CYvYTWZZGK2Q1zpiyLFOEaMbteTMayu7JRDJd+13nwlQuD2emt6jJA9iKcbGr08GJgDgW21fpriFGm2EQ6gy6LHfn7fYx6nZR5tHB+uV+HCqTvPZjErmopGXmAbE3Uzq+gfSOn4bHGbLtS9E26OA5T7TCK5+8ib7eQX7DaYvx8LW92OH/Ack+eMyVxiu5ZlMXhj7Ib9Vb/GeWnMZmDUqhbUc4oO9ZUoXz4/DRxpZqypzpMadD3t6DXaRq21yemDlN4mr6/mQVhETjDVBn2cXGJG6ebu/czA+9D3LUPS6KCIHNAiksLBmo6aLjh19J05lELlGZ+xX7tx+pWXHte8LharEQfy1/i/YvL9IIna6Qb3deCtTcULDx17k2IOTgLXBR5pm76/XqhDNjRvoJ4QCYUif4yTO9qJRakSe6hjNCwHV01O+CcQSWpueCFcepR4FV5CncZE6BLWC1RugGzPyEfmhH7+4upCwNGMWJNK/xnGxwSoVS9WHGS7WupKf3fWT/0kbq8JJbwLHpv6qzX1UMe8iIGShnqQbT1wzIQDoT4NkMer5J7BlTOqKIAZrzdRgypxUNXpuMru6B+2TE3aQrXydxdbGyNf0dkQWfCu11I2QkM+hnIf6dxp9YYV3z/m6C97sDVb1EZcLftxzdF7UskkYJBHhjkuLDy3bE4bQd0g39KWH7kRwdBRsoEBgf972Qg7HjkLTNAIhXwgW33TyYrLTjrCsXf1qjjJIUvzHTXCtFtx+rFQGP5717YybOMzk7TbibiX2bw/rMex5zGZmO/kdv8gGVPnGT/wAaYgsuEITUJSAREBcumYr3hWUp+etXuYXUyONsFC7OOsFFr4C5Gud2jnZ6q/mRdH7+J6wNOHBJASqkF6bjA7ZBpk8H2MuHAHWwjzgixmwvceJVNFlQ"
`endif