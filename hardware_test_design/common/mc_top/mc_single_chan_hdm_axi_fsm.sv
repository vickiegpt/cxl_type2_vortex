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

module mc_single_chan_hdm_axi_fsm
  import ddr_mc_top_common_pkg::*;
  import hdm_axi_if_pkg::*;
(
  input logic emifclk,                         // EMIF User Clock
  input logic emifresetn,                      // EMIF reset
  input logic emif_avmm_1_axi_0,
 
  /* signals to/from mc_ecc_req
  */
  input ddr_mc_top_common_pkg::t_reqfifo_data_post_ecc_axi     from_mceccreq_new_req_emifclk,

  input logic from_mceccreq_reqfifo_empty_emifclk,
 
  output ddr_mc_top_common_pkg::t_emif_fsm_cntrl_to_ecc      from_mceccreq_cntrl_emifclk,
 
  /* signals to/from hdm-axi out to NoC initators / fabric connectors
  */
  output logic [hdm_axi_if_pkg::HDM_AXI_AWADDR_BW-1:0]  awaddr,
  output logic [hdm_axi_if_pkg::HDM_AXI_AWID_BW-1:0]    awid,
  output logic                                          awvalid,
   input hdm_axi_if_pkg::t_hdm_axi_wr_addr_chan_ready   awready,
  
  output logic [hdm_axi_if_pkg::HDM_AXI_WDATA_BW-1:0]   wdata,
  output logic                                          wlast,
  output logic                                          wvalid,
  output hdm_axi_if_pkg::t_hdm_axi_wuser                wuser,
   input hdm_axi_if_pkg::t_hdm_axi_wr_data_chan_ready   wready,

  output logic [hdm_axi_if_pkg::HDM_AXI_ARADDR_BW-1:0]  araddr,
  output logic [hdm_axi_if_pkg::HDM_AXI_ARID_BW-1:0]    arid,
  output logic                                          arvalid,
   input hdm_axi_if_pkg::t_hdm_axi_rd_addr_chan_ready   arready
);

// ================================================================================================
parameter DIFF_HDMAXI_ID_BW_MCTOP_ID_BW = hdm_axi_if_pkg::HDM_AXI_AWID_BW - ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW;

logic [DIFF_HDMAXI_ID_BW_MCTOP_ID_BW-1:0] diff_id_bw;
assign diff_id_bw = '0;

parameter DIFF_HDMAXI_ID_BW_MCTOP_ADDR_BW = hdm_axi_if_pkg::HDM_AXI_AWADDR_BW - (ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH + 6);

logic [DIFF_HDMAXI_ID_BW_MCTOP_ADDR_BW-1:0] diff_addr_bw;
assign diff_addr_bw = '0;

// ================================================================================================
logic mem_ready_comb;
logic to_ecc_clear_read_emifclk;
logic to_ecc_clear_write_emifclk;
logic clock_and_hold_inputs_wr;
logic clock_and_hold_inputs_rd;

logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] hold_writedata;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hold_address_wr;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hold_address_rd;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    hold_wr_id;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    hold_rd_id;

logic [7:0][7:0] hold_wuser_ecc;

logic [ddr_mc_top_common_pkg::MCTOP_MC_HA_DP_DATA_WIDTH-1:0] hold_writedata_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hold_address_wr_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] hold_address_rd_emifclk;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    hold_wr_id_emifclk;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_RAC_ID_BW-1:0]    hold_rd_id_emifclk;

logic [7:0][7:0] hold_wuser_ecc_emifclk;

// ================================================================================================
logic validWrite_notAwready_notWready;
logic validWrite_notAwready_wready;
logic validWrite_awready_notWready;
logic validWrite_awready_wready;
logic validRead_notArready;
logic validRead_arready;

