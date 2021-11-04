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
wire [1:0] SNN_OUT;  // Data to the JTAG

reg [799:0] IMAGE; // Room for 800 bits of data (25*32 bits)

wire NEXT;
wire FINISH;
reg [9:0] reg_offset = 0;
wire [1:0] neuron_out;
reg [3:0] i;
reg [5:0] j;

wire [31:0] DEBUG;

reg progressed = 0;
reg start_SNN = 0;

reg [1:0] cnt = 0;
wire spike_clock;


MyDesign MyDesign_inst (
	.iCLK_MAIN(wCLK8),		// Attach main 120MHz clock
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
	.OUT_01(DEBUG),
	.NEXT(NEXT),
	.FINISH(FINISH),
	.SNN_OUT(SNN_OUT)
);

// 33 pixels works
//run_network #(
//	.WIDTH(8),
//	.HEIGHT(33),
//	.NUM_POS_WEIGHTS(17),
//	.WEIGHTS('{9'd0,9'd260,9'd261,9'd7,9'd0,9'd258,9'd0,9'd273,9'd261,9'd266,9'd2,9'd258,9'd6,9'd2,9'd264,9'd1,9'd260,9'd0,9'd1,9'd260,9'd5,9'd1,9'd0,9'd265,9'd259,9'd260,9'd6,9'd15,9'd0,9'd270,9'd264,9'd5,9'd262})
//) SNN (
//	.clk(spike_clock),
//	.pixels(IMAGE[32:0]),
//	.start(wCLK8 & start_SNN),
//	.neuron_out(neuron_out),
//	.balance_out(DEBUG)
//);


