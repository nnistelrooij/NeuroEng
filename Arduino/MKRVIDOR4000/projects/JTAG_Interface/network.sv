module network
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter NUM_POS_WEIGHTS = 3,
	parameter bit [WIDTH:0] WEIGHTS [0:HEIGHT - 1] = '{9'd60, 9'd60, 9'd60, 9'd260, 9'd260, 9'd260, 9'd260}
)
(
	input wire clk,  // clock signal
	input wire rst,  // active low reset signal
	input wire [HEIGHT - 1:0] pixels,  // binary inputs
	output neuron_out,  // binary output
	output [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance_out,
	output pixel_out_out,
	output reset_out
);
	wire reset_circuit;
	wire pixel_neg;
	wire pixel_pos;
	wire tmp;
	wire pixel_out;
	reg [$clog2(HEIGHT) - 1:0] pixel_idx = 0;
	reg polarity = 0;
	reg [$clog2(2**(WIDTH + 1)) - 1:0] cnt = 0;
	
	stim S (
		.clk(clk),
		.rst(rst & reset_circuit),
		.stim_out(stim)
	);
	
	divider #(.WIDTH(WIDTH)) Dneg (
		.clk(!polarity & stim & pixels[pixel_idx]),
		.rst(rst & reset_circuit),
		.w(WEIGHTS[pixel_idx][WIDTH - 1:0]),
		.neuron_out(pixel_neg)
	);
	
	divider #(.WIDTH(WIDTH)) Dpos (
		.clk(polarity & stim & pixels[pixel_idx]),
		.rst(rst & reset_circuit),
		.w(WEIGHTS[pixel_idx][WIDTH - 1:0]),
		.neuron_out(tmp)
	);
	delay De (
		.clk(clk),
		.rst(rst & reset_circuit),
		.signal(tmp),
		.neuron_out(pixel_pos)
	);
	
	
	
	always @(negedge clk, negedge rst) begin
		if (!rst) begin
			pixel_idx = 0;
			polarity = 0;
			cnt = 0;
		end else begin		
			if (cnt == (2**(WIDTH + 1) - 1)) begin
				pixel_idx = pixel_idx + 1;
				polarity = WEIGHTS[pixel_idx][WIDTH:WIDTH] == 1'b0;
				cnt = 0;
			end else begin
				cnt = cnt + 1;
			end
		end
	end
	
	
	
	assign pixel_out = reset_circuit & ((stim & !pixel_neg) | pixel_pos);
	assign reset_circuit = cnt != 0;
	assign pixel_out_out = pixel_out;
	assign reset_out = reset_circuit;

	output2 #(.WIDTH(WIDTH), .HEIGHT(HEIGHT), .NUM_POS_WEIGHTS(0)) Out (
		.clk(clk),
		.rst(rst),
		.reset_circuit(reset_circuit),
		.pixel(pixel_out),
		.neuron_out(neuron_out),
		.balance_out(balance_out)
	);
endmodule


module testbench_network;
	reg clk = 1;
	reg rst = 1;
	reg [6:0] pixels = 7'b0101010;
	wire neuron_out;
	wire pixel_out;
	wire [10:0] balance_out;
	wire reset_out;
	
	network #(.WEIGHTS('{9'd255, 9'd255, 9'd60, 9'd260, 9'd260, 9'd260, 9'd260})) N (
		.clk(clk),
		.rst(rst),
		.pixels(pixels),
		.neuron_out(neuron_out),
		.balance_out(balance_out),
		.pixel_out_out(pixel_out),
		.reset_out(reset_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < (1024 * 7 * 2); i = i + 1) begin
			#50 clk = !clk;
		end
		pixels = 7'b0000000;
		rst = 0;
		#50;
		rst = 1;		
		for (i = 0; i < (1024 * 7 * 2); i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
