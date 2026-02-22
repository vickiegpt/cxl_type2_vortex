
namespace eval emif_cal_two_ch {
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    lappend memory_files "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq_code.hex"
    lappend memory_files "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq_sim_global_param_tbl.hex"
    lappend memory_files "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq_synth_global_param_tbl.hex"
    return $memory_files
  }
  
  proc get_common_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [dict create]
    dict set design_files "altera_emif_cal_iossm.sv"                                  "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/altera_emif_cal_iossm.sv"                                 
    dict set design_files "altera_emif_f2c_gearbox.sv"                                "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/altera_emif_f2c_gearbox.sv"                               
    dict set design_files "emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq_arch.sv" "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq_arch.sv"
    dict set design_files "emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq.sv"      "$QSYS_SIMDIR/../altera_emif_cal_iossm_277/sim/emif_cal_two_ch_altera_emif_cal_iossm_277_udi6bxq.sv"     
    dict set design_files "emif_cal_two_ch_altera_emif_cal_277_w4se6ky.v"             "$QSYS_SIMDIR/../altera_emif_cal_277/sim/emif_cal_two_ch_altera_emif_cal_277_w4se6ky.v"                  
    dict set design_files "emif_cal_two_ch.v"                                         "$QSYS_SIMDIR/emif_cal_two_ch.v"                                                                         
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
