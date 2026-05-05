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


// Copyright 2022 Intel Corporation.
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

`include "cxl_type2_defines.svh.iv"

import cxlip_top_pkg::*;
import afu_axi_if_pkg::*;

`include "rnr_ial_sip_intf.svh.iv"

module intel_rtile_cxl_top_cxltyp2_ed_intel_rtile_cxl_top_1160_rsjc3dy #(
    parameter CXL2P0_COMPLIANCE = 1,
	parameter  ADME_ENABLE              =  1,
    parameter CXL_MEM_DEV_REGBLOCK_EN      = 1'h1,
    parameter CXL_MEM_DEV_REGBLOCK_OFFSET  = 32'h0018_0000,
	parameter  PF0_MSIX_CAP_EN          =  1'b0,
	parameter  PF0_MSIX_TABLE_SIZE      =  11'h000,
	parameter  PF0_MSIX_TABLE_MAO       =  29'h00000000,
	parameter  PF0_MSIX_TABLE_BIR       =  3'h0,
	parameter  PF0_MSIX_PBA_MAO         =  29'h00000000,
	parameter  PF0_MSIX_PBA_BIR         =  3'h0,
	parameter  PF1_MSIX_CAP_EN          =  1'b0,
	parameter  PF1_MSIX_TABLE_SIZE      =  11'h000,
	parameter  PF1_MSIX_TABLE_MAO       =  29'h00000000,
	parameter  PF1_MSIX_TABLE_BIR       =  3'h0,
	parameter  PF1_MSIX_PBA_MAO         =  29'h00000000,
	parameter  PF1_MSIX_PBA_BIR         =  3'h0,

    parameter  CXL_SCC_EN               =  1'b0 ,
    parameter PF1_BAR01_SIZE            = 14'd2,
    parameter  PTMCAP_EN                =  1'b0 ,
    parameter  PTM_AUTO_UPDATE          =  1'b0 ,
    parameter  PTMRCSR_RFSHTIME         =  4'b0000 ,
	parameter  DEVCAP_MPSS              =  2'h2,
	parameter  NUM_DCOH_SLICES_ENC_VAL  =  4'h1,
	parameter  CXL_FREQ_ENC_VAL         =  4'h6,
	parameter  CXL_TYPE_ENC_VAL         =  4'h2,

	parameter  CXLIPUNIQID              =  32'h00000000,
	parameter  PF0_CCRID_RID            =  8'h02,
	parameter  PF0_CCRID_PI             =  8'h00,
	parameter  PF0_CCRID_SUBCC          =  8'h00,
	parameter  PF0_CCRID_BCC            =  8'h12,
	parameter  PF0_DEVICE_ID            =  16'h0DDB,
	parameter  PF0_SID                  =  16'h0000,
	parameter  PF0_SVID                 =  16'h8086,
	parameter  PF0_VID                  =  16'h8086,
	parameter  PF1_CCRID_RID            =  8'h02,
	parameter  PF1_CCRID_PI             =  8'h00,
	parameter  PF1_CCRID_SUBCC          =  8'h00,
	parameter  PF1_CCRID_BCC            =  8'h12,
	parameter  PF1_DEVICE_ID            =  16'h0DDB,
	parameter  PF1_SID                  =  16'h0000,
	parameter  PF1_SVID                 =  16'h8086,
	parameter  PF1_VID                  =  16'h8086,
	parameter  HDMDECHDR_EN             =  1'b1,
        parameter  HDMDECHDR_CAPVER         = 4'h1, 
	parameter  DEVICE_PORT_TYPE         =  4'h9,
	parameter  T1IP_ENABLE              =  0
 )
 (
  input                             refclk0,     // to RTile
  input                             refclk1,     // to RTile
  input                             refclk4,     // to Fabric PLL
  input                             resetn,
  input                             nInit_done,
                                    
  //RX-TX interface                 
  input             [15:0]          cxl_rx_n,
  input             [15:0]          cxl_rx_p,
  output            [15:0]          cxl_tx_n,
  output            [15:0]          cxl_tx_p,
   
  
  output wire         phy_sys_ial_0__pipe_Reset_l,             //          phy_sys_ial_.0__pipe_Reset_l,       
  output wire         phy_sys_ial_1__pipe_Reset_l,             //                      .1__pipe_Reset_l,       
  output wire         phy_sys_ial_2__pipe_Reset_l,             //                      .2__pipe_Reset_l,       
  output wire         phy_sys_ial_3__pipe_Reset_l,             //                      .3__pipe_Reset_l,       
  output wire         phy_sys_ial_4__pipe_Reset_l,             //                      .4__pipe_Reset_l,       
  output wire         phy_sys_ial_5__pipe_Reset_l,             //                      .5__pipe_Reset_l,       
  output wire         phy_sys_ial_6__pipe_Reset_l,             //                      .6__pipe_Reset_l,       
  output wire         phy_sys_ial_7__pipe_Reset_l,             //                      .7__pipe_Reset_l,       
  output wire         phy_sys_ial_8__pipe_Reset_l,             //                      .8__pipe_Reset_l,       
  output wire         phy_sys_ial_9__pipe_Reset_l,             //                      .9__pipe_Reset_l,       
  output wire         phy_sys_ial_10__pipe_Reset_l,            //                      .10__pipe_Reset_l,      
  output wire         phy_sys_ial_11__pipe_Reset_l,            //                      .11__pipe_Reset_l,      
  output wire         phy_sys_ial_12__pipe_Reset_l,            //                      .12__pipe_Reset_l,      
  output wire         phy_sys_ial_13__pipe_Reset_l,            //                      .13__pipe_Reset_l,      
  output wire         phy_sys_ial_14__pipe_Reset_l,            //                      .14__pipe_Reset_l,      
  output wire         phy_sys_ial_15__pipe_Reset_l,            //                      .15__pipe_Reset_l,      
  output wire         o_phy_0_pipe_TxDataValid,                //         o_phy_0_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_0_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_0_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_0_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_0_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_0_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_0_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_0_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_0_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_0_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_0_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_0_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_0_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_0_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_0_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_0_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_0_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_0_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_0_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_0_pipe_RxClk,                      //         i_phy_0_pipe_.RxClk,                 
  input  wire         i_phy_0_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_0_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_0_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_0_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_0_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_0_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_0_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_0_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_0_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_1_pipe_TxDataValid,                //         o_phy_1_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_1_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_1_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_1_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_1_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_1_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_1_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_1_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_1_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_1_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_1_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_1_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_1_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_1_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_1_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_1_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_1_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_1_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_1_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_1_pipe_RxClk,                      //         i_phy_1_pipe_.RxClk,                 
  input  wire         i_phy_1_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_1_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_1_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_1_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_1_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_1_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_1_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_1_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_1_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_2_pipe_TxDataValid,                //         o_phy_2_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_2_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_2_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_2_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_2_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_2_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_2_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_2_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_2_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_2_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_2_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_2_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_2_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_2_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_2_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_2_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_2_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_2_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_2_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_2_pipe_RxClk,                      //         i_phy_2_pipe_.RxClk,                 
  input  wire         i_phy_2_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_2_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_2_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_2_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_2_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_2_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_2_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_2_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_2_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_3_pipe_TxDataValid,                //         o_phy_3_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_3_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_3_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_3_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_3_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_3_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_3_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_3_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_3_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_3_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_3_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_3_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_3_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_3_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_3_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_3_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_3_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_3_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_3_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_3_pipe_RxClk,                      //         i_phy_3_pipe_.RxClk,                 
  input  wire         i_phy_3_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_3_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_3_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_3_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_3_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_3_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_3_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_3_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_3_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_4_pipe_TxDataValid,                //         o_phy_4_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_4_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_4_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_4_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_4_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_4_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_4_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_4_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_4_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_4_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_4_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_4_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_4_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_4_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_4_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_4_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_4_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_4_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_4_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_4_pipe_RxClk,                      //         i_phy_4_pipe_.RxClk,                 
  input  wire         i_phy_4_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_4_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_4_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_4_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_4_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_4_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_4_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_4_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_4_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_5_pipe_TxDataValid,                //         o_phy_5_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_5_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_5_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_5_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_5_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_5_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_5_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_5_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_5_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_5_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_5_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_5_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_5_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_5_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_5_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_5_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_5_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_5_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_5_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_5_pipe_RxClk,                      //         i_phy_5_pipe_.RxClk,                 
  input  wire         i_phy_5_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_5_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_5_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_5_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_5_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_5_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_5_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_5_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_5_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_6_pipe_TxDataValid,                //         o_phy_6_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_6_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_6_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_6_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_6_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_6_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_6_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_6_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_6_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_6_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_6_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_6_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_6_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_6_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_6_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_6_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_6_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_6_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_6_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_6_pipe_RxClk,                      //         i_phy_6_pipe_.RxClk,                 
  input  wire         i_phy_6_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_6_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_6_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_6_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_6_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_6_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_6_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_6_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_6_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_7_pipe_TxDataValid,                //         o_phy_7_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_7_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_7_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_7_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_7_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_7_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_7_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_7_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_7_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_7_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_7_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_7_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_7_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_7_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_7_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_7_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_7_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_7_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_7_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_7_pipe_RxClk,                      //         i_phy_7_pipe_.RxClk,                 
  input  wire         i_phy_7_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_7_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_7_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_7_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_7_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_7_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_7_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_7_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_7_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_8_pipe_TxDataValid,                //         o_phy_8_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_8_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_8_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_8_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_8_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_8_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_8_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_8_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_8_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_8_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_8_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_8_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_8_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_8_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_8_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_8_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_8_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_8_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_8_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_8_pipe_RxClk,                      //         i_phy_8_pipe_.RxClk,                 
  input  wire         i_phy_8_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_8_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_8_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_8_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_8_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_8_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_8_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_8_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_8_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_9_pipe_TxDataValid,                //         o_phy_9_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_9_pipe_TxData,                     //                      .TxData,                
  output wire         o_phy_9_pipe_TxDetRxLpbk,                //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_9_pipe_TxElecIdle,                 //                      .TxElecIdle,            
  output wire [3:0]   o_phy_9_pipe_PowerDown,                  //                      .PowerDown,             
  output wire [2:0]   o_phy_9_pipe_Rate,                       //                      .Rate,                  
  output wire         o_phy_9_pipe_PclkChangeAck,              //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_9_pipe_PCLKRate,                   //                      .PCLKRate,              
  output wire [1:0]   o_phy_9_pipe_Width,                      //                      .Width,                 
  output wire         o_phy_9_pipe_PCLK,                       //                      .PCLK,                  
  output wire         o_phy_9_pipe_rxelecidle_disable,         //                      .rxelecidle_disable,    
  output wire         o_phy_9_pipe_txcmnmode_disable,          //                      .txcmnmode_disable,     
  output wire         o_phy_9_pipe_srisenable,                 //                      .srisenable,            
  output wire         o_phy_9_pipe_RxStandby,                  //                      .RxStandby,             
  output wire         o_phy_9_pipe_RxTermination,              //                      .RxTermination,         
  output wire [1:0]   o_phy_9_pipe_RxWidth,                    //                      .RxWidth,               
  output wire [7:0]   o_phy_9_pipe_M2P_MessageBus,             //                      .M2P_MessageBus,        
  output wire         o_phy_9_pipe_rxbitslip_req,              //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_9_pipe_rxbitslip_va,               //                      .rxbitslip_va,          
  input  wire         i_phy_9_pipe_RxClk,                      //         i_phy_9_pipe_.RxClk,                 
  input  wire         i_phy_9_pipe_RxValid,                    //                      .RxValid,               
  input  wire [39:0]  i_phy_9_pipe_RxData,                     //                      .RxData,                
  input  wire         i_phy_9_pipe_RxElecIdle,                 //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_9_pipe_RxStatus,                   //                      .RxStatus,              
  input  wire         i_phy_9_pipe_RxStandbyStatus,            //                      .RxStandbyStatus,       
  input  wire         i_phy_9_pipe_PhyStatus,                  //                      .PhyStatus,             
  input  wire         i_phy_9_pipe_PclkChangeOk,               //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_9_pipe_P2M_MessageBus,             //                      .P2M_MessageBus,        
  input  wire         i_phy_9_pipe_RxBitSlip_Ack,              //                      .RxBitSlip_Ack,         
  output wire         o_phy_10_pipe_TxDataValid,               //        o_phy_10_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_10_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_10_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_10_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_10_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_10_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_10_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_10_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_10_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_10_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_10_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_10_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_10_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_10_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_10_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_10_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_10_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_10_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_10_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_10_pipe_RxClk,                     //        i_phy_10_pipe_.RxClk,                 
  input  wire         i_phy_10_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_10_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_10_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_10_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_10_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_10_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_10_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_10_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_10_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         
  output wire         o_phy_11_pipe_TxDataValid,               //        o_phy_11_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_11_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_11_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_11_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_11_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_11_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_11_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_11_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_11_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_11_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_11_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_11_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_11_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_11_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_11_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_11_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_11_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_11_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_11_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_11_pipe_RxClk,                     //        i_phy_11_pipe_.RxClk,                 
  input  wire         i_phy_11_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_11_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_11_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_11_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_11_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_11_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_11_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_11_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_11_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         
  output wire         o_phy_12_pipe_TxDataValid,               //        o_phy_12_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_12_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_12_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_12_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_12_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_12_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_12_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_12_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_12_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_12_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_12_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_12_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_12_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_12_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_12_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_12_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_12_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_12_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_12_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_12_pipe_RxClk,                     //        i_phy_12_pipe_.RxClk,                 
  input  wire         i_phy_12_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_12_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_12_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_12_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_12_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_12_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_12_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_12_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_12_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         
  output wire         o_phy_13_pipe_TxDataValid,               //        o_phy_13_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_13_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_13_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_13_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_13_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_13_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_13_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_13_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_13_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_13_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_13_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_13_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_13_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_13_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_13_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_13_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_13_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_13_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_13_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_13_pipe_RxClk,                     //        i_phy_13_pipe_.RxClk,                 
  input  wire         i_phy_13_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_13_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_13_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_13_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_13_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_13_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_13_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_13_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_13_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         
  output wire         o_phy_14_pipe_TxDataValid,               //        o_phy_14_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_14_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_14_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_14_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_14_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_14_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_14_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_14_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_14_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_14_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_14_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_14_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_14_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_14_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_14_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_14_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_14_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_14_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_14_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_14_pipe_RxClk,                     //        i_phy_14_pipe_.RxClk,                 
  input  wire         i_phy_14_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_14_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_14_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_14_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_14_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_14_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_14_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_14_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_14_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         
  output wire         o_phy_15_pipe_TxDataValid,               //        o_phy_15_pipe_.TxDataValid,           
  output wire [39:0]  o_phy_15_pipe_TxData,                    //                      .TxData,                
  output wire         o_phy_15_pipe_TxDetRxLpbk,               //                      .TxDetRxLpbk,           
  output wire [3:0]   o_phy_15_pipe_TxElecIdle,                //                      .TxElecIdle,            
  output wire [3:0]   o_phy_15_pipe_PowerDown,                 //                      .PowerDown,             
  output wire [2:0]   o_phy_15_pipe_Rate,                      //                      .Rate,                  
  output wire         o_phy_15_pipe_PclkChangeAck,             //                      .PclkChangeAck,         
  output wire [2:0]   o_phy_15_pipe_PCLKRate,                  //                      .PCLKRate,              
  output wire [1:0]   o_phy_15_pipe_Width,                     //                      .Width,                 
  output wire         o_phy_15_pipe_PCLK,                      //                      .PCLK,                  
  output wire         o_phy_15_pipe_rxelecidle_disable,        //                      .rxelecidle_disable,    
  output wire         o_phy_15_pipe_txcmnmode_disable,         //                      .txcmnmode_disable,     
  output wire         o_phy_15_pipe_srisenable,                //                      .srisenable,            
  output wire         o_phy_15_pipe_RxStandby,                 //                      .RxStandby,             
  output wire         o_phy_15_pipe_RxTermination,             //                      .RxTermination,         
  output wire [1:0]   o_phy_15_pipe_RxWidth,                   //                      .RxWidth,               
  output wire [7:0]   o_phy_15_pipe_M2P_MessageBus,            //                      .M2P_MessageBus,        
  output wire         o_phy_15_pipe_rxbitslip_req,             //                      .rxbitslip_req,         
  output wire [4:0]   o_phy_15_pipe_rxbitslip_va,              //                      .rxbitslip_va,          
  input  wire         i_phy_15_pipe_RxClk,                     //        i_phy_15_pipe_.RxClk,                 
  input  wire         i_phy_15_pipe_RxValid,                   //                      .RxValid,               
  input  wire [39:0]  i_phy_15_pipe_RxData,                    //                      .RxData,                
  input  wire         i_phy_15_pipe_RxElecIdle,                //                      .RxElecIdle,            
  input  wire [2:0]   i_phy_15_pipe_RxStatus,                  //                      .RxStatus,              
  input  wire         i_phy_15_pipe_RxStandbyStatus,           //                      .RxStandbyStatus,       
  input  wire         i_phy_15_pipe_PhyStatus,                 //                      .PhyStatus,             
  input  wire         i_phy_15_pipe_PclkChangeOk,              //                      .PclkChangeOk,          
  input  wire [7:0]   i_phy_15_pipe_P2M_MessageBus,            //                      .P2M_MessageBus,        
  input  wire         i_phy_15_pipe_RxBitSlip_Ack,             //                      .RxBitSlip_Ack,         


  output logic                      ip2hdm_clk,
  output logic                      ip2hdm_reset_n ,	
  output logic                      cxl_warm_rst_n,
  output logic                      cxl_cold_rst_n,
  output logic                      pll_lock_o,


 // DDRMC <--> IP
  input  logic [63:0]               mc2ip_memsize,

  input logic  [1:0]                usr2ip_qos_devload,
  input logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]          mc2ip_0_sr_status,    
  input logic [cxlip_top_pkg::MC_SR_STAT_WIDTH-1:0]          mc2ip_1_sr_status,    

     // write address channel
      
  output logic          ip2hdm_aximm0_awvalid,       
  output logic  [7:0]  ip2hdm_aximm0_awid,       
  output logic  [51:0]  ip2hdm_aximm0_awaddr,       
  output logic  [9:0]   ip2hdm_aximm0_awlen,       
  output logic  [3:0]   ip2hdm_aximm0_awregion,       
  output logic          ip2hdm_aximm0_awuser,       
  output logic  [2:0]   ip2hdm_aximm0_awsize,      
  output logic  [1:0]   ip2hdm_aximm0_awburst,      
  output logic  [2:0]   ip2hdm_aximm0_awprot,      
  output logic  [3:0]   ip2hdm_aximm0_awqos,      
  output logic  [3:0]   ip2hdm_aximm0_awcache,      
  output logic  [1:0]   ip2hdm_aximm0_awlock,      
  input  logic          hdm2ip_aximm0_awready,
     // write data channel
      
  output logic          ip2hdm_aximm0_wvalid,          
  output logic  [511:0] ip2hdm_aximm0_wdata,           
  output logic  [63:0]  ip2hdm_aximm0_wstrb,           
  output logic          ip2hdm_aximm0_wlast,           
  output logic          ip2hdm_aximm0_wuser,           
  input logic           hdm2ip_aximm0_wready,
     // write response channel
      
  input  logic          hdm2ip_aximm0_bvalid,
  input  logic [7:0]   hdm2ip_aximm0_bid,
  input  logic          hdm2ip_aximm0_buser,
  input  logic [1:0]    hdm2ip_aximm0_bresp,
  output logic          ip2hdm_aximm0_bready,               
     // read address channel
      
  output logic          ip2hdm_aximm0_arvalid,         
  output logic  [7:0]  ip2hdm_aximm0_arid,         
  output logic  [51:0]  ip2hdm_aximm0_araddr,         
  output logic  [9:0]   ip2hdm_aximm0_arlen,         
  output logic  [3:0]   ip2hdm_aximm0_arregion,         
  output logic          ip2hdm_aximm0_aruser,         
  output logic  [2:0]   ip2hdm_aximm0_arsize,         
  output logic  [1:0]   ip2hdm_aximm0_arburst,         
  output logic  [2:0]   ip2hdm_aximm0_arprot,         
  output logic  [3:0]   ip2hdm_aximm0_arqos,         
  output logic  [3:0]   ip2hdm_aximm0_arcache,         
  output logic  [1:0]   ip2hdm_aximm0_arlock,         
  input  logic          hdm2ip_aximm0_arready, 
    //  read response channel
      
  input  logic          hdm2ip_aximm0_rvalid,
  input  logic          hdm2ip_aximm0_rlast,
  input  logic  [7:0]   hdm2ip_aximm0_rid,
  input  logic  [511:0] hdm2ip_aximm0_rdata,
  input  logic          hdm2ip_aximm0_ruser,
  input  logic  [1:0]   hdm2ip_aximm0_rresp,
  output logic          ip2hdm_aximm0_rready,   



     // write address channel
      
  output logic          ip2hdm_aximm1_awvalid,       
  output logic  [7:0]  ip2hdm_aximm1_awid,       
  output logic  [51:0]  ip2hdm_aximm1_awaddr,       
  output logic  [9:0]   ip2hdm_aximm1_awlen,       
  output logic  [3:0]   ip2hdm_aximm1_awregion,       
  output logic          ip2hdm_aximm1_awuser,       
  output logic  [2:0]   ip2hdm_aximm1_awsize,      
  output logic  [1:0]   ip2hdm_aximm1_awburst,      
  output logic  [2:0]   ip2hdm_aximm1_awprot,      
  output logic  [3:0]   ip2hdm_aximm1_awqos,      
  output logic  [3:0]   ip2hdm_aximm1_awcache,      
  output logic  [1:0]   ip2hdm_aximm1_awlock,      
  input  logic          hdm2ip_aximm1_awready,
     // write data channel
      
  output logic          ip2hdm_aximm1_wvalid,          
  output logic  [511:0] ip2hdm_aximm1_wdata,           
  output logic  [63:0]  ip2hdm_aximm1_wstrb,           
  output logic          ip2hdm_aximm1_wlast,           
  output logic          ip2hdm_aximm1_wuser,           
  input logic           hdm2ip_aximm1_wready,
     // write response channel
      
  input  logic          hdm2ip_aximm1_bvalid,
  input  logic [7:0]   hdm2ip_aximm1_bid,
  input  logic          hdm2ip_aximm1_buser,
  input  logic [1:0]    hdm2ip_aximm1_bresp,
  output logic          ip2hdm_aximm1_bready,               
     // read address channel
      
  output logic          ip2hdm_aximm1_arvalid,         
  output logic  [7:0]  ip2hdm_aximm1_arid,         
  output logic  [51:0]  ip2hdm_aximm1_araddr,         
  output logic  [9:0]   ip2hdm_aximm1_arlen,         
  output logic  [3:0]   ip2hdm_aximm1_arregion,         
  output logic          ip2hdm_aximm1_aruser,         
  output logic  [2:0]   ip2hdm_aximm1_arsize,         
  output logic  [1:0]   ip2hdm_aximm1_arburst,         
  output logic  [2:0]   ip2hdm_aximm1_arprot,         
  output logic  [3:0]   ip2hdm_aximm1_arqos,         
  output logic  [3:0]   ip2hdm_aximm1_arcache,         
  output logic  [1:0]   ip2hdm_aximm1_arlock,         
  input  logic          hdm2ip_aximm1_arready, 
     // read response channel
  input  logic          hdm2ip_aximm1_rvalid, 
  input  logic          hdm2ip_aximm1_rlast, 
  input  logic  [7:0]   hdm2ip_aximm1_rid,
  input  logic  [511:0] hdm2ip_aximm1_rdata,
  input  logic          hdm2ip_aximm1_ruser,
  input  logic  [1:0]   hdm2ip_aximm1_rresp,
  output logic          ip2hdm_aximm1_rready,  




    output logic                                 ip2cafu_quiesce_req,
    input logic                                  cafu2ip_quiesce_ack,
        //CXL RESET handshake signal to ED 
    input  logic                                usr2ip_cxlreset_initiate, 
    output logic                                ip2usr_cxlreset_req,  
    input  logic                                usr2ip_cxlreset_ack,  
    output logic                                ip2usr_cxlreset_error,
    output logic                                ip2usr_cxlreset_complete, 
    output logic                                ip2usr_gpf_ph2_req_o,
    input  logic                                usr2ip_gpf_ph2_ack_i,
    input  logic [1:0]                          usr2ip_cache_evict_policy , 
 
  //AXI <-->         write address channels
   input [11:0]               cafu2ip_aximm0_awid,
   input [63:0]               cafu2ip_aximm0_awaddr, 
   input [9:0]                cafu2ip_aximm0_awlen,
   input [2:0]                cafu2ip_aximm0_awsize,
   input [1:0]                cafu2ip_aximm0_awburst,
   input [2:0]                cafu2ip_aximm0_awprot,
   input [3:0]                cafu2ip_aximm0_awqos,
   input [6:0]                cafu2ip_aximm0_awuser,
   input                      cafu2ip_aximm0_awvalid,
   input [3:0]                cafu2ip_aximm0_awcache,
   input [1:0]                cafu2ip_aximm0_awlock,
   input [3:0]                cafu2ip_aximm0_awregion,
   input [5:0]                cafu2ip_aximm0_awatop,   
   output logic               ip2cafu_aximm0_awready,
  
   input [11:0]               cafu2ip_aximm1_awid,
   input [63:0]               cafu2ip_aximm1_awaddr, 
   input [9:0]                cafu2ip_aximm1_awlen,
   input [2:0]                cafu2ip_aximm1_awsize,
   input [1:0]                cafu2ip_aximm1_awburst,
   input [2:0]                cafu2ip_aximm1_awprot,
   input [3:0]                cafu2ip_aximm1_awqos,
   input [6:0]                cafu2ip_aximm1_awuser,
   input                      cafu2ip_aximm1_awvalid,
   input [3:0]                cafu2ip_aximm1_awcache,
   input [1:0]                cafu2ip_aximm1_awlock,
   input [3:0]                cafu2ip_aximm1_awregion,
   input [5:0]                cafu2ip_aximm1_awatop,   
   output logic               ip2cafu_aximm1_awready,
  
  //AXI <-->    write data channels
   input [511:0]              cafu2ip_aximm0_wdata,
   input [(512/8)-1:0]        cafu2ip_aximm0_wstrb,
   input                      cafu2ip_aximm0_wlast,
   input                      cafu2ip_aximm0_wuser,
   input                      cafu2ip_aximm0_wvalid,
   output logic               ip2cafu_aximm0_wready,
  
   input [511:0]              cafu2ip_aximm1_wdata,
   input [(512/8)-1:0]        cafu2ip_aximm1_wstrb,
   input                      cafu2ip_aximm1_wlast,
   input                      cafu2ip_aximm1_wuser,
   input                      cafu2ip_aximm1_wvalid,
   output logic               ip2cafu_aximm1_wready,
  
  //AXI <-->         write response channels
  output logic [11:0]         ip2cafu_aximm0_bid,
  output logic [1:0]          ip2cafu_aximm0_bresp,
  output logic [3:0]          ip2cafu_aximm0_buser,
  output logic                ip2cafu_aximm0_bvalid,
   input                      cafu2ip_aximm0_bready,
  
  output logic [11:0]         ip2cafu_aximm1_bid,
  output logic [1:0]          ip2cafu_aximm1_bresp,
  output logic [3:0]          ip2cafu_aximm1_buser,
  output logic                ip2cafu_aximm1_bvalid,
   input                      cafu2ip_aximm1_bready,
  
  //AXI <-->        read address channels
   input [11:0]               cafu2ip_aximm0_arid,
   input [63:0]               cafu2ip_aximm0_araddr,
   input [9:0]                cafu2ip_aximm0_arlen,
   input [2:0]                cafu2ip_aximm0_arsize,
   input [1:0]                cafu2ip_aximm0_arburst,
   input [2:0]                cafu2ip_aximm0_arprot,
   input [3:0]                cafu2ip_aximm0_arqos,
   input [5:0]                cafu2ip_aximm0_aruser,
   input                      cafu2ip_aximm0_arvalid,
   input [3:0]                cafu2ip_aximm0_arcache,
   input [1:0]                cafu2ip_aximm0_arlock,
   input [3:0]                cafu2ip_aximm0_arregion,
  output logic                ip2cafu_aximm0_arready,
  
   input [11:0]               cafu2ip_aximm1_arid,
   input [63:0]               cafu2ip_aximm1_araddr,
   input [9:0]                cafu2ip_aximm1_arlen,
   input [2:0]                cafu2ip_aximm1_arsize,
   input [1:0]                cafu2ip_aximm1_arburst,
   input [2:0]                cafu2ip_aximm1_arprot,
   input [3:0]                cafu2ip_aximm1_arqos,
   input [5:0]                cafu2ip_aximm1_aruser,
   input                      cafu2ip_aximm1_arvalid,
   input [3:0]                cafu2ip_aximm1_arcache,
   input [1:0]                cafu2ip_aximm1_arlock,
   input [3:0]                cafu2ip_aximm1_arregion,
  output logic                ip2cafu_aximm1_arready,

  //AXI <-->         read response channels
  output logic [11:0]         ip2cafu_aximm0_rid,
  output logic [511:0]        ip2cafu_aximm0_rdata,
  output logic [1:0]          ip2cafu_aximm0_rresp,
  output logic                ip2cafu_aximm0_rlast,
  output logic [AFU_AXI_RUSER_WIDTH-1:0] ip2cafu_aximm0_ruser,
  output logic                ip2cafu_aximm0_rvalid,
   input                      cafu2ip_aximm0_rready,
  
  output logic [11:0]         ip2cafu_aximm1_rid,
  output logic [511:0]        ip2cafu_aximm1_rdata,
  output logic [1:0]          ip2cafu_aximm1_rresp,
  output logic                ip2cafu_aximm1_rlast,
  output logic [AFU_AXI_RUSER_WIDTH-1:0] ip2cafu_aximm1_ruser,
  output logic                ip2cafu_aximm1_rvalid,
   input                      cafu2ip_aximm1_rready,

   //CLST
 
   //Slice-0
  output logic             ip2cafu_axistd0_tvalid,
  output logic  [71:0]     ip2cafu_axistd0_tdata, 
  output logic  [8:0]      ip2cafu_axistd0_tstrb,
  output logic  [2:0]      ip2cafu_axistd0_tdest,
  output logic  [8:0]      ip2cafu_axistd0_tkeep,
  output logic             ip2cafu_axistd0_tlast,
  output logic  [7:0]      ip2cafu_axistd0_tid,
  output logic  [7:0]      ip2cafu_axistd0_tuser,  
  input  logic             cafu2ip_axistd0_tready, 
  output logic             ip2cafu_axisth0_tvalid,
  output logic  [71:0]     ip2cafu_axisth0_tdata, 
  output logic  [8:0]      ip2cafu_axisth0_tstrb,
  output logic  [2:0]      ip2cafu_axisth0_tdest,
  output logic  [8:0]      ip2cafu_axisth0_tkeep,
  output logic             ip2cafu_axisth0_tlast,
  output logic  [7:0]      ip2cafu_axisth0_tid,
  output logic  [7:0]      ip2cafu_axisth0_tuser,  
  input  logic             cafu2ip_axisth0_tready, 
  
   //Slice-1
  output logic             ip2cafu_axistd1_tvalid,
  output logic  [71:0]     ip2cafu_axistd1_tdata, 
  output logic  [8:0]      ip2cafu_axistd1_tstrb,
  output logic  [2:0]      ip2cafu_axistd1_tdest,
  output logic  [8:0]      ip2cafu_axistd1_tkeep,
  output logic             ip2cafu_axistd1_tlast,
  output logic  [7:0]      ip2cafu_axistd1_tid,
  output logic  [7:0]      ip2cafu_axistd1_tuser,  
  input  logic             cafu2ip_axistd1_tready, 
  output logic             ip2cafu_axisth1_tvalid,
  output logic  [71:0]     ip2cafu_axisth1_tdata, 
  output logic  [8:0]      ip2cafu_axisth1_tstrb,
  output logic  [2:0]      ip2cafu_axisth1_tdest,
  output logic  [8:0]      ip2cafu_axisth1_tkeep,
  output logic             ip2cafu_axisth1_tlast,
  output logic  [7:0]      ip2cafu_axisth1_tid,
  output logic  [7:0]      ip2cafu_axisth1_tuser,  
  input  logic             cafu2ip_axisth1_tready,  
  
  
 
   // External CSR <--> IP
  input  logic [95:0]         cafu2ip_csr0_cfg_if,
  output  logic [5:0]         ip2cafu_csr0_cfg_if,  
 
 
  
  //AFU inline CSR avmm access
  output logic                             ip2csr_avmm_clk,
  output logic                             ip2csr_avmm_rstn,  
  input  logic                             csr2ip_avmm_waitrequest,  
  input  logic [63:0]                      csr2ip_avmm_readdata,     
  input  logic                             csr2ip_avmm_readdatavalid,
  output logic [63:0]                      ip2csr_avmm_writedata,
  output logic                             ip2csr_avmm_poison,
  output logic [21:0]                      ip2csr_avmm_address,
  output logic                             ip2csr_avmm_write,
  output logic                             ip2csr_avmm_read, 
  output logic [7:0]                       ip2csr_avmm_byteenable,

    //CXL compliance csr avmm interface 
  output logic                               ip2cafu_avmm_clk,
  output logic                               ip2cafu_avmm_rstn,  
  input  logic                               cafu2ip_avmm_waitrequest,
  input  logic [63:0]                        cafu2ip_avmm_readdata,
  input  logic                               cafu2ip_avmm_readdatavalid,
  output logic [0:0]                         ip2cafu_avmm_burstcount,
  output logic [63:0]                        ip2cafu_avmm_writedata,
  output logic                               ip2cafu_avmm_poison,
  output logic [21:0]                        ip2cafu_avmm_address,
  output logic                               ip2cafu_avmm_write,
  output logic                               ip2cafu_avmm_read,
  output logic [7:0]                         ip2cafu_avmm_byteenable, 

    //TO EXT COMPLIANCE 
  output logic [31:0]                       ccv_afu_conf_base_addr_high,
  output logic                              ccv_afu_conf_base_addr_high_valid,
  output logic [27:0]                       ccv_afu_conf_base_addr_low,
  output logic                              ccv_afu_conf_base_addr_low_valid,
  output logic [2:0]                        pf0_max_payload_size,
  output logic [2:0]                        pf0_max_read_request_size,
  output logic                              pf0_bus_master_en,
  output logic                              pf0_memory_access_en,
  output logic [2:0]                        pf1_max_payload_size,
  output logic [2:0]                        pf1_max_read_request_size,
  output logic                              pf1_bus_master_en,
  output logic                              pf1_memory_access_en,
  //MSI-X user  interface    
  output logic                              pf0_msix_enable,
  output logic                              pf0_msix_fn_mask,
  output logic                              pf1_msix_enable,
  output logic                              pf1_msix_fn_mask,
    
  input logic [63:0]                        dev_serial_num, 
  input logic                               dev_serial_num_valid, 


  // IO - User AVST interface
  output  logic                            ip2uio_tx_ready,      
  input   logic                            uio2ip_tx_st0_dvalid,
  input   logic                            uio2ip_tx_st0_sop,
  input   logic                            uio2ip_tx_st0_eop,
  input   logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st0_data,
  input   logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st0_data_parity,
  input   logic [127:0]                    uio2ip_tx_st0_hdr,
  input   logic [3:0]                      uio2ip_tx_st0_hdr_parity,
  input   logic                            uio2ip_tx_st0_hvalid,
  input   logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st0_prefix,
  input   logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st0_prefix_parity,
  input   logic                            uio2ip_tx_st0_pvalid,
  input   logic [2:0]                      uio2ip_tx_st0_empty,  
  input   logic                            uio2ip_tx_st0_misc_parity,

  input   logic                            uio2ip_tx_st1_dvalid,
  input   logic                            uio2ip_tx_st1_sop,
  input   logic                            uio2ip_tx_st1_eop,
  input   logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st1_data,
  input   logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st1_data_parity,
  input   logic [127:0]                    uio2ip_tx_st1_hdr,
  input   logic [3:0]                      uio2ip_tx_st1_hdr_parity,
  input   logic                            uio2ip_tx_st1_hvalid,
  input   logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st1_prefix,
  input   logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st1_prefix_parity,
  input   logic                            uio2ip_tx_st1_pvalid,
  input   logic [2:0]                      uio2ip_tx_st1_empty, 
  input   logic                            uio2ip_tx_st1_misc_parity,

  input   logic                            uio2ip_tx_st2_dvalid,
  input   logic                            uio2ip_tx_st2_sop,
  input   logic                            uio2ip_tx_st2_eop,
  input   logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st2_data,
  input   logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st2_data_parity,
  input   logic [127:0]                    uio2ip_tx_st2_hdr,
  input   logic [3:0]                      uio2ip_tx_st2_hdr_parity,
  input   logic                            uio2ip_tx_st2_hvalid,
  input   logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st2_prefix,
  input   logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st2_prefix_parity,
  input   logic                            uio2ip_tx_st2_pvalid,
  input   logic [2:0]                      uio2ip_tx_st2_empty,  
  input   logic                            uio2ip_tx_st2_misc_parity,

  input   logic                            uio2ip_tx_st3_dvalid,
  input   logic                            uio2ip_tx_st3_sop,
  input   logic                            uio2ip_tx_st3_eop,
  input   logic [(CXL_IO_DWIDTH-1):0]      uio2ip_tx_st3_data,
  input   logic [((CXL_IO_DWIDTH/32)-1):0] uio2ip_tx_st3_data_parity,
  input   logic [127:0]                    uio2ip_tx_st3_hdr,
  input   logic [3:0]                      uio2ip_tx_st3_hdr_parity,
  input   logic                            uio2ip_tx_st3_hvalid,
  input   logic [(CXL_IO_PWIDTH-1):0]      uio2ip_tx_st3_prefix,
  input   logic [((CXL_IO_PWIDTH/32)-1):0] uio2ip_tx_st3_prefix_parity,
  input   logic                            uio2ip_tx_st3_pvalid,
  input   logic [2:0]                      uio2ip_tx_st3_empty,  
  input   logic                            uio2ip_tx_st3_misc_parity,