assign validWrite_notAwready_notWready = ( from_mceccreq_new_req_emifclk.write & (~awready) & (~wready) );
assign validWrite_notAwready_wready    = ( from_mceccreq_new_req_emifclk.write & (~awready) &   wready  );
assign validWrite_awready_notWready    = ( from_mceccreq_new_req_emifclk.write &   awready  & (~wready) );
assign validWrite_awready_wready       = ( from_mceccreq_new_req_emifclk.write &   awready  &   wready  );
assign validRead_notArready            = ( from_mceccreq_new_req_emifclk.read  & (~arready) );
assign validRead_arready               = ( from_mceccreq_new_req_emifclk.read  &   arready );

logic notValidWrite_notValidRead;

assign notValidWrite_notValidRead = ( ~from_mceccreq_new_req_emifclk.write & ~from_mceccreq_new_req_emifclk.read );

logic awready_and_IDs_match;
logic  wready_and_IDs_match;

assign awready_and_IDs_match = awready & ( hold_wr_id_emifclk == from_mceccreq_new_req_emifclk.wr_id );
assign  wready_and_IDs_match =  wready & ( hold_wr_id_emifclk == from_mceccreq_new_req_emifclk.wr_id );

logic awready_and_wready_and_IDs_match;

assign awready_and_wready_and_IDs_match = awready & wready & ( hold_wr_id_emifclk == from_mceccreq_new_req_emifclk.wr_id );

logic arready_and_IDs_match;

assign arready_and_IDs_match = arready & ( hold_rd_id_emifclk == from_mceccreq_new_req_emifclk.rd_id );


// ================================================================================================
always_comb
begin
  from_mceccreq_cntrl_emifclk.clear_write_valid = to_ecc_clear_write_emifclk;
  from_mceccreq_cntrl_emifclk.clear_read_valid  = to_ecc_clear_read_emifclk;
  from_mceccreq_cntrl_emifclk.mem_ready         = mem_ready_comb;
end

// ================================================================================================

assign hold_writedata = emif_avmm_1_axi_0
                        ? '0
                        : clock_and_hold_inputs_wr
                          ? from_mceccreq_new_req_emifclk.writedata
                          : hold_writedata_emifclk;

assign hold_address_wr = emif_avmm_1_axi_0
                         ? '0
                         : clock_and_hold_inputs_wr
                           ? from_mceccreq_new_req_emifclk.address
                           : hold_address_wr_emifclk;

assign hold_wr_id = emif_avmm_1_axi_0
                    ? '0
                    : clock_and_hold_inputs_wr
                      ? from_mceccreq_new_req_emifclk.wr_id
                      : hold_wr_id_emifclk;

assign hold_wuser_ecc = emif_avmm_1_axi_0
                        ? '0
                        : clock_and_hold_inputs_wr
                          ? from_mceccreq_new_req_emifclk.wuser_ecc
                          : hold_wuser_ecc_emifclk;
						  
assign hold_address_rd = emif_avmm_1_axi_0
                         ? '0
                         : clock_and_hold_inputs_rd
                           ? from_mceccreq_new_req_emifclk.address
                           : hold_address_rd_emifclk;
						
assign hold_rd_id = emif_avmm_1_axi_0
                    ? '0
                    : clock_and_hold_inputs_rd
                      ? from_mceccreq_new_req_emifclk.rd_id
                      : hold_rd_id_emifclk;

// ================================================================================================
always_ff @( posedge emifclk )
begin
   hold_writedata_emifclk <= hold_writedata;
  hold_address_wr_emifclk <= hold_address_wr;
       hold_wr_id_emifclk <= hold_wr_id;
   hold_wuser_ecc_emifclk <= hold_wuser_ecc;
  hold_address_rd_emifclk <= hold_address_rd;
       hold_rd_id_emifclk <= hold_rd_id;
end 

// ================================================================================================
/* AXI4 read & write request control + reads to CDC Request fifo from AXI4
 */
typedef enum logic [3:0] {
  WAIT                     = 'd0,
  WAIT_FOR_WREADY_1        = 'd1,
  WAIT_FOR_AWREADY_1       = 'd2,
  WAIT_BOTH_WREADYS_1      = 'd3,
  WAIT_FOR_AREADY_1        = 'd4,
  WAIT_FOR_WREADY_2        = 'd5,
  WAIT_FOR_AWREADY_2       = 'd6,
  WAIT_BOTH_WREADYS_2      = 'd7,
  WAIT_FOR_AREADY_2        = 'd8  
} e_axi_req_fsm;

