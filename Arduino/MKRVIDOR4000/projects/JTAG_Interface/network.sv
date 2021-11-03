module network
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter bit [WIDTH:0] WEIGHTS [HEIGHT - 1:0] = '{9'd60, 9'd60, 9'd60, 9'd260, 9'd260, 9'd260, 9'd260}
)
(
	input wire clk,  // clock signal
	input wire rst,  // active low reset signal
	input wire [HEIGHT - 1:0] pixels,  // binary inputs
	output neuron_out  // binary output
);
	wire slow_clk;
	wire stim;
	reg [HEIGHT - 1:0] pixels_out_pos = 0;
	reg [HEIGHT - 1:0] pixels_out_neg = 0;
	wire [HEIGHT - 1:0] pixels_out;
	wire [HEIGHT - 1:0] tmp;
	
	divide_clock #(.DENOM(HEIGHT)) DC (
		.clk(clk),
		.rst(rst),
		.clk_out(slow_clk)
	);
	
	stim S (
		.clk(slow_clk),
		.rst(rst),
		.stim_out(stim)
	);
	
	genvar i;
	generate
		for (i = 0; i < HEIGHT; i = i + 1) begin : generate_block
			if (WEIGHTS[i][WIDTH]) begin
				divider #(.WIDTH(WIDTH)) Dneg (
					.clk(stim & pixels[i]),
					.rst(rst),
					.w(WEIGHTS[i][WIDTH - 1:0]),
					.neuron_out(pixels_out_neg[i])
				);
			end else if (WEIGHTS[i] != 0) begin			
				divider #(.WIDTH(WIDTH)) Dpos (
					.clk(stim & pixels[i]),
					.rst(rst),
					.w(WEIGHTS[i][WIDTH - 1:0]),
					.neuron_out(tmp[i])
				);
				delay De (
					.clk(slow_clk),
					.rst(rst),
					.signal(tmp[i]),
					.neuron_out(pixels_out_pos[i])
				);
			end
		end
	endgenerate

	output2 #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) Out (
		.clk(clk),
		.rst(rst),
		.inputs(pixels_out),
		.neuron_out(neuron_out)
	);
	
	assign pixels_out = (stim * ~pixels_out_neg) | pixels_out_pos;
endmodule


module testbench_network;
	reg clk = 1;
	reg rst = 1;
	reg [6:0] pixels = 7'b0101010;
	wire neuron_out;
	
	network N (
		.clk(clk),
		.rst(rst),
		.pixels(pixels),
		.neuron_out(neuron_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < (1024 * 7 * 2); i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
