module run_network
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter NUM_POS_WEIGHTS = 3,
	parameter bit [WIDTH:0] WEIGHTS [0:HEIGHT - 1] = '{9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60}
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


module testbench_run_network;
	reg clk = 0;
	reg [6:0] pixels = 7'b1111111;
	reg start = 0;
	wire [1:0] neuron_out;
	wire [10:0] balance_out;
	wire reset_out;
	
	run_network #(.WEIGHTS('{9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260})) RN (
		.clk(clk),
		.pixels(pixels),
		.start(start),
		.neuron_out(neuron_out),
		.balance_out(balance_out)
		// .reset_out(reset_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < 100; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 0;
		start = 1;
		#50 clk = 1;
		start = 0;
		for (i = 0; i < 8000; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 0;
		pixels = 7'b0000000;
		start = 1;
		#50 clk = 1;
		start = 0;
		for (i = 0; i < 8000; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
