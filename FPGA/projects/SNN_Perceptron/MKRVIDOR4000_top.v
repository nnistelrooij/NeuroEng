/*
* Copyright 2018 ARDUINO SA (http://www.arduino.cc/)
* This file is part of Vidor IP.
* Copyright (c) 2018
* Authors: Dario Pennisi
*
* This software is released under:
* The GNU General Public License, which covers the main part of 
* Vidor IP
* The terms of this license can be found at:
* https://www.gnu.org/licenses/gpl-3.0.en.html
*
* You can be released from the requirements of the above licenses by purchasing
* a commercial license. Buying such a license is mandatory if you want to modify or
* otherwise use the software for commercial activities involving the Arduino
* software without disclosing the source code of your own applications. To purchase
* a commercial license, send an email to license@arduino.cc.
*
*/

module MKRVIDOR4000_top
(
  // system signals
  input         iCLK,
  input         iRESETn,
  input         iSAM_INT,
  output        oSAM_INT,
  
  // SDRAM
  output        oSDRAM_CLK,
  output [11:0] oSDRAM_ADDR,
  output [1:0]  oSDRAM_BA,
  output        oSDRAM_CASn,
  output        oSDRAM_CKE,
  output        oSDRAM_CSn,
  inout  [15:0] bSDRAM_DQ,
  output [1:0]  oSDRAM_DQM,
  output        oSDRAM_RASn,
  output        oSDRAM_WEn,

  // SAM D21 PINS
  inout         bMKR_AREF,
  inout  [6:0]  bMKR_A,
  inout  [14:0] bMKR_D,
  
  // Mini PCIe
  inout         bPEX_RST,
  inout         bPEX_PIN6,
  inout         bPEX_PIN8,
  inout         bPEX_PIN10,
  input         iPEX_PIN11,
  inout         bPEX_PIN12,
  input         iPEX_PIN13,
  inout         bPEX_PIN14,
  inout         bPEX_PIN16,
  inout         bPEX_PIN20,
  input         iPEX_PIN23,
  input         iPEX_PIN25,
  inout         bPEX_PIN28,
  inout         bPEX_PIN30,
  input         iPEX_PIN31,
  inout         bPEX_PIN32,
  input         iPEX_PIN33,
  inout         bPEX_PIN42,
  inout         bPEX_PIN44,
  inout         bPEX_PIN45,
  inout         bPEX_PIN46,
  inout         bPEX_PIN47,
  inout         bPEX_PIN48,
  inout         bPEX_PIN49,
  inout         bPEX_PIN51,

  // NINA interface
  inout         bWM_PIO1,
  inout         bWM_PIO2,
  inout         bWM_PIO3,
  inout         bWM_PIO4,
  inout         bWM_PIO5,
  inout         bWM_PIO7,
  inout         bWM_PIO8,
  inout         bWM_PIO18,
  inout         bWM_PIO20,
  inout         bWM_PIO21,
  inout         bWM_PIO27,
  inout         bWM_PIO28,
  inout         bWM_PIO29,
  inout         bWM_PIO31,
  input         iWM_PIO32,
  inout         bWM_PIO34,
  inout         bWM_PIO35,
  inout         bWM_PIO36,
  input         iWM_TX,
  inout         oWM_RX,
  inout         oWM_RESET,

  // HDMI output
  output [2:0]  oHDMI_TX,
  output        oHDMI_CLK,

  inout         bHDMI_SDA,
  inout         bHDMI_SCL,
  
  input         iHDMI_HPD,
  
  // MIPI input
  input  [1:0]  iMIPI_D,
  input         iMIPI_CLK,
  inout         bMIPI_SDA,
  inout         bMIPI_SCL,
  inout  [1:0]  bMIPI_GP,

  // Q-SPI Flash interface
  output        oFLASH_SCK,
  output        oFLASH_CS,
  inout         oFLASH_MOSI,
  inout         iFLASH_MISO,
  inout         oFLASH_HOLD,
  inout         oFLASH_WP

);

// signal declaration

wire        wOSC_CLK;

wire        wCLK8,wCLK24, wCLK64, wCLK120;

