# ------------------------------------------------------------------------------ #
# --
# --      This source code is provided to you (the Licensee) under license
# --      by BittWare, a Molex Company.  To view or use this source code,
# --      the Licensee must accept a Software License Agreement (viewable
# --      at developer.bittware.com), which is commonly provided as a click-
# --      through license agreement.  The terms of the Software License
# --      Agreement govern all use and distribution of this file unless an
# --      alternative superseding license has been executed with BittWare.
# --      This source code and its derivatives may not be distributed to
# --      third parties in source code form. Software including or derived
# --      from this source code, including derivative works thereof created
# --      by Licensee, may be distributed to third parties with BittWare
# --      hardware only and in executable form only.
# --
# --      The click-through license is available here:
# --        https://developer.bittware.com/software_license.txt
# --
# ------------------------------------------------------------------------------ #
# --      UNCLASSIFIED//FOR OFFICIAL USE ONLY
# ------------------------------------------------------------------------------ #
# -- Title       : IA-780i
# -- Project     : IA-780i
# ------------------------------------------------------------------------------ #
# -- Description : Pinout and constraints for the IA-780i
# ------------------------------------------------------------------------------ #
# -- Known Issues and Omissions:
# -- 
# ------------------------------------------------------------------------------ #

# --------------------------
# Device, configuration, VID
# --------------------------
set_global_assignment -name FAMILY "Agilex 7"
# IA-780i devices: AGIB027R29A1E2VR2
set_global_assignment -name DEVICE AGIB027R29A1E2VR2
set_global_assignment -name BOARD default
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
set_global_assignment -name ENABLE_ED_CRC_CHECK ON
set_global_assignment -name MINIMUM_SEU_INTERVAL 0
set_global_assignment -name DEVICE_INITIALIZATION_CLOCK OSC_CLK_1_125MHZ
set_global_assignment -name AUTO_RESTART_CONFIGURATION OFF
set_global_assignment -name STRATIXV_CONFIGURATION_SCHEME "AVST X8"
set_global_assignment -name USE_PWRMGT_SCL SDM_IO0
set_global_assignment -name USE_PWRMGT_SDA SDM_IO12
set_global_assignment -name USE_CONF_DONE SDM_IO16
set_global_assignment -name USE_INIT_DONE SDM_IO5
set_global_assignment -name USE_PWRMGT_ALERT SDM_IO9
set_global_assignment -name USE_HPS_COLD_RESET SDM_IO7
set_global_assignment -name VID_OPERATION_MODE "PMBUS SLAVE"
set_global_assignment -name PWRMGT_DEVICE_ADDRESS_IN_PMBUS_SLAVE_MODE 01
set_global_assignment -name GENERATE_PR_RBF_FILE ON
set_global_assignment -name PWRMGT_VOLTAGE_OUTPUT_FORMAT "LINEAR FORMAT"
set_global_assignment -name PWRMGT_LINEAR_FORMAT_N "-12"
set_global_assignment -name GENERATE_COMPRESSED_SOF ON


# ------------------------------------
# Transceiver preservation constraints
# ------------------------------------
#
# See the following Intel doc for details:
# https://www.intel.com/content/www/us/en/docs/programmable/683872/23-1-4-4-0/preserving-unused-pma-lanes.html
#
# F-tile preservation
# If the F-tile (QSFP-DDs) is not included in the design transceiver preservation needs enabled for the F-tile. Use the following setting (this not required
#   if the global setting below is used):
# F-tile (Bank 12A) RX_Q3_CH3P Pin: AR47
# set_instance_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON -to AR47
#   Fitter report snippet which confirms preservation:
#     Info(22251): Empty 'F-tile' indicated by pin 'AR47' has been preserved  due to PRESERVE_UNUSED_XCVR_CHANNEL instance assignment
# Alternativly the following global assignment can be used
# set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON

# ----------------
# General clocking
# ----------------

# User Clock 100MHz, Bank 3A
set_location_assignment PIN_A25 -to USER_CLK
set_location_assignment PIN_B26 -to "USER_CLK(n)"
set_instance_assignment -name IO_STANDARD "TRUE DIFFERENTIAL SIGNALING" -to USER_CLK
set_instance_assignment -name INPUT_TERMINATION DIFFERENTIAL -to USER_CLK

# 1PPS Clock, Bank 3A
set_location_assignment PIN_B24 -to U1PPS
set_instance_assignment -name IO_STANDARD "1.2 V" -to U1PPS

# ClkA/External Clock, Bank 3A
set_location_assignment PIN_J23 -to CLKA
set_instance_assignment -name IO_STANDARD "1.2 V" -to CLKA


# --------------
# PCIe Interface
# --------------
# PCIe - R-Tile Bank 14C except the PCIe Reset
set_location_assignment PIN_AR37 -to PCIE_REFCLK0
set_location_assignment PIN_AT38 -to "PCIE_REFCLK0(n)"
set_location_assignment PIN_AG37 -to PCIE_REFCLK1
set_location_assignment PIN_AH38 -to "PCIE_REFCLK1(n)"
set_instance_assignment -name IO_STANDARD HCSL -to PCIE_REFCLK0
set_instance_assignment -name IO_STANDARD HCSL -to PCIE_REFCLK1

set_location_assignment PIN_L31  -to PERST_L
set_instance_assignment -name IO_STANDARD 1.0V -to PERST_L

set_location_assignment PIN_AR41 -to PCIE_TX_P[0]
set_location_assignment PIN_AP44 -to PCIE_TX_P[1]
set_location_assignment PIN_AL41 -to PCIE_TX_P[2]
set_location_assignment PIN_AK44 -to PCIE_TX_P[3]
set_location_assignment PIN_AG41 -to PCIE_TX_P[4]
set_location_assignment PIN_AF44 -to PCIE_TX_P[5]
set_location_assignment PIN_AC41 -to PCIE_TX_P[6]
set_location_assignment PIN_AB44 -to PCIE_TX_P[7]
set_location_assignment PIN_W41  -to PCIE_TX_P[8]
set_location_assignment PIN_V44  -to PCIE_TX_P[9]
set_location_assignment PIN_R41  -to PCIE_TX_P[10]
set_location_assignment PIN_P44  -to PCIE_TX_P[11]
set_location_assignment PIN_L41  -to PCIE_TX_P[12]
set_location_assignment PIN_V38  -to PCIE_TX_P[13]
set_location_assignment PIN_P38  -to PCIE_TX_P[14]
set_location_assignment PIN_K38  -to PCIE_TX_P[15]
set_location_assignment PIN_AT40 -to PCIE_TX_N[0]
set_location_assignment PIN_AN43 -to PCIE_TX_N[1]
set_location_assignment PIN_AM40 -to PCIE_TX_N[2]
set_location_assignment PIN_AJ43 -to PCIE_TX_N[3]
set_location_assignment PIN_AH40 -to PCIE_TX_N[4]
set_location_assignment PIN_AE43 -to PCIE_TX_N[5]
set_location_assignment PIN_AD40 -to PCIE_TX_N[6]
set_location_assignment PIN_AA43 -to PCIE_TX_N[7]
set_location_assignment PIN_Y40  -to PCIE_TX_N[8]
set_location_assignment PIN_U43  -to PCIE_TX_N[9]
set_location_assignment PIN_T40  -to PCIE_TX_N[10]
set_location_assignment PIN_N43  -to PCIE_TX_N[11]
set_location_assignment PIN_M40  -to PCIE_TX_N[12]
set_location_assignment PIN_U37  -to PCIE_TX_N[13]
set_location_assignment PIN_N37  -to PCIE_TX_N[14]
set_location_assignment PIN_J37  -to PCIE_TX_N[15]
set_location_assignment PIN_AL47 -to PCIE_RX_P[0]
set_location_assignment PIN_AG47 -to PCIE_RX_P[1]
set_location_assignment PIN_AC47 -to PCIE_RX_P[2]
set_location_assignment PIN_W47  -to PCIE_RX_P[3]
set_location_assignment PIN_R47  -to PCIE_RX_P[4]
set_location_assignment PIN_L47  -to PCIE_RX_P[5]
set_location_assignment PIN_G47  -to PCIE_RX_P[6]
set_location_assignment PIN_K44  -to PCIE_RX_P[7]
set_location_assignment PIN_D46  -to PCIE_RX_P[8]
set_location_assignment PIN_F44  -to PCIE_RX_P[9]
set_location_assignment PIN_G41  -to PCIE_RX_P[10]
set_location_assignment PIN_C41  -to PCIE_RX_P[11]
set_location_assignment PIN_B38  -to PCIE_RX_P[12]
set_location_assignment PIN_F38  -to PCIE_RX_P[13]
set_location_assignment PIN_C35  -to PCIE_RX_P[14]
set_location_assignment PIN_G35  -to PCIE_RX_P[15]
set_location_assignment PIN_AM46 -to PCIE_RX_N[0]
set_location_assignment PIN_AH46 -to PCIE_RX_N[1]
set_location_assignment PIN_AD46 -to PCIE_RX_N[2]
set_location_assignment PIN_Y46  -to PCIE_RX_N[3]
set_location_assignment PIN_T46  -to PCIE_RX_N[4]
set_location_assignment PIN_M46  -to PCIE_RX_N[5]
set_location_assignment PIN_H46  -to PCIE_RX_N[6]
set_location_assignment PIN_J43  -to PCIE_RX_N[7]
set_location_assignment PIN_C45  -to PCIE_RX_N[8]
set_location_assignment PIN_E43  -to PCIE_RX_N[9]
set_location_assignment PIN_H40  -to PCIE_RX_N[10]
set_location_assignment PIN_D40  -to PCIE_RX_N[11]
set_location_assignment PIN_A37  -to PCIE_RX_N[12]
set_location_assignment PIN_D34  -to PCIE_RX_N[14]
set_location_assignment PIN_E37  -to PCIE_RX_N[13]
set_location_assignment PIN_H34  -to PCIE_RX_N[15]

