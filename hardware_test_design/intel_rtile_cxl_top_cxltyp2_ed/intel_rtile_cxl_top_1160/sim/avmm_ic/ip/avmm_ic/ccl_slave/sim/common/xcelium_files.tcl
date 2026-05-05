
namespace eval ccl_slave {
  proc get_design_libraries {} {
    set libraries [dict create]
    dict set libraries st_dc_fifo_1953 1
    dict set libraries mm_ccb_1930     1
    dict set libraries ccl_slave       1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    return $memory_files
  }
  
  proc get_common_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [list]
    lappend design_files "xmvlog -zlib 1 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../st_dc_fifo_1953/sim/ccl_slave_st_dc_fifo_1953_3qfelpa.v\"  -work st_dc_fifo_1953 -cdslib  ./cds_libs/st_dc_fifo_1953.cds.lib"
    lappend design_files "xmvlog -zlib 1 -sv $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_reset_synchronizer.v\"  -work st_dc_fifo_1953 -cdslib  ./cds_libs/st_dc_fifo_1953.cds.lib"    
    lappend design_files "xmvlog -zlib 1 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_dcfifo_synchronizer_bundle.v\"  -work st_dc_fifo_1953 -cdslib  ./cds_libs/st_dc_fifo_1953.cds.lib"
    lappend design_files "xmvlog -zlib 1 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_std_synchronizer_nocut.v\"  -work st_dc_fifo_1953 -cdslib  ./cds_libs/st_dc_fifo_1953.cds.lib"    
    lappend design_files "xmvlog -zlib 1 -compcnfg $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_slave_mm_ccb_st_dc_fifo_1930_2oijlri.v\"  -work mm_ccb_1930"                                   
    lappend design_files "xmvlog -zlib 1 -compcnfg $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_slave_mm_ccb_st_dc_fifo_1930_hgbukbi.v\"  -work mm_ccb_1930"                                   
    lappend design_files "xmvlog -zlib 1 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_slave_mm_ccb_1930_g6yp7lq.v\"  -work mm_ccb_1930 -cdslib  ./cds_libs/mm_ccb_1930.cds.lib"                
    lappend design_files "xmvlog -zlib 1 -compcnfg $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"$QSYS_SIMDIR/ccl_slave.v\"  -work ccl_slave"                                                                                       
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
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
  proc get_dpi_libraries {QSYS_SIMDIR} {
    set libraries [dict create]
    
    return $libraries
  }
  
}
