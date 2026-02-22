source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_ic_clk/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/hip_recfg_rst_in/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/avmm_ic_clk_in/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/hip_recfg_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/bbs_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/cmb2avst_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_csb2wire_csr/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_ic_rst/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/hip_recfg_clk_in/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_master/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_mirror_master/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/usr_avmm_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/debug_master/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/avmm_ic_rst_in/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/afu_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccv_afu/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/ccl_slave/sim/common/modelsim_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/avmm_ic/usr_access_master/sim/common/modelsim_files.tcl]

namespace eval avmm_ic {
  proc get_design_libraries {} {
    set libraries [dict create]
    set libraries [dict merge $libraries [ccl_ic_clk::get_design_libraries]]
    set libraries [dict merge $libraries [hip_recfg_rst_in::get_design_libraries]]
    set libraries [dict merge $libraries [avmm_ic_clk_in::get_design_libraries]]
    set libraries [dict merge $libraries [hip_recfg_slave::get_design_libraries]]
    set libraries [dict merge $libraries [bbs_slave::get_design_libraries]]
    set libraries [dict merge $libraries [cmb2avst_slave::get_design_libraries]]
    set libraries [dict merge $libraries [ccl_csb2wire_csr::get_design_libraries]]
    set libraries [dict merge $libraries [ccl_ic_rst::get_design_libraries]]
    set libraries [dict merge $libraries [hip_recfg_clk_in::get_design_libraries]]
    set libraries [dict merge $libraries [ccl_master::get_design_libraries]]
    set libraries [dict merge $libraries [ccl_mirror_master::get_design_libraries]]
    set libraries [dict merge $libraries [usr_avmm_slave::get_design_libraries]]
    set libraries [dict merge $libraries [debug_master::get_design_libraries]]
    set libraries [dict merge $libraries [avmm_ic_rst_in::get_design_libraries]]
    set libraries [dict merge $libraries [afu_slave::get_design_libraries]]
    set libraries [dict merge $libraries [ccv_afu::get_design_libraries]]
    set libraries [dict merge $libraries [ccl_slave::get_design_libraries]]
    set libraries [dict merge $libraries [usr_access_master::get_design_libraries]]
    dict set libraries altera_merlin_master_translator_193  1
    dict set libraries altera_merlin_slave_translator_191   1
    dict set libraries altera_merlin_master_agent_1931      1
    dict set libraries altera_merlin_slave_agent_1930       1
    dict set libraries altera_avalon_sc_fifo_1932           1
    dict set libraries altera_merlin_router_1921            1
    dict set libraries altera_merlin_traffic_limiter_1921   1
    dict set libraries altera_avalon_st_pipeline_stage_1930 1
    dict set libraries altera_merlin_burst_adapter_1940     1
    dict set libraries altera_merlin_demultiplexer_1921     1
    dict set libraries altera_merlin_multiplexer_1922       1
    dict set libraries altera_merlin_width_adapter_1950     1
    dict set libraries altera_mm_interconnect_1920          1
    dict set libraries avmm_ic                              1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    set memory_files [concat $memory_files [ccl_ic_clk::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_clk/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [hip_recfg_rst_in::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_rst_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [avmm_ic_clk_in::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_clk_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [hip_recfg_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [bbs_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/bbs_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [cmb2avst_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/cmb2avst_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccl_csb2wire_csr::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_csb2wire_csr/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccl_ic_rst::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_rst/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [hip_recfg_clk_in::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_clk_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccl_master::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccl_mirror_master::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_mirror_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [usr_avmm_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_avmm_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [debug_master::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/debug_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [avmm_ic_rst_in::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_rst_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [afu_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/afu_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccv_afu::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccv_afu/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [ccl_slave::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [usr_access_master::get_memory_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_access_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    return $memory_files
  }
  
  proc get_common_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    set design_files [dict merge $design_files [ccl_ic_clk::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_clk/sim/"]]
    set design_files [dict merge $design_files [hip_recfg_rst_in::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_rst_in/sim/"]]
    set design_files [dict merge $design_files [avmm_ic_clk_in::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_clk_in/sim/"]]
    set design_files [dict merge $design_files [hip_recfg_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_slave/sim/"]]
    set design_files [dict merge $design_files [bbs_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/bbs_slave/sim/"]]
    set design_files [dict merge $design_files [cmb2avst_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/cmb2avst_slave/sim/"]]
    set design_files [dict merge $design_files [ccl_csb2wire_csr::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_csb2wire_csr/sim/"]]
    set design_files [dict merge $design_files [ccl_ic_rst::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_rst/sim/"]]
    set design_files [dict merge $design_files [hip_recfg_clk_in::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_clk_in/sim/"]]
    set design_files [dict merge $design_files [ccl_master::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_master/sim/"]]
    set design_files [dict merge $design_files [ccl_mirror_master::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_mirror_master/sim/"]]
    set design_files [dict merge $design_files [usr_avmm_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_avmm_slave/sim/"]]
    set design_files [dict merge $design_files [debug_master::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/debug_master/sim/"]]
    set design_files [dict merge $design_files [avmm_ic_rst_in::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_rst_in/sim/"]]
    set design_files [dict merge $design_files [afu_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/afu_slave/sim/"]]
    set design_files [dict merge $design_files [ccv_afu::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccv_afu/sim/"]]
    set design_files [dict merge $design_files [ccl_slave::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_slave/sim/"]]
    set design_files [dict merge $design_files [usr_access_master::get_common_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_access_master/sim/"]]
    return $design_files
  }
  
  proc get_design_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [list]
    set design_files [concat $design_files [ccl_ic_clk::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_clk/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [hip_recfg_rst_in::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_rst_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [avmm_ic_clk_in::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_clk_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [hip_recfg_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [bbs_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/bbs_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [cmb2avst_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/cmb2avst_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccl_csb2wire_csr::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_csb2wire_csr/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccl_ic_rst::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_rst/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [hip_recfg_clk_in::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_clk_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccl_master::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccl_mirror_master::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_mirror_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [usr_avmm_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_avmm_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [debug_master::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/debug_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [avmm_ic_rst_in::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_rst_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [afu_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/afu_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccv_afu::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccv_afu/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [ccl_slave::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_slave/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [usr_access_master::get_design_files "$QSYS_SIMDIR/../../ip/avmm_ic/usr_access_master/sim/" "$QUARTUS_INSTALL_DIR"]]
    lappend design_files "-makelib altera_merlin_master_translator_193 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_translator_193/sim/avmm_ic_altera_merlin_master_translator_193_lgcew2q.sv"]\"   -end"                      
    lappend design_files "-makelib altera_merlin_slave_translator_191 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_translator_191/sim/avmm_ic_altera_merlin_slave_translator_191_xg7rzxi.sv"]\"   -end"                         
    lappend design_files "-makelib altera_merlin_master_agent_1931 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_agent_1931/sim/avmm_ic_altera_merlin_master_agent_1931_g4xxafa.sv"]\"   -end"                                  
    lappend design_files "-makelib altera_merlin_master_agent_1931 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_agent_1931/sim/avmm_ic_altera_merlin_master_agent_1931_jtx3eyy.sv"]\"   -end"                                  
    lappend design_files "-makelib altera_merlin_slave_agent_1930 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_agent_1930/sim/avmm_ic_altera_merlin_slave_agent_1930_jxauz3i.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_slave_agent_1930 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_agent_1930/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                                   
    lappend design_files "-makelib altera_avalon_sc_fifo_1932 \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_sc_fifo_1932/sim/avmm_ic_altera_avalon_sc_fifo_1932_22gxxgi.v"]\"   -end"                                                  
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_sbdbuxi.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_jj2bgxq.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_oyxwseq.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_ehvpati.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_5gzewpi.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_tn5z2ha.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_r7twxui.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_l4qtj5y.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_ign5h4a.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_7f6f5fi.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_router_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/avmm_ic_altera_merlin_router_1921_yupsl4a.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_traffic_limiter_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/avmm_ic_altera_merlin_traffic_limiter_altera_avalon_sc_fifo_1921_gkzjeda.v"]\"   -end"    
    lappend design_files "-makelib altera_merlin_traffic_limiter_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/altera_merlin_reorder_memory.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_traffic_limiter_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/altera_avalon_st_pipeline_base.v"]\"   -end"                                              
    lappend design_files "-makelib altera_merlin_traffic_limiter_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/avmm_ic_altera_merlin_traffic_limiter_1921_nm2ibua.sv"]\"   -end"                         
    lappend design_files "-makelib altera_avalon_st_pipeline_stage_1930 \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_st_pipeline_stage_1930/sim/avmm_ic_altera_avalon_st_pipeline_stage_1930_oiupeiq.sv"]\"   -end"                   
    lappend design_files "-makelib altera_avalon_st_pipeline_stage_1930 \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_st_pipeline_stage_1930/sim/altera_avalon_st_pipeline_base.v"]\"   -end"                                          
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/avmm_ic_altera_merlin_burst_adapter_altera_avalon_st_pipeline_stage_1940_xiwuelq.v"]\"   -end"
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/avmm_ic_altera_merlin_burst_adapter_1940_kzpeuni.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_uncmpr.sv"]\"   -end"                                             
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_13_1.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_new.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_incr_burst_converter.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_wrap_burst_converter.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_default_burst_converter.sv"]\"   -end"                                                 
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/avmm_ic_altera_merlin_burst_adapter_altera_avalon_st_pipeline_stage_1940_zhbvnza.v"]\"   -end"
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/avmm_ic_altera_merlin_burst_adapter_1940_brpzfhq.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_uncmpr.sv"]\"   -end"                                             
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_13_1.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_burst_adapter_new.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_incr_burst_converter.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_wrap_burst_converter.sv"]\"   -end"                                                    
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_default_burst_converter.sv"]\"   -end"                                                 
    lappend design_files "-makelib altera_merlin_burst_adapter_1940 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_burst_adapter_1940/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_nnukihq.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_cvl6pja.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_jlx254y.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_h5jrlaq.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_7folira.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_zl6s2jy.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_uca5dfq.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_s4cwysy.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_zbeb2ai.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_vzaz7iq.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_k2lns2i.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_m624g6i.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_dgfibqy.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_fcuzvuy.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_dpelvkq.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_demultiplexer_1921 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/avmm_ic_altera_merlin_demultiplexer_1921_xubonsq.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_gfamwdi.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_byfy56q.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/avmm_ic_altera_merlin_multiplexer_1922_74gpt4a.sv"]\"   -end"                                     
    lappend design_files "-makelib altera_merlin_multiplexer_1922 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"   -end"                                                           
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_ssddhoi.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_uam5dii.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_43i7ysa.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_ksbifri.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_gbpug3i.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/avmm_ic_altera_merlin_width_adapter_1950_m3lulhi.sv"]\"   -end"                               
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_address_alignment.sv"]\"   -end"                                                
    lappend design_files "-makelib altera_merlin_width_adapter_1950 \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_width_adapter_1950/sim/altera_merlin_burst_uncompressor.sv"]\"   -end"                                               
    lappend design_files "-makelib altera_mm_interconnect_1920 \"[normalize_path "$QSYS_SIMDIR/../altera_mm_interconnect_1920/sim/avmm_ic_altera_mm_interconnect_1920_ozp4xmi.v"]\"   -end"                                               
    lappend design_files "-makelib avmm_ic \"[normalize_path "$QSYS_SIMDIR/avmm_ic.v"]\"   -end"                                                                                                                                          
    return $design_files
  }
  
  proc get_non_duplicate_elab_option {ELAB_OPTIONS NEW_ELAB_OPTION} {
    set IS_DUPLICATE [string first $NEW_ELAB_OPTION $ELAB_OPTIONS]
    if {$IS_DUPLICATE == -1} {
      return $NEW_ELAB_OPTION
    } else {
      return ""
    }
  }
  
  
  proc get_elab_options {SIMULATOR_TOOL_BITNESS} {
    set ELAB_OPTIONS ""
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_ic_clk::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [hip_recfg_rst_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [avmm_ic_clk_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [hip_recfg_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [bbs_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [cmb2avst_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_csb2wire_csr::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_ic_rst::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [hip_recfg_clk_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_master::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_mirror_master::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [usr_avmm_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [debug_master::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [avmm_ic_rst_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [afu_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccv_afu::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [ccl_slave::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [usr_access_master::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    append SIM_OPTIONS [ccl_ic_clk::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [hip_recfg_rst_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [avmm_ic_clk_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [hip_recfg_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [bbs_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [cmb2avst_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccl_csb2wire_csr::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccl_ic_rst::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [hip_recfg_clk_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccl_master::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccl_mirror_master::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [usr_avmm_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [debug_master::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [avmm_ic_rst_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [afu_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccv_afu::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [ccl_slave::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [usr_access_master::get_sim_options $SIMULATOR_TOOL_BITNESS]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_ic_clk::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [hip_recfg_rst_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [avmm_ic_clk_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [hip_recfg_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [bbs_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [cmb2avst_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_csb2wire_csr::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_ic_rst::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [hip_recfg_clk_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_master::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_mirror_master::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [usr_avmm_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [debug_master::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [avmm_ic_rst_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [afu_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccv_afu::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [ccl_slave::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [usr_access_master::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
  proc normalize_path {FILEPATH} {
      if {[catch { package require fileutil } err]} { 
          return $FILEPATH 
      } 
      set path [fileutil::lexnormalize [file join [pwd] $FILEPATH]]  
      if {[file pathtype $FILEPATH] eq "relative"} { 
          set path [fileutil::relative [pwd] $path] 
      } 
      return $path 
  } 
  proc get_dpi_libraries {QSYS_SIMDIR} {
    set libraries [dict create]
    set libraries [dict merge $libraries [ccl_ic_clk::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_clk/sim/"]]
    set libraries [dict merge $libraries [hip_recfg_rst_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_rst_in/sim/"]]
    set libraries [dict merge $libraries [avmm_ic_clk_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_clk_in/sim/"]]
    set libraries [dict merge $libraries [hip_recfg_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_slave/sim/"]]
    set libraries [dict merge $libraries [bbs_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/bbs_slave/sim/"]]
    set libraries [dict merge $libraries [cmb2avst_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/cmb2avst_slave/sim/"]]
    set libraries [dict merge $libraries [ccl_csb2wire_csr::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_csb2wire_csr/sim/"]]
    set libraries [dict merge $libraries [ccl_ic_rst::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_ic_rst/sim/"]]
    set libraries [dict merge $libraries [hip_recfg_clk_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/hip_recfg_clk_in/sim/"]]
    set libraries [dict merge $libraries [ccl_master::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_master/sim/"]]
    set libraries [dict merge $libraries [ccl_mirror_master::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_mirror_master/sim/"]]
    set libraries [dict merge $libraries [usr_avmm_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/usr_avmm_slave/sim/"]]
    set libraries [dict merge $libraries [debug_master::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/debug_master/sim/"]]
    set libraries [dict merge $libraries [avmm_ic_rst_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/avmm_ic_rst_in/sim/"]]
    set libraries [dict merge $libraries [afu_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/afu_slave/sim/"]]
    set libraries [dict merge $libraries [ccv_afu::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccv_afu/sim/"]]
    set libraries [dict merge $libraries [ccl_slave::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/ccl_slave/sim/"]]
    set libraries [dict merge $libraries [usr_access_master::get_dpi_libraries "$QSYS_SIMDIR/../../ip/avmm_ic/usr_access_master/sim/"]]
    
    return $libraries
  }
  
}