//IO tx credit interface 
  output  logic [2:0]                      ip2uio_tx_st_Hcrdt_update,
  output  logic [5:0]                      ip2uio_tx_st_Hcrdt_update_cnt,
  output  logic [2:0]                      ip2uio_tx_st_Hcrdt_init,
  input   logic [2:0]                      uio2ip_tx_st_Hcrdt_init_ack,
  output  logic [2:0]                      ip2uio_tx_st_Dcrdt_update,
  output  logic [11:0]                     ip2uio_tx_st_Dcrdt_update_cnt,
  output  logic [2:0]                      ip2uio_tx_st_Dcrdt_init ,
  input   logic [2:0]                      uio2ip_tx_st_Dcrdt_init_ack,
  
  output logic                             ip2uio_rx_st0_dvalid,
  output logic                             ip2uio_rx_st0_sop,
  output logic                             ip2uio_rx_st0_eop,
  output logic                             ip2uio_rx_st0_passthrough,
  output logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st0_data,
  output logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st0_data_parity,
  output logic  [127:0]                    ip2uio_rx_st0_hdr,
  output logic  [3:0]                      ip2uio_rx_st0_hdr_parity,
  output logic                             ip2uio_rx_st0_hvalid,
  output logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st0_prefix,
  output logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st0_prefix_parity,
  output logic                             ip2uio_rx_st0_pvalid,
  output logic  [2:0]                      ip2uio_rx_st0_bar,
  output logic  [2:0]                      ip2uio_rx_st0_pfnum,
  output logic                             ip2uio_rx_st0_misc_parity,
  output logic  [2:0]                      ip2uio_rx_st0_empty,  

  output logic                             ip2uio_rx_st1_dvalid,
  output logic                             ip2uio_rx_st1_sop,
  output logic                             ip2uio_rx_st1_eop,
  output logic                             ip2uio_rx_st1_passthrough,
  output logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st1_data,
  output logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st1_data_parity,
  output logic  [127:0]                    ip2uio_rx_st1_hdr,
  output logic  [3:0]                      ip2uio_rx_st1_hdr_parity,
  output logic                             ip2uio_rx_st1_hvalid,
  output logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st1_prefix,
  output logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st1_prefix_parity,
  output logic                             ip2uio_rx_st1_pvalid,
  output logic  [2:0]                      ip2uio_rx_st1_bar,
  output logic  [2:0]                      ip2uio_rx_st1_pfnum,
  output logic                             ip2uio_rx_st1_misc_parity,
  output logic  [2:0]                      ip2uio_rx_st1_empty,  
  
  output logic                             ip2uio_rx_st2_dvalid,
  output logic                             ip2uio_rx_st2_sop,
  output logic                             ip2uio_rx_st2_eop,
  output logic                             ip2uio_rx_st2_passthrough,
  output logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st2_data,
  output logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st2_data_parity,
  output logic  [127:0]                    ip2uio_rx_st2_hdr,
  output logic  [3:0]                      ip2uio_rx_st2_hdr_parity,
  output logic                             ip2uio_rx_st2_hvalid,
  output logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st2_prefix,
  output logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st2_prefix_parity,
  output logic                             ip2uio_rx_st2_pvalid,
  output logic  [2:0]                      ip2uio_rx_st2_bar,
  output logic  [2:0]                      ip2uio_rx_st2_pfnum,
  output logic                             ip2uio_rx_st2_misc_parity,
  output logic  [2:0]                      ip2uio_rx_st2_empty,  

  output logic                             ip2uio_rx_st3_dvalid,
  output logic                             ip2uio_rx_st3_sop,
  output logic                             ip2uio_rx_st3_eop,
  output logic                             ip2uio_rx_st3_passthrough,
  output logic  [(CXL_IO_DWIDTH-1):0]      ip2uio_rx_st3_data,
  output logic  [((CXL_IO_DWIDTH/32)-1):0] ip2uio_rx_st3_data_parity,
  output logic  [127:0]                    ip2uio_rx_st3_hdr,
  output logic  [3:0]                      ip2uio_rx_st3_hdr_parity,
  output logic                             ip2uio_rx_st3_hvalid,
  output logic  [(CXL_IO_PWIDTH-1):0]      ip2uio_rx_st3_prefix,
  output logic  [((CXL_IO_PWIDTH/32)-1):0] ip2uio_rx_st3_prefix_parity,
  output logic                             ip2uio_rx_st3_pvalid,
  output logic  [2:0]                      ip2uio_rx_st3_bar,
  output logic  [2:0]                      ip2uio_rx_st3_pfnum,
  output logic                             ip2uio_rx_st3_misc_parity,
  output logic  [2:0]                      ip2uio_rx_st3_empty,  
  
  input  logic [2:0]                       uio2ip_rx_st_Hcrdt_update,
  input  logic [5:0]                       uio2ip_rx_st_Hcrdt_update_cnt,
  input  logic [2:0]                       uio2ip_rx_st_Hcrdt_init,
  output logic [2:0]                       ip2uio_rx_st_Hcrdt_init_ack,
  input  logic [2:0]                       uio2ip_rx_st_Dcrdt_update,
  input  logic [11:0]                      uio2ip_rx_st_Dcrdt_update_cnt,
  input  logic [2:0]                       uio2ip_rx_st_Dcrdt_init,
  output logic [2:0]                       ip2uio_rx_st_Dcrdt_init_ack,
  //From User : Error Interface
  input   logic                            usr2ip_app_err_valid,   
  input   logic [31:0]                     usr2ip_app_err_hdr,  
  input   logic [13:0]                     usr2ip_app_err_info,
  input   logic [2:0]                      usr2ip_app_err_func_num,
  output  logic                            ip2usr_app_err_ready,
   // output  logic                        ip2usr_err_valid,
   // output  logic [127:0]                ip2usr_err_hdr,
   // output  logic [31:0]                 ip2usr_err_tlp_prefix,
   // output  logic [13:0]                 ip2usr_err_info,
    //FROM IP to USER
    output  logic                        ip2usr_aermsg_correctable_valid ,
    output  logic                        ip2usr_aermsg_uncorrectable_valid,
    output  logic                        ip2usr_aermsg_res ,  
    output  logic                        ip2usr_aermsg_bts ,  
    output  logic                        ip2usr_aermsg_bds ,  
    output  logic                        ip2usr_aermsg_rrs ,  
    output  logic                        ip2usr_aermsg_rtts,  
    output  logic                        ip2usr_aermsg_anes,  
    output  logic                        ip2usr_aermsg_cies,  
    output  logic                        ip2usr_aermsg_hlos,  
    output  logic [1:0]                  ip2usr_aermsg_fmt ,  
    output  logic [4:0]                  ip2usr_aermsg_type,  
    output  logic [2:0]                  ip2usr_aermsg_tc  ,  
    output  logic                        ip2usr_aermsg_ido ,  
    output  logic                        ip2usr_aermsg_th  ,  
    output  logic                        ip2usr_aermsg_td  ,  
    output  logic                        ip2usr_aermsg_ep  ,  
    output  logic                        ip2usr_aermsg_ro  ,  
    output  logic                        ip2usr_aermsg_ns  ,  
    output  logic [1:0]                  ip2usr_aermsg_at  ,  
    output  logic [9:0]                  ip2usr_aermsg_length,
    output  logic [95:0]                 ip2usr_aermsg_header,
    output  logic                        ip2usr_aermsg_und,   
    output  logic                        ip2usr_aermsg_anf,   
    output  logic                        ip2usr_aermsg_dlpes, 
    output  logic                        ip2usr_aermsg_sdes,  
    output  logic [4:0]                  ip2usr_aermsg_fep,   
    output  logic                        ip2usr_aermsg_pts,   
    output  logic                        ip2usr_aermsg_fcpes, 
    output  logic                        ip2usr_aermsg_cts ,  
    output  logic                        ip2usr_aermsg_cas ,  
    output  logic                        ip2usr_aermsg_ucs ,  
    output  logic                        ip2usr_aermsg_ros ,  
    output  logic                        ip2usr_aermsg_mts ,  
    output  logic                        ip2usr_aermsg_uies,  
    output  logic                        ip2usr_aermsg_mbts,  
    output  logic                        ip2usr_aermsg_aebs,  
    output  logic                        ip2usr_aermsg_tpbes, 
    output  logic                        ip2usr_aermsg_ees,   
    output  logic                        ip2usr_aermsg_ures,  
    output  logic                        ip2usr_aermsg_avs , 
  output  logic                            ip2usr_serr_out,
  //Debug access
  output  logic                            ip2usr_debug_waitrequest,   
  output  logic [31:0]                     ip2usr_debug_readdata,
  output  logic                            ip2usr_debug_readdatavalid,   
  input   logic [31:0]                     usr2ip_debug_writedata,   
  input   logic [31:0]                     usr2ip_debug_address,   
  input   logic                            usr2ip_debug_write,   
  input   logic                            usr2ip_debug_read,   
  input   logic [3:0]                      usr2ip_debug_byteenable,   

  output logic [7:0]                       ip2uio_bus_number,                            
  output logic [4:0]                       ip2uio_device_number

);

   //localparam CXL_MEM_DEV_REGBLOCK_EN      = 1'h1;
   //localparam CXL_MEM_DEV_REGBLOCK_OFFSET  = 32'h0018_0000;