wire [31:0] wJTAG_ADDRESS, wJTAG_READ_DATA, wJTAG_WRITE_DATA, wDPRAM_READ_DATA;
wire        wJTAG_READ, wJTAG_WRITE, wJTAG_WAIT_REQUEST, wJTAG_READ_DATAVALID;
wire [4:0]  wJTAG_BURST_COUNT;
wire        wDPRAM_CS;

wire [7:0]  wDVI_RED,wDVI_GRN,wDVI_BLU;
wire        wDVI_HS, wDVI_VS, wDVI_DE;

wire        wVID_CLK, wVID_CLKx5;
wire        wMEM_CLK;

assign wVID_CLK   = wCLK24;
assign wVID_CLKx5 = wCLK120;
assign wCLK8      = iCLK;

// internal oscillator
cyclone10lp_oscillator   osc
  ( 
  .clkout(wOSC_CLK),
  .oscena(1'b1));

// system PLL
SYSTEM_PLL PLL_inst(
  .areset(1'b0),
  .inclk0(wCLK8),
  .c0(wCLK24),
  .c1(wCLK120),
  .c2(wMEM_CLK),
   .c3(oSDRAM_CLK),
  .c4(wFLASH_CLK),
   
  .locked()
);


// ================================================
// Your design here

wire [31:0] DATA [13:0];  // Data from the JTAG
wire NEXT, FINISH;  // Status information from the JTAG
wire [1:0] SNN_OUT;  // Data to the JTAG
wire [31:0] DEBUG;  // Debug information to the JTAG
MyDesign MyDesign_inst (
	.iCLK_MAIN(wCLK120),		// Attach main 120MHz clock
	.IN_00(DATA[0]),
	.IN_01(DATA[1]),
	.IN_02(DATA[2]),
	.IN_03(DATA[3]),
	.IN_04(DATA[4]),
	.IN_05(DATA[5]),
	.IN_06(DATA[6]),
	.IN_07(DATA[7]),
	.IN_08(DATA[8]),
	.IN_09(DATA[9]),
	.IN_10(DATA[10]),
	.IN_11(DATA[11]),
	.IN_12(DATA[12]),
	.IN_13(DATA[13]),
	.NEXT(NEXT),
	.FINISH(FINISH),
	.SNN_OUT(SNN_OUT),
	.OUT_01(DEBUG)
);


reg [799:0] IMAGE; // Room for 800 bits of data (25*32 bits)
reg [1:0] status = 0; // status to finish and reset in order
reg start_SNN = 0;  // spike to reset and start SNN
run_network #(
	.WIDTH(8),
	.HEIGHT(7),
	.WEIGHTS('{9'd255, 9'd1, 9'd60, 9'd260, 9'd260, 9'd257, 9'd511})
) SNN (
	.clk((status == 0) & wCLK8),
	.pixels(IMAGE[6:0]),
	.start(wCLK8 & start_SNN),
	.neuron_out(SNN_OUT),
	.balance_out(DEBUG)
);


reg [9:0] reg_offset = 0;  // which pixel is being written
reg progressed = 0;  // whether we have written something in IMAGE
integer i, j;
always @(posedge wCLK8) begin
	if (NEXT && !progressed) begin
		status = 1;
		progressed = 1;
		for (i = 0; i < 14; i = i + 1) begin
			reg_offset = 448 * FINISH + 32 * i;
			if (!FINISH || i < 11) begin
				for (j = 0; j < 32; j = j + 1) begin
					IMAGE[reg_offset + j] <= DATA[i][j];
				end
			end
		end
	end else if (!NEXT) begin
		progressed = 0;
	end
	
	if (FINISH && reg_offset > 0) begin
		reg_offset = 0;
		status = 2;
	end else if (status == 2) begin
		start_SNN = 1;
		status = 3;
	end else if (status == 3) begin
		start_SNN = 0;
		status = 0;
	end
end

// ================================================


reg [5:0] rRESETstatus;

always @(posedge wMEM_CLK)
begin
  if (!rRESETstatus[5])
  begin
  rRESETstatus<=rRESETstatus+1;
  end
end

endmodule