set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_TX_P[*]
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_TX_N[*]
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_RX_P[*]
set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_RX_N[*]


# -----------------
# DDR4 P0 Interface
# -----------------
# DDR4 Bank 0 - Bank 2F Bottom, 2F Top, 2C Bottom

# DDR4 Reference Clk
set_location_assignment PIN_CC23 -to P0_DDR4_REFCLK
set_location_assignment PIN_CB24 -to "P0_DDR4_REFCLK(n)"

set_location_assignment PIN_CL25 -to P0_DDR4_CLK_P[0]
set_location_assignment PIN_CK26 -to P0_DDR4_CLK_N[0]
set_location_assignment PIN_CL19 -to P0_DDR4_CLK_P[1]
set_location_assignment PIN_CK20 -to P0_DDR4_CLK_N[1]
set_location_assignment PIN_CR29 -to P0_DDR4_A[0]
set_location_assignment PIN_CT30 -to P0_DDR4_A[1]
set_location_assignment PIN_CN29 -to P0_DDR4_A[2]
set_location_assignment PIN_CM30 -to P0_DDR4_A[3]
set_location_assignment PIN_CR27 -to P0_DDR4_A[4]
set_location_assignment PIN_CT28 -to P0_DDR4_A[5]
set_location_assignment PIN_CN27 -to P0_DDR4_A[6]
set_location_assignment PIN_CM28 -to P0_DDR4_A[7]
set_location_assignment PIN_CR25 -to P0_DDR4_A[8]
set_location_assignment PIN_CT26 -to P0_DDR4_A[9]
set_location_assignment PIN_CN25 -to P0_DDR4_A[10]
set_location_assignment PIN_CM26 -to P0_DDR4_A[11]
set_location_assignment PIN_CF24 -to P0_DDR4_A[12]
set_location_assignment PIN_CE21 -to P0_DDR4_A[13]
set_location_assignment PIN_CF22 -to P0_DDR4_A[14]
set_location_assignment PIN_CC21 -to P0_DDR4_A[15]
set_location_assignment PIN_CB22 -to P0_DDR4_A[16]
set_location_assignment PIN_CH26 -to P0_DDR4_ACT_L[0]
set_location_assignment PIN_CB20 -to P0_DDR4_BA[0]
set_location_assignment PIN_CE19 -to P0_DDR4_BA[1]
set_location_assignment PIN_CF20 -to P0_DDR4_BG[0]
set_location_assignment PIN_CG27 -to P0_DDR4_BG[1]
set_location_assignment PIN_CG29 -to P0_DDR4_CKE[0]
set_location_assignment PIN_CH30 -to P0_DDR4_CKE[1]
set_location_assignment PIN_CG25 -to P0_DDR4_CS_L[0]
set_location_assignment PIN_CL29 -to P0_DDR4_CS_L[1]
set_location_assignment PIN_CL27 -to P0_DDR4_ODT[0]
set_location_assignment PIN_CK28 -to P0_DDR4_ODT[1]
set_location_assignment PIN_CH28 -to P0_DDR4_RESET_L[0]
set_location_assignment PIN_CK30 -to P0_DDR4_PARITY[0]
set_location_assignment PIN_CC19 -to P0_DDR4_ALERT_L[0]
set_location_assignment PIN_DA15 -to P0_DDR4_DQS_P[0]
set_location_assignment PIN_CY16 -to P0_DDR4_DQS_N[0]
set_location_assignment PIN_DA27 -to P0_DDR4_DQS_P[1]
set_location_assignment PIN_CY28 -to P0_DDR4_DQS_N[1]
set_location_assignment PIN_CR21 -to P0_DDR4_DQS_P[2]
set_location_assignment PIN_CT22 -to P0_DDR4_DQS_N[2]
set_location_assignment PIN_DA21 -to P0_DDR4_DQS_P[3]
set_location_assignment PIN_CY22 -to P0_DDR4_DQS_N[3]
set_location_assignment PIN_CR3  -to P0_DDR4_DQS_P[4]
set_location_assignment PIN_CT4  -to P0_DDR4_DQS_N[4]
set_location_assignment PIN_DA9  -to P0_DDR4_DQS_P[5]
set_location_assignment PIN_CY10 -to P0_DDR4_DQS_N[5]
set_location_assignment PIN_CR9  -to P0_DDR4_DQS_P[6]
set_location_assignment PIN_CT10 -to P0_DDR4_DQS_N[6]
set_location_assignment PIN_CR15 -to P0_DDR4_DQS_P[7]
set_location_assignment PIN_CT16 -to P0_DDR4_DQS_N[7]
set_location_assignment PIN_CU15 -to P0_DDR4_DM[0]
set_location_assignment PIN_CU27 -to P0_DDR4_DM[1]
set_location_assignment PIN_CN21 -to P0_DDR4_DM[2]
set_location_assignment PIN_CU21 -to P0_DDR4_DM[3]
set_location_assignment PIN_CN1  -to P0_DDR4_DM[4]
set_location_assignment PIN_CU9  -to P0_DDR4_DM[5]
set_location_assignment PIN_CN9  -to P0_DDR4_DM[6]
set_location_assignment PIN_CN15 -to P0_DDR4_DM[7]
set_location_assignment PIN_CU17 -to P0_DDR4_DQ[0]
set_location_assignment PIN_DA17 -to P0_DDR4_DQ[1]
set_location_assignment PIN_CU13 -to P0_DDR4_DQ[2]
set_location_assignment PIN_DA13 -to P0_DDR4_DQ[3]
set_location_assignment PIN_CY18 -to P0_DDR4_DQ[4]
set_location_assignment PIN_CV18 -to P0_DDR4_DQ[5]
set_location_assignment PIN_CV14 -to P0_DDR4_DQ[6]
set_location_assignment PIN_CY14 -to P0_DDR4_DQ[7]
set_location_assignment PIN_DA29 -to P0_DDR4_DQ[8]
set_location_assignment PIN_CU29 -to P0_DDR4_DQ[9]
set_location_assignment PIN_CU25 -to P0_DDR4_DQ[10]
set_location_assignment PIN_DA25 -to P0_DDR4_DQ[11]
set_location_assignment PIN_CY30 -to P0_DDR4_DQ[12]
set_location_assignment PIN_CV30 -to P0_DDR4_DQ[13]
set_location_assignment PIN_CY26 -to P0_DDR4_DQ[14]
set_location_assignment PIN_CV26 -to P0_DDR4_DQ[15]
set_location_assignment PIN_CR23 -to P0_DDR4_DQ[16]
set_location_assignment PIN_CN23 -to P0_DDR4_DQ[17]
set_location_assignment PIN_CN19 -to P0_DDR4_DQ[18]
set_location_assignment PIN_CR19 -to P0_DDR4_DQ[19]
set_location_assignment PIN_CT24 -to P0_DDR4_DQ[20]
set_location_assignment PIN_CM24 -to P0_DDR4_DQ[21]
set_location_assignment PIN_CM20 -to P0_DDR4_DQ[22]
set_location_assignment PIN_CT20 -to P0_DDR4_DQ[23]
set_location_assignment PIN_DA23 -to P0_DDR4_DQ[24]
set_location_assignment PIN_CU23 -to P0_DDR4_DQ[25]
set_location_assignment PIN_CU19 -to P0_DDR4_DQ[26]
set_location_assignment PIN_CV20 -to P0_DDR4_DQ[27]
set_location_assignment PIN_CY24 -to P0_DDR4_DQ[28]
set_location_assignment PIN_CV24 -to P0_DDR4_DQ[29]
set_location_assignment PIN_CY20 -to P0_DDR4_DQ[30]
set_location_assignment PIN_DA19 -to P0_DDR4_DQ[31]
set_location_assignment PIN_CT2  -to P0_DDR4_DQ[32]
set_location_assignment PIN_CR5  -to P0_DDR4_DQ[33]
set_location_assignment PIN_CT6  -to P0_DDR4_DQ[34]
set_location_assignment PIN_CM4  -to P0_DDR4_DQ[35]
set_location_assignment PIN_CR1  -to P0_DDR4_DQ[36]
set_location_assignment PIN_CN5  -to P0_DDR4_DQ[37]
set_location_assignment PIN_CM6  -to P0_DDR4_DQ[38]
set_location_assignment PIN_CN3  -to P0_DDR4_DQ[39]
set_location_assignment PIN_CV8  -to P0_DDR4_DQ[40]
set_location_assignment PIN_CV12 -to P0_DDR4_DQ[41]
set_location_assignment PIN_DA7  -to P0_DDR4_DQ[42]
set_location_assignment PIN_CU11 -to P0_DDR4_DQ[43]
set_location_assignment PIN_CY8  -to P0_DDR4_DQ[44]
set_location_assignment PIN_CY12 -to P0_DDR4_DQ[45]
set_location_assignment PIN_CU7  -to P0_DDR4_DQ[46]
set_location_assignment PIN_DA11 -to P0_DDR4_DQ[47]
set_location_assignment PIN_CN7  -to P0_DDR4_DQ[48]
set_location_assignment PIN_CM8  -to P0_DDR4_DQ[49]
set_location_assignment PIN_CT12 -to P0_DDR4_DQ[50]
set_location_assignment PIN_CM12 -to P0_DDR4_DQ[51]
set_location_assignment PIN_CR7  -to P0_DDR4_DQ[52]
set_location_assignment PIN_CT8  -to P0_DDR4_DQ[53]
set_location_assignment PIN_CR11 -to P0_DDR4_DQ[54]
set_location_assignment PIN_CN11 -to P0_DDR4_DQ[55]
set_location_assignment PIN_CT14 -to P0_DDR4_DQ[56]
set_location_assignment PIN_CM14 -to P0_DDR4_DQ[57]
set_location_assignment PIN_CT18 -to P0_DDR4_DQ[58]
set_location_assignment PIN_CM18 -to P0_DDR4_DQ[59]
set_location_assignment PIN_CN13 -to P0_DDR4_DQ[60]
set_location_assignment PIN_CR13 -to P0_DDR4_DQ[61]
set_location_assignment PIN_CR17 -to P0_DDR4_DQ[62]
set_location_assignment PIN_CN17 -to P0_DDR4_DQ[63]
set_location_assignment PIN_CE23 -to P0_RZQ