//cxl_ip_top #(
  cxl_type2_cxlip_top #(
    .CXL2P0_COMPLIANCE  (CXL2P0_COMPLIANCE),
	.ADME_ENABLE            (ADME_ENABLE), 
	.T1IP_ENABLE            (T1IP_ENABLE),
    .CXL_SCC_EN             (CXL_SCC_EN),
    .PTMCAP_EN              (PTMCAP_EN                   ),      
    .PF1_BAR01_SIZE         (PF1_BAR01_SIZE              ), 
    .PTM_AUTO_UPDATE        (PTM_AUTO_UPDATE             ), 
    .PTMRCSR_RFSHTIME       (PTMRCSR_RFSHTIME            ), 
	.DEVCAP_MPSS            (DEVCAP_MPSS),     
	.NUM_DCOH_SLICES_ENC_VAL(NUM_DCOH_SLICES_ENC_VAL),
	.CXL_FREQ_ENC_VAL       (CXL_FREQ_ENC_VAL),
	.CXL_TYPE_ENC_VAL       (CXL_TYPE_ENC_VAL),
	.CXLIPUNIQID            (CXLIPUNIQID),
	.PF0_CCRID_RID          (PF0_CCRID_RID),
	.PF0_CCRID_PI           (PF0_CCRID_PI),
	.PF0_CCRID_SUBCC        (PF0_CCRID_SUBCC),
	.PF0_CCRID_BCC          (PF0_CCRID_BCC),
	.PF0_DEVICE_ID          (PF0_DEVICE_ID),
	.PF0_SID                (PF0_SID),
	.PF0_SVID               (PF0_SVID),
	.PF0_VID                (PF0_VID),
	.PF1_CCRID_RID          (PF1_CCRID_RID),
	.PF1_CCRID_PI           (PF1_CCRID_PI),
	.PF1_CCRID_SUBCC        (PF1_CCRID_SUBCC),
	.PF1_CCRID_BCC          (PF1_CCRID_BCC),
	.PF1_DEVICE_ID          (PF1_DEVICE_ID),
	.PF1_SID                (PF1_SID),
	.PF1_SVID               (PF1_SVID),
	.PF1_VID                (PF1_VID),
	.HDMDECHDR_EN           (HDMDECHDR_EN),
        .HDMDECHDR_CAPVER       (HDMDECHDR_CAPVER),
	.DEVICE_PORT_TYPE       (DEVICE_PORT_TYPE),
        .CXL_MEM_DEV_REGBLOCK_EN      (CXL_MEM_DEV_REGBLOCK_EN),
        .CXL_MEM_DEV_REGBLOCK_OFFSET  (CXL_MEM_DEV_REGBLOCK_OFFSET),
	.PF0_MSIX_CAP_EN        (PF0_MSIX_CAP_EN),
	.PF0_MSIX_TABLE_SIZE    (PF0_MSIX_TABLE_SIZE),
	.PF0_MSIX_TABLE_MAO     (PF0_MSIX_TABLE_MAO),
	.PF0_MSIX_TABLE_BIR     (PF0_MSIX_TABLE_BIR),
	.PF0_MSIX_PBA_MAO       (PF0_MSIX_PBA_MAO),
	.PF0_MSIX_PBA_BIR       (PF0_MSIX_PBA_BIR),
	.PF1_MSIX_CAP_EN        (PF1_MSIX_CAP_EN),
	.PF1_MSIX_TABLE_SIZE    (PF1_MSIX_TABLE_SIZE),
	.PF1_MSIX_TABLE_MAO     (PF1_MSIX_TABLE_MAO),
	.PF1_MSIX_TABLE_BIR     (PF1_MSIX_TABLE_BIR),
	.PF1_MSIX_PBA_MAO       (PF1_MSIX_PBA_MAO),
	.PF1_MSIX_PBA_BIR       (PF1_MSIX_PBA_BIR) 
  )
 inst_cxl_type2_top (
    .refclk0                               (refclk0),     // To R-Tile
    .refclk1                               (refclk1),     // To R-Tile
    .refclk4                               (refclk4),     // To Fabric PLL
    
    .resetn                                (resetn),
    .nInit_done                            (nInit_done),
    .cxl_warm_rst_n                        (cxl_warm_rst_n),// OUTPUT  
    .cxl_cold_rst_n                        (cxl_cold_rst_n),// OUTPUT
    .pll_lock_o                            (pll_lock_o),    // PLL Lock output
    .cxl_tx_n                              (cxl_tx_n),      // To R-tile
    .cxl_tx_p                              (cxl_tx_p),      // To R-tile
    .cxl_rx_n                              (cxl_rx_n),      // To R-tile
    .cxl_rx_p                              (cxl_rx_p),      // To R-tile


     .phy_sys_ial_0__pipe_Reset_l                       (phy_sys_ial_0__pipe_Reset_l),                                          //  output,    width = 1,          phy_sys_ial_.0__pipe_Reset_l
     .phy_sys_ial_1__pipe_Reset_l                       (phy_sys_ial_1__pipe_Reset_l),                                          //  output,    width = 1,                      .1__pipe_Reset_l
     .phy_sys_ial_2__pipe_Reset_l                       (phy_sys_ial_2__pipe_Reset_l),                                          //  output,    width = 1,                      .2__pipe_Reset_l
     .phy_sys_ial_3__pipe_Reset_l                       (phy_sys_ial_3__pipe_Reset_l),                                          //  output,    width = 1,                      .3__pipe_Reset_l
     .phy_sys_ial_4__pipe_Reset_l                       (phy_sys_ial_4__pipe_Reset_l),                                          //  output,    width = 1,                      .4__pipe_Reset_l
     .phy_sys_ial_5__pipe_Reset_l                       (phy_sys_ial_5__pipe_Reset_l),                                          //  output,    width = 1,                      .5__pipe_Reset_l
     .phy_sys_ial_6__pipe_Reset_l                       (phy_sys_ial_6__pipe_Reset_l),                                          //  output,    width = 1,                      .6__pipe_Reset_l
     .phy_sys_ial_7__pipe_Reset_l                       (phy_sys_ial_7__pipe_Reset_l),                                          //  output,    width = 1,                      .7__pipe_Reset_l
     .phy_sys_ial_8__pipe_Reset_l                       (phy_sys_ial_8__pipe_Reset_l),                                          //  output,    width = 1,                      .8__pipe_Reset_l
     .phy_sys_ial_9__pipe_Reset_l                       (phy_sys_ial_9__pipe_Reset_l),                                          //  output,    width = 1,                      .9__pipe_Reset_l
     .phy_sys_ial_10__pipe_Reset_l                      (phy_sys_ial_10__pipe_Reset_l),                                         //  output,    width = 1,                      .10__pipe_Reset_l
     .phy_sys_ial_11__pipe_Reset_l                      (phy_sys_ial_11__pipe_Reset_l),                                         //  output,    width = 1,                      .11__pipe_Reset_l
     .phy_sys_ial_12__pipe_Reset_l                      (phy_sys_ial_12__pipe_Reset_l),                                         //  output,    width = 1,                      .12__pipe_Reset_l
     .phy_sys_ial_13__pipe_Reset_l                      (phy_sys_ial_13__pipe_Reset_l),                                         //  output,    width = 1,                      .13__pipe_Reset_l
     .phy_sys_ial_14__pipe_Reset_l                      (phy_sys_ial_14__pipe_Reset_l),                                         //  output,    width = 1,                      .14__pipe_Reset_l
     .phy_sys_ial_15__pipe_Reset_l                      (phy_sys_ial_15__pipe_Reset_l),                                         //  output,    width = 1,                      .15__pipe_Reset_l
     .o_phy_0_pipe_TxDataValid                          (o_phy_0_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_0_pipe_.TxDataValid
     .o_phy_0_pipe_TxData                               (o_phy_0_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_0_pipe_TxDetRxLpbk                          (o_phy_0_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_0_pipe_TxElecIdle                           (o_phy_0_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_0_pipe_PowerDown                            (o_phy_0_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_0_pipe_Rate                                 (o_phy_0_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_0_pipe_PclkChangeAck                        (o_phy_0_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_0_pipe_PCLKRate                             (o_phy_0_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_0_pipe_Width                                (o_phy_0_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_0_pipe_PCLK                                 (o_phy_0_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_0_pipe_rxelecidle_disable                   (o_phy_0_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_0_pipe_txcmnmode_disable                    (o_phy_0_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_0_pipe_srisenable                           (o_phy_0_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_0_pipe_RxStandby                            (o_phy_0_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_0_pipe_RxTermination                        (o_phy_0_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_0_pipe_RxWidth                              (o_phy_0_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_0_pipe_M2P_MessageBus                       (o_phy_0_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_0_pipe_rxbitslip_req                        (o_phy_0_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_0_pipe_rxbitslip_va                         (o_phy_0_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_0_pipe_RxClk                                (i_phy_0_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_0_pipe_.RxClk
     .i_phy_0_pipe_RxValid                              (i_phy_0_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_0_pipe_RxData                               (i_phy_0_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_0_pipe_RxElecIdle                           (i_phy_0_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_0_pipe_RxStatus                             (i_phy_0_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_0_pipe_RxStandbyStatus                      (i_phy_0_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_0_pipe_PhyStatus                            (i_phy_0_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_0_pipe_PclkChangeOk                         (i_phy_0_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_0_pipe_P2M_MessageBus                       (i_phy_0_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_0_pipe_RxBitSlip_Ack                        (i_phy_0_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_1_pipe_TxDataValid                          (o_phy_1_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_1_pipe_.TxDataValid
     .o_phy_1_pipe_TxData                               (o_phy_1_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_1_pipe_TxDetRxLpbk                          (o_phy_1_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_1_pipe_TxElecIdle                           (o_phy_1_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_1_pipe_PowerDown                            (o_phy_1_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_1_pipe_Rate                                 (o_phy_1_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_1_pipe_PclkChangeAck                        (o_phy_1_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_1_pipe_PCLKRate                             (o_phy_1_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_1_pipe_Width                                (o_phy_1_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_1_pipe_PCLK                                 (o_phy_1_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_1_pipe_rxelecidle_disable                   (o_phy_1_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_1_pipe_txcmnmode_disable                    (o_phy_1_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_1_pipe_srisenable                           (o_phy_1_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_1_pipe_RxStandby                            (o_phy_1_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_1_pipe_RxTermination                        (o_phy_1_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_1_pipe_RxWidth                              (o_phy_1_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_1_pipe_M2P_MessageBus                       (o_phy_1_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_1_pipe_rxbitslip_req                        (o_phy_1_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_1_pipe_rxbitslip_va                         (o_phy_1_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_1_pipe_RxClk                                (i_phy_1_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_1_pipe_.RxClk
     .i_phy_1_pipe_RxValid                              (i_phy_1_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_1_pipe_RxData                               (i_phy_1_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_1_pipe_RxElecIdle                           (i_phy_1_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_1_pipe_RxStatus                             (i_phy_1_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_1_pipe_RxStandbyStatus                      (i_phy_1_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_1_pipe_PhyStatus                            (i_phy_1_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_1_pipe_PclkChangeOk                         (i_phy_1_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_1_pipe_P2M_MessageBus                       (i_phy_1_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_1_pipe_RxBitSlip_Ack                        (i_phy_1_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_2_pipe_TxDataValid                          (o_phy_2_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_2_pipe_.TxDataValid
     .o_phy_2_pipe_TxData                               (o_phy_2_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_2_pipe_TxDetRxLpbk                          (o_phy_2_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_2_pipe_TxElecIdle                           (o_phy_2_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_2_pipe_PowerDown                            (o_phy_2_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_2_pipe_Rate                                 (o_phy_2_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_2_pipe_PclkChangeAck                        (o_phy_2_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_2_pipe_PCLKRate                             (o_phy_2_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_2_pipe_Width                                (o_phy_2_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_2_pipe_PCLK                                 (o_phy_2_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_2_pipe_rxelecidle_disable                   (o_phy_2_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_2_pipe_txcmnmode_disable                    (o_phy_2_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_2_pipe_srisenable                           (o_phy_2_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_2_pipe_RxStandby                            (o_phy_2_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_2_pipe_RxTermination                        (o_phy_2_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_2_pipe_RxWidth                              (o_phy_2_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_2_pipe_M2P_MessageBus                       (o_phy_2_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_2_pipe_rxbitslip_req                        (o_phy_2_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_2_pipe_rxbitslip_va                         (o_phy_2_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_2_pipe_RxClk                                (i_phy_2_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_2_pipe_.RxClk
     .i_phy_2_pipe_RxValid                              (i_phy_2_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_2_pipe_RxData                               (i_phy_2_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_2_pipe_RxElecIdle                           (i_phy_2_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_2_pipe_RxStatus                             (i_phy_2_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_2_pipe_RxStandbyStatus                      (i_phy_2_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_2_pipe_PhyStatus                            (i_phy_2_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_2_pipe_PclkChangeOk                         (i_phy_2_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_2_pipe_P2M_MessageBus                       (i_phy_2_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_2_pipe_RxBitSlip_Ack                        (i_phy_2_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_3_pipe_TxDataValid                          (o_phy_3_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_3_pipe_.TxDataValid
     .o_phy_3_pipe_TxData                               (o_phy_3_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_3_pipe_TxDetRxLpbk                          (o_phy_3_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_3_pipe_TxElecIdle                           (o_phy_3_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_3_pipe_PowerDown                            (o_phy_3_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_3_pipe_Rate                                 (o_phy_3_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_3_pipe_PclkChangeAck                        (o_phy_3_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_3_pipe_PCLKRate                             (o_phy_3_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_3_pipe_Width                                (o_phy_3_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_3_pipe_PCLK                                 (o_phy_3_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_3_pipe_rxelecidle_disable                   (o_phy_3_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_3_pipe_txcmnmode_disable                    (o_phy_3_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_3_pipe_srisenable                           (o_phy_3_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_3_pipe_RxStandby                            (o_phy_3_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_3_pipe_RxTermination                        (o_phy_3_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_3_pipe_RxWidth                              (o_phy_3_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_3_pipe_M2P_MessageBus                       (o_phy_3_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_3_pipe_rxbitslip_req                        (o_phy_3_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_3_pipe_rxbitslip_va                         (o_phy_3_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_3_pipe_RxClk                                (i_phy_3_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_3_pipe_.RxClk
     .i_phy_3_pipe_RxValid                              (i_phy_3_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_3_pipe_RxData                               (i_phy_3_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_3_pipe_RxElecIdle                           (i_phy_3_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_3_pipe_RxStatus                             (i_phy_3_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_3_pipe_RxStandbyStatus                      (i_phy_3_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_3_pipe_PhyStatus                            (i_phy_3_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_3_pipe_PclkChangeOk                         (i_phy_3_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_3_pipe_P2M_MessageBus                       (i_phy_3_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_3_pipe_RxBitSlip_Ack                        (i_phy_3_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_4_pipe_TxDataValid                          (o_phy_4_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_4_pipe_.TxDataValid
     .o_phy_4_pipe_TxData                               (o_phy_4_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_4_pipe_TxDetRxLpbk                          (o_phy_4_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_4_pipe_TxElecIdle                           (o_phy_4_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_4_pipe_PowerDown                            (o_phy_4_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_4_pipe_Rate                                 (o_phy_4_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_4_pipe_PclkChangeAck                        (o_phy_4_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_4_pipe_PCLKRate                             (o_phy_4_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_4_pipe_Width                                (o_phy_4_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_4_pipe_PCLK                                 (o_phy_4_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_4_pipe_rxelecidle_disable                   (o_phy_4_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_4_pipe_txcmnmode_disable                    (o_phy_4_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_4_pipe_srisenable                           (o_phy_4_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_4_pipe_RxStandby                            (o_phy_4_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_4_pipe_RxTermination                        (o_phy_4_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_4_pipe_RxWidth                              (o_phy_4_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_4_pipe_M2P_MessageBus                       (o_phy_4_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_4_pipe_rxbitslip_req                        (o_phy_4_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_4_pipe_rxbitslip_va                         (o_phy_4_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_4_pipe_RxClk                                (i_phy_4_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_4_pipe_.RxClk
     .i_phy_4_pipe_RxValid                              (i_phy_4_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_4_pipe_RxData                               (i_phy_4_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_4_pipe_RxElecIdle                           (i_phy_4_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_4_pipe_RxStatus                             (i_phy_4_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_4_pipe_RxStandbyStatus                      (i_phy_4_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_4_pipe_PhyStatus                            (i_phy_4_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_4_pipe_PclkChangeOk                         (i_phy_4_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_4_pipe_P2M_MessageBus                       (i_phy_4_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_4_pipe_RxBitSlip_Ack                        (i_phy_4_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_5_pipe_TxDataValid                          (o_phy_5_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_5_pipe_.TxDataValid
     .o_phy_5_pipe_TxData                               (o_phy_5_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_5_pipe_TxDetRxLpbk                          (o_phy_5_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_5_pipe_TxElecIdle                           (o_phy_5_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_5_pipe_PowerDown                            (o_phy_5_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_5_pipe_Rate                                 (o_phy_5_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_5_pipe_PclkChangeAck                        (o_phy_5_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_5_pipe_PCLKRate                             (o_phy_5_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_5_pipe_Width                                (o_phy_5_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_5_pipe_PCLK                                 (o_phy_5_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_5_pipe_rxelecidle_disable                   (o_phy_5_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_5_pipe_txcmnmode_disable                    (o_phy_5_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_5_pipe_srisenable                           (o_phy_5_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_5_pipe_RxStandby                            (o_phy_5_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_5_pipe_RxTermination                        (o_phy_5_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_5_pipe_RxWidth                              (o_phy_5_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_5_pipe_M2P_MessageBus                       (o_phy_5_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_5_pipe_rxbitslip_req                        (o_phy_5_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_5_pipe_rxbitslip_va                         (o_phy_5_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_5_pipe_RxClk                                (i_phy_5_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_5_pipe_.RxClk
     .i_phy_5_pipe_RxValid                              (i_phy_5_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_5_pipe_RxData                               (i_phy_5_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_5_pipe_RxElecIdle                           (i_phy_5_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_5_pipe_RxStatus                             (i_phy_5_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_5_pipe_RxStandbyStatus                      (i_phy_5_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_5_pipe_PhyStatus                            (i_phy_5_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_5_pipe_PclkChangeOk                         (i_phy_5_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_5_pipe_P2M_MessageBus                       (i_phy_5_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_5_pipe_RxBitSlip_Ack                        (i_phy_5_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_6_pipe_TxDataValid                          (o_phy_6_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_6_pipe_.TxDataValid
     .o_phy_6_pipe_TxData                               (o_phy_6_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_6_pipe_TxDetRxLpbk                          (o_phy_6_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_6_pipe_TxElecIdle                           (o_phy_6_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_6_pipe_PowerDown                            (o_phy_6_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_6_pipe_Rate                                 (o_phy_6_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_6_pipe_PclkChangeAck                        (o_phy_6_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_6_pipe_PCLKRate                             (o_phy_6_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_6_pipe_Width                                (o_phy_6_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_6_pipe_PCLK                                 (o_phy_6_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_6_pipe_rxelecidle_disable                   (o_phy_6_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_6_pipe_txcmnmode_disable                    (o_phy_6_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_6_pipe_srisenable                           (o_phy_6_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_6_pipe_RxStandby                            (o_phy_6_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_6_pipe_RxTermination                        (o_phy_6_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_6_pipe_RxWidth                              (o_phy_6_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_6_pipe_M2P_MessageBus                       (o_phy_6_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_6_pipe_rxbitslip_req                        (o_phy_6_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_6_pipe_rxbitslip_va                         (o_phy_6_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_6_pipe_RxClk                                (i_phy_6_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_6_pipe_.RxClk
     .i_phy_6_pipe_RxValid                              (i_phy_6_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_6_pipe_RxData                               (i_phy_6_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_6_pipe_RxElecIdle                           (i_phy_6_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_6_pipe_RxStatus                             (i_phy_6_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_6_pipe_RxStandbyStatus                      (i_phy_6_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_6_pipe_PhyStatus                            (i_phy_6_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_6_pipe_PclkChangeOk                         (i_phy_6_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_6_pipe_P2M_MessageBus                       (i_phy_6_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_6_pipe_RxBitSlip_Ack                        (i_phy_6_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_7_pipe_TxDataValid                          (o_phy_7_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_7_pipe_.TxDataValid
     .o_phy_7_pipe_TxData                               (o_phy_7_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_7_pipe_TxDetRxLpbk                          (o_phy_7_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_7_pipe_TxElecIdle                           (o_phy_7_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_7_pipe_PowerDown                            (o_phy_7_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_7_pipe_Rate                                 (o_phy_7_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_7_pipe_PclkChangeAck                        (o_phy_7_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_7_pipe_PCLKRate                             (o_phy_7_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_7_pipe_Width                                (o_phy_7_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_7_pipe_PCLK                                 (o_phy_7_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_7_pipe_rxelecidle_disable                   (o_phy_7_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_7_pipe_txcmnmode_disable                    (o_phy_7_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_7_pipe_srisenable                           (o_phy_7_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_7_pipe_RxStandby                            (o_phy_7_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_7_pipe_RxTermination                        (o_phy_7_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_7_pipe_RxWidth                              (o_phy_7_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_7_pipe_M2P_MessageBus                       (o_phy_7_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_7_pipe_rxbitslip_req                        (o_phy_7_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_7_pipe_rxbitslip_va                         (o_phy_7_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_7_pipe_RxClk                                (i_phy_7_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_7_pipe_.RxClk
     .i_phy_7_pipe_RxValid                              (i_phy_7_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_7_pipe_RxData                               (i_phy_7_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_7_pipe_RxElecIdle                           (i_phy_7_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_7_pipe_RxStatus                             (i_phy_7_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_7_pipe_RxStandbyStatus                      (i_phy_7_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_7_pipe_PhyStatus                            (i_phy_7_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_7_pipe_PclkChangeOk                         (i_phy_7_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_7_pipe_P2M_MessageBus                       (i_phy_7_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_7_pipe_RxBitSlip_Ack                        (i_phy_7_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_8_pipe_TxDataValid                          (o_phy_8_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_8_pipe_.TxDataValid
     .o_phy_8_pipe_TxData                               (o_phy_8_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_8_pipe_TxDetRxLpbk                          (o_phy_8_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_8_pipe_TxElecIdle                           (o_phy_8_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_8_pipe_PowerDown                            (o_phy_8_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_8_pipe_Rate                                 (o_phy_8_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_8_pipe_PclkChangeAck                        (o_phy_8_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_8_pipe_PCLKRate                             (o_phy_8_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_8_pipe_Width                                (o_phy_8_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_8_pipe_PCLK                                 (o_phy_8_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_8_pipe_rxelecidle_disable                   (o_phy_8_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_8_pipe_txcmnmode_disable                    (o_phy_8_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_8_pipe_srisenable                           (o_phy_8_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_8_pipe_RxStandby                            (o_phy_8_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_8_pipe_RxTermination                        (o_phy_8_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_8_pipe_RxWidth                              (o_phy_8_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_8_pipe_M2P_MessageBus                       (o_phy_8_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_8_pipe_rxbitslip_req                        (o_phy_8_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_8_pipe_rxbitslip_va                         (o_phy_8_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_8_pipe_RxClk                                (i_phy_8_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_8_pipe_.RxClk
     .i_phy_8_pipe_RxValid                              (i_phy_8_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_8_pipe_RxData                               (i_phy_8_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_8_pipe_RxElecIdle                           (i_phy_8_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_8_pipe_RxStatus                             (i_phy_8_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_8_pipe_RxStandbyStatus                      (i_phy_8_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_8_pipe_PhyStatus                            (i_phy_8_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_8_pipe_PclkChangeOk                         (i_phy_8_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_8_pipe_P2M_MessageBus                       (i_phy_8_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_8_pipe_RxBitSlip_Ack                        (i_phy_8_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_9_pipe_TxDataValid                          (o_phy_9_pipe_TxDataValid),                                             //  output,    width = 1,         o_phy_9_pipe_.TxDataValid
     .o_phy_9_pipe_TxData                               (o_phy_9_pipe_TxData),                                                  //  output,   width = 40,                      .TxData
     .o_phy_9_pipe_TxDetRxLpbk                          (o_phy_9_pipe_TxDetRxLpbk),                                             //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_9_pipe_TxElecIdle                           (o_phy_9_pipe_TxElecIdle),                                              //  output,    width = 4,                      .TxElecIdle
     .o_phy_9_pipe_PowerDown                            (o_phy_9_pipe_PowerDown),                                               //  output,    width = 4,                      .PowerDown
     .o_phy_9_pipe_Rate                                 (o_phy_9_pipe_Rate),                                                    //  output,    width = 3,                      .Rate
     .o_phy_9_pipe_PclkChangeAck                        (o_phy_9_pipe_PclkChangeAck),                                           //  output,    width = 1,                      .PclkChangeAck
     .o_phy_9_pipe_PCLKRate                             (o_phy_9_pipe_PCLKRate),                                                //  output,    width = 3,                      .PCLKRate
     .o_phy_9_pipe_Width                                (o_phy_9_pipe_Width),                                                   //  output,    width = 2,                      .Width
     .o_phy_9_pipe_PCLK                                 (o_phy_9_pipe_PCLK),                                                    //  output,    width = 1,                      .PCLK
     .o_phy_9_pipe_rxelecidle_disable                   (o_phy_9_pipe_rxelecidle_disable),                                      //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_9_pipe_txcmnmode_disable                    (o_phy_9_pipe_txcmnmode_disable),                                       //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_9_pipe_srisenable                           (o_phy_9_pipe_srisenable),                                              //  output,    width = 1,                      .srisenable
     .o_phy_9_pipe_RxStandby                            (o_phy_9_pipe_RxStandby),                                               //  output,    width = 1,                      .RxStandby
     .o_phy_9_pipe_RxTermination                        (o_phy_9_pipe_RxTermination),                                           //  output,    width = 1,                      .RxTermination
     .o_phy_9_pipe_RxWidth                              (o_phy_9_pipe_RxWidth),                                                 //  output,    width = 2,                      .RxWidth
     .o_phy_9_pipe_M2P_MessageBus                       (o_phy_9_pipe_M2P_MessageBus),                                          //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_9_pipe_rxbitslip_req                        (o_phy_9_pipe_rxbitslip_req),                                           //  output,    width = 1,                      .rxbitslip_req
     .o_phy_9_pipe_rxbitslip_va                         (o_phy_9_pipe_rxbitslip_va),                                            //  output,    width = 5,                      .rxbitslip_va
     .i_phy_9_pipe_RxClk                                (i_phy_9_pipe_RxClk),                                                   //   input,    width = 1,         i_phy_9_pipe_.RxClk
     .i_phy_9_pipe_RxValid                              (i_phy_9_pipe_RxValid),                                                 //   input,    width = 1,                      .RxValid
     .i_phy_9_pipe_RxData                               (i_phy_9_pipe_RxData),                                                  //   input,   width = 40,                      .RxData
     .i_phy_9_pipe_RxElecIdle                           (i_phy_9_pipe_RxElecIdle),                                              //   input,    width = 1,                      .RxElecIdle
     .i_phy_9_pipe_RxStatus                             (i_phy_9_pipe_RxStatus),                                                //   input,    width = 3,                      .RxStatus
     .i_phy_9_pipe_RxStandbyStatus                      (i_phy_9_pipe_RxStandbyStatus),                                         //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_9_pipe_PhyStatus                            (i_phy_9_pipe_PhyStatus),                                               //   input,    width = 1,                      .PhyStatus
     .i_phy_9_pipe_PclkChangeOk                         (i_phy_9_pipe_PclkChangeOk),                                            //   input,    width = 1,                      .PclkChangeOk
     .i_phy_9_pipe_P2M_MessageBus                       (i_phy_9_pipe_P2M_MessageBus),                                          //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_9_pipe_RxBitSlip_Ack                        (i_phy_9_pipe_RxBitSlip_Ack),                                           //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_10_pipe_TxDataValid                         (o_phy_10_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_10_pipe_.TxDataValid
     .o_phy_10_pipe_TxData                              (o_phy_10_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_10_pipe_TxDetRxLpbk                         (o_phy_10_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_10_pipe_TxElecIdle                          (o_phy_10_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_10_pipe_PowerDown                           (o_phy_10_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_10_pipe_Rate                                (o_phy_10_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_10_pipe_PclkChangeAck                       (o_phy_10_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_10_pipe_PCLKRate                            (o_phy_10_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_10_pipe_Width                               (o_phy_10_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_10_pipe_PCLK                                (o_phy_10_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_10_pipe_rxelecidle_disable                  (o_phy_10_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_10_pipe_txcmnmode_disable                   (o_phy_10_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_10_pipe_srisenable                          (o_phy_10_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_10_pipe_RxStandby                           (o_phy_10_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_10_pipe_RxTermination                       (o_phy_10_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_10_pipe_RxWidth                             (o_phy_10_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_10_pipe_M2P_MessageBus                      (o_phy_10_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_10_pipe_rxbitslip_req                       (o_phy_10_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_10_pipe_rxbitslip_va                        (o_phy_10_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_10_pipe_RxClk                               (i_phy_10_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_10_pipe_.RxClk
     .i_phy_10_pipe_RxValid                             (i_phy_10_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_10_pipe_RxData                              (i_phy_10_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_10_pipe_RxElecIdle                          (i_phy_10_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_10_pipe_RxStatus                            (i_phy_10_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_10_pipe_RxStandbyStatus                     (i_phy_10_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_10_pipe_PhyStatus                           (i_phy_10_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_10_pipe_PclkChangeOk                        (i_phy_10_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_10_pipe_P2M_MessageBus                      (i_phy_10_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_10_pipe_RxBitSlip_Ack                       (i_phy_10_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_11_pipe_TxDataValid                         (o_phy_11_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_11_pipe_.TxDataValid
     .o_phy_11_pipe_TxData                              (o_phy_11_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_11_pipe_TxDetRxLpbk                         (o_phy_11_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_11_pipe_TxElecIdle                          (o_phy_11_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_11_pipe_PowerDown                           (o_phy_11_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_11_pipe_Rate                                (o_phy_11_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_11_pipe_PclkChangeAck                       (o_phy_11_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_11_pipe_PCLKRate                            (o_phy_11_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_11_pipe_Width                               (o_phy_11_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_11_pipe_PCLK                                (o_phy_11_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_11_pipe_rxelecidle_disable                  (o_phy_11_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_11_pipe_txcmnmode_disable                   (o_phy_11_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_11_pipe_srisenable                          (o_phy_11_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_11_pipe_RxStandby                           (o_phy_11_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_11_pipe_RxTermination                       (o_phy_11_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_11_pipe_RxWidth                             (o_phy_11_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_11_pipe_M2P_MessageBus                      (o_phy_11_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_11_pipe_rxbitslip_req                       (o_phy_11_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_11_pipe_rxbitslip_va                        (o_phy_11_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_11_pipe_RxClk                               (i_phy_11_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_11_pipe_.RxClk
     .i_phy_11_pipe_RxValid                             (i_phy_11_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_11_pipe_RxData                              (i_phy_11_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_11_pipe_RxElecIdle                          (i_phy_11_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_11_pipe_RxStatus                            (i_phy_11_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_11_pipe_RxStandbyStatus                     (i_phy_11_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_11_pipe_PhyStatus                           (i_phy_11_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_11_pipe_PclkChangeOk                        (i_phy_11_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_11_pipe_P2M_MessageBus                      (i_phy_11_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_11_pipe_RxBitSlip_Ack                       (i_phy_11_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_12_pipe_TxDataValid                         (o_phy_12_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_12_pipe_.TxDataValid
     .o_phy_12_pipe_TxData                              (o_phy_12_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_12_pipe_TxDetRxLpbk                         (o_phy_12_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_12_pipe_TxElecIdle                          (o_phy_12_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_12_pipe_PowerDown                           (o_phy_12_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_12_pipe_Rate                                (o_phy_12_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_12_pipe_PclkChangeAck                       (o_phy_12_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_12_pipe_PCLKRate                            (o_phy_12_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_12_pipe_Width                               (o_phy_12_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_12_pipe_PCLK                                (o_phy_12_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_12_pipe_rxelecidle_disable                  (o_phy_12_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_12_pipe_txcmnmode_disable                   (o_phy_12_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_12_pipe_srisenable                          (o_phy_12_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_12_pipe_RxStandby                           (o_phy_12_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_12_pipe_RxTermination                       (o_phy_12_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_12_pipe_RxWidth                             (o_phy_12_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_12_pipe_M2P_MessageBus                      (o_phy_12_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_12_pipe_rxbitslip_req                       (o_phy_12_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_12_pipe_rxbitslip_va                        (o_phy_12_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_12_pipe_RxClk                               (i_phy_12_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_12_pipe_.RxClk
     .i_phy_12_pipe_RxValid                             (i_phy_12_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_12_pipe_RxData                              (i_phy_12_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_12_pipe_RxElecIdle                          (i_phy_12_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_12_pipe_RxStatus                            (i_phy_12_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_12_pipe_RxStandbyStatus                     (i_phy_12_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_12_pipe_PhyStatus                           (i_phy_12_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_12_pipe_PclkChangeOk                        (i_phy_12_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_12_pipe_P2M_MessageBus                      (i_phy_12_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_12_pipe_RxBitSlip_Ack                       (i_phy_12_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_13_pipe_TxDataValid                         (o_phy_13_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_13_pipe_.TxDataValid
     .o_phy_13_pipe_TxData                              (o_phy_13_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_13_pipe_TxDetRxLpbk                         (o_phy_13_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_13_pipe_TxElecIdle                          (o_phy_13_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_13_pipe_PowerDown                           (o_phy_13_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_13_pipe_Rate                                (o_phy_13_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_13_pipe_PclkChangeAck                       (o_phy_13_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_13_pipe_PCLKRate                            (o_phy_13_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_13_pipe_Width                               (o_phy_13_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_13_pipe_PCLK                                (o_phy_13_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_13_pipe_rxelecidle_disable                  (o_phy_13_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_13_pipe_txcmnmode_disable                   (o_phy_13_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_13_pipe_srisenable                          (o_phy_13_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_13_pipe_RxStandby                           (o_phy_13_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_13_pipe_RxTermination                       (o_phy_13_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_13_pipe_RxWidth                             (o_phy_13_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_13_pipe_M2P_MessageBus                      (o_phy_13_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_13_pipe_rxbitslip_req                       (o_phy_13_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_13_pipe_rxbitslip_va                        (o_phy_13_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_13_pipe_RxClk                               (i_phy_13_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_13_pipe_.RxClk
     .i_phy_13_pipe_RxValid                             (i_phy_13_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_13_pipe_RxData                              (i_phy_13_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_13_pipe_RxElecIdle                          (i_phy_13_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_13_pipe_RxStatus                            (i_phy_13_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_13_pipe_RxStandbyStatus                     (i_phy_13_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_13_pipe_PhyStatus                           (i_phy_13_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_13_pipe_PclkChangeOk                        (i_phy_13_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_13_pipe_P2M_MessageBus                      (i_phy_13_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_13_pipe_RxBitSlip_Ack                       (i_phy_13_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_14_pipe_TxDataValid                         (o_phy_14_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_14_pipe_.TxDataValid
     .o_phy_14_pipe_TxData                              (o_phy_14_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_14_pipe_TxDetRxLpbk                         (o_phy_14_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_14_pipe_TxElecIdle                          (o_phy_14_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_14_pipe_PowerDown                           (o_phy_14_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_14_pipe_Rate                                (o_phy_14_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_14_pipe_PclkChangeAck                       (o_phy_14_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_14_pipe_PCLKRate                            (o_phy_14_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_14_pipe_Width                               (o_phy_14_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_14_pipe_PCLK                                (o_phy_14_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_14_pipe_rxelecidle_disable                  (o_phy_14_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_14_pipe_txcmnmode_disable                   (o_phy_14_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_14_pipe_srisenable                          (o_phy_14_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_14_pipe_RxStandby                           (o_phy_14_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_14_pipe_RxTermination                       (o_phy_14_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_14_pipe_RxWidth                             (o_phy_14_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_14_pipe_M2P_MessageBus                      (o_phy_14_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_14_pipe_rxbitslip_req                       (o_phy_14_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_14_pipe_rxbitslip_va                        (o_phy_14_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_14_pipe_RxClk                               (i_phy_14_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_14_pipe_.RxClk
     .i_phy_14_pipe_RxValid                             (i_phy_14_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_14_pipe_RxData                              (i_phy_14_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_14_pipe_RxElecIdle                          (i_phy_14_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_14_pipe_RxStatus                            (i_phy_14_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_14_pipe_RxStandbyStatus                     (i_phy_14_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_14_pipe_PhyStatus                           (i_phy_14_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_14_pipe_PclkChangeOk                        (i_phy_14_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_14_pipe_P2M_MessageBus                      (i_phy_14_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_14_pipe_RxBitSlip_Ack                       (i_phy_14_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack
     .o_phy_15_pipe_TxDataValid                         (o_phy_15_pipe_TxDataValid),                                            //  output,    width = 1,        o_phy_15_pipe_.TxDataValid
     .o_phy_15_pipe_TxData                              (o_phy_15_pipe_TxData),                                                 //  output,   width = 40,                      .TxData
     .o_phy_15_pipe_TxDetRxLpbk                         (o_phy_15_pipe_TxDetRxLpbk),                                            //  output,    width = 1,                      .TxDetRxLpbk
     .o_phy_15_pipe_TxElecIdle                          (o_phy_15_pipe_TxElecIdle),                                             //  output,    width = 4,                      .TxElecIdle
     .o_phy_15_pipe_PowerDown                           (o_phy_15_pipe_PowerDown),                                              //  output,    width = 4,                      .PowerDown
     .o_phy_15_pipe_Rate                                (o_phy_15_pipe_Rate),                                                   //  output,    width = 3,                      .Rate
     .o_phy_15_pipe_PclkChangeAck                       (o_phy_15_pipe_PclkChangeAck),                                          //  output,    width = 1,                      .PclkChangeAck
     .o_phy_15_pipe_PCLKRate                            (o_phy_15_pipe_PCLKRate),                                               //  output,    width = 3,                      .PCLKRate
     .o_phy_15_pipe_Width                               (o_phy_15_pipe_Width),                                                  //  output,    width = 2,                      .Width
     .o_phy_15_pipe_PCLK                                (o_phy_15_pipe_PCLK),                                                   //  output,    width = 1,                      .PCLK
     .o_phy_15_pipe_rxelecidle_disable                  (o_phy_15_pipe_rxelecidle_disable),                                     //  output,    width = 1,                      .rxelecidle_disable
     .o_phy_15_pipe_txcmnmode_disable                   (o_phy_15_pipe_txcmnmode_disable),                                      //  output,    width = 1,                      .txcmnmode_disable
     .o_phy_15_pipe_srisenable                          (o_phy_15_pipe_srisenable),                                             //  output,    width = 1,                      .srisenable
     .o_phy_15_pipe_RxStandby                           (o_phy_15_pipe_RxStandby),                                              //  output,    width = 1,                      .RxStandby
     .o_phy_15_pipe_RxTermination                       (o_phy_15_pipe_RxTermination),                                          //  output,    width = 1,                      .RxTermination
     .o_phy_15_pipe_RxWidth                             (o_phy_15_pipe_RxWidth),                                                //  output,    width = 2,                      .RxWidth
     .o_phy_15_pipe_M2P_MessageBus                      (o_phy_15_pipe_M2P_MessageBus),                                         //  output,    width = 8,                      .M2P_MessageBus
     .o_phy_15_pipe_rxbitslip_req                       (o_phy_15_pipe_rxbitslip_req),                                          //  output,    width = 1,                      .rxbitslip_req
     .o_phy_15_pipe_rxbitslip_va                        (o_phy_15_pipe_rxbitslip_va),                                           //  output,    width = 5,                      .rxbitslip_va
     .i_phy_15_pipe_RxClk                               (i_phy_15_pipe_RxClk),                                                  //   input,    width = 1,        i_phy_15_pipe_.RxClk
     .i_phy_15_pipe_RxValid                             (i_phy_15_pipe_RxValid),                                                //   input,    width = 1,                      .RxValid
     .i_phy_15_pipe_RxData                              (i_phy_15_pipe_RxData),                                                 //   input,   width = 40,                      .RxData
     .i_phy_15_pipe_RxElecIdle                          (i_phy_15_pipe_RxElecIdle),                                             //   input,    width = 1,                      .RxElecIdle
     .i_phy_15_pipe_RxStatus                            (i_phy_15_pipe_RxStatus),                                               //   input,    width = 3,                      .RxStatus
     .i_phy_15_pipe_RxStandbyStatus                     (i_phy_15_pipe_RxStandbyStatus),                                        //   input,    width = 1,                      .RxStandbyStatus
     .i_phy_15_pipe_PhyStatus                           (i_phy_15_pipe_PhyStatus),                                              //   input,    width = 1,                      .PhyStatus
     .i_phy_15_pipe_PclkChangeOk                        (i_phy_15_pipe_PclkChangeOk),                                           //   input,    width = 1,                      .PclkChangeOk
     .i_phy_15_pipe_P2M_MessageBus                      (i_phy_15_pipe_P2M_MessageBus),                                         //   input,    width = 8,                      .P2M_MessageBus
     .i_phy_15_pipe_RxBitSlip_Ack                       (i_phy_15_pipe_RxBitSlip_Ack),                                          //   input,    width = 1,                      .RxBitSlip_Ack



    .ip2hdm_clk                            (ip2hdm_clk),    // PLD clk 
    
// DDRMC <--> CXL-IP Slice
    .ip2hdm_reset_n                        (ip2hdm_reset_n),     // pipelined Warm reset from from CXL-IP
    .mc2ip_memsize                         (mc2ip_memsize),
  
    .usr2ip_qos_devload                    (usr2ip_qos_devload),

    //Channel-->0	  
    .mc2ip_0_sr_status                     (mc2ip_0_sr_status),
    .mc2ip_1_sr_status                     (mc2ip_1_sr_status),
 

//Channel-0
     // write address channel
      
   .ip2hdm_aximm0_awvalid   (ip2hdm_aximm0_awvalid),       
   .ip2hdm_aximm0_awid      (ip2hdm_aximm0_awid),       
   .ip2hdm_aximm0_awaddr    (ip2hdm_aximm0_awaddr),       
   .ip2hdm_aximm0_awlen     (ip2hdm_aximm0_awlen),       
   .ip2hdm_aximm0_awregion  (ip2hdm_aximm0_awregion),       
   .ip2hdm_aximm0_awuser    (ip2hdm_aximm0_awuser),       
   .ip2hdm_aximm0_awsize    (ip2hdm_aximm0_awsize),      
   .ip2hdm_aximm0_awburst   (ip2hdm_aximm0_awburst),      
   .ip2hdm_aximm0_awprot    (ip2hdm_aximm0_awprot),      
   .ip2hdm_aximm0_awqos     (ip2hdm_aximm0_awqos),      
   .ip2hdm_aximm0_awcache   (ip2hdm_aximm0_awcache),      
   .ip2hdm_aximm0_awlock    (ip2hdm_aximm0_awlock),      
   .hdm2ip_aximm0_awready   (hdm2ip_aximm0_awready),
     // write data channel
      
   .ip2hdm_aximm0_wvalid    (ip2hdm_aximm0_wvalid),          
   .ip2hdm_aximm0_wdata     (ip2hdm_aximm0_wdata),           
   .ip2hdm_aximm0_wstrb     (ip2hdm_aximm0_wstrb),           
   .ip2hdm_aximm0_wlast     (ip2hdm_aximm0_wlast),           
   .ip2hdm_aximm0_wuser     (ip2hdm_aximm0_wuser),           
   .hdm2ip_aximm0_wready    (hdm2ip_aximm0_wready),
     // write response channel
      
   .hdm2ip_aximm0_bvalid    (hdm2ip_aximm0_bvalid),
   .hdm2ip_aximm0_bid       (hdm2ip_aximm0_bid),
   .hdm2ip_aximm0_buser     (hdm2ip_aximm0_buser),
   .hdm2ip_aximm0_bresp     (hdm2ip_aximm0_bresp),
   .ip2hdm_aximm0_bready    (ip2hdm_aximm0_bready),               
     // read address channel
      
   .ip2hdm_aximm0_arvalid   (ip2hdm_aximm0_arvalid),         
   .ip2hdm_aximm0_arid      (ip2hdm_aximm0_arid),         
   .ip2hdm_aximm0_araddr    (ip2hdm_aximm0_araddr),         
   .ip2hdm_aximm0_arlen     (ip2hdm_aximm0_arlen),         
   .ip2hdm_aximm0_arregion  (ip2hdm_aximm0_arregion),         
   .ip2hdm_aximm0_aruser    (ip2hdm_aximm0_aruser),         
   .ip2hdm_aximm0_arsize    (ip2hdm_aximm0_arsize),         
   .ip2hdm_aximm0_arburst   (ip2hdm_aximm0_arburst),         
   .ip2hdm_aximm0_arprot    (ip2hdm_aximm0_arprot),         
   .ip2hdm_aximm0_arqos     (ip2hdm_aximm0_arqos),         
   .ip2hdm_aximm0_arcache   (ip2hdm_aximm0_arcache),         
   .ip2hdm_aximm0_arlock    (ip2hdm_aximm0_arlock),         
   .hdm2ip_aximm0_arready   (hdm2ip_aximm0_arready), 
     // read response channel
      
   .hdm2ip_aximm0_rvalid    (hdm2ip_aximm0_rvalid),
   .hdm2ip_aximm0_rlast     (hdm2ip_aximm0_rlast),
   .hdm2ip_aximm0_rid       (hdm2ip_aximm0_rid),
   .hdm2ip_aximm0_rdata     (hdm2ip_aximm0_rdata),
   .hdm2ip_aximm0_ruser     (hdm2ip_aximm0_ruser),
   .hdm2ip_aximm0_rresp     (hdm2ip_aximm0_rresp),
   .ip2hdm_aximm0_rready    (ip2hdm_aximm0_rready),   


//Channel-1
     // write address channel
      
   .ip2hdm_aximm1_awvalid   (ip2hdm_aximm1_awvalid),       
   .ip2hdm_aximm1_awid      (ip2hdm_aximm1_awid),       
   .ip2hdm_aximm1_awaddr    (ip2hdm_aximm1_awaddr),       
   .ip2hdm_aximm1_awlen     (ip2hdm_aximm1_awlen),       
   .ip2hdm_aximm1_awregion  (ip2hdm_aximm1_awregion),       
   .ip2hdm_aximm1_awuser    (ip2hdm_aximm1_awuser),       
   .ip2hdm_aximm1_awsize    (ip2hdm_aximm1_awsize),      
   .ip2hdm_aximm1_awburst   (ip2hdm_aximm1_awburst),      
   .ip2hdm_aximm1_awprot    (ip2hdm_aximm1_awprot),      
   .ip2hdm_aximm1_awqos     (ip2hdm_aximm1_awqos),      
   .ip2hdm_aximm1_awcache   (ip2hdm_aximm1_awcache),      
   .ip2hdm_aximm1_awlock    (ip2hdm_aximm1_awlock),      
   .hdm2ip_aximm1_awready   (hdm2ip_aximm1_awready),
     // write data channel
      
   .ip2hdm_aximm1_wvalid    (ip2hdm_aximm1_wvalid),          
   .ip2hdm_aximm1_wdata     (ip2hdm_aximm1_wdata),           
   .ip2hdm_aximm1_wstrb     (ip2hdm_aximm1_wstrb),           
   .ip2hdm_aximm1_wlast     (ip2hdm_aximm1_wlast),           
   .ip2hdm_aximm1_wuser     (ip2hdm_aximm1_wuser),           
   .hdm2ip_aximm1_wready    (hdm2ip_aximm1_wready),
     // write response channel
      
   .hdm2ip_aximm1_bvalid    (hdm2ip_aximm1_bvalid),
   .hdm2ip_aximm1_bid       (hdm2ip_aximm1_bid),
   .hdm2ip_aximm1_buser     (hdm2ip_aximm1_buser),
   .hdm2ip_aximm1_bresp     (hdm2ip_aximm1_bresp),
   .ip2hdm_aximm1_bready    (ip2hdm_aximm1_bready),               
     // read address channel
      
   .ip2hdm_aximm1_arvalid   (ip2hdm_aximm1_arvalid),         
   .ip2hdm_aximm1_arid      (ip2hdm_aximm1_arid),         
   .ip2hdm_aximm1_araddr    (ip2hdm_aximm1_araddr),         
   .ip2hdm_aximm1_arlen     (ip2hdm_aximm1_arlen),         
   .ip2hdm_aximm1_arregion  (ip2hdm_aximm1_arregion),         
   .ip2hdm_aximm1_aruser    (ip2hdm_aximm1_aruser),         
   .ip2hdm_aximm1_arsize    (ip2hdm_aximm1_arsize),         
   .ip2hdm_aximm1_arburst   (ip2hdm_aximm1_arburst),         
   .ip2hdm_aximm1_arprot    (ip2hdm_aximm1_arprot),         
   .ip2hdm_aximm1_arqos     (ip2hdm_aximm1_arqos),         
   .ip2hdm_aximm1_arcache   (ip2hdm_aximm1_arcache),         
   .ip2hdm_aximm1_arlock    (ip2hdm_aximm1_arlock),         
   .hdm2ip_aximm1_arready   (hdm2ip_aximm1_arready), 
     // read response channel
      
   .hdm2ip_aximm1_rvalid    (hdm2ip_aximm1_rvalid),
   .hdm2ip_aximm1_rlast     (hdm2ip_aximm1_rlast),
   .hdm2ip_aximm1_rid       (hdm2ip_aximm1_rid),
   .hdm2ip_aximm1_rdata     (hdm2ip_aximm1_rdata),
   .hdm2ip_aximm1_ruser     (hdm2ip_aximm1_ruser),
   .hdm2ip_aximm1_rresp     (hdm2ip_aximm1_rresp),
   .ip2hdm_aximm1_rready    (ip2hdm_aximm1_rready), 
   
   




 //AXI <-->       write address channels

   .cafu2ip_aximm0_awid                 (cafu2ip_aximm0_awid),
   .cafu2ip_aximm0_awaddr               (cafu2ip_aximm0_awaddr), 
   .cafu2ip_aximm0_awlen                (cafu2ip_aximm0_awlen),
   .cafu2ip_aximm0_awsize               (cafu2ip_aximm0_awsize),
   .cafu2ip_aximm0_awburst              (cafu2ip_aximm0_awburst),
   .cafu2ip_aximm0_awprot               (cafu2ip_aximm0_awprot),
   .cafu2ip_aximm0_awqos                (cafu2ip_aximm0_awqos),
   .cafu2ip_aximm0_awuser               (cafu2ip_aximm0_awuser),
   .cafu2ip_aximm0_awvalid              (cafu2ip_aximm0_awvalid),
   .cafu2ip_aximm0_awcache              (cafu2ip_aximm0_awcache),
   .cafu2ip_aximm0_awlock               (cafu2ip_aximm0_awlock),
   .cafu2ip_aximm0_awregion             (cafu2ip_aximm0_awregion),
   .cafu2ip_aximm0_awatop               (cafu2ip_aximm0_awatop    ) ,
   .ip2cafu_aximm0_awready              (ip2cafu_aximm0_awready),
  
   .cafu2ip_aximm1_awid                 (cafu2ip_aximm1_awid),
   .cafu2ip_aximm1_awaddr               (cafu2ip_aximm1_awaddr),
   .cafu2ip_aximm1_awlen                (cafu2ip_aximm1_awlen),
   .cafu2ip_aximm1_awsize               (cafu2ip_aximm1_awsize),
   .cafu2ip_aximm1_awburst              (cafu2ip_aximm1_awburst),
   .cafu2ip_aximm1_awprot               (cafu2ip_aximm1_awprot),
   .cafu2ip_aximm1_awqos                (cafu2ip_aximm1_awqos),
   .cafu2ip_aximm1_awuser               (cafu2ip_aximm1_awuser),
   .cafu2ip_aximm1_awvalid              (cafu2ip_aximm1_awvalid),
   .cafu2ip_aximm1_awcache              (cafu2ip_aximm1_awcache),
   .cafu2ip_aximm1_awlock               (cafu2ip_aximm1_awlock),
   .cafu2ip_aximm1_awregion             (cafu2ip_aximm1_awregion),
   .cafu2ip_aximm1_awatop               (cafu2ip_aximm1_awatop    ) ,
   .ip2cafu_aximm1_awready              (ip2cafu_aximm1_awready),

  
  //AXI <-->    write data channels
  
   .cafu2ip_aximm0_wdata                (cafu2ip_aximm0_wdata),
   .cafu2ip_aximm0_wstrb                (cafu2ip_aximm0_wstrb),
   .cafu2ip_aximm0_wlast                (cafu2ip_aximm0_wlast),
   .cafu2ip_aximm0_wuser                (cafu2ip_aximm0_wuser),
   .cafu2ip_aximm0_wvalid               (cafu2ip_aximm0_wvalid),
   .ip2cafu_aximm0_wready               (ip2cafu_aximm0_wready),
  
   .cafu2ip_aximm1_wdata                (cafu2ip_aximm1_wdata),
   .cafu2ip_aximm1_wstrb                (cafu2ip_aximm1_wstrb),
   .cafu2ip_aximm1_wlast                (cafu2ip_aximm1_wlast),
   .cafu2ip_aximm1_wuser                (cafu2ip_aximm1_wuser),
   .cafu2ip_aximm1_wvalid               (cafu2ip_aximm1_wvalid),
   .ip2cafu_aximm1_wready               (ip2cafu_aximm1_wready),

  
  //AXI <-->      write response channels

  .ip2cafu_aximm0_bid                  (ip2cafu_aximm0_bid),
  .ip2cafu_aximm0_bresp                (ip2cafu_aximm0_bresp),
  .ip2cafu_aximm0_buser                (ip2cafu_aximm0_buser),
  .ip2cafu_aximm0_bvalid               (ip2cafu_aximm0_bvalid),
  .cafu2ip_aximm0_bready               (cafu2ip_aximm0_bready),
  
  .ip2cafu_aximm1_bid                  (ip2cafu_aximm1_bid),
  .ip2cafu_aximm1_bresp                (ip2cafu_aximm1_bresp),
  .ip2cafu_aximm1_buser                (ip2cafu_aximm1_buser),
  .ip2cafu_aximm1_bvalid               (ip2cafu_aximm1_bvalid),
  .cafu2ip_aximm1_bready               (cafu2ip_aximm1_bready),

  
  //AXI <-->         read address channels

   .cafu2ip_aximm0_arid               (cafu2ip_aximm0_arid),
   .cafu2ip_aximm0_araddr             (cafu2ip_aximm0_araddr),
   .cafu2ip_aximm0_arlen              (cafu2ip_aximm0_arlen),
   .cafu2ip_aximm0_arsize             (cafu2ip_aximm0_arsize),
   .cafu2ip_aximm0_arburst            (cafu2ip_aximm0_arburst),
   .cafu2ip_aximm0_arprot             (cafu2ip_aximm0_arprot),
   .cafu2ip_aximm0_arqos              (cafu2ip_aximm0_arqos),
   .cafu2ip_aximm0_aruser             (cafu2ip_aximm0_aruser),
   .cafu2ip_aximm0_arvalid            (cafu2ip_aximm0_arvalid),
   .cafu2ip_aximm0_arcache            (cafu2ip_aximm0_arcache),
   .cafu2ip_aximm0_arlock             (cafu2ip_aximm0_arlock),
   .cafu2ip_aximm0_arregion           (cafu2ip_aximm0_arregion),
   .ip2cafu_aximm0_arready            (ip2cafu_aximm0_arready),
  
   .cafu2ip_aximm1_arid               (cafu2ip_aximm1_arid),
   .cafu2ip_aximm1_araddr             (cafu2ip_aximm1_araddr),
   .cafu2ip_aximm1_arlen              (cafu2ip_aximm1_arlen),
   .cafu2ip_aximm1_arsize             (cafu2ip_aximm1_arsize),
   .cafu2ip_aximm1_arburst            (cafu2ip_aximm1_arburst),
   .cafu2ip_aximm1_arprot             (cafu2ip_aximm1_arprot),
   .cafu2ip_aximm1_arqos              (cafu2ip_aximm1_arqos),
   .cafu2ip_aximm1_aruser             (cafu2ip_aximm1_aruser),
   .cafu2ip_aximm1_arvalid            (cafu2ip_aximm1_arvalid),
   .cafu2ip_aximm1_arcache            (cafu2ip_aximm1_arcache),
   .cafu2ip_aximm1_arlock             (cafu2ip_aximm1_arlock),
   .cafu2ip_aximm1_arregion           (cafu2ip_aximm1_arregion),
   .ip2cafu_aximm1_arready            (ip2cafu_aximm1_arready),
 


  //AXI <-->         read response channels
 
   .ip2cafu_aximm0_rid               (ip2cafu_aximm0_rid),
   .ip2cafu_aximm0_rdata             (ip2cafu_aximm0_rdata),
   .ip2cafu_aximm0_rresp             (ip2cafu_aximm0_rresp),
   .ip2cafu_aximm0_rlast             (ip2cafu_aximm0_rlast),
   .ip2cafu_aximm0_ruser             (ip2cafu_aximm0_ruser),
   .ip2cafu_aximm0_rvalid            (ip2cafu_aximm0_rvalid),
   .cafu2ip_aximm0_rready            (cafu2ip_aximm0_rready),
  
   .ip2cafu_aximm1_rid               (ip2cafu_aximm1_rid),
   .ip2cafu_aximm1_rdata             (ip2cafu_aximm1_rdata),
   .ip2cafu_aximm1_rresp             (ip2cafu_aximm1_rresp),
   .ip2cafu_aximm1_rlast             (ip2cafu_aximm1_rlast),
   .ip2cafu_aximm1_ruser             (ip2cafu_aximm1_ruser),
   .ip2cafu_aximm1_rvalid            (ip2cafu_aximm1_rvalid),
   .cafu2ip_aximm1_rready            (cafu2ip_aximm1_rready),

 
   .ip2cafu_axistd0_tvalid            (ip2cafu_axistd0_tvalid),
   .ip2cafu_axistd0_tdata             (ip2cafu_axistd0_tdata),
   .ip2cafu_axistd0_tstrb             (ip2cafu_axistd0_tstrb),
   .ip2cafu_axistd0_tdest             (ip2cafu_axistd0_tdest),
   .ip2cafu_axistd0_tkeep             (ip2cafu_axistd0_tkeep),
   .ip2cafu_axistd0_tlast             (ip2cafu_axistd0_tlast),
   .ip2cafu_axistd0_tid               (ip2cafu_axistd0_tid),
   .ip2cafu_axistd0_tuser             (ip2cafu_axistd0_tuser),
   .cafu2ip_axistd0_tready            (cafu2ip_axistd0_tready),
   .ip2cafu_axisth0_tvalid            (ip2cafu_axisth0_tvalid),
   .ip2cafu_axisth0_tdata             (ip2cafu_axisth0_tdata),
   .ip2cafu_axisth0_tstrb             (ip2cafu_axisth0_tstrb),
   .ip2cafu_axisth0_tdest             (ip2cafu_axisth0_tdest),
   .ip2cafu_axisth0_tkeep             (ip2cafu_axisth0_tkeep),
   .ip2cafu_axisth0_tlast             (ip2cafu_axisth0_tlast),
   .ip2cafu_axisth0_tid               (ip2cafu_axisth0_tid),
   .ip2cafu_axisth0_tuser             (ip2cafu_axisth0_tuser),
   .cafu2ip_axisth0_tready            (cafu2ip_axisth0_tready),
   
   .ip2cafu_axistd1_tvalid            (ip2cafu_axistd1_tvalid),
   .ip2cafu_axistd1_tdata             (ip2cafu_axistd1_tdata),
   .ip2cafu_axistd1_tstrb             (ip2cafu_axistd1_tstrb),
   .ip2cafu_axistd1_tdest             (ip2cafu_axistd1_tdest),
   .ip2cafu_axistd1_tkeep             (ip2cafu_axistd1_tkeep),
   .ip2cafu_axistd1_tlast             (ip2cafu_axistd1_tlast),
   .ip2cafu_axistd1_tid               (ip2cafu_axistd1_tid),
   .ip2cafu_axistd1_tuser             (ip2cafu_axistd1_tuser),
   .cafu2ip_axistd1_tready            (cafu2ip_axistd1_tready),
   .ip2cafu_axisth1_tvalid            (ip2cafu_axisth1_tvalid),
   .ip2cafu_axisth1_tdata             (ip2cafu_axisth1_tdata),
   .ip2cafu_axisth1_tstrb             (ip2cafu_axisth1_tstrb),
   .ip2cafu_axisth1_tdest             (ip2cafu_axisth1_tdest),
   .ip2cafu_axisth1_tkeep             (ip2cafu_axisth1_tkeep),
   .ip2cafu_axisth1_tlast             (ip2cafu_axisth1_tlast),
   .ip2cafu_axisth1_tid               (ip2cafu_axisth1_tid),
   .ip2cafu_axisth1_tuser             (ip2cafu_axisth1_tuser),
   .cafu2ip_axisth1_tready            (cafu2ip_axisth1_tready),
 

   .cafu2ip_csr0_cfg_if              (cafu2ip_csr0_cfg_if),
   .ip2cafu_csr0_cfg_if              (ip2cafu_csr0_cfg_if  ),

// Mirror
    .ip2csr_avmm_clk           ,  
    .ip2csr_avmm_rstn          , 
    .csr2ip_avmm_waitrequest   ,   
    .csr2ip_avmm_readdata      ,  
    .csr2ip_avmm_readdatavalid , 
    .ip2csr_avmm_writedata     ,
    .ip2csr_avmm_poison        ,
    .ip2csr_avmm_address       ,
    .ip2csr_avmm_write         ,
    .ip2csr_avmm_read          ,
    .ip2csr_avmm_byteenable    ,

    .ip2cafu_avmm_clk            ,
    .ip2cafu_avmm_rstn           ,
    .cafu2ip_avmm_waitrequest    ,
    .cafu2ip_avmm_readdata       ,
    .cafu2ip_avmm_readdatavalid  ,
    .ip2cafu_avmm_burstcount     ,
    .ip2cafu_avmm_writedata      ,
    .ip2cafu_avmm_poison         ,
    .ip2cafu_avmm_address        ,
    .ip2cafu_avmm_write          ,
    .ip2cafu_avmm_read           ,
    .ip2cafu_avmm_byteenable     , 

    .cafu2ip_quiesce_ack                 (cafu2ip_quiesce_ack),
    .ip2cafu_quiesce_req                 (ip2cafu_quiesce_req),
    .usr2ip_cxlreset_initiate            (usr2ip_cxlreset_initiate), 
    .ip2usr_cxlreset_req                 (ip2usr_cxlreset_req),
    .usr2ip_cxlreset_ack                 (usr2ip_cxlreset_ack),
    .ip2usr_cxlreset_error               (ip2usr_cxlreset_error),
    .ip2usr_cxlreset_complete            (ip2usr_cxlreset_complete), 
  // GPF to Example design persistent memory flow handshake
    .ip2usr_gpf_ph2_req_o                ( ip2usr_gpf_ph2_req_o ),
    .usr2ip_gpf_ph2_ack_i                ( usr2ip_gpf_ph2_ack_i ),
  // CAFU to CXL-IP , to indicate the cache evict policy
    .usr2ip_cache_evict_policy           ( usr2ip_cache_evict_policy ),
    
    .pf0_msix_enable                     (pf0_msix_enable ),
    .pf0_msix_fn_mask                    (pf0_msix_fn_mask),
    .pf1_msix_enable                     (pf1_msix_enable ),
    .pf1_msix_fn_mask                    (pf1_msix_fn_mask),
    .dev_serial_num                      (dev_serial_num),
    .dev_serial_num_valid                (dev_serial_num_valid),
    
    .ccv_afu_conf_base_addr_high         (ccv_afu_conf_base_addr_high),
    .ccv_afu_conf_base_addr_high_valid   (ccv_afu_conf_base_addr_high_valid),
    .ccv_afu_conf_base_addr_low          (ccv_afu_conf_base_addr_low),
    .ccv_afu_conf_base_addr_low_valid    (ccv_afu_conf_base_addr_low_valid),
    .pf0_max_payload_size                (pf0_max_payload_size),
    .pf0_max_read_request_size           (pf0_max_read_request_size),
    .pf0_bus_master_en                   (pf0_bus_master_en),
    .pf0_memory_access_en                (pf0_memory_access_en),
    .pf1_max_payload_size                (pf1_max_payload_size),
    .pf1_max_read_request_size           (pf1_max_read_request_size),
    .pf1_bus_master_en                   (pf1_bus_master_en),
    .pf1_memory_access_en                (pf1_memory_access_en),

    .ip2uio_tx_ready                     (ip2uio_tx_ready),
    .uio2ip_tx_st0_dvalid                (uio2ip_tx_st0_dvalid),
    .uio2ip_tx_st0_sop                   (uio2ip_tx_st0_sop),
    .uio2ip_tx_st0_eop                   (uio2ip_tx_st0_eop),
    .uio2ip_tx_st0_data                  (uio2ip_tx_st0_data),
    .uio2ip_tx_st0_data_parity           (uio2ip_tx_st0_data_parity),
    .uio2ip_tx_st0_hdr                   (uio2ip_tx_st0_hdr),
    .uio2ip_tx_st0_hdr_parity            (uio2ip_tx_st0_hdr_parity),
    .uio2ip_tx_st0_hvalid                (uio2ip_tx_st0_hvalid),
    .uio2ip_tx_st0_prefix                (uio2ip_tx_st0_prefix),
    .uio2ip_tx_st0_prefix_parity         (uio2ip_tx_st0_prefix_parity),
    .uio2ip_tx_st0_pvalid                (uio2ip_tx_st0_pvalid),
    .uio2ip_tx_st0_empty                 (uio2ip_tx_st0_empty),
    .uio2ip_tx_st0_misc_parity           (uio2ip_tx_st0_misc_parity),
  
    .uio2ip_tx_st1_dvalid                (uio2ip_tx_st1_dvalid),
    .uio2ip_tx_st1_sop                   (uio2ip_tx_st1_sop),
    .uio2ip_tx_st1_eop                   (uio2ip_tx_st1_eop),
    .uio2ip_tx_st1_data                  (uio2ip_tx_st1_data),
    .uio2ip_tx_st1_data_parity           (uio2ip_tx_st1_data_parity),
    .uio2ip_tx_st1_hdr                   (uio2ip_tx_st1_hdr),
    .uio2ip_tx_st1_hdr_parity            (uio2ip_tx_st1_hdr_parity),
    .uio2ip_tx_st1_hvalid                (uio2ip_tx_st1_hvalid),
    .uio2ip_tx_st1_prefix                (uio2ip_tx_st1_prefix),
    .uio2ip_tx_st1_prefix_parity         (uio2ip_tx_st1_prefix_parity),
    .uio2ip_tx_st1_pvalid                (uio2ip_tx_st1_pvalid),
    .uio2ip_tx_st1_empty                 (uio2ip_tx_st1_empty),
    .uio2ip_tx_st1_misc_parity           (uio2ip_tx_st1_misc_parity),
  
    .uio2ip_tx_st2_dvalid                (uio2ip_tx_st2_dvalid),
    .uio2ip_tx_st2_sop                   (uio2ip_tx_st2_sop),
    .uio2ip_tx_st2_eop                   (uio2ip_tx_st2_eop),
    .uio2ip_tx_st2_data                  (uio2ip_tx_st2_data),
    .uio2ip_tx_st2_data_parity           (uio2ip_tx_st2_data_parity),
    .uio2ip_tx_st2_hdr                   (uio2ip_tx_st2_hdr),
    .uio2ip_tx_st2_hdr_parity            (uio2ip_tx_st2_hdr_parity),
    .uio2ip_tx_st2_hvalid                (uio2ip_tx_st2_hvalid),
    .uio2ip_tx_st2_prefix                (uio2ip_tx_st2_prefix),
    .uio2ip_tx_st2_prefix_parity         (uio2ip_tx_st2_prefix_parity),
    .uio2ip_tx_st2_pvalid                (uio2ip_tx_st2_pvalid),
    .uio2ip_tx_st2_empty                 (uio2ip_tx_st2_empty),
    .uio2ip_tx_st2_misc_parity           (uio2ip_tx_st2_misc_parity),
  
    .uio2ip_tx_st3_dvalid                (uio2ip_tx_st3_dvalid),
    .uio2ip_tx_st3_sop                   (uio2ip_tx_st3_sop),
    .uio2ip_tx_st3_eop                   (uio2ip_tx_st3_eop),
    .uio2ip_tx_st3_data                  (uio2ip_tx_st3_data),
    .uio2ip_tx_st3_data_parity           (uio2ip_tx_st3_data_parity),
    .uio2ip_tx_st3_hdr                   (uio2ip_tx_st3_hdr),
    .uio2ip_tx_st3_hdr_parity            (uio2ip_tx_st3_hdr_parity),
    .uio2ip_tx_st3_hvalid                (uio2ip_tx_st3_hvalid),
    .uio2ip_tx_st3_prefix                (uio2ip_tx_st3_prefix),
    .uio2ip_tx_st3_prefix_parity         (uio2ip_tx_st3_prefix_parity),
    .uio2ip_tx_st3_pvalid                (uio2ip_tx_st3_pvalid),
    .uio2ip_tx_st3_empty                 (uio2ip_tx_st3_empty),
    .uio2ip_tx_st3_misc_parity           (uio2ip_tx_st3_misc_parity),

    .ip2uio_tx_st_Hcrdt_update           (ip2uio_tx_st_Hcrdt_update),
    .ip2uio_tx_st_Hcrdt_update_cnt       (ip2uio_tx_st_Hcrdt_update_cnt),
    .ip2uio_tx_st_Hcrdt_init             (ip2uio_tx_st_Hcrdt_init),
    .uio2ip_tx_st_Hcrdt_init_ack         (uio2ip_tx_st_Hcrdt_init_ack),
    .ip2uio_tx_st_Dcrdt_update           (ip2uio_tx_st_Dcrdt_update),
    .ip2uio_tx_st_Dcrdt_update_cnt       (ip2uio_tx_st_Dcrdt_update_cnt),
    .ip2uio_tx_st_Dcrdt_init             (ip2uio_tx_st_Dcrdt_init),
    .uio2ip_tx_st_Dcrdt_init_ack         (uio2ip_tx_st_Dcrdt_init_ack),
  
    .ip2uio_rx_st0_dvalid                (ip2uio_rx_st0_dvalid),
    .ip2uio_rx_st0_sop                   (ip2uio_rx_st0_sop),
    .ip2uio_rx_st0_eop                   (ip2uio_rx_st0_eop),
    .ip2uio_rx_st0_passthrough           (ip2uio_rx_st0_passthrough),
    .ip2uio_rx_st0_data                  (ip2uio_rx_st0_data),
    .ip2uio_rx_st0_data_parity           (ip2uio_rx_st0_data_parity),
    .ip2uio_rx_st0_hdr                   (ip2uio_rx_st0_hdr),
    .ip2uio_rx_st0_hdr_parity            (ip2uio_rx_st0_hdr_parity),
    .ip2uio_rx_st0_hvalid                (ip2uio_rx_st0_hvalid),
    .ip2uio_rx_st0_prefix                (ip2uio_rx_st0_prefix),
    .ip2uio_rx_st0_prefix_parity         (ip2uio_rx_st0_prefix_parity),
    .ip2uio_rx_st0_pvalid                (ip2uio_rx_st0_pvalid),
    .ip2uio_rx_st0_bar                   (ip2uio_rx_st0_bar),
    .ip2uio_rx_st0_pfnum                 (ip2uio_rx_st0_pfnum),
    .ip2uio_rx_st0_misc_parity           (ip2uio_rx_st0_misc_parity),
    .ip2uio_rx_st0_empty                 (ip2uio_rx_st0_empty),
  
    .ip2uio_rx_st1_dvalid                (ip2uio_rx_st1_dvalid),
    .ip2uio_rx_st1_sop                   (ip2uio_rx_st1_sop),
    .ip2uio_rx_st1_eop                   (ip2uio_rx_st1_eop),
    .ip2uio_rx_st1_passthrough           (ip2uio_rx_st1_passthrough),
    .ip2uio_rx_st1_data                  (ip2uio_rx_st1_data),
    .ip2uio_rx_st1_data_parity           (ip2uio_rx_st1_data_parity),
    .ip2uio_rx_st1_hdr                   (ip2uio_rx_st1_hdr),
    .ip2uio_rx_st1_hdr_parity            (ip2uio_rx_st1_hdr_parity),
    .ip2uio_rx_st1_hvalid                (ip2uio_rx_st1_hvalid),
    .ip2uio_rx_st1_prefix                (ip2uio_rx_st1_prefix),
    .ip2uio_rx_st1_prefix_parity         (ip2uio_rx_st1_prefix_parity),
    .ip2uio_rx_st1_pvalid                (ip2uio_rx_st1_pvalid),
    .ip2uio_rx_st1_bar                   (ip2uio_rx_st1_bar),
    .ip2uio_rx_st1_pfnum                 (ip2uio_rx_st1_pfnum),
    .ip2uio_rx_st1_misc_parity           (ip2uio_rx_st1_misc_parity),
    .ip2uio_rx_st1_empty                 (ip2uio_rx_st1_empty),
  
    .ip2uio_rx_st2_dvalid                (ip2uio_rx_st2_dvalid),
    .ip2uio_rx_st2_sop                   (ip2uio_rx_st2_sop),
    .ip2uio_rx_st2_eop                   (ip2uio_rx_st2_eop),
    .ip2uio_rx_st2_passthrough           (ip2uio_rx_st2_passthrough),
    .ip2uio_rx_st2_data                  (ip2uio_rx_st2_data),
    .ip2uio_rx_st2_data_parity           (ip2uio_rx_st2_data_parity),
    .ip2uio_rx_st2_hdr                   (ip2uio_rx_st2_hdr),
    .ip2uio_rx_st2_hdr_parity            (ip2uio_rx_st2_hdr_parity),
    .ip2uio_rx_st2_hvalid                (ip2uio_rx_st2_hvalid),
    .ip2uio_rx_st2_prefix                (ip2uio_rx_st2_prefix),
    .ip2uio_rx_st2_prefix_parity         (ip2uio_rx_st2_prefix_parity),
    .ip2uio_rx_st2_pvalid                (ip2uio_rx_st2_pvalid),
    .ip2uio_rx_st2_bar                   (ip2uio_rx_st2_bar),
    .ip2uio_rx_st2_pfnum                 (ip2uio_rx_st2_pfnum),
    .ip2uio_rx_st2_misc_parity           (ip2uio_rx_st2_misc_parity),
    .ip2uio_rx_st2_empty                 (ip2uio_rx_st2_empty),
    
    .ip2uio_rx_st3_dvalid                (ip2uio_rx_st3_dvalid),
    .ip2uio_rx_st3_sop                   (ip2uio_rx_st3_sop),
    .ip2uio_rx_st3_eop                   (ip2uio_rx_st3_eop),
    .ip2uio_rx_st3_passthrough           (ip2uio_rx_st3_passthrough),
    .ip2uio_rx_st3_data                  (ip2uio_rx_st3_data),
    .ip2uio_rx_st3_data_parity           (ip2uio_rx_st3_data_parity),
    .ip2uio_rx_st3_hdr                   (ip2uio_rx_st3_hdr),
    .ip2uio_rx_st3_hdr_parity            (ip2uio_rx_st3_hdr_parity),
    .ip2uio_rx_st3_hvalid                (ip2uio_rx_st3_hvalid),
    .ip2uio_rx_st3_prefix                (ip2uio_rx_st3_prefix),
    .ip2uio_rx_st3_prefix_parity         (ip2uio_rx_st3_prefix_parity),
    .ip2uio_rx_st3_pvalid                (ip2uio_rx_st3_pvalid),
    .ip2uio_rx_st3_bar                   (ip2uio_rx_st3_bar),
    .ip2uio_rx_st3_pfnum                 (ip2uio_rx_st3_pfnum),
    .ip2uio_rx_st3_misc_parity           (ip2uio_rx_st3_misc_parity),
    .ip2uio_rx_st3_empty                 (ip2uio_rx_st3_empty),
  
    .uio2ip_rx_st_Hcrdt_update           (uio2ip_rx_st_Hcrdt_update),
    .uio2ip_rx_st_Hcrdt_update_cnt       (uio2ip_rx_st_Hcrdt_update_cnt),
    .uio2ip_rx_st_Hcrdt_init             (uio2ip_rx_st_Hcrdt_init),
    .ip2uio_rx_st_Hcrdt_init_ack         (ip2uio_rx_st_Hcrdt_init_ack),
    .uio2ip_rx_st_Dcrdt_update           (uio2ip_rx_st_Dcrdt_update),
    .uio2ip_rx_st_Dcrdt_update_cnt       (uio2ip_rx_st_Dcrdt_update_cnt),
    .uio2ip_rx_st_Dcrdt_init             (uio2ip_rx_st_Dcrdt_init),
    .ip2uio_rx_st_Dcrdt_init_ack         (ip2uio_rx_st_Dcrdt_init_ack),
    .usr2ip_app_err_valid                (usr2ip_app_err_valid),
    .usr2ip_app_err_hdr                  (usr2ip_app_err_hdr),
    .usr2ip_app_err_info                 (usr2ip_app_err_info),
    .usr2ip_app_err_func_num             (usr2ip_app_err_func_num),
    .ip2usr_app_err_ready                (ip2usr_app_err_ready),
    //.ip2usr_err_valid                    (ip2usr_err_valid                    ),
    //.ip2usr_err_hdr                      (ip2usr_err_hdr                      ),
    //.ip2usr_err_tlp_prefix               (ip2usr_err_tlp_prefix               ),
    //.ip2usr_err_info                     (ip2usr_err_info                     ),
    .ip2usr_aermsg_correctable_valid     (ip2usr_aermsg_correctable_valid  ),
    .ip2usr_aermsg_uncorrectable_valid   (ip2usr_aermsg_uncorrectable_valid),
    .ip2usr_aermsg_res                   (ip2usr_aermsg_res                ),    
    .ip2usr_aermsg_bts                   (ip2usr_aermsg_bts                ),    
    .ip2usr_aermsg_bds                   (ip2usr_aermsg_bds                ),    
    .ip2usr_aermsg_rrs                   (ip2usr_aermsg_rrs                ),    
    .ip2usr_aermsg_rtts                  (ip2usr_aermsg_rtts               ),    
    .ip2usr_aermsg_anes                  (ip2usr_aermsg_anes               ),    
    .ip2usr_aermsg_cies                  (ip2usr_aermsg_cies               ),    
    .ip2usr_aermsg_hlos                  (ip2usr_aermsg_hlos               ),    
    .ip2usr_aermsg_fmt                   (ip2usr_aermsg_fmt                ),    
    .ip2usr_aermsg_type                  (ip2usr_aermsg_type               ),    
    .ip2usr_aermsg_tc                    (ip2usr_aermsg_tc                 ),    
    .ip2usr_aermsg_ido                   (ip2usr_aermsg_ido                ),    
    .ip2usr_aermsg_th                    (ip2usr_aermsg_th                 ),    
    .ip2usr_aermsg_td                    (ip2usr_aermsg_td                 ),    
    .ip2usr_aermsg_ep                    (ip2usr_aermsg_ep                 ),    
    .ip2usr_aermsg_ro                    (ip2usr_aermsg_ro                 ),    
    .ip2usr_aermsg_ns                    (ip2usr_aermsg_ns                 ),    
    .ip2usr_aermsg_at                    (ip2usr_aermsg_at                 ),    
    .ip2usr_aermsg_length                (ip2usr_aermsg_length             ),  
    .ip2usr_aermsg_header                (ip2usr_aermsg_header             ),  
    .ip2usr_aermsg_und                   (ip2usr_aermsg_und                ),     
    .ip2usr_aermsg_anf                   (ip2usr_aermsg_anf                ),     
    .ip2usr_aermsg_dlpes                 (ip2usr_aermsg_dlpes              ),   
    .ip2usr_aermsg_sdes                  (ip2usr_aermsg_sdes               ),    
    .ip2usr_aermsg_fep                   (ip2usr_aermsg_fep                ),     
    .ip2usr_aermsg_pts                   (ip2usr_aermsg_pts                ),     
    .ip2usr_aermsg_fcpes                 (ip2usr_aermsg_fcpes              ),   
    .ip2usr_aermsg_cts                   (ip2usr_aermsg_cts                ),    
    .ip2usr_aermsg_cas                   (ip2usr_aermsg_cas                ),    
    .ip2usr_aermsg_ucs                   (ip2usr_aermsg_ucs                ),    
    .ip2usr_aermsg_ros                   (ip2usr_aermsg_ros                ),    
    .ip2usr_aermsg_mts                   (ip2usr_aermsg_mts                ),    
    .ip2usr_aermsg_uies                  (ip2usr_aermsg_uies               ),    
    .ip2usr_aermsg_mbts                  (ip2usr_aermsg_mbts               ),    
    .ip2usr_aermsg_aebs                  (ip2usr_aermsg_aebs               ),    
    .ip2usr_aermsg_tpbes                 (ip2usr_aermsg_tpbes              ),   
    .ip2usr_aermsg_ees                   (ip2usr_aermsg_ees                ),     
    .ip2usr_aermsg_ures                  (ip2usr_aermsg_ures               ),    
    .ip2usr_aermsg_avs                   (ip2usr_aermsg_avs                ), 
    .ip2usr_serr_out                     (ip2usr_serr_out),
    .ip2usr_debug_waitrequest            (ip2usr_debug_waitrequest),
    .ip2usr_debug_readdata               (ip2usr_debug_readdata),
    .ip2usr_debug_readdatavalid          (ip2usr_debug_readdatavalid),
    .usr2ip_debug_writedata              (usr2ip_debug_writedata),
    .usr2ip_debug_address                (usr2ip_debug_address),
    .usr2ip_debug_write                  (usr2ip_debug_write),
    .usr2ip_debug_read                   (usr2ip_debug_read),
    .usr2ip_debug_byteenable             (usr2ip_debug_byteenable),   

    .ip2uio_bus_number                   (ip2uio_bus_number), 
    .ip2uio_device_number                (ip2uio_device_number)  
  );

endmodule

