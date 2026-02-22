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

module mc_single_chan_ram_init
  import ddr_mc_top_common_pkg::*;
#(
  parameter USE_ORIGINAL_RAM_INIT = 0,  // 0 - OFF; 1 - ON
  parameter MC_RAM_INIT_W_ZERO_EN = 1,  // 0 - OFF; 1 - ON
  parameter RST_REG_NUM           = 2
 )
(
  input logic                   emifclk,
  input logic                   emifresetn,
  input logic [RST_REG_NUM-1:0] emifresetn_reg,
  
  input logic emif_avmm_1_axi_0,
  input logic from_rmw_memory_ready_emifclk,
  input logic from_emif_write_resp_valid_emifclk,

  output logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_emifclk,
  output logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0]    ram_init_wr_id_emifclk,
 
  output logic ram_init_done_emifclk,
  output logic ram_init_done_del1_emifclk,
  output logic ram_init_wr_en_emifclk
);

// ================================================================================================
localparam FINAL_ADDR = ((2**(ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH)) - 1);

logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_comb;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_req_counter_plus1;

logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_comb;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_emifclk;
logic [ddr_mc_top_common_pkg::MCTOP_EMIF_AMM_ADDR_WIDTH-1:0] write_resp_counter_plus1;

logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_comb;
logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] ram_init_addr_plus1;

logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] ram_init_wr_id_comb;
logic [ddr_mc_top_common_pkg::MC_LOCAL_AXI_WAC_ID_BW-1:0] ram_init_wr_id_plus1;

logic [2:0] sync_counter_comb;
logic [2:0] sync_counter_emifclk;
logic       sync_counter_equals_zero;

logic ram_init_done_comb;
logic ram_init_wr_en_comb;
logic ram_init_addr_equals_final_addr;
logic wr_req_count_equals_wr_resp_count;

// ================================================================================================
assign ram_init_addr_equals_final_addr = ( ram_init_addr_emifclk == FINAL_ADDR );

