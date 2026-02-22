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

module mc_single_chan_rmw_block
  import ddr_mc_top_common_pkg::*;
#(
  parameter REQFIFO_DEPTH_WIDTH = 8,
  parameter REG_ON_BCHAN_WEN_TO_RSPFIFO    = 0, // 0 - OFF; 1 - ON  could be needed for timing  
  parameter REG_ON_BCHAN_STRUCT_TO_RSPFIFO = 0, // 0 - OFF; 1 - ON  could be needed for timing

  // == REG_ON_RMW_RD_DATA_INPUT_EN = 1 Improves timing with impact of additional
  // == 1 clk latency on RMW transactions (normal reads and writes are NOT affected)
  parameter REG_ON_RMW_RD_DATA_INPUT_EN = 1, // 0 - OFF; 1 - ON

  localparam SYMBOL_WIDTH       = 8,
  localparam BE_WIDTH           = ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH / SYMBOL_WIDTH
)
(
  input logic emifclk,                         // EMIF User Clock
  input logic emifresetn,                      // EMIF reset
  input logic emifresetn_reg,
  input logic emif_avmm_1_axi_0,
  input logic from_axi_rd_id_fifo_almost_full, // always zero in avmm mode
  input logic from_ram_init_done_del1_emifclk,

  output logic from_rmw_rmw_pending_emifclk,
  output logic from_rmw_memory_ready_emifclk,
  output logic from_rmw_clear_reqfifo_read_valid_emifclk,
  output logic from_rmw_clear_reqfifo_write_valid_emifclk,
 
  /* to/from cdc_reqfifo
  */
  input ddr_mc_top_common_pkg::t_reqfifo_data    from_reqfifo_new_req_emifclk,

   input logic from_reqfifo_real_empty_emifclk, // straight from reqfifo
   input logic from_reqfifo_empty_emifclk,      // clocked version 
  output logic from_rmw_to_reqfifo_read_enable_emifclk,
  
  /* to/from mc_ecc (then to emif)
  */
   input ddr_mc_top_common_pkg::t_rchan_rspfifo_data     from_mcecc_rd_resp_emifclk,
   input ddr_mc_top_common_pkg::t_rchan_rspfifo_ecc      from_mcecc_rd_ecc_emifclk,
 
  output ddr_mc_top_common_pkg::t_reqfifo_data_postRMW_preECC     to_mcecc_new_req_emifclk,

   input logic from_mcecc_memory_ready_emifclk,
  output logic to_mcecc_reqfifo_empty_emifclk,
 
  /* write response structs from emif selection logic
  */
  input ddr_mc_top_common_pkg::t_bchan_rspfifo_data     from_emif_wr_resp_emifclk, 

  /* to clock domain crossing (cdc) response fifos
  */
  output ddr_mc_top_common_pkg::t_bchan_rspfifo_data     to_rspfifo_wr_resp_emifclk,
  output ddr_mc_top_common_pkg::t_rchan_rspfifo_data     to_rspfifo_rd_resp_emifclk,
  output ddr_mc_top_common_pkg::t_rchan_rspfifo_ecc      to_rspfifo_rd_ecc_emifclk,
 
  output logic to_rspfifo_bchan_wen_emifclk,
  output logic to_rspfifo_rchan_wen_emifclk
);

//-----------------------------------------------------------------------------------------------------------------------------------------------------------
ddr_mc_top_common_pkg::t_rchan_rspfifo_data     from_mcecc_rd_resp_emifclk_internal;

logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] rmw_wr_id_emifclk;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] rmw_rd_id_emifclk;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] rmw_wr_id_comb;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0] rmw_rd_id_comb;

logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] rmw_data_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] rmw_data_comb;

logic rmw_poison_emifclk;
logic rmw_write;
logic rmw_to_ecc_reqfifo_empty_emifclk;
logic rmw_to_ecc_reqfifo_empty_comb;
logic rmw_poison_comb;
logic block_rchan_rspfifo_wen_emifclk;

logic prev_from_reqfifo_write_partial_emifclk;
logic prev_from_reqfifo_valid_write_emifclk;
logic prev_from_reqfifo_valid_read_emifclk;

logic new_posedge_from_reqfifo_write_partial_emifclk;
logic new_posedge_from_reqfifo_valid_write_emifclk;
logic new_posedge_from_reqfifo_valid_read_emifclk;

