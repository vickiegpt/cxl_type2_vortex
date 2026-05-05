
namespace eval ccl_master {
  proc get_design_libraries {} {
    set libraries [dict create]
    dict set libraries st_dc_fifo_1953 1
    dict set libraries mm_ccb_1930     1
    dict set libraries ccl_master      1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    return $memory_files
  }
  
  proc get_common_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [list]
    lappend design_files "-makelib st_dc_fifo_1953 \"[normalize_path "$QSYS_SIMDIR/../st_dc_fifo_1953/sim/ccl_master_st_dc_fifo_1953_3qfelpa.v"]\"   -end"
    lappend design_files "-makelib st_dc_fifo_1953 \"[normalize_path "$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_reset_synchronizer.v"]\"   -end"         
    lappend design_files "-makelib st_dc_fifo_1953 \"[normalize_path "$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_dcfifo_synchronizer_bundle.v"]\"   -end" 
    lappend design_files "-makelib st_dc_fifo_1953 \"[normalize_path "$QSYS_SIMDIR/../st_dc_fifo_1953/sim/altera_std_synchronizer_nocut.v"]\"   -end"     
    lappend design_files "-makelib mm_ccb_1930 \"[normalize_path "$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_master_mm_ccb_st_dc_fifo_1930_mpoy3by.v"]\"   -end" 
    lappend design_files "-makelib mm_ccb_1930 \"[normalize_path "$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_master_mm_ccb_st_dc_fifo_1930_na4r5ci.v"]\"   -end" 
    lappend design_files "-makelib mm_ccb_1930 \"[normalize_path "$QSYS_SIMDIR/../mm_ccb_1930/sim/ccl_master_mm_ccb_1930_g6yp7lq.v"]\"   -end"            
    lappend design_files "-makelib ccl_master \"[normalize_path "$QSYS_SIMDIR/ccl_master.v"]\"   -end"                                                    
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
    
    return $libraries
  }
  
}