# -----------------
# DDR4 P1 Interface
# -----------------
# DDR4 Bank 1 - Banks 2C Bottom, Bank 2D top, 2D Bottom

# DDR4 Reference Clk
set_location_assignment PIN_CA1  -to P1_DDR4_REFCLK
set_location_assignment PIN_BY2  -to "P1_DDR4_REFCLK(n)"

set_location_assignment PIN_CG3  -to P1_DDR4_CLK_P[0]
set_location_assignment PIN_CH4  -to P1_DDR4_CLK_N[0]
set_location_assignment PIN_BN5  -to P1_DDR4_CLK_P[1]
set_location_assignment PIN_BM6  -to P1_DDR4_CLK_N[1]
set_location_assignment PIN_CE1  -to P1_DDR4_A[0]
set_location_assignment PIN_CF2  -to P1_DDR4_A[1]
set_location_assignment PIN_CE5  -to P1_DDR4_A[2]
set_location_assignment PIN_CF6  -to P1_DDR4_A[3]
set_location_assignment PIN_CE3  -to P1_DDR4_A[4]
set_location_assignment PIN_CF4  -to P1_DDR4_A[5]
set_location_assignment PIN_CC1  -to P1_DDR4_A[6]
set_location_assignment PIN_CB2  -to P1_DDR4_A[7]
set_location_assignment PIN_CC3  -to P1_DDR4_A[8]
set_location_assignment PIN_CB4  -to P1_DDR4_A[9]
set_location_assignment PIN_CC5  -to P1_DDR4_A[10]
set_location_assignment PIN_CB6  -to P1_DDR4_A[11]
set_location_assignment PIN_BY6  -to P1_DDR4_A[12]
set_location_assignment PIN_CA3  -to P1_DDR4_A[13]
set_location_assignment PIN_BY4  -to P1_DDR4_A[14]
set_location_assignment PIN_BU1  -to P1_DDR4_A[15]
set_location_assignment PIN_BV2  -to P1_DDR4_A[16]
set_location_assignment PIN_CK6  -to P1_DDR4_ACT_L[0]
set_location_assignment PIN_BV4  -to P1_DDR4_BA[0]
set_location_assignment PIN_BU5  -to P1_DDR4_BA[1]
set_location_assignment PIN_BV6  -to P1_DDR4_BG[0]
set_location_assignment PIN_CL1  -to P1_DDR4_BG[1]
set_location_assignment PIN_CG1  -to P1_DDR4_CKE[0]
set_location_assignment PIN_CH2  -to P1_DDR4_CKE[1]
set_location_assignment PIN_CL5  -to P1_DDR4_CS_L[0]
set_location_assignment PIN_CG5  -to P1_DDR4_CS_L[1]
set_location_assignment PIN_CL3  -to P1_DDR4_ODT[0]
set_location_assignment PIN_CK4  -to P1_DDR4_ODT[1]
set_location_assignment PIN_CK2  -to P1_DDR4_RESET_L[0]
set_location_assignment PIN_CH6  -to P1_DDR4_PARITY[0]
set_location_assignment PIN_BU3  -to P1_DDR4_ALERT_L[0]
set_location_assignment PIN_CA9  -to P1_DDR4_DQS_P[0]
set_location_assignment PIN_BY10 -to P1_DDR4_DQS_N[0]
set_location_assignment PIN_BL9  -to P1_DDR4_DQS_P[1]
set_location_assignment PIN_BK10 -to P1_DDR4_DQS_N[1]
set_location_assignment PIN_BL3  -to P1_DDR4_DQS_P[2]
set_location_assignment PIN_BK4  -to P1_DDR4_DQS_N[2]
set_location_assignment PIN_BR9  -to P1_DDR4_DQS_P[3]
set_location_assignment PIN_BT10 -to P1_DDR4_DQS_N[3]
set_location_assignment PIN_CL15 -to P1_DDR4_DQS_P[4]
set_location_assignment PIN_CK16 -to P1_DDR4_DQS_N[4]
set_location_assignment PIN_CE9  -to P1_DDR4_DQS_P[5]
set_location_assignment PIN_CF10 -to P1_DDR4_DQS_N[5]
set_location_assignment PIN_CL9  -to P1_DDR4_DQS_P[6]
set_location_assignment PIN_CK10 -to P1_DDR4_DQS_N[6]
set_location_assignment PIN_CE15 -to P1_DDR4_DQS_P[7]
set_location_assignment PIN_CF16 -to P1_DDR4_DQS_N[7]
set_location_assignment PIN_BU7  -to P1_DDR4_DM[0]
set_location_assignment PIN_BG9  -to P1_DDR4_DM[1]
set_location_assignment PIN_BL5  -to P1_DDR4_DM[2]
set_location_assignment PIN_BN7  -to P1_DDR4_DM[3]
set_location_assignment PIN_CG17 -to P1_DDR4_DM[4]
set_location_assignment PIN_CC7  -to P1_DDR4_DM[5]
set_location_assignment PIN_CG7  -to P1_DDR4_DM[6]
set_location_assignment PIN_CE17 -to P1_DDR4_DM[7]
set_location_assignment PIN_BU11 -to P1_DDR4_DQ[0]
set_location_assignment PIN_BV12 -to P1_DDR4_DQ[1]
set_location_assignment PIN_BV10 -to P1_DDR4_DQ[2]
set_location_assignment PIN_CA7  -to P1_DDR4_DQ[3]
set_location_assignment PIN_CA11 -to P1_DDR4_DQ[4]
set_location_assignment PIN_BY12 -to P1_DDR4_DQ[5]
set_location_assignment PIN_BU9  -to P1_DDR4_DQ[6]
set_location_assignment PIN_BY8  -to P1_DDR4_DQ[7]
set_location_assignment PIN_BG11 -to P1_DDR4_DQ[8]
set_location_assignment PIN_BL11 -to P1_DDR4_DQ[9]
set_location_assignment PIN_BL7  -to P1_DDR4_DQ[10]
set_location_assignment PIN_BG7  -to P1_DDR4_DQ[11]
set_location_assignment PIN_BK12 -to P1_DDR4_DQ[12]
set_location_assignment PIN_BH12 -to P1_DDR4_DQ[13]
set_location_assignment PIN_BH8  -to P1_DDR4_DQ[14]
set_location_assignment PIN_BK8  -to P1_DDR4_DQ[15]
set_location_assignment PIN_BG5  -to P1_DDR4_DQ[16]
set_location_assignment PIN_BG1  -to P1_DDR4_DQ[17]
set_location_assignment PIN_BH2  -to P1_DDR4_DQ[18]
set_location_assignment PIN_BL1  -to P1_DDR4_DQ[19]
set_location_assignment PIN_BH6  -to P1_DDR4_DQ[20]
set_location_assignment PIN_BH4  -to P1_DDR4_DQ[21]
set_location_assignment PIN_BG3  -to P1_DDR4_DQ[22]
set_location_assignment PIN_BK2  -to P1_DDR4_DQ[23]
set_location_assignment PIN_BN11 -to P1_DDR4_DQ[24]
set_location_assignment PIN_BM12 -to P1_DDR4_DQ[25]
set_location_assignment PIN_BR7  -to P1_DDR4_DQ[26]
set_location_assignment PIN_BT8  -to P1_DDR4_DQ[27]
set_location_assignment PIN_BR11 -to P1_DDR4_DQ[28]
set_location_assignment PIN_BT12 -to P1_DDR4_DQ[29]
set_location_assignment PIN_BM10 -to P1_DDR4_DQ[30]
set_location_assignment PIN_BN9  -to P1_DDR4_DQ[31]
set_location_assignment PIN_CH14 -to P1_DDR4_DQ[32]
set_location_assignment PIN_CG13 -to P1_DDR4_DQ[33]
set_location_assignment PIN_CK18 -to P1_DDR4_DQ[34]
set_location_assignment PIN_CK14 -to P1_DDR4_DQ[35]
set_location_assignment PIN_CG15 -to P1_DDR4_DQ[36]
set_location_assignment PIN_CH16 -to P1_DDR4_DQ[37]
set_location_assignment PIN_CL17 -to P1_DDR4_DQ[38]
set_location_assignment PIN_CL13 -to P1_DDR4_DQ[39]
set_location_assignment PIN_CF8  -to P1_DDR4_DQ[40]
set_location_assignment PIN_CB10 -to P1_DDR4_DQ[41]
set_location_assignment PIN_CB12 -to P1_DDR4_DQ[42]
set_location_assignment PIN_CC11 -to P1_DDR4_DQ[43]
set_location_assignment PIN_CE7  -to P1_DDR4_DQ[44]
set_location_assignment PIN_CC9  -to P1_DDR4_DQ[45]
set_location_assignment PIN_CF12 -to P1_DDR4_DQ[46]
set_location_assignment PIN_CE11 -to P1_DDR4_DQ[47]
set_location_assignment PIN_CK8  -to P1_DDR4_DQ[48]
set_location_assignment PIN_CL7  -to P1_DDR4_DQ[49]
set_location_assignment PIN_CH12 -to P1_DDR4_DQ[50]
set_location_assignment PIN_CK12 -to P1_DDR4_DQ[51]
set_location_assignment PIN_CG9  -to P1_DDR4_DQ[52]
set_location_assignment PIN_CH10 -to P1_DDR4_DQ[53]
set_location_assignment PIN_CG11 -to P1_DDR4_DQ[54]
set_location_assignment PIN_CL11 -to P1_DDR4_DQ[55]
set_location_assignment PIN_CF14 -to P1_DDR4_DQ[56]
set_location_assignment PIN_CB14 -to P1_DDR4_DQ[57]
set_location_assignment PIN_CB18 -to P1_DDR4_DQ[58]
set_location_assignment PIN_CC17 -to P1_DDR4_DQ[59]
set_location_assignment PIN_CC13 -to P1_DDR4_DQ[60]
set_location_assignment PIN_CE13 -to P1_DDR4_DQ[61]
set_location_assignment PIN_CB16 -to P1_DDR4_DQ[62]
set_location_assignment PIN_CC15 -to P1_DDR4_DQ[63]
set_location_assignment PIN_CA5  -to P1_RZQ


