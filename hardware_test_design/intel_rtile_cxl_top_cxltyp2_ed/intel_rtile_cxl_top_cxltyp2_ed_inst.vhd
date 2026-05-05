	component intel_rtile_cxl_top_cxltyp2_ed is
		port (
			refclk0                           : in  std_logic                      := 'X';             -- clk
			refclk1                           : in  std_logic                      := 'X';             -- clk
			refclk4                           : in  std_logic                      := 'X';             -- clk
			resetn                            : in  std_logic                      := 'X';             -- reset_n
			nInit_done                        : in  std_logic                      := 'X';             -- ninit_done
			pll_lock_o                        : out std_logic;                                         -- pll_lock_o
			usr2ip_qos_devload                : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- usr2ip_qos_devload
			ip2hdm_clk                        : out std_logic;                                         -- clk
			ip2hdm_reset_n                    : out std_logic;                                         -- reset_n
			cxl_warm_rst_n                    : out std_logic;                                         -- reset_n
			cxl_cold_rst_n                    : out std_logic;                                         -- reset_n
			mc2ip_memsize                     : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- mem_size_t
			cxl_rx_n                          : in  std_logic_vector(15 downto 0)  := (others => 'X'); -- cxl_rx_n
			cxl_rx_p                          : in  std_logic_vector(15 downto 0)  := (others => 'X'); -- cxl_rx_p
			cxl_tx_n                          : out std_logic_vector(15 downto 0);                     -- cxl_tx_n
			cxl_tx_p                          : out std_logic_vector(15 downto 0);                     -- cxl_tx_p
			mc2ip_0_sr_status                 : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- mc_sr_status
			mc2ip_1_sr_status                 : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- mc_sr_status
			ip2cafu_quiesce_req               : out std_logic;                                         -- quiesce_req
			cafu2ip_quiesce_ack               : in  std_logic                      := 'X';             -- quiesce_ack
			cafu2ip_aximm0_awid               : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- awid
			cafu2ip_aximm0_awaddr             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- awaddr
			cafu2ip_aximm0_awlen              : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- awlen
			cafu2ip_aximm0_awsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			cafu2ip_aximm0_awburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			cafu2ip_aximm0_awprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			cafu2ip_aximm0_awqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			cafu2ip_aximm0_awuser             : in  std_logic_vector(6 downto 0)   := (others => 'X'); -- awuser
			cafu2ip_aximm0_awvalid            : in  std_logic                      := 'X';             -- awvalid
			cafu2ip_aximm0_awcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			cafu2ip_aximm0_awlock             : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awlock
			cafu2ip_aximm0_awregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awregion
			cafu2ip_aximm0_awatop             : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- awatop
			ip2cafu_aximm0_awready            : out std_logic;                                         -- awready
			cafu2ip_aximm1_awid               : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- awid
			cafu2ip_aximm1_awaddr             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- awaddr
			cafu2ip_aximm1_awlen              : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- awlen
			cafu2ip_aximm1_awsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			cafu2ip_aximm1_awburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			cafu2ip_aximm1_awprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			cafu2ip_aximm1_awqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awqos
			cafu2ip_aximm1_awuser             : in  std_logic_vector(6 downto 0)   := (others => 'X'); -- awuser
			cafu2ip_aximm1_awvalid            : in  std_logic                      := 'X';             -- awvalid
			cafu2ip_aximm1_awcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			cafu2ip_aximm1_awlock             : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- awlock
			cafu2ip_aximm1_awregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- awregion
			cafu2ip_aximm1_awatop             : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- awatop
			ip2cafu_aximm1_awready            : out std_logic;                                         -- awready
			cafu2ip_aximm0_wdata              : in  std_logic_vector(511 downto 0) := (others => 'X'); -- wdata
			cafu2ip_aximm0_wstrb              : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- wstrb
			cafu2ip_aximm0_wlast              : in  std_logic                      := 'X';             -- wlast
			cafu2ip_aximm0_wuser              : in  std_logic                      := 'X';             -- wuser
			cafu2ip_aximm0_wvalid             : in  std_logic                      := 'X';             -- wvalid
			ip2cafu_aximm0_wready             : out std_logic;                                         -- wready
			cafu2ip_aximm1_wdata              : in  std_logic_vector(511 downto 0) := (others => 'X'); -- wdata
			cafu2ip_aximm1_wstrb              : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- wstrb
			cafu2ip_aximm1_wlast              : in  std_logic                      := 'X';             -- wlast
			cafu2ip_aximm1_wuser              : in  std_logic                      := 'X';             -- wuser
			cafu2ip_aximm1_wvalid             : in  std_logic                      := 'X';             -- wvalid
			ip2cafu_aximm1_wready             : out std_logic;                                         -- wready
			ip2cafu_aximm0_bid                : out std_logic_vector(11 downto 0);                     -- bid
			ip2cafu_aximm0_bresp              : out std_logic_vector(1 downto 0);                      -- bresp
			ip2cafu_aximm0_buser              : out std_logic_vector(3 downto 0);                      -- buser
			ip2cafu_aximm0_bvalid             : out std_logic;                                         -- bvalid
			cafu2ip_aximm0_bready             : in  std_logic                      := 'X';             -- bready
			ip2cafu_aximm1_bid                : out std_logic_vector(11 downto 0);                     -- bid
			ip2cafu_aximm1_bresp              : out std_logic_vector(1 downto 0);                      -- bresp
			ip2cafu_aximm1_buser              : out std_logic_vector(3 downto 0);                      -- buser
			ip2cafu_aximm1_bvalid             : out std_logic;                                         -- bvalid
			cafu2ip_aximm1_bready             : in  std_logic                      := 'X';             -- bready
			cafu2ip_aximm0_arid               : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- arid
			cafu2ip_aximm0_araddr             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- araddr
			cafu2ip_aximm0_arlen              : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- arlen
			cafu2ip_aximm0_arsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			cafu2ip_aximm0_arburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			cafu2ip_aximm0_arprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			cafu2ip_aximm0_arqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			cafu2ip_aximm0_aruser             : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- aruser
			cafu2ip_aximm0_arvalid            : in  std_logic                      := 'X';             -- arvalid
			cafu2ip_aximm0_arcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			cafu2ip_aximm0_arlock             : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arlock
			cafu2ip_aximm0_arregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			ip2cafu_aximm0_arready            : out std_logic;                                         -- arready
			cafu2ip_aximm1_arid               : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- arid
			cafu2ip_aximm1_araddr             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- araddr
			cafu2ip_aximm1_arlen              : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- arlen
			cafu2ip_aximm1_arsize             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			cafu2ip_aximm1_arburst            : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			cafu2ip_aximm1_arprot             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			cafu2ip_aximm1_arqos              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arqos
			cafu2ip_aximm1_aruser             : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- aruser
			cafu2ip_aximm1_arvalid            : in  std_logic                      := 'X';             -- arvalid
			cafu2ip_aximm1_arcache            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			cafu2ip_aximm1_arlock             : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- arlock
			cafu2ip_aximm1_arregion           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- arregion
			ip2cafu_aximm1_arready            : out std_logic;                                         -- arready
			ip2cafu_aximm0_rid                : out std_logic_vector(11 downto 0);                     -- rid
			ip2cafu_aximm0_rdata              : out std_logic_vector(511 downto 0);                    -- rdata
			ip2cafu_aximm0_rresp              : out std_logic_vector(1 downto 0);                      -- rresp
			ip2cafu_aximm0_rlast              : out std_logic;                                         -- rlast
			ip2cafu_aximm0_ruser              : out std_logic_vector(1 downto 0);                      -- ruser
			ip2cafu_aximm0_rvalid             : out std_logic;                                         -- rvalid
			cafu2ip_aximm0_rready             : in  std_logic                      := 'X';             -- rready
			ip2cafu_aximm1_rid                : out std_logic_vector(11 downto 0);                     -- rid
			ip2cafu_aximm1_rdata              : out std_logic_vector(511 downto 0);                    -- rdata
			ip2cafu_aximm1_rresp              : out std_logic_vector(1 downto 0);                      -- rresp
			ip2cafu_aximm1_rlast              : out std_logic;                                         -- rlast
			ip2cafu_aximm1_ruser              : out std_logic_vector(1 downto 0);                      -- ruser
			ip2cafu_aximm1_rvalid             : out std_logic;                                         -- rvalid
			cafu2ip_aximm1_rready             : in  std_logic                      := 'X';             -- rready
			cafu2ip_csr0_cfg_if               : in  std_logic_vector(95 downto 0)  := (others => 'X'); -- cafu2ip_cfg_if
			ip2cafu_csr0_cfg_if               : out std_logic_vector(5 downto 0);                      -- ip2cafu_devsec
			ip2csr_avmm_clk                   : out std_logic;                                         -- clk
			ip2csr_avmm_rstn                  : out std_logic;                                         -- rst_n
			csr2ip_avmm_waitrequest           : in  std_logic                      := 'X';             -- waitrequest
			csr2ip_avmm_readdata              : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- readdata
			csr2ip_avmm_readdatavalid         : in  std_logic                      := 'X';             -- readdatavalid
			ip2csr_avmm_writedata             : out std_logic_vector(63 downto 0);                     -- writedata
			ip2csr_avmm_poison                : out std_logic;                                         -- poison
			ip2csr_avmm_address               : out std_logic_vector(21 downto 0);                     -- address
			ip2csr_avmm_write                 : out std_logic;                                         -- write
			ip2csr_avmm_read                  : out std_logic;                                         -- read
			ip2csr_avmm_byteenable            : out std_logic_vector(7 downto 0);                      -- byteenable
			ip2cafu_avmm_clk                  : out std_logic;                                         -- clk
			ip2cafu_avmm_rstn                 : out std_logic;                                         -- rstn
			cafu2ip_avmm_waitrequest          : in  std_logic                      := 'X';             -- waitrequest
			cafu2ip_avmm_readdata             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- readdata
			cafu2ip_avmm_readdatavalid        : in  std_logic                      := 'X';             -- readdatavalid
			ip2cafu_avmm_burstcount           : out std_logic;                                         -- burstcount
			ip2cafu_avmm_writedata            : out std_logic_vector(63 downto 0);                     -- writedata
			ip2cafu_avmm_poison               : out std_logic;                                         -- poison
			ip2cafu_avmm_address              : out std_logic_vector(21 downto 0);                     -- address
			ip2cafu_avmm_write                : out std_logic;                                         -- write
			ip2cafu_avmm_read                 : out std_logic;                                         -- read
			ip2cafu_avmm_byteenable           : out std_logic_vector(7 downto 0);                      -- byteenable
			ccv_afu_conf_base_addr_high       : out std_logic_vector(31 downto 0);                     -- base_addr_high
			ccv_afu_conf_base_addr_high_valid : out std_logic;                                         -- base_addr_high_valid
			ccv_afu_conf_base_addr_low        : out std_logic_vector(27 downto 0);                     -- base_addr_low
			ccv_afu_conf_base_addr_low_valid  : out std_logic;                                         -- base_addr_low_valid
			pf0_max_payload_size              : out std_logic_vector(2 downto 0);                      -- pfo_mpss
			pf0_max_read_request_size         : out std_logic_vector(2 downto 0);                      -- pf0_mrrs
			pf0_bus_master_en                 : out std_logic;                                         -- pfo_bus_master_en
			pf0_memory_access_en              : out std_logic;                                         -- pfo_mem_access_en
			pf1_max_payload_size              : out std_logic_vector(2 downto 0);                      -- pf1_mpss
			pf1_max_read_request_size         : out std_logic_vector(2 downto 0);                      -- pf1_mrrs
			pf1_bus_master_en                 : out std_logic;                                         -- pf1_bus_master_en
			pf1_memory_access_en              : out std_logic;                                         -- pf1_mem_access_en
			pf0_msix_enable                   : out std_logic;                                         -- msix_enable
			pf0_msix_fn_mask                  : out std_logic;                                         -- msix_fn_mask
			pf1_msix_enable                   : out std_logic;                                         -- msix_enable
			pf1_msix_fn_mask                  : out std_logic;                                         -- msix_fn_mask
			dev_serial_num                    : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- dev_serial_num
			dev_serial_num_valid              : in  std_logic                      := 'X';             -- dev_serial_num_valid
			ip2uio_tx_ready                   : out std_logic;                                         -- ready
			uio2ip_tx_st0_dvalid              : in  std_logic                      := 'X';             -- dvalid
			uio2ip_tx_st0_sop                 : in  std_logic                      := 'X';             -- sop
			uio2ip_tx_st0_eop                 : in  std_logic                      := 'X';             -- eop
			uio2ip_tx_st0_data                : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
			uio2ip_tx_st0_data_parity         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- data_parity
			uio2ip_tx_st0_hdr                 : in  std_logic_vector(127 downto 0) := (others => 'X'); -- hdr
			uio2ip_tx_st0_hdr_parity          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- hdr_parity
			uio2ip_tx_st0_hvalid              : in  std_logic                      := 'X';             -- hvalid
			uio2ip_tx_st0_prefix              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- prefix
			uio2ip_tx_st0_prefix_parity       : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- prefix_parity
			uio2ip_tx_st0_pvalid              : in  std_logic                      := 'X';             -- pvalid
			uio2ip_tx_st0_empty               : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- empty
			uio2ip_tx_st0_misc_parity         : in  std_logic                      := 'X';             -- misc_parity
			uio2ip_tx_st1_dvalid              : in  std_logic                      := 'X';             -- dvalid
			uio2ip_tx_st1_sop                 : in  std_logic                      := 'X';             -- sop
			uio2ip_tx_st1_eop                 : in  std_logic                      := 'X';             -- eop
			uio2ip_tx_st1_data                : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
			uio2ip_tx_st1_data_parity         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- data_parity
			uio2ip_tx_st1_hdr                 : in  std_logic_vector(127 downto 0) := (others => 'X'); -- hdr
			uio2ip_tx_st1_hdr_parity          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- hdr_parity
			uio2ip_tx_st1_hvalid              : in  std_logic                      := 'X';             -- hvalid
			uio2ip_tx_st1_prefix              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- prefix
			uio2ip_tx_st1_prefix_parity       : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- prefix_parity
			uio2ip_tx_st1_pvalid              : in  std_logic                      := 'X';             -- pvalid
			uio2ip_tx_st1_empty               : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- empty
			uio2ip_tx_st1_misc_parity         : in  std_logic                      := 'X';             -- misc_parity
			uio2ip_tx_st2_dvalid              : in  std_logic                      := 'X';             -- dvalid
			uio2ip_tx_st2_sop                 : in  std_logic                      := 'X';             -- sop
			uio2ip_tx_st2_eop                 : in  std_logic                      := 'X';             -- eop
			uio2ip_tx_st2_data                : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
			uio2ip_tx_st2_data_parity         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- data_parity
			uio2ip_tx_st2_hdr                 : in  std_logic_vector(127 downto 0) := (others => 'X'); -- hdr
			uio2ip_tx_st2_hdr_parity          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- hdr_parity
			uio2ip_tx_st2_hvalid              : in  std_logic                      := 'X';             -- hvalid
			uio2ip_tx_st2_prefix              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- prefix
			uio2ip_tx_st2_prefix_parity       : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- prefix_parity
			uio2ip_tx_st2_pvalid              : in  std_logic                      := 'X';             -- pvalid
			uio2ip_tx_st2_empty               : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- empty
			uio2ip_tx_st2_misc_parity         : in  std_logic                      := 'X';             -- misc_parity
			uio2ip_tx_st3_dvalid              : in  std_logic                      := 'X';             -- dvalid
			uio2ip_tx_st3_sop                 : in  std_logic                      := 'X';             -- sop
			uio2ip_tx_st3_eop                 : in  std_logic                      := 'X';             -- eop
			uio2ip_tx_st3_data                : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
			uio2ip_tx_st3_data_parity         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- data_parity
			uio2ip_tx_st3_hdr                 : in  std_logic_vector(127 downto 0) := (others => 'X'); -- hdr
			uio2ip_tx_st3_hdr_parity          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- hdr_parity
			uio2ip_tx_st3_hvalid              : in  std_logic                      := 'X';             -- hvalid
			uio2ip_tx_st3_prefix              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- prefix
			uio2ip_tx_st3_prefix_parity       : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- prefix_parity
			uio2ip_tx_st3_pvalid              : in  std_logic                      := 'X';             -- pvalid
			uio2ip_tx_st3_empty               : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- empty
			uio2ip_tx_st3_misc_parity         : in  std_logic                      := 'X';             -- misc_parity
			ip2uio_tx_st_Hcrdt_update         : out std_logic_vector(2 downto 0);                      -- Hcrdt_update
			ip2uio_tx_st_Hcrdt_update_cnt     : out std_logic_vector(5 downto 0);                      -- Hcrdt_update_cnt
			ip2uio_tx_st_Hcrdt_init           : out std_logic_vector(2 downto 0);                      -- Hcrdt_init
			uio2ip_tx_st_Hcrdt_init_ack       : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Hcrdt_init_ack
			ip2uio_tx_st_Dcrdt_update         : out std_logic_vector(2 downto 0);                      -- Dcrdt_update
			ip2uio_tx_st_Dcrdt_update_cnt     : out std_logic_vector(11 downto 0);                     -- Dcrdt_update_cnt
			ip2uio_tx_st_Dcrdt_init           : out std_logic_vector(2 downto 0);                      -- Dcrdt_init
			uio2ip_tx_st_Dcrdt_init_ack       : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Dcrdt_init_ack
			ip2uio_rx_st0_dvalid              : out std_logic;                                         -- dvalid
			ip2uio_rx_st0_sop                 : out std_logic;                                         -- sop
			ip2uio_rx_st0_eop                 : out std_logic;                                         -- eop
			ip2uio_rx_st0_passthrough         : out std_logic;                                         -- passthrough
			ip2uio_rx_st0_data                : out std_logic_vector(255 downto 0);                    -- data
			ip2uio_rx_st0_data_parity         : out std_logic_vector(7 downto 0);                      -- data_parity
			ip2uio_rx_st0_hdr                 : out std_logic_vector(127 downto 0);                    -- hdr
			ip2uio_rx_st0_hdr_parity          : out std_logic_vector(3 downto 0);                      -- hdr_parity
			ip2uio_rx_st0_hvalid              : out std_logic;                                         -- hvalid
			ip2uio_rx_st0_prefix              : out std_logic_vector(31 downto 0);                     -- prefix
			ip2uio_rx_st0_prefix_parity       : out std_logic_vector(0 downto 0);                      -- prefix_parity
			ip2uio_rx_st0_pvalid              : out std_logic;                                         -- pvalid
			ip2uio_rx_st0_bar                 : out std_logic_vector(2 downto 0);                      -- bar
			ip2uio_rx_st0_pfnum               : out std_logic_vector(2 downto 0);                      -- pfnum
			ip2uio_rx_st0_misc_parity         : out std_logic;                                         -- misc_parity
			ip2uio_rx_st0_empty               : out std_logic_vector(2 downto 0);                      -- empty
			ip2uio_rx_st1_dvalid              : out std_logic;                                         -- dvalid
			ip2uio_rx_st1_sop                 : out std_logic;                                         -- sop
			ip2uio_rx_st1_eop                 : out std_logic;                                         -- eop
			ip2uio_rx_st1_passthrough         : out std_logic;                                         -- passthrough
			ip2uio_rx_st1_data                : out std_logic_vector(255 downto 0);                    -- data
			ip2uio_rx_st1_data_parity         : out std_logic_vector(7 downto 0);                      -- data_parity
			ip2uio_rx_st1_hdr                 : out std_logic_vector(127 downto 0);                    -- hdr
			ip2uio_rx_st1_hdr_parity          : out std_logic_vector(3 downto 0);                      -- hdr_parity
			ip2uio_rx_st1_hvalid              : out std_logic;                                         -- hvalid
			ip2uio_rx_st1_prefix              : out std_logic_vector(31 downto 0);                     -- prefix
			ip2uio_rx_st1_prefix_parity       : out std_logic_vector(0 downto 0);                      -- prefix_parity
			ip2uio_rx_st1_pvalid              : out std_logic;                                         -- pvalid
			ip2uio_rx_st1_bar                 : out std_logic_vector(2 downto 0);                      -- bar
			ip2uio_rx_st1_pfnum               : out std_logic_vector(2 downto 0);                      -- pfnum
			ip2uio_rx_st1_misc_parity         : out std_logic;                                         -- misc_parity
			ip2uio_rx_st1_empty               : out std_logic_vector(2 downto 0);                      -- empty
			ip2uio_rx_st2_dvalid              : out std_logic;                                         -- dvalid
			ip2uio_rx_st2_sop                 : out std_logic;                                         -- sop
			ip2uio_rx_st2_eop                 : out std_logic;                                         -- eop
			ip2uio_rx_st2_passthrough         : out std_logic;                                         -- passthrough
			ip2uio_rx_st2_data                : out std_logic_vector(255 downto 0);                    -- data
			ip2uio_rx_st2_data_parity         : out std_logic_vector(7 downto 0);                      -- data_parity
			ip2uio_rx_st2_hdr                 : out std_logic_vector(127 downto 0);                    -- hdr
			ip2uio_rx_st2_hdr_parity          : out std_logic_vector(3 downto 0);                      -- hdr_parity
			ip2uio_rx_st2_hvalid              : out std_logic;                                         -- hvalid
			ip2uio_rx_st2_prefix              : out std_logic_vector(31 downto 0);                     -- prefix
			ip2uio_rx_st2_prefix_parity       : out std_logic_vector(0 downto 0);                      -- prefix_parity
			ip2uio_rx_st2_pvalid              : out std_logic;                                         -- pvalid
			ip2uio_rx_st2_bar                 : out std_logic_vector(2 downto 0);                      -- bar
			ip2uio_rx_st2_pfnum               : out std_logic_vector(2 downto 0);                      -- pfnum
			ip2uio_rx_st2_misc_parity         : out std_logic;                                         -- misc_parity
			ip2uio_rx_st2_empty               : out std_logic_vector(2 downto 0);                      -- empty
			ip2uio_rx_st3_dvalid              : out std_logic;                                         -- dvalid
			ip2uio_rx_st3_sop                 : out std_logic;                                         -- sop
			ip2uio_rx_st3_eop                 : out std_logic;                                         -- eop
			ip2uio_rx_st3_passthrough         : out std_logic;                                         -- passthrough
			ip2uio_rx_st3_data                : out std_logic_vector(255 downto 0);                    -- data
			ip2uio_rx_st3_data_parity         : out std_logic_vector(7 downto 0);                      -- data_parity
			ip2uio_rx_st3_hdr                 : out std_logic_vector(127 downto 0);                    -- hdr
			ip2uio_rx_st3_hdr_parity          : out std_logic_vector(3 downto 0);                      -- hdr_parity
			ip2uio_rx_st3_hvalid              : out std_logic;                                         -- hvalid
			ip2uio_rx_st3_prefix              : out std_logic_vector(31 downto 0);                     -- prefix
			ip2uio_rx_st3_prefix_parity       : out std_logic_vector(0 downto 0);                      -- prefix_parity
			ip2uio_rx_st3_pvalid              : out std_logic;                                         -- pvalid
			ip2uio_rx_st3_bar                 : out std_logic_vector(2 downto 0);                      -- bar
			ip2uio_rx_st3_pfnum               : out std_logic_vector(2 downto 0);                      -- pfnum
			ip2uio_rx_st3_misc_parity         : out std_logic;                                         -- misc_parity
			ip2uio_rx_st3_empty               : out std_logic_vector(2 downto 0);                      -- empty
			uio2ip_rx_st_Hcrdt_update         : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Hcrdt_update
			uio2ip_rx_st_Hcrdt_update_cnt     : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- Hcrdt_update_cnt
			uio2ip_rx_st_Hcrdt_init           : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Hcrdt_init
			ip2uio_rx_st_Hcrdt_init_ack       : out std_logic_vector(2 downto 0);                      -- Hcrdt_init_ack
			uio2ip_rx_st_Dcrdt_update         : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Dcrdt_update
			uio2ip_rx_st_Dcrdt_update_cnt     : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- Dcrdt_update_cnt
			uio2ip_rx_st_Dcrdt_init           : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- Dcrdt_init
			ip2uio_rx_st_Dcrdt_init_ack       : out std_logic_vector(2 downto 0);                      -- Dcrdt_init_ack
			ip2uio_bus_number                 : out std_logic_vector(7 downto 0);                      -- usr_bus_number
			ip2uio_device_number              : out std_logic_vector(4 downto 0);                      -- usr_device_number
			ip2cafu_axistd0_tvalid            : out std_logic;                                         -- td0_tvalid
			ip2cafu_axistd0_tdata             : out std_logic_vector(71 downto 0);                     -- td0_tdata
			ip2cafu_axistd0_tstrb             : out std_logic_vector(8 downto 0);                      -- td0_tstrb
			ip2cafu_axistd0_tdest             : out std_logic_vector(2 downto 0);                      -- td0_tdest
			ip2cafu_axistd0_tkeep             : out std_logic_vector(8 downto 0);                      -- td0_tkeep
			ip2cafu_axistd0_tlast             : out std_logic;                                         -- td0_tlast
			ip2cafu_axistd0_tid               : out std_logic_vector(7 downto 0);                      -- td0_tid
			ip2cafu_axistd0_tuser             : out std_logic_vector(7 downto 0);                      -- td0_tuser
			cafu2ip_axistd0_tready            : in  std_logic                      := 'X';             -- td0_tready
			ip2cafu_axisth0_tvalid            : out std_logic;                                         -- th0_tvalid
			ip2cafu_axisth0_tdata             : out std_logic_vector(71 downto 0);                     -- th0_tdata
			ip2cafu_axisth0_tstrb             : out std_logic_vector(8 downto 0);                      -- th0_tstrb
			ip2cafu_axisth0_tdest             : out std_logic_vector(2 downto 0);                      -- th0_tdest
			ip2cafu_axisth0_tkeep             : out std_logic_vector(8 downto 0);                      -- th0_tkeep
			ip2cafu_axisth0_tlast             : out std_logic;                                         -- th0_tlast
			ip2cafu_axisth0_tid               : out std_logic_vector(7 downto 0);                      -- th0_tid
			ip2cafu_axisth0_tuser             : out std_logic_vector(7 downto 0);                      -- th0_tuser
			cafu2ip_axisth0_tready            : in  std_logic                      := 'X';             -- th0_tready
			ip2cafu_axistd1_tvalid            : out std_logic;                                         -- td1_tvalid
			ip2cafu_axistd1_tdata             : out std_logic_vector(71 downto 0);                     -- td1_tdata
			ip2cafu_axistd1_tstrb             : out std_logic_vector(8 downto 0);                      -- td1_tstrb
			ip2cafu_axistd1_tdest             : out std_logic_vector(2 downto 0);                      -- td1_tdest
			ip2cafu_axistd1_tkeep             : out std_logic_vector(8 downto 0);                      -- td1_tkeep
			ip2cafu_axistd1_tlast             : out std_logic;                                         -- td1_tlast
			ip2cafu_axistd1_tid               : out std_logic_vector(7 downto 0);                      -- td1_tid
			ip2cafu_axistd1_tuser             : out std_logic_vector(7 downto 0);                      -- td1_tuser
			cafu2ip_axistd1_tready            : in  std_logic                      := 'X';             -- td1_tready
			ip2cafu_axisth1_tvalid            : out std_logic;                                         -- th1_tvalid
			ip2cafu_axisth1_tdata             : out std_logic_vector(71 downto 0);                     -- th1_tdata
			ip2cafu_axisth1_tstrb             : out std_logic_vector(8 downto 0);                      -- th1_tstrb
			ip2cafu_axisth1_tdest             : out std_logic_vector(2 downto 0);                      -- th1_tdest
			ip2cafu_axisth1_tkeep             : out std_logic_vector(8 downto 0);                      -- th1_tkeep
			ip2cafu_axisth1_tlast             : out std_logic;                                         -- th1_tlast
			ip2cafu_axisth1_tid               : out std_logic_vector(7 downto 0);                      -- th1_tid
			ip2cafu_axisth1_tuser             : out std_logic_vector(7 downto 0);                      -- th1_tuser
			cafu2ip_axisth1_tready            : in  std_logic                      := 'X';             -- th1_tready
			usr2ip_cxlreset_initiate          : in  std_logic                      := 'X';             -- cxlreset_initiate
			ip2usr_cxlreset_req               : out std_logic;                                         -- cxlreset_req
			usr2ip_cxlreset_ack               : in  std_logic                      := 'X';             -- cxlreset_ack
			ip2usr_cxlreset_error             : out std_logic;                                         -- cxlreset_error
			ip2usr_cxlreset_complete          : out std_logic;                                         -- cxlreset_complete
			usr2ip_app_err_valid              : in  std_logic                      := 'X';             -- err_valid
			usr2ip_app_err_hdr                : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- err_hdr
			usr2ip_app_err_info               : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- err_info
			usr2ip_app_err_func_num           : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- err_fn_num
			ip2usr_app_err_ready              : out std_logic;                                         -- err_rdy
			ip2usr_aermsg_correctable_valid   : out std_logic;                                         -- aermsg_correctable_valid
			ip2usr_aermsg_uncorrectable_valid : out std_logic;                                         -- aermsg_uncorrectable_valid
			ip2usr_aermsg_res                 : out std_logic;                                         -- aermsg_res
			ip2usr_aermsg_bts                 : out std_logic;                                         -- aermsg_bts
			ip2usr_aermsg_bds                 : out std_logic;                                         -- aermsg_bds
			ip2usr_aermsg_rrs                 : out std_logic;                                         -- aermsg_rrs
			ip2usr_aermsg_rtts                : out std_logic;                                         -- aermsg_rtts
			ip2usr_aermsg_anes                : out std_logic;                                         -- aermsg_anes
			ip2usr_aermsg_cies                : out std_logic;                                         -- aermsg_cies
			ip2usr_aermsg_hlos                : out std_logic;                                         -- aermsg_hlos
			ip2usr_aermsg_fmt                 : out std_logic_vector(1 downto 0);                      -- aermsg_fmt
			ip2usr_aermsg_type                : out std_logic_vector(4 downto 0);                      -- aermsg_type
			ip2usr_aermsg_tc                  : out std_logic_vector(2 downto 0);                      -- aermsg_tc
			ip2usr_aermsg_ido                 : out std_logic;                                         -- aermsg_ido
			ip2usr_aermsg_th                  : out std_logic;                                         -- aermsg_th
			ip2usr_aermsg_td                  : out std_logic;                                         -- aermsg_td
			ip2usr_aermsg_ep                  : out std_logic;                                         -- aermsg_ep
			ip2usr_aermsg_ro                  : out std_logic;                                         -- aermsg_ro
			ip2usr_aermsg_ns                  : out std_logic;                                         -- aermsg_ns
			ip2usr_aermsg_at                  : out std_logic_vector(1 downto 0);                      -- aermsg_at
			ip2usr_aermsg_length              : out std_logic_vector(9 downto 0);                      -- aermsg_length
			ip2usr_aermsg_header              : out std_logic_vector(95 downto 0);                     -- aermsg_header
			ip2usr_aermsg_und                 : out std_logic;                                         -- aermsg_und
			ip2usr_aermsg_anf                 : out std_logic;                                         -- aermsg_anf
			ip2usr_aermsg_dlpes               : out std_logic;                                         -- aermsg_dlpes
			ip2usr_aermsg_sdes                : out std_logic;                                         -- aermsg_sdes
			ip2usr_aermsg_fep                 : out std_logic_vector(4 downto 0);                      -- aermsg_fep
			ip2usr_aermsg_pts                 : out std_logic;                                         -- aermsg_pts
			ip2usr_aermsg_fcpes               : out std_logic;                                         -- aermsg_fcpes
			ip2usr_aermsg_cts                 : out std_logic;                                         -- aermsg_cts
			ip2usr_aermsg_cas                 : out std_logic;                                         -- aermsg_cas
			ip2usr_aermsg_ucs                 : out std_logic;                                         -- aermsg_ucs
			ip2usr_aermsg_ros                 : out std_logic;                                         -- aermsg_ros
			ip2usr_aermsg_mts                 : out std_logic;                                         -- aermsg_mts
			ip2usr_aermsg_uies                : out std_logic;                                         -- aermsg_uies
			ip2usr_aermsg_mbts                : out std_logic;                                         -- aermsg_mbts
			ip2usr_aermsg_aebs                : out std_logic;                                         -- aermsg_aebs
			ip2usr_aermsg_tpbes               : out std_logic;                                         -- aermsg_tpbes
			ip2usr_aermsg_ees                 : out std_logic;                                         -- aermsg_ees
			ip2usr_aermsg_ures                : out std_logic;                                         -- aermsg_ures
			ip2usr_aermsg_avs                 : out std_logic;                                         -- aermsg_avs
			ip2usr_serr_out                   : out std_logic;                                         -- serr_out
			ip2usr_debug_waitrequest          : out std_logic;                                         -- dbg_waitreq
			ip2usr_debug_readdata             : out std_logic_vector(31 downto 0);                     -- dbg_rddata
			ip2usr_debug_readdatavalid        : out std_logic;                                         -- dbg_drvalid
			usr2ip_debug_writedata            : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- dbg_wrad
			usr2ip_debug_address              : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- dbg_add
			usr2ip_debug_write                : in  std_logic                      := 'X';             -- dbg_wrt
			usr2ip_debug_read                 : in  std_logic                      := 'X';             -- dbg_read
			usr2ip_debug_byteenable           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- dbg_byten
			ip2hdm_aximm0_awvalid             : out std_logic;                                         -- awvalid
			ip2hdm_aximm0_awid                : out std_logic_vector(7 downto 0);                      -- awid
			ip2hdm_aximm0_awaddr              : out std_logic_vector(51 downto 0);                     -- awaddr
			ip2hdm_aximm0_awlen               : out std_logic_vector(9 downto 0);                      -- awlen
			ip2hdm_aximm0_awregion            : out std_logic_vector(3 downto 0);                      -- awregion
			ip2hdm_aximm0_awuser              : out std_logic;                                         -- awuser
			ip2hdm_aximm0_awsize              : out std_logic_vector(2 downto 0);                      -- awsize
			ip2hdm_aximm0_awburst             : out std_logic_vector(1 downto 0);                      -- awburst
			ip2hdm_aximm0_awprot              : out std_logic_vector(2 downto 0);                      -- awport
			ip2hdm_aximm0_awqos               : out std_logic_vector(3 downto 0);                      -- awqos
			ip2hdm_aximm0_awcache             : out std_logic_vector(3 downto 0);                      -- awcache
			ip2hdm_aximm0_awlock              : out std_logic_vector(1 downto 0);                      -- awlock
			hdm2ip_aximm0_awready             : in  std_logic                      := 'X';             -- awready
			ip2hdm_aximm0_wvalid              : out std_logic;                                         -- wvalid
			ip2hdm_aximm0_wdata               : out std_logic_vector(511 downto 0);                    -- wdata
			ip2hdm_aximm0_wstrb               : out std_logic_vector(63 downto 0);                     -- wstrb
			ip2hdm_aximm0_wlast               : out std_logic;                                         -- wlast
			ip2hdm_aximm0_wuser               : out std_logic;                                         -- wuser
			hdm2ip_aximm0_wready              : in  std_logic                      := 'X';             -- wready
			hdm2ip_aximm0_bvalid              : in  std_logic                      := 'X';             -- bvlaid
			hdm2ip_aximm0_bid                 : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- bid
			hdm2ip_aximm0_buser               : in  std_logic                      := 'X';             -- buser
			hdm2ip_aximm0_bresp               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- brsp
			ip2hdm_aximm0_bready              : out std_logic;                                         -- bready
			ip2hdm_aximm0_arvalid             : out std_logic;                                         -- arvalid
			ip2hdm_aximm0_arid                : out std_logic_vector(7 downto 0);                      -- arid
			ip2hdm_aximm0_araddr              : out std_logic_vector(51 downto 0);                     -- araddr
			ip2hdm_aximm0_arlen               : out std_logic_vector(9 downto 0);                      -- arlen
			ip2hdm_aximm0_arregion            : out std_logic_vector(3 downto 0);                      -- arregion
			ip2hdm_aximm0_aruser              : out std_logic;                                         -- aruser
			ip2hdm_aximm0_arsize              : out std_logic_vector(2 downto 0);                      -- arsize
			ip2hdm_aximm0_arburst             : out std_logic_vector(1 downto 0);                      -- arburst
			ip2hdm_aximm0_arprot              : out std_logic_vector(2 downto 0);                      -- arport
			ip2hdm_aximm0_arqos               : out std_logic_vector(3 downto 0);                      -- arqos
			ip2hdm_aximm0_arcache             : out std_logic_vector(3 downto 0);                      -- arcache
			ip2hdm_aximm0_arlock              : out std_logic_vector(1 downto 0);                      -- arlock
			hdm2ip_aximm0_arready             : in  std_logic                      := 'X';             -- arready
			hdm2ip_aximm0_rvalid              : in  std_logic                      := 'X';             -- rvalid
			hdm2ip_aximm0_rlast               : in  std_logic                      := 'X';             -- rlast
			hdm2ip_aximm0_rid                 : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rid
			hdm2ip_aximm0_rdata               : in  std_logic_vector(511 downto 0) := (others => 'X'); -- rdata
			hdm2ip_aximm0_ruser               : in  std_logic                      := 'X';             -- ruser
			hdm2ip_aximm0_rresp               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			ip2hdm_aximm0_rready              : out std_logic;                                         -- rready
			ip2hdm_aximm1_awvalid             : out std_logic;                                         -- awvalid
			ip2hdm_aximm1_awid                : out std_logic_vector(7 downto 0);                      -- awid
			ip2hdm_aximm1_awaddr              : out std_logic_vector(51 downto 0);                     -- awaddr
			ip2hdm_aximm1_awlen               : out std_logic_vector(9 downto 0);                      -- awlen
			ip2hdm_aximm1_awregion            : out std_logic_vector(3 downto 0);                      -- awregion
			ip2hdm_aximm1_awuser              : out std_logic;                                         -- awuser
			ip2hdm_aximm1_awsize              : out std_logic_vector(2 downto 0);                      -- awsize
			ip2hdm_aximm1_awburst             : out std_logic_vector(1 downto 0);                      -- awburst
			ip2hdm_aximm1_awprot              : out std_logic_vector(2 downto 0);                      -- awport
			ip2hdm_aximm1_awqos               : out std_logic_vector(3 downto 0);                      -- awqos
			ip2hdm_aximm1_awcache             : out std_logic_vector(3 downto 0);                      -- awcache
			ip2hdm_aximm1_awlock              : out std_logic_vector(1 downto 0);                      -- awlock
			hdm2ip_aximm1_awready             : in  std_logic                      := 'X';             -- awready
			ip2hdm_aximm1_wvalid              : out std_logic;                                         -- wvalid
			ip2hdm_aximm1_wdata               : out std_logic_vector(511 downto 0);                    -- wdata
			ip2hdm_aximm1_wstrb               : out std_logic_vector(63 downto 0);                     -- wstrb
			ip2hdm_aximm1_wlast               : out std_logic;                                         -- wlast
			ip2hdm_aximm1_wuser               : out std_logic;                                         -- wuser
			hdm2ip_aximm1_wready              : in  std_logic                      := 'X';             -- wready
			hdm2ip_aximm1_bvalid              : in  std_logic                      := 'X';             -- bvlaid
			hdm2ip_aximm1_bid                 : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- bid
			hdm2ip_aximm1_buser               : in  std_logic                      := 'X';             -- buser
			hdm2ip_aximm1_bresp               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- brsp
			ip2hdm_aximm1_bready              : out std_logic;                                         -- bready
			ip2hdm_aximm1_arvalid             : out std_logic;                                         -- arvalid
			ip2hdm_aximm1_arid                : out std_logic_vector(7 downto 0);                      -- arid
			ip2hdm_aximm1_araddr              : out std_logic_vector(51 downto 0);                     -- araddr
			ip2hdm_aximm1_arlen               : out std_logic_vector(9 downto 0);                      -- arlen
			ip2hdm_aximm1_arregion            : out std_logic_vector(3 downto 0);                      -- arregion
			ip2hdm_aximm1_aruser              : out std_logic;                                         -- aruser
			ip2hdm_aximm1_arsize              : out std_logic_vector(2 downto 0);                      -- arsize
			ip2hdm_aximm1_arburst             : out std_logic_vector(1 downto 0);                      -- arburst
			ip2hdm_aximm1_arprot              : out std_logic_vector(2 downto 0);                      -- arport
			ip2hdm_aximm1_arqos               : out std_logic_vector(3 downto 0);                      -- arqos
			ip2hdm_aximm1_arcache             : out std_logic_vector(3 downto 0);                      -- arcache
			ip2hdm_aximm1_arlock              : out std_logic_vector(1 downto 0);                      -- arlock
			hdm2ip_aximm1_arready             : in  std_logic                      := 'X';             -- arready
			hdm2ip_aximm1_rvalid              : in  std_logic                      := 'X';             -- rvalid
			hdm2ip_aximm1_rlast               : in  std_logic                      := 'X';             -- rlast
			hdm2ip_aximm1_rid                 : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rid
			hdm2ip_aximm1_rdata               : in  std_logic_vector(511 downto 0) := (others => 'X'); -- rdata
			hdm2ip_aximm1_ruser               : in  std_logic                      := 'X';             -- ruser
			hdm2ip_aximm1_rresp               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- rresp
			ip2hdm_aximm1_rready              : out std_logic;                                         -- rready
			ip2usr_gpf_ph2_req_o              : out std_logic;                                         -- gpf_req
			usr2ip_gpf_ph2_ack_i              : in  std_logic                      := 'X';             -- gpf_ack
			usr2ip_cache_evict_policy         : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- cache_evict_policy
			phy_sys_ial_0__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_0__pipe_Reset_l
			phy_sys_ial_1__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_1__pipe_Reset_l
			phy_sys_ial_2__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_2__pipe_Reset_l
			phy_sys_ial_3__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_3__pipe_Reset_l
			phy_sys_ial_4__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_4__pipe_Reset_l
			phy_sys_ial_5__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_5__pipe_Reset_l
			phy_sys_ial_6__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_6__pipe_Reset_l
			phy_sys_ial_7__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_7__pipe_Reset_l
			phy_sys_ial_8__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_8__pipe_Reset_l
			phy_sys_ial_9__pipe_Reset_l       : out std_logic;                                         -- if_phy_sys_ial_9__pipe_Reset_l
			phy_sys_ial_10__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_10__pipe_Reset_l
			phy_sys_ial_11__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_11__pipe_Reset_l
			phy_sys_ial_12__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_12__pipe_Reset_l
			phy_sys_ial_13__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_13__pipe_Reset_l
			phy_sys_ial_14__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_14__pipe_Reset_l
			phy_sys_ial_15__pipe_Reset_l      : out std_logic;                                         -- if_phy_sys_ial_15__pipe_Reset_l
			o_phy_0_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_0_pipe_TxDataValid
			o_phy_0_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_0_pipe_TxData
			o_phy_0_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_0_pipe_TxDetRxLpbk
			o_phy_0_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_0_pipe_TxElecIdle
			o_phy_0_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_0_pipe_PowerDown
			o_phy_0_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_0_pipe_Rate
			o_phy_0_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_0_pipe_PclkChangeAck
			o_phy_0_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_0_pipe_PCLKRate
			o_phy_0_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_0_pipe_Width
			o_phy_0_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_0_pipe_PCLK
			o_phy_0_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_0_pipe_rxelecidle_disable
			o_phy_0_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_0_pipe_txcmnmode_disable
			o_phy_0_pipe_srisenable           : out std_logic;                                         -- if_o_phy_0_pipe_srisenable
			i_phy_0_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_RxClk
			i_phy_0_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_RxValid
			i_phy_0_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_0_pipe_RxData
			i_phy_0_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_RxElecIdle
			i_phy_0_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_0_pipe_RxStatus
			i_phy_0_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_RxStandbyStatus
			o_phy_0_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_0_pipe_RxStandby
			o_phy_0_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_0_pipe_RxTermination
			o_phy_0_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_0_pipe_RxWidth
			i_phy_0_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_PhyStatus
			i_phy_0_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_PclkChangeOk
			o_phy_0_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_0_pipe_M2P_MessageBus
			i_phy_0_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_0_pipe_P2M_MessageBus
			o_phy_1_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_1_pipe_TxDataValid
			o_phy_1_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_1_pipe_TxData
			o_phy_1_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_1_pipe_TxDetRxLpbk
			o_phy_1_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_1_pipe_TxElecIdle
			o_phy_1_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_1_pipe_PowerDown
			o_phy_1_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_1_pipe_Rate
			o_phy_1_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_1_pipe_PclkChangeAck
			o_phy_1_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_1_pipe_PCLKRate
			o_phy_1_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_1_pipe_Width
			o_phy_1_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_1_pipe_PCLK
			o_phy_1_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_1_pipe_rxelecidle_disable
			o_phy_1_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_1_pipe_txcmnmode_disable
			o_phy_1_pipe_srisenable           : out std_logic;                                         -- if_o_phy_1_pipe_srisenable
			i_phy_1_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_RxClk
			i_phy_1_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_RxValid
			i_phy_1_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_1_pipe_RxData
			i_phy_1_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_RxElecIdle
			i_phy_1_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_1_pipe_RxStatus
			i_phy_1_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_RxStandbyStatus
			o_phy_1_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_1_pipe_RxStandby
			o_phy_1_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_1_pipe_RxTermination
			o_phy_1_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_1_pipe_RxWidth
			i_phy_1_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_PhyStatus
			i_phy_1_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_PclkChangeOk
			o_phy_1_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_1_pipe_M2P_MessageBus
			i_phy_1_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_1_pipe_P2M_MessageBus
			o_phy_2_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_2_pipe_TxDataValid
			o_phy_2_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_2_pipe_TxData
			o_phy_2_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_2_pipe_TxDetRxLpbk
			o_phy_2_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_2_pipe_TxElecIdle
			o_phy_2_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_2_pipe_PowerDown
			o_phy_2_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_2_pipe_Rate
			o_phy_2_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_2_pipe_PclkChangeAck
			o_phy_2_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_2_pipe_PCLKRate
			o_phy_2_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_2_pipe_Width
			o_phy_2_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_2_pipe_PCLK
			o_phy_2_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_2_pipe_rxelecidle_disable
			o_phy_2_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_2_pipe_txcmnmode_disable
			o_phy_2_pipe_srisenable           : out std_logic;                                         -- if_o_phy_2_pipe_srisenable
			i_phy_2_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_RxClk
			i_phy_2_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_RxValid
			i_phy_2_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_2_pipe_RxData
			i_phy_2_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_RxElecIdle
			i_phy_2_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_2_pipe_RxStatus
			i_phy_2_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_RxStandbyStatus
			o_phy_2_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_2_pipe_RxStandby
			o_phy_2_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_2_pipe_RxTermination
			o_phy_2_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_2_pipe_RxWidth
			i_phy_2_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_PhyStatus
			i_phy_2_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_PclkChangeOk
			o_phy_2_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_2_pipe_M2P_MessageBus
			i_phy_2_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_2_pipe_P2M_MessageBus
			o_phy_3_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_3_pipe_TxDataValid
			o_phy_3_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_3_pipe_TxData
			o_phy_3_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_3_pipe_TxDetRxLpbk
			o_phy_3_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_3_pipe_TxElecIdle
			o_phy_3_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_3_pipe_PowerDown
			o_phy_3_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_3_pipe_Rate
			o_phy_3_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_3_pipe_PclkChangeAck
			o_phy_3_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_3_pipe_PCLKRate
			o_phy_3_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_3_pipe_Width
			o_phy_3_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_3_pipe_PCLK
			o_phy_3_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_3_pipe_rxelecidle_disable
			o_phy_3_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_3_pipe_txcmnmode_disable
			o_phy_3_pipe_srisenable           : out std_logic;                                         -- if_o_phy_3_pipe_srisenable
			i_phy_3_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_RxClk
			i_phy_3_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_RxValid
			i_phy_3_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_3_pipe_RxData
			i_phy_3_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_RxElecIdle
			i_phy_3_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_3_pipe_RxStatus
			i_phy_3_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_RxStandbyStatus
			o_phy_3_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_3_pipe_RxStandby
			o_phy_3_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_3_pipe_RxTermination
			o_phy_3_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_3_pipe_RxWidth
			i_phy_3_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_PhyStatus
			i_phy_3_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_PclkChangeOk
			o_phy_3_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_3_pipe_M2P_MessageBus
			i_phy_3_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_3_pipe_P2M_MessageBus
			o_phy_4_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_4_pipe_TxDataValid
			o_phy_4_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_4_pipe_TxData
			o_phy_4_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_4_pipe_TxDetRxLpbk
			o_phy_4_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_4_pipe_TxElecIdle
			o_phy_4_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_4_pipe_PowerDown
			o_phy_4_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_4_pipe_Rate
			o_phy_4_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_4_pipe_PclkChangeAck
			o_phy_4_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_4_pipe_PCLKRate
			o_phy_4_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_4_pipe_Width
			o_phy_4_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_4_pipe_PCLK
			o_phy_4_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_4_pipe_rxelecidle_disable
			o_phy_4_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_4_pipe_txcmnmode_disable
			o_phy_4_pipe_srisenable           : out std_logic;                                         -- if_o_phy_4_pipe_srisenable
			i_phy_4_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_RxClk
			i_phy_4_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_RxValid
			i_phy_4_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_4_pipe_RxData
			i_phy_4_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_RxElecIdle
			i_phy_4_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_4_pipe_RxStatus
			i_phy_4_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_RxStandbyStatus
			o_phy_4_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_4_pipe_RxStandby
			o_phy_4_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_4_pipe_RxTermination
			o_phy_4_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_4_pipe_RxWidth
			i_phy_4_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_PhyStatus
			i_phy_4_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_PclkChangeOk
			o_phy_4_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_4_pipe_M2P_MessageBus
			i_phy_4_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_4_pipe_P2M_MessageBus
			o_phy_5_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_5_pipe_TxDataValid
			o_phy_5_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_5_pipe_TxData
			o_phy_5_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_5_pipe_TxDetRxLpbk
			o_phy_5_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_5_pipe_TxElecIdle
			o_phy_5_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_5_pipe_PowerDown
			o_phy_5_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_5_pipe_Rate
			o_phy_5_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_5_pipe_PclkChangeAck
			o_phy_5_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_5_pipe_PCLKRate
			o_phy_5_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_5_pipe_Width
			o_phy_5_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_5_pipe_PCLK
			o_phy_5_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_5_pipe_rxelecidle_disable
			o_phy_5_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_5_pipe_txcmnmode_disable
			o_phy_5_pipe_srisenable           : out std_logic;                                         -- if_o_phy_5_pipe_srisenable
			i_phy_5_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_RxClk
			i_phy_5_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_RxValid
			i_phy_5_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_5_pipe_RxData
			i_phy_5_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_RxElecIdle
			i_phy_5_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_5_pipe_RxStatus
			i_phy_5_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_RxStandbyStatus
			o_phy_5_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_5_pipe_RxStandby
			o_phy_5_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_5_pipe_RxTermination
			o_phy_5_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_5_pipe_RxWidth
			i_phy_5_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_PhyStatus
			i_phy_5_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_PclkChangeOk
			o_phy_5_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_5_pipe_M2P_MessageBus
			i_phy_5_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_5_pipe_P2M_MessageBus
			o_phy_6_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_6_pipe_TxDataValid
			o_phy_6_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_6_pipe_TxData
			o_phy_6_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_6_pipe_TxDetRxLpbk
			o_phy_6_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_6_pipe_TxElecIdle
			o_phy_6_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_6_pipe_PowerDown
			o_phy_6_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_6_pipe_Rate
			o_phy_6_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_6_pipe_PclkChangeAck
			o_phy_6_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_6_pipe_PCLKRate
			o_phy_6_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_6_pipe_Width
			o_phy_6_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_6_pipe_PCLK
			o_phy_6_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_6_pipe_rxelecidle_disable
			o_phy_6_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_6_pipe_txcmnmode_disable
			o_phy_6_pipe_srisenable           : out std_logic;                                         -- if_o_phy_6_pipe_srisenable
			i_phy_6_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_RxClk
			i_phy_6_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_RxValid
			i_phy_6_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_6_pipe_RxData
			i_phy_6_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_RxElecIdle
			i_phy_6_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_6_pipe_RxStatus
			i_phy_6_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_RxStandbyStatus
			o_phy_6_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_6_pipe_RxStandby
			o_phy_6_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_6_pipe_RxTermination
			o_phy_6_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_6_pipe_RxWidth
			i_phy_6_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_PhyStatus
			i_phy_6_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_PclkChangeOk
			o_phy_6_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_6_pipe_M2P_MessageBus
			i_phy_6_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_6_pipe_P2M_MessageBus
			o_phy_7_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_7_pipe_TxDataValid
			o_phy_7_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_7_pipe_TxData
			o_phy_7_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_7_pipe_TxDetRxLpbk
			o_phy_7_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_7_pipe_TxElecIdle
			o_phy_7_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_7_pipe_PowerDown
			o_phy_7_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_7_pipe_Rate
			o_phy_7_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_7_pipe_PclkChangeAck
			o_phy_7_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_7_pipe_PCLKRate
			o_phy_7_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_7_pipe_Width
			o_phy_7_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_7_pipe_PCLK
			o_phy_7_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_7_pipe_rxelecidle_disable
			o_phy_7_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_7_pipe_txcmnmode_disable
			o_phy_7_pipe_srisenable           : out std_logic;                                         -- if_o_phy_7_pipe_srisenable
			i_phy_7_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_RxClk
			i_phy_7_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_RxValid
			i_phy_7_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_7_pipe_RxData
			i_phy_7_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_RxElecIdle
			i_phy_7_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_7_pipe_RxStatus
			i_phy_7_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_RxStandbyStatus
			o_phy_7_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_7_pipe_RxStandby
			o_phy_7_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_7_pipe_RxTermination
			o_phy_7_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_7_pipe_RxWidth
			i_phy_7_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_PhyStatus
			i_phy_7_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_PclkChangeOk
			o_phy_7_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_7_pipe_M2P_MessageBus
			i_phy_7_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_7_pipe_P2M_MessageBus
			o_phy_8_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_8_pipe_TxDataValid
			o_phy_8_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_8_pipe_TxData
			o_phy_8_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_8_pipe_TxDetRxLpbk
			o_phy_8_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_8_pipe_TxElecIdle
			o_phy_8_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_8_pipe_PowerDown
			o_phy_8_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_8_pipe_Rate
			o_phy_8_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_8_pipe_PclkChangeAck
			o_phy_8_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_8_pipe_PCLKRate
			o_phy_8_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_8_pipe_Width
			o_phy_8_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_8_pipe_PCLK
			o_phy_8_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_8_pipe_rxelecidle_disable
			o_phy_8_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_8_pipe_txcmnmode_disable
			o_phy_8_pipe_srisenable           : out std_logic;                                         -- if_o_phy_8_pipe_srisenable
			i_phy_8_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_RxClk
			i_phy_8_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_RxValid
			i_phy_8_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_8_pipe_RxData
			i_phy_8_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_RxElecIdle
			i_phy_8_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_8_pipe_RxStatus
			i_phy_8_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_RxStandbyStatus
			o_phy_8_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_8_pipe_RxStandby
			o_phy_8_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_8_pipe_RxTermination
			o_phy_8_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_8_pipe_RxWidth
			i_phy_8_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_PhyStatus
			i_phy_8_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_PclkChangeOk
			o_phy_8_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_8_pipe_M2P_MessageBus
			i_phy_8_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_8_pipe_P2M_MessageBus
			o_phy_9_pipe_TxDataValid          : out std_logic;                                         -- if_o_phy_9_pipe_TxDataValid
			o_phy_9_pipe_TxData               : out std_logic_vector(39 downto 0);                     -- if_o_phy_9_pipe_TxData
			o_phy_9_pipe_TxDetRxLpbk          : out std_logic;                                         -- if_o_phy_9_pipe_TxDetRxLpbk
			o_phy_9_pipe_TxElecIdle           : out std_logic_vector(3 downto 0);                      -- if_o_phy_9_pipe_TxElecIdle
			o_phy_9_pipe_PowerDown            : out std_logic_vector(3 downto 0);                      -- if_o_phy_9_pipe_PowerDown
			o_phy_9_pipe_Rate                 : out std_logic_vector(2 downto 0);                      -- if_o_phy_9_pipe_Rate
			o_phy_9_pipe_PclkChangeAck        : out std_logic;                                         -- if_o_phy_9_pipe_PclkChangeAck
			o_phy_9_pipe_PCLKRate             : out std_logic_vector(2 downto 0);                      -- if_o_phy_9_pipe_PCLKRate
			o_phy_9_pipe_Width                : out std_logic_vector(1 downto 0);                      -- if_o_phy_9_pipe_Width
			o_phy_9_pipe_PCLK                 : out std_logic;                                         -- if_o_phy_9_pipe_PCLK
			o_phy_9_pipe_rxelecidle_disable   : out std_logic;                                         -- if_o_phy_9_pipe_rxelecidle_disable
			o_phy_9_pipe_txcmnmode_disable    : out std_logic;                                         -- if_o_phy_9_pipe_txcmnmode_disable
			o_phy_9_pipe_srisenable           : out std_logic;                                         -- if_o_phy_9_pipe_srisenable
			i_phy_9_pipe_RxClk                : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_RxClk
			i_phy_9_pipe_RxValid              : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_RxValid
			i_phy_9_pipe_RxData               : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_9_pipe_RxData
			i_phy_9_pipe_RxElecIdle           : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_RxElecIdle
			i_phy_9_pipe_RxStatus             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_9_pipe_RxStatus
			i_phy_9_pipe_RxStandbyStatus      : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_RxStandbyStatus
			o_phy_9_pipe_RxStandby            : out std_logic;                                         -- if_o_phy_9_pipe_RxStandby
			o_phy_9_pipe_RxTermination        : out std_logic;                                         -- if_o_phy_9_pipe_RxTermination
			o_phy_9_pipe_RxWidth              : out std_logic_vector(1 downto 0);                      -- if_o_phy_9_pipe_RxWidth
			i_phy_9_pipe_PhyStatus            : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_PhyStatus
			i_phy_9_pipe_PclkChangeOk         : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_PclkChangeOk
			o_phy_9_pipe_M2P_MessageBus       : out std_logic_vector(7 downto 0);                      -- if_o_phy_9_pipe_M2P_MessageBus
			i_phy_9_pipe_P2M_MessageBus       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_9_pipe_P2M_MessageBus
			o_phy_10_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_10_pipe_TxDataValid
			o_phy_10_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_10_pipe_TxData
			o_phy_10_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_10_pipe_TxDetRxLpbk
			o_phy_10_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_10_pipe_TxElecIdle
			o_phy_10_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_10_pipe_PowerDown
			o_phy_10_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_10_pipe_Rate
			o_phy_10_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_10_pipe_PclkChangeAck
			o_phy_10_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_10_pipe_PCLKRate
			o_phy_10_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_10_pipe_Width
			o_phy_10_pipe_PCLK                : out std_logic;                                         -- if_o_phy_10_pipe_PCLK
			o_phy_10_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_10_pipe_rxelecidle_disable
			o_phy_10_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_10_pipe_txcmnmode_disable
			o_phy_10_pipe_srisenable          : out std_logic;                                         -- if_o_phy_10_pipe_srisenable
			i_phy_10_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_RxClk
			i_phy_10_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_RxValid
			i_phy_10_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_10_pipe_RxData
			i_phy_10_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_RxElecIdle
			i_phy_10_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_10_pipe_RxStatus
			i_phy_10_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_RxStandbyStatus
			o_phy_10_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_10_pipe_RxStandby
			o_phy_10_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_10_pipe_RxTermination
			o_phy_10_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_10_pipe_RxWidth
			i_phy_10_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_PhyStatus
			i_phy_10_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_PclkChangeOk
			o_phy_10_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_10_pipe_M2P_MessageBus
			i_phy_10_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_10_pipe_P2M_MessageBus
			o_phy_11_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_11_pipe_TxDataValid
			o_phy_11_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_11_pipe_TxData
			o_phy_11_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_11_pipe_TxDetRxLpbk
			o_phy_11_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_11_pipe_TxElecIdle
			o_phy_11_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_11_pipe_PowerDown
			o_phy_11_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_11_pipe_Rate
			o_phy_11_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_11_pipe_PclkChangeAck
			o_phy_11_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_11_pipe_PCLKRate
			o_phy_11_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_11_pipe_Width
			o_phy_11_pipe_PCLK                : out std_logic;                                         -- if_o_phy_11_pipe_PCLK
			o_phy_11_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_11_pipe_rxelecidle_disable
			o_phy_11_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_11_pipe_txcmnmode_disable
			o_phy_11_pipe_srisenable          : out std_logic;                                         -- if_o_phy_11_pipe_srisenable
			i_phy_11_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_RxClk
			i_phy_11_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_RxValid
			i_phy_11_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_11_pipe_RxData
			i_phy_11_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_RxElecIdle
			i_phy_11_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_11_pipe_RxStatus
			i_phy_11_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_RxStandbyStatus
			o_phy_11_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_11_pipe_RxStandby
			o_phy_11_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_11_pipe_RxTermination
			o_phy_11_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_11_pipe_RxWidth
			i_phy_11_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_PhyStatus
			i_phy_11_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_PclkChangeOk
			o_phy_11_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_11_pipe_M2P_MessageBus
			i_phy_11_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_11_pipe_P2M_MessageBus
			o_phy_12_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_12_pipe_TxDataValid
			o_phy_12_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_12_pipe_TxData
			o_phy_12_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_12_pipe_TxDetRxLpbk
			o_phy_12_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_12_pipe_TxElecIdle
			o_phy_12_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_12_pipe_PowerDown
			o_phy_12_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_12_pipe_Rate
			o_phy_12_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_12_pipe_PclkChangeAck
			o_phy_12_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_12_pipe_PCLKRate
			o_phy_12_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_12_pipe_Width
			o_phy_12_pipe_PCLK                : out std_logic;                                         -- if_o_phy_12_pipe_PCLK
			o_phy_12_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_12_pipe_rxelecidle_disable
			o_phy_12_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_12_pipe_txcmnmode_disable
			o_phy_12_pipe_srisenable          : out std_logic;                                         -- if_o_phy_12_pipe_srisenable
			i_phy_12_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_RxClk
			i_phy_12_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_RxValid
			i_phy_12_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_12_pipe_RxData
			i_phy_12_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_RxElecIdle
			i_phy_12_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_12_pipe_RxStatus
			i_phy_12_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_RxStandbyStatus
			o_phy_12_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_12_pipe_RxStandby
			o_phy_12_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_12_pipe_RxTermination
			o_phy_12_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_12_pipe_RxWidth
			i_phy_12_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_PhyStatus
			i_phy_12_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_PclkChangeOk
			o_phy_12_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_12_pipe_M2P_MessageBus
			i_phy_12_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_12_pipe_P2M_MessageBus
			o_phy_13_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_13_pipe_TxDataValid
			o_phy_13_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_13_pipe_TxData
			o_phy_13_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_13_pipe_TxDetRxLpbk
			o_phy_13_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_13_pipe_TxElecIdle
			o_phy_13_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_13_pipe_PowerDown
			o_phy_13_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_13_pipe_Rate
			o_phy_13_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_13_pipe_PclkChangeAck
			o_phy_13_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_13_pipe_PCLKRate
			o_phy_13_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_13_pipe_Width
			o_phy_13_pipe_PCLK                : out std_logic;                                         -- if_o_phy_13_pipe_PCLK
			o_phy_13_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_13_pipe_rxelecidle_disable
			o_phy_13_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_13_pipe_txcmnmode_disable
			o_phy_13_pipe_srisenable          : out std_logic;                                         -- if_o_phy_13_pipe_srisenable
			i_phy_13_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_RxClk
			i_phy_13_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_RxValid
			i_phy_13_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_13_pipe_RxData
			i_phy_13_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_RxElecIdle
			i_phy_13_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_13_pipe_RxStatus
			i_phy_13_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_RxStandbyStatus
			o_phy_13_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_13_pipe_RxStandby
			o_phy_13_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_13_pipe_RxTermination
			o_phy_13_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_13_pipe_RxWidth
			i_phy_13_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_PhyStatus
			i_phy_13_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_PclkChangeOk
			o_phy_13_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_13_pipe_M2P_MessageBus
			i_phy_13_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_13_pipe_P2M_MessageBus
			o_phy_14_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_14_pipe_TxDataValid
			o_phy_14_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_14_pipe_TxData
			o_phy_14_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_14_pipe_TxDetRxLpbk
			o_phy_14_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_14_pipe_TxElecIdle
			o_phy_14_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_14_pipe_PowerDown
			o_phy_14_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_14_pipe_Rate
			o_phy_14_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_14_pipe_PclkChangeAck
			o_phy_14_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_14_pipe_PCLKRate
			o_phy_14_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_14_pipe_Width
			o_phy_14_pipe_PCLK                : out std_logic;                                         -- if_o_phy_14_pipe_PCLK
			o_phy_14_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_14_pipe_rxelecidle_disable
			o_phy_14_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_14_pipe_txcmnmode_disable
			o_phy_14_pipe_srisenable          : out std_logic;                                         -- if_o_phy_14_pipe_srisenable
			i_phy_14_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_RxClk
			i_phy_14_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_RxValid
			i_phy_14_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_14_pipe_RxData
			i_phy_14_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_RxElecIdle
			i_phy_14_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_14_pipe_RxStatus
			i_phy_14_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_RxStandbyStatus
			o_phy_14_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_14_pipe_RxStandby
			o_phy_14_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_14_pipe_RxTermination
			o_phy_14_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_14_pipe_RxWidth
			i_phy_14_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_PhyStatus
			i_phy_14_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_PclkChangeOk
			o_phy_14_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_14_pipe_M2P_MessageBus
			i_phy_14_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_14_pipe_P2M_MessageBus
			o_phy_15_pipe_TxDataValid         : out std_logic;                                         -- if_o_phy_15_pipe_TxDataValid
			o_phy_15_pipe_TxData              : out std_logic_vector(39 downto 0);                     -- if_o_phy_15_pipe_TxData
			o_phy_15_pipe_TxDetRxLpbk         : out std_logic;                                         -- if_o_phy_15_pipe_TxDetRxLpbk
			o_phy_15_pipe_TxElecIdle          : out std_logic_vector(3 downto 0);                      -- if_o_phy_15_pipe_TxElecIdle
			o_phy_15_pipe_PowerDown           : out std_logic_vector(3 downto 0);                      -- if_o_phy_15_pipe_PowerDown
			o_phy_15_pipe_Rate                : out std_logic_vector(2 downto 0);                      -- if_o_phy_15_pipe_Rate
			o_phy_15_pipe_PclkChangeAck       : out std_logic;                                         -- if_o_phy_15_pipe_PclkChangeAck
			o_phy_15_pipe_PCLKRate            : out std_logic_vector(2 downto 0);                      -- if_o_phy_15_pipe_PCLKRate
			o_phy_15_pipe_Width               : out std_logic_vector(1 downto 0);                      -- if_o_phy_15_pipe_Width
			o_phy_15_pipe_PCLK                : out std_logic;                                         -- if_o_phy_15_pipe_PCLK
			o_phy_15_pipe_rxelecidle_disable  : out std_logic;                                         -- if_o_phy_15_pipe_rxelecidle_disable
			o_phy_15_pipe_txcmnmode_disable   : out std_logic;                                         -- if_o_phy_15_pipe_txcmnmode_disable
			o_phy_15_pipe_srisenable          : out std_logic;                                         -- if_o_phy_15_pipe_srisenable
			i_phy_15_pipe_RxClk               : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_RxClk
			i_phy_15_pipe_RxValid             : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_RxValid
			i_phy_15_pipe_RxData              : in  std_logic_vector(39 downto 0)  := (others => 'X'); -- if_i_phy_15_pipe_RxData
			i_phy_15_pipe_RxElecIdle          : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_RxElecIdle
			i_phy_15_pipe_RxStatus            : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- if_i_phy_15_pipe_RxStatus
			i_phy_15_pipe_RxStandbyStatus     : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_RxStandbyStatus
			o_phy_15_pipe_RxStandby           : out std_logic;                                         -- if_o_phy_15_pipe_RxStandby
			o_phy_15_pipe_RxTermination       : out std_logic;                                         -- if_o_phy_15_pipe_RxTermination
			o_phy_15_pipe_RxWidth             : out std_logic_vector(1 downto 0);                      -- if_o_phy_15_pipe_RxWidth
			i_phy_15_pipe_PhyStatus           : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_PhyStatus
			i_phy_15_pipe_PclkChangeOk        : in  std_logic                      := 'X';             -- if_i_phy_15_pipe_PclkChangeOk
			o_phy_15_pipe_M2P_MessageBus      : out std_logic_vector(7 downto 0);                      -- if_o_phy_15_pipe_M2P_MessageBus
			i_phy_15_pipe_P2M_MessageBus      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- if_i_phy_15_pipe_P2M_MessageBus
			o_phy_0_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_0_pipe_rxbitslip_req
			o_phy_0_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_0_pipe_rxbitslip_va
			i_phy_0_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_0_pipe_RxBitSlip_Ack
			o_phy_1_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_1_pipe_rxbitslip_req
			o_phy_1_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_1_pipe_rxbitslip_va
			i_phy_1_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_1_pipe_RxBitSlip_Ack
			o_phy_2_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_2_pipe_rxbitslip_req
			o_phy_2_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_2_pipe_rxbitslip_va
			i_phy_2_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_2_pipe_RxBitSlip_Ack
			o_phy_3_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_3_pipe_rxbitslip_req
			o_phy_3_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_3_pipe_rxbitslip_va
			i_phy_3_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_3_pipe_RxBitSlip_Ack
			o_phy_4_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_4_pipe_rxbitslip_req
			o_phy_4_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_4_pipe_rxbitslip_va
			i_phy_4_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_4_pipe_RxBitSlip_Ack
			o_phy_5_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_5_pipe_rxbitslip_req
			o_phy_5_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_5_pipe_rxbitslip_va
			i_phy_5_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_5_pipe_RxBitSlip_Ack
			o_phy_6_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_6_pipe_rxbitslip_req
			o_phy_6_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_6_pipe_rxbitslip_va
			i_phy_6_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_6_pipe_RxBitSlip_Ack
			o_phy_7_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_7_pipe_rxbitslip_req
			o_phy_7_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_7_pipe_rxbitslip_va
			i_phy_7_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_7_pipe_RxBitSlip_Ack
			o_phy_8_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_8_pipe_rxbitslip_req
			o_phy_8_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_8_pipe_rxbitslip_va
			i_phy_8_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_8_pipe_RxBitSlip_Ack
			o_phy_9_pipe_rxbitslip_req        : out std_logic;                                         -- if_o_phy_9_pipe_rxbitslip_req
			o_phy_9_pipe_rxbitslip_va         : out std_logic_vector(4 downto 0);                      -- if_o_phy_9_pipe_rxbitslip_va
			i_phy_9_pipe_RxBitSlip_Ack        : in  std_logic                      := 'X';             -- if_i_phy_9_pipe_RxBitSlip_Ack
			o_phy_10_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_10_pipe_rxbitslip_req
			o_phy_10_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_10_pipe_rxbitslip_va
			i_phy_10_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X';             -- if_i_phy_10_pipe_RxBitSlip_Ack
			o_phy_11_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_11_pipe_rxbitslip_req
			o_phy_11_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_11_pipe_rxbitslip_va
			i_phy_11_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X';             -- if_i_phy_11_pipe_RxBitSlip_Ack
			o_phy_12_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_12_pipe_rxbitslip_req
			o_phy_12_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_12_pipe_rxbitslip_va
			i_phy_12_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X';             -- if_i_phy_12_pipe_RxBitSlip_Ack
			o_phy_13_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_13_pipe_rxbitslip_req
			o_phy_13_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_13_pipe_rxbitslip_va
			i_phy_13_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X';             -- if_i_phy_13_pipe_RxBitSlip_Ack
			o_phy_14_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_14_pipe_rxbitslip_req
			o_phy_14_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_14_pipe_rxbitslip_va
			i_phy_14_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X';             -- if_i_phy_14_pipe_RxBitSlip_Ack
			o_phy_15_pipe_rxbitslip_req       : out std_logic;                                         -- if_o_phy_15_pipe_rxbitslip_req
			o_phy_15_pipe_rxbitslip_va        : out std_logic_vector(4 downto 0);                      -- if_o_phy_15_pipe_rxbitslip_va
			i_phy_15_pipe_RxBitSlip_Ack       : in  std_logic                      := 'X'              -- if_i_phy_15_pipe_RxBitSlip_Ack
		);
	end component intel_rtile_cxl_top_cxltyp2_ed;

	u0 : component intel_rtile_cxl_top_cxltyp2_ed
		port map (
			refclk0                           => CONNECTED_TO_refclk0,                           --             refclk0.clk
			refclk1                           => CONNECTED_TO_refclk1,                           --             refclk1.clk
			refclk4                           => CONNECTED_TO_refclk4,                           --             refclk4.clk
			resetn                            => CONNECTED_TO_resetn,                            --              resetn.reset_n
			nInit_done                        => CONNECTED_TO_nInit_done,                        --          ninit_done.ninit_done
			pll_lock_o                        => CONNECTED_TO_pll_lock_o,                        --                 pll.pll_lock_o
			usr2ip_qos_devload                => CONNECTED_TO_usr2ip_qos_devload,                --         qos_devload.usr2ip_qos_devload
			ip2hdm_clk                        => CONNECTED_TO_ip2hdm_clk,                        --          ip2hdm_clk.clk
			ip2hdm_reset_n                    => CONNECTED_TO_ip2hdm_reset_n,                    --      ip2hdm_reset_n.reset_n
			cxl_warm_rst_n                    => CONNECTED_TO_cxl_warm_rst_n,                    --      cxl_warm_rst_n.reset_n
			cxl_cold_rst_n                    => CONNECTED_TO_cxl_cold_rst_n,                    --      cxl_cold_rst_n.reset_n
			mc2ip_memsize                     => CONNECTED_TO_mc2ip_memsize,                     --            hdm_size.mem_size_t
			cxl_rx_n                          => CONNECTED_TO_cxl_rx_n,                          --              cxl_rx.cxl_rx_n
			cxl_rx_p                          => CONNECTED_TO_cxl_rx_p,                          --                    .cxl_rx_p
			cxl_tx_n                          => CONNECTED_TO_cxl_tx_n,                          --              cxl_tx.cxl_tx_n
			cxl_tx_p                          => CONNECTED_TO_cxl_tx_p,                          --                    .cxl_tx_p
			mc2ip_0_sr_status                 => CONNECTED_TO_mc2ip_0_sr_status,                 --             mc2ip_0.mc_sr_status
			mc2ip_1_sr_status                 => CONNECTED_TO_mc2ip_1_sr_status,                 --             mc2ip_1.mc_sr_status
			ip2cafu_quiesce_req               => CONNECTED_TO_ip2cafu_quiesce_req,               --             quiesce.quiesce_req
			cafu2ip_quiesce_ack               => CONNECTED_TO_cafu2ip_quiesce_ack,               --                    .quiesce_ack
			cafu2ip_aximm0_awid               => CONNECTED_TO_cafu2ip_aximm0_awid,               -- axi2ccip_wraddr_ch0.awid
			cafu2ip_aximm0_awaddr             => CONNECTED_TO_cafu2ip_aximm0_awaddr,             --                    .awaddr
			cafu2ip_aximm0_awlen              => CONNECTED_TO_cafu2ip_aximm0_awlen,              --                    .awlen
			cafu2ip_aximm0_awsize             => CONNECTED_TO_cafu2ip_aximm0_awsize,             --                    .awsize
			cafu2ip_aximm0_awburst            => CONNECTED_TO_cafu2ip_aximm0_awburst,            --                    .awburst
			cafu2ip_aximm0_awprot             => CONNECTED_TO_cafu2ip_aximm0_awprot,             --                    .awprot
			cafu2ip_aximm0_awqos              => CONNECTED_TO_cafu2ip_aximm0_awqos,              --                    .awqos
			cafu2ip_aximm0_awuser             => CONNECTED_TO_cafu2ip_aximm0_awuser,             --                    .awuser
			cafu2ip_aximm0_awvalid            => CONNECTED_TO_cafu2ip_aximm0_awvalid,            --                    .awvalid
			cafu2ip_aximm0_awcache            => CONNECTED_TO_cafu2ip_aximm0_awcache,            --                    .awcache
			cafu2ip_aximm0_awlock             => CONNECTED_TO_cafu2ip_aximm0_awlock,             --                    .awlock
			cafu2ip_aximm0_awregion           => CONNECTED_TO_cafu2ip_aximm0_awregion,           --                    .awregion
			cafu2ip_aximm0_awatop             => CONNECTED_TO_cafu2ip_aximm0_awatop,             --                    .awatop
			ip2cafu_aximm0_awready            => CONNECTED_TO_ip2cafu_aximm0_awready,            --                    .awready
			cafu2ip_aximm1_awid               => CONNECTED_TO_cafu2ip_aximm1_awid,               -- axi2ccip_wraddr_ch1.awid
			cafu2ip_aximm1_awaddr             => CONNECTED_TO_cafu2ip_aximm1_awaddr,             --                    .awaddr
			cafu2ip_aximm1_awlen              => CONNECTED_TO_cafu2ip_aximm1_awlen,              --                    .awlen
			cafu2ip_aximm1_awsize             => CONNECTED_TO_cafu2ip_aximm1_awsize,             --                    .awsize
			cafu2ip_aximm1_awburst            => CONNECTED_TO_cafu2ip_aximm1_awburst,            --                    .awburst
			cafu2ip_aximm1_awprot             => CONNECTED_TO_cafu2ip_aximm1_awprot,             --                    .awprot
			cafu2ip_aximm1_awqos              => CONNECTED_TO_cafu2ip_aximm1_awqos,              --                    .awqos
			cafu2ip_aximm1_awuser             => CONNECTED_TO_cafu2ip_aximm1_awuser,             --                    .awuser
			cafu2ip_aximm1_awvalid            => CONNECTED_TO_cafu2ip_aximm1_awvalid,            --                    .awvalid
			cafu2ip_aximm1_awcache            => CONNECTED_TO_cafu2ip_aximm1_awcache,            --                    .awcache
			cafu2ip_aximm1_awlock             => CONNECTED_TO_cafu2ip_aximm1_awlock,             --                    .awlock
			cafu2ip_aximm1_awregion           => CONNECTED_TO_cafu2ip_aximm1_awregion,           --                    .awregion
			cafu2ip_aximm1_awatop             => CONNECTED_TO_cafu2ip_aximm1_awatop,             --                    .awatop
			ip2cafu_aximm1_awready            => CONNECTED_TO_ip2cafu_aximm1_awready,            --                    .awready
			cafu2ip_aximm0_wdata              => CONNECTED_TO_cafu2ip_aximm0_wdata,              -- axi2ccip_wrdata_ch0.wdata
			cafu2ip_aximm0_wstrb              => CONNECTED_TO_cafu2ip_aximm0_wstrb,              --                    .wstrb
			cafu2ip_aximm0_wlast              => CONNECTED_TO_cafu2ip_aximm0_wlast,              --                    .wlast
			cafu2ip_aximm0_wuser              => CONNECTED_TO_cafu2ip_aximm0_wuser,              --                    .wuser
			cafu2ip_aximm0_wvalid             => CONNECTED_TO_cafu2ip_aximm0_wvalid,             --                    .wvalid
			ip2cafu_aximm0_wready             => CONNECTED_TO_ip2cafu_aximm0_wready,             --                    .wready
			cafu2ip_aximm1_wdata              => CONNECTED_TO_cafu2ip_aximm1_wdata,              -- axi2ccip_wrdata_ch1.wdata
			cafu2ip_aximm1_wstrb              => CONNECTED_TO_cafu2ip_aximm1_wstrb,              --                    .wstrb
			cafu2ip_aximm1_wlast              => CONNECTED_TO_cafu2ip_aximm1_wlast,              --                    .wlast
			cafu2ip_aximm1_wuser              => CONNECTED_TO_cafu2ip_aximm1_wuser,              --                    .wuser
			cafu2ip_aximm1_wvalid             => CONNECTED_TO_cafu2ip_aximm1_wvalid,             --                    .wvalid
			ip2cafu_aximm1_wready             => CONNECTED_TO_ip2cafu_aximm1_wready,             --                    .wready
			ip2cafu_aximm0_bid                => CONNECTED_TO_ip2cafu_aximm0_bid,                --  axi2ccip_wrrsp_ch0.bid
			ip2cafu_aximm0_bresp              => CONNECTED_TO_ip2cafu_aximm0_bresp,              --                    .bresp
			ip2cafu_aximm0_buser              => CONNECTED_TO_ip2cafu_aximm0_buser,              --                    .buser
			ip2cafu_aximm0_bvalid             => CONNECTED_TO_ip2cafu_aximm0_bvalid,             --                    .bvalid
			cafu2ip_aximm0_bready             => CONNECTED_TO_cafu2ip_aximm0_bready,             --                    .bready
			ip2cafu_aximm1_bid                => CONNECTED_TO_ip2cafu_aximm1_bid,                --  axi2ccip_wrrsp_ch1.bid
			ip2cafu_aximm1_bresp              => CONNECTED_TO_ip2cafu_aximm1_bresp,              --                    .bresp
			ip2cafu_aximm1_buser              => CONNECTED_TO_ip2cafu_aximm1_buser,              --                    .buser
			ip2cafu_aximm1_bvalid             => CONNECTED_TO_ip2cafu_aximm1_bvalid,             --                    .bvalid
			cafu2ip_aximm1_bready             => CONNECTED_TO_cafu2ip_aximm1_bready,             --                    .bready
			cafu2ip_aximm0_arid               => CONNECTED_TO_cafu2ip_aximm0_arid,               -- axi2ccip_rdaddr_ch0.arid
			cafu2ip_aximm0_araddr             => CONNECTED_TO_cafu2ip_aximm0_araddr,             --                    .araddr
			cafu2ip_aximm0_arlen              => CONNECTED_TO_cafu2ip_aximm0_arlen,              --                    .arlen
			cafu2ip_aximm0_arsize             => CONNECTED_TO_cafu2ip_aximm0_arsize,             --                    .arsize
			cafu2ip_aximm0_arburst            => CONNECTED_TO_cafu2ip_aximm0_arburst,            --                    .arburst
			cafu2ip_aximm0_arprot             => CONNECTED_TO_cafu2ip_aximm0_arprot,             --                    .arprot
			cafu2ip_aximm0_arqos              => CONNECTED_TO_cafu2ip_aximm0_arqos,              --                    .arqos
			cafu2ip_aximm0_aruser             => CONNECTED_TO_cafu2ip_aximm0_aruser,             --                    .aruser
			cafu2ip_aximm0_arvalid            => CONNECTED_TO_cafu2ip_aximm0_arvalid,            --                    .arvalid
			cafu2ip_aximm0_arcache            => CONNECTED_TO_cafu2ip_aximm0_arcache,            --                    .arcache
			cafu2ip_aximm0_arlock             => CONNECTED_TO_cafu2ip_aximm0_arlock,             --                    .arlock
			cafu2ip_aximm0_arregion           => CONNECTED_TO_cafu2ip_aximm0_arregion,           --                    .arregion
			ip2cafu_aximm0_arready            => CONNECTED_TO_ip2cafu_aximm0_arready,            --                    .arready
			cafu2ip_aximm1_arid               => CONNECTED_TO_cafu2ip_aximm1_arid,               -- axi2ccip_rdaddr_ch1.arid
			cafu2ip_aximm1_araddr             => CONNECTED_TO_cafu2ip_aximm1_araddr,             --                    .araddr
			cafu2ip_aximm1_arlen              => CONNECTED_TO_cafu2ip_aximm1_arlen,              --                    .arlen
			cafu2ip_aximm1_arsize             => CONNECTED_TO_cafu2ip_aximm1_arsize,             --                    .arsize
			cafu2ip_aximm1_arburst            => CONNECTED_TO_cafu2ip_aximm1_arburst,            --                    .arburst
			cafu2ip_aximm1_arprot             => CONNECTED_TO_cafu2ip_aximm1_arprot,             --                    .arprot
			cafu2ip_aximm1_arqos              => CONNECTED_TO_cafu2ip_aximm1_arqos,              --                    .arqos
			cafu2ip_aximm1_aruser             => CONNECTED_TO_cafu2ip_aximm1_aruser,             --                    .aruser
			cafu2ip_aximm1_arvalid            => CONNECTED_TO_cafu2ip_aximm1_arvalid,            --                    .arvalid
			cafu2ip_aximm1_arcache            => CONNECTED_TO_cafu2ip_aximm1_arcache,            --                    .arcache
			cafu2ip_aximm1_arlock             => CONNECTED_TO_cafu2ip_aximm1_arlock,             --                    .arlock
			cafu2ip_aximm1_arregion           => CONNECTED_TO_cafu2ip_aximm1_arregion,           --                    .arregion
			ip2cafu_aximm1_arready            => CONNECTED_TO_ip2cafu_aximm1_arready,            --                    .arready
			ip2cafu_aximm0_rid                => CONNECTED_TO_ip2cafu_aximm0_rid,                --  axi2ccip_rdrsp_ch0.rid
			ip2cafu_aximm0_rdata              => CONNECTED_TO_ip2cafu_aximm0_rdata,              --                    .rdata
			ip2cafu_aximm0_rresp              => CONNECTED_TO_ip2cafu_aximm0_rresp,              --                    .rresp
			ip2cafu_aximm0_rlast              => CONNECTED_TO_ip2cafu_aximm0_rlast,              --                    .rlast
			ip2cafu_aximm0_ruser              => CONNECTED_TO_ip2cafu_aximm0_ruser,              --                    .ruser
			ip2cafu_aximm0_rvalid             => CONNECTED_TO_ip2cafu_aximm0_rvalid,             --                    .rvalid
			cafu2ip_aximm0_rready             => CONNECTED_TO_cafu2ip_aximm0_rready,             --                    .rready
			ip2cafu_aximm1_rid                => CONNECTED_TO_ip2cafu_aximm1_rid,                --  axi2ccip_rdrsp_ch1.rid
			ip2cafu_aximm1_rdata              => CONNECTED_TO_ip2cafu_aximm1_rdata,              --                    .rdata
			ip2cafu_aximm1_rresp              => CONNECTED_TO_ip2cafu_aximm1_rresp,              --                    .rresp
			ip2cafu_aximm1_rlast              => CONNECTED_TO_ip2cafu_aximm1_rlast,              --                    .rlast
			ip2cafu_aximm1_ruser              => CONNECTED_TO_ip2cafu_aximm1_ruser,              --                    .ruser
			ip2cafu_aximm1_rvalid             => CONNECTED_TO_ip2cafu_aximm1_rvalid,             --                    .rvalid
			cafu2ip_aximm1_rready             => CONNECTED_TO_cafu2ip_aximm1_rready,             --                    .rready
			cafu2ip_csr0_cfg_if               => CONNECTED_TO_cafu2ip_csr0_cfg_if,               --       cafu_csr0_cfg.cafu2ip_cfg_if
			ip2cafu_csr0_cfg_if               => CONNECTED_TO_ip2cafu_csr0_cfg_if,               --                    .ip2cafu_devsec
			ip2csr_avmm_clk                   => CONNECTED_TO_ip2csr_avmm_clk,                   --             afu_csr.clk
			ip2csr_avmm_rstn                  => CONNECTED_TO_ip2csr_avmm_rstn,                  --                    .rst_n
			csr2ip_avmm_waitrequest           => CONNECTED_TO_csr2ip_avmm_waitrequest,           --                    .waitrequest
			csr2ip_avmm_readdata              => CONNECTED_TO_csr2ip_avmm_readdata,              --                    .readdata
			csr2ip_avmm_readdatavalid         => CONNECTED_TO_csr2ip_avmm_readdatavalid,         --                    .readdatavalid
			ip2csr_avmm_writedata             => CONNECTED_TO_ip2csr_avmm_writedata,             --                    .writedata
			ip2csr_avmm_poison                => CONNECTED_TO_ip2csr_avmm_poison,                --                    .poison
			ip2csr_avmm_address               => CONNECTED_TO_ip2csr_avmm_address,               --                    .address
			ip2csr_avmm_write                 => CONNECTED_TO_ip2csr_avmm_write,                 --                    .write
			ip2csr_avmm_read                  => CONNECTED_TO_ip2csr_avmm_read,                  --                    .read
			ip2csr_avmm_byteenable            => CONNECTED_TO_ip2csr_avmm_byteenable,            --                    .byteenable
			ip2cafu_avmm_clk                  => CONNECTED_TO_ip2cafu_avmm_clk,                  --            cafu_csr.clk
			ip2cafu_avmm_rstn                 => CONNECTED_TO_ip2cafu_avmm_rstn,                 --                    .rstn
			cafu2ip_avmm_waitrequest          => CONNECTED_TO_cafu2ip_avmm_waitrequest,          --                    .waitrequest
			cafu2ip_avmm_readdata             => CONNECTED_TO_cafu2ip_avmm_readdata,             --                    .readdata
			cafu2ip_avmm_readdatavalid        => CONNECTED_TO_cafu2ip_avmm_readdatavalid,        --                    .readdatavalid
			ip2cafu_avmm_burstcount           => CONNECTED_TO_ip2cafu_avmm_burstcount,           --                    .burstcount
			ip2cafu_avmm_writedata            => CONNECTED_TO_ip2cafu_avmm_writedata,            --                    .writedata
			ip2cafu_avmm_poison               => CONNECTED_TO_ip2cafu_avmm_poison,               --                    .poison
			ip2cafu_avmm_address              => CONNECTED_TO_ip2cafu_avmm_address,              --                    .address
			ip2cafu_avmm_write                => CONNECTED_TO_ip2cafu_avmm_write,                --                    .write
			ip2cafu_avmm_read                 => CONNECTED_TO_ip2cafu_avmm_read,                 --                    .read
			ip2cafu_avmm_byteenable           => CONNECTED_TO_ip2cafu_avmm_byteenable,           --                    .byteenable
			ccv_afu_conf_base_addr_high       => CONNECTED_TO_ccv_afu_conf_base_addr_high,       --             ccv_afu.base_addr_high
			ccv_afu_conf_base_addr_high_valid => CONNECTED_TO_ccv_afu_conf_base_addr_high_valid, --                    .base_addr_high_valid
			ccv_afu_conf_base_addr_low        => CONNECTED_TO_ccv_afu_conf_base_addr_low,        --                    .base_addr_low
			ccv_afu_conf_base_addr_low_valid  => CONNECTED_TO_ccv_afu_conf_base_addr_low_valid,  --                    .base_addr_low_valid
			pf0_max_payload_size              => CONNECTED_TO_pf0_max_payload_size,              --            ext_comp.pfo_mpss
			pf0_max_read_request_size         => CONNECTED_TO_pf0_max_read_request_size,         --                    .pf0_mrrs
			pf0_bus_master_en                 => CONNECTED_TO_pf0_bus_master_en,                 --                    .pfo_bus_master_en
			pf0_memory_access_en              => CONNECTED_TO_pf0_memory_access_en,              --                    .pfo_mem_access_en
			pf1_max_payload_size              => CONNECTED_TO_pf1_max_payload_size,              --                    .pf1_mpss
			pf1_max_read_request_size         => CONNECTED_TO_pf1_max_read_request_size,         --                    .pf1_mrrs
			pf1_bus_master_en                 => CONNECTED_TO_pf1_bus_master_en,                 --                    .pf1_bus_master_en
			pf1_memory_access_en              => CONNECTED_TO_pf1_memory_access_en,              --                    .pf1_mem_access_en
			pf0_msix_enable                   => CONNECTED_TO_pf0_msix_enable,                   --  pf0_msix_interface.msix_enable
			pf0_msix_fn_mask                  => CONNECTED_TO_pf0_msix_fn_mask,                  --                    .msix_fn_mask
			pf1_msix_enable                   => CONNECTED_TO_pf1_msix_enable,                   --  pf1_msix_interface.msix_enable
			pf1_msix_fn_mask                  => CONNECTED_TO_pf1_msix_fn_mask,                  --                    .msix_fn_mask
			dev_serial_num                    => CONNECTED_TO_dev_serial_num,                    --                    .dev_serial_num
			dev_serial_num_valid              => CONNECTED_TO_dev_serial_num_valid,              --                    .dev_serial_num_valid
			ip2uio_tx_ready                   => CONNECTED_TO_ip2uio_tx_ready,                   --          usr_tx_st0.ready
			uio2ip_tx_st0_dvalid              => CONNECTED_TO_uio2ip_tx_st0_dvalid,              --                    .dvalid
			uio2ip_tx_st0_sop                 => CONNECTED_TO_uio2ip_tx_st0_sop,                 --                    .sop
			uio2ip_tx_st0_eop                 => CONNECTED_TO_uio2ip_tx_st0_eop,                 --                    .eop
			uio2ip_tx_st0_data                => CONNECTED_TO_uio2ip_tx_st0_data,                --                    .data
			uio2ip_tx_st0_data_parity         => CONNECTED_TO_uio2ip_tx_st0_data_parity,         --                    .data_parity
			uio2ip_tx_st0_hdr                 => CONNECTED_TO_uio2ip_tx_st0_hdr,                 --                    .hdr
			uio2ip_tx_st0_hdr_parity          => CONNECTED_TO_uio2ip_tx_st0_hdr_parity,          --                    .hdr_parity
			uio2ip_tx_st0_hvalid              => CONNECTED_TO_uio2ip_tx_st0_hvalid,              --                    .hvalid
			uio2ip_tx_st0_prefix              => CONNECTED_TO_uio2ip_tx_st0_prefix,              --                    .prefix
			uio2ip_tx_st0_prefix_parity       => CONNECTED_TO_uio2ip_tx_st0_prefix_parity,       --                    .prefix_parity
			uio2ip_tx_st0_pvalid              => CONNECTED_TO_uio2ip_tx_st0_pvalid,              --                    .pvalid
			uio2ip_tx_st0_empty               => CONNECTED_TO_uio2ip_tx_st0_empty,               --                    .empty
			uio2ip_tx_st0_misc_parity         => CONNECTED_TO_uio2ip_tx_st0_misc_parity,         --                    .misc_parity
			uio2ip_tx_st1_dvalid              => CONNECTED_TO_uio2ip_tx_st1_dvalid,              --          usr_tx_st1.dvalid
			uio2ip_tx_st1_sop                 => CONNECTED_TO_uio2ip_tx_st1_sop,                 --                    .sop
			uio2ip_tx_st1_eop                 => CONNECTED_TO_uio2ip_tx_st1_eop,                 --                    .eop
			uio2ip_tx_st1_data                => CONNECTED_TO_uio2ip_tx_st1_data,                --                    .data
			uio2ip_tx_st1_data_parity         => CONNECTED_TO_uio2ip_tx_st1_data_parity,         --                    .data_parity
			uio2ip_tx_st1_hdr                 => CONNECTED_TO_uio2ip_tx_st1_hdr,                 --                    .hdr
			uio2ip_tx_st1_hdr_parity          => CONNECTED_TO_uio2ip_tx_st1_hdr_parity,          --                    .hdr_parity
			uio2ip_tx_st1_hvalid              => CONNECTED_TO_uio2ip_tx_st1_hvalid,              --                    .hvalid
			uio2ip_tx_st1_prefix              => CONNECTED_TO_uio2ip_tx_st1_prefix,              --                    .prefix
			uio2ip_tx_st1_prefix_parity       => CONNECTED_TO_uio2ip_tx_st1_prefix_parity,       --                    .prefix_parity
			uio2ip_tx_st1_pvalid              => CONNECTED_TO_uio2ip_tx_st1_pvalid,              --                    .pvalid
			uio2ip_tx_st1_empty               => CONNECTED_TO_uio2ip_tx_st1_empty,               --                    .empty
			uio2ip_tx_st1_misc_parity         => CONNECTED_TO_uio2ip_tx_st1_misc_parity,         --                    .misc_parity
			uio2ip_tx_st2_dvalid              => CONNECTED_TO_uio2ip_tx_st2_dvalid,              --          usr_tx_st2.dvalid
			uio2ip_tx_st2_sop                 => CONNECTED_TO_uio2ip_tx_st2_sop,                 --                    .sop
			uio2ip_tx_st2_eop                 => CONNECTED_TO_uio2ip_tx_st2_eop,                 --                    .eop
			uio2ip_tx_st2_data                => CONNECTED_TO_uio2ip_tx_st2_data,                --                    .data
			uio2ip_tx_st2_data_parity         => CONNECTED_TO_uio2ip_tx_st2_data_parity,         --                    .data_parity
			uio2ip_tx_st2_hdr                 => CONNECTED_TO_uio2ip_tx_st2_hdr,                 --                    .hdr
			uio2ip_tx_st2_hdr_parity          => CONNECTED_TO_uio2ip_tx_st2_hdr_parity,          --                    .hdr_parity
			uio2ip_tx_st2_hvalid              => CONNECTED_TO_uio2ip_tx_st2_hvalid,              --                    .hvalid
			uio2ip_tx_st2_prefix              => CONNECTED_TO_uio2ip_tx_st2_prefix,              --                    .prefix
			uio2ip_tx_st2_prefix_parity       => CONNECTED_TO_uio2ip_tx_st2_prefix_parity,       --                    .prefix_parity
			uio2ip_tx_st2_pvalid              => CONNECTED_TO_uio2ip_tx_st2_pvalid,              --                    .pvalid
			uio2ip_tx_st2_empty               => CONNECTED_TO_uio2ip_tx_st2_empty,               --                    .empty
			uio2ip_tx_st2_misc_parity         => CONNECTED_TO_uio2ip_tx_st2_misc_parity,         --                    .misc_parity
			uio2ip_tx_st3_dvalid              => CONNECTED_TO_uio2ip_tx_st3_dvalid,              --          usr_tx_st3.dvalid
			uio2ip_tx_st3_sop                 => CONNECTED_TO_uio2ip_tx_st3_sop,                 --                    .sop
			uio2ip_tx_st3_eop                 => CONNECTED_TO_uio2ip_tx_st3_eop,                 --                    .eop
			uio2ip_tx_st3_data                => CONNECTED_TO_uio2ip_tx_st3_data,                --                    .data
			uio2ip_tx_st3_data_parity         => CONNECTED_TO_uio2ip_tx_st3_data_parity,         --                    .data_parity
			uio2ip_tx_st3_hdr                 => CONNECTED_TO_uio2ip_tx_st3_hdr,                 --                    .hdr
			uio2ip_tx_st3_hdr_parity          => CONNECTED_TO_uio2ip_tx_st3_hdr_parity,          --                    .hdr_parity
			uio2ip_tx_st3_hvalid              => CONNECTED_TO_uio2ip_tx_st3_hvalid,              --                    .hvalid
			uio2ip_tx_st3_prefix              => CONNECTED_TO_uio2ip_tx_st3_prefix,              --                    .prefix
			uio2ip_tx_st3_prefix_parity       => CONNECTED_TO_uio2ip_tx_st3_prefix_parity,       --                    .prefix_parity
			uio2ip_tx_st3_pvalid              => CONNECTED_TO_uio2ip_tx_st3_pvalid,              --                    .pvalid
			uio2ip_tx_st3_empty               => CONNECTED_TO_uio2ip_tx_st3_empty,               --                    .empty
			uio2ip_tx_st3_misc_parity         => CONNECTED_TO_uio2ip_tx_st3_misc_parity,         --                    .misc_parity
			ip2uio_tx_st_Hcrdt_update         => CONNECTED_TO_ip2uio_tx_st_Hcrdt_update,         --           usr_tx_st.Hcrdt_update
			ip2uio_tx_st_Hcrdt_update_cnt     => CONNECTED_TO_ip2uio_tx_st_Hcrdt_update_cnt,     --                    .Hcrdt_update_cnt
			ip2uio_tx_st_Hcrdt_init           => CONNECTED_TO_ip2uio_tx_st_Hcrdt_init,           --                    .Hcrdt_init
			uio2ip_tx_st_Hcrdt_init_ack       => CONNECTED_TO_uio2ip_tx_st_Hcrdt_init_ack,       --                    .Hcrdt_init_ack
			ip2uio_tx_st_Dcrdt_update         => CONNECTED_TO_ip2uio_tx_st_Dcrdt_update,         --                    .Dcrdt_update
			ip2uio_tx_st_Dcrdt_update_cnt     => CONNECTED_TO_ip2uio_tx_st_Dcrdt_update_cnt,     --                    .Dcrdt_update_cnt
			ip2uio_tx_st_Dcrdt_init           => CONNECTED_TO_ip2uio_tx_st_Dcrdt_init,           --                    .Dcrdt_init
			uio2ip_tx_st_Dcrdt_init_ack       => CONNECTED_TO_uio2ip_tx_st_Dcrdt_init_ack,       --                    .Dcrdt_init_ack
			ip2uio_rx_st0_dvalid              => CONNECTED_TO_ip2uio_rx_st0_dvalid,              --         usr_rx_st_0.dvalid
			ip2uio_rx_st0_sop                 => CONNECTED_TO_ip2uio_rx_st0_sop,                 --                    .sop
			ip2uio_rx_st0_eop                 => CONNECTED_TO_ip2uio_rx_st0_eop,                 --                    .eop
			ip2uio_rx_st0_passthrough         => CONNECTED_TO_ip2uio_rx_st0_passthrough,         --                    .passthrough
			ip2uio_rx_st0_data                => CONNECTED_TO_ip2uio_rx_st0_data,                --                    .data
			ip2uio_rx_st0_data_parity         => CONNECTED_TO_ip2uio_rx_st0_data_parity,         --                    .data_parity
			ip2uio_rx_st0_hdr                 => CONNECTED_TO_ip2uio_rx_st0_hdr,                 --                    .hdr
			ip2uio_rx_st0_hdr_parity          => CONNECTED_TO_ip2uio_rx_st0_hdr_parity,          --                    .hdr_parity
			ip2uio_rx_st0_hvalid              => CONNECTED_TO_ip2uio_rx_st0_hvalid,              --                    .hvalid
			ip2uio_rx_st0_prefix              => CONNECTED_TO_ip2uio_rx_st0_prefix,              --                    .prefix
			ip2uio_rx_st0_prefix_parity       => CONNECTED_TO_ip2uio_rx_st0_prefix_parity,       --                    .prefix_parity
			ip2uio_rx_st0_pvalid              => CONNECTED_TO_ip2uio_rx_st0_pvalid,              --                    .pvalid
			ip2uio_rx_st0_bar                 => CONNECTED_TO_ip2uio_rx_st0_bar,                 --                    .bar
			ip2uio_rx_st0_pfnum               => CONNECTED_TO_ip2uio_rx_st0_pfnum,               --                    .pfnum
			ip2uio_rx_st0_misc_parity         => CONNECTED_TO_ip2uio_rx_st0_misc_parity,         --                    .misc_parity
			ip2uio_rx_st0_empty               => CONNECTED_TO_ip2uio_rx_st0_empty,               --                    .empty
			ip2uio_rx_st1_dvalid              => CONNECTED_TO_ip2uio_rx_st1_dvalid,              --         usr_rx_st_1.dvalid
			ip2uio_rx_st1_sop                 => CONNECTED_TO_ip2uio_rx_st1_sop,                 --                    .sop
			ip2uio_rx_st1_eop                 => CONNECTED_TO_ip2uio_rx_st1_eop,                 --                    .eop
			ip2uio_rx_st1_passthrough         => CONNECTED_TO_ip2uio_rx_st1_passthrough,         --                    .passthrough
			ip2uio_rx_st1_data                => CONNECTED_TO_ip2uio_rx_st1_data,                --                    .data
			ip2uio_rx_st1_data_parity         => CONNECTED_TO_ip2uio_rx_st1_data_parity,         --                    .data_parity
			ip2uio_rx_st1_hdr                 => CONNECTED_TO_ip2uio_rx_st1_hdr,                 --                    .hdr
			ip2uio_rx_st1_hdr_parity          => CONNECTED_TO_ip2uio_rx_st1_hdr_parity,          --                    .hdr_parity
			ip2uio_rx_st1_hvalid              => CONNECTED_TO_ip2uio_rx_st1_hvalid,              --                    .hvalid
			ip2uio_rx_st1_prefix              => CONNECTED_TO_ip2uio_rx_st1_prefix,              --                    .prefix
			ip2uio_rx_st1_prefix_parity       => CONNECTED_TO_ip2uio_rx_st1_prefix_parity,       --                    .prefix_parity
			ip2uio_rx_st1_pvalid              => CONNECTED_TO_ip2uio_rx_st1_pvalid,              --                    .pvalid
			ip2uio_rx_st1_bar                 => CONNECTED_TO_ip2uio_rx_st1_bar,                 --                    .bar
			ip2uio_rx_st1_pfnum               => CONNECTED_TO_ip2uio_rx_st1_pfnum,               --                    .pfnum
			ip2uio_rx_st1_misc_parity         => CONNECTED_TO_ip2uio_rx_st1_misc_parity,         --                    .misc_parity
			ip2uio_rx_st1_empty               => CONNECTED_TO_ip2uio_rx_st1_empty,               --                    .empty
			ip2uio_rx_st2_dvalid              => CONNECTED_TO_ip2uio_rx_st2_dvalid,              --         usr_rx_st_2.dvalid
			ip2uio_rx_st2_sop                 => CONNECTED_TO_ip2uio_rx_st2_sop,                 --                    .sop
			ip2uio_rx_st2_eop                 => CONNECTED_TO_ip2uio_rx_st2_eop,                 --                    .eop
			ip2uio_rx_st2_passthrough         => CONNECTED_TO_ip2uio_rx_st2_passthrough,         --                    .passthrough
			ip2uio_rx_st2_data                => CONNECTED_TO_ip2uio_rx_st2_data,                --                    .data
			ip2uio_rx_st2_data_parity         => CONNECTED_TO_ip2uio_rx_st2_data_parity,         --                    .data_parity
			ip2uio_rx_st2_hdr                 => CONNECTED_TO_ip2uio_rx_st2_hdr,                 --                    .hdr
			ip2uio_rx_st2_hdr_parity          => CONNECTED_TO_ip2uio_rx_st2_hdr_parity,          --                    .hdr_parity
			ip2uio_rx_st2_hvalid              => CONNECTED_TO_ip2uio_rx_st2_hvalid,              --                    .hvalid
			ip2uio_rx_st2_prefix              => CONNECTED_TO_ip2uio_rx_st2_prefix,              --                    .prefix
			ip2uio_rx_st2_prefix_parity       => CONNECTED_TO_ip2uio_rx_st2_prefix_parity,       --                    .prefix_parity
			ip2uio_rx_st2_pvalid              => CONNECTED_TO_ip2uio_rx_st2_pvalid,              --                    .pvalid
			ip2uio_rx_st2_bar                 => CONNECTED_TO_ip2uio_rx_st2_bar,                 --                    .bar
			ip2uio_rx_st2_pfnum               => CONNECTED_TO_ip2uio_rx_st2_pfnum,               --                    .pfnum
			ip2uio_rx_st2_misc_parity         => CONNECTED_TO_ip2uio_rx_st2_misc_parity,         --                    .misc_parity
			ip2uio_rx_st2_empty               => CONNECTED_TO_ip2uio_rx_st2_empty,               --                    .empty
			ip2uio_rx_st3_dvalid              => CONNECTED_TO_ip2uio_rx_st3_dvalid,              --         usr_rx_st_3.dvalid
			ip2uio_rx_st3_sop                 => CONNECTED_TO_ip2uio_rx_st3_sop,                 --                    .sop
			ip2uio_rx_st3_eop                 => CONNECTED_TO_ip2uio_rx_st3_eop,                 --                    .eop
			ip2uio_rx_st3_passthrough         => CONNECTED_TO_ip2uio_rx_st3_passthrough,         --                    .passthrough
			ip2uio_rx_st3_data                => CONNECTED_TO_ip2uio_rx_st3_data,                --                    .data
			ip2uio_rx_st3_data_parity         => CONNECTED_TO_ip2uio_rx_st3_data_parity,         --                    .data_parity
			ip2uio_rx_st3_hdr                 => CONNECTED_TO_ip2uio_rx_st3_hdr,                 --                    .hdr
			ip2uio_rx_st3_hdr_parity          => CONNECTED_TO_ip2uio_rx_st3_hdr_parity,          --                    .hdr_parity
			ip2uio_rx_st3_hvalid              => CONNECTED_TO_ip2uio_rx_st3_hvalid,              --                    .hvalid
			ip2uio_rx_st3_prefix              => CONNECTED_TO_ip2uio_rx_st3_prefix,              --                    .prefix
			ip2uio_rx_st3_prefix_parity       => CONNECTED_TO_ip2uio_rx_st3_prefix_parity,       --                    .prefix_parity
			ip2uio_rx_st3_pvalid              => CONNECTED_TO_ip2uio_rx_st3_pvalid,              --                    .pvalid
			ip2uio_rx_st3_bar                 => CONNECTED_TO_ip2uio_rx_st3_bar,                 --                    .bar
			ip2uio_rx_st3_pfnum               => CONNECTED_TO_ip2uio_rx_st3_pfnum,               --                    .pfnum
			ip2uio_rx_st3_misc_parity         => CONNECTED_TO_ip2uio_rx_st3_misc_parity,         --                    .misc_parity
			ip2uio_rx_st3_empty               => CONNECTED_TO_ip2uio_rx_st3_empty,               --                    .empty
			uio2ip_rx_st_Hcrdt_update         => CONNECTED_TO_uio2ip_rx_st_Hcrdt_update,         --           usr_rx_st.Hcrdt_update
			uio2ip_rx_st_Hcrdt_update_cnt     => CONNECTED_TO_uio2ip_rx_st_Hcrdt_update_cnt,     --                    .Hcrdt_update_cnt
			uio2ip_rx_st_Hcrdt_init           => CONNECTED_TO_uio2ip_rx_st_Hcrdt_init,           --                    .Hcrdt_init
			ip2uio_rx_st_Hcrdt_init_ack       => CONNECTED_TO_ip2uio_rx_st_Hcrdt_init_ack,       --                    .Hcrdt_init_ack
			uio2ip_rx_st_Dcrdt_update         => CONNECTED_TO_uio2ip_rx_st_Dcrdt_update,         --                    .Dcrdt_update
			uio2ip_rx_st_Dcrdt_update_cnt     => CONNECTED_TO_uio2ip_rx_st_Dcrdt_update_cnt,     --                    .Dcrdt_update_cnt
			uio2ip_rx_st_Dcrdt_init           => CONNECTED_TO_uio2ip_rx_st_Dcrdt_init,           --                    .Dcrdt_init
			ip2uio_rx_st_Dcrdt_init_ack       => CONNECTED_TO_ip2uio_rx_st_Dcrdt_init_ack,       --                    .Dcrdt_init_ack
			ip2uio_bus_number                 => CONNECTED_TO_ip2uio_bus_number,                 --                 uio.usr_bus_number
			ip2uio_device_number              => CONNECTED_TO_ip2uio_device_number,              --                    .usr_device_number
			ip2cafu_axistd0_tvalid            => CONNECTED_TO_ip2cafu_axistd0_tvalid,            --     ip2cafu_axistd0.td0_tvalid
			ip2cafu_axistd0_tdata             => CONNECTED_TO_ip2cafu_axistd0_tdata,             --                    .td0_tdata
			ip2cafu_axistd0_tstrb             => CONNECTED_TO_ip2cafu_axistd0_tstrb,             --                    .td0_tstrb
			ip2cafu_axistd0_tdest             => CONNECTED_TO_ip2cafu_axistd0_tdest,             --                    .td0_tdest
			ip2cafu_axistd0_tkeep             => CONNECTED_TO_ip2cafu_axistd0_tkeep,             --                    .td0_tkeep
			ip2cafu_axistd0_tlast             => CONNECTED_TO_ip2cafu_axistd0_tlast,             --                    .td0_tlast
			ip2cafu_axistd0_tid               => CONNECTED_TO_ip2cafu_axistd0_tid,               --                    .td0_tid
			ip2cafu_axistd0_tuser             => CONNECTED_TO_ip2cafu_axistd0_tuser,             --                    .td0_tuser
			cafu2ip_axistd0_tready            => CONNECTED_TO_cafu2ip_axistd0_tready,            --                    .td0_tready
			ip2cafu_axisth0_tvalid            => CONNECTED_TO_ip2cafu_axisth0_tvalid,            --                    .th0_tvalid
			ip2cafu_axisth0_tdata             => CONNECTED_TO_ip2cafu_axisth0_tdata,             --                    .th0_tdata
			ip2cafu_axisth0_tstrb             => CONNECTED_TO_ip2cafu_axisth0_tstrb,             --                    .th0_tstrb
			ip2cafu_axisth0_tdest             => CONNECTED_TO_ip2cafu_axisth0_tdest,             --                    .th0_tdest
			ip2cafu_axisth0_tkeep             => CONNECTED_TO_ip2cafu_axisth0_tkeep,             --                    .th0_tkeep
			ip2cafu_axisth0_tlast             => CONNECTED_TO_ip2cafu_axisth0_tlast,             --                    .th0_tlast
			ip2cafu_axisth0_tid               => CONNECTED_TO_ip2cafu_axisth0_tid,               --                    .th0_tid
			ip2cafu_axisth0_tuser             => CONNECTED_TO_ip2cafu_axisth0_tuser,             --                    .th0_tuser
			cafu2ip_axisth0_tready            => CONNECTED_TO_cafu2ip_axisth0_tready,            --                    .th0_tready
			ip2cafu_axistd1_tvalid            => CONNECTED_TO_ip2cafu_axistd1_tvalid,            --     ip2cafu_axistd1.td1_tvalid
			ip2cafu_axistd1_tdata             => CONNECTED_TO_ip2cafu_axistd1_tdata,             --                    .td1_tdata
			ip2cafu_axistd1_tstrb             => CONNECTED_TO_ip2cafu_axistd1_tstrb,             --                    .td1_tstrb
			ip2cafu_axistd1_tdest             => CONNECTED_TO_ip2cafu_axistd1_tdest,             --                    .td1_tdest
			ip2cafu_axistd1_tkeep             => CONNECTED_TO_ip2cafu_axistd1_tkeep,             --                    .td1_tkeep
			ip2cafu_axistd1_tlast             => CONNECTED_TO_ip2cafu_axistd1_tlast,             --                    .td1_tlast
			ip2cafu_axistd1_tid               => CONNECTED_TO_ip2cafu_axistd1_tid,               --                    .td1_tid
			ip2cafu_axistd1_tuser             => CONNECTED_TO_ip2cafu_axistd1_tuser,             --                    .td1_tuser
			cafu2ip_axistd1_tready            => CONNECTED_TO_cafu2ip_axistd1_tready,            --                    .td1_tready
			ip2cafu_axisth1_tvalid            => CONNECTED_TO_ip2cafu_axisth1_tvalid,            --                    .th1_tvalid
			ip2cafu_axisth1_tdata             => CONNECTED_TO_ip2cafu_axisth1_tdata,             --                    .th1_tdata
			ip2cafu_axisth1_tstrb             => CONNECTED_TO_ip2cafu_axisth1_tstrb,             --                    .th1_tstrb
			ip2cafu_axisth1_tdest             => CONNECTED_TO_ip2cafu_axisth1_tdest,             --                    .th1_tdest
			ip2cafu_axisth1_tkeep             => CONNECTED_TO_ip2cafu_axisth1_tkeep,             --                    .th1_tkeep
			ip2cafu_axisth1_tlast             => CONNECTED_TO_ip2cafu_axisth1_tlast,             --                    .th1_tlast
			ip2cafu_axisth1_tid               => CONNECTED_TO_ip2cafu_axisth1_tid,               --                    .th1_tid
			ip2cafu_axisth1_tuser             => CONNECTED_TO_ip2cafu_axisth1_tuser,             --                    .th1_tuser
			cafu2ip_axisth1_tready            => CONNECTED_TO_cafu2ip_axisth1_tready,            --                    .th1_tready
			usr2ip_cxlreset_initiate          => CONNECTED_TO_usr2ip_cxlreset_initiate,          --       cxl_reset_inf.cxlreset_initiate
			ip2usr_cxlreset_req               => CONNECTED_TO_ip2usr_cxlreset_req,               --                    .cxlreset_req
			usr2ip_cxlreset_ack               => CONNECTED_TO_usr2ip_cxlreset_ack,               --                    .cxlreset_ack
			ip2usr_cxlreset_error             => CONNECTED_TO_ip2usr_cxlreset_error,             --                    .cxlreset_error
			ip2usr_cxlreset_complete          => CONNECTED_TO_ip2usr_cxlreset_complete,          --                    .cxlreset_complete
			usr2ip_app_err_valid              => CONNECTED_TO_usr2ip_app_err_valid,              --         usr_err_inf.err_valid
			usr2ip_app_err_hdr                => CONNECTED_TO_usr2ip_app_err_hdr,                --                    .err_hdr
			usr2ip_app_err_info               => CONNECTED_TO_usr2ip_app_err_info,               --                    .err_info
			usr2ip_app_err_func_num           => CONNECTED_TO_usr2ip_app_err_func_num,           --                    .err_fn_num
			ip2usr_app_err_ready              => CONNECTED_TO_ip2usr_app_err_ready,              --                    .err_rdy
			ip2usr_aermsg_correctable_valid   => CONNECTED_TO_ip2usr_aermsg_correctable_valid,   --                    .aermsg_correctable_valid
			ip2usr_aermsg_uncorrectable_valid => CONNECTED_TO_ip2usr_aermsg_uncorrectable_valid, --                    .aermsg_uncorrectable_valid
			ip2usr_aermsg_res                 => CONNECTED_TO_ip2usr_aermsg_res,                 --                    .aermsg_res
			ip2usr_aermsg_bts                 => CONNECTED_TO_ip2usr_aermsg_bts,                 --                    .aermsg_bts
			ip2usr_aermsg_bds                 => CONNECTED_TO_ip2usr_aermsg_bds,                 --                    .aermsg_bds
			ip2usr_aermsg_rrs                 => CONNECTED_TO_ip2usr_aermsg_rrs,                 --                    .aermsg_rrs
			ip2usr_aermsg_rtts                => CONNECTED_TO_ip2usr_aermsg_rtts,                --                    .aermsg_rtts
			ip2usr_aermsg_anes                => CONNECTED_TO_ip2usr_aermsg_anes,                --                    .aermsg_anes
			ip2usr_aermsg_cies                => CONNECTED_TO_ip2usr_aermsg_cies,                --                    .aermsg_cies
			ip2usr_aermsg_hlos                => CONNECTED_TO_ip2usr_aermsg_hlos,                --                    .aermsg_hlos
			ip2usr_aermsg_fmt                 => CONNECTED_TO_ip2usr_aermsg_fmt,                 --                    .aermsg_fmt
			ip2usr_aermsg_type                => CONNECTED_TO_ip2usr_aermsg_type,                --                    .aermsg_type
			ip2usr_aermsg_tc                  => CONNECTED_TO_ip2usr_aermsg_tc,                  --                    .aermsg_tc
			ip2usr_aermsg_ido                 => CONNECTED_TO_ip2usr_aermsg_ido,                 --                    .aermsg_ido
			ip2usr_aermsg_th                  => CONNECTED_TO_ip2usr_aermsg_th,                  --                    .aermsg_th
			ip2usr_aermsg_td                  => CONNECTED_TO_ip2usr_aermsg_td,                  --                    .aermsg_td
			ip2usr_aermsg_ep                  => CONNECTED_TO_ip2usr_aermsg_ep,                  --                    .aermsg_ep
			ip2usr_aermsg_ro                  => CONNECTED_TO_ip2usr_aermsg_ro,                  --                    .aermsg_ro
			ip2usr_aermsg_ns                  => CONNECTED_TO_ip2usr_aermsg_ns,                  --                    .aermsg_ns
			ip2usr_aermsg_at                  => CONNECTED_TO_ip2usr_aermsg_at,                  --                    .aermsg_at
			ip2usr_aermsg_length              => CONNECTED_TO_ip2usr_aermsg_length,              --                    .aermsg_length
			ip2usr_aermsg_header              => CONNECTED_TO_ip2usr_aermsg_header,              --                    .aermsg_header
			ip2usr_aermsg_und                 => CONNECTED_TO_ip2usr_aermsg_und,                 --                    .aermsg_und
			ip2usr_aermsg_anf                 => CONNECTED_TO_ip2usr_aermsg_anf,                 --                    .aermsg_anf
			ip2usr_aermsg_dlpes               => CONNECTED_TO_ip2usr_aermsg_dlpes,               --                    .aermsg_dlpes
			ip2usr_aermsg_sdes                => CONNECTED_TO_ip2usr_aermsg_sdes,                --                    .aermsg_sdes
			ip2usr_aermsg_fep                 => CONNECTED_TO_ip2usr_aermsg_fep,                 --                    .aermsg_fep
			ip2usr_aermsg_pts                 => CONNECTED_TO_ip2usr_aermsg_pts,                 --                    .aermsg_pts
			ip2usr_aermsg_fcpes               => CONNECTED_TO_ip2usr_aermsg_fcpes,               --                    .aermsg_fcpes
			ip2usr_aermsg_cts                 => CONNECTED_TO_ip2usr_aermsg_cts,                 --                    .aermsg_cts
			ip2usr_aermsg_cas                 => CONNECTED_TO_ip2usr_aermsg_cas,                 --                    .aermsg_cas
			ip2usr_aermsg_ucs                 => CONNECTED_TO_ip2usr_aermsg_ucs,                 --                    .aermsg_ucs
			ip2usr_aermsg_ros                 => CONNECTED_TO_ip2usr_aermsg_ros,                 --                    .aermsg_ros
			ip2usr_aermsg_mts                 => CONNECTED_TO_ip2usr_aermsg_mts,                 --                    .aermsg_mts
			ip2usr_aermsg_uies                => CONNECTED_TO_ip2usr_aermsg_uies,                --                    .aermsg_uies
			ip2usr_aermsg_mbts                => CONNECTED_TO_ip2usr_aermsg_mbts,                --                    .aermsg_mbts
			ip2usr_aermsg_aebs                => CONNECTED_TO_ip2usr_aermsg_aebs,                --                    .aermsg_aebs
			ip2usr_aermsg_tpbes               => CONNECTED_TO_ip2usr_aermsg_tpbes,               --                    .aermsg_tpbes
			ip2usr_aermsg_ees                 => CONNECTED_TO_ip2usr_aermsg_ees,                 --                    .aermsg_ees
			ip2usr_aermsg_ures                => CONNECTED_TO_ip2usr_aermsg_ures,                --                    .aermsg_ures
			ip2usr_aermsg_avs                 => CONNECTED_TO_ip2usr_aermsg_avs,                 --                    .aermsg_avs
			ip2usr_serr_out                   => CONNECTED_TO_ip2usr_serr_out,                   --                    .serr_out
			ip2usr_debug_waitrequest          => CONNECTED_TO_ip2usr_debug_waitrequest,          --                    .dbg_waitreq
			ip2usr_debug_readdata             => CONNECTED_TO_ip2usr_debug_readdata,             --                    .dbg_rddata
			ip2usr_debug_readdatavalid        => CONNECTED_TO_ip2usr_debug_readdatavalid,        --                    .dbg_drvalid
			usr2ip_debug_writedata            => CONNECTED_TO_usr2ip_debug_writedata,            --                    .dbg_wrad
			usr2ip_debug_address              => CONNECTED_TO_usr2ip_debug_address,              --                    .dbg_add
			usr2ip_debug_write                => CONNECTED_TO_usr2ip_debug_write,                --                    .dbg_wrt
			usr2ip_debug_read                 => CONNECTED_TO_usr2ip_debug_read,                 --                    .dbg_read
			usr2ip_debug_byteenable           => CONNECTED_TO_usr2ip_debug_byteenable,           --                    .dbg_byten
			ip2hdm_aximm0_awvalid             => CONNECTED_TO_ip2hdm_aximm0_awvalid,             --       ip2hdm_aximm0.awvalid
			ip2hdm_aximm0_awid                => CONNECTED_TO_ip2hdm_aximm0_awid,                --                    .awid
			ip2hdm_aximm0_awaddr              => CONNECTED_TO_ip2hdm_aximm0_awaddr,              --                    .awaddr
			ip2hdm_aximm0_awlen               => CONNECTED_TO_ip2hdm_aximm0_awlen,               --                    .awlen
			ip2hdm_aximm0_awregion            => CONNECTED_TO_ip2hdm_aximm0_awregion,            --                    .awregion
			ip2hdm_aximm0_awuser              => CONNECTED_TO_ip2hdm_aximm0_awuser,              --                    .awuser
			ip2hdm_aximm0_awsize              => CONNECTED_TO_ip2hdm_aximm0_awsize,              --                    .awsize
			ip2hdm_aximm0_awburst             => CONNECTED_TO_ip2hdm_aximm0_awburst,             --                    .awburst
			ip2hdm_aximm0_awprot              => CONNECTED_TO_ip2hdm_aximm0_awprot,              --                    .awport
			ip2hdm_aximm0_awqos               => CONNECTED_TO_ip2hdm_aximm0_awqos,               --                    .awqos
			ip2hdm_aximm0_awcache             => CONNECTED_TO_ip2hdm_aximm0_awcache,             --                    .awcache
			ip2hdm_aximm0_awlock              => CONNECTED_TO_ip2hdm_aximm0_awlock,              --                    .awlock
			hdm2ip_aximm0_awready             => CONNECTED_TO_hdm2ip_aximm0_awready,             --                    .awready
			ip2hdm_aximm0_wvalid              => CONNECTED_TO_ip2hdm_aximm0_wvalid,              --                    .wvalid
			ip2hdm_aximm0_wdata               => CONNECTED_TO_ip2hdm_aximm0_wdata,               --                    .wdata
			ip2hdm_aximm0_wstrb               => CONNECTED_TO_ip2hdm_aximm0_wstrb,               --                    .wstrb
			ip2hdm_aximm0_wlast               => CONNECTED_TO_ip2hdm_aximm0_wlast,               --                    .wlast
			ip2hdm_aximm0_wuser               => CONNECTED_TO_ip2hdm_aximm0_wuser,               --                    .wuser
			hdm2ip_aximm0_wready              => CONNECTED_TO_hdm2ip_aximm0_wready,              --                    .wready
			hdm2ip_aximm0_bvalid              => CONNECTED_TO_hdm2ip_aximm0_bvalid,              --                    .bvlaid
			hdm2ip_aximm0_bid                 => CONNECTED_TO_hdm2ip_aximm0_bid,                 --                    .bid
			hdm2ip_aximm0_buser               => CONNECTED_TO_hdm2ip_aximm0_buser,               --                    .buser
			hdm2ip_aximm0_bresp               => CONNECTED_TO_hdm2ip_aximm0_bresp,               --                    .brsp
			ip2hdm_aximm0_bready              => CONNECTED_TO_ip2hdm_aximm0_bready,              --                    .bready
			ip2hdm_aximm0_arvalid             => CONNECTED_TO_ip2hdm_aximm0_arvalid,             --                    .arvalid
			ip2hdm_aximm0_arid                => CONNECTED_TO_ip2hdm_aximm0_arid,                --                    .arid
			ip2hdm_aximm0_araddr              => CONNECTED_TO_ip2hdm_aximm0_araddr,              --                    .araddr
			ip2hdm_aximm0_arlen               => CONNECTED_TO_ip2hdm_aximm0_arlen,               --                    .arlen
			ip2hdm_aximm0_arregion            => CONNECTED_TO_ip2hdm_aximm0_arregion,            --                    .arregion
			ip2hdm_aximm0_aruser              => CONNECTED_TO_ip2hdm_aximm0_aruser,              --                    .aruser
			ip2hdm_aximm0_arsize              => CONNECTED_TO_ip2hdm_aximm0_arsize,              --                    .arsize
			ip2hdm_aximm0_arburst             => CONNECTED_TO_ip2hdm_aximm0_arburst,             --                    .arburst
			ip2hdm_aximm0_arprot              => CONNECTED_TO_ip2hdm_aximm0_arprot,              --                    .arport
			ip2hdm_aximm0_arqos               => CONNECTED_TO_ip2hdm_aximm0_arqos,               --                    .arqos
			ip2hdm_aximm0_arcache             => CONNECTED_TO_ip2hdm_aximm0_arcache,             --                    .arcache
			ip2hdm_aximm0_arlock              => CONNECTED_TO_ip2hdm_aximm0_arlock,              --                    .arlock
			hdm2ip_aximm0_arready             => CONNECTED_TO_hdm2ip_aximm0_arready,             --                    .arready
			hdm2ip_aximm0_rvalid              => CONNECTED_TO_hdm2ip_aximm0_rvalid,              --                    .rvalid
			hdm2ip_aximm0_rlast               => CONNECTED_TO_hdm2ip_aximm0_rlast,               --                    .rlast
			hdm2ip_aximm0_rid                 => CONNECTED_TO_hdm2ip_aximm0_rid,                 --                    .rid
			hdm2ip_aximm0_rdata               => CONNECTED_TO_hdm2ip_aximm0_rdata,               --                    .rdata
			hdm2ip_aximm0_ruser               => CONNECTED_TO_hdm2ip_aximm0_ruser,               --                    .ruser
			hdm2ip_aximm0_rresp               => CONNECTED_TO_hdm2ip_aximm0_rresp,               --                    .rresp
			ip2hdm_aximm0_rready              => CONNECTED_TO_ip2hdm_aximm0_rready,              --                    .rready
			ip2hdm_aximm1_awvalid             => CONNECTED_TO_ip2hdm_aximm1_awvalid,             --       ip2hdm_aximm1.awvalid
			ip2hdm_aximm1_awid                => CONNECTED_TO_ip2hdm_aximm1_awid,                --                    .awid
			ip2hdm_aximm1_awaddr              => CONNECTED_TO_ip2hdm_aximm1_awaddr,              --                    .awaddr
			ip2hdm_aximm1_awlen               => CONNECTED_TO_ip2hdm_aximm1_awlen,               --                    .awlen
			ip2hdm_aximm1_awregion            => CONNECTED_TO_ip2hdm_aximm1_awregion,            --                    .awregion
			ip2hdm_aximm1_awuser              => CONNECTED_TO_ip2hdm_aximm1_awuser,              --                    .awuser
			ip2hdm_aximm1_awsize              => CONNECTED_TO_ip2hdm_aximm1_awsize,              --                    .awsize
			ip2hdm_aximm1_awburst             => CONNECTED_TO_ip2hdm_aximm1_awburst,             --                    .awburst
			ip2hdm_aximm1_awprot              => CONNECTED_TO_ip2hdm_aximm1_awprot,              --                    .awport
			ip2hdm_aximm1_awqos               => CONNECTED_TO_ip2hdm_aximm1_awqos,               --                    .awqos
			ip2hdm_aximm1_awcache             => CONNECTED_TO_ip2hdm_aximm1_awcache,             --                    .awcache
			ip2hdm_aximm1_awlock              => CONNECTED_TO_ip2hdm_aximm1_awlock,              --                    .awlock
			hdm2ip_aximm1_awready             => CONNECTED_TO_hdm2ip_aximm1_awready,             --                    .awready
			ip2hdm_aximm1_wvalid              => CONNECTED_TO_ip2hdm_aximm1_wvalid,              --                    .wvalid
			ip2hdm_aximm1_wdata               => CONNECTED_TO_ip2hdm_aximm1_wdata,               --                    .wdata
			ip2hdm_aximm1_wstrb               => CONNECTED_TO_ip2hdm_aximm1_wstrb,               --                    .wstrb
			ip2hdm_aximm1_wlast               => CONNECTED_TO_ip2hdm_aximm1_wlast,               --                    .wlast
			ip2hdm_aximm1_wuser               => CONNECTED_TO_ip2hdm_aximm1_wuser,               --                    .wuser
			hdm2ip_aximm1_wready              => CONNECTED_TO_hdm2ip_aximm1_wready,              --                    .wready
			hdm2ip_aximm1_bvalid              => CONNECTED_TO_hdm2ip_aximm1_bvalid,              --                    .bvlaid
			hdm2ip_aximm1_bid                 => CONNECTED_TO_hdm2ip_aximm1_bid,                 --                    .bid
			hdm2ip_aximm1_buser               => CONNECTED_TO_hdm2ip_aximm1_buser,               --                    .buser
			hdm2ip_aximm1_bresp               => CONNECTED_TO_hdm2ip_aximm1_bresp,               --                    .brsp
			ip2hdm_aximm1_bready              => CONNECTED_TO_ip2hdm_aximm1_bready,              --                    .bready
			ip2hdm_aximm1_arvalid             => CONNECTED_TO_ip2hdm_aximm1_arvalid,             --                    .arvalid
			ip2hdm_aximm1_arid                => CONNECTED_TO_ip2hdm_aximm1_arid,                --                    .arid
			ip2hdm_aximm1_araddr              => CONNECTED_TO_ip2hdm_aximm1_araddr,              --                    .araddr
			ip2hdm_aximm1_arlen               => CONNECTED_TO_ip2hdm_aximm1_arlen,               --                    .arlen
			ip2hdm_aximm1_arregion            => CONNECTED_TO_ip2hdm_aximm1_arregion,            --                    .arregion
			ip2hdm_aximm1_aruser              => CONNECTED_TO_ip2hdm_aximm1_aruser,              --                    .aruser
			ip2hdm_aximm1_arsize              => CONNECTED_TO_ip2hdm_aximm1_arsize,              --                    .arsize
			ip2hdm_aximm1_arburst             => CONNECTED_TO_ip2hdm_aximm1_arburst,             --                    .arburst
			ip2hdm_aximm1_arprot              => CONNECTED_TO_ip2hdm_aximm1_arprot,              --                    .arport
			ip2hdm_aximm1_arqos               => CONNECTED_TO_ip2hdm_aximm1_arqos,               --                    .arqos
			ip2hdm_aximm1_arcache             => CONNECTED_TO_ip2hdm_aximm1_arcache,             --                    .arcache
			ip2hdm_aximm1_arlock              => CONNECTED_TO_ip2hdm_aximm1_arlock,              --                    .arlock
			hdm2ip_aximm1_arready             => CONNECTED_TO_hdm2ip_aximm1_arready,             --                    .arready
			hdm2ip_aximm1_rvalid              => CONNECTED_TO_hdm2ip_aximm1_rvalid,              --                    .rvalid
			hdm2ip_aximm1_rlast               => CONNECTED_TO_hdm2ip_aximm1_rlast,               --                    .rlast
			hdm2ip_aximm1_rid                 => CONNECTED_TO_hdm2ip_aximm1_rid,                 --                    .rid
			hdm2ip_aximm1_rdata               => CONNECTED_TO_hdm2ip_aximm1_rdata,               --                    .rdata
			hdm2ip_aximm1_ruser               => CONNECTED_TO_hdm2ip_aximm1_ruser,               --                    .ruser
			hdm2ip_aximm1_rresp               => CONNECTED_TO_hdm2ip_aximm1_rresp,               --                    .rresp
			ip2hdm_aximm1_rready              => CONNECTED_TO_ip2hdm_aximm1_rready,              --                    .rready
			ip2usr_gpf_ph2_req_o              => CONNECTED_TO_ip2usr_gpf_ph2_req_o,              --             gpf_ph2.gpf_req
			usr2ip_gpf_ph2_ack_i              => CONNECTED_TO_usr2ip_gpf_ph2_ack_i,              --                    .gpf_ack
			usr2ip_cache_evict_policy         => CONNECTED_TO_usr2ip_cache_evict_policy,         --         cache_evict.cache_evict_policy
			phy_sys_ial_0__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_0__pipe_Reset_l,       --     pipe_mode_rtile.if_phy_sys_ial_0__pipe_Reset_l
			phy_sys_ial_1__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_1__pipe_Reset_l,       --                    .if_phy_sys_ial_1__pipe_Reset_l
			phy_sys_ial_2__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_2__pipe_Reset_l,       --                    .if_phy_sys_ial_2__pipe_Reset_l
			phy_sys_ial_3__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_3__pipe_Reset_l,       --                    .if_phy_sys_ial_3__pipe_Reset_l
			phy_sys_ial_4__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_4__pipe_Reset_l,       --                    .if_phy_sys_ial_4__pipe_Reset_l
			phy_sys_ial_5__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_5__pipe_Reset_l,       --                    .if_phy_sys_ial_5__pipe_Reset_l
			phy_sys_ial_6__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_6__pipe_Reset_l,       --                    .if_phy_sys_ial_6__pipe_Reset_l
			phy_sys_ial_7__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_7__pipe_Reset_l,       --                    .if_phy_sys_ial_7__pipe_Reset_l
			phy_sys_ial_8__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_8__pipe_Reset_l,       --                    .if_phy_sys_ial_8__pipe_Reset_l
			phy_sys_ial_9__pipe_Reset_l       => CONNECTED_TO_phy_sys_ial_9__pipe_Reset_l,       --                    .if_phy_sys_ial_9__pipe_Reset_l
			phy_sys_ial_10__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_10__pipe_Reset_l,      --                    .if_phy_sys_ial_10__pipe_Reset_l
			phy_sys_ial_11__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_11__pipe_Reset_l,      --                    .if_phy_sys_ial_11__pipe_Reset_l
			phy_sys_ial_12__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_12__pipe_Reset_l,      --                    .if_phy_sys_ial_12__pipe_Reset_l
			phy_sys_ial_13__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_13__pipe_Reset_l,      --                    .if_phy_sys_ial_13__pipe_Reset_l
			phy_sys_ial_14__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_14__pipe_Reset_l,      --                    .if_phy_sys_ial_14__pipe_Reset_l
			phy_sys_ial_15__pipe_Reset_l      => CONNECTED_TO_phy_sys_ial_15__pipe_Reset_l,      --                    .if_phy_sys_ial_15__pipe_Reset_l
			o_phy_0_pipe_TxDataValid          => CONNECTED_TO_o_phy_0_pipe_TxDataValid,          --                    .if_o_phy_0_pipe_TxDataValid
			o_phy_0_pipe_TxData               => CONNECTED_TO_o_phy_0_pipe_TxData,               --                    .if_o_phy_0_pipe_TxData
			o_phy_0_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_0_pipe_TxDetRxLpbk,          --                    .if_o_phy_0_pipe_TxDetRxLpbk
			o_phy_0_pipe_TxElecIdle           => CONNECTED_TO_o_phy_0_pipe_TxElecIdle,           --                    .if_o_phy_0_pipe_TxElecIdle
			o_phy_0_pipe_PowerDown            => CONNECTED_TO_o_phy_0_pipe_PowerDown,            --                    .if_o_phy_0_pipe_PowerDown
			o_phy_0_pipe_Rate                 => CONNECTED_TO_o_phy_0_pipe_Rate,                 --                    .if_o_phy_0_pipe_Rate
			o_phy_0_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_0_pipe_PclkChangeAck,        --                    .if_o_phy_0_pipe_PclkChangeAck
			o_phy_0_pipe_PCLKRate             => CONNECTED_TO_o_phy_0_pipe_PCLKRate,             --                    .if_o_phy_0_pipe_PCLKRate
			o_phy_0_pipe_Width                => CONNECTED_TO_o_phy_0_pipe_Width,                --                    .if_o_phy_0_pipe_Width
			o_phy_0_pipe_PCLK                 => CONNECTED_TO_o_phy_0_pipe_PCLK,                 --                    .if_o_phy_0_pipe_PCLK
			o_phy_0_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_0_pipe_rxelecidle_disable,   --                    .if_o_phy_0_pipe_rxelecidle_disable
			o_phy_0_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_0_pipe_txcmnmode_disable,    --                    .if_o_phy_0_pipe_txcmnmode_disable
			o_phy_0_pipe_srisenable           => CONNECTED_TO_o_phy_0_pipe_srisenable,           --                    .if_o_phy_0_pipe_srisenable
			i_phy_0_pipe_RxClk                => CONNECTED_TO_i_phy_0_pipe_RxClk,                --                    .if_i_phy_0_pipe_RxClk
			i_phy_0_pipe_RxValid              => CONNECTED_TO_i_phy_0_pipe_RxValid,              --                    .if_i_phy_0_pipe_RxValid
			i_phy_0_pipe_RxData               => CONNECTED_TO_i_phy_0_pipe_RxData,               --                    .if_i_phy_0_pipe_RxData
			i_phy_0_pipe_RxElecIdle           => CONNECTED_TO_i_phy_0_pipe_RxElecIdle,           --                    .if_i_phy_0_pipe_RxElecIdle
			i_phy_0_pipe_RxStatus             => CONNECTED_TO_i_phy_0_pipe_RxStatus,             --                    .if_i_phy_0_pipe_RxStatus
			i_phy_0_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_0_pipe_RxStandbyStatus,      --                    .if_i_phy_0_pipe_RxStandbyStatus
			o_phy_0_pipe_RxStandby            => CONNECTED_TO_o_phy_0_pipe_RxStandby,            --                    .if_o_phy_0_pipe_RxStandby
			o_phy_0_pipe_RxTermination        => CONNECTED_TO_o_phy_0_pipe_RxTermination,        --                    .if_o_phy_0_pipe_RxTermination
			o_phy_0_pipe_RxWidth              => CONNECTED_TO_o_phy_0_pipe_RxWidth,              --                    .if_o_phy_0_pipe_RxWidth
			i_phy_0_pipe_PhyStatus            => CONNECTED_TO_i_phy_0_pipe_PhyStatus,            --                    .if_i_phy_0_pipe_PhyStatus
			i_phy_0_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_0_pipe_PclkChangeOk,         --                    .if_i_phy_0_pipe_PclkChangeOk
			o_phy_0_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_0_pipe_M2P_MessageBus,       --                    .if_o_phy_0_pipe_M2P_MessageBus
			i_phy_0_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_0_pipe_P2M_MessageBus,       --                    .if_i_phy_0_pipe_P2M_MessageBus
			o_phy_1_pipe_TxDataValid          => CONNECTED_TO_o_phy_1_pipe_TxDataValid,          --                    .if_o_phy_1_pipe_TxDataValid
			o_phy_1_pipe_TxData               => CONNECTED_TO_o_phy_1_pipe_TxData,               --                    .if_o_phy_1_pipe_TxData
			o_phy_1_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_1_pipe_TxDetRxLpbk,          --                    .if_o_phy_1_pipe_TxDetRxLpbk
			o_phy_1_pipe_TxElecIdle           => CONNECTED_TO_o_phy_1_pipe_TxElecIdle,           --                    .if_o_phy_1_pipe_TxElecIdle
			o_phy_1_pipe_PowerDown            => CONNECTED_TO_o_phy_1_pipe_PowerDown,            --                    .if_o_phy_1_pipe_PowerDown
			o_phy_1_pipe_Rate                 => CONNECTED_TO_o_phy_1_pipe_Rate,                 --                    .if_o_phy_1_pipe_Rate
			o_phy_1_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_1_pipe_PclkChangeAck,        --                    .if_o_phy_1_pipe_PclkChangeAck
			o_phy_1_pipe_PCLKRate             => CONNECTED_TO_o_phy_1_pipe_PCLKRate,             --                    .if_o_phy_1_pipe_PCLKRate
			o_phy_1_pipe_Width                => CONNECTED_TO_o_phy_1_pipe_Width,                --                    .if_o_phy_1_pipe_Width
			o_phy_1_pipe_PCLK                 => CONNECTED_TO_o_phy_1_pipe_PCLK,                 --                    .if_o_phy_1_pipe_PCLK
			o_phy_1_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_1_pipe_rxelecidle_disable,   --                    .if_o_phy_1_pipe_rxelecidle_disable
			o_phy_1_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_1_pipe_txcmnmode_disable,    --                    .if_o_phy_1_pipe_txcmnmode_disable
			o_phy_1_pipe_srisenable           => CONNECTED_TO_o_phy_1_pipe_srisenable,           --                    .if_o_phy_1_pipe_srisenable
			i_phy_1_pipe_RxClk                => CONNECTED_TO_i_phy_1_pipe_RxClk,                --                    .if_i_phy_1_pipe_RxClk
			i_phy_1_pipe_RxValid              => CONNECTED_TO_i_phy_1_pipe_RxValid,              --                    .if_i_phy_1_pipe_RxValid
			i_phy_1_pipe_RxData               => CONNECTED_TO_i_phy_1_pipe_RxData,               --                    .if_i_phy_1_pipe_RxData
			i_phy_1_pipe_RxElecIdle           => CONNECTED_TO_i_phy_1_pipe_RxElecIdle,           --                    .if_i_phy_1_pipe_RxElecIdle
			i_phy_1_pipe_RxStatus             => CONNECTED_TO_i_phy_1_pipe_RxStatus,             --                    .if_i_phy_1_pipe_RxStatus
			i_phy_1_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_1_pipe_RxStandbyStatus,      --                    .if_i_phy_1_pipe_RxStandbyStatus
			o_phy_1_pipe_RxStandby            => CONNECTED_TO_o_phy_1_pipe_RxStandby,            --                    .if_o_phy_1_pipe_RxStandby
			o_phy_1_pipe_RxTermination        => CONNECTED_TO_o_phy_1_pipe_RxTermination,        --                    .if_o_phy_1_pipe_RxTermination
			o_phy_1_pipe_RxWidth              => CONNECTED_TO_o_phy_1_pipe_RxWidth,              --                    .if_o_phy_1_pipe_RxWidth
			i_phy_1_pipe_PhyStatus            => CONNECTED_TO_i_phy_1_pipe_PhyStatus,            --                    .if_i_phy_1_pipe_PhyStatus
			i_phy_1_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_1_pipe_PclkChangeOk,         --                    .if_i_phy_1_pipe_PclkChangeOk
			o_phy_1_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_1_pipe_M2P_MessageBus,       --                    .if_o_phy_1_pipe_M2P_MessageBus
			i_phy_1_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_1_pipe_P2M_MessageBus,       --                    .if_i_phy_1_pipe_P2M_MessageBus
			o_phy_2_pipe_TxDataValid          => CONNECTED_TO_o_phy_2_pipe_TxDataValid,          --                    .if_o_phy_2_pipe_TxDataValid
			o_phy_2_pipe_TxData               => CONNECTED_TO_o_phy_2_pipe_TxData,               --                    .if_o_phy_2_pipe_TxData
			o_phy_2_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_2_pipe_TxDetRxLpbk,          --                    .if_o_phy_2_pipe_TxDetRxLpbk
			o_phy_2_pipe_TxElecIdle           => CONNECTED_TO_o_phy_2_pipe_TxElecIdle,           --                    .if_o_phy_2_pipe_TxElecIdle
			o_phy_2_pipe_PowerDown            => CONNECTED_TO_o_phy_2_pipe_PowerDown,            --                    .if_o_phy_2_pipe_PowerDown
			o_phy_2_pipe_Rate                 => CONNECTED_TO_o_phy_2_pipe_Rate,                 --                    .if_o_phy_2_pipe_Rate
			o_phy_2_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_2_pipe_PclkChangeAck,        --                    .if_o_phy_2_pipe_PclkChangeAck
			o_phy_2_pipe_PCLKRate             => CONNECTED_TO_o_phy_2_pipe_PCLKRate,             --                    .if_o_phy_2_pipe_PCLKRate
			o_phy_2_pipe_Width                => CONNECTED_TO_o_phy_2_pipe_Width,                --                    .if_o_phy_2_pipe_Width
			o_phy_2_pipe_PCLK                 => CONNECTED_TO_o_phy_2_pipe_PCLK,                 --                    .if_o_phy_2_pipe_PCLK
			o_phy_2_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_2_pipe_rxelecidle_disable,   --                    .if_o_phy_2_pipe_rxelecidle_disable
			o_phy_2_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_2_pipe_txcmnmode_disable,    --                    .if_o_phy_2_pipe_txcmnmode_disable
			o_phy_2_pipe_srisenable           => CONNECTED_TO_o_phy_2_pipe_srisenable,           --                    .if_o_phy_2_pipe_srisenable
			i_phy_2_pipe_RxClk                => CONNECTED_TO_i_phy_2_pipe_RxClk,                --                    .if_i_phy_2_pipe_RxClk
			i_phy_2_pipe_RxValid              => CONNECTED_TO_i_phy_2_pipe_RxValid,              --                    .if_i_phy_2_pipe_RxValid
			i_phy_2_pipe_RxData               => CONNECTED_TO_i_phy_2_pipe_RxData,               --                    .if_i_phy_2_pipe_RxData
			i_phy_2_pipe_RxElecIdle           => CONNECTED_TO_i_phy_2_pipe_RxElecIdle,           --                    .if_i_phy_2_pipe_RxElecIdle
			i_phy_2_pipe_RxStatus             => CONNECTED_TO_i_phy_2_pipe_RxStatus,             --                    .if_i_phy_2_pipe_RxStatus
			i_phy_2_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_2_pipe_RxStandbyStatus,      --                    .if_i_phy_2_pipe_RxStandbyStatus
			o_phy_2_pipe_RxStandby            => CONNECTED_TO_o_phy_2_pipe_RxStandby,            --                    .if_o_phy_2_pipe_RxStandby
			o_phy_2_pipe_RxTermination        => CONNECTED_TO_o_phy_2_pipe_RxTermination,        --                    .if_o_phy_2_pipe_RxTermination
			o_phy_2_pipe_RxWidth              => CONNECTED_TO_o_phy_2_pipe_RxWidth,              --                    .if_o_phy_2_pipe_RxWidth
			i_phy_2_pipe_PhyStatus            => CONNECTED_TO_i_phy_2_pipe_PhyStatus,            --                    .if_i_phy_2_pipe_PhyStatus
			i_phy_2_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_2_pipe_PclkChangeOk,         --                    .if_i_phy_2_pipe_PclkChangeOk
			o_phy_2_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_2_pipe_M2P_MessageBus,       --                    .if_o_phy_2_pipe_M2P_MessageBus
			i_phy_2_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_2_pipe_P2M_MessageBus,       --                    .if_i_phy_2_pipe_P2M_MessageBus
			o_phy_3_pipe_TxDataValid          => CONNECTED_TO_o_phy_3_pipe_TxDataValid,          --                    .if_o_phy_3_pipe_TxDataValid
			o_phy_3_pipe_TxData               => CONNECTED_TO_o_phy_3_pipe_TxData,               --                    .if_o_phy_3_pipe_TxData
			o_phy_3_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_3_pipe_TxDetRxLpbk,          --                    .if_o_phy_3_pipe_TxDetRxLpbk
			o_phy_3_pipe_TxElecIdle           => CONNECTED_TO_o_phy_3_pipe_TxElecIdle,           --                    .if_o_phy_3_pipe_TxElecIdle
			o_phy_3_pipe_PowerDown            => CONNECTED_TO_o_phy_3_pipe_PowerDown,            --                    .if_o_phy_3_pipe_PowerDown
			o_phy_3_pipe_Rate                 => CONNECTED_TO_o_phy_3_pipe_Rate,                 --                    .if_o_phy_3_pipe_Rate
			o_phy_3_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_3_pipe_PclkChangeAck,        --                    .if_o_phy_3_pipe_PclkChangeAck
			o_phy_3_pipe_PCLKRate             => CONNECTED_TO_o_phy_3_pipe_PCLKRate,             --                    .if_o_phy_3_pipe_PCLKRate
			o_phy_3_pipe_Width                => CONNECTED_TO_o_phy_3_pipe_Width,                --                    .if_o_phy_3_pipe_Width
			o_phy_3_pipe_PCLK                 => CONNECTED_TO_o_phy_3_pipe_PCLK,                 --                    .if_o_phy_3_pipe_PCLK
			o_phy_3_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_3_pipe_rxelecidle_disable,   --                    .if_o_phy_3_pipe_rxelecidle_disable
			o_phy_3_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_3_pipe_txcmnmode_disable,    --                    .if_o_phy_3_pipe_txcmnmode_disable
			o_phy_3_pipe_srisenable           => CONNECTED_TO_o_phy_3_pipe_srisenable,           --                    .if_o_phy_3_pipe_srisenable
			i_phy_3_pipe_RxClk                => CONNECTED_TO_i_phy_3_pipe_RxClk,                --                    .if_i_phy_3_pipe_RxClk
			i_phy_3_pipe_RxValid              => CONNECTED_TO_i_phy_3_pipe_RxValid,              --                    .if_i_phy_3_pipe_RxValid
			i_phy_3_pipe_RxData               => CONNECTED_TO_i_phy_3_pipe_RxData,               --                    .if_i_phy_3_pipe_RxData
			i_phy_3_pipe_RxElecIdle           => CONNECTED_TO_i_phy_3_pipe_RxElecIdle,           --                    .if_i_phy_3_pipe_RxElecIdle
			i_phy_3_pipe_RxStatus             => CONNECTED_TO_i_phy_3_pipe_RxStatus,             --                    .if_i_phy_3_pipe_RxStatus
			i_phy_3_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_3_pipe_RxStandbyStatus,      --                    .if_i_phy_3_pipe_RxStandbyStatus
			o_phy_3_pipe_RxStandby            => CONNECTED_TO_o_phy_3_pipe_RxStandby,            --                    .if_o_phy_3_pipe_RxStandby
			o_phy_3_pipe_RxTermination        => CONNECTED_TO_o_phy_3_pipe_RxTermination,        --                    .if_o_phy_3_pipe_RxTermination
			o_phy_3_pipe_RxWidth              => CONNECTED_TO_o_phy_3_pipe_RxWidth,              --                    .if_o_phy_3_pipe_RxWidth
			i_phy_3_pipe_PhyStatus            => CONNECTED_TO_i_phy_3_pipe_PhyStatus,            --                    .if_i_phy_3_pipe_PhyStatus
			i_phy_3_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_3_pipe_PclkChangeOk,         --                    .if_i_phy_3_pipe_PclkChangeOk
			o_phy_3_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_3_pipe_M2P_MessageBus,       --                    .if_o_phy_3_pipe_M2P_MessageBus
			i_phy_3_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_3_pipe_P2M_MessageBus,       --                    .if_i_phy_3_pipe_P2M_MessageBus
			o_phy_4_pipe_TxDataValid          => CONNECTED_TO_o_phy_4_pipe_TxDataValid,          --                    .if_o_phy_4_pipe_TxDataValid
			o_phy_4_pipe_TxData               => CONNECTED_TO_o_phy_4_pipe_TxData,               --                    .if_o_phy_4_pipe_TxData
			o_phy_4_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_4_pipe_TxDetRxLpbk,          --                    .if_o_phy_4_pipe_TxDetRxLpbk
			o_phy_4_pipe_TxElecIdle           => CONNECTED_TO_o_phy_4_pipe_TxElecIdle,           --                    .if_o_phy_4_pipe_TxElecIdle
			o_phy_4_pipe_PowerDown            => CONNECTED_TO_o_phy_4_pipe_PowerDown,            --                    .if_o_phy_4_pipe_PowerDown
			o_phy_4_pipe_Rate                 => CONNECTED_TO_o_phy_4_pipe_Rate,                 --                    .if_o_phy_4_pipe_Rate
			o_phy_4_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_4_pipe_PclkChangeAck,        --                    .if_o_phy_4_pipe_PclkChangeAck
			o_phy_4_pipe_PCLKRate             => CONNECTED_TO_o_phy_4_pipe_PCLKRate,             --                    .if_o_phy_4_pipe_PCLKRate
			o_phy_4_pipe_Width                => CONNECTED_TO_o_phy_4_pipe_Width,                --                    .if_o_phy_4_pipe_Width
			o_phy_4_pipe_PCLK                 => CONNECTED_TO_o_phy_4_pipe_PCLK,                 --                    .if_o_phy_4_pipe_PCLK
			o_phy_4_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_4_pipe_rxelecidle_disable,   --                    .if_o_phy_4_pipe_rxelecidle_disable
			o_phy_4_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_4_pipe_txcmnmode_disable,    --                    .if_o_phy_4_pipe_txcmnmode_disable
			o_phy_4_pipe_srisenable           => CONNECTED_TO_o_phy_4_pipe_srisenable,           --                    .if_o_phy_4_pipe_srisenable
			i_phy_4_pipe_RxClk                => CONNECTED_TO_i_phy_4_pipe_RxClk,                --                    .if_i_phy_4_pipe_RxClk
			i_phy_4_pipe_RxValid              => CONNECTED_TO_i_phy_4_pipe_RxValid,              --                    .if_i_phy_4_pipe_RxValid
			i_phy_4_pipe_RxData               => CONNECTED_TO_i_phy_4_pipe_RxData,               --                    .if_i_phy_4_pipe_RxData
			i_phy_4_pipe_RxElecIdle           => CONNECTED_TO_i_phy_4_pipe_RxElecIdle,           --                    .if_i_phy_4_pipe_RxElecIdle
			i_phy_4_pipe_RxStatus             => CONNECTED_TO_i_phy_4_pipe_RxStatus,             --                    .if_i_phy_4_pipe_RxStatus
			i_phy_4_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_4_pipe_RxStandbyStatus,      --                    .if_i_phy_4_pipe_RxStandbyStatus
			o_phy_4_pipe_RxStandby            => CONNECTED_TO_o_phy_4_pipe_RxStandby,            --                    .if_o_phy_4_pipe_RxStandby
			o_phy_4_pipe_RxTermination        => CONNECTED_TO_o_phy_4_pipe_RxTermination,        --                    .if_o_phy_4_pipe_RxTermination
			o_phy_4_pipe_RxWidth              => CONNECTED_TO_o_phy_4_pipe_RxWidth,              --                    .if_o_phy_4_pipe_RxWidth
			i_phy_4_pipe_PhyStatus            => CONNECTED_TO_i_phy_4_pipe_PhyStatus,            --                    .if_i_phy_4_pipe_PhyStatus
			i_phy_4_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_4_pipe_PclkChangeOk,         --                    .if_i_phy_4_pipe_PclkChangeOk
			o_phy_4_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_4_pipe_M2P_MessageBus,       --                    .if_o_phy_4_pipe_M2P_MessageBus
			i_phy_4_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_4_pipe_P2M_MessageBus,       --                    .if_i_phy_4_pipe_P2M_MessageBus
			o_phy_5_pipe_TxDataValid          => CONNECTED_TO_o_phy_5_pipe_TxDataValid,          --                    .if_o_phy_5_pipe_TxDataValid
			o_phy_5_pipe_TxData               => CONNECTED_TO_o_phy_5_pipe_TxData,               --                    .if_o_phy_5_pipe_TxData
			o_phy_5_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_5_pipe_TxDetRxLpbk,          --                    .if_o_phy_5_pipe_TxDetRxLpbk
			o_phy_5_pipe_TxElecIdle           => CONNECTED_TO_o_phy_5_pipe_TxElecIdle,           --                    .if_o_phy_5_pipe_TxElecIdle
			o_phy_5_pipe_PowerDown            => CONNECTED_TO_o_phy_5_pipe_PowerDown,            --                    .if_o_phy_5_pipe_PowerDown
			o_phy_5_pipe_Rate                 => CONNECTED_TO_o_phy_5_pipe_Rate,                 --                    .if_o_phy_5_pipe_Rate
			o_phy_5_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_5_pipe_PclkChangeAck,        --                    .if_o_phy_5_pipe_PclkChangeAck
			o_phy_5_pipe_PCLKRate             => CONNECTED_TO_o_phy_5_pipe_PCLKRate,             --                    .if_o_phy_5_pipe_PCLKRate
			o_phy_5_pipe_Width                => CONNECTED_TO_o_phy_5_pipe_Width,                --                    .if_o_phy_5_pipe_Width
			o_phy_5_pipe_PCLK                 => CONNECTED_TO_o_phy_5_pipe_PCLK,                 --                    .if_o_phy_5_pipe_PCLK
			o_phy_5_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_5_pipe_rxelecidle_disable,   --                    .if_o_phy_5_pipe_rxelecidle_disable
			o_phy_5_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_5_pipe_txcmnmode_disable,    --                    .if_o_phy_5_pipe_txcmnmode_disable
			o_phy_5_pipe_srisenable           => CONNECTED_TO_o_phy_5_pipe_srisenable,           --                    .if_o_phy_5_pipe_srisenable
			i_phy_5_pipe_RxClk                => CONNECTED_TO_i_phy_5_pipe_RxClk,                --                    .if_i_phy_5_pipe_RxClk
			i_phy_5_pipe_RxValid              => CONNECTED_TO_i_phy_5_pipe_RxValid,              --                    .if_i_phy_5_pipe_RxValid
			i_phy_5_pipe_RxData               => CONNECTED_TO_i_phy_5_pipe_RxData,               --                    .if_i_phy_5_pipe_RxData
			i_phy_5_pipe_RxElecIdle           => CONNECTED_TO_i_phy_5_pipe_RxElecIdle,           --                    .if_i_phy_5_pipe_RxElecIdle
			i_phy_5_pipe_RxStatus             => CONNECTED_TO_i_phy_5_pipe_RxStatus,             --                    .if_i_phy_5_pipe_RxStatus
			i_phy_5_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_5_pipe_RxStandbyStatus,      --                    .if_i_phy_5_pipe_RxStandbyStatus
			o_phy_5_pipe_RxStandby            => CONNECTED_TO_o_phy_5_pipe_RxStandby,            --                    .if_o_phy_5_pipe_RxStandby
			o_phy_5_pipe_RxTermination        => CONNECTED_TO_o_phy_5_pipe_RxTermination,        --                    .if_o_phy_5_pipe_RxTermination
			o_phy_5_pipe_RxWidth              => CONNECTED_TO_o_phy_5_pipe_RxWidth,              --                    .if_o_phy_5_pipe_RxWidth
			i_phy_5_pipe_PhyStatus            => CONNECTED_TO_i_phy_5_pipe_PhyStatus,            --                    .if_i_phy_5_pipe_PhyStatus
			i_phy_5_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_5_pipe_PclkChangeOk,         --                    .if_i_phy_5_pipe_PclkChangeOk
			o_phy_5_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_5_pipe_M2P_MessageBus,       --                    .if_o_phy_5_pipe_M2P_MessageBus
			i_phy_5_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_5_pipe_P2M_MessageBus,       --                    .if_i_phy_5_pipe_P2M_MessageBus
			o_phy_6_pipe_TxDataValid          => CONNECTED_TO_o_phy_6_pipe_TxDataValid,          --                    .if_o_phy_6_pipe_TxDataValid
			o_phy_6_pipe_TxData               => CONNECTED_TO_o_phy_6_pipe_TxData,               --                    .if_o_phy_6_pipe_TxData
			o_phy_6_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_6_pipe_TxDetRxLpbk,          --                    .if_o_phy_6_pipe_TxDetRxLpbk
			o_phy_6_pipe_TxElecIdle           => CONNECTED_TO_o_phy_6_pipe_TxElecIdle,           --                    .if_o_phy_6_pipe_TxElecIdle
			o_phy_6_pipe_PowerDown            => CONNECTED_TO_o_phy_6_pipe_PowerDown,            --                    .if_o_phy_6_pipe_PowerDown
			o_phy_6_pipe_Rate                 => CONNECTED_TO_o_phy_6_pipe_Rate,                 --                    .if_o_phy_6_pipe_Rate
			o_phy_6_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_6_pipe_PclkChangeAck,        --                    .if_o_phy_6_pipe_PclkChangeAck
			o_phy_6_pipe_PCLKRate             => CONNECTED_TO_o_phy_6_pipe_PCLKRate,             --                    .if_o_phy_6_pipe_PCLKRate
			o_phy_6_pipe_Width                => CONNECTED_TO_o_phy_6_pipe_Width,                --                    .if_o_phy_6_pipe_Width
			o_phy_6_pipe_PCLK                 => CONNECTED_TO_o_phy_6_pipe_PCLK,                 --                    .if_o_phy_6_pipe_PCLK
			o_phy_6_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_6_pipe_rxelecidle_disable,   --                    .if_o_phy_6_pipe_rxelecidle_disable
			o_phy_6_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_6_pipe_txcmnmode_disable,    --                    .if_o_phy_6_pipe_txcmnmode_disable
			o_phy_6_pipe_srisenable           => CONNECTED_TO_o_phy_6_pipe_srisenable,           --                    .if_o_phy_6_pipe_srisenable
			i_phy_6_pipe_RxClk                => CONNECTED_TO_i_phy_6_pipe_RxClk,                --                    .if_i_phy_6_pipe_RxClk
			i_phy_6_pipe_RxValid              => CONNECTED_TO_i_phy_6_pipe_RxValid,              --                    .if_i_phy_6_pipe_RxValid
			i_phy_6_pipe_RxData               => CONNECTED_TO_i_phy_6_pipe_RxData,               --                    .if_i_phy_6_pipe_RxData
			i_phy_6_pipe_RxElecIdle           => CONNECTED_TO_i_phy_6_pipe_RxElecIdle,           --                    .if_i_phy_6_pipe_RxElecIdle
			i_phy_6_pipe_RxStatus             => CONNECTED_TO_i_phy_6_pipe_RxStatus,             --                    .if_i_phy_6_pipe_RxStatus
			i_phy_6_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_6_pipe_RxStandbyStatus,      --                    .if_i_phy_6_pipe_RxStandbyStatus
			o_phy_6_pipe_RxStandby            => CONNECTED_TO_o_phy_6_pipe_RxStandby,            --                    .if_o_phy_6_pipe_RxStandby
			o_phy_6_pipe_RxTermination        => CONNECTED_TO_o_phy_6_pipe_RxTermination,        --                    .if_o_phy_6_pipe_RxTermination
			o_phy_6_pipe_RxWidth              => CONNECTED_TO_o_phy_6_pipe_RxWidth,              --                    .if_o_phy_6_pipe_RxWidth
			i_phy_6_pipe_PhyStatus            => CONNECTED_TO_i_phy_6_pipe_PhyStatus,            --                    .if_i_phy_6_pipe_PhyStatus
			i_phy_6_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_6_pipe_PclkChangeOk,         --                    .if_i_phy_6_pipe_PclkChangeOk
			o_phy_6_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_6_pipe_M2P_MessageBus,       --                    .if_o_phy_6_pipe_M2P_MessageBus
			i_phy_6_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_6_pipe_P2M_MessageBus,       --                    .if_i_phy_6_pipe_P2M_MessageBus
			o_phy_7_pipe_TxDataValid          => CONNECTED_TO_o_phy_7_pipe_TxDataValid,          --                    .if_o_phy_7_pipe_TxDataValid
			o_phy_7_pipe_TxData               => CONNECTED_TO_o_phy_7_pipe_TxData,               --                    .if_o_phy_7_pipe_TxData
			o_phy_7_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_7_pipe_TxDetRxLpbk,          --                    .if_o_phy_7_pipe_TxDetRxLpbk
			o_phy_7_pipe_TxElecIdle           => CONNECTED_TO_o_phy_7_pipe_TxElecIdle,           --                    .if_o_phy_7_pipe_TxElecIdle
			o_phy_7_pipe_PowerDown            => CONNECTED_TO_o_phy_7_pipe_PowerDown,            --                    .if_o_phy_7_pipe_PowerDown
			o_phy_7_pipe_Rate                 => CONNECTED_TO_o_phy_7_pipe_Rate,                 --                    .if_o_phy_7_pipe_Rate
			o_phy_7_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_7_pipe_PclkChangeAck,        --                    .if_o_phy_7_pipe_PclkChangeAck
			o_phy_7_pipe_PCLKRate             => CONNECTED_TO_o_phy_7_pipe_PCLKRate,             --                    .if_o_phy_7_pipe_PCLKRate
			o_phy_7_pipe_Width                => CONNECTED_TO_o_phy_7_pipe_Width,                --                    .if_o_phy_7_pipe_Width
			o_phy_7_pipe_PCLK                 => CONNECTED_TO_o_phy_7_pipe_PCLK,                 --                    .if_o_phy_7_pipe_PCLK
			o_phy_7_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_7_pipe_rxelecidle_disable,   --                    .if_o_phy_7_pipe_rxelecidle_disable
			o_phy_7_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_7_pipe_txcmnmode_disable,    --                    .if_o_phy_7_pipe_txcmnmode_disable
			o_phy_7_pipe_srisenable           => CONNECTED_TO_o_phy_7_pipe_srisenable,           --                    .if_o_phy_7_pipe_srisenable
			i_phy_7_pipe_RxClk                => CONNECTED_TO_i_phy_7_pipe_RxClk,                --                    .if_i_phy_7_pipe_RxClk
			i_phy_7_pipe_RxValid              => CONNECTED_TO_i_phy_7_pipe_RxValid,              --                    .if_i_phy_7_pipe_RxValid
			i_phy_7_pipe_RxData               => CONNECTED_TO_i_phy_7_pipe_RxData,               --                    .if_i_phy_7_pipe_RxData
			i_phy_7_pipe_RxElecIdle           => CONNECTED_TO_i_phy_7_pipe_RxElecIdle,           --                    .if_i_phy_7_pipe_RxElecIdle
			i_phy_7_pipe_RxStatus             => CONNECTED_TO_i_phy_7_pipe_RxStatus,             --                    .if_i_phy_7_pipe_RxStatus
			i_phy_7_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_7_pipe_RxStandbyStatus,      --                    .if_i_phy_7_pipe_RxStandbyStatus
			o_phy_7_pipe_RxStandby            => CONNECTED_TO_o_phy_7_pipe_RxStandby,            --                    .if_o_phy_7_pipe_RxStandby
			o_phy_7_pipe_RxTermination        => CONNECTED_TO_o_phy_7_pipe_RxTermination,        --                    .if_o_phy_7_pipe_RxTermination
			o_phy_7_pipe_RxWidth              => CONNECTED_TO_o_phy_7_pipe_RxWidth,              --                    .if_o_phy_7_pipe_RxWidth
			i_phy_7_pipe_PhyStatus            => CONNECTED_TO_i_phy_7_pipe_PhyStatus,            --                    .if_i_phy_7_pipe_PhyStatus
			i_phy_7_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_7_pipe_PclkChangeOk,         --                    .if_i_phy_7_pipe_PclkChangeOk
			o_phy_7_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_7_pipe_M2P_MessageBus,       --                    .if_o_phy_7_pipe_M2P_MessageBus
			i_phy_7_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_7_pipe_P2M_MessageBus,       --                    .if_i_phy_7_pipe_P2M_MessageBus
			o_phy_8_pipe_TxDataValid          => CONNECTED_TO_o_phy_8_pipe_TxDataValid,          --                    .if_o_phy_8_pipe_TxDataValid
			o_phy_8_pipe_TxData               => CONNECTED_TO_o_phy_8_pipe_TxData,               --                    .if_o_phy_8_pipe_TxData
			o_phy_8_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_8_pipe_TxDetRxLpbk,          --                    .if_o_phy_8_pipe_TxDetRxLpbk
			o_phy_8_pipe_TxElecIdle           => CONNECTED_TO_o_phy_8_pipe_TxElecIdle,           --                    .if_o_phy_8_pipe_TxElecIdle
			o_phy_8_pipe_PowerDown            => CONNECTED_TO_o_phy_8_pipe_PowerDown,            --                    .if_o_phy_8_pipe_PowerDown
			o_phy_8_pipe_Rate                 => CONNECTED_TO_o_phy_8_pipe_Rate,                 --                    .if_o_phy_8_pipe_Rate
			o_phy_8_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_8_pipe_PclkChangeAck,        --                    .if_o_phy_8_pipe_PclkChangeAck
			o_phy_8_pipe_PCLKRate             => CONNECTED_TO_o_phy_8_pipe_PCLKRate,             --                    .if_o_phy_8_pipe_PCLKRate
			o_phy_8_pipe_Width                => CONNECTED_TO_o_phy_8_pipe_Width,                --                    .if_o_phy_8_pipe_Width
			o_phy_8_pipe_PCLK                 => CONNECTED_TO_o_phy_8_pipe_PCLK,                 --                    .if_o_phy_8_pipe_PCLK
			o_phy_8_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_8_pipe_rxelecidle_disable,   --                    .if_o_phy_8_pipe_rxelecidle_disable
			o_phy_8_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_8_pipe_txcmnmode_disable,    --                    .if_o_phy_8_pipe_txcmnmode_disable
			o_phy_8_pipe_srisenable           => CONNECTED_TO_o_phy_8_pipe_srisenable,           --                    .if_o_phy_8_pipe_srisenable
			i_phy_8_pipe_RxClk                => CONNECTED_TO_i_phy_8_pipe_RxClk,                --                    .if_i_phy_8_pipe_RxClk
			i_phy_8_pipe_RxValid              => CONNECTED_TO_i_phy_8_pipe_RxValid,              --                    .if_i_phy_8_pipe_RxValid
			i_phy_8_pipe_RxData               => CONNECTED_TO_i_phy_8_pipe_RxData,               --                    .if_i_phy_8_pipe_RxData
			i_phy_8_pipe_RxElecIdle           => CONNECTED_TO_i_phy_8_pipe_RxElecIdle,           --                    .if_i_phy_8_pipe_RxElecIdle
			i_phy_8_pipe_RxStatus             => CONNECTED_TO_i_phy_8_pipe_RxStatus,             --                    .if_i_phy_8_pipe_RxStatus
			i_phy_8_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_8_pipe_RxStandbyStatus,      --                    .if_i_phy_8_pipe_RxStandbyStatus
			o_phy_8_pipe_RxStandby            => CONNECTED_TO_o_phy_8_pipe_RxStandby,            --                    .if_o_phy_8_pipe_RxStandby
			o_phy_8_pipe_RxTermination        => CONNECTED_TO_o_phy_8_pipe_RxTermination,        --                    .if_o_phy_8_pipe_RxTermination
			o_phy_8_pipe_RxWidth              => CONNECTED_TO_o_phy_8_pipe_RxWidth,              --                    .if_o_phy_8_pipe_RxWidth
			i_phy_8_pipe_PhyStatus            => CONNECTED_TO_i_phy_8_pipe_PhyStatus,            --                    .if_i_phy_8_pipe_PhyStatus
			i_phy_8_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_8_pipe_PclkChangeOk,         --                    .if_i_phy_8_pipe_PclkChangeOk
			o_phy_8_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_8_pipe_M2P_MessageBus,       --                    .if_o_phy_8_pipe_M2P_MessageBus
			i_phy_8_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_8_pipe_P2M_MessageBus,       --                    .if_i_phy_8_pipe_P2M_MessageBus
			o_phy_9_pipe_TxDataValid          => CONNECTED_TO_o_phy_9_pipe_TxDataValid,          --                    .if_o_phy_9_pipe_TxDataValid
			o_phy_9_pipe_TxData               => CONNECTED_TO_o_phy_9_pipe_TxData,               --                    .if_o_phy_9_pipe_TxData
			o_phy_9_pipe_TxDetRxLpbk          => CONNECTED_TO_o_phy_9_pipe_TxDetRxLpbk,          --                    .if_o_phy_9_pipe_TxDetRxLpbk
			o_phy_9_pipe_TxElecIdle           => CONNECTED_TO_o_phy_9_pipe_TxElecIdle,           --                    .if_o_phy_9_pipe_TxElecIdle
			o_phy_9_pipe_PowerDown            => CONNECTED_TO_o_phy_9_pipe_PowerDown,            --                    .if_o_phy_9_pipe_PowerDown
			o_phy_9_pipe_Rate                 => CONNECTED_TO_o_phy_9_pipe_Rate,                 --                    .if_o_phy_9_pipe_Rate
			o_phy_9_pipe_PclkChangeAck        => CONNECTED_TO_o_phy_9_pipe_PclkChangeAck,        --                    .if_o_phy_9_pipe_PclkChangeAck
			o_phy_9_pipe_PCLKRate             => CONNECTED_TO_o_phy_9_pipe_PCLKRate,             --                    .if_o_phy_9_pipe_PCLKRate
			o_phy_9_pipe_Width                => CONNECTED_TO_o_phy_9_pipe_Width,                --                    .if_o_phy_9_pipe_Width
			o_phy_9_pipe_PCLK                 => CONNECTED_TO_o_phy_9_pipe_PCLK,                 --                    .if_o_phy_9_pipe_PCLK
			o_phy_9_pipe_rxelecidle_disable   => CONNECTED_TO_o_phy_9_pipe_rxelecidle_disable,   --                    .if_o_phy_9_pipe_rxelecidle_disable
			o_phy_9_pipe_txcmnmode_disable    => CONNECTED_TO_o_phy_9_pipe_txcmnmode_disable,    --                    .if_o_phy_9_pipe_txcmnmode_disable
			o_phy_9_pipe_srisenable           => CONNECTED_TO_o_phy_9_pipe_srisenable,           --                    .if_o_phy_9_pipe_srisenable
			i_phy_9_pipe_RxClk                => CONNECTED_TO_i_phy_9_pipe_RxClk,                --                    .if_i_phy_9_pipe_RxClk
			i_phy_9_pipe_RxValid              => CONNECTED_TO_i_phy_9_pipe_RxValid,              --                    .if_i_phy_9_pipe_RxValid
			i_phy_9_pipe_RxData               => CONNECTED_TO_i_phy_9_pipe_RxData,               --                    .if_i_phy_9_pipe_RxData
			i_phy_9_pipe_RxElecIdle           => CONNECTED_TO_i_phy_9_pipe_RxElecIdle,           --                    .if_i_phy_9_pipe_RxElecIdle
			i_phy_9_pipe_RxStatus             => CONNECTED_TO_i_phy_9_pipe_RxStatus,             --                    .if_i_phy_9_pipe_RxStatus
			i_phy_9_pipe_RxStandbyStatus      => CONNECTED_TO_i_phy_9_pipe_RxStandbyStatus,      --                    .if_i_phy_9_pipe_RxStandbyStatus
			o_phy_9_pipe_RxStandby            => CONNECTED_TO_o_phy_9_pipe_RxStandby,            --                    .if_o_phy_9_pipe_RxStandby
			o_phy_9_pipe_RxTermination        => CONNECTED_TO_o_phy_9_pipe_RxTermination,        --                    .if_o_phy_9_pipe_RxTermination
			o_phy_9_pipe_RxWidth              => CONNECTED_TO_o_phy_9_pipe_RxWidth,              --                    .if_o_phy_9_pipe_RxWidth
			i_phy_9_pipe_PhyStatus            => CONNECTED_TO_i_phy_9_pipe_PhyStatus,            --                    .if_i_phy_9_pipe_PhyStatus
			i_phy_9_pipe_PclkChangeOk         => CONNECTED_TO_i_phy_9_pipe_PclkChangeOk,         --                    .if_i_phy_9_pipe_PclkChangeOk
			o_phy_9_pipe_M2P_MessageBus       => CONNECTED_TO_o_phy_9_pipe_M2P_MessageBus,       --                    .if_o_phy_9_pipe_M2P_MessageBus
			i_phy_9_pipe_P2M_MessageBus       => CONNECTED_TO_i_phy_9_pipe_P2M_MessageBus,       --                    .if_i_phy_9_pipe_P2M_MessageBus
			o_phy_10_pipe_TxDataValid         => CONNECTED_TO_o_phy_10_pipe_TxDataValid,         --                    .if_o_phy_10_pipe_TxDataValid
			o_phy_10_pipe_TxData              => CONNECTED_TO_o_phy_10_pipe_TxData,              --                    .if_o_phy_10_pipe_TxData
			o_phy_10_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_10_pipe_TxDetRxLpbk,         --                    .if_o_phy_10_pipe_TxDetRxLpbk
			o_phy_10_pipe_TxElecIdle          => CONNECTED_TO_o_phy_10_pipe_TxElecIdle,          --                    .if_o_phy_10_pipe_TxElecIdle
			o_phy_10_pipe_PowerDown           => CONNECTED_TO_o_phy_10_pipe_PowerDown,           --                    .if_o_phy_10_pipe_PowerDown
			o_phy_10_pipe_Rate                => CONNECTED_TO_o_phy_10_pipe_Rate,                --                    .if_o_phy_10_pipe_Rate
			o_phy_10_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_10_pipe_PclkChangeAck,       --                    .if_o_phy_10_pipe_PclkChangeAck
			o_phy_10_pipe_PCLKRate            => CONNECTED_TO_o_phy_10_pipe_PCLKRate,            --                    .if_o_phy_10_pipe_PCLKRate
			o_phy_10_pipe_Width               => CONNECTED_TO_o_phy_10_pipe_Width,               --                    .if_o_phy_10_pipe_Width
			o_phy_10_pipe_PCLK                => CONNECTED_TO_o_phy_10_pipe_PCLK,                --                    .if_o_phy_10_pipe_PCLK
			o_phy_10_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_10_pipe_rxelecidle_disable,  --                    .if_o_phy_10_pipe_rxelecidle_disable
			o_phy_10_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_10_pipe_txcmnmode_disable,   --                    .if_o_phy_10_pipe_txcmnmode_disable
			o_phy_10_pipe_srisenable          => CONNECTED_TO_o_phy_10_pipe_srisenable,          --                    .if_o_phy_10_pipe_srisenable
			i_phy_10_pipe_RxClk               => CONNECTED_TO_i_phy_10_pipe_RxClk,               --                    .if_i_phy_10_pipe_RxClk
			i_phy_10_pipe_RxValid             => CONNECTED_TO_i_phy_10_pipe_RxValid,             --                    .if_i_phy_10_pipe_RxValid
			i_phy_10_pipe_RxData              => CONNECTED_TO_i_phy_10_pipe_RxData,              --                    .if_i_phy_10_pipe_RxData
			i_phy_10_pipe_RxElecIdle          => CONNECTED_TO_i_phy_10_pipe_RxElecIdle,          --                    .if_i_phy_10_pipe_RxElecIdle
			i_phy_10_pipe_RxStatus            => CONNECTED_TO_i_phy_10_pipe_RxStatus,            --                    .if_i_phy_10_pipe_RxStatus
			i_phy_10_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_10_pipe_RxStandbyStatus,     --                    .if_i_phy_10_pipe_RxStandbyStatus
			o_phy_10_pipe_RxStandby           => CONNECTED_TO_o_phy_10_pipe_RxStandby,           --                    .if_o_phy_10_pipe_RxStandby
			o_phy_10_pipe_RxTermination       => CONNECTED_TO_o_phy_10_pipe_RxTermination,       --                    .if_o_phy_10_pipe_RxTermination
			o_phy_10_pipe_RxWidth             => CONNECTED_TO_o_phy_10_pipe_RxWidth,             --                    .if_o_phy_10_pipe_RxWidth
			i_phy_10_pipe_PhyStatus           => CONNECTED_TO_i_phy_10_pipe_PhyStatus,           --                    .if_i_phy_10_pipe_PhyStatus
			i_phy_10_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_10_pipe_PclkChangeOk,        --                    .if_i_phy_10_pipe_PclkChangeOk
			o_phy_10_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_10_pipe_M2P_MessageBus,      --                    .if_o_phy_10_pipe_M2P_MessageBus
			i_phy_10_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_10_pipe_P2M_MessageBus,      --                    .if_i_phy_10_pipe_P2M_MessageBus
			o_phy_11_pipe_TxDataValid         => CONNECTED_TO_o_phy_11_pipe_TxDataValid,         --                    .if_o_phy_11_pipe_TxDataValid
			o_phy_11_pipe_TxData              => CONNECTED_TO_o_phy_11_pipe_TxData,              --                    .if_o_phy_11_pipe_TxData
			o_phy_11_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_11_pipe_TxDetRxLpbk,         --                    .if_o_phy_11_pipe_TxDetRxLpbk
			o_phy_11_pipe_TxElecIdle          => CONNECTED_TO_o_phy_11_pipe_TxElecIdle,          --                    .if_o_phy_11_pipe_TxElecIdle
			o_phy_11_pipe_PowerDown           => CONNECTED_TO_o_phy_11_pipe_PowerDown,           --                    .if_o_phy_11_pipe_PowerDown
			o_phy_11_pipe_Rate                => CONNECTED_TO_o_phy_11_pipe_Rate,                --                    .if_o_phy_11_pipe_Rate
			o_phy_11_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_11_pipe_PclkChangeAck,       --                    .if_o_phy_11_pipe_PclkChangeAck
			o_phy_11_pipe_PCLKRate            => CONNECTED_TO_o_phy_11_pipe_PCLKRate,            --                    .if_o_phy_11_pipe_PCLKRate
			o_phy_11_pipe_Width               => CONNECTED_TO_o_phy_11_pipe_Width,               --                    .if_o_phy_11_pipe_Width
			o_phy_11_pipe_PCLK                => CONNECTED_TO_o_phy_11_pipe_PCLK,                --                    .if_o_phy_11_pipe_PCLK
			o_phy_11_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_11_pipe_rxelecidle_disable,  --                    .if_o_phy_11_pipe_rxelecidle_disable
			o_phy_11_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_11_pipe_txcmnmode_disable,   --                    .if_o_phy_11_pipe_txcmnmode_disable
			o_phy_11_pipe_srisenable          => CONNECTED_TO_o_phy_11_pipe_srisenable,          --                    .if_o_phy_11_pipe_srisenable
			i_phy_11_pipe_RxClk               => CONNECTED_TO_i_phy_11_pipe_RxClk,               --                    .if_i_phy_11_pipe_RxClk
			i_phy_11_pipe_RxValid             => CONNECTED_TO_i_phy_11_pipe_RxValid,             --                    .if_i_phy_11_pipe_RxValid
			i_phy_11_pipe_RxData              => CONNECTED_TO_i_phy_11_pipe_RxData,              --                    .if_i_phy_11_pipe_RxData
			i_phy_11_pipe_RxElecIdle          => CONNECTED_TO_i_phy_11_pipe_RxElecIdle,          --                    .if_i_phy_11_pipe_RxElecIdle
			i_phy_11_pipe_RxStatus            => CONNECTED_TO_i_phy_11_pipe_RxStatus,            --                    .if_i_phy_11_pipe_RxStatus
			i_phy_11_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_11_pipe_RxStandbyStatus,     --                    .if_i_phy_11_pipe_RxStandbyStatus
			o_phy_11_pipe_RxStandby           => CONNECTED_TO_o_phy_11_pipe_RxStandby,           --                    .if_o_phy_11_pipe_RxStandby
			o_phy_11_pipe_RxTermination       => CONNECTED_TO_o_phy_11_pipe_RxTermination,       --                    .if_o_phy_11_pipe_RxTermination
			o_phy_11_pipe_RxWidth             => CONNECTED_TO_o_phy_11_pipe_RxWidth,             --                    .if_o_phy_11_pipe_RxWidth
			i_phy_11_pipe_PhyStatus           => CONNECTED_TO_i_phy_11_pipe_PhyStatus,           --                    .if_i_phy_11_pipe_PhyStatus
			i_phy_11_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_11_pipe_PclkChangeOk,        --                    .if_i_phy_11_pipe_PclkChangeOk
			o_phy_11_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_11_pipe_M2P_MessageBus,      --                    .if_o_phy_11_pipe_M2P_MessageBus
			i_phy_11_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_11_pipe_P2M_MessageBus,      --                    .if_i_phy_11_pipe_P2M_MessageBus
			o_phy_12_pipe_TxDataValid         => CONNECTED_TO_o_phy_12_pipe_TxDataValid,         --                    .if_o_phy_12_pipe_TxDataValid
			o_phy_12_pipe_TxData              => CONNECTED_TO_o_phy_12_pipe_TxData,              --                    .if_o_phy_12_pipe_TxData
			o_phy_12_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_12_pipe_TxDetRxLpbk,         --                    .if_o_phy_12_pipe_TxDetRxLpbk
			o_phy_12_pipe_TxElecIdle          => CONNECTED_TO_o_phy_12_pipe_TxElecIdle,          --                    .if_o_phy_12_pipe_TxElecIdle
			o_phy_12_pipe_PowerDown           => CONNECTED_TO_o_phy_12_pipe_PowerDown,           --                    .if_o_phy_12_pipe_PowerDown
			o_phy_12_pipe_Rate                => CONNECTED_TO_o_phy_12_pipe_Rate,                --                    .if_o_phy_12_pipe_Rate
			o_phy_12_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_12_pipe_PclkChangeAck,       --                    .if_o_phy_12_pipe_PclkChangeAck
			o_phy_12_pipe_PCLKRate            => CONNECTED_TO_o_phy_12_pipe_PCLKRate,            --                    .if_o_phy_12_pipe_PCLKRate
			o_phy_12_pipe_Width               => CONNECTED_TO_o_phy_12_pipe_Width,               --                    .if_o_phy_12_pipe_Width
			o_phy_12_pipe_PCLK                => CONNECTED_TO_o_phy_12_pipe_PCLK,                --                    .if_o_phy_12_pipe_PCLK
			o_phy_12_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_12_pipe_rxelecidle_disable,  --                    .if_o_phy_12_pipe_rxelecidle_disable
			o_phy_12_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_12_pipe_txcmnmode_disable,   --                    .if_o_phy_12_pipe_txcmnmode_disable
			o_phy_12_pipe_srisenable          => CONNECTED_TO_o_phy_12_pipe_srisenable,          --                    .if_o_phy_12_pipe_srisenable
			i_phy_12_pipe_RxClk               => CONNECTED_TO_i_phy_12_pipe_RxClk,               --                    .if_i_phy_12_pipe_RxClk
			i_phy_12_pipe_RxValid             => CONNECTED_TO_i_phy_12_pipe_RxValid,             --                    .if_i_phy_12_pipe_RxValid
			i_phy_12_pipe_RxData              => CONNECTED_TO_i_phy_12_pipe_RxData,              --                    .if_i_phy_12_pipe_RxData
			i_phy_12_pipe_RxElecIdle          => CONNECTED_TO_i_phy_12_pipe_RxElecIdle,          --                    .if_i_phy_12_pipe_RxElecIdle
			i_phy_12_pipe_RxStatus            => CONNECTED_TO_i_phy_12_pipe_RxStatus,            --                    .if_i_phy_12_pipe_RxStatus
			i_phy_12_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_12_pipe_RxStandbyStatus,     --                    .if_i_phy_12_pipe_RxStandbyStatus
			o_phy_12_pipe_RxStandby           => CONNECTED_TO_o_phy_12_pipe_RxStandby,           --                    .if_o_phy_12_pipe_RxStandby
			o_phy_12_pipe_RxTermination       => CONNECTED_TO_o_phy_12_pipe_RxTermination,       --                    .if_o_phy_12_pipe_RxTermination
			o_phy_12_pipe_RxWidth             => CONNECTED_TO_o_phy_12_pipe_RxWidth,             --                    .if_o_phy_12_pipe_RxWidth
			i_phy_12_pipe_PhyStatus           => CONNECTED_TO_i_phy_12_pipe_PhyStatus,           --                    .if_i_phy_12_pipe_PhyStatus
			i_phy_12_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_12_pipe_PclkChangeOk,        --                    .if_i_phy_12_pipe_PclkChangeOk
			o_phy_12_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_12_pipe_M2P_MessageBus,      --                    .if_o_phy_12_pipe_M2P_MessageBus
			i_phy_12_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_12_pipe_P2M_MessageBus,      --                    .if_i_phy_12_pipe_P2M_MessageBus
			o_phy_13_pipe_TxDataValid         => CONNECTED_TO_o_phy_13_pipe_TxDataValid,         --                    .if_o_phy_13_pipe_TxDataValid
			o_phy_13_pipe_TxData              => CONNECTED_TO_o_phy_13_pipe_TxData,              --                    .if_o_phy_13_pipe_TxData
			o_phy_13_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_13_pipe_TxDetRxLpbk,         --                    .if_o_phy_13_pipe_TxDetRxLpbk
			o_phy_13_pipe_TxElecIdle          => CONNECTED_TO_o_phy_13_pipe_TxElecIdle,          --                    .if_o_phy_13_pipe_TxElecIdle
			o_phy_13_pipe_PowerDown           => CONNECTED_TO_o_phy_13_pipe_PowerDown,           --                    .if_o_phy_13_pipe_PowerDown
			o_phy_13_pipe_Rate                => CONNECTED_TO_o_phy_13_pipe_Rate,                --                    .if_o_phy_13_pipe_Rate
			o_phy_13_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_13_pipe_PclkChangeAck,       --                    .if_o_phy_13_pipe_PclkChangeAck
			o_phy_13_pipe_PCLKRate            => CONNECTED_TO_o_phy_13_pipe_PCLKRate,            --                    .if_o_phy_13_pipe_PCLKRate
			o_phy_13_pipe_Width               => CONNECTED_TO_o_phy_13_pipe_Width,               --                    .if_o_phy_13_pipe_Width
			o_phy_13_pipe_PCLK                => CONNECTED_TO_o_phy_13_pipe_PCLK,                --                    .if_o_phy_13_pipe_PCLK
			o_phy_13_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_13_pipe_rxelecidle_disable,  --                    .if_o_phy_13_pipe_rxelecidle_disable
			o_phy_13_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_13_pipe_txcmnmode_disable,   --                    .if_o_phy_13_pipe_txcmnmode_disable
			o_phy_13_pipe_srisenable          => CONNECTED_TO_o_phy_13_pipe_srisenable,          --                    .if_o_phy_13_pipe_srisenable
			i_phy_13_pipe_RxClk               => CONNECTED_TO_i_phy_13_pipe_RxClk,               --                    .if_i_phy_13_pipe_RxClk
			i_phy_13_pipe_RxValid             => CONNECTED_TO_i_phy_13_pipe_RxValid,             --                    .if_i_phy_13_pipe_RxValid
			i_phy_13_pipe_RxData              => CONNECTED_TO_i_phy_13_pipe_RxData,              --                    .if_i_phy_13_pipe_RxData
			i_phy_13_pipe_RxElecIdle          => CONNECTED_TO_i_phy_13_pipe_RxElecIdle,          --                    .if_i_phy_13_pipe_RxElecIdle
			i_phy_13_pipe_RxStatus            => CONNECTED_TO_i_phy_13_pipe_RxStatus,            --                    .if_i_phy_13_pipe_RxStatus
			i_phy_13_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_13_pipe_RxStandbyStatus,     --                    .if_i_phy_13_pipe_RxStandbyStatus
			o_phy_13_pipe_RxStandby           => CONNECTED_TO_o_phy_13_pipe_RxStandby,           --                    .if_o_phy_13_pipe_RxStandby
			o_phy_13_pipe_RxTermination       => CONNECTED_TO_o_phy_13_pipe_RxTermination,       --                    .if_o_phy_13_pipe_RxTermination
			o_phy_13_pipe_RxWidth             => CONNECTED_TO_o_phy_13_pipe_RxWidth,             --                    .if_o_phy_13_pipe_RxWidth
			i_phy_13_pipe_PhyStatus           => CONNECTED_TO_i_phy_13_pipe_PhyStatus,           --                    .if_i_phy_13_pipe_PhyStatus
			i_phy_13_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_13_pipe_PclkChangeOk,        --                    .if_i_phy_13_pipe_PclkChangeOk
			o_phy_13_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_13_pipe_M2P_MessageBus,      --                    .if_o_phy_13_pipe_M2P_MessageBus
			i_phy_13_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_13_pipe_P2M_MessageBus,      --                    .if_i_phy_13_pipe_P2M_MessageBus
			o_phy_14_pipe_TxDataValid         => CONNECTED_TO_o_phy_14_pipe_TxDataValid,         --                    .if_o_phy_14_pipe_TxDataValid
			o_phy_14_pipe_TxData              => CONNECTED_TO_o_phy_14_pipe_TxData,              --                    .if_o_phy_14_pipe_TxData
			o_phy_14_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_14_pipe_TxDetRxLpbk,         --                    .if_o_phy_14_pipe_TxDetRxLpbk
			o_phy_14_pipe_TxElecIdle          => CONNECTED_TO_o_phy_14_pipe_TxElecIdle,          --                    .if_o_phy_14_pipe_TxElecIdle
			o_phy_14_pipe_PowerDown           => CONNECTED_TO_o_phy_14_pipe_PowerDown,           --                    .if_o_phy_14_pipe_PowerDown
			o_phy_14_pipe_Rate                => CONNECTED_TO_o_phy_14_pipe_Rate,                --                    .if_o_phy_14_pipe_Rate
			o_phy_14_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_14_pipe_PclkChangeAck,       --                    .if_o_phy_14_pipe_PclkChangeAck
			o_phy_14_pipe_PCLKRate            => CONNECTED_TO_o_phy_14_pipe_PCLKRate,            --                    .if_o_phy_14_pipe_PCLKRate
			o_phy_14_pipe_Width               => CONNECTED_TO_o_phy_14_pipe_Width,               --                    .if_o_phy_14_pipe_Width
			o_phy_14_pipe_PCLK                => CONNECTED_TO_o_phy_14_pipe_PCLK,                --                    .if_o_phy_14_pipe_PCLK
			o_phy_14_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_14_pipe_rxelecidle_disable,  --                    .if_o_phy_14_pipe_rxelecidle_disable
			o_phy_14_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_14_pipe_txcmnmode_disable,   --                    .if_o_phy_14_pipe_txcmnmode_disable
			o_phy_14_pipe_srisenable          => CONNECTED_TO_o_phy_14_pipe_srisenable,          --                    .if_o_phy_14_pipe_srisenable
			i_phy_14_pipe_RxClk               => CONNECTED_TO_i_phy_14_pipe_RxClk,               --                    .if_i_phy_14_pipe_RxClk
			i_phy_14_pipe_RxValid             => CONNECTED_TO_i_phy_14_pipe_RxValid,             --                    .if_i_phy_14_pipe_RxValid
			i_phy_14_pipe_RxData              => CONNECTED_TO_i_phy_14_pipe_RxData,              --                    .if_i_phy_14_pipe_RxData
			i_phy_14_pipe_RxElecIdle          => CONNECTED_TO_i_phy_14_pipe_RxElecIdle,          --                    .if_i_phy_14_pipe_RxElecIdle
			i_phy_14_pipe_RxStatus            => CONNECTED_TO_i_phy_14_pipe_RxStatus,            --                    .if_i_phy_14_pipe_RxStatus
			i_phy_14_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_14_pipe_RxStandbyStatus,     --                    .if_i_phy_14_pipe_RxStandbyStatus
			o_phy_14_pipe_RxStandby           => CONNECTED_TO_o_phy_14_pipe_RxStandby,           --                    .if_o_phy_14_pipe_RxStandby
			o_phy_14_pipe_RxTermination       => CONNECTED_TO_o_phy_14_pipe_RxTermination,       --                    .if_o_phy_14_pipe_RxTermination
			o_phy_14_pipe_RxWidth             => CONNECTED_TO_o_phy_14_pipe_RxWidth,             --                    .if_o_phy_14_pipe_RxWidth
			i_phy_14_pipe_PhyStatus           => CONNECTED_TO_i_phy_14_pipe_PhyStatus,           --                    .if_i_phy_14_pipe_PhyStatus
			i_phy_14_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_14_pipe_PclkChangeOk,        --                    .if_i_phy_14_pipe_PclkChangeOk
			o_phy_14_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_14_pipe_M2P_MessageBus,      --                    .if_o_phy_14_pipe_M2P_MessageBus
			i_phy_14_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_14_pipe_P2M_MessageBus,      --                    .if_i_phy_14_pipe_P2M_MessageBus
			o_phy_15_pipe_TxDataValid         => CONNECTED_TO_o_phy_15_pipe_TxDataValid,         --                    .if_o_phy_15_pipe_TxDataValid
			o_phy_15_pipe_TxData              => CONNECTED_TO_o_phy_15_pipe_TxData,              --                    .if_o_phy_15_pipe_TxData
			o_phy_15_pipe_TxDetRxLpbk         => CONNECTED_TO_o_phy_15_pipe_TxDetRxLpbk,         --                    .if_o_phy_15_pipe_TxDetRxLpbk
			o_phy_15_pipe_TxElecIdle          => CONNECTED_TO_o_phy_15_pipe_TxElecIdle,          --                    .if_o_phy_15_pipe_TxElecIdle
			o_phy_15_pipe_PowerDown           => CONNECTED_TO_o_phy_15_pipe_PowerDown,           --                    .if_o_phy_15_pipe_PowerDown
			o_phy_15_pipe_Rate                => CONNECTED_TO_o_phy_15_pipe_Rate,                --                    .if_o_phy_15_pipe_Rate
			o_phy_15_pipe_PclkChangeAck       => CONNECTED_TO_o_phy_15_pipe_PclkChangeAck,       --                    .if_o_phy_15_pipe_PclkChangeAck
			o_phy_15_pipe_PCLKRate            => CONNECTED_TO_o_phy_15_pipe_PCLKRate,            --                    .if_o_phy_15_pipe_PCLKRate
			o_phy_15_pipe_Width               => CONNECTED_TO_o_phy_15_pipe_Width,               --                    .if_o_phy_15_pipe_Width
			o_phy_15_pipe_PCLK                => CONNECTED_TO_o_phy_15_pipe_PCLK,                --                    .if_o_phy_15_pipe_PCLK
			o_phy_15_pipe_rxelecidle_disable  => CONNECTED_TO_o_phy_15_pipe_rxelecidle_disable,  --                    .if_o_phy_15_pipe_rxelecidle_disable
			o_phy_15_pipe_txcmnmode_disable   => CONNECTED_TO_o_phy_15_pipe_txcmnmode_disable,   --                    .if_o_phy_15_pipe_txcmnmode_disable
			o_phy_15_pipe_srisenable          => CONNECTED_TO_o_phy_15_pipe_srisenable,          --                    .if_o_phy_15_pipe_srisenable
			i_phy_15_pipe_RxClk               => CONNECTED_TO_i_phy_15_pipe_RxClk,               --                    .if_i_phy_15_pipe_RxClk
			i_phy_15_pipe_RxValid             => CONNECTED_TO_i_phy_15_pipe_RxValid,             --                    .if_i_phy_15_pipe_RxValid
			i_phy_15_pipe_RxData              => CONNECTED_TO_i_phy_15_pipe_RxData,              --                    .if_i_phy_15_pipe_RxData
			i_phy_15_pipe_RxElecIdle          => CONNECTED_TO_i_phy_15_pipe_RxElecIdle,          --                    .if_i_phy_15_pipe_RxElecIdle
			i_phy_15_pipe_RxStatus            => CONNECTED_TO_i_phy_15_pipe_RxStatus,            --                    .if_i_phy_15_pipe_RxStatus
			i_phy_15_pipe_RxStandbyStatus     => CONNECTED_TO_i_phy_15_pipe_RxStandbyStatus,     --                    .if_i_phy_15_pipe_RxStandbyStatus
			o_phy_15_pipe_RxStandby           => CONNECTED_TO_o_phy_15_pipe_RxStandby,           --                    .if_o_phy_15_pipe_RxStandby
			o_phy_15_pipe_RxTermination       => CONNECTED_TO_o_phy_15_pipe_RxTermination,       --                    .if_o_phy_15_pipe_RxTermination
			o_phy_15_pipe_RxWidth             => CONNECTED_TO_o_phy_15_pipe_RxWidth,             --                    .if_o_phy_15_pipe_RxWidth
			i_phy_15_pipe_PhyStatus           => CONNECTED_TO_i_phy_15_pipe_PhyStatus,           --                    .if_i_phy_15_pipe_PhyStatus
			i_phy_15_pipe_PclkChangeOk        => CONNECTED_TO_i_phy_15_pipe_PclkChangeOk,        --                    .if_i_phy_15_pipe_PclkChangeOk
			o_phy_15_pipe_M2P_MessageBus      => CONNECTED_TO_o_phy_15_pipe_M2P_MessageBus,      --                    .if_o_phy_15_pipe_M2P_MessageBus
			i_phy_15_pipe_P2M_MessageBus      => CONNECTED_TO_i_phy_15_pipe_P2M_MessageBus,      --                    .if_i_phy_15_pipe_P2M_MessageBus
			o_phy_0_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_0_pipe_rxbitslip_req,        --                    .if_o_phy_0_pipe_rxbitslip_req
			o_phy_0_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_0_pipe_rxbitslip_va,         --                    .if_o_phy_0_pipe_rxbitslip_va
			i_phy_0_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_0_pipe_RxBitSlip_Ack,        --                    .if_i_phy_0_pipe_RxBitSlip_Ack
			o_phy_1_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_1_pipe_rxbitslip_req,        --                    .if_o_phy_1_pipe_rxbitslip_req
			o_phy_1_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_1_pipe_rxbitslip_va,         --                    .if_o_phy_1_pipe_rxbitslip_va
			i_phy_1_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_1_pipe_RxBitSlip_Ack,        --                    .if_i_phy_1_pipe_RxBitSlip_Ack
			o_phy_2_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_2_pipe_rxbitslip_req,        --                    .if_o_phy_2_pipe_rxbitslip_req
			o_phy_2_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_2_pipe_rxbitslip_va,         --                    .if_o_phy_2_pipe_rxbitslip_va
			i_phy_2_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_2_pipe_RxBitSlip_Ack,        --                    .if_i_phy_2_pipe_RxBitSlip_Ack
			o_phy_3_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_3_pipe_rxbitslip_req,        --                    .if_o_phy_3_pipe_rxbitslip_req
			o_phy_3_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_3_pipe_rxbitslip_va,         --                    .if_o_phy_3_pipe_rxbitslip_va
			i_phy_3_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_3_pipe_RxBitSlip_Ack,        --                    .if_i_phy_3_pipe_RxBitSlip_Ack
			o_phy_4_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_4_pipe_rxbitslip_req,        --                    .if_o_phy_4_pipe_rxbitslip_req
			o_phy_4_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_4_pipe_rxbitslip_va,         --                    .if_o_phy_4_pipe_rxbitslip_va
			i_phy_4_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_4_pipe_RxBitSlip_Ack,        --                    .if_i_phy_4_pipe_RxBitSlip_Ack
			o_phy_5_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_5_pipe_rxbitslip_req,        --                    .if_o_phy_5_pipe_rxbitslip_req
			o_phy_5_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_5_pipe_rxbitslip_va,         --                    .if_o_phy_5_pipe_rxbitslip_va
			i_phy_5_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_5_pipe_RxBitSlip_Ack,        --                    .if_i_phy_5_pipe_RxBitSlip_Ack
			o_phy_6_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_6_pipe_rxbitslip_req,        --                    .if_o_phy_6_pipe_rxbitslip_req
			o_phy_6_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_6_pipe_rxbitslip_va,         --                    .if_o_phy_6_pipe_rxbitslip_va
			i_phy_6_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_6_pipe_RxBitSlip_Ack,        --                    .if_i_phy_6_pipe_RxBitSlip_Ack
			o_phy_7_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_7_pipe_rxbitslip_req,        --                    .if_o_phy_7_pipe_rxbitslip_req
			o_phy_7_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_7_pipe_rxbitslip_va,         --                    .if_o_phy_7_pipe_rxbitslip_va
			i_phy_7_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_7_pipe_RxBitSlip_Ack,        --                    .if_i_phy_7_pipe_RxBitSlip_Ack
			o_phy_8_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_8_pipe_rxbitslip_req,        --                    .if_o_phy_8_pipe_rxbitslip_req
			o_phy_8_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_8_pipe_rxbitslip_va,         --                    .if_o_phy_8_pipe_rxbitslip_va
			i_phy_8_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_8_pipe_RxBitSlip_Ack,        --                    .if_i_phy_8_pipe_RxBitSlip_Ack
			o_phy_9_pipe_rxbitslip_req        => CONNECTED_TO_o_phy_9_pipe_rxbitslip_req,        --                    .if_o_phy_9_pipe_rxbitslip_req
			o_phy_9_pipe_rxbitslip_va         => CONNECTED_TO_o_phy_9_pipe_rxbitslip_va,         --                    .if_o_phy_9_pipe_rxbitslip_va
			i_phy_9_pipe_RxBitSlip_Ack        => CONNECTED_TO_i_phy_9_pipe_RxBitSlip_Ack,        --                    .if_i_phy_9_pipe_RxBitSlip_Ack
			o_phy_10_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_10_pipe_rxbitslip_req,       --                    .if_o_phy_10_pipe_rxbitslip_req
			o_phy_10_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_10_pipe_rxbitslip_va,        --                    .if_o_phy_10_pipe_rxbitslip_va
			i_phy_10_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_10_pipe_RxBitSlip_Ack,       --                    .if_i_phy_10_pipe_RxBitSlip_Ack
			o_phy_11_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_11_pipe_rxbitslip_req,       --                    .if_o_phy_11_pipe_rxbitslip_req
			o_phy_11_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_11_pipe_rxbitslip_va,        --                    .if_o_phy_11_pipe_rxbitslip_va
			i_phy_11_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_11_pipe_RxBitSlip_Ack,       --                    .if_i_phy_11_pipe_RxBitSlip_Ack
			o_phy_12_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_12_pipe_rxbitslip_req,       --                    .if_o_phy_12_pipe_rxbitslip_req
			o_phy_12_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_12_pipe_rxbitslip_va,        --                    .if_o_phy_12_pipe_rxbitslip_va
			i_phy_12_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_12_pipe_RxBitSlip_Ack,       --                    .if_i_phy_12_pipe_RxBitSlip_Ack
			o_phy_13_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_13_pipe_rxbitslip_req,       --                    .if_o_phy_13_pipe_rxbitslip_req
			o_phy_13_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_13_pipe_rxbitslip_va,        --                    .if_o_phy_13_pipe_rxbitslip_va
			i_phy_13_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_13_pipe_RxBitSlip_Ack,       --                    .if_i_phy_13_pipe_RxBitSlip_Ack
			o_phy_14_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_14_pipe_rxbitslip_req,       --                    .if_o_phy_14_pipe_rxbitslip_req
			o_phy_14_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_14_pipe_rxbitslip_va,        --                    .if_o_phy_14_pipe_rxbitslip_va
			i_phy_14_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_14_pipe_RxBitSlip_Ack,       --                    .if_i_phy_14_pipe_RxBitSlip_Ack
			o_phy_15_pipe_rxbitslip_req       => CONNECTED_TO_o_phy_15_pipe_rxbitslip_req,       --                    .if_o_phy_15_pipe_rxbitslip_req
			o_phy_15_pipe_rxbitslip_va        => CONNECTED_TO_o_phy_15_pipe_rxbitslip_va,        --                    .if_o_phy_15_pipe_rxbitslip_va
			i_phy_15_pipe_RxBitSlip_Ack       => CONNECTED_TO_i_phy_15_pipe_RxBitSlip_Ack        --                    .if_i_phy_15_pipe_RxBitSlip_Ack
		);