logic mem_ready_fsm_rmw_read_valid;

// ================================================================================================
/* grab inputs from the cdc_reqfifo
*/
assign rmw_poison_comb = from_mcecc_rd_resp_emifclk_internal.read_resp_valid
                         ? ( from_reqfifo_new_req_emifclk.write_poison | from_mcecc_rd_resp_emifclk_internal.read_poison )
                         : rmw_poison_emifclk;

assign rmw_wr_id_comb = from_mcecc_rd_resp_emifclk_internal.read_resp_valid
                        ? from_reqfifo_new_req_emifclk.wr_id
                        : rmw_wr_id_emifclk;

assign rmw_rd_id_comb = from_mcecc_rd_resp_emifclk_internal.read_resp_valid
                        ? from_reqfifo_new_req_emifclk.rd_id
                        : rmw_rd_id_emifclk;

assign rmw_to_ecc_reqfifo_empty_comb = from_mcecc_rd_resp_emifclk_internal.read_resp_valid
                                       ? 1'b0 // need it zero to propagte the write on case the refifo is empty
                                       : from_reqfifo_empty_emifclk; //rmw_to_ecc_reqfifo_empty_emifclk;

always_ff @(posedge emifclk)
begin
  rmw_poison_emifclk <= ~emifresetn ? 1'b0 : rmw_poison_comb;

  rmw_wr_id_emifclk <= ~emifresetn ? '0 : rmw_wr_id_comb;  // need reset to zero here?  

  rmw_rd_id_emifclk <= ~emifresetn ? '0 : rmw_rd_id_comb;  // need reset to zero here?  				 

  rmw_to_ecc_reqfifo_empty_emifclk <= ~emifresetn ? 1'b1 : rmw_to_ecc_reqfifo_empty_comb;
end


// ================================================================================================
/* selecting the data from either the cdc_reqfifo or from the avmm read port after a read op for the RMW
*/
int i;

always_comb
begin
  rmw_data_comb = rmw_data_emifclk;
  
  if( from_mcecc_rd_resp_emifclk_internal.read_resp_valid )
  begin
    for (i=0; i<=BE_WIDTH-1; i=i+1)
	begin
	  if( from_reqfifo_new_req_emifclk.byteenable[i] ) rmw_data_comb[i*SYMBOL_WIDTH +:SYMBOL_WIDTH] = from_reqfifo_new_req_emifclk.writedata[i*SYMBOL_WIDTH +:SYMBOL_WIDTH];
	  else                                             rmw_data_comb[i*SYMBOL_WIDTH +:SYMBOL_WIDTH] = from_mcecc_rd_resp_emifclk_internal.read_data[i*SYMBOL_WIDTH +:SYMBOL_WIDTH];
    end
  end
end

always_ff @(posedge emifclk)
begin
  rmw_data_emifclk <= rmw_data_comb;
end

// ================================================================================================
/* Detect new write-valids and read-valids on the inputs from the cdc_reqfifo clocking in mc-chan-adapter
   should eliminate need for clearing signals as we only care about action on new packets
*/
always_ff @(posedge emifclk)
begin
  prev_from_reqfifo_write_partial_emifclk <= ~emifresetn ? 1'b0 : from_reqfifo_new_req_emifclk.partial_write;
  prev_from_reqfifo_valid_write_emifclk   <= ~emifresetn ? 1'b0 : from_reqfifo_new_req_emifclk.write;
  prev_from_reqfifo_valid_read_emifclk    <= ~emifresetn ? 1'b0 : from_reqfifo_new_req_emifclk.read;
end

assign new_posedge_from_reqfifo_write_partial_emifclk = ~prev_from_reqfifo_write_partial_emifclk & from_reqfifo_new_req_emifclk.partial_write;
assign new_posedge_from_reqfifo_valid_write_emifclk   = ~prev_from_reqfifo_valid_write_emifclk   & from_reqfifo_new_req_emifclk.write;
assign new_posedge_from_reqfifo_valid_read_emifclk    = ~prev_from_reqfifo_valid_read_emifclk    & from_reqfifo_new_req_emifclk.read;