assign sync_counter_equals_zero = ( sync_counter_emifclk == '0 );

assign wr_req_count_equals_wr_resp_count = ( write_req_counter_emifclk == write_resp_counter_emifclk );

assign write_req_counter_plus1 = ( write_req_counter_emifclk + 'd1 );

assign write_resp_counter_plus1 = ( write_resp_counter_emifclk + 'd1 );

assign ram_init_addr_plus1 = ( ram_init_addr_emifclk + 'd1 );

assign ram_init_wr_id_plus1 = ( ram_init_wr_id_emifclk + 'd1 );

// ================================================================================================ sync counter out of reset
assign sync_counter_comb = ( ram_init_done_emifclk | sync_counter_equals_zero )
                           ? '0
                           : ( sync_counter_emifclk - 3'b001 );

always_ff @( posedge emifclk )
begin
  sync_counter_emifclk <= ( ~emifresetn ) ? 3'b111 : sync_counter_comb;
end

// ================================================================================================ ram init done delay
generate if( MC_RAM_INIT_W_ZERO_EN == 1 )
begin : gen_done_delay_on

  always_ff @(posedge emifclk)
  begin
    ram_init_done_del1_emifclk <= ( ~emifresetn_reg[RST_REG_NUM-2] ) ? 1'b0 : ram_init_done_emifclk;
  end
  
end
else begin : gen_done_delay_off

  assign ram_init_done_del1_emifclk = 1'b1;

end
endgenerate

// ================================================================================================
generate if( USE_ORIGINAL_RAM_INIT == 0 // ============================================================================ ram init on new
           & MC_RAM_INIT_W_ZERO_EN == 1
           )
begin : gen_ram_init_on_new

  typedef enum logic [2:0] {
    RI_WAIT_ON_SYNC          = 'd0,
    RI_FIRST_REQ             = 'd1,
    RI_SENDING_REQS          = 'd2,
    RI_WAIT_RESPS            = 'd3,
	RI_COMPLETE              = 'd4,
	RI_SEND_SINGLE_REQ       = 'd5,
	RI_WAIT_SINGLE_RESP      = 'd6
  } t_enum_rmw_ram_init_fsm;

  t_enum_rmw_ram_init_fsm   next_state_ram_init;
  t_enum_rmw_ram_init_fsm        state_ram_init;


  always@( posedge emifclk )
  begin
    state_ram_init <= ~emifresetn ? RI_WAIT_ON_SYNC : next_state_ram_init;
  end


  always_comb
  begin
    ram_init_addr_comb     = ram_init_addr_emifclk;
    ram_init_wr_id_comb    = ram_init_wr_id_emifclk;
    ram_init_wr_en_comb    = 1'b0;
    ram_init_done_comb     = 1'b0;
    write_req_counter_comb = write_req_counter_emifclk;

    case( state_ram_init )
      RI_WAIT_ON_SYNC :
      begin
        `ifdef SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY // To skip whole or majority of memory initialization - used in t2ip but not t3ip
           if( sync_counter_equals_zero )                  next_state_ram_init = RI_SEND_SINGLE_REQ;
           else                                            next_state_ram_init = RI_WAIT_ON_SYNC;
        `else
           if( sync_counter_equals_zero )                  next_state_ram_init = RI_FIRST_REQ;   //RI_SENDING_REQS;
           else                                            next_state_ram_init = RI_WAIT_ON_SYNC;

           if( sync_counter_equals_zero )                  ram_init_wr_en_comb = 1'b1;          
        `endif
      end

      RI_FIRST_REQ :
      begin
        /* needed because from_rmw_memory_ready_emifclk is high out of reset and does not go low
           until a cycle after the first req comes in, causing the second req to drop
        */
        ram_init_wr_en_comb = 1'b1;

        if( from_rmw_memory_ready_emifclk ) next_state_ram_init = RI_SENDING_REQS;
        else                                next_state_ram_init = RI_FIRST_REQ;

        if( from_rmw_memory_ready_emifclk )
        begin
            ram_init_addr_comb = ram_init_addr_plus1;
            ram_init_wr_id_comb = ram_init_wr_id_plus1;

            if( ~emif_avmm_1_axi_0 )  // start counting here in AXI mode but not avmm mode
            begin
               write_req_counter_comb = write_req_counter_plus1;
            end
        end
     end
  
      RI_SENDING_REQS :
      begin
        if( ram_init_addr_equals_final_addr & from_rmw_memory_ready_emifclk )
        begin
            write_req_counter_comb = write_req_counter_plus1;
               next_state_ram_init = RI_WAIT_RESPS;        
        end
        else if( ram_init_addr_equals_final_addr )
        begin
            ram_init_wr_en_comb = 1'b1;
            next_state_ram_init = RI_SENDING_REQS;
        end
        else if( from_rmw_memory_ready_emifclk )
        begin
            ram_init_wr_en_comb = 1'b1;
            ram_init_addr_comb = ram_init_addr_plus1;
            ram_init_wr_id_comb = ram_init_wr_id_plus1;
            write_req_counter_comb = write_req_counter_plus1;
            next_state_ram_init = RI_SENDING_REQS;
        end
        else begin
            ram_init_wr_en_comb = 1'b1;
            next_state_ram_init = RI_SENDING_REQS;
        end
      end

      RI_WAIT_RESPS :
      begin
         // wait for the response count to equal the request sent count
        if( wr_req_count_equals_wr_resp_count )            next_state_ram_init = RI_COMPLETE;
        else                                               next_state_ram_init = RI_WAIT_RESPS;
      end

      RI_COMPLETE :
      begin
                                                            ram_init_done_comb = 1'b1;
                                                           next_state_ram_init = RI_COMPLETE;
      end
      
      `ifdef SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY // To skip whole or majority of memory initialization - used in t2ip but not t3ip      
        RI_SEND_SINGLE_REQ :
        begin
                                                           ram_init_wr_en_comb = 1'b1;        
                                                            ram_init_addr_comb = '0;
                                                           ram_init_wr_id_comb = '0;
		  if( from_rmw_memory_ready_emifclk )              next_state_ram_init = RI_WAIT_SINGLE_RESP;
		  else                                             next_state_ram_init = RI_SEND_SINGLE_REQ;
        end
      
        RI_WAIT_SINGLE_RESP :
        begin
		  if( from_emif_write_resp_valid_emifclk )         next_state_ram_init = RI_COMPLETE;
		  else                                             next_state_ram_init = RI_WAIT_SINGLE_RESP;
        end
      `endif
   
      default :
	  begin
	                                                       next_state_ram_init = RI_COMPLETE;
      end
    endcase
  end
  
  // ==============================================================================================     
  always_ff @(posedge emifclk) ram_init_wr_en_emifclk <= ( ~emifresetn ) ? 1'b0 : ram_init_wr_en_comb;
  
  always_ff @(posedge emifclk) ram_init_wr_id_emifclk <= ( ~emifresetn ) ? '0 : ram_init_wr_id_comb;
  
  always_ff @(posedge emifclk) ram_init_done_emifclk  <= ( ~emifresetn ) ? 1'b0 : ram_init_done_comb;
  
  always_ff @(posedge emifclk) write_req_counter_emifclk <= ( ~emifresetn ) ?'0 : write_req_counter_comb;
  
  `ifdef SIM_MC_RAM_INIT_W_ZERO_PARTIAL_ONLY

	 logic [ddr_mc_top_common_pkg::MCTOP_MEMCNTRL_ADDR_WIDTH-1:0] start_addr;
	 assign start_addr = FINAL_ADDR - 'd128;
	 
	 always_ff @(posedge emifclk) ram_init_addr_emifclk  <= ( ~emifresetn ) ? start_addr : ram_init_addr_comb;
	 
  `else

     always_ff @(posedge emifclk) ram_init_addr_emifclk  <= ( ~emifresetn ) ? '0 : ram_init_addr_comb;	
	   
  `endif

  // ============================================================================================== write response counter
  assign write_resp_counter_comb = ram_init_done_emifclk
                                   ? write_resp_counter_emifclk
                                   : ~sync_counter_equals_zero   // sync counter not yet zero
                                     ? '0
                                     : from_emif_write_resp_valid_emifclk
                                       ? write_resp_counter_plus1
                                       : write_resp_counter_emifclk;

  always_ff @(posedge emifclk)
  begin  
    write_resp_counter_emifclk <= ( ~emifresetn ) ? '0 : write_resp_counter_comb;
  end  

end
else if( USE_ORIGINAL_RAM_INIT == 1 // ================================================================================ ram init on original
       & MC_RAM_INIT_W_ZERO_EN == 1
       )
begin : gen_ram_init_on_old

  assign ram_init_addr_comb = '0;
  assign ram_init_wr_id_comb = '0;

  always_ff @(posedge emifclk)
  begin
    if( from_rmw_memory_ready_emifclk & ~ram_init_done_emifclk )
	begin
	  ram_init_addr_emifclk  <= ram_init_addr_emifclk  + 'd1;
	  ram_init_wr_id_emifclk <= ram_init_wr_id_emifclk + 'd1;
    end
    
    if (~emifresetn_reg[RST_REG_NUM-1])
	begin
	  ram_init_addr_emifclk  <= '0;
	  ram_init_wr_id_emifclk <= '0;
    end
  end

  `ifdef SIM_MC_RAM_INIT_W_ZERO_SINGLE_ONLY // To skip whole or majority of memory initialization - used in t2ip but not t3ip

     always_ff @(posedge emifclk)
     begin
        ram_init_done_emifclk <= ~emifresetn
                                 ? 1'b0
                                 : ( from_rmw_memory_ready_emifclk & ( ram_init_addr_emifclk == '0 ))
                                   ? 1'b1
                                   : ram_init_done_emifclk;
     end

  `else

     always_ff @(posedge emifclk)
     begin
        ram_init_done_emifclk <= ~emifresetn
                                 ? 1'b0
                                 : ( from_rmw_memory_ready_emifclk & ram_init_addr_equals_final_addr )
                                   ? 1'b1
                                   : ram_init_done_emifclk;
     end

  `endif

  assign write_req_counter_comb = '0;
  assign write_req_counter_emifclk = '0;
  
  assign write_resp_counter_comb = '0;
  assign write_resp_counter_emifclk = '0;
  
  assign ram_init_wr_en_comb = 1'b0;
  assign ram_init_wr_en_emifclk = 1'b1;
  
  assign ram_init_done_comb = 1'b0;
  
end
else begin : gen_ram_init_off // ====================================================================================== ram init off

  assign ram_init_addr_comb = '0;
  assign ram_init_addr_emifclk = '0;

  assign ram_init_wr_id_comb = '0;
  assign ram_init_wr_id_emifclk = '0;

  assign write_req_counter_comb = '0;
  assign write_req_counter_emifclk = '0;

  assign write_resp_counter_comb = '0;
  assign write_resp_counter_emifclk = '0;

  assign ram_init_wr_en_comb = 1'b0;
  assign ram_init_wr_en_emifclk = 1'b0;

  assign ram_init_done_comb = 1'b1;
  assign ram_init_done_emifclk = 1'b1;

end
endgenerate

// ================================================================================================
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "9dP2rrkT6Qw2uDZoiFnemLu4hDPgm5kLPB4Oah83qQND5Xnhi9Hs9rs+h97Twdv7kXxmhl9OlNXQmDisvAqLebbjZeLAFMoSbw6OJPSrto8M05dxTUtmhPJ+JyzT49mc4OKRxZSS+RNAYvaY8cdOt95a5a6tv2+Sioo6RwzMUMC7knPn8TUgizSrdtTH3OkFAxgSJFdQSOy0Ssxqpc1F7xcOkumMGGX9b2Lbzn9Lg3Qiksr3pBLID/2DLv8CJvzCn7PdiXgyQ6xQjjNEA8gh5a5DWE/fliocvMSkZkB6cvKRjxvJlE8pkyaXmX/zGv1slKOamoVgagaS0jwKsvigQ5Gg6CYyjWo3Q0QVwPWvOSq9s8C7A1+emz9oDGKQcF4daheuwQpWAeZAWY+Yf6CquVcRWxGgQWrjL77TQkrzN3b7bPzvjLr9LasolMvIfp9fijyCyrvH2AJx6H2cfmG8xehe8Gf5eJoVxc+1ija1BeGiZM8c0Xu0eiwMq6kOkRj5sLG9kCpmmQ0kCVq5HKZ0swJPNSJUgJWsWozt37xxw85qGjvbFz28JJBIZZK6Hyj8GK6i+DyhFjyoM39KQ5MnnkxXzWpaIYnfrRbXPXez4PMsdHOaDdT7zy8ibTMaVaZ17flY9XEJ7GcRXgBio2R89fXKmlDHunt++NXy7aSdg1jNKFPbbpXpYSkzdrlg9zyX1Ir5MFbMa4FAddyoy4L2XbLePBYMd0DnMIA54pd9EdcHnF+Q9JgS5K1oUREEdyFEJ0jf+EV0+FHABgiHZk1rciY1a43Fi+0DHHtjOj51DkVVDuthZ1NFGgnMulX2oqWqEXp9zRUaF6riQiQnl8JXNkmX0mpR6mZGlfG8sBKguDjhXC84aH57KWWhpCGAt7n1LY4uHba7Ajp7y0zGyzNv1MoCb5xoGICpj5+VA+z4p2VWfhoRRzaQaA0ANcqOCKKUlPOLMRU5P1/TcQaulJtWnSGdhRYANIErxDXNtyyACI6sLJ1gIZ2IuZrgUanUBP1l"
`endif