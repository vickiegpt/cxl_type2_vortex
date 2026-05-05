module intel_rtile_cxl_top_cxltyp2_ed (
		input  wire         refclk0,                           //             refclk0.clk
		input  wire         refclk1,                           //             refclk1.clk
		input  wire         refclk4,                           //             refclk4.clk
		input  wire         resetn,                            //              resetn.reset_n
		input  wire         nInit_done,                        //          ninit_done.ninit_done
		output wire         pll_lock_o,                        //                 pll.pll_lock_o
		input  wire [1:0]   usr2ip_qos_devload,                //         qos_devload.usr2ip_qos_devload
		output wire         ip2hdm_clk,                        //          ip2hdm_clk.clk
		output wire         ip2hdm_reset_n,                    //      ip2hdm_reset_n.reset_n
		output wire         cxl_warm_rst_n,                    //      cxl_warm_rst_n.reset_n
		output wire         cxl_cold_rst_n,                    //      cxl_cold_rst_n.reset_n
		input  wire [63:0]  mc2ip_memsize,                     //            hdm_size.mem_size_t
		input  wire [15:0]  cxl_rx_n,                          //              cxl_rx.cxl_rx_n
		input  wire [15:0]  cxl_rx_p,                          //                    .cxl_rx_p
		output wire [15:0]  cxl_tx_n,                          //              cxl_tx.cxl_tx_n
		output wire [15:0]  cxl_tx_p,                          //                    .cxl_tx_p
		input  wire [4:0]   mc2ip_0_sr_status,                 //             mc2ip_0.mc_sr_status
		input  wire [4:0]   mc2ip_1_sr_status,                 //             mc2ip_1.mc_sr_status
		output wire         ip2cafu_quiesce_req,               //             quiesce.quiesce_req
		input  wire         cafu2ip_quiesce_ack,               //                    .quiesce_ack
		input  wire [11:0]  cafu2ip_aximm0_awid,               // axi2ccip_wraddr_ch0.awid
		input  wire [63:0]  cafu2ip_aximm0_awaddr,             //                    .awaddr
		input  wire [9:0]   cafu2ip_aximm0_awlen,              //                    .awlen
		input  wire [2:0]   cafu2ip_aximm0_awsize,             //                    .awsize
		input  wire [1:0]   cafu2ip_aximm0_awburst,            //                    .awburst
		input  wire [2:0]   cafu2ip_aximm0_awprot,             //                    .awprot
		input  wire [3:0]   cafu2ip_aximm0_awqos,              //                    .awqos
		input  wire [6:0]   cafu2ip_aximm0_awuser,             //                    .awuser
		input  wire         cafu2ip_aximm0_awvalid,            //                    .awvalid
		input  wire [3:0]   cafu2ip_aximm0_awcache,            //                    .awcache
		input  wire [1:0]   cafu2ip_aximm0_awlock,             //                    .awlock
		input  wire [3:0]   cafu2ip_aximm0_awregion,           //                    .awregion
		input  wire [5:0]   cafu2ip_aximm0_awatop,             //                    .awatop
		output wire         ip2cafu_aximm0_awready,            //                    .awready
		input  wire [11:0]  cafu2ip_aximm1_awid,               // axi2ccip_wraddr_ch1.awid
		input  wire [63:0]  cafu2ip_aximm1_awaddr,             //                    .awaddr
		input  wire [9:0]   cafu2ip_aximm1_awlen,              //                    .awlen
		input  wire [2:0]   cafu2ip_aximm1_awsize,             //                    .awsize
		input  wire [1:0]   cafu2ip_aximm1_awburst,            //                    .awburst
		input  wire [2:0]   cafu2ip_aximm1_awprot,             //                    .awprot
		input  wire [3:0]   cafu2ip_aximm1_awqos,              //                    .awqos
		input  wire [6:0]   cafu2ip_aximm1_awuser,             //                    .awuser
		input  wire         cafu2ip_aximm1_awvalid,            //                    .awvalid
		input  wire [3:0]   cafu2ip_aximm1_awcache,            //                    .awcache
		input  wire [1:0]   cafu2ip_aximm1_awlock,             //                    .awlock
		input  wire [3:0]   cafu2ip_aximm1_awregion,           //                    .awregion
		input  wire [5:0]   cafu2ip_aximm1_awatop,             //                    .awatop
		output wire         ip2cafu_aximm1_awready,            //                    .awready
		input  wire [511:0] cafu2ip_aximm0_wdata,              // axi2ccip_wrdata_ch0.wdata
		input  wire [63:0]  cafu2ip_aximm0_wstrb,              //                    .wstrb
		input  wire         cafu2ip_aximm0_wlast,              //                    .wlast
		input  wire         cafu2ip_aximm0_wuser,              //                    .wuser
		input  wire         cafu2ip_aximm0_wvalid,             //                    .wvalid
		output wire         ip2cafu_aximm0_wready,             //                    .wready
		input  wire [511:0] cafu2ip_aximm1_wdata,              // axi2ccip_wrdata_ch1.wdata
		input  wire [63:0]  cafu2ip_aximm1_wstrb,              //                    .wstrb
		input  wire         cafu2ip_aximm1_wlast,              //                    .wlast
		input  wire         cafu2ip_aximm1_wuser,              //                    .wuser
		input  wire         cafu2ip_aximm1_wvalid,             //                    .wvalid
		output wire         ip2cafu_aximm1_wready,             //                    .wready
		output wire [11:0]  ip2cafu_aximm0_bid,                //  axi2ccip_wrrsp_ch0.bid
		output wire [1:0]   ip2cafu_aximm0_bresp,              //                    .bresp
		output wire [3:0]   ip2cafu_aximm0_buser,              //                    .buser
		output wire         ip2cafu_aximm0_bvalid,             //                    .bvalid
		input  wire         cafu2ip_aximm0_bready,             //                    .bready
		output wire [11:0]  ip2cafu_aximm1_bid,                //  axi2ccip_wrrsp_ch1.bid
		output wire [1:0]   ip2cafu_aximm1_bresp,              //                    .bresp
		output wire [3:0]   ip2cafu_aximm1_buser,              //                    .buser
		output wire         ip2cafu_aximm1_bvalid,             //                    .bvalid
		input  wire         cafu2ip_aximm1_bready,             //                    .bready
		input  wire [11:0]  cafu2ip_aximm0_arid,               // axi2ccip_rdaddr_ch0.arid
		input  wire [63:0]  cafu2ip_aximm0_araddr,             //                    .araddr
		input  wire [9:0]   cafu2ip_aximm0_arlen,              //                    .arlen
		input  wire [2:0]   cafu2ip_aximm0_arsize,             //                    .arsize
		input  wire [1:0]   cafu2ip_aximm0_arburst,            //                    .arburst
		input  wire [2:0]   cafu2ip_aximm0_arprot,             //                    .arprot
		input  wire [3:0]   cafu2ip_aximm0_arqos,              //                    .arqos
		input  wire [5:0]   cafu2ip_aximm0_aruser,             //                    .aruser
		input  wire         cafu2ip_aximm0_arvalid,            //                    .arvalid
		input  wire [3:0]   cafu2ip_aximm0_arcache,            //                    .arcache
		input  wire [1:0]   cafu2ip_aximm0_arlock,             //                    .arlock
		input  wire [3:0]   cafu2ip_aximm0_arregion,           //                    .arregion
		output wire         ip2cafu_aximm0_arready,            //                    .arready
		input  wire [11:0]  cafu2ip_aximm1_arid,               // axi2ccip_rdaddr_ch1.arid
		input  wire [63:0]  cafu2ip_aximm1_araddr,             //                    .araddr
		input  wire [9:0]   cafu2ip_aximm1_arlen,              //                    .arlen
		input  wire [2:0]   cafu2ip_aximm1_arsize,             //                    .arsize
		input  wire [1:0]   cafu2ip_aximm1_arburst,            //                    .arburst
		input  wire [2:0]   cafu2ip_aximm1_arprot,             //                    .arprot
		input  wire [3:0]   cafu2ip_aximm1_arqos,              //                    .arqos
		input  wire [5:0]   cafu2ip_aximm1_aruser,             //                    .aruser
		input  wire         cafu2ip_aximm1_arvalid,            //                    .arvalid
		input  wire [3:0]   cafu2ip_aximm1_arcache,            //                    .arcache
		input  wire [1:0]   cafu2ip_aximm1_arlock,             //                    .arlock
		input  wire [3:0]   cafu2ip_aximm1_arregion,           //                    .arregion
		output wire         ip2cafu_aximm1_arready,            //                    .arready
		output wire [11:0]  ip2cafu_aximm0_rid,                //  axi2ccip_rdrsp_ch0.rid
		output wire [511:0] ip2cafu_aximm0_rdata,              //                    .rdata
		output wire [1:0]   ip2cafu_aximm0_rresp,              //                    .rresp
		output wire         ip2cafu_aximm0_rlast,              //                    .rlast
		output wire [1:0]   ip2cafu_aximm0_ruser,              //                    .ruser
		output wire         ip2cafu_aximm0_rvalid,             //                    .rvalid
		input  wire         cafu2ip_aximm0_rready,             //                    .rready
		output wire [11:0]  ip2cafu_aximm1_rid,                //  axi2ccip_rdrsp_ch1.rid
		output wire [511:0] ip2cafu_aximm1_rdata,              //                    .rdata
		output wire [1:0]   ip2cafu_aximm1_rresp,              //                    .rresp
		output wire         ip2cafu_aximm1_rlast,              //                    .rlast
		output wire [1:0]   ip2cafu_aximm1_ruser,              //                    .ruser
		output wire         ip2cafu_aximm1_rvalid,             //                    .rvalid
		input  wire         cafu2ip_aximm1_rready,             //                    .rready
		input  wire [95:0]  cafu2ip_csr0_cfg_if,               //       cafu_csr0_cfg.cafu2ip_cfg_if
		output wire [5:0]   ip2cafu_csr0_cfg_if,               //                    .ip2cafu_devsec
		output wire         ip2csr_avmm_clk,                   //             afu_csr.clk
		output wire         ip2csr_avmm_rstn,                  //                    .rst_n
		input  wire         csr2ip_avmm_waitrequest,           //                    .waitrequest
		input  wire [63:0]  csr2ip_avmm_readdata,              //                    .readdata
		input  wire         csr2ip_avmm_readdatavalid,         //                    .readdatavalid
		output wire [63:0]  ip2csr_avmm_writedata,             //                    .writedata
		output wire         ip2csr_avmm_poison,                //                    .poison
		output wire [21:0]  ip2csr_avmm_address,               //                    .address
		output wire         ip2csr_avmm_write,                 //                    .write
		output wire         ip2csr_avmm_read,                  //                    .read
		output wire [7:0]   ip2csr_avmm_byteenable,            //                    .byteenable
		output wire         ip2cafu_avmm_clk,                  //            cafu_csr.clk
		output wire         ip2cafu_avmm_rstn,                 //                    .rstn
		input  wire         cafu2ip_avmm_waitrequest,          //                    .waitrequest
		input  wire [63:0]  cafu2ip_avmm_readdata,             //                    .readdata
		input  wire         cafu2ip_avmm_readdatavalid,        //                    .readdatavalid
		output wire         ip2cafu_avmm_burstcount,           //                    .burstcount
		output wire [63:0]  ip2cafu_avmm_writedata,            //                    .writedata
		output wire         ip2cafu_avmm_poison,               //                    .poison
		output wire [21:0]  ip2cafu_avmm_address,              //                    .address
		output wire         ip2cafu_avmm_write,                //                    .write
		output wire         ip2cafu_avmm_read,                 //                    .read
		output wire [7:0]   ip2cafu_avmm_byteenable,           //                    .byteenable
		output wire [31:0]  ccv_afu_conf_base_addr_high,       //             ccv_afu.base_addr_high
		output wire         ccv_afu_conf_base_addr_high_valid, //                    .base_addr_high_valid
		output wire [27:0]  ccv_afu_conf_base_addr_low,        //                    .base_addr_low
		output wire         ccv_afu_conf_base_addr_low_valid,  //                    .base_addr_low_valid
		output wire [2:0]   pf0_max_payload_size,              //            ext_comp.pfo_mpss
		output wire [2:0]   pf0_max_read_request_size,         //                    .pf0_mrrs
		output wire         pf0_bus_master_en,                 //                    .pfo_bus_master_en
		output wire         pf0_memory_access_en,              //                    .pfo_mem_access_en
		output wire [2:0]   pf1_max_payload_size,              //                    .pf1_mpss
		output wire [2:0]   pf1_max_read_request_size,         //                    .pf1_mrrs
		output wire         pf1_bus_master_en,                 //                    .pf1_bus_master_en
		output wire         pf1_memory_access_en,              //                    .pf1_mem_access_en
		output wire         pf0_msix_enable,                   //  pf0_msix_interface.msix_enable
		output wire         pf0_msix_fn_mask,                  //                    .msix_fn_mask
		output wire         pf1_msix_enable,                   //  pf1_msix_interface.msix_enable
		output wire         pf1_msix_fn_mask,                  //                    .msix_fn_mask
		input  wire [63:0]  dev_serial_num,                    //                    .dev_serial_num
		input  wire         dev_serial_num_valid,              //                    .dev_serial_num_valid
		output wire         ip2uio_tx_ready,                   //          usr_tx_st0.ready
		input  wire         uio2ip_tx_st0_dvalid,              //                    .dvalid
		input  wire         uio2ip_tx_st0_sop,                 //                    .sop
		input  wire         uio2ip_tx_st0_eop,                 //                    .eop
		input  wire [255:0] uio2ip_tx_st0_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st0_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st0_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st0_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st0_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st0_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st0_prefix_parity,       //                    .prefix_parity
		input  wire         uio2ip_tx_st0_pvalid,              //                    .pvalid
		input  wire [2:0]   uio2ip_tx_st0_empty,               //                    .empty
		input  wire         uio2ip_tx_st0_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st1_dvalid,              //          usr_tx_st1.dvalid
		input  wire         uio2ip_tx_st1_sop,                 //                    .sop
		input  wire         uio2ip_tx_st1_eop,                 //                    .eop
		input  wire [255:0] uio2ip_tx_st1_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st1_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st1_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st1_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st1_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st1_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st1_prefix_parity,       //                    .prefix_parity
		input  wire         uio2ip_tx_st1_pvalid,              //                    .pvalid
		input  wire [2:0]   uio2ip_tx_st1_empty,               //                    .empty
		input  wire         uio2ip_tx_st1_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st2_dvalid,              //          usr_tx_st2.dvalid
		input  wire         uio2ip_tx_st2_sop,                 //                    .sop
		input  wire         uio2ip_tx_st2_eop,                 //                    .eop
		input  wire [255:0] uio2ip_tx_st2_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st2_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st2_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st2_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st2_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st2_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st2_prefix_parity,       //                    .prefix_parity
		input  wire         uio2ip_tx_st2_pvalid,              //                    .pvalid
		input  wire [2:0]   uio2ip_tx_st2_empty,               //                    .empty
		input  wire         uio2ip_tx_st2_misc_parity,         //                    .misc_parity
		input  wire         uio2ip_tx_st3_dvalid,              //          usr_tx_st3.dvalid
		input  wire         uio2ip_tx_st3_sop,                 //                    .sop
		input  wire         uio2ip_tx_st3_eop,                 //                    .eop
		input  wire [255:0] uio2ip_tx_st3_data,                //                    .data
		input  wire [7:0]   uio2ip_tx_st3_data_parity,         //                    .data_parity
		input  wire [127:0] uio2ip_tx_st3_hdr,                 //                    .hdr
		input  wire [3:0]   uio2ip_tx_st3_hdr_parity,          //                    .hdr_parity
		input  wire         uio2ip_tx_st3_hvalid,              //                    .hvalid
		input  wire [31:0]  uio2ip_tx_st3_prefix,              //                    .prefix
		input  wire [0:0]   uio2ip_tx_st3_prefix_parity,       //                    .prefix_parity
		input  wire         uio2ip_tx_st3_pvalid,              //                    .pvalid
		input  wire [2:0]   uio2ip_tx_st3_empty,               //                    .empty
		input  wire         uio2ip_tx_st3_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_tx_st_Hcrdt_update,         //           usr_tx_st.Hcrdt_update
		output wire [5:0]   ip2uio_tx_st_Hcrdt_update_cnt,     //                    .Hcrdt_update_cnt
		output wire [2:0]   ip2uio_tx_st_Hcrdt_init,           //                    .Hcrdt_init
		input  wire [2:0]   uio2ip_tx_st_Hcrdt_init_ack,       //                    .Hcrdt_init_ack
		output wire [2:0]   ip2uio_tx_st_Dcrdt_update,         //                    .Dcrdt_update
		output wire [11:0]  ip2uio_tx_st_Dcrdt_update_cnt,     //                    .Dcrdt_update_cnt
		output wire [2:0]   ip2uio_tx_st_Dcrdt_init,           //                    .Dcrdt_init
		input  wire [2:0]   uio2ip_tx_st_Dcrdt_init_ack,       //                    .Dcrdt_init_ack
		output wire         ip2uio_rx_st0_dvalid,              //         usr_rx_st_0.dvalid
		output wire         ip2uio_rx_st0_sop,                 //                    .sop
		output wire         ip2uio_rx_st0_eop,                 //                    .eop
		output wire         ip2uio_rx_st0_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st0_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st0_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st0_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st0_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st0_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st0_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st0_prefix_parity,       //                    .prefix_parity
		output wire         ip2uio_rx_st0_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st0_bar,                 //                    .bar
		output wire [2:0]   ip2uio_rx_st0_pfnum,               //                    .pfnum
		output wire         ip2uio_rx_st0_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st0_empty,               //                    .empty
		output wire         ip2uio_rx_st1_dvalid,              //         usr_rx_st_1.dvalid
		output wire         ip2uio_rx_st1_sop,                 //                    .sop
		output wire         ip2uio_rx_st1_eop,                 //                    .eop
		output wire         ip2uio_rx_st1_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st1_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st1_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st1_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st1_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st1_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st1_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st1_prefix_parity,       //                    .prefix_parity
		output wire         ip2uio_rx_st1_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st1_bar,                 //                    .bar
		output wire [2:0]   ip2uio_rx_st1_pfnum,               //                    .pfnum
		output wire         ip2uio_rx_st1_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st1_empty,               //                    .empty
		output wire         ip2uio_rx_st2_dvalid,              //         usr_rx_st_2.dvalid
		output wire         ip2uio_rx_st2_sop,                 //                    .sop
		output wire         ip2uio_rx_st2_eop,                 //                    .eop
		output wire         ip2uio_rx_st2_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st2_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st2_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st2_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st2_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st2_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st2_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st2_prefix_parity,       //                    .prefix_parity
		output wire         ip2uio_rx_st2_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st2_bar,                 //                    .bar
		output wire [2:0]   ip2uio_rx_st2_pfnum,               //                    .pfnum
		output wire         ip2uio_rx_st2_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st2_empty,               //                    .empty
		output wire         ip2uio_rx_st3_dvalid,              //         usr_rx_st_3.dvalid
		output wire         ip2uio_rx_st3_sop,                 //                    .sop
		output wire         ip2uio_rx_st3_eop,                 //                    .eop
		output wire         ip2uio_rx_st3_passthrough,         //                    .passthrough
		output wire [255:0] ip2uio_rx_st3_data,                //                    .data
		output wire [7:0]   ip2uio_rx_st3_data_parity,         //                    .data_parity
		output wire [127:0] ip2uio_rx_st3_hdr,                 //                    .hdr
		output wire [3:0]   ip2uio_rx_st3_hdr_parity,          //                    .hdr_parity
		output wire         ip2uio_rx_st3_hvalid,              //                    .hvalid
		output wire [31:0]  ip2uio_rx_st3_prefix,              //                    .prefix
		output wire [0:0]   ip2uio_rx_st3_prefix_parity,       //                    .prefix_parity
		output wire         ip2uio_rx_st3_pvalid,              //                    .pvalid
		output wire [2:0]   ip2uio_rx_st3_bar,                 //                    .bar
		output wire [2:0]   ip2uio_rx_st3_pfnum,               //                    .pfnum
		output wire         ip2uio_rx_st3_misc_parity,         //                    .misc_parity
		output wire [2:0]   ip2uio_rx_st3_empty,               //                    .empty
		input  wire [2:0]   uio2ip_rx_st_Hcrdt_update,         //           usr_rx_st.Hcrdt_update
		input  wire [5:0]   uio2ip_rx_st_Hcrdt_update_cnt,     //                    .Hcrdt_update_cnt
		input  wire [2:0]   uio2ip_rx_st_Hcrdt_init,           //                    .Hcrdt_init
		output wire [2:0]   ip2uio_rx_st_Hcrdt_init_ack,       //                    .Hcrdt_init_ack
		input  wire [2:0]   uio2ip_rx_st_Dcrdt_update,         //                    .Dcrdt_update
		input  wire [11:0]  uio2ip_rx_st_Dcrdt_update_cnt,     //                    .Dcrdt_update_cnt
		input  wire [2:0]   uio2ip_rx_st_Dcrdt_init,           //                    .Dcrdt_init
		output wire [2:0]   ip2uio_rx_st_Dcrdt_init_ack,       //                    .Dcrdt_init_ack
		output wire [7:0]   ip2uio_bus_number,                 //                 uio.usr_bus_number
		output wire [4:0]   ip2uio_device_number,              //                    .usr_device_number
		output wire         ip2cafu_axistd0_tvalid,            //     ip2cafu_axistd0.td0_tvalid
		output wire [71:0]  ip2cafu_axistd0_tdata,             //                    .td0_tdata
		output wire [8:0]   ip2cafu_axistd0_tstrb,             //                    .td0_tstrb
		output wire [2:0]   ip2cafu_axistd0_tdest,             //                    .td0_tdest
		output wire [8:0]   ip2cafu_axistd0_tkeep,             //                    .td0_tkeep
		output wire         ip2cafu_axistd0_tlast,             //                    .td0_tlast
		output wire [7:0]   ip2cafu_axistd0_tid,               //                    .td0_tid
		output wire [7:0]   ip2cafu_axistd0_tuser,             //                    .td0_tuser
		input  wire         cafu2ip_axistd0_tready,            //                    .td0_tready
		output wire         ip2cafu_axisth0_tvalid,            //                    .th0_tvalid
		output wire [71:0]  ip2cafu_axisth0_tdata,             //                    .th0_tdata
		output wire [8:0]   ip2cafu_axisth0_tstrb,             //                    .th0_tstrb
		output wire [2:0]   ip2cafu_axisth0_tdest,             //                    .th0_tdest
		output wire [8:0]   ip2cafu_axisth0_tkeep,             //                    .th0_tkeep
		output wire         ip2cafu_axisth0_tlast,             //                    .th0_tlast
		output wire [7:0]   ip2cafu_axisth0_tid,               //                    .th0_tid
		output wire [7:0]   ip2cafu_axisth0_tuser,             //                    .th0_tuser
		input  wire         cafu2ip_axisth0_tready,            //                    .th0_tready
		output wire         ip2cafu_axistd1_tvalid,            //     ip2cafu_axistd1.td1_tvalid
		output wire [71:0]  ip2cafu_axistd1_tdata,             //                    .td1_tdata
		output wire [8:0]   ip2cafu_axistd1_tstrb,             //                    .td1_tstrb
		output wire [2:0]   ip2cafu_axistd1_tdest,             //                    .td1_tdest
		output wire [8:0]   ip2cafu_axistd1_tkeep,             //                    .td1_tkeep
		output wire         ip2cafu_axistd1_tlast,             //                    .td1_tlast
		output wire [7:0]   ip2cafu_axistd1_tid,               //                    .td1_tid
		output wire [7:0]   ip2cafu_axistd1_tuser,             //                    .td1_tuser
		input  wire         cafu2ip_axistd1_tready,            //                    .td1_tready
		output wire         ip2cafu_axisth1_tvalid,            //                    .th1_tvalid
		output wire [71:0]  ip2cafu_axisth1_tdata,             //                    .th1_tdata
		output wire [8:0]   ip2cafu_axisth1_tstrb,             //                    .th1_tstrb
		output wire [2:0]   ip2cafu_axisth1_tdest,             //                    .th1_tdest
		output wire [8:0]   ip2cafu_axisth1_tkeep,             //                    .th1_tkeep
		output wire         ip2cafu_axisth1_tlast,             //                    .th1_tlast
		output wire [7:0]   ip2cafu_axisth1_tid,               //                    .th1_tid
		output wire [7:0]   ip2cafu_axisth1_tuser,             //                    .th1_tuser
		input  wire         cafu2ip_axisth1_tready,            //                    .th1_tready
		input  wire         usr2ip_cxlreset_initiate,          //       cxl_reset_inf.cxlreset_initiate
		output wire         ip2usr_cxlreset_req,               //                    .cxlreset_req
		input  wire         usr2ip_cxlreset_ack,               //                    .cxlreset_ack
		output wire         ip2usr_cxlreset_error,             //                    .cxlreset_error
		output wire         ip2usr_cxlreset_complete,          //                    .cxlreset_complete
		input  wire         usr2ip_app_err_valid,              //         usr_err_inf.err_valid
		input  wire [31:0]  usr2ip_app_err_hdr,                //                    .err_hdr
		input  wire [13:0]  usr2ip_app_err_info,               //                    .err_info
		input  wire [2:0]   usr2ip_app_err_func_num,           //                    .err_fn_num
		output wire         ip2usr_app_err_ready,              //                    .err_rdy
		output wire         ip2usr_aermsg_correctable_valid,   //                    .aermsg_correctable_valid
		output wire         ip2usr_aermsg_uncorrectable_valid, //                    .aermsg_uncorrectable_valid
		output wire         ip2usr_aermsg_res,                 //                    .aermsg_res
		output wire         ip2usr_aermsg_bts,                 //                    .aermsg_bts
		output wire         ip2usr_aermsg_bds,                 //                    .aermsg_bds
		output wire         ip2usr_aermsg_rrs,                 //                    .aermsg_rrs
		output wire         ip2usr_aermsg_rtts,                //                    .aermsg_rtts
		output wire         ip2usr_aermsg_anes,                //                    .aermsg_anes
		output wire         ip2usr_aermsg_cies,                //                    .aermsg_cies
		output wire         ip2usr_aermsg_hlos,                //                    .aermsg_hlos
		output wire [1:0]   ip2usr_aermsg_fmt,                 //                    .aermsg_fmt
		output wire [4:0]   ip2usr_aermsg_type,                //                    .aermsg_type
		output wire [2:0]   ip2usr_aermsg_tc,                  //                    .aermsg_tc
		output wire         ip2usr_aermsg_ido,                 //                    .aermsg_ido
		output wire         ip2usr_aermsg_th,                  //                    .aermsg_th
		output wire         ip2usr_aermsg_td,                  //                    .aermsg_td
		output wire         ip2usr_aermsg_ep,                  //                    .aermsg_ep
		output wire         ip2usr_aermsg_ro,                  //                    .aermsg_ro
		output wire         ip2usr_aermsg_ns,                  //                    .aermsg_ns
		output wire [1:0]   ip2usr_aermsg_at,                  //                    .aermsg_at
		output wire [9:0]   ip2usr_aermsg_length,              //                    .aermsg_length
		output wire [95:0]  ip2usr_aermsg_header,              //                    .aermsg_header
		output wire         ip2usr_aermsg_und,                 //                    .aermsg_und
		output wire         ip2usr_aermsg_anf,                 //                    .aermsg_anf
		output wire         ip2usr_aermsg_dlpes,               //                    .aermsg_dlpes
		output wire         ip2usr_aermsg_sdes,                //                    .aermsg_sdes
		output wire [4:0]   ip2usr_aermsg_fep,                 //                    .aermsg_fep
		output wire         ip2usr_aermsg_pts,                 //                    .aermsg_pts
		output wire         ip2usr_aermsg_fcpes,               //                    .aermsg_fcpes
		output wire         ip2usr_aermsg_cts,                 //                    .aermsg_cts
		output wire         ip2usr_aermsg_cas,                 //                    .aermsg_cas
		output wire         ip2usr_aermsg_ucs,                 //                    .aermsg_ucs
		output wire         ip2usr_aermsg_ros,                 //                    .aermsg_ros
		output wire         ip2usr_aermsg_mts,                 //                    .aermsg_mts
		output wire         ip2usr_aermsg_uies,                //                    .aermsg_uies
		output wire         ip2usr_aermsg_mbts,                //                    .aermsg_mbts
		output wire         ip2usr_aermsg_aebs,                //                    .aermsg_aebs
		output wire         ip2usr_aermsg_tpbes,               //                    .aermsg_tpbes
		output wire         ip2usr_aermsg_ees,                 //                    .aermsg_ees
		output wire         ip2usr_aermsg_ures,                //                    .aermsg_ures
		output wire         ip2usr_aermsg_avs,                 //                    .aermsg_avs
		output wire         ip2usr_serr_out,                   //                    .serr_out
		output wire         ip2usr_debug_waitrequest,          //                    .dbg_waitreq
		output wire [31:0]  ip2usr_debug_readdata,             //                    .dbg_rddata
		output wire         ip2usr_debug_readdatavalid,        //                    .dbg_drvalid
		input  wire [31:0]  usr2ip_debug_writedata,            //                    .dbg_wrad
		input  wire [31:0]  usr2ip_debug_address,              //                    .dbg_add
		input  wire         usr2ip_debug_write,                //                    .dbg_wrt
		input  wire         usr2ip_debug_read,                 //                    .dbg_read
		input  wire [3:0]   usr2ip_debug_byteenable,           //                    .dbg_byten
		output wire         ip2hdm_aximm0_awvalid,             //       ip2hdm_aximm0.awvalid
		output wire [7:0]   ip2hdm_aximm0_awid,                //                    .awid
		output wire [51:0]  ip2hdm_aximm0_awaddr,              //                    .awaddr
		output wire [9:0]   ip2hdm_aximm0_awlen,               //                    .awlen
		output wire [3:0]   ip2hdm_aximm0_awregion,            //                    .awregion
		output wire         ip2hdm_aximm0_awuser,              //                    .awuser
		output wire [2:0]   ip2hdm_aximm0_awsize,              //                    .awsize
		output wire [1:0]   ip2hdm_aximm0_awburst,             //                    .awburst
		output wire [2:0]   ip2hdm_aximm0_awprot,              //                    .awport
		output wire [3:0]   ip2hdm_aximm0_awqos,               //                    .awqos
		output wire [3:0]   ip2hdm_aximm0_awcache,             //                    .awcache
		output wire [1:0]   ip2hdm_aximm0_awlock,              //                    .awlock
		input  wire         hdm2ip_aximm0_awready,             //                    .awready
		output wire         ip2hdm_aximm0_wvalid,              //                    .wvalid
		output wire [511:0] ip2hdm_aximm0_wdata,               //                    .wdata
		output wire [63:0]  ip2hdm_aximm0_wstrb,               //                    .wstrb
		output wire         ip2hdm_aximm0_wlast,               //                    .wlast
		output wire         ip2hdm_aximm0_wuser,               //                    .wuser
		input  wire         hdm2ip_aximm0_wready,              //                    .wready
		input  wire         hdm2ip_aximm0_bvalid,              //                    .bvlaid
		input  wire [7:0]   hdm2ip_aximm0_bid,                 //                    .bid
		input  wire         hdm2ip_aximm0_buser,               //                    .buser
		input  wire [1:0]   hdm2ip_aximm0_bresp,               //                    .brsp
		output wire         ip2hdm_aximm0_bready,              //                    .bready
		output wire         ip2hdm_aximm0_arvalid,             //                    .arvalid
		output wire [7:0]   ip2hdm_aximm0_arid,                //                    .arid
		output wire [51:0]  ip2hdm_aximm0_araddr,              //                    .araddr
		output wire [9:0]   ip2hdm_aximm0_arlen,               //                    .arlen
		output wire [3:0]   ip2hdm_aximm0_arregion,            //                    .arregion
		output wire         ip2hdm_aximm0_aruser,              //                    .aruser
		output wire [2:0]   ip2hdm_aximm0_arsize,              //                    .arsize
		output wire [1:0]   ip2hdm_aximm0_arburst,             //                    .arburst
		output wire [2:0]   ip2hdm_aximm0_arprot,              //                    .arport
		output wire [3:0]   ip2hdm_aximm0_arqos,               //                    .arqos
		output wire [3:0]   ip2hdm_aximm0_arcache,             //                    .arcache
		output wire [1:0]   ip2hdm_aximm0_arlock,              //                    .arlock
		input  wire         hdm2ip_aximm0_arready,             //                    .arready
		input  wire         hdm2ip_aximm0_rvalid,              //                    .rvalid
		input  wire         hdm2ip_aximm0_rlast,               //                    .rlast
		input  wire [7:0]   hdm2ip_aximm0_rid,                 //                    .rid
		input  wire [511:0] hdm2ip_aximm0_rdata,               //                    .rdata
		input  wire         hdm2ip_aximm0_ruser,               //                    .ruser
		input  wire [1:0]   hdm2ip_aximm0_rresp,               //                    .rresp
		output wire         ip2hdm_aximm0_rready,              //                    .rready
		output wire         ip2hdm_aximm1_awvalid,             //       ip2hdm_aximm1.awvalid
		output wire [7:0]   ip2hdm_aximm1_awid,                //                    .awid
		output wire [51:0]  ip2hdm_aximm1_awaddr,              //                    .awaddr
		output wire [9:0]   ip2hdm_aximm1_awlen,               //                    .awlen
		output wire [3:0]   ip2hdm_aximm1_awregion,            //                    .awregion
		output wire         ip2hdm_aximm1_awuser,              //                    .awuser
		output wire [2:0]   ip2hdm_aximm1_awsize,              //                    .awsize
		output wire [1:0]   ip2hdm_aximm1_awburst,             //                    .awburst
		output wire [2:0]   ip2hdm_aximm1_awprot,              //                    .awport
		output wire [3:0]   ip2hdm_aximm1_awqos,               //                    .awqos
		output wire [3:0]   ip2hdm_aximm1_awcache,             //                    .awcache
		output wire [1:0]   ip2hdm_aximm1_awlock,              //                    .awlock
		input  wire         hdm2ip_aximm1_awready,             //                    .awready
		output wire         ip2hdm_aximm1_wvalid,              //                    .wvalid
		output wire [511:0] ip2hdm_aximm1_wdata,               //                    .wdata
		output wire [63:0]  ip2hdm_aximm1_wstrb,               //                    .wstrb
		output wire         ip2hdm_aximm1_wlast,               //                    .wlast
		output wire         ip2hdm_aximm1_wuser,               //                    .wuser
		input  wire         hdm2ip_aximm1_wready,              //                    .wready
		input  wire         hdm2ip_aximm1_bvalid,              //                    .bvlaid
		input  wire [7:0]   hdm2ip_aximm1_bid,                 //                    .bid
		input  wire         hdm2ip_aximm1_buser,               //                    .buser
		input  wire [1:0]   hdm2ip_aximm1_bresp,               //                    .brsp
		output wire         ip2hdm_aximm1_bready,              //                    .bready
		output wire         ip2hdm_aximm1_arvalid,             //                    .arvalid
		output wire [7:0]   ip2hdm_aximm1_arid,                //                    .arid
		output wire [51:0]  ip2hdm_aximm1_araddr,              //                    .araddr
		output wire [9:0]   ip2hdm_aximm1_arlen,               //                    .arlen
		output wire [3:0]   ip2hdm_aximm1_arregion,            //                    .arregion
		output wire         ip2hdm_aximm1_aruser,              //                    .aruser
		output wire [2:0]   ip2hdm_aximm1_arsize,              //                    .arsize
		output wire [1:0]   ip2hdm_aximm1_arburst,             //                    .arburst
		output wire [2:0]   ip2hdm_aximm1_arprot,              //                    .arport
		output wire [3:0]   ip2hdm_aximm1_arqos,               //                    .arqos
		output wire [3:0]   ip2hdm_aximm1_arcache,             //                    .arcache
		output wire [1:0]   ip2hdm_aximm1_arlock,              //                    .arlock
		input  wire         hdm2ip_aximm1_arready,             //                    .arready
		input  wire         hdm2ip_aximm1_rvalid,              //                    .rvalid
		input  wire         hdm2ip_aximm1_rlast,               //                    .rlast
		input  wire [7:0]   hdm2ip_aximm1_rid,                 //                    .rid
		input  wire [511:0] hdm2ip_aximm1_rdata,               //                    .rdata
		input  wire         hdm2ip_aximm1_ruser,               //                    .ruser
		input  wire [1:0]   hdm2ip_aximm1_rresp,               //                    .rresp
		output wire         ip2hdm_aximm1_rready,              //                    .rready
		output wire         ip2usr_gpf_ph2_req_o,              //             gpf_ph2.gpf_req
		input  wire         usr2ip_gpf_ph2_ack_i,              //                    .gpf_ack
		input  wire [1:0]   usr2ip_cache_evict_policy,         //         cache_evict.cache_evict_policy
		output wire         phy_sys_ial_0__pipe_Reset_l,       //     pipe_mode_rtile.if_phy_sys_ial_0__pipe_Reset_l
		output wire         phy_sys_ial_1__pipe_Reset_l,       //                    .if_phy_sys_ial_1__pipe_Reset_l
		output wire         phy_sys_ial_2__pipe_Reset_l,       //                    .if_phy_sys_ial_2__pipe_Reset_l
		output wire         phy_sys_ial_3__pipe_Reset_l,       //                    .if_phy_sys_ial_3__pipe_Reset_l
		output wire         phy_sys_ial_4__pipe_Reset_l,       //                    .if_phy_sys_ial_4__pipe_Reset_l
		output wire         phy_sys_ial_5__pipe_Reset_l,       //                    .if_phy_sys_ial_5__pipe_Reset_l
		output wire         phy_sys_ial_6__pipe_Reset_l,       //                    .if_phy_sys_ial_6__pipe_Reset_l
		output wire         phy_sys_ial_7__pipe_Reset_l,       //                    .if_phy_sys_ial_7__pipe_Reset_l
		output wire         phy_sys_ial_8__pipe_Reset_l,       //                    .if_phy_sys_ial_8__pipe_Reset_l
		output wire         phy_sys_ial_9__pipe_Reset_l,       //                    .if_phy_sys_ial_9__pipe_Reset_l
		output wire         phy_sys_ial_10__pipe_Reset_l,      //                    .if_phy_sys_ial_10__pipe_Reset_l
		output wire         phy_sys_ial_11__pipe_Reset_l,      //                    .if_phy_sys_ial_11__pipe_Reset_l
		output wire         phy_sys_ial_12__pipe_Reset_l,      //                    .if_phy_sys_ial_12__pipe_Reset_l
		output wire         phy_sys_ial_13__pipe_Reset_l,      //                    .if_phy_sys_ial_13__pipe_Reset_l
		output wire         phy_sys_ial_14__pipe_Reset_l,      //                    .if_phy_sys_ial_14__pipe_Reset_l
		output wire         phy_sys_ial_15__pipe_Reset_l,      //                    .if_phy_sys_ial_15__pipe_Reset_l
		output wire         o_phy_0_pipe_TxDataValid,          //                    .if_o_phy_0_pipe_TxDataValid
		output wire [39:0]  o_phy_0_pipe_TxData,               //                    .if_o_phy_0_pipe_TxData
		output wire         o_phy_0_pipe_TxDetRxLpbk,          //                    .if_o_phy_0_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_0_pipe_TxElecIdle,           //                    .if_o_phy_0_pipe_TxElecIdle
		output wire [3:0]   o_phy_0_pipe_PowerDown,            //                    .if_o_phy_0_pipe_PowerDown
		output wire [2:0]   o_phy_0_pipe_Rate,                 //                    .if_o_phy_0_pipe_Rate
		output wire         o_phy_0_pipe_PclkChangeAck,        //                    .if_o_phy_0_pipe_PclkChangeAck
		output wire [2:0]   o_phy_0_pipe_PCLKRate,             //                    .if_o_phy_0_pipe_PCLKRate
		output wire [1:0]   o_phy_0_pipe_Width,                //                    .if_o_phy_0_pipe_Width
		output wire         o_phy_0_pipe_PCLK,                 //                    .if_o_phy_0_pipe_PCLK
		output wire         o_phy_0_pipe_rxelecidle_disable,   //                    .if_o_phy_0_pipe_rxelecidle_disable
		output wire         o_phy_0_pipe_txcmnmode_disable,    //                    .if_o_phy_0_pipe_txcmnmode_disable
		output wire         o_phy_0_pipe_srisenable,           //                    .if_o_phy_0_pipe_srisenable
		input  wire         i_phy_0_pipe_RxClk,                //                    .if_i_phy_0_pipe_RxClk
		input  wire         i_phy_0_pipe_RxValid,              //                    .if_i_phy_0_pipe_RxValid
		input  wire [39:0]  i_phy_0_pipe_RxData,               //                    .if_i_phy_0_pipe_RxData
		input  wire         i_phy_0_pipe_RxElecIdle,           //                    .if_i_phy_0_pipe_RxElecIdle
		input  wire [2:0]   i_phy_0_pipe_RxStatus,             //                    .if_i_phy_0_pipe_RxStatus
		input  wire         i_phy_0_pipe_RxStandbyStatus,      //                    .if_i_phy_0_pipe_RxStandbyStatus
		output wire         o_phy_0_pipe_RxStandby,            //                    .if_o_phy_0_pipe_RxStandby
		output wire         o_phy_0_pipe_RxTermination,        //                    .if_o_phy_0_pipe_RxTermination
		output wire [1:0]   o_phy_0_pipe_RxWidth,              //                    .if_o_phy_0_pipe_RxWidth
		input  wire         i_phy_0_pipe_PhyStatus,            //                    .if_i_phy_0_pipe_PhyStatus
		input  wire         i_phy_0_pipe_PclkChangeOk,         //                    .if_i_phy_0_pipe_PclkChangeOk
		output wire [7:0]   o_phy_0_pipe_M2P_MessageBus,       //                    .if_o_phy_0_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_0_pipe_P2M_MessageBus,       //                    .if_i_phy_0_pipe_P2M_MessageBus
		output wire         o_phy_1_pipe_TxDataValid,          //                    .if_o_phy_1_pipe_TxDataValid
		output wire [39:0]  o_phy_1_pipe_TxData,               //                    .if_o_phy_1_pipe_TxData
		output wire         o_phy_1_pipe_TxDetRxLpbk,          //                    .if_o_phy_1_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_1_pipe_TxElecIdle,           //                    .if_o_phy_1_pipe_TxElecIdle
		output wire [3:0]   o_phy_1_pipe_PowerDown,            //                    .if_o_phy_1_pipe_PowerDown
		output wire [2:0]   o_phy_1_pipe_Rate,                 //                    .if_o_phy_1_pipe_Rate
		output wire         o_phy_1_pipe_PclkChangeAck,        //                    .if_o_phy_1_pipe_PclkChangeAck
		output wire [2:0]   o_phy_1_pipe_PCLKRate,             //                    .if_o_phy_1_pipe_PCLKRate
		output wire [1:0]   o_phy_1_pipe_Width,                //                    .if_o_phy_1_pipe_Width
		output wire         o_phy_1_pipe_PCLK,                 //                    .if_o_phy_1_pipe_PCLK
		output wire         o_phy_1_pipe_rxelecidle_disable,   //                    .if_o_phy_1_pipe_rxelecidle_disable
		output wire         o_phy_1_pipe_txcmnmode_disable,    //                    .if_o_phy_1_pipe_txcmnmode_disable
		output wire         o_phy_1_pipe_srisenable,           //                    .if_o_phy_1_pipe_srisenable
		input  wire         i_phy_1_pipe_RxClk,                //                    .if_i_phy_1_pipe_RxClk
		input  wire         i_phy_1_pipe_RxValid,              //                    .if_i_phy_1_pipe_RxValid
		input  wire [39:0]  i_phy_1_pipe_RxData,               //                    .if_i_phy_1_pipe_RxData
		input  wire         i_phy_1_pipe_RxElecIdle,           //                    .if_i_phy_1_pipe_RxElecIdle
		input  wire [2:0]   i_phy_1_pipe_RxStatus,             //                    .if_i_phy_1_pipe_RxStatus
		input  wire         i_phy_1_pipe_RxStandbyStatus,      //                    .if_i_phy_1_pipe_RxStandbyStatus
		output wire         o_phy_1_pipe_RxStandby,            //                    .if_o_phy_1_pipe_RxStandby
		output wire         o_phy_1_pipe_RxTermination,        //                    .if_o_phy_1_pipe_RxTermination
		output wire [1:0]   o_phy_1_pipe_RxWidth,              //                    .if_o_phy_1_pipe_RxWidth
		input  wire         i_phy_1_pipe_PhyStatus,            //                    .if_i_phy_1_pipe_PhyStatus
		input  wire         i_phy_1_pipe_PclkChangeOk,         //                    .if_i_phy_1_pipe_PclkChangeOk
		output wire [7:0]   o_phy_1_pipe_M2P_MessageBus,       //                    .if_o_phy_1_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_1_pipe_P2M_MessageBus,       //                    .if_i_phy_1_pipe_P2M_MessageBus
		output wire         o_phy_2_pipe_TxDataValid,          //                    .if_o_phy_2_pipe_TxDataValid
		output wire [39:0]  o_phy_2_pipe_TxData,               //                    .if_o_phy_2_pipe_TxData
		output wire         o_phy_2_pipe_TxDetRxLpbk,          //                    .if_o_phy_2_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_2_pipe_TxElecIdle,           //                    .if_o_phy_2_pipe_TxElecIdle
		output wire [3:0]   o_phy_2_pipe_PowerDown,            //                    .if_o_phy_2_pipe_PowerDown
		output wire [2:0]   o_phy_2_pipe_Rate,                 //                    .if_o_phy_2_pipe_Rate
		output wire         o_phy_2_pipe_PclkChangeAck,        //                    .if_o_phy_2_pipe_PclkChangeAck
		output wire [2:0]   o_phy_2_pipe_PCLKRate,             //                    .if_o_phy_2_pipe_PCLKRate
		output wire [1:0]   o_phy_2_pipe_Width,                //                    .if_o_phy_2_pipe_Width
		output wire         o_phy_2_pipe_PCLK,                 //                    .if_o_phy_2_pipe_PCLK
		output wire         o_phy_2_pipe_rxelecidle_disable,   //                    .if_o_phy_2_pipe_rxelecidle_disable
		output wire         o_phy_2_pipe_txcmnmode_disable,    //                    .if_o_phy_2_pipe_txcmnmode_disable
		output wire         o_phy_2_pipe_srisenable,           //                    .if_o_phy_2_pipe_srisenable
		input  wire         i_phy_2_pipe_RxClk,                //                    .if_i_phy_2_pipe_RxClk
		input  wire         i_phy_2_pipe_RxValid,              //                    .if_i_phy_2_pipe_RxValid
		input  wire [39:0]  i_phy_2_pipe_RxData,               //                    .if_i_phy_2_pipe_RxData
		input  wire         i_phy_2_pipe_RxElecIdle,           //                    .if_i_phy_2_pipe_RxElecIdle
		input  wire [2:0]   i_phy_2_pipe_RxStatus,             //                    .if_i_phy_2_pipe_RxStatus
		input  wire         i_phy_2_pipe_RxStandbyStatus,      //                    .if_i_phy_2_pipe_RxStandbyStatus
		output wire         o_phy_2_pipe_RxStandby,            //                    .if_o_phy_2_pipe_RxStandby
		output wire         o_phy_2_pipe_RxTermination,        //                    .if_o_phy_2_pipe_RxTermination
		output wire [1:0]   o_phy_2_pipe_RxWidth,              //                    .if_o_phy_2_pipe_RxWidth
		input  wire         i_phy_2_pipe_PhyStatus,            //                    .if_i_phy_2_pipe_PhyStatus
		input  wire         i_phy_2_pipe_PclkChangeOk,         //                    .if_i_phy_2_pipe_PclkChangeOk
		output wire [7:0]   o_phy_2_pipe_M2P_MessageBus,       //                    .if_o_phy_2_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_2_pipe_P2M_MessageBus,       //                    .if_i_phy_2_pipe_P2M_MessageBus
		output wire         o_phy_3_pipe_TxDataValid,          //                    .if_o_phy_3_pipe_TxDataValid
		output wire [39:0]  o_phy_3_pipe_TxData,               //                    .if_o_phy_3_pipe_TxData
		output wire         o_phy_3_pipe_TxDetRxLpbk,          //                    .if_o_phy_3_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_3_pipe_TxElecIdle,           //                    .if_o_phy_3_pipe_TxElecIdle
		output wire [3:0]   o_phy_3_pipe_PowerDown,            //                    .if_o_phy_3_pipe_PowerDown
		output wire [2:0]   o_phy_3_pipe_Rate,                 //                    .if_o_phy_3_pipe_Rate
		output wire         o_phy_3_pipe_PclkChangeAck,        //                    .if_o_phy_3_pipe_PclkChangeAck
		output wire [2:0]   o_phy_3_pipe_PCLKRate,             //                    .if_o_phy_3_pipe_PCLKRate
		output wire [1:0]   o_phy_3_pipe_Width,                //                    .if_o_phy_3_pipe_Width
		output wire         o_phy_3_pipe_PCLK,                 //                    .if_o_phy_3_pipe_PCLK
		output wire         o_phy_3_pipe_rxelecidle_disable,   //                    .if_o_phy_3_pipe_rxelecidle_disable
		output wire         o_phy_3_pipe_txcmnmode_disable,    //                    .if_o_phy_3_pipe_txcmnmode_disable
		output wire         o_phy_3_pipe_srisenable,           //                    .if_o_phy_3_pipe_srisenable
		input  wire         i_phy_3_pipe_RxClk,                //                    .if_i_phy_3_pipe_RxClk
		input  wire         i_phy_3_pipe_RxValid,              //                    .if_i_phy_3_pipe_RxValid
		input  wire [39:0]  i_phy_3_pipe_RxData,               //                    .if_i_phy_3_pipe_RxData
		input  wire         i_phy_3_pipe_RxElecIdle,           //                    .if_i_phy_3_pipe_RxElecIdle
		input  wire [2:0]   i_phy_3_pipe_RxStatus,             //                    .if_i_phy_3_pipe_RxStatus
		input  wire         i_phy_3_pipe_RxStandbyStatus,      //                    .if_i_phy_3_pipe_RxStandbyStatus
		output wire         o_phy_3_pipe_RxStandby,            //                    .if_o_phy_3_pipe_RxStandby
		output wire         o_phy_3_pipe_RxTermination,        //                    .if_o_phy_3_pipe_RxTermination
		output wire [1:0]   o_phy_3_pipe_RxWidth,              //                    .if_o_phy_3_pipe_RxWidth
		input  wire         i_phy_3_pipe_PhyStatus,            //                    .if_i_phy_3_pipe_PhyStatus
		input  wire         i_phy_3_pipe_PclkChangeOk,         //                    .if_i_phy_3_pipe_PclkChangeOk
		output wire [7:0]   o_phy_3_pipe_M2P_MessageBus,       //                    .if_o_phy_3_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_3_pipe_P2M_MessageBus,       //                    .if_i_phy_3_pipe_P2M_MessageBus
		output wire         o_phy_4_pipe_TxDataValid,          //                    .if_o_phy_4_pipe_TxDataValid
		output wire [39:0]  o_phy_4_pipe_TxData,               //                    .if_o_phy_4_pipe_TxData
		output wire         o_phy_4_pipe_TxDetRxLpbk,          //                    .if_o_phy_4_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_4_pipe_TxElecIdle,           //                    .if_o_phy_4_pipe_TxElecIdle
		output wire [3:0]   o_phy_4_pipe_PowerDown,            //                    .if_o_phy_4_pipe_PowerDown
		output wire [2:0]   o_phy_4_pipe_Rate,                 //                    .if_o_phy_4_pipe_Rate
		output wire         o_phy_4_pipe_PclkChangeAck,        //                    .if_o_phy_4_pipe_PclkChangeAck
		output wire [2:0]   o_phy_4_pipe_PCLKRate,             //                    .if_o_phy_4_pipe_PCLKRate
		output wire [1:0]   o_phy_4_pipe_Width,                //                    .if_o_phy_4_pipe_Width
		output wire         o_phy_4_pipe_PCLK,                 //                    .if_o_phy_4_pipe_PCLK
		output wire         o_phy_4_pipe_rxelecidle_disable,   //                    .if_o_phy_4_pipe_rxelecidle_disable
		output wire         o_phy_4_pipe_txcmnmode_disable,    //                    .if_o_phy_4_pipe_txcmnmode_disable
		output wire         o_phy_4_pipe_srisenable,           //                    .if_o_phy_4_pipe_srisenable
		input  wire         i_phy_4_pipe_RxClk,                //                    .if_i_phy_4_pipe_RxClk
		input  wire         i_phy_4_pipe_RxValid,              //                    .if_i_phy_4_pipe_RxValid
		input  wire [39:0]  i_phy_4_pipe_RxData,               //                    .if_i_phy_4_pipe_RxData
		input  wire         i_phy_4_pipe_RxElecIdle,           //                    .if_i_phy_4_pipe_RxElecIdle
		input  wire [2:0]   i_phy_4_pipe_RxStatus,             //                    .if_i_phy_4_pipe_RxStatus
		input  wire         i_phy_4_pipe_RxStandbyStatus,      //                    .if_i_phy_4_pipe_RxStandbyStatus
		output wire         o_phy_4_pipe_RxStandby,            //                    .if_o_phy_4_pipe_RxStandby
		output wire         o_phy_4_pipe_RxTermination,        //                    .if_o_phy_4_pipe_RxTermination
		output wire [1:0]   o_phy_4_pipe_RxWidth,              //                    .if_o_phy_4_pipe_RxWidth
		input  wire         i_phy_4_pipe_PhyStatus,            //                    .if_i_phy_4_pipe_PhyStatus
		input  wire         i_phy_4_pipe_PclkChangeOk,         //                    .if_i_phy_4_pipe_PclkChangeOk
		output wire [7:0]   o_phy_4_pipe_M2P_MessageBus,       //                    .if_o_phy_4_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_4_pipe_P2M_MessageBus,       //                    .if_i_phy_4_pipe_P2M_MessageBus
		output wire         o_phy_5_pipe_TxDataValid,          //                    .if_o_phy_5_pipe_TxDataValid
		output wire [39:0]  o_phy_5_pipe_TxData,               //                    .if_o_phy_5_pipe_TxData
		output wire         o_phy_5_pipe_TxDetRxLpbk,          //                    .if_o_phy_5_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_5_pipe_TxElecIdle,           //                    .if_o_phy_5_pipe_TxElecIdle
		output wire [3:0]   o_phy_5_pipe_PowerDown,            //                    .if_o_phy_5_pipe_PowerDown
		output wire [2:0]   o_phy_5_pipe_Rate,                 //                    .if_o_phy_5_pipe_Rate
		output wire         o_phy_5_pipe_PclkChangeAck,        //                    .if_o_phy_5_pipe_PclkChangeAck
		output wire [2:0]   o_phy_5_pipe_PCLKRate,             //                    .if_o_phy_5_pipe_PCLKRate
		output wire [1:0]   o_phy_5_pipe_Width,                //                    .if_o_phy_5_pipe_Width
		output wire         o_phy_5_pipe_PCLK,                 //                    .if_o_phy_5_pipe_PCLK
		output wire         o_phy_5_pipe_rxelecidle_disable,   //                    .if_o_phy_5_pipe_rxelecidle_disable
		output wire         o_phy_5_pipe_txcmnmode_disable,    //                    .if_o_phy_5_pipe_txcmnmode_disable
		output wire         o_phy_5_pipe_srisenable,           //                    .if_o_phy_5_pipe_srisenable
		input  wire         i_phy_5_pipe_RxClk,                //                    .if_i_phy_5_pipe_RxClk
		input  wire         i_phy_5_pipe_RxValid,              //                    .if_i_phy_5_pipe_RxValid
		input  wire [39:0]  i_phy_5_pipe_RxData,               //                    .if_i_phy_5_pipe_RxData
		input  wire         i_phy_5_pipe_RxElecIdle,           //                    .if_i_phy_5_pipe_RxElecIdle
		input  wire [2:0]   i_phy_5_pipe_RxStatus,             //                    .if_i_phy_5_pipe_RxStatus
		input  wire         i_phy_5_pipe_RxStandbyStatus,      //                    .if_i_phy_5_pipe_RxStandbyStatus
		output wire         o_phy_5_pipe_RxStandby,            //                    .if_o_phy_5_pipe_RxStandby
		output wire         o_phy_5_pipe_RxTermination,        //                    .if_o_phy_5_pipe_RxTermination
		output wire [1:0]   o_phy_5_pipe_RxWidth,              //                    .if_o_phy_5_pipe_RxWidth
		input  wire         i_phy_5_pipe_PhyStatus,            //                    .if_i_phy_5_pipe_PhyStatus
		input  wire         i_phy_5_pipe_PclkChangeOk,         //                    .if_i_phy_5_pipe_PclkChangeOk
		output wire [7:0]   o_phy_5_pipe_M2P_MessageBus,       //                    .if_o_phy_5_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_5_pipe_P2M_MessageBus,       //                    .if_i_phy_5_pipe_P2M_MessageBus
		output wire         o_phy_6_pipe_TxDataValid,          //                    .if_o_phy_6_pipe_TxDataValid
		output wire [39:0]  o_phy_6_pipe_TxData,               //                    .if_o_phy_6_pipe_TxData
		output wire         o_phy_6_pipe_TxDetRxLpbk,          //                    .if_o_phy_6_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_6_pipe_TxElecIdle,           //                    .if_o_phy_6_pipe_TxElecIdle
		output wire [3:0]   o_phy_6_pipe_PowerDown,            //                    .if_o_phy_6_pipe_PowerDown
		output wire [2:0]   o_phy_6_pipe_Rate,                 //                    .if_o_phy_6_pipe_Rate
		output wire         o_phy_6_pipe_PclkChangeAck,        //                    .if_o_phy_6_pipe_PclkChangeAck
		output wire [2:0]   o_phy_6_pipe_PCLKRate,             //                    .if_o_phy_6_pipe_PCLKRate
		output wire [1:0]   o_phy_6_pipe_Width,                //                    .if_o_phy_6_pipe_Width
		output wire         o_phy_6_pipe_PCLK,                 //                    .if_o_phy_6_pipe_PCLK
		output wire         o_phy_6_pipe_rxelecidle_disable,   //                    .if_o_phy_6_pipe_rxelecidle_disable
		output wire         o_phy_6_pipe_txcmnmode_disable,    //                    .if_o_phy_6_pipe_txcmnmode_disable
		output wire         o_phy_6_pipe_srisenable,           //                    .if_o_phy_6_pipe_srisenable
		input  wire         i_phy_6_pipe_RxClk,                //                    .if_i_phy_6_pipe_RxClk
		input  wire         i_phy_6_pipe_RxValid,              //                    .if_i_phy_6_pipe_RxValid
		input  wire [39:0]  i_phy_6_pipe_RxData,               //                    .if_i_phy_6_pipe_RxData
		input  wire         i_phy_6_pipe_RxElecIdle,           //                    .if_i_phy_6_pipe_RxElecIdle
		input  wire [2:0]   i_phy_6_pipe_RxStatus,             //                    .if_i_phy_6_pipe_RxStatus
		input  wire         i_phy_6_pipe_RxStandbyStatus,      //                    .if_i_phy_6_pipe_RxStandbyStatus
		output wire         o_phy_6_pipe_RxStandby,            //                    .if_o_phy_6_pipe_RxStandby
		output wire         o_phy_6_pipe_RxTermination,        //                    .if_o_phy_6_pipe_RxTermination
		output wire [1:0]   o_phy_6_pipe_RxWidth,              //                    .if_o_phy_6_pipe_RxWidth
		input  wire         i_phy_6_pipe_PhyStatus,            //                    .if_i_phy_6_pipe_PhyStatus
		input  wire         i_phy_6_pipe_PclkChangeOk,         //                    .if_i_phy_6_pipe_PclkChangeOk
		output wire [7:0]   o_phy_6_pipe_M2P_MessageBus,       //                    .if_o_phy_6_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_6_pipe_P2M_MessageBus,       //                    .if_i_phy_6_pipe_P2M_MessageBus
		output wire         o_phy_7_pipe_TxDataValid,          //                    .if_o_phy_7_pipe_TxDataValid
		output wire [39:0]  o_phy_7_pipe_TxData,               //                    .if_o_phy_7_pipe_TxData
		output wire         o_phy_7_pipe_TxDetRxLpbk,          //                    .if_o_phy_7_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_7_pipe_TxElecIdle,           //                    .if_o_phy_7_pipe_TxElecIdle
		output wire [3:0]   o_phy_7_pipe_PowerDown,            //                    .if_o_phy_7_pipe_PowerDown
		output wire [2:0]   o_phy_7_pipe_Rate,                 //                    .if_o_phy_7_pipe_Rate
		output wire         o_phy_7_pipe_PclkChangeAck,        //                    .if_o_phy_7_pipe_PclkChangeAck
		output wire [2:0]   o_phy_7_pipe_PCLKRate,             //                    .if_o_phy_7_pipe_PCLKRate
		output wire [1:0]   o_phy_7_pipe_Width,                //                    .if_o_phy_7_pipe_Width
		output wire         o_phy_7_pipe_PCLK,                 //                    .if_o_phy_7_pipe_PCLK
		output wire         o_phy_7_pipe_rxelecidle_disable,   //                    .if_o_phy_7_pipe_rxelecidle_disable
		output wire         o_phy_7_pipe_txcmnmode_disable,    //                    .if_o_phy_7_pipe_txcmnmode_disable
		output wire         o_phy_7_pipe_srisenable,           //                    .if_o_phy_7_pipe_srisenable
		input  wire         i_phy_7_pipe_RxClk,                //                    .if_i_phy_7_pipe_RxClk
		input  wire         i_phy_7_pipe_RxValid,              //                    .if_i_phy_7_pipe_RxValid
		input  wire [39:0]  i_phy_7_pipe_RxData,               //                    .if_i_phy_7_pipe_RxData
		input  wire         i_phy_7_pipe_RxElecIdle,           //                    .if_i_phy_7_pipe_RxElecIdle
		input  wire [2:0]   i_phy_7_pipe_RxStatus,             //                    .if_i_phy_7_pipe_RxStatus
		input  wire         i_phy_7_pipe_RxStandbyStatus,      //                    .if_i_phy_7_pipe_RxStandbyStatus
		output wire         o_phy_7_pipe_RxStandby,            //                    .if_o_phy_7_pipe_RxStandby
		output wire         o_phy_7_pipe_RxTermination,        //                    .if_o_phy_7_pipe_RxTermination
		output wire [1:0]   o_phy_7_pipe_RxWidth,              //                    .if_o_phy_7_pipe_RxWidth
		input  wire         i_phy_7_pipe_PhyStatus,            //                    .if_i_phy_7_pipe_PhyStatus
		input  wire         i_phy_7_pipe_PclkChangeOk,         //                    .if_i_phy_7_pipe_PclkChangeOk
		output wire [7:0]   o_phy_7_pipe_M2P_MessageBus,       //                    .if_o_phy_7_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_7_pipe_P2M_MessageBus,       //                    .if_i_phy_7_pipe_P2M_MessageBus
		output wire         o_phy_8_pipe_TxDataValid,          //                    .if_o_phy_8_pipe_TxDataValid
		output wire [39:0]  o_phy_8_pipe_TxData,               //                    .if_o_phy_8_pipe_TxData
		output wire         o_phy_8_pipe_TxDetRxLpbk,          //                    .if_o_phy_8_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_8_pipe_TxElecIdle,           //                    .if_o_phy_8_pipe_TxElecIdle
		output wire [3:0]   o_phy_8_pipe_PowerDown,            //                    .if_o_phy_8_pipe_PowerDown
		output wire [2:0]   o_phy_8_pipe_Rate,                 //                    .if_o_phy_8_pipe_Rate
		output wire         o_phy_8_pipe_PclkChangeAck,        //                    .if_o_phy_8_pipe_PclkChangeAck
		output wire [2:0]   o_phy_8_pipe_PCLKRate,             //                    .if_o_phy_8_pipe_PCLKRate
		output wire [1:0]   o_phy_8_pipe_Width,                //                    .if_o_phy_8_pipe_Width
		output wire         o_phy_8_pipe_PCLK,                 //                    .if_o_phy_8_pipe_PCLK
		output wire         o_phy_8_pipe_rxelecidle_disable,   //                    .if_o_phy_8_pipe_rxelecidle_disable
		output wire         o_phy_8_pipe_txcmnmode_disable,    //                    .if_o_phy_8_pipe_txcmnmode_disable
		output wire         o_phy_8_pipe_srisenable,           //                    .if_o_phy_8_pipe_srisenable
		input  wire         i_phy_8_pipe_RxClk,                //                    .if_i_phy_8_pipe_RxClk
		input  wire         i_phy_8_pipe_RxValid,              //                    .if_i_phy_8_pipe_RxValid
		input  wire [39:0]  i_phy_8_pipe_RxData,               //                    .if_i_phy_8_pipe_RxData
		input  wire         i_phy_8_pipe_RxElecIdle,           //                    .if_i_phy_8_pipe_RxElecIdle
		input  wire [2:0]   i_phy_8_pipe_RxStatus,             //                    .if_i_phy_8_pipe_RxStatus
		input  wire         i_phy_8_pipe_RxStandbyStatus,      //                    .if_i_phy_8_pipe_RxStandbyStatus
		output wire         o_phy_8_pipe_RxStandby,            //                    .if_o_phy_8_pipe_RxStandby
		output wire         o_phy_8_pipe_RxTermination,        //                    .if_o_phy_8_pipe_RxTermination
		output wire [1:0]   o_phy_8_pipe_RxWidth,              //                    .if_o_phy_8_pipe_RxWidth
		input  wire         i_phy_8_pipe_PhyStatus,            //                    .if_i_phy_8_pipe_PhyStatus
		input  wire         i_phy_8_pipe_PclkChangeOk,         //                    .if_i_phy_8_pipe_PclkChangeOk
		output wire [7:0]   o_phy_8_pipe_M2P_MessageBus,       //                    .if_o_phy_8_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_8_pipe_P2M_MessageBus,       //                    .if_i_phy_8_pipe_P2M_MessageBus
		output wire         o_phy_9_pipe_TxDataValid,          //                    .if_o_phy_9_pipe_TxDataValid
		output wire [39:0]  o_phy_9_pipe_TxData,               //                    .if_o_phy_9_pipe_TxData
		output wire         o_phy_9_pipe_TxDetRxLpbk,          //                    .if_o_phy_9_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_9_pipe_TxElecIdle,           //                    .if_o_phy_9_pipe_TxElecIdle
		output wire [3:0]   o_phy_9_pipe_PowerDown,            //                    .if_o_phy_9_pipe_PowerDown
		output wire [2:0]   o_phy_9_pipe_Rate,                 //                    .if_o_phy_9_pipe_Rate
		output wire         o_phy_9_pipe_PclkChangeAck,        //                    .if_o_phy_9_pipe_PclkChangeAck
		output wire [2:0]   o_phy_9_pipe_PCLKRate,             //                    .if_o_phy_9_pipe_PCLKRate
		output wire [1:0]   o_phy_9_pipe_Width,                //                    .if_o_phy_9_pipe_Width
		output wire         o_phy_9_pipe_PCLK,                 //                    .if_o_phy_9_pipe_PCLK
		output wire         o_phy_9_pipe_rxelecidle_disable,   //                    .if_o_phy_9_pipe_rxelecidle_disable
		output wire         o_phy_9_pipe_txcmnmode_disable,    //                    .if_o_phy_9_pipe_txcmnmode_disable
		output wire         o_phy_9_pipe_srisenable,           //                    .if_o_phy_9_pipe_srisenable
		input  wire         i_phy_9_pipe_RxClk,                //                    .if_i_phy_9_pipe_RxClk
		input  wire         i_phy_9_pipe_RxValid,              //                    .if_i_phy_9_pipe_RxValid
		input  wire [39:0]  i_phy_9_pipe_RxData,               //                    .if_i_phy_9_pipe_RxData
		input  wire         i_phy_9_pipe_RxElecIdle,           //                    .if_i_phy_9_pipe_RxElecIdle
		input  wire [2:0]   i_phy_9_pipe_RxStatus,             //                    .if_i_phy_9_pipe_RxStatus
		input  wire         i_phy_9_pipe_RxStandbyStatus,      //                    .if_i_phy_9_pipe_RxStandbyStatus
		output wire         o_phy_9_pipe_RxStandby,            //                    .if_o_phy_9_pipe_RxStandby
		output wire         o_phy_9_pipe_RxTermination,        //                    .if_o_phy_9_pipe_RxTermination
		output wire [1:0]   o_phy_9_pipe_RxWidth,              //                    .if_o_phy_9_pipe_RxWidth
		input  wire         i_phy_9_pipe_PhyStatus,            //                    .if_i_phy_9_pipe_PhyStatus
		input  wire         i_phy_9_pipe_PclkChangeOk,         //                    .if_i_phy_9_pipe_PclkChangeOk
		output wire [7:0]   o_phy_9_pipe_M2P_MessageBus,       //                    .if_o_phy_9_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_9_pipe_P2M_MessageBus,       //                    .if_i_phy_9_pipe_P2M_MessageBus
		output wire         o_phy_10_pipe_TxDataValid,         //                    .if_o_phy_10_pipe_TxDataValid
		output wire [39:0]  o_phy_10_pipe_TxData,              //                    .if_o_phy_10_pipe_TxData
		output wire         o_phy_10_pipe_TxDetRxLpbk,         //                    .if_o_phy_10_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_10_pipe_TxElecIdle,          //                    .if_o_phy_10_pipe_TxElecIdle
		output wire [3:0]   o_phy_10_pipe_PowerDown,           //                    .if_o_phy_10_pipe_PowerDown
		output wire [2:0]   o_phy_10_pipe_Rate,                //                    .if_o_phy_10_pipe_Rate
		output wire         o_phy_10_pipe_PclkChangeAck,       //                    .if_o_phy_10_pipe_PclkChangeAck
		output wire [2:0]   o_phy_10_pipe_PCLKRate,            //                    .if_o_phy_10_pipe_PCLKRate
		output wire [1:0]   o_phy_10_pipe_Width,               //                    .if_o_phy_10_pipe_Width
		output wire         o_phy_10_pipe_PCLK,                //                    .if_o_phy_10_pipe_PCLK
		output wire         o_phy_10_pipe_rxelecidle_disable,  //                    .if_o_phy_10_pipe_rxelecidle_disable
		output wire         o_phy_10_pipe_txcmnmode_disable,   //                    .if_o_phy_10_pipe_txcmnmode_disable
		output wire         o_phy_10_pipe_srisenable,          //                    .if_o_phy_10_pipe_srisenable
		input  wire         i_phy_10_pipe_RxClk,               //                    .if_i_phy_10_pipe_RxClk
		input  wire         i_phy_10_pipe_RxValid,             //                    .if_i_phy_10_pipe_RxValid
		input  wire [39:0]  i_phy_10_pipe_RxData,              //                    .if_i_phy_10_pipe_RxData
		input  wire         i_phy_10_pipe_RxElecIdle,          //                    .if_i_phy_10_pipe_RxElecIdle
		input  wire [2:0]   i_phy_10_pipe_RxStatus,            //                    .if_i_phy_10_pipe_RxStatus
		input  wire         i_phy_10_pipe_RxStandbyStatus,     //                    .if_i_phy_10_pipe_RxStandbyStatus
		output wire         o_phy_10_pipe_RxStandby,           //                    .if_o_phy_10_pipe_RxStandby
		output wire         o_phy_10_pipe_RxTermination,       //                    .if_o_phy_10_pipe_RxTermination
		output wire [1:0]   o_phy_10_pipe_RxWidth,             //                    .if_o_phy_10_pipe_RxWidth
		input  wire         i_phy_10_pipe_PhyStatus,           //                    .if_i_phy_10_pipe_PhyStatus
		input  wire         i_phy_10_pipe_PclkChangeOk,        //                    .if_i_phy_10_pipe_PclkChangeOk
		output wire [7:0]   o_phy_10_pipe_M2P_MessageBus,      //                    .if_o_phy_10_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_10_pipe_P2M_MessageBus,      //                    .if_i_phy_10_pipe_P2M_MessageBus
		output wire         o_phy_11_pipe_TxDataValid,         //                    .if_o_phy_11_pipe_TxDataValid
		output wire [39:0]  o_phy_11_pipe_TxData,              //                    .if_o_phy_11_pipe_TxData
		output wire         o_phy_11_pipe_TxDetRxLpbk,         //                    .if_o_phy_11_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_11_pipe_TxElecIdle,          //                    .if_o_phy_11_pipe_TxElecIdle
		output wire [3:0]   o_phy_11_pipe_PowerDown,           //                    .if_o_phy_11_pipe_PowerDown
		output wire [2:0]   o_phy_11_pipe_Rate,                //                    .if_o_phy_11_pipe_Rate
		output wire         o_phy_11_pipe_PclkChangeAck,       //                    .if_o_phy_11_pipe_PclkChangeAck
		output wire [2:0]   o_phy_11_pipe_PCLKRate,            //                    .if_o_phy_11_pipe_PCLKRate
		output wire [1:0]   o_phy_11_pipe_Width,               //                    .if_o_phy_11_pipe_Width
		output wire         o_phy_11_pipe_PCLK,                //                    .if_o_phy_11_pipe_PCLK
		output wire         o_phy_11_pipe_rxelecidle_disable,  //                    .if_o_phy_11_pipe_rxelecidle_disable
		output wire         o_phy_11_pipe_txcmnmode_disable,   //                    .if_o_phy_11_pipe_txcmnmode_disable
		output wire         o_phy_11_pipe_srisenable,          //                    .if_o_phy_11_pipe_srisenable
		input  wire         i_phy_11_pipe_RxClk,               //                    .if_i_phy_11_pipe_RxClk
		input  wire         i_phy_11_pipe_RxValid,             //                    .if_i_phy_11_pipe_RxValid
		input  wire [39:0]  i_phy_11_pipe_RxData,              //                    .if_i_phy_11_pipe_RxData
		input  wire         i_phy_11_pipe_RxElecIdle,          //                    .if_i_phy_11_pipe_RxElecIdle
		input  wire [2:0]   i_phy_11_pipe_RxStatus,            //                    .if_i_phy_11_pipe_RxStatus
		input  wire         i_phy_11_pipe_RxStandbyStatus,     //                    .if_i_phy_11_pipe_RxStandbyStatus
		output wire         o_phy_11_pipe_RxStandby,           //                    .if_o_phy_11_pipe_RxStandby
		output wire         o_phy_11_pipe_RxTermination,       //                    .if_o_phy_11_pipe_RxTermination
		output wire [1:0]   o_phy_11_pipe_RxWidth,             //                    .if_o_phy_11_pipe_RxWidth
		input  wire         i_phy_11_pipe_PhyStatus,           //                    .if_i_phy_11_pipe_PhyStatus
		input  wire         i_phy_11_pipe_PclkChangeOk,        //                    .if_i_phy_11_pipe_PclkChangeOk
		output wire [7:0]   o_phy_11_pipe_M2P_MessageBus,      //                    .if_o_phy_11_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_11_pipe_P2M_MessageBus,      //                    .if_i_phy_11_pipe_P2M_MessageBus
		output wire         o_phy_12_pipe_TxDataValid,         //                    .if_o_phy_12_pipe_TxDataValid
		output wire [39:0]  o_phy_12_pipe_TxData,              //                    .if_o_phy_12_pipe_TxData
		output wire         o_phy_12_pipe_TxDetRxLpbk,         //                    .if_o_phy_12_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_12_pipe_TxElecIdle,          //                    .if_o_phy_12_pipe_TxElecIdle
		output wire [3:0]   o_phy_12_pipe_PowerDown,           //                    .if_o_phy_12_pipe_PowerDown
		output wire [2:0]   o_phy_12_pipe_Rate,                //                    .if_o_phy_12_pipe_Rate
		output wire         o_phy_12_pipe_PclkChangeAck,       //                    .if_o_phy_12_pipe_PclkChangeAck
		output wire [2:0]   o_phy_12_pipe_PCLKRate,            //                    .if_o_phy_12_pipe_PCLKRate
		output wire [1:0]   o_phy_12_pipe_Width,               //                    .if_o_phy_12_pipe_Width
		output wire         o_phy_12_pipe_PCLK,                //                    .if_o_phy_12_pipe_PCLK
		output wire         o_phy_12_pipe_rxelecidle_disable,  //                    .if_o_phy_12_pipe_rxelecidle_disable
		output wire         o_phy_12_pipe_txcmnmode_disable,   //                    .if_o_phy_12_pipe_txcmnmode_disable
		output wire         o_phy_12_pipe_srisenable,          //                    .if_o_phy_12_pipe_srisenable
		input  wire         i_phy_12_pipe_RxClk,               //                    .if_i_phy_12_pipe_RxClk
		input  wire         i_phy_12_pipe_RxValid,             //                    .if_i_phy_12_pipe_RxValid
		input  wire [39:0]  i_phy_12_pipe_RxData,              //                    .if_i_phy_12_pipe_RxData
		input  wire         i_phy_12_pipe_RxElecIdle,          //                    .if_i_phy_12_pipe_RxElecIdle
		input  wire [2:0]   i_phy_12_pipe_RxStatus,            //                    .if_i_phy_12_pipe_RxStatus
		input  wire         i_phy_12_pipe_RxStandbyStatus,     //                    .if_i_phy_12_pipe_RxStandbyStatus
		output wire         o_phy_12_pipe_RxStandby,           //                    .if_o_phy_12_pipe_RxStandby
		output wire         o_phy_12_pipe_RxTermination,       //                    .if_o_phy_12_pipe_RxTermination
		output wire [1:0]   o_phy_12_pipe_RxWidth,             //                    .if_o_phy_12_pipe_RxWidth
		input  wire         i_phy_12_pipe_PhyStatus,           //                    .if_i_phy_12_pipe_PhyStatus
		input  wire         i_phy_12_pipe_PclkChangeOk,        //                    .if_i_phy_12_pipe_PclkChangeOk
		output wire [7:0]   o_phy_12_pipe_M2P_MessageBus,      //                    .if_o_phy_12_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_12_pipe_P2M_MessageBus,      //                    .if_i_phy_12_pipe_P2M_MessageBus
		output wire         o_phy_13_pipe_TxDataValid,         //                    .if_o_phy_13_pipe_TxDataValid
		output wire [39:0]  o_phy_13_pipe_TxData,              //                    .if_o_phy_13_pipe_TxData
		output wire         o_phy_13_pipe_TxDetRxLpbk,         //                    .if_o_phy_13_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_13_pipe_TxElecIdle,          //                    .if_o_phy_13_pipe_TxElecIdle
		output wire [3:0]   o_phy_13_pipe_PowerDown,           //                    .if_o_phy_13_pipe_PowerDown
		output wire [2:0]   o_phy_13_pipe_Rate,                //                    .if_o_phy_13_pipe_Rate
		output wire         o_phy_13_pipe_PclkChangeAck,       //                    .if_o_phy_13_pipe_PclkChangeAck
		output wire [2:0]   o_phy_13_pipe_PCLKRate,            //                    .if_o_phy_13_pipe_PCLKRate
		output wire [1:0]   o_phy_13_pipe_Width,               //                    .if_o_phy_13_pipe_Width
		output wire         o_phy_13_pipe_PCLK,                //                    .if_o_phy_13_pipe_PCLK
		output wire         o_phy_13_pipe_rxelecidle_disable,  //                    .if_o_phy_13_pipe_rxelecidle_disable
		output wire         o_phy_13_pipe_txcmnmode_disable,   //                    .if_o_phy_13_pipe_txcmnmode_disable
		output wire         o_phy_13_pipe_srisenable,          //                    .if_o_phy_13_pipe_srisenable
		input  wire         i_phy_13_pipe_RxClk,               //                    .if_i_phy_13_pipe_RxClk
		input  wire         i_phy_13_pipe_RxValid,             //                    .if_i_phy_13_pipe_RxValid
		input  wire [39:0]  i_phy_13_pipe_RxData,              //                    .if_i_phy_13_pipe_RxData
		input  wire         i_phy_13_pipe_RxElecIdle,          //                    .if_i_phy_13_pipe_RxElecIdle
		input  wire [2:0]   i_phy_13_pipe_RxStatus,            //                    .if_i_phy_13_pipe_RxStatus
		input  wire         i_phy_13_pipe_RxStandbyStatus,     //                    .if_i_phy_13_pipe_RxStandbyStatus
		output wire         o_phy_13_pipe_RxStandby,           //                    .if_o_phy_13_pipe_RxStandby
		output wire         o_phy_13_pipe_RxTermination,       //                    .if_o_phy_13_pipe_RxTermination
		output wire [1:0]   o_phy_13_pipe_RxWidth,             //                    .if_o_phy_13_pipe_RxWidth
		input  wire         i_phy_13_pipe_PhyStatus,           //                    .if_i_phy_13_pipe_PhyStatus
		input  wire         i_phy_13_pipe_PclkChangeOk,        //                    .if_i_phy_13_pipe_PclkChangeOk
		output wire [7:0]   o_phy_13_pipe_M2P_MessageBus,      //                    .if_o_phy_13_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_13_pipe_P2M_MessageBus,      //                    .if_i_phy_13_pipe_P2M_MessageBus
		output wire         o_phy_14_pipe_TxDataValid,         //                    .if_o_phy_14_pipe_TxDataValid
		output wire [39:0]  o_phy_14_pipe_TxData,              //                    .if_o_phy_14_pipe_TxData
		output wire         o_phy_14_pipe_TxDetRxLpbk,         //                    .if_o_phy_14_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_14_pipe_TxElecIdle,          //                    .if_o_phy_14_pipe_TxElecIdle
		output wire [3:0]   o_phy_14_pipe_PowerDown,           //                    .if_o_phy_14_pipe_PowerDown
		output wire [2:0]   o_phy_14_pipe_Rate,                //                    .if_o_phy_14_pipe_Rate
		output wire         o_phy_14_pipe_PclkChangeAck,       //                    .if_o_phy_14_pipe_PclkChangeAck
		output wire [2:0]   o_phy_14_pipe_PCLKRate,            //                    .if_o_phy_14_pipe_PCLKRate
		output wire [1:0]   o_phy_14_pipe_Width,               //                    .if_o_phy_14_pipe_Width
		output wire         o_phy_14_pipe_PCLK,                //                    .if_o_phy_14_pipe_PCLK
		output wire         o_phy_14_pipe_rxelecidle_disable,  //                    .if_o_phy_14_pipe_rxelecidle_disable
		output wire         o_phy_14_pipe_txcmnmode_disable,   //                    .if_o_phy_14_pipe_txcmnmode_disable
		output wire         o_phy_14_pipe_srisenable,          //                    .if_o_phy_14_pipe_srisenable
		input  wire         i_phy_14_pipe_RxClk,               //                    .if_i_phy_14_pipe_RxClk
		input  wire         i_phy_14_pipe_RxValid,             //                    .if_i_phy_14_pipe_RxValid
		input  wire [39:0]  i_phy_14_pipe_RxData,              //                    .if_i_phy_14_pipe_RxData
		input  wire         i_phy_14_pipe_RxElecIdle,          //                    .if_i_phy_14_pipe_RxElecIdle
		input  wire [2:0]   i_phy_14_pipe_RxStatus,            //                    .if_i_phy_14_pipe_RxStatus
		input  wire         i_phy_14_pipe_RxStandbyStatus,     //                    .if_i_phy_14_pipe_RxStandbyStatus
		output wire         o_phy_14_pipe_RxStandby,           //                    .if_o_phy_14_pipe_RxStandby
		output wire         o_phy_14_pipe_RxTermination,       //                    .if_o_phy_14_pipe_RxTermination
		output wire [1:0]   o_phy_14_pipe_RxWidth,             //                    .if_o_phy_14_pipe_RxWidth
		input  wire         i_phy_14_pipe_PhyStatus,           //                    .if_i_phy_14_pipe_PhyStatus
		input  wire         i_phy_14_pipe_PclkChangeOk,        //                    .if_i_phy_14_pipe_PclkChangeOk
		output wire [7:0]   o_phy_14_pipe_M2P_MessageBus,      //                    .if_o_phy_14_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_14_pipe_P2M_MessageBus,      //                    .if_i_phy_14_pipe_P2M_MessageBus
		output wire         o_phy_15_pipe_TxDataValid,         //                    .if_o_phy_15_pipe_TxDataValid
		output wire [39:0]  o_phy_15_pipe_TxData,              //                    .if_o_phy_15_pipe_TxData
		output wire         o_phy_15_pipe_TxDetRxLpbk,         //                    .if_o_phy_15_pipe_TxDetRxLpbk
		output wire [3:0]   o_phy_15_pipe_TxElecIdle,          //                    .if_o_phy_15_pipe_TxElecIdle
		output wire [3:0]   o_phy_15_pipe_PowerDown,           //                    .if_o_phy_15_pipe_PowerDown
		output wire [2:0]   o_phy_15_pipe_Rate,                //                    .if_o_phy_15_pipe_Rate
		output wire         o_phy_15_pipe_PclkChangeAck,       //                    .if_o_phy_15_pipe_PclkChangeAck
		output wire [2:0]   o_phy_15_pipe_PCLKRate,            //                    .if_o_phy_15_pipe_PCLKRate
		output wire [1:0]   o_phy_15_pipe_Width,               //                    .if_o_phy_15_pipe_Width
		output wire         o_phy_15_pipe_PCLK,                //                    .if_o_phy_15_pipe_PCLK
		output wire         o_phy_15_pipe_rxelecidle_disable,  //                    .if_o_phy_15_pipe_rxelecidle_disable
		output wire         o_phy_15_pipe_txcmnmode_disable,   //                    .if_o_phy_15_pipe_txcmnmode_disable
		output wire         o_phy_15_pipe_srisenable,          //                    .if_o_phy_15_pipe_srisenable
		input  wire         i_phy_15_pipe_RxClk,               //                    .if_i_phy_15_pipe_RxClk
		input  wire         i_phy_15_pipe_RxValid,             //                    .if_i_phy_15_pipe_RxValid
		input  wire [39:0]  i_phy_15_pipe_RxData,              //                    .if_i_phy_15_pipe_RxData
		input  wire         i_phy_15_pipe_RxElecIdle,          //                    .if_i_phy_15_pipe_RxElecIdle
		input  wire [2:0]   i_phy_15_pipe_RxStatus,            //                    .if_i_phy_15_pipe_RxStatus
		input  wire         i_phy_15_pipe_RxStandbyStatus,     //                    .if_i_phy_15_pipe_RxStandbyStatus
		output wire         o_phy_15_pipe_RxStandby,           //                    .if_o_phy_15_pipe_RxStandby
		output wire         o_phy_15_pipe_RxTermination,       //                    .if_o_phy_15_pipe_RxTermination
		output wire [1:0]   o_phy_15_pipe_RxWidth,             //                    .if_o_phy_15_pipe_RxWidth
		input  wire         i_phy_15_pipe_PhyStatus,           //                    .if_i_phy_15_pipe_PhyStatus
		input  wire         i_phy_15_pipe_PclkChangeOk,        //                    .if_i_phy_15_pipe_PclkChangeOk
		output wire [7:0]   o_phy_15_pipe_M2P_MessageBus,      //                    .if_o_phy_15_pipe_M2P_MessageBus
		input  wire [7:0]   i_phy_15_pipe_P2M_MessageBus,      //                    .if_i_phy_15_pipe_P2M_MessageBus
		output wire         o_phy_0_pipe_rxbitslip_req,        //                    .if_o_phy_0_pipe_rxbitslip_req
		output wire [4:0]   o_phy_0_pipe_rxbitslip_va,         //                    .if_o_phy_0_pipe_rxbitslip_va
		input  wire         i_phy_0_pipe_RxBitSlip_Ack,        //                    .if_i_phy_0_pipe_RxBitSlip_Ack
		output wire         o_phy_1_pipe_rxbitslip_req,        //                    .if_o_phy_1_pipe_rxbitslip_req
		output wire [4:0]   o_phy_1_pipe_rxbitslip_va,         //                    .if_o_phy_1_pipe_rxbitslip_va
		input  wire         i_phy_1_pipe_RxBitSlip_Ack,        //                    .if_i_phy_1_pipe_RxBitSlip_Ack
		output wire         o_phy_2_pipe_rxbitslip_req,        //                    .if_o_phy_2_pipe_rxbitslip_req
		output wire [4:0]   o_phy_2_pipe_rxbitslip_va,         //                    .if_o_phy_2_pipe_rxbitslip_va
		input  wire         i_phy_2_pipe_RxBitSlip_Ack,        //                    .if_i_phy_2_pipe_RxBitSlip_Ack
		output wire         o_phy_3_pipe_rxbitslip_req,        //                    .if_o_phy_3_pipe_rxbitslip_req
		output wire [4:0]   o_phy_3_pipe_rxbitslip_va,         //                    .if_o_phy_3_pipe_rxbitslip_va
		input  wire         i_phy_3_pipe_RxBitSlip_Ack,        //                    .if_i_phy_3_pipe_RxBitSlip_Ack
		output wire         o_phy_4_pipe_rxbitslip_req,        //                    .if_o_phy_4_pipe_rxbitslip_req
		output wire [4:0]   o_phy_4_pipe_rxbitslip_va,         //                    .if_o_phy_4_pipe_rxbitslip_va
		input  wire         i_phy_4_pipe_RxBitSlip_Ack,        //                    .if_i_phy_4_pipe_RxBitSlip_Ack
		output wire         o_phy_5_pipe_rxbitslip_req,        //                    .if_o_phy_5_pipe_rxbitslip_req
		output wire [4:0]   o_phy_5_pipe_rxbitslip_va,         //                    .if_o_phy_5_pipe_rxbitslip_va
		input  wire         i_phy_5_pipe_RxBitSlip_Ack,        //                    .if_i_phy_5_pipe_RxBitSlip_Ack
		output wire         o_phy_6_pipe_rxbitslip_req,        //                    .if_o_phy_6_pipe_rxbitslip_req
		output wire [4:0]   o_phy_6_pipe_rxbitslip_va,         //                    .if_o_phy_6_pipe_rxbitslip_va
		input  wire         i_phy_6_pipe_RxBitSlip_Ack,        //                    .if_i_phy_6_pipe_RxBitSlip_Ack
		output wire         o_phy_7_pipe_rxbitslip_req,        //                    .if_o_phy_7_pipe_rxbitslip_req
		output wire [4:0]   o_phy_7_pipe_rxbitslip_va,         //                    .if_o_phy_7_pipe_rxbitslip_va
		input  wire         i_phy_7_pipe_RxBitSlip_Ack,        //                    .if_i_phy_7_pipe_RxBitSlip_Ack
		output wire         o_phy_8_pipe_rxbitslip_req,        //                    .if_o_phy_8_pipe_rxbitslip_req
		output wire [4:0]   o_phy_8_pipe_rxbitslip_va,         //                    .if_o_phy_8_pipe_rxbitslip_va
		input  wire         i_phy_8_pipe_RxBitSlip_Ack,        //                    .if_i_phy_8_pipe_RxBitSlip_Ack
		output wire         o_phy_9_pipe_rxbitslip_req,        //                    .if_o_phy_9_pipe_rxbitslip_req
		output wire [4:0]   o_phy_9_pipe_rxbitslip_va,         //                    .if_o_phy_9_pipe_rxbitslip_va
		input  wire         i_phy_9_pipe_RxBitSlip_Ack,        //                    .if_i_phy_9_pipe_RxBitSlip_Ack
		output wire         o_phy_10_pipe_rxbitslip_req,       //                    .if_o_phy_10_pipe_rxbitslip_req
		output wire [4:0]   o_phy_10_pipe_rxbitslip_va,        //                    .if_o_phy_10_pipe_rxbitslip_va
		input  wire         i_phy_10_pipe_RxBitSlip_Ack,       //                    .if_i_phy_10_pipe_RxBitSlip_Ack
		output wire         o_phy_11_pipe_rxbitslip_req,       //                    .if_o_phy_11_pipe_rxbitslip_req
		output wire [4:0]   o_phy_11_pipe_rxbitslip_va,        //                    .if_o_phy_11_pipe_rxbitslip_va
		input  wire         i_phy_11_pipe_RxBitSlip_Ack,       //                    .if_i_phy_11_pipe_RxBitSlip_Ack
		output wire         o_phy_12_pipe_rxbitslip_req,       //                    .if_o_phy_12_pipe_rxbitslip_req
		output wire [4:0]   o_phy_12_pipe_rxbitslip_va,        //                    .if_o_phy_12_pipe_rxbitslip_va
		input  wire         i_phy_12_pipe_RxBitSlip_Ack,       //                    .if_i_phy_12_pipe_RxBitSlip_Ack
		output wire         o_phy_13_pipe_rxbitslip_req,       //                    .if_o_phy_13_pipe_rxbitslip_req
		output wire [4:0]   o_phy_13_pipe_rxbitslip_va,        //                    .if_o_phy_13_pipe_rxbitslip_va
		input  wire         i_phy_13_pipe_RxBitSlip_Ack,       //                    .if_i_phy_13_pipe_RxBitSlip_Ack
		output wire         o_phy_14_pipe_rxbitslip_req,       //                    .if_o_phy_14_pipe_rxbitslip_req
		output wire [4:0]   o_phy_14_pipe_rxbitslip_va,        //                    .if_o_phy_14_pipe_rxbitslip_va
		input  wire         i_phy_14_pipe_RxBitSlip_Ack,       //                    .if_i_phy_14_pipe_RxBitSlip_Ack
		output wire         o_phy_15_pipe_rxbitslip_req,       //                    .if_o_phy_15_pipe_rxbitslip_req
		output wire [4:0]   o_phy_15_pipe_rxbitslip_va,        //                    .if_o_phy_15_pipe_rxbitslip_va
		input  wire         i_phy_15_pipe_RxBitSlip_Ack        //                    .if_i_phy_15_pipe_RxBitSlip_Ack
	);
endmodule