// ================================================================================================
/* mem_ready output to the the mc_channel_adapter (specifically used for cdc_reqfifo_REN)
   outputs of "memory_ready" to block/allow reads from the cdc_reqfifo
   This should be really just thought of as "rmw_shim_ready" instead of mem_ready, as mem_ready feeds into mc_ecc, which then feeds a mem_ready (really a
     mc_ecc_ready) into rmw_shim
*/
typedef enum logic [2:0] {
  MEM_READY_IDLE          = 'd0,
  MEM_READY_START         = 'd1,
  MEM_READY_READ          = 'd2,
  MEM_READY_WRITE         = 'd3,
  MEM_READY_RMW_READ      = 'd4,
  MEM_READY_RMW_WRITE     = 'd5,
  MEM_READY_RMW_POST      = 'd6
} t_enum_mem_ready_state;

t_enum_mem_ready_state   next_state_mem_ready;
t_enum_mem_ready_state        state_mem_ready;


always@( posedge emifclk )
begin
  state_mem_ready <= ~emifresetn ? MEM_READY_IDLE : next_state_mem_ready;
end


always_comb
begin
  from_rmw_memory_ready_emifclk = from_mcecc_memory_ready_emifclk;  // auto assign to ready coming from mc_ecc/emif - STILL SEND OUT FOR RAM INIT
  
  from_rmw_to_reqfifo_read_enable_emifclk    = 1'b0;
  from_rmw_clear_reqfifo_read_valid_emifclk  = 1'b0;
  from_rmw_clear_reqfifo_write_valid_emifclk = 1'b0;
  
  mem_ready_fsm_rmw_read_valid = 1'b0;

  case( state_mem_ready )
    MEM_READY_IDLE :
    begin
      if( from_mcecc_memory_ready_emifclk
		& ~from_reqfifo_real_empty_emifclk
		& emifresetn_reg
		& ~from_axi_rd_id_fifo_almost_full
		)
      begin
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready
                              from_rmw_to_reqfifo_read_enable_emifclk = 1'b1;  // pop from the cdc_reqfifo
                                                 next_state_mem_ready = MEM_READY_START;
      end
      else begin
                                                 next_state_mem_ready = MEM_READY_IDLE;
      end
    end   

    MEM_READY_START :
    begin
      if( from_reqfifo_new_req_emifclk.write & from_reqfifo_new_req_emifclk.partial_write )
      begin
        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled
        
        mem_ready_fsm_rmw_read_valid = 1'b1; // set read valid and hold it til from_mcecc_memory_ready_emifclk==1
      
        if( from_mcecc_memory_ready_emifclk ) next_state_mem_ready = MEM_READY_RMW_READ;
        else                                  next_state_mem_ready = MEM_READY_START;
      end
      else if( from_reqfifo_new_req_emifclk.write | from_reqfifo_new_req_emifclk.read )
      begin
        if( from_mcecc_memory_ready_emifclk & ~from_reqfifo_real_empty_emifclk )  // eccreq ready, reqfifo not empty
		begin
          from_rmw_to_reqfifo_read_enable_emifclk = 1'b1;  // pop from the cdc_reqfifo
                             next_state_mem_ready = MEM_READY_START;
        end
        else if( from_mcecc_memory_ready_emifclk & from_reqfifo_real_empty_emifclk )  // eccreq ready, reqfifo empty
		begin
          if( from_reqfifo_new_req_emifclk.write ) from_rmw_clear_reqfifo_write_valid_emifclk = 1'b1;  // read sent to mc_ecc, clear the valid from reqfifo
          else                                     from_rmw_clear_reqfifo_read_valid_emifclk  = 1'b1;  // read sent to mc_ecc, clear the valid from reqfifo

          from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready
                   next_state_mem_ready = MEM_READY_IDLE;
        end
        else begin
          from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready
                   next_state_mem_ready = MEM_READY_START;  // waiting on mcecc_memory_ready
                    