e_axi_req_fsm        req_state;
e_axi_req_fsm   next_req_state;

always_ff @( posedge emifclk )
begin
  req_state <= ( ~emifresetn | emif_avmm_1_axi_0 ) ? WAIT : next_req_state;
end

// ================================================================================================
always_comb
begin
  awvalid = 1'b0;
  awid    =  'd0;
  awaddr  =  'd0;
   wvalid = 1'b0;
   wdata  =  'd0;
   wlast  = 1'b0;
   wuser  =  'd0;
  arvalid = 1'b0;
  arid    =  'd0;
  araddr  =  'd0;
  
  mem_ready_comb             = 1'b0;
  to_ecc_clear_read_emifclk  = 1'b0;
  to_ecc_clear_write_emifclk = 1'b0;
  clock_and_hold_inputs_wr   = 1'b0;
  clock_and_hold_inputs_rd   = 1'b0;

  case( req_state )
    WAIT :
    begin
      if( from_mceccreq_new_req_emifclk.write )
	    begin
           awvalid = 1'b1;
              awid = {diff_id_bw,   from_mceccreq_new_req_emifclk.wr_id};
            awaddr = {diff_addr_bw, from_mceccreq_new_req_emifclk.address, 6'd0};  // include byte addressing
            wvalid = 1'b1;
             wdata = from_mceccreq_new_req_emifclk.writedata;
             wlast = 1'b1;
             wuser = from_mceccreq_new_req_emifclk.wuser_ecc;
      end
      
      if( from_mceccreq_new_req_emifclk.read )
	    begin
           arvalid = 1'b1;
              arid = {diff_id_bw,   from_mceccreq_new_req_emifclk.rd_id};
            araddr = {diff_addr_bw, from_mceccreq_new_req_emifclk.address, 6'd0};  // include byte addressing
      end

           if( validWrite_notAwready_notWready ) next_req_state = WAIT_BOTH_WREADYS_1; // valid request in but neither write chan ready
	    else if( validWrite_notAwready_wready )    next_req_state = WAIT_FOR_AWREADY_1;  // valid request in but write addr chan not ready
	    else if( validWrite_awready_notWready )    next_req_state = WAIT_FOR_WREADY_1;   // valid request in but write data chan not ready
	    else if( validWrite_awready_wready )       next_req_state = WAIT;                // valid request in and both write chans readys
      else if( validRead_arready )               next_req_state = WAIT;                // valid request in and read addr chan ready
	    else if( validRead_notArready )            next_req_state = WAIT_FOR_AREADY_1;   // valid request in but read addr chan not ready
	    else                                       next_req_state = WAIT;                // probably an error, means valid req with neither write or read set     

           if( notValidWrite_notValidRead ) mem_ready_comb = 1'b1; // probably an error, means valid req with neither write or read set
      else if( validWrite_awready_wready )  mem_ready_comb = 1'b1; // back to waiting on a valid request in
      else if( validRead_arready )          mem_ready_comb = 1'b1; // back to waiting on a valid request in
		
           if( validWrite_notAwready_notWready ) clock_and_hold_inputs_wr = 1'b1;  // both wr chans NOT ready, so clock-and-hold inputs
      else if( validWrite_notAwready_wready )    clock_and_hold_inputs_wr = 1'b1;  //  wr addr chan NOT ready, so clock-and-hold inputs		
      else if( validWrite_awready_notWready )    clock_and_hold_inputs_wr = 1'b1;  //  wr data chan NOT ready, so clock-and-hold inputs
		
      if( validRead_notArready ) clock_and_hold_inputs_rd = 1'b1;  // rd req and rd addr chan NOT ready, so clock-and-hold inputs

      if( validWrite_awready_wready ) to_ecc_clear_write_emifclk = 1'b1;  // wr req and wr addr+data chan ready, so clear the input
		
      if( validRead_arready ) to_ecc_clear_read_emifclk   = 1'b1;  // rd req and rd addr chan ready, so clear the input		
    end

    WAIT_FOR_AWREADY_1 : // need the write address channel to confirm, unset the write data channel
    begin
      // hold these steady
      awvalid = 1'b1;
         awid = {diff_id_bw,   from_mceccreq_new_req_emifclk.wr_id};
	     awaddr = {diff_addr_bw, from_mceccreq_new_req_emifclk.address, 6'd0};  // include byte addressing

      if( awready ) next_req_state = WAIT;
      else          next_req_state = WAIT_FOR_AWREADY_2;
		
      if( awready ) mem_ready_comb = 1'b1;
      
           if(  awready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
      else if( ~awready )               to_ecc_clear_write_emifclk = 1'b1; // still waiting on awready, haven't provided mem_ready back yet
	  end
	  
    WAIT_FOR_AWREADY_2 : // still need the write address channel to confirm  
    begin
      // hold these steady
      awvalid = 1'b1;
         awid = {diff_id_bw,   hold_wr_id_emifclk};
	     awaddr = {diff_addr_bw, hold_address_wr_emifclk, 6'd0};  // include byte addressing
	  
      if( awready ) next_req_state = WAIT;
      else          next_req_state = WAIT_FOR_AWREADY_2;
	  
      if( awready ) mem_ready_comb = 1'b1;
      
      if( awready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
	  end	  

    WAIT_FOR_WREADY_1 : // need the write data channel to confirm, unset the write address channel
    begin
      // hold these steady 
      wvalid = 1'b1;
       wlast = 1'b1;
       wdata = from_mceccreq_new_req_emifclk.writedata;
       wuser = from_mceccreq_new_req_emifclk.wuser_ecc;
    
      if( wready ) next_req_state = WAIT;
      else         next_req_state = WAIT_FOR_WREADY_2;
	   
      if( wready ) mem_ready_comb = 1'b1;
	   
      if(   wready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
	  end
    
    WAIT_FOR_WREADY_2 : // still need the write data channel to confirm
    begin
      // hold these steady 
      wvalid = 1'b1;
       wlast = 1'b1;
       wdata = hold_writedata_emifclk;
       wuser = hold_wuser_ecc_emifclk;
    
      if( wready ) next_req_state = WAIT;
      else         next_req_state = WAIT_FOR_WREADY_2;
	   
      if( wready ) mem_ready_comb = 1'b1;
	   
      if( wready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
	  end

    WAIT_BOTH_WREADYS_1 : // had an active write request come in, need both channels to confirm
    begin
      // hold these steady 
      awvalid = 1'b1;
       wvalid = 1'b1;
        wlast = 1'b1;	   
         awid = {diff_id_bw,   from_mceccreq_new_req_emifclk.wr_id};
       awaddr = {diff_addr_bw, from_mceccreq_new_req_emifclk.address, 6'd0};  // include byte addressing
        wdata = from_mceccreq_new_req_emifclk.writedata;
        wuser = from_mceccreq_new_req_emifclk.wuser_ecc;
		
           if(  awready &  wready ) next_req_state = WAIT;
	    else if(  awready & ~wready )	next_req_state = WAIT_FOR_WREADY_2;	
	    else if( ~awready &  wready ) next_req_state = WAIT_FOR_AWREADY_2;
      else                          next_req_state = WAIT_BOTH_WREADYS_2;

      if( awready & wready ) mem_ready_comb = 1'b1;
 
      if( awready_and_wready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
	  end

    WAIT_BOTH_WREADYS_2 : // still need both channels to confirm
    begin
      // hold these steady 
      awvalid = 1'b1;
       wvalid = 1'b1;
        wlast = 1'b1;	   
         awid = {diff_id_bw,   hold_wr_id_emifclk};
       awaddr = {diff_addr_bw, hold_address_wr_emifclk, 6'd0};  // include byte addressing
        wdata = hold_writedata_emifclk;
        wuser = hold_wuser_ecc_emifclk;
	  
           if(  awready &  wready ) next_req_state = WAIT;
	    else if(  awready & ~wready )	next_req_state = WAIT_FOR_WREADY_2;	
	    else if( ~awready &  wready ) next_req_state = WAIT_FOR_AWREADY_2;
      else                          next_req_state = WAIT_BOTH_WREADYS_2;
	  
      if( awready & wready ) mem_ready_comb = 1'b1;
      
      if( awready_and_wready_and_IDs_match ) to_ecc_clear_write_emifclk = 1'b1; // clear write if hold_id equals input_id
	  end

    WAIT_FOR_AREADY_1 : // need the read address channel to confirm
    begin
      // hold these steady 
  	  arvalid = 1'b1;		
      arid    = {diff_id_bw,   from_mceccreq_new_req_emifclk.rd_id};
      araddr  = {diff_addr_bw, from_mceccreq_new_req_emifclk.address, 6'd0}; // include byte addressing
    
      if( arready ) next_req_state = WAIT;
      else          next_req_state = WAIT_FOR_AREADY_2;
    
      if( arready ) mem_ready_comb = 1'b1;
      
      if( arready_and_IDs_match ) to_ecc_clear_read_emifclk = 1'b1; // clear read if hold_id equals input_id
	  end
    
    WAIT_FOR_AREADY_2 : // still need the read address channel to confirm
    begin
      // hold these steady 
  	  arvalid = 1'b1;		
         arid = {diff_id_bw,   hold_rd_id_emifclk};
       araddr = {diff_addr_bw, hold_address_rd_emifclk, 6'd0}; // include byte addressing
    
      if( arready ) next_req_state = WAIT;
      else          next_req_state = WAIT_FOR_AREADY_2;
    
      if( arready ) mem_ready_comb = 1'b1;
    
      if( arready_and_IDs_match ) to_ecc_clear_read_emifclk = 1'b1; // clear read if hold_id equals input_id
	  end

    default :                                              next_req_state = WAIT;  
  endcase
end

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3TqyVfzU+rSqHufBfTGAL8DMwp+3QHNCVAlv91kuTQ9etm0cfTuLPYty4d9+watL3N2vf6lX94LAv3OCVXCHyHOpn8vrqfzL+uFIDndhtIVqgzLGWO7mfV2Y0/7HB0hLA9fS/6QS4b0ZXwXy+OazjcNT0syCs+7iAERlIyi6OBM6fMpMG8eCMXOTdaNr1f3PJWxi57w/+Rq0qfVIDBatrciekqOjrsHybuAPe9+8cwugu2e9ajdyTVgwmUdk/xM3UYxhlC0N85/2YUSzPmk9I4d6Sy2PHfyRwomGtkY9kplDqZ6sJpqjk4hpYQ6cp5Yz22uBb+9KrBDGMpTN3QT194IinJThLebc5plhFo/MnRM6s3Lp/+Ct8bh2M5dRSDvdAxAKQox7tvItkIthW8Tct3HOA5A9RnGzbmFDfSSq/NsXJye2y5U2x6OrmY6uHmylOLeS/ZNuah61i4oDyJhoN20eNYKF0g90WqYIMzMmfxitcmsdm4JYiRvcbdK8Yx+ukHHcj6R2IOecGxqbI/LXbLv09s+YND8DnR1gcg7SpuotTDcM1rs1BLOFNcph6gcbMtnP/cupfSVt+a/S+Ni0zF/Foz6UuGbcbMbdrjJMjG0SE85bVeqNqPTeac7BlHaTAWtXDnIX5GegGpSDR/RDY8T9JhsLfvIqzTekNi/tzlGQlyk1IQejvC/qXdw/PaiDTe/E60v8FxVXmQl/8mku2QCLNq8jPHbCXyYH3Kd5/tWWhKh5QskD/DbhaK3GEzidpn4XNfzfFpPLZtQwVQCXpAM"
`endif