# ------------------
# DDR4 HPS Interface
# ------------------
# DDR4 Bank HPS - Banks 3B Top, Bank 3B Bottom
set_location_assignment PIN_L7  -to HPS_DDR4_REFCLK
set_location_assignment PIN_M8  -to "HPS_DDR4_REFCLK(n)"

set_location_assignment PIN_L13 -to HPS_DDR4_CLK_P[0]
set_location_assignment PIN_M14 -to HPS_DDR4_CLK_N[0]
set_location_assignment PIN_J11 -to HPS_DDR4_A[0]
set_location_assignment PIN_K12 -to HPS_DDR4_A[1]
set_location_assignment PIN_G11 -to HPS_DDR4_A[2]
set_location_assignment PIN_F12 -to HPS_DDR4_A[3]
set_location_assignment PIN_G9  -to HPS_DDR4_A[4]
set_location_assignment PIN_F10 -to HPS_DDR4_A[5]
set_location_assignment PIN_J9  -to HPS_DDR4_A[6]
set_location_assignment PIN_K10 -to HPS_DDR4_A[7]
set_location_assignment PIN_G7  -to HPS_DDR4_A[8]
set_location_assignment PIN_F8  -to HPS_DDR4_A[9]
set_location_assignment PIN_J7  -to HPS_DDR4_A[10]
set_location_assignment PIN_K8  -to HPS_DDR4_A[11]
set_location_assignment PIN_M12 -to HPS_DDR4_A[12]
set_location_assignment PIN_L9  -to HPS_DDR4_A[13]
set_location_assignment PIN_M10 -to HPS_DDR4_A[14]
set_location_assignment PIN_R9  -to HPS_DDR4_A[15]
set_location_assignment PIN_P10 -to HPS_DDR4_A[16]
set_location_assignment PIN_P18 -to HPS_DDR4_ACT_L[0]
set_location_assignment PIN_P12 -to HPS_DDR4_BA[0]
set_location_assignment PIN_R7  -to HPS_DDR4_BA[1]
set_location_assignment PIN_P8  -to HPS_DDR4_BG[0]
set_location_assignment PIN_R15 -to HPS_DDR4_CKE[0]
set_location_assignment PIN_R17 -to HPS_DDR4_CS_L[0]
set_location_assignment PIN_L15 -to HPS_DDR4_ODT[0]
set_location_assignment PIN_M18 -to HPS_DDR4_RESET_L[0]
set_location_assignment PIN_P14 -to HPS_DDR4_PARITY[0]
set_location_assignment PIN_R11 -to HPS_DDR4_ALERT_L[0]
set_location_assignment PIN_U3  -to HPS_DDR4_DQS_P[0]
set_location_assignment PIN_T4  -to HPS_DDR4_DQS_N[0]
set_location_assignment PIN_L3  -to HPS_DDR4_DQS_P[1]
set_location_assignment PIN_M4  -to HPS_DDR4_DQS_N[1]
set_location_assignment PIN_G3  -to HPS_DDR4_DQS_P[2]
set_location_assignment PIN_F4  -to HPS_DDR4_DQS_N[2]
set_location_assignment PIN_A9  -to HPS_DDR4_DQS_P[3]
set_location_assignment PIN_B10 -to HPS_DDR4_DQS_N[3]
set_location_assignment PIN_U9  -to HPS_DDR4_DQS_P[4]
set_location_assignment PIN_T10 -to HPS_DDR4_DQS_N[4]
set_location_assignment PIN_W1  -to HPS_DDR4_DM[0]
set_location_assignment PIN_R1  -to HPS_DDR4_DM[1]
set_location_assignment PIN_J1  -to HPS_DDR4_DM[2]
set_location_assignment PIN_E9  -to HPS_DDR4_DM[3]
set_location_assignment PIN_W7  -to HPS_DDR4_DM[4]
set_location_assignment PIN_Y6  -to HPS_DDR4_DQ[0]
set_location_assignment PIN_T2  -to HPS_DDR4_DQ[1]
set_location_assignment PIN_W5  -to HPS_DDR4_DQ[2]
set_location_assignment PIN_Y4  -to HPS_DDR4_DQ[3]
set_location_assignment PIN_T6  -to HPS_DDR4_DQ[4]
set_location_assignment PIN_W3  -to HPS_DDR4_DQ[5]
set_location_assignment PIN_U5  -to HPS_DDR4_DQ[6]
set_location_assignment PIN_U1  -to HPS_DDR4_DQ[7]
set_location_assignment PIN_R5  -to HPS_DDR4_DQ[8]
set_location_assignment PIN_M2  -to HPS_DDR4_DQ[9]
set_location_assignment PIN_M6  -to HPS_DDR4_DQ[10]
set_location_assignment PIN_P4  -to HPS_DDR4_DQ[11]
set_location_assignment PIN_P6  -to HPS_DDR4_DQ[12]
set_location_assignment PIN_L1  -to HPS_DDR4_DQ[13]
set_location_assignment PIN_L5  -to HPS_DDR4_DQ[14]
set_location_assignment PIN_R3  -to HPS_DDR4_DQ[15]
set_location_assignment PIN_G5  -to HPS_DDR4_DQ[16]
set_location_assignment PIN_J3  -to HPS_DDR4_DQ[17]
set_location_assignment PIN_J5  -to HPS_DDR4_DQ[18]
set_location_assignment PIN_F2  -to HPS_DDR4_DQ[19]
set_location_assignment PIN_K6  -to HPS_DDR4_DQ[20]
set_location_assignment PIN_G1  -to HPS_DDR4_DQ[21]
set_location_assignment PIN_F6  -to HPS_DDR4_DQ[22]
set_location_assignment PIN_K4  -to HPS_DDR4_DQ[23]
set_location_assignment PIN_B12 -to HPS_DDR4_DQ[24]
set_location_assignment PIN_B8  -to HPS_DDR4_DQ[25]
set_location_assignment PIN_D12 -to HPS_DDR4_DQ[26]
set_location_assignment PIN_D8  -to HPS_DDR4_DQ[27]
set_location_assignment PIN_E11 -to HPS_DDR4_DQ[28]
set_location_assignment PIN_E7  -to HPS_DDR4_DQ[29]
set_location_assignment PIN_A11 -to HPS_DDR4_DQ[30]
set_location_assignment PIN_A7  -to HPS_DDR4_DQ[31]
set_location_assignment PIN_W11 -to HPS_DDR4_DQ[32]
set_location_assignment PIN_T8  -to HPS_DDR4_DQ[33]
set_location_assignment PIN_U11 -to HPS_DDR4_DQ[34]
set_location_assignment PIN_W9  -to HPS_DDR4_DQ[35]
set_location_assignment PIN_Y10 -to HPS_DDR4_DQ[36]
set_location_assignment PIN_U7  -to HPS_DDR4_DQ[37]
set_location_assignment PIN_Y12 -to HPS_DDR4_DQ[38]
set_location_assignment PIN_T12 -to HPS_DDR4_DQ[39]
set_location_assignment PIN_L11 -to HPS_RZQ