//          if( from_reqfifo_new_req_emifclk.write ) next_state_mem_ready = MEM_READY_WRITE;
//          else                                     next_state_mem_ready = MEM_READY_READ;
        end
      end
      else begin
                    from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready
                             next_state_mem_ready = MEM_READY_START;  // a reqfifo ren happened, so wait for it to be clocked in mc_chan_adapt
      end
    end
    
    MEM_READY_READ :
    begin
        if( from_mcecc_memory_ready_emifclk ) // if the ready coming from mc_ecc/emif is present
        begin
          from_rmw_clear_reqfifo_read_valid_emifclk = 1'b1;  // read has been issued to mc_ecc so clear the valid from reqfifo	       
                      from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled - want one cycle edge if reqfifo not empty
                               next_state_mem_ready = MEM_READY_IDLE;
		end
		else begin
		  from_rmw_clear_reqfifo_read_valid_emifclk = 1'b1;  // read has been issued to mc_ecc so clear the valid from reqfifo
                      from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready until the read is handled
                               next_state_mem_ready = MEM_READY_READ;
        end    
    end
    
    MEM_READY_WRITE :
    begin
        if( from_mcecc_memory_ready_emifclk ) // if the ready coming from mc_ecc/emif is present
        begin
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled - want one cycle edge if reqfifo not empty
                                                 next_state_mem_ready = MEM_READY_IDLE;
												 
            //if( ~emif_avmm_1_axi_0 )	from_rmw_clear_reqfifo_write_valid_emifclk = 1'b1;  // write has been issued to mc_ecc so clear the valid from reqfifo
                                        from_rmw_clear_reqfifo_write_valid_emifclk = 1'b1;  // write has been issued to mc_ecc so clear the valid from reqfifo			  
		end
		else begin
		                   from_rmw_clear_reqfifo_write_valid_emifclk = 1'b1;  // write has been issued to mc_ecc so clear the valid from reqfifo
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready until the write is handled
                                                 next_state_mem_ready = MEM_READY_WRITE;
        end    
    end    

    MEM_READY_RMW_READ :
    begin
      if( from_mcecc_rd_resp_emifclk_internal.read_resp_valid // a valid read response
        & ( from_mcecc_rd_resp_emifclk_internal.read_id == from_reqfifo_new_req_emifclk.wr_id ) // read resp ID == partial write ID
        )
	  begin
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled
                                                 next_state_mem_ready = MEM_READY_RMW_WRITE;
      end
	  else begin
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled
                                                 next_state_mem_ready = MEM_READY_RMW_READ;
      end
    end

    MEM_READY_RMW_WRITE :
    begin    
      if( to_mcecc_new_req_emifclk.write ) // full line write is sent to ecc on to emif
      begin
          		           from_rmw_clear_reqfifo_write_valid_emifclk = 1'b1;  // write has been issued to mc_ecc so clear the valid from reqfifo
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled
                                                 next_state_mem_ready = MEM_READY_IDLE;												 
      end    
	  else begin
                                        from_rmw_memory_ready_emifclk = 1'b0;  // advertise that mem is not ready while partial write is handled
                                                 next_state_mem_ready = MEM_READY_RMW_WRITE;
      end
    end    

    default :                                    next_state_mem_ready = MEM_READY_IDLE;
  endcase
end

// ================================================================================================
/* Handle the rmw_pending signal and correlated control signals
*/
typedef enum logic [1:0] {
  RMW_NOT_PENDING     = 'd0,
  RMW_WAIT_RD_RSP     = 'd1,
  RMW_WAIT_WR_SENT    = 'd2,
  RMW_WAIT_POST       = 'd3
} t_enum_rmw_pending_state;

t_enum_rmw_pending_state   next_state_rmw_pending;
t_enum_rmw_pending_state        state_rmw_pending;


always@( posedge emifclk )
begin
  state_rmw_pending <= ~emifresetn ? RMW_NOT_PENDING : next_state_rmw_pending;
end


always_comb
begin
  from_rmw_rmw_pending_emifclk = 1'b0;
                     rmw_write = 1'b0;
  block_rchan_rspfifo_wen_emifclk = 1'b0;

  case( state_rmw_pending )
    RMW_NOT_PENDING :
    begin
      if( from_reqfifo_new_req_emifclk.write
		& from_reqfifo_new_req_emifclk.partial_write
		)
      begin
                                                 next_state_rmw_pending = RMW_WAIT_RD_RSP;
      end
      else begin
                                                 next_state_rmw_pending = RMW_NOT_PENDING;
      end
    end
    
    RMW_WAIT_RD_RSP : 
    begin
      if( from_mcecc_rd_resp_emifclk_internal.read_resp_valid // a valid read response
        & ( from_mcecc_rd_resp_emifclk_internal.read_id == from_reqfifo_new_req_emifclk.wr_id ) // read resp ID == partial write ID
        )
	  begin
	                                    block_rchan_rspfifo_wen_emifclk = 1'b1;
                                           from_rmw_rmw_pending_emifclk = 1'b1;
                                                 next_state_rmw_pending = RMW_WAIT_WR_SENT;
      end
      else begin
                                           from_rmw_rmw_pending_emifclk = 1'b1;
                                                 next_state_rmw_pending = RMW_WAIT_RD_RSP;
      end
    end

    RMW_WAIT_WR_SENT : 
    begin
										                      rmw_write = 1'b1;
                                                 next_state_rmw_pending = RMW_NOT_PENDING;
    end

    default :                                    next_state_rmw_pending = RMW_NOT_PENDING;
  endcase