// precision of 8
//run_network #(
//	.WIDTH(8),
//	.HEIGHT(784),
//	.NUM_POS_WEIGHTS(398),
//	.WEIGHTS('{9'd0,9'd260,9'd261,9'd7,9'd0,9'd258,9'd0,9'd273,9'd261,9'd266,9'd2,9'd258,9'd6,9'd2,9'd264,9'd1,9'd260,9'd0,9'd1,9'd260,9'd5,9'd1,9'd0,9'd265,9'd259,9'd260,9'd6,9'd15,9'd0,9'd270,9'd264,9'd5,9'd262,9'd17,9'd266,9'd5,9'd0,9'd259,9'd258,9'd259,9'd4,9'd261,9'd0,9'd261,9'd11,9'd6,9'd1,9'd258,9'd260,9'd3,9'd258,9'd0,9'd260,9'd6,9'd3,9'd1,9'd5,9'd258,9'd258,9'd5,9'd0,9'd3,9'd0,9'd0,9'd266,9'd0,9'd265,9'd264,9'd261,9'd12,9'd4,9'd0,9'd292,9'd288,9'd259,9'd264,9'd0,9'd5,9'd0,9'd3,9'd7,9'd5,9'd258,9'd2,9'd1,9'd1,9'd3,9'd5,9'd264,9'd0,9'd261,9'd257,9'd294,9'd259,9'd305,9'd310,9'd347,9'd281,9'd293,9'd349,9'd330,9'd312,9'd322,9'd267,9'd268,9'd262,9'd4,9'd259,9'd4,9'd261,9'd264,9'd11,9'd257,9'd18,9'd6,9'd2,9'd2,9'd273,9'd268,9'd323,9'd297,9'd332,9'd389,9'd471,9'd509,9'd507,9'd419,9'd473,9'd475,9'd382,9'd399,9'd351,9'd286,9'd277,9'd6,9'd261,9'd8,9'd270,9'd1,9'd7,9'd0,9'd261,9'd0,9'd264,9'd261,9'd40,9'd32,9'd306,9'd35,9'd109,9'd274,9'd291,9'd305,9'd305,9'd10,9'd280,9'd285,9'd345,9'd389,9'd393,9'd436,9'd401,9'd358,9'd344,9'd8,9'd266,9'd257,9'd0,9'd258,9'd259,9'd272,9'd8,9'd75,9'd152,9'd78,9'd262,9'd92,9'd337,9'd268,9'd335,9'd38,9'd43,9'd19,9'd327,9'd305,9'd81,9'd336,9'd327,9'd341,9'd267,9'd56,9'd319,9'd275,9'd0,9'd5,9'd0,9'd266,9'd0,9'd0,9'd58,9'd149,9'd264,9'd17,9'd124,9'd359,9'd120,9'd37,9'd48,9'd310,9'd259,9'd298,9'd26,9'd286,9'd39,9'd85,9'd265,9'd119,9'd39,9'd82,9'd68,9'd331,9'd0,9'd7,9'd12,9'd260,9'd17,9'd52,9'd22,9'd78,9'd0,9'd111,9'd78,9'd62,9'd91,9'd303,9'd271,9'd102,9'd317,9'd29,9'd261,9'd275,9'd86,9'd276,9'd53,9'd271,9'd78,9'd18,9'd68,9'd287,9'd1,9'd4,9'd3,9'd3,9'd10,9'd35,9'd88,9'd107,9'd279,9'd51,9'd26,9'd13,9'd0,9'd327,9'd260,9'd46,9'd53,9'd296,9'd12,9'd31,9'd278,9'd34,9'd60,9'd358,9'd58,9'd23,9'd2,9'd17,9'd3,9'd22,9'd26,9'd8,9'd23,9'd40,9'd15,9'd95,9'd48,9'd68,9'd18,9'd1,9'd136,9'd0,9'd45,9'd285,9'd305,9'd46,9'd120,9'd105,9'd261,9'd55,9'd91,9'd305,9'd37,9'd112,9'd269,9'd25,9'd24,9'd26,9'd6,9'd258,9'd27,9'd76,9'd112,9'd78,9'd261,9'd101,9'd39,9'd57,9'd264,9'd187,9'd95,9'd0,9'd273,9'd104,9'd61,9'd149,9'd141,9'd85,9'd291,9'd78,9'd66,9'd114,9'd57,9'd58,9'd6,9'd267,9'd8,9'd257,9'd17,9'd73,9'd79,9'd56,9'd131,9'd77,9'd117,9'd233,9'd267,9'd328,9'd323,9'd426,9'd280,9'd304,9'd2,9'd30,9'd263,9'd56,9'd308,9'd336,9'd104,9'd109,9'd292,9'd76,9'd0,9'd11,9'd259,9'd259,9'd9,9'd30,9'd54,9'd48,9'd101,9'd299,9'd263,9'd298,9'd98,9'd118,9'd316,9'd504,9'd436,9'd337,9'd95,9'd286,9'd309,9'd282,9'd281,9'd56,9'd92,9'd101,9'd55,9'd25,9'd268,9'd4,9'd10,9'd4,9'd3,9'd11,9'd25,9'd42,9'd72,9'd28,9'd116,9'd20,9'd96,9'd73,9'd276,9'd355,9'd314,9'd296,9'd363,9'd302,9'd83,9'd64,9'd96,9'd54,9'd348,9'd86,9'd9,9'd20,9'd0,9'd0,9'd267,9'd266,9'd2,9'd257,9'd69,9'd11,9'd263,9'd47,9'd55,9'd19,9'd307,9'd101,9'd60,9'd374,9'd318,9'd330,9'd34,9'd288,9'd32,9'd57,9'd26,9'd301,9'd23,9'd56,9'd294,9'd313,9'd7,9'd261,9'd4,9'd0,9'd258,9'd266,9'd270,9'd5,9'd50,9'd133,9'd68,9'd70,9'd264,9'd278,9'd273,9'd340,9'd363,9'd51,9'd46,9'd135,9'd70,9'd271,9'd274,9'd333,9'd264,9'd324,9'd351,9'd324,9'd0,9'd0,9'd0,9'd6,9'd257,9'd263,9'd354,9'd343,9'd377,9'd21,9'd0,9'd296,9'd45,9'd312,9'd33,9'd298,9'd96,9'd121,9'd100,9'd147,9'd348,9'd267,9'd331,9'd265,9'd0,9'd273,9'd278,9'd79,9'd25,9'd257,9'd262,9'd6,9'd5,9'd263,9'd351,9'd391,9'd365,9'd401,9'd384,9'd296,9'd294,9'd329,9'd1,9'd306,9'd45,9'd53,9'd306,9'd395,9'd330,9'd96,9'd372,9'd57,9'd291,9'd312,9'd85,9'd73,9'd1,9'd265,9'd1,9'd7,9'd264,9'd261,9'd321,9'd370,9'd476,9'd352,9'd4,9'd26,9'd308,9'd78,9'd255,9'd302,9'd306,9'd282,9'd328,9'd283,9'd265,9'd333,9'd332,9'd294,9'd327,9'd357,9'd87,9'd120,9'd259,9'd261,9'd262,9'd259,9'd1,9'd265,9'd319,9'd449,9'd407,9'd381,9'd352,9'd284,9'd322,9'd53,9'd112,9'd88,9'd16,9'd306,9'd312,9'd283,9'd362,9'd404,9'd372,9'd397,9'd428,9'd472,9'd10,9'd52,9'd263,9'd261,9'd263,9'd257,9'd7,9'd319,9'd367,9'd407,9'd410,9'd321,9'd456,9'd351,9'd35,9'd260,9'd123,9'd108,9'd8,9'd326,9'd325,9'd364,9'd310,9'd449,9'd378,9'd415,9'd340,9'd409,9'd304,9'd259,9'd3,9'd260,9'd0,9'd0,9'd258,9'd277,9'd369,9'd395,9'd106,9'd289,9'd345,9'd351,9'd302,9'd446,9'd385,9'd42,9'd27,9'd285,9'd31,9'd359,9'd379,9'd343,9'd299,9'd365,9'd363,9'd365,9'd289,9'd11,9'd0,9'd4,9'd1,9'd9,9'd257,9'd4,9'd342,9'd295,9'd308,9'd31,9'd36,9'd389,9'd285,9'd302,9'd364,9'd257,9'd263,9'd294,9'd311,9'd16,9'd315,9'd299,9'd318,9'd267,9'd318,9'd294,9'd299,9'd269,9'd265,9'd0,9'd260,9'd3,9'd261,9'd268,9'd285,9'd326,9'd19,9'd303,9'd0,9'd81,9'd329,9'd339,9'd328,9'd372,9'd91,9'd39,9'd306,9'd34,9'd30,9'd68,9'd25,9'd277,9'd279,9'd270,9'd282,9'd0,9'd258,9'd260,9'd3,9'd257,9'd262,9'd6,9'd261,9'd71,9'd35,9'd382,9'd267,9'd331,9'd294,9'd300,9'd38,9'd407,9'd375,9'd310,9'd35,9'd316,9'd55,9'd258,9'd298,9'd28,9'd68,9'd10,9'd1,9'd3,9'd264,9'd0,9'd3,9'd1,9'd257,9'd267,9'd258,9'd265,9'd3,9'd313,9'd285,9'd25,9'd8,9'd21,9'd17,9'd18,9'd37,9'd55,9'd266,9'd266,9'd272,9'd9,9'd25,9'd3,9'd7,9'd0,9'd10,9'd1,9'd4,9'd9,9'd6,9'd17,9'd0,9'd6,9'd8,9'd261,9'd0,9'd0,9'd5,9'd265,9'd11,9'd25,9'd0,9'd12,9'd23,9'd24,9'd44,9'd15,9'd8,9'd1,9'd5,9'd9,9'd8,9'd271,9'd12,9'd1,9'd3,9'd14,9'd3})
//) SNN (
//	.clk(spike_clock),
//	.pixels(IMAGE[783:0]),
//	.start(wCLK8 & start_SNN),
//	.neuron_out(neuron_out),
//	.balance_out(DEBUG)
//);

// test network
run_network #(
	.WIDTH(8),
	.HEIGHT(7),
	.NUM_POS_WEIGHTS(3),
	.WEIGHTS('{9'd255, 9'd1, 9'd60, 9'd260, 9'd260, 9'd257, 9'd511})
) SNN (
	.clk(spike_clock),
	.pixels(IMAGE[6:0]),
	.start(start_SNN),
	.neuron_out(neuron_out),
	.balance_out(DEBUG)
);

always @(posedge wCLK8) begin
	if (NEXT && !progressed) begin
		cnt = 3;
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
		cnt = 1;
	end else if (cnt == 1) begin
		start_SNN = 1;
		cnt = 2;
	end else if (cnt == 2) begin
		start_SNN = 0;
		cnt = 0;
	end
end

assign SNN_OUT = neuron_out;
assign spike_clock = (cnt == 0) * wCLK8;

// ================================================


reg [5:0] rRESETCNT;

always @(posedge wMEM_CLK)
begin
  if (!rRESETCNT[5])
  begin
  rRESETCNT<=rRESETCNT+1;
  end
end

endmodule
