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



module altera_emif_arch_fm_cal_counter # (
   parameter IS_HPS = 0
) (
   input logic pll_ref_clk_int,
   input logic local_reset_req_int,
   input logic afi_cal_in_progress
);
   timeunit 1ps;
   timeprecision 1ps;

   typedef enum {
      INIT,
      IDLE,
      COUNT_CAL,
      STOP
   } counter_state_t;

   logic                         done;
   logic [31:0]                  clk_counter;

   generate
      if (IS_HPS == 0) begin : non_hps
         logic                         cal_done;
         logic                         reset_req_sync;
         logic                         cal_in_progress_sync;

         altera_std_synchronizer_nocut
         inst_sync_reset_n (
            .clk     (pll_ref_clk_int),
            .reset_n (1'b1),
            .din     (local_reset_req_int),
            .dout    (reset_req_sync)
         );

         altera_std_synchronizer_nocut
         inst_sync_cal_in_progress (
            .clk     (pll_ref_clk_int),
            .reset_n (1'b1),
            .din     (afi_cal_in_progress),
            .dout    (cal_in_progress_sync)
         );

         counter_state_t counter_state /* synthesis ignore_power_up */;

         assign done = ((counter_state == STOP) ? 1'b1 : 1'b0);

         always_ff @(posedge pll_ref_clk_int) begin
            if(reset_req_sync == 1'b1) begin
               counter_state <= INIT;
            end
            else begin
               case(counter_state)
                  INIT:
                  begin
                     clk_counter <= 32'h0;
                     counter_state <= IDLE;
                  end

                  IDLE:
                  begin
                     if (cal_in_progress_sync == 1'b1)
                     begin
                        counter_state <= COUNT_CAL;
                     end
                  end

                  COUNT_CAL:
                  begin
                     clk_counter[31:0] <= clk_counter[31:0] + 32'h0000_0001;

                     if (cal_in_progress_sync == 1'b0)
                     begin
                        counter_state <= STOP;
                     end
                  end

                  STOP:
                  begin
                     counter_state <= STOP;
                  end

                  default:
                  begin
                     counter_state <= INIT;
                  end
               endcase
            end
         end
      end else begin : hps
         assign done = 1'b1;
         assign clk_counter = '0;
      end
   endgenerate

`ifdef ALTERA_EMIF_ENABLE_ISSP
   altsource_probe #(         
      .sld_auto_instance_index ("YES"),
      .sld_instance_index      (0),
      .instance_id             ("CALC"),
      .probe_width             (33),
      .source_width            (0),
      .source_initial_value    ("0"),
      .enable_metastability    ("NO")
      ) cal_counter_issp (
      .probe  ({done, clk_counter[31:0]})
   );
`endif

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "HRFB9h0JM+4tnc46TLLQGKXeO0wFf2L7Uf3z86pAG7o4XIe3zmPCNcFxIfwQnMRLnVc45aRiC0lz1DuXjuXmcYi5WzRmA9Eyd+Rg9QXs7Q+U3H84PxdgCWLgfNJh+a4mGYTcM/tgb0XFxwY8IfDnryr54Yz1pzo75222Rs3U6FhM3fCzxrnQ20kIdG4oZk+nc5kSUHTp5fDK41aMUpNmb4850AHzUXv8tZU6gDRdfqhxe8xIa+nJk3C5gM5EcX5kDUO85xlQqb49MuCYzN7dFhUfNIm9eMW3nwIB1pB6cQIKNV2WqMd06UvHnKJSOgR5qwEazCCGGKfZLuXMrJNBpGFswhNYfkQl3zankS/zR5suERzFEoIVjnADv8eSvCOLo5nbw/m1ezXHLnhiFKssQwunchqS8WdKggIYwukMZeW+tvHRqUmPj37mNz/1RIMCnqUP1qR6/zWkZRmf1S3KuZsAYkjDPXF8oZzdplFcZsnhLFWlcnyAqvz8PlkLJ/Yl64Tl2TxxLha3vZoNPCPZFMSD37DbjkeCzAl06N1fna0/W8+ZmPkMVElQWvdBkTZo4bdMDOLtsNzfI5ZGd+q2ua7a8oUr+J17Fq3pK3L2Et3HSykX3dV97A1gjdks/9wFW0zMsfCES8+Tc+ATVdMU0uT9hZr82AQZwFuirxMrAL3qjAl6ZLSDzdpn7KrtYr5TXFSy97ALUCl6v9NNH2q6MItS+VCF7kgysVMMFucX7nn6Wkc2nzwGmJLhLDAH1GQSxM0lGDDoFYNJyz8IdUjtdEnB3WtePjGVykujfAd7BAxfFQvXgjlbpF0P/CRx/RaTGvWMD3G6x3hMjfX6+qDdgcHT4VE6C1Kp+/jFkrWd/QQoRK/SRVKZJP4F5vbjsO5C2iIwlO1AZ/ffQW4FtYdShS42BBanOLfFcpN143hPSmjl2Vwscp2EoMHIzp/3rsfB1Y8Z6E8LsOOxd9HVBrdT3bPUC0fp/0hoSFGZwmhWvOOl78JzywmvJ19GjQpLvXSk"
`endif