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


///////////////////////////////////////////////////////////////////////////////
// This module is responsible for exposing control signals from/to the
// sequencer.
//
///////////////////////////////////////////////////////////////////////////////

module altera_emif_arch_fm_seq_if #(
   parameter PHY_CONFIG_ENUM                         = "",
   parameter USER_CLK_RATIO                          = 1,
   parameter REGISTER_AFI_C2P                        = 0,
   parameter REGISTER_AFI_P2C                        = 0,
   parameter PHY_USERMODE_OCT                        = 0,
   parameter PORT_AFI_RLAT_WIDTH                     = 1,
   parameter PORT_AFI_WLAT_WIDTH                     = 1,
   parameter PORT_AFI_SEQ_BUSY_WIDTH                 = 1,
   parameter PORT_HPS_EMIF_H2E_GP_WIDTH              = 1,
   parameter PORT_HPS_EMIF_E2H_GP_WIDTH              = 1,
   parameter PHY_PERIODIC_OCT_RECAL = 1,
   parameter IS_HPS                                  = 0
) (
   input  logic                                                     core2seq_reset_req,
   output logic                                                     seq2core_reset_done,
   input  logic [1:0]                                               core_clks_locked_cpa_pri,

   input  logic                                                     afi_clk,
   input  logic                                                     afi_reset_n,
   input  logic                                                     emif_usr_clk,
   input  logic                                                     emif_usr_reset_n,
   output logic                                                     afi_cal_success,
   output logic                                                     afi_cal_fail,
   output logic                                                     afi_cal_in_progress,
   input  logic                                                     afi_cal_req,
   output logic [PORT_AFI_RLAT_WIDTH-1:0]                           afi_rlat,
   output logic [PORT_AFI_WLAT_WIDTH-1:0]                           afi_wlat,
   output logic                                                     afi_mps_ack,
   output logic [PORT_AFI_SEQ_BUSY_WIDTH-1:0]                       afi_seq_busy,
   input  logic                                                     afi_ctl_refresh_done,
   input  logic                                                     afi_ctl_long_idle,
   input  logic                                                     afi_mps_req,
   output logic [17:0]                                              c2t_afi,
   input  logic [26:0]                                              t2c_afi,
   input  logic [PORT_HPS_EMIF_H2E_GP_WIDTH-1:0]                    hps_to_emif_gp,
   output logic [PORT_HPS_EMIF_E2H_GP_WIDTH-1:0]                    emif_to_hps_gp,
   output logic                                                     seq2core_reset_n,
   output logic                                                     ac_parity_err
);
   timeunit 1ns;
   timeprecision 1ps;

   logic clk;
   logic reset_n;

   generate
      if (PHY_CONFIG_ENUM == "CONFIG_PHY_AND_HARD_CTRL") begin : hmc
         assign clk = emif_usr_clk;
         assign reset_n = emif_usr_reset_n;
      end else begin : non_hmc
         assign clk = afi_clk;
         assign reset_n = afi_reset_n;
      end
   endgenerate

   assign c2t_afi[4:0]      = '0;

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_C2P),
      .WIDTH          (1)
   ) core2seq_reset_req_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (core2seq_reset_req),
      .data_out (c2t_afi[6])
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_C2P),
      .WIDTH          (1)
   ) afi_cal_req_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (afi_cal_req),
      .data_out (c2t_afi[8])
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_C2P),
      .WIDTH          (4)
   ) afi_ctl_refresh_done_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  ({4{afi_ctl_refresh_done}}),
      .data_out (c2t_afi[12:9])
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_C2P),
      .WIDTH          (4)
   ) afi_ctl_long_idle_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  ({4{afi_ctl_long_idle}}),
      .data_out (c2t_afi[16:13])
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_C2P),
      .WIDTH          (1)
   ) afi_mps_reg_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (afi_mps_req),
      .data_out (c2t_afi[17])
   );
   assign c2t_afi[7] = 1'b0;
   assign c2t_afi[5] = 1'b0;



   logic [PORT_AFI_RLAT_WIDTH-1:0] pre_adjusted_afi_rlat;

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_P2C),
      .WIDTH          (6)
   ) afi_rlat_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (t2c_afi[5:0]),
      .data_out (pre_adjusted_afi_rlat)
   );

   assign afi_rlat = pre_adjusted_afi_rlat + REGISTER_AFI_P2C[PORT_AFI_RLAT_WIDTH-2:0] + REGISTER_AFI_C2P[PORT_AFI_RLAT_WIDTH-2:0];

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_P2C),
      .WIDTH          (6)
   ) afi_wlat_regs (
      .clk      (clk),
      .reset_n  (1'b1),
      .data_in  (t2c_afi[11:6]),
      .data_out (afi_wlat)
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_P2C),
      .WIDTH          (4)
   ) afi_seq_busy_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (t2c_afi[23:20]),
      .data_out (afi_seq_busy)
   );

   altera_emif_arch_fm_regs # (
      .REGISTER       (REGISTER_AFI_P2C),
      .WIDTH          (1)
   ) afi_mps_ack_regs (
      .clk      (clk),
      .reset_n  (reset_n),
      .data_in  (t2c_afi[26]),
      .data_out (afi_mps_ack)
   );

   localparam SYNC_LENGTH = 3;
   
   generate
      if (IS_HPS == 0) begin : non_hps
         altera_std_synchronizer_nocut # (
            .depth     (SYNC_LENGTH),
            .rst_value (0)
         ) afi_cal_success_sync_inst (
            .clk     (clk),
            .reset_n (reset_n),
            .din     (t2c_afi[24]),
            .dout    (afi_cal_success)
         );       
         
         altera_std_synchronizer_nocut # (
            .depth     (SYNC_LENGTH),
            .rst_value (0)
         ) afi_cal_fail_sync_inst (
            .clk     (clk),
            .reset_n (reset_n),
            .din     (t2c_afi[25]),
            .dout    (afi_cal_fail)
         );     

         altera_std_synchronizer_nocut # (
            .depth     (SYNC_LENGTH),
            .rst_value (0)
         ) seq2core_reset_done_sync_inst (
            .clk     (clk),
            .reset_n (reset_n),
            .din     (t2c_afi[17]),
            .dout    (seq2core_reset_done)
         );   
         
         altera_std_synchronizer_nocut # (
            .depth     (SYNC_LENGTH),
            .rst_value (0)
         ) afi_cal_in_progress_sync_inst (
            .clk     (clk),
            .reset_n (reset_n),
            .din     (t2c_afi[16]),
            .dout    (afi_cal_in_progress)
         );   

         // Connects the parity error flag (t2c_afi[19]) to a register (ac_parity_err)
         altera_std_synchronizer_nocut # (
            .depth     (SYNC_LENGTH),
            .rst_value (0)
         ) seq2core_ac_parity_sync_inst (
            .clk (clk),
            .reset_n (reset_n),
            .din     (t2c_afi[19]),
            .dout    (ac_parity_err)
         );

         assign seq2core_reset_n = t2c_afi[18];

      end else begin : hps
         assign  afi_cal_success    = 1'b0;
         assign  afi_cal_fail       = 1'b0;
         assign  seq2core_reset_done= 1'b0;
         assign  afi_cal_in_progress= 1'b0;
         assign  ac_parity_err      = 1'b0;

         assign seq2core_reset_n    = 1'b1;
      end
   endgenerate

   assign emif_to_hps_gp = '0;
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqjoZr6elKbzOWHUIjaM0+5VM4nLvQ36Vio9KvmwfLCzK7y4dUOKFCilbLgoigXsuXKJUH6w8PmRujQ7cFlW9gzphWYtYoYEbwouIxQMR0St9HuJp+CYo0qcWXaAlGTR17T/IHKjGXiS7q7VgWtJSXV7MFfTZ8e8a6JlexDL0CnNErqdEs6h0qCZlHr326yAj+qZOF53HIkBcUPXNROdV6S+Ig6mCS5Ly00DtF0CftmvUGSaYgG3PUodxrRrHYKnYJ1NY33E2ksgGnLseDLC5k5a888vVS8C5NrFnR47WokFKcqJ2MDXO/v4cizlAffj2QpZ9pCLBwn20jvWNTWMY+WKPjRvwwnKkNcvSzVNUF9sIYcdeLfq9i892IrO9OjFNiPn8+691Fl0MzTdvS41uMOfj+gXiHgDMPbFJDMaLO0B4ZXzOsSUOGH4VVKolXD8qMPp3APZJUFmUKk+269IaX/70NNauRk6Wz3WToD8VgbU3JpnfaNL8mqd6GchJB+PwiBapJRKYIITNqTGCa38fp3UZjn1obDlrCcRcBZcWYKddZS5giMrA56rrVx3m0JjgqVNHTOlNtqJ0jdBFi6eRyKiG8PnZoI6VPCYKEv/VwB/fFUMd+XH8JjrWKxoGyaX20ozpPxLYe6oohJfO7DkNiLbtCwJG97g6ZezaSpE2eKwA5KU8/pNqZNtEkMw8NY/W8ifTaGGRTlaD6GaeiAJx2t/i4AYptEnTwurZzNCsKcXN2y3sapHTOwYioKfD15hpAQmONfznUhwZnFzq+1uBc6I"
`endif