# ------------------------------------------------------------
# F-tile, Bank 12A High speed serial transcievers and clocking
# ------------------------------------------------------------
# Reference clocks
# Refclk #2 - PIN_CE37
set_location_assignment PIN_CE37 -to FTILE_REFCLK_CH2
set_location_assignment PIN_CC37 -to "FTILE_REFCLK_CH2(n)"
# Refclk #3 - PIN_CB38
set_location_assignment PIN_CB38 -to FTILE_REFCLK_CH3
set_location_assignment PIN_CA37 -to "FTILE_REFCLK_CH3(n)"
# Refclk #4 - PIN_BT38
set_location_assignment PIN_BT38 -to FTILE_REFCLK_CH4
set_location_assignment PIN_BU37 -to "FTILE_REFCLK_CH4(n)"
# Refclk #5 - PIN_BN37
set_location_assignment PIN_BN37 -to FTILE_REFCLK_CH5
set_location_assignment PIN_BR37 -to "FTILE_REFCLK_CH5(n)"

# QSFPDD0 Recovered clocks output from the FPGA
# Refclk #9 - PIN_BB38
set_location_assignment PIN_BB38 -to RECV0_CLK
set_location_assignment PIN_BA37 -to "RECV0_CLK(n)"
# Refclk #8 - PIN_BM38
set_location_assignment PIN_BM38 -to RECV1_CLK
set_location_assignment PIN_BL37 -to "RECV1_CLK(n)"

