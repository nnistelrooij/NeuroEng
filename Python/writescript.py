import os
import random
import re
import time

import numpy as np


def binarize_data(images, labels, pos_class=7, neg_class=3):
    # only retain two classes
    mask = (labels == pos_class) | (labels == neg_class)

    # make pixel values and labels binary
    images = (images[mask] > 128).astype(int)
    labels = (labels[mask] == pos_class).astype(int)

    return images, labels


def image_to_bits(image):
    bit_string = ''
    for pixel_row in reversed(image):
        for pixel in reversed(pixel_row):
            bit_string += str(pixel)

    return bit_string


if __name__ == '__main__':
    # load test data and binarize images
    test_file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'test.npz')
    data = np.load(test_file_path)
    images, labels = binarize_data(data['arr_0'], data['arr_1'])

    # select which images to test in simulation
    num_images = 1038
    start_idx = 1000
    images, labels = images[start_idx:start_idx + num_images], labels[start_idx:start_idx + num_images]

    # base module as string
    base = f"""module run_network
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter NUM_POS_WEIGHTS = 3,
	parameter bit [WIDTH:0] WEIGHTS [0:HEIGHT - 1] = '{{9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60}}
)
(
	input wire clk,  // clock signal
	input wire [HEIGHT - 1:0] pixels,  // binary inputs
	input wire start,  // active high start signal
	// binary outputs; 00: don't know, 01: pos class, 10: neg class
	output wire [1:0] neuron_out,
	output [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance_out
);
	reg running = 0;  // whether network is running
	// number of iterations network has been running
	reg [$clog2(HEIGHT * (2 **(WIDTH + 1) + 2)) - 1:0] iters = 0;

	network #(.WIDTH(WIDTH), .HEIGHT(HEIGHT), .NUM_POS_WEIGHTS(NUM_POS_WEIGHTS), .WEIGHTS(WEIGHTS)) N (
		.clk(running & clk),
		.rst(!start),
		.pixels(pixels),
		.neuron_out(neuron_out[0]),
		.balance_out(balance_out)
	);
	
	always @(posedge clk, posedge start) begin
		if (start) begin
			running = 1;
			iters = 0;
		end else if (iters == (HEIGHT * (2 **(WIDTH + 1) + 2) - 1)) begin
			running = 0;
			iters = 0;
		end else begin
			iters = iters + running;
		end
	end
	
	assign neuron_out[1] = !start & !running & !neuron_out[0];
endmodule

module test_all_images;
	reg clk = 0;
	reg [783:0] pixels = 0;
	reg start = 0;
	wire [1:0] neuron_out;
	reg [1:0] expected_neuron_out = 0;
	reg [$clog2({num_images}) - 1:0] guessed_neuron_out = 0;

	run_network #(
		.WIDTH(8),
		.HEIGHT(784),
		.WEIGHTS('{{9'd0,9'd260,9'd261,9'd7,9'd0,9'd258,9'd0,9'd273,9'd261,9'd266,9'd2,9'd258,9'd6,9'd2,9'd264,9'd1,9'd260,9'd0,9'd1,9'd260,9'd5,9'd1,9'd0,9'd265,9'd259,9'd260,9'd6,9'd15,9'd0,9'd270,9'd264,9'd5,9'd262,9'd17,9'd266,9'd5,9'd0,9'd259,9'd258,9'd259,9'd4,9'd261,9'd0,9'd261,9'd11,9'd6,9'd1,9'd258,9'd260,9'd3,9'd258,9'd0,9'd260,9'd6,9'd3,9'd1,9'd5,9'd258,9'd258,9'd5,9'd0,9'd3,9'd0,9'd0,9'd266,9'd0,9'd265,9'd264,9'd261,9'd12,9'd4,9'd0,9'd292,9'd288,9'd259,9'd264,9'd0,9'd5,9'd0,9'd3,9'd7,9'd5,9'd258,9'd2,9'd1,9'd1,9'd3,9'd5,9'd264,9'd0,9'd261,9'd257,9'd294,9'd259,9'd305,9'd310,9'd347,9'd281,9'd293,9'd349,9'd330,9'd312,9'd322,9'd267,9'd268,9'd262,9'd4,9'd259,9'd4,9'd261,9'd264,9'd11,9'd257,9'd18,9'd6,9'd2,9'd2,9'd273,9'd268,9'd323,9'd297,9'd332,9'd389,9'd471,9'd509,9'd507,9'd419,9'd473,9'd475,9'd382,9'd399,9'd351,9'd286,9'd277,9'd6,9'd261,9'd8,9'd270,9'd1,9'd7,9'd0,9'd261,9'd0,9'd264,9'd261,9'd40,9'd32,9'd306,9'd35,9'd109,9'd274,9'd291,9'd305,9'd305,9'd10,9'd280,9'd285,9'd345,9'd389,9'd393,9'd436,9'd401,9'd358,9'd344,9'd8,9'd266,9'd257,9'd0,9'd258,9'd259,9'd272,9'd8,9'd75,9'd152,9'd78,9'd262,9'd92,9'd337,9'd268,9'd335,9'd38,9'd43,9'd19,9'd327,9'd305,9'd81,9'd336,9'd327,9'd341,9'd267,9'd56,9'd319,9'd275,9'd0,9'd5,9'd0,9'd266,9'd0,9'd0,9'd58,9'd149,9'd264,9'd17,9'd124,9'd359,9'd120,9'd37,9'd48,9'd310,9'd259,9'd298,9'd26,9'd286,9'd39,9'd85,9'd265,9'd119,9'd39,9'd82,9'd68,9'd331,9'd0,9'd7,9'd12,9'd260,9'd17,9'd52,9'd22,9'd78,9'd0,9'd111,9'd78,9'd62,9'd91,9'd303,9'd271,9'd102,9'd317,9'd29,9'd261,9'd275,9'd86,9'd276,9'd53,9'd271,9'd78,9'd18,9'd68,9'd287,9'd1,9'd4,9'd3,9'd3,9'd10,9'd35,9'd88,9'd107,9'd279,9'd51,9'd26,9'd13,9'd0,9'd327,9'd260,9'd46,9'd53,9'd296,9'd12,9'd31,9'd278,9'd34,9'd60,9'd358,9'd58,9'd23,9'd2,9'd17,9'd3,9'd22,9'd26,9'd8,9'd23,9'd40,9'd15,9'd95,9'd48,9'd68,9'd18,9'd1,9'd136,9'd0,9'd45,9'd285,9'd305,9'd46,9'd120,9'd105,9'd261,9'd55,9'd91,9'd305,9'd37,9'd112,9'd269,9'd25,9'd24,9'd26,9'd6,9'd258,9'd27,9'd76,9'd112,9'd78,9'd261,9'd101,9'd39,9'd57,9'd264,9'd187,9'd95,9'd0,9'd273,9'd104,9'd61,9'd149,9'd141,9'd85,9'd291,9'd78,9'd66,9'd114,9'd57,9'd58,9'd6,9'd267,9'd8,9'd257,9'd17,9'd73,9'd79,9'd56,9'd131,9'd77,9'd117,9'd233,9'd267,9'd328,9'd323,9'd426,9'd280,9'd304,9'd2,9'd30,9'd263,9'd56,9'd308,9'd336,9'd104,9'd109,9'd292,9'd76,9'd0,9'd11,9'd259,9'd259,9'd9,9'd30,9'd54,9'd48,9'd101,9'd299,9'd263,9'd298,9'd98,9'd118,9'd316,9'd504,9'd436,9'd337,9'd95,9'd286,9'd309,9'd282,9'd281,9'd56,9'd92,9'd101,9'd55,9'd25,9'd268,9'd4,9'd10,9'd4,9'd3,9'd11,9'd25,9'd42,9'd72,9'd28,9'd116,9'd20,9'd96,9'd73,9'd276,9'd355,9'd314,9'd296,9'd363,9'd302,9'd83,9'd64,9'd96,9'd54,9'd348,9'd86,9'd9,9'd20,9'd0,9'd0,9'd267,9'd266,9'd2,9'd257,9'd69,9'd11,9'd263,9'd47,9'd55,9'd19,9'd307,9'd101,9'd60,9'd374,9'd318,9'd330,9'd34,9'd288,9'd32,9'd57,9'd26,9'd301,9'd23,9'd56,9'd294,9'd313,9'd7,9'd261,9'd4,9'd0,9'd258,9'd266,9'd270,9'd5,9'd50,9'd133,9'd68,9'd70,9'd264,9'd278,9'd273,9'd340,9'd363,9'd51,9'd46,9'd135,9'd70,9'd271,9'd274,9'd333,9'd264,9'd324,9'd351,9'd324,9'd0,9'd0,9'd0,9'd6,9'd257,9'd263,9'd354,9'd343,9'd377,9'd21,9'd0,9'd296,9'd45,9'd312,9'd33,9'd298,9'd96,9'd121,9'd100,9'd147,9'd348,9'd267,9'd331,9'd265,9'd0,9'd273,9'd278,9'd79,9'd25,9'd257,9'd262,9'd6,9'd5,9'd263,9'd351,9'd391,9'd365,9'd401,9'd384,9'd296,9'd294,9'd329,9'd1,9'd306,9'd45,9'd53,9'd306,9'd395,9'd330,9'd96,9'd372,9'd57,9'd291,9'd312,9'd85,9'd73,9'd1,9'd265,9'd1,9'd7,9'd264,9'd261,9'd321,9'd370,9'd476,9'd352,9'd4,9'd26,9'd308,9'd78,9'd255,9'd302,9'd306,9'd282,9'd328,9'd283,9'd265,9'd333,9'd332,9'd294,9'd327,9'd357,9'd87,9'd120,9'd259,9'd261,9'd262,9'd259,9'd1,9'd265,9'd319,9'd449,9'd407,9'd381,9'd352,9'd284,9'd322,9'd53,9'd112,9'd88,9'd16,9'd306,9'd312,9'd283,9'd362,9'd404,9'd372,9'd397,9'd428,9'd472,9'd10,9'd52,9'd263,9'd261,9'd263,9'd257,9'd7,9'd319,9'd367,9'd407,9'd410,9'd321,9'd456,9'd351,9'd35,9'd260,9'd123,9'd108,9'd8,9'd326,9'd325,9'd364,9'd310,9'd449,9'd378,9'd415,9'd340,9'd409,9'd304,9'd259,9'd3,9'd260,9'd0,9'd0,9'd258,9'd277,9'd369,9'd395,9'd106,9'd289,9'd345,9'd351,9'd302,9'd446,9'd385,9'd42,9'd27,9'd285,9'd31,9'd359,9'd379,9'd343,9'd299,9'd365,9'd363,9'd365,9'd289,9'd11,9'd0,9'd4,9'd1,9'd9,9'd257,9'd4,9'd342,9'd295,9'd308,9'd31,9'd36,9'd389,9'd285,9'd302,9'd364,9'd257,9'd263,9'd294,9'd311,9'd16,9'd315,9'd299,9'd318,9'd267,9'd318,9'd294,9'd299,9'd269,9'd265,9'd0,9'd260,9'd3,9'd261,9'd268,9'd285,9'd326,9'd19,9'd303,9'd0,9'd81,9'd329,9'd339,9'd328,9'd372,9'd91,9'd39,9'd306,9'd34,9'd30,9'd68,9'd25,9'd277,9'd279,9'd270,9'd282,9'd0,9'd258,9'd260,9'd3,9'd257,9'd262,9'd6,9'd261,9'd71,9'd35,9'd382,9'd267,9'd331,9'd294,9'd300,9'd38,9'd407,9'd375,9'd310,9'd35,9'd316,9'd55,9'd258,9'd298,9'd28,9'd68,9'd10,9'd1,9'd3,9'd264,9'd0,9'd3,9'd1,9'd257,9'd267,9'd258,9'd265,9'd3,9'd313,9'd285,9'd25,9'd8,9'd21,9'd17,9'd18,9'd37,9'd55,9'd266,9'd266,9'd272,9'd9,9'd25,9'd3,9'd7,9'd0,9'd10,9'd1,9'd4,9'd9,9'd6,9'd17,9'd0,9'd6,9'd8,9'd261,9'd0,9'd0,9'd5,9'd265,9'd11,9'd25,9'd0,9'd12,9'd23,9'd24,9'd44,9'd15,9'd8,9'd1,9'd5,9'd9,9'd8,9'd271,9'd12,9'd1,9'd3,9'd14,9'd3}})
	) SNN (
		.clk(clk),
		.pixels(pixels),
		.start(start),
		.neuron_out(neuron_out)
	);

	initial begin
		integer i;
		integer j;
		for (j = 0; j < {num_images}; j = j + 1) begin
			// set pixels
			{{}}

					 
			#50;
			start = 1;
			#50;
			start = 0;
			
			for (i = 0; i < 810000; i = i + 1) begin
				#50 clk = !clk;
			end clk = 0;

			// update guess count
			if (expected_neuron_out == neuron_out) begin
				guessed_neuron_out = guessed_neuron_out + 1;
			end
		end
	end
endmodule
"""

    # add each test image
    in_string = f"""
        if (j == 0) begin
            pixels = 784'b{image_to_bits(images[0])};
            expected_neuron_out = {1 if labels[0] else 2};
        {{}}
    """

    for i, (image, label) in enumerate(zip(images[1:], labels[1:]), 1):
        in_string = in_string.format(
            f"""end else if (j == {i}) begin
            pixels = 784'b{image_to_bits(image)};
            expected_neuron_out = {1 if label else 2};
        {{}}"""
        )
    in_string = in_string.format('end')

    # add test images to base module string and write to SystemVerilog file
    final_string = re.sub('\{\}', in_string, base)
    with open(r'code.sv', 'w') as f:#r'..\Arduino\MKRVIDOR4000\projects\JTAG_Interface\run_network.sv', 'w') as f:
        f.write(final_string)