end

// ================================================================================================
/* outputs to the ecc module on to the memory
   don't want added latency on non-partial writes
*/
always_comb
begin
   to_mcecc_new_req_emifclk.write         = from_reqfifo_new_req_emifclk.partial_write ? rmw_write          : from_reqfifo_new_req_emifclk.write;  
   to_mcecc_new_req_emifclk.wr_id         = from_reqfifo_new_req_emifclk.partial_write ? rmw_wr_id_emifclk  : from_reqfifo_new_req_emifclk.wr_id;
   to_mcecc_new_req_emifclk.writedata     = from_reqfifo_new_req_emifclk.partial_write ? rmw_data_emifclk   : from_reqfifo_new_req_emifclk.writedata;
   to_mcecc_new_req_emifclk.write_poison  = from_reqfifo_new_req_emifclk.partial_write ? rmw_poison_emifclk : from_reqfifo_new_req_emifclk.write_poison;
   to_mcecc_new_req_emifclk.req_mdata     = from_reqfifo_new_req_emifclk.req_mdata;  
   to_mcecc_new_req_emifclk.write_ras_sbe = from_reqfifo_new_req_emifclk.write_ras_sbe;     
   to_mcecc_new_req_emifclk.write_ras_dbe = from_reqfifo_new_req_emifclk.write_ras_dbe;    
   to_mcecc_new_req_emifclk.address       = from_reqfifo_new_req_emifclk.address;
   
   to_mcecc_reqfifo_empty_emifclk = from_reqfifo_new_req_emifclk.partial_write ? rmw_to_ecc_reqfifo_empty_emifclk  : from_reqfifo_empty_emifclk;

   to_mcecc_new_req_emifclk.rd_id = ( from_reqfifo_new_req_emifclk.write & from_reqfifo_new_req_emifclk.partial_write )  // if a valid partial write, then tie read to sending read op of rmw
                                  ? from_reqfifo_new_req_emifclk.wr_id   // assign to the write ID in
                                  : from_reqfifo_new_req_emifclk.rd_id;  // assign to the read  ID in

   to_mcecc_new_req_emifclk.read = ( from_reqfifo_new_req_emifclk.write & from_reqfifo_new_req_emifclk.partial_write )  // if a valid partial write, then tie read to sending read op of rmw
                                 ? mem_ready_fsm_rmw_read_valid
                                 : from_reqfifo_new_req_emifclk.read;
                                 //? (~from_rmw_rmw_pending_emifclk & ~rmw_write)  // make sure the read op cleared and the full write was sent
                                 //: from_reqfifo_new_req_emifclk.read;
end

// ================================================================================================
/* handle the write responses to the cdc_rspfifo
*/
logic to_rspfifo_bchan_wen_comb;

assign to_rspfifo_bchan_wen_comb = from_ram_init_done_del1_emifclk  // needed to block write responses back to CXLIP during ram initialization
                                 & from_emif_wr_resp_emifclk.write_resp_valid;

generate if( REG_ON_BCHAN_WEN_TO_RSPFIFO == 1 )
begin : gen_reg_bchan_wen_on

  always_ff @( posedge emifclk )
  begin
    to_rspfifo_bchan_wen_emifclk <= ~emifresetn ? 1'b0 : to_rspfifo_bchan_wen_comb;
  end
  
end
begin : gen_reg_bchan_wen_off

  assign to_rspfifo_bchan_wen_emifclk = to_rspfifo_bchan_wen_comb;
  
end
endgenerate

generate if( REG_ON_BCHAN_STRUCT_TO_RSPFIFO == 1 )
begin : gen_reg_bchan_struct_on

  always_ff @( posedge emifclk )
  begin
    to_rspfifo_wr_resp_emifclk <= from_emif_wr_resp_emifclk;
  end
  