# QSFP-DD0 pinout for Ethernet (lane indexing reversed w.r.t cardtest/Hardware Reference Guide signal names)
# F-tile Quad3 Lanes 0-3, QSFPDD0[0] - Quad3, FGT/CH3
# F-tile Quad2 Lanes 4-7, QSFPDD0[7] - Quad2, FGT/CH0
set_location_assignment PIN_BR41 -to QSFPDD0_TX_P[7]
set_location_assignment PIN_BP44 -to QSFPDD0_TX_P[6]
set_location_assignment PIN_BL41 -to QSFPDD0_TX_P[5]
set_location_assignment PIN_BK44 -to QSFPDD0_TX_P[4]
set_location_assignment PIN_BG41 -to QSFPDD0_TX_P[3]
set_location_assignment PIN_BF44 -to QSFPDD0_TX_P[2]
set_location_assignment PIN_BC41 -to QSFPDD0_TX_P[1]
set_location_assignment PIN_AW41 -to QSFPDD0_TX_P[0]
set_location_assignment PIN_BT40 -to QSFPDD0_TX_N[7]
set_location_assignment PIN_BN43 -to QSFPDD0_TX_N[6]
set_location_assignment PIN_BM40 -to QSFPDD0_TX_N[5]
set_location_assignment PIN_BJ43 -to QSFPDD0_TX_N[4]
set_location_assignment PIN_BH40 -to QSFPDD0_TX_N[3]
set_location_assignment PIN_BE43 -to QSFPDD0_TX_N[2]
set_location_assignment PIN_BD40 -to QSFPDD0_TX_N[1]
set_location_assignment PIN_AY40 -to QSFPDD0_TX_N[0]
set_location_assignment PIN_BR47 -to QSFPDD0_RX_P[7]
set_location_assignment PIN_BL47 -to QSFPDD0_RX_P[6]
set_location_assignment PIN_BG47 -to QSFPDD0_RX_P[5]
set_location_assignment PIN_BC47 -to QSFPDD0_RX_P[4]
set_location_assignment PIN_BB44 -to QSFPDD0_RX_P[3]
set_location_assignment PIN_AW47 -to QSFPDD0_RX_P[2]
set_location_assignment PIN_AV44 -to QSFPDD0_RX_P[1]
set_location_assignment PIN_AR47 -to QSFPDD0_RX_P[0]
set_location_assignment PIN_BT46 -to QSFPDD0_RX_N[7]
set_location_assignment PIN_BM46 -to QSFPDD0_RX_N[6]
set_location_assignment PIN_BH46 -to QSFPDD0_RX_N[5]
set_location_assignment PIN_BD46 -to QSFPDD0_RX_N[4]
set_location_assignment PIN_BA43 -to QSFPDD0_RX_N[3]
set_location_assignment PIN_AY46 -to QSFPDD0_RX_N[2]
set_location_assignment PIN_AU43 -to QSFPDD0_RX_N[1]
set_location_assignment PIN_AT46 -to QSFPDD0_RX_N[0]

# # QSFP-DD0 pinout for cardtest (as detailed in the Hardware Reference Guide signal names)
# # F-tile Quad3 Lanes 4-7, QSFPDD0[7] - Quad3, FGT/CH3
# # F-tile Quad2 Lanes 0-3, QSFPDD0[0] - Quad2, FGT/CH0
# set_location_assignment PIN_BR41 -to QSFPDD0_TX_P[0]
# set_location_assignment PIN_BP44 -to QSFPDD0_TX_P[1]
# set_location_assignment PIN_BL41 -to QSFPDD0_TX_P[2]
# set_location_assignment PIN_BK44 -to QSFPDD0_TX_P[3]
# set_location_assignment PIN_BG41 -to QSFPDD0_TX_P[4]
# set_location_assignment PIN_BF44 -to QSFPDD0_TX_P[5]
# set_location_assignment PIN_BC41 -to QSFPDD0_TX_P[6]
# set_location_assignment PIN_AW41 -to QSFPDD0_TX_P[7]
# set_location_assignment PIN_BT40 -to QSFPDD0_TX_N[0]
# set_location_assignment PIN_BN43 -to QSFPDD0_TX_N[1]
# set_location_assignment PIN_BM40 -to QSFPDD0_TX_N[2]
# set_location_assignment PIN_BJ43 -to QSFPDD0_TX_N[3]
# set_location_assignment PIN_BH40 -to QSFPDD0_TX_N[4]
# set_location_assignment PIN_BE43 -to QSFPDD0_TX_N[5]
# set_location_assignment PIN_BD40 -to QSFPDD0_TX_N[6]
# set_location_assignment PIN_AY40 -to QSFPDD0_TX_N[7]
# set_location_assignment PIN_BR47 -to QSFPDD0_RX_P[0]
# set_location_assignment PIN_BL47 -to QSFPDD0_RX_P[1]
# set_location_assignment PIN_BG47 -to QSFPDD0_RX_P[2]
# set_location_assignment PIN_BC47 -to QSFPDD0_RX_P[3]
# set_location_assignment PIN_BB44 -to QSFPDD0_RX_P[4]
# set_location_assignment PIN_AW47 -to QSFPDD0_RX_P[5]
# set_location_assignment PIN_AV44 -to QSFPDD0_RX_P[6]
# set_location_assignment PIN_AR47 -to QSFPDD0_RX_P[7]
# set_location_assignment PIN_BT46 -to QSFPDD0_RX_N[0]
# set_location_assignment PIN_BM46 -to QSFPDD0_RX_N[1]
# set_location_assignment PIN_BH46 -to QSFPDD0_RX_N[2]
# set_location_assignment PIN_BD46 -to QSFPDD0_RX_N[3]
# set_location_assignment PIN_BA43 -to QSFPDD0_RX_N[4]
# set_location_assignment PIN_AY46 -to QSFPDD0_RX_N[5]
# set_location_assignment PIN_AU43 -to QSFPDD0_RX_N[6]
# set_location_assignment PIN_AT46 -to QSFPDD0_RX_N[7]

set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[0]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[1]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[2]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[3]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[4]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[5]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[6]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD0_RX_P[7]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[0] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[1] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[2] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[3] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[4] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[5] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[6] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD0_RX_P[7] -entity cardtest_top
# QSFPDD Tx HSSI assigments are in the qsf

# QSFP-DD1 pinout for Ethernet (lane indexing reversed w.r.t cardtest/Hardware Reference Guide signal names)
# F-tile Quad1 Lanes 3-0, QSFPDD1[0] - Quad1, FGT/CH3
# F-tile Quad0 Lanes 7-4, QSFPDD1[7] - Quad0, FGT/CH0
set_location_assignment PIN_CR41 -to QSFPDD1_TX_P[7]
set_location_assignment PIN_CL41 -to QSFPDD1_TX_P[6]
set_location_assignment PIN_CG41 -to QSFPDD1_TX_P[5]
set_location_assignment PIN_CF44 -to QSFPDD1_TX_P[4]
set_location_assignment PIN_CC41 -to QSFPDD1_TX_P[3]
set_location_assignment PIN_CB44 -to QSFPDD1_TX_P[2]
set_location_assignment PIN_BW41 -to QSFPDD1_TX_P[1]
set_location_assignment PIN_BV44 -to QSFPDD1_TX_P[0]
set_location_assignment PIN_CT40 -to QSFPDD1_TX_N[7]
set_location_assignment PIN_CM40 -to QSFPDD1_TX_N[6]
set_location_assignment PIN_CH40 -to QSFPDD1_TX_N[5]
set_location_assignment PIN_CE43 -to QSFPDD1_TX_N[4]
set_location_assignment PIN_CD40 -to QSFPDD1_TX_N[3]
set_location_assignment PIN_CA43 -to QSFPDD1_TX_N[2]
set_location_assignment PIN_BY40 -to QSFPDD1_TX_N[1]
set_location_assignment PIN_BU43 -to QSFPDD1_TX_N[0]
set_location_assignment PIN_CV44 -to QSFPDD1_RX_P[7]
set_location_assignment PIN_CR47 -to QSFPDD1_RX_P[6]
set_location_assignment PIN_CP44 -to QSFPDD1_RX_P[5]
set_location_assignment PIN_CL47 -to QSFPDD1_RX_P[4]
set_location_assignment PIN_CK44 -to QSFPDD1_RX_P[3]
set_location_assignment PIN_CG47 -to QSFPDD1_RX_P[2]
set_location_assignment PIN_CC47 -to QSFPDD1_RX_P[1]
set_location_assignment PIN_BW47 -to QSFPDD1_RX_P[0]
set_location_assignment PIN_CU43 -to QSFPDD1_RX_N[7]
set_location_assignment PIN_CT46 -to QSFPDD1_RX_N[6]
set_location_assignment PIN_CN43 -to QSFPDD1_RX_N[5]
set_location_assignment PIN_CM46 -to QSFPDD1_RX_N[4]
set_location_assignment PIN_CJ43 -to QSFPDD1_RX_N[3]
set_location_assignment PIN_CH46 -to QSFPDD1_RX_N[2]
set_location_assignment PIN_CD46 -to QSFPDD1_RX_N[1]
set_location_assignment PIN_BY46 -to QSFPDD1_RX_N[0]

# # QSFP-DD1 pinout for cardtest (as detailed in the Hardware Reference Guide signal names)
# # F-tile Quad1 Lanes 4-7, QSFPDD1[7] - Quad1, FGT/CH3
# # F-tile Quad0 Lanes 0-3, QSFPDD1[0] - Quad0, FGT/CH0
# set_location_assignment PIN_CR41 -to QSFPDD1_TX_P[0]
# set_location_assignment PIN_CL41 -to QSFPDD1_TX_P[1]
# set_location_assignment PIN_CG41 -to QSFPDD1_TX_P[2]
# set_location_assignment PIN_CF44 -to QSFPDD1_TX_P[3]
# set_location_assignment PIN_CC41 -to QSFPDD1_TX_P[4]
# set_location_assignment PIN_CB44 -to QSFPDD1_TX_P[5]
# set_location_assignment PIN_BW41 -to QSFPDD1_TX_P[6]
# set_location_assignment PIN_BV44 -to QSFPDD1_TX_P[7]
# set_location_assignment PIN_CT40 -to QSFPDD1_TX_N[0]
# set_location_assignment PIN_CM40 -to QSFPDD1_TX_N[1]
# set_location_assignment PIN_CH40 -to QSFPDD1_TX_N[2]
# set_location_assignment PIN_CE43 -to QSFPDD1_TX_N[3]
# set_location_assignment PIN_CD40 -to QSFPDD1_TX_N[4]
# set_location_assignment PIN_CA43 -to QSFPDD1_TX_N[5]
# set_location_assignment PIN_BY40 -to QSFPDD1_TX_N[6]
# set_location_assignment PIN_BU43 -to QSFPDD1_TX_N[7]
# set_location_assignment PIN_CV44 -to QSFPDD1_RX_P[0]
# set_location_assignment PIN_CR47 -to QSFPDD1_RX_P[1]
# set_location_assignment PIN_CP44 -to QSFPDD1_RX_P[2]
# set_location_assignment PIN_CL47 -to QSFPDD1_RX_P[3]
# set_location_assignment PIN_CK44 -to QSFPDD1_RX_P[4]
# set_location_assignment PIN_CG47 -to QSFPDD1_RX_P[5]
# set_location_assignment PIN_CC47 -to QSFPDD1_RX_P[6]
# set_location_assignment PIN_BW47 -to QSFPDD1_RX_P[7]
# set_location_assignment PIN_CU43 -to QSFPDD1_RX_N[0]
# set_location_assignment PIN_CT46 -to QSFPDD1_RX_N[1]
# set_location_assignment PIN_CN43 -to QSFPDD1_RX_N[2]
# set_location_assignment PIN_CM46 -to QSFPDD1_RX_N[3]
# set_location_assignment PIN_CJ43 -to QSFPDD1_RX_N[4]
# set_location_assignment PIN_CH46 -to QSFPDD1_RX_N[5]
# set_location_assignment PIN_CD46 -to QSFPDD1_RX_N[6]
# set_location_assignment PIN_BY46 -to QSFPDD1_RX_N[7]

set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[0]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[1]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[2]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[3]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[4]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[5]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[6]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_ac_couple_enable=ENABLE" -to QSFPDD1_RX_P[7]  -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[0] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[1] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[2] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[3] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[4] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[5] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[6] -entity cardtest_top
set_instance_assignment -name HSSI_PARAMETER "rx_onchip_termination=RX_ONCHIP_TERMINATION_R_2" -to QSFPDD1_RX_P[7] -entity cardtest_top
# QSFPDD Tx HSSI assigments are in the qsf


# -------------------------------------------
# Board Management Controller (BMC) Interface
# -------------------------------------------
# BMC interface FPGA Egress SPI and IRQ
set_location_assignment PIN_A17 -to FPGA_EG_SPI_SCK
set_location_assignment PIN_B18 -to FPGA_EG_SPI_MISO
set_location_assignment PIN_E19 -to FPGA_EG_SPI_MOSI
set_location_assignment PIN_D20 -to FPGA_EG_SPI_PCS0
set_location_assignment PIN_J19 -to BMC_TO_FPGA_IRQ

# BMC interface FPGA Ingress SPI and IRQ
set_location_assignment PIN_A19 -to FPGA_IG_SPI_SCK
set_location_assignment PIN_B20 -to FPGA_IG_SPI_MISO
set_location_assignment PIN_E21 -to FPGA_IG_SPI_MOSI
set_location_assignment PIN_D22 -to FPGA_IG_SPI_PCS0
set_location_assignment PIN_J17 -to FPGA_TO_BMC_IRQ

# BMC interface present in FPGA design
set_location_assignment PIN_K18 -to BMC_IF_PRESENT_L

# BMC_GPIO0 and BMC_GPIO1 are reserved for future use
# BMC_GPIO0 - General purpose output from the FPGA to the BMC
# BMC_GPIO1 - General purpose input from the BMC to the FPGA
set_location_assignment PIN_E27 -to BMC_GPIO0
set_location_assignment PIN_D28 -to BMC_GPIO1


# ---------------------------------------
# Board Management Controller (BMC) reset
# ---------------------------------------
# Reset from the BMC - independant from the BMC interface
set_location_assignment PIN_G17 -to BMC_RST_L


# ---------------
# Other - Bank 3A
# ---------------
# LED
set_location_assignment PIN_E25 -to LED_G_L
set_location_assignment PIN_D26 -to LED_R_L
set_instance_assignment -name IO_STANDARD "1.2 V" -to LED_G_L
set_instance_assignment -name IO_STANDARD "1.2 V" -to LED_R_L

# External GPIO
set_location_assignment PIN_P28 -to EXT_GPIO_EN_L
set_location_assignment PIN_D30 -to EXT_GPIO[0]
set_location_assignment PIN_G25 -to EXT_GPIO[1]
set_location_assignment PIN_J27 -to EXT_GPIO[2]
set_location_assignment PIN_G29 -to EXT_GPIO[3]
set_location_assignment PIN_J13 -to EXT_GPIO_DIR[0]
set_location_assignment PIN_R19 -to EXT_GPIO_DIR[1]
set_location_assignment PIN_L23 -to EXT_GPIO_DIR[2]
set_location_assignment PIN_P30 -to EXT_GPIO_DIR[3]

set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO_EN_L
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO[0]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO[1]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO[2]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO[3]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO_DIR[0]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO_DIR[1]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO_DIR[2]
set_instance_assignment -name IO_STANDARD "1.2 V" -to EXT_GPIO_DIR[3]

# Test Point
set_location_assignment PIN_A13 -to DEBUG_TP
set_instance_assignment -name IO_STANDARD "1.2 V" -to DEBUG_TP

# DDR4 Test mode enable
# Included only for completeness. Should never be asserted. Deliberatly commented out.
# set_location_assignment PIN_L25 -to DDR4_TEN
# set_instance_assignment -name IO_STANDARD "1.2 V" -to DDR4_TEN


# -------------
# Miscellaneous
# -------------
# Included only for completeness. Deliberatly commented out.
# # TEMPDIODE0A - SDM temperature diode
# set_location_assignment PIN_CL35 -to SDM_DX_P
# set_location_assignment PIN_CK34 -to SDM_DX_N
# # TEMPDIODE1 - F-tile temperature diode
# set_location_assignment PIN_CG33 -to FTILE_DX_P
# set_location_assignment PIN_CF32 -to FTILE_DX_N
# # TEMPDIODE0C - FPGA fabric temperature diode
# set_location_assignment PIN_W29  -to FABRIC_DX_P
# set_location_assignment PIN_AA29 -to FABRIC_DX_N
# # F-tile PERST - Tied to GND
# set_location_assignment PIN_CD30 -to PERST_FTILE_1V8_L


# --------
# HPS Bank
# --------
# HPS_IOA_1  - PIN_AH10
set_location_assignment PIN_AH10 -to HPS_NAND_D[0]
# HPS_IOA_2  - PIN_AN9
set_location_assignment PIN_AN9  -to HPS_NAND_D[1]
# HPS_IOA_3  - PIN_AJ11
set_location_assignment PIN_AJ11 -to HPS_NAND_WE_L
# HPS_IOA_4  - PIN_AP10
set_location_assignment PIN_AP10 -to HPS_NAND_RE_L
# HPS_IOA_5  - PIN_AL11
set_location_assignment PIN_AL11 -to HPS_NAND_WP_L
# HPS_IOA_6  - PIN_AP8
set_location_assignment PIN_AP8  -to HPS_NAND_D[2]
# HPS_IOA_7  - PIN_AL9
set_location_assignment PIN_AL9  -to HPS_NAND_D[3]
# HPS_IOA_8  - PIN_AN7
set_location_assignment PIN_AN7  -to HPS_NAND_CLE
# HPS_IOA_9  - PIN_AJ9
set_location_assignment PIN_AJ9  -to HPS_NAND_D[4]
# HPS_IOA_10 - PIN_AM8
set_location_assignment PIN_AM8  -to HPS_NAND_D[5]
# HPS_IOA_11 - PIN_AH8
set_location_assignment PIN_AH8  -to HPS_NAND_D[6]
# HPS_IOA_12 - PIN_AL7
set_location_assignment PIN_AL7  -to HPS_NAND_D[7]
# HPS_IOA_13 - PIN_AG9
set_location_assignment PIN_AG9  -to HPS_NAND_ALE
# HPS_IOA_14 - PIN_AP6
set_location_assignment PIN_AP6  -to HPS_NAND_RB_L
# HPS_IOA_15 - PIN_AF8
set_location_assignment PIN_AF8  -to HPS_NAND_CE_L
# HPS_IOA_21 - PIN_AH6
set_location_assignment PIN_AH6  -to HPS_CLK

# HPS_IOB_3  - PIN_AG5
set_location_assignment PIN_AG5 -to HPS_UART_TXD
# HPS_IOB_4  - PIN_AN3
set_location_assignment PIN_AN3 -to HPS_UART_RXD
# HPS_IOB_7  - PIN_AG3
set_location_assignment PIN_AG3 -to ETH_PHY_RESET_L
# HPS_IOB_9  - PIN_AF4
set_location_assignment PIN_AF4 -to EMAC_MDIO
# HPS_IOB_10 - PIN_AJ3
set_location_assignment PIN_AJ3 -to EMAC_MDC
# HPS_IOB_13 - PIN_AD6
set_location_assignment PIN_AD6 -to EMAC_TX_CLK
# HPS_IOB_14 - PIN_AP2
set_location_assignment PIN_AP2 -to EMAC_TX_CTL
# HPS_IOB_15 - PIN_AC5
set_location_assignment PIN_AC5 -to EMAC_RX_CLK
# HPS_IOB_16 - PIN_AN1
set_location_assignment PIN_AN1 -to EMAC_RX_CTL
# HPS_IOB_17 - PIN_AD4
set_location_assignment PIN_AD4 -to EMAC_TXD[0]
# HPS_IOB_18 - PIN_AM2
set_location_assignment PIN_AM2 -to EMAC_TXD[1]
# HPS_IOB_19 - PIN_AC3
set_location_assignment PIN_AC3 -to EMAC_RXD[0]
# HPS_IOB_20 - PIN_AL1
set_location_assignment PIN_AL1 -to EMAC_RXD[1]
# HPS_IOB_21 - PIN_AC1
set_location_assignment PIN_AC1 -to EMAC_TXD[2]
# HPS_IOB_22 - PIN_AJ1
set_location_assignment PIN_AJ1 -to EMAC_TXD[3]
# HPS_IOB_23 - PIN_AD2
set_location_assignment PIN_AD2 -to EMAC_RXD[2]
# HPS_IOB_24 - PIN_AG1
set_location_assignment PIN_AG1 -to EMAC_RXD[3]


# --------------------------
# SDM Bank - non-fabric pins
# --------------------------
# SDM_IO0   - PIN_CU31
set_location_assignment PIN_CU31 -to PWRMGT_SCL
# SDM_IO1   - PIN_CN31
set_location_assignment PIN_CN31 -to AVST_DATA[2]
# SDM_IO2   - PIN_CY34
set_location_assignment PIN_CY34 -to AVST_DATA[0]
# SDM_IO3   - PIN_CV34
set_location_assignment PIN_CV34 -to AVST_DATA[3]
# SDM_IO4   - PIN_CK32
set_location_assignment PIN_CK32 -to AVST_DATA[1]
# SDM_IO5   - PIN_CM32
set_location_assignment PIN_CM32 -to INIT_DONE_MSEL[0]
# SDM_IO6   - PIN_CR31
set_location_assignment PIN_CR31 -to AVST_DATA[4]
# SDM_IO7   - PIN_DA31
set_location_assignment PIN_DA31 -to HPS_RESET_L_MSEL[1]
# SDM_IO8   - PIN_CU35
set_location_assignment PIN_CU35 -to AVST_READY
# SDM_IO9   - PIN_DA33
set_location_assignment PIN_DA33 -to PWRMGT_ALERT_MSEL[2]
# SDM_IO10  - PIN_CL31
set_location_assignment PIN_CL31 -to AVST_DATA[7]
# SDM_IO11  - PIN_CU33
set_location_assignment PIN_CU33 -to AVST_VALID
# SDM_IO12  - PIN_CY32
set_location_assignment PIN_CY32 -to PWRMGT_SDA
# SDM_IO13  - PIN_CR35
set_location_assignment PIN_CR35 -to AVST_DATA[5]
# SDM_IO14  - PIN_CT32
set_location_assignment PIN_CT32 -to AVST_CLK
# SDM_IO15  - PIN_CT34
set_location_assignment PIN_CT34 -to AVST_DATA[6]
# SDM_IO16  - PIN_CM34
 set_location_assignment PIN_CM34 -to CONF_DONE

# TDO       - PIN_CN35
set_location_assignment PIN_CN35 -to SDM_TDO
# nCONFIG   - PIN_CT36
set_location_assignment PIN_CT36 -to SDM_nCONFIG
# OSK_CLK_1 - PIN_CN33
set_location_assignment PIN_CN33 -to SDM_OSC_CLK_1
# nSTATUS   - PIN_CV32
set_location_assignment PIN_CV32 -to SDM_nSTATUS
# TMS       - PIN_CH32
set_location_assignment PIN_CH32 -to SDM_TMS
# TDI       - PIN_CR33
set_location_assignment PIN_CR33 -to SDM_TDI
# TCK       - PIN_CL33
set_location_assignment PIN_CL33 -to SDM_TCK
# RREF_SDM  - PIN_CP38
set_location_assignment PIN_CP38 -to RREF_SDM