end
begin : gen_reg_bchan_struct_off

  assign to_rspfifo_wr_resp_emifclk = from_emif_wr_resp_emifclk;

end
endgenerate

// ================================================================================================
/* handle the read responses to the cdc_rspfifo
   This is post mcecc, which combines the from_emif_read_response and the ecc result
   
   1) clock the input struct from mc_ecc if REG_ON_RMW_RD_DATA_INPUT_EN == 1
      This is to hold these items for RMWs where read responses do not propagate back to the rspfifo
*/
generate if( REG_ON_RMW_RD_DATA_INPUT_EN == 1 )
begin : reg_on_rmw_rd_data_input_on

  always_ff @(posedge emifclk)
  begin
    from_mcecc_rd_resp_emifclk_internal.read_poison     <= ~emifresetn ? '0 : from_mcecc_rd_resp_emifclk.read_poison;
    from_mcecc_rd_resp_emifclk_internal.read_resp_valid <= ~emifresetn ? '0 : from_mcecc_rd_resp_emifclk.read_resp_valid;
   
    from_mcecc_rd_resp_emifclk_internal.read_data     <= from_mcecc_rd_resp_emifclk.read_data;
    from_mcecc_rd_resp_emifclk_internal.read_id       <= from_mcecc_rd_resp_emifclk.read_id;
    from_mcecc_rd_resp_emifclk_internal.read_axi_resp <= from_mcecc_rd_resp_emifclk.read_axi_resp;
  end

end
else begin : reg_on_rmw_rd_data_input_off
  
   assign from_mcecc_rd_resp_emifclk_internal = from_mcecc_rd_resp_emifclk;

end
endgenerate
					
/* 2) assign the wen to the cdc_rchan_rspfifo
      previously in mc-channel-adapter post-mc_ecc and post-mc_rmw
*/
assign to_rspfifo_rchan_wen_emifclk = from_mcecc_rd_resp_emifclk_internal.read_resp_valid
                                    & ~block_rchan_rspfifo_wen_emifclk;

/* 3) mimic the clocking that was previously in mc_channel_adapter post-mc_ecc and post-mc_rmw
      but an interface out
*/
always_ff @(posedge emifclk)
begin	
  to_rspfifo_rd_resp_emifclk <= from_mcecc_rd_resp_emifclk;
  to_rspfifo_rd_ecc_emifclk  <= from_mcecc_rd_ecc_emifclk;
end

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3S9W1IvtHldzAds2A7qrJdDwn1nh3X30+SLP9dofsTJDIqyHsYUvVDOI0W0JpLcMTmGviEPuvtm0dnOzUcJ2PnFnzduaTZ8C56PW4EKsrx1shrWmlvfgCK/i0+O4bNoG0y78gezr9tZ3zYyoaG4ULZ8Zp1d0dmN+uJVwp7HwsghJDjLbhVlDB05jvzZ2LFnCAtyVkWbfS0/lg3rl58MZfSkTYqcpWbePWT+Wbgek51TUNKqHPdtCdVMKPX8myLKIoDREr1QjoiETSgevRYqHdkacoU3HYlWS4Jf4l1mgS1O4VJM5yQEa6hiM4bifTIZNFdOIv44ulf7CvckCuCHSDTZsRk/LQH2lrKqn8PVFTiK0TRVYUp4/+i/QTOnWeT1sHzhs4Luu020s2Nes9Cnn81HR/cSXdZiPizbGUbGmcxro393f7E1+QFR6FKgPrcH23HLXgmet82vrIIfHxGu9RNIuu+DJJdxeDTxChvpJvoCOsK8WR20oG9ySFMQH07/BuHxCjh931s3/cyKSvl4BE+BuBuZX/pwEFwAmOiJoP4P/I23egNbSiljtGYrYGXFn52INUXPxnElJ6tLFAZuT9U8KtISYbfXKU0VRajRDg3Yrdm6RJ7Zpdh4GXk0GzorUvZLhpW+eKhPq1XlmOxaoUJkH0fJ841RpCcxlM+dcIjjYN8t4uHLu7UeYUQVZ6u9LW5HMJaw7B83VS5l/Fnzr9+s1SnWXUYo5tZMUUyOZaYL1bZc88YmuwOqKcilDyAIcaK/E1LGyz2mjrNPkUVBdJDt"
`endif