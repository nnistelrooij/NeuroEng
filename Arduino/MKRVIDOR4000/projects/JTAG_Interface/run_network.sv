module run_network
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter bit [WIDTH:0] WEIGHTS [HEIGHT - 1:0] = '{9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60, 9'd60}
)
(
	input wire clk,
	input wire [HEIGHT - 1:0] pixels,
	input wire start,
	output wire [1:0] neuron_out
);
	reg rst = 1;
	reg started = 0;
	reg [WIDTH:0] cnt = 0;

	network #(.WIDTH(WIDTH), .HEIGHT(HEIGHT), .WEIGHTS(WEIGHTS)) N (
		.clk(started * clk),
		.rst(rst),
		.pixels(pixels),
		.neuron_out(neuron_out[0])
	);
	
	always @(posedge clk) begin
		if (cnt == (2 ** (WIDTH + 1) - 1)) begin
			started <= 0;
		end else begin
			started <= started | start;
		end
		
		rst = !(rst & start);
		cnt = cnt + started;
	end
	
	assign neuron_out[1] = rst & !started & !neuron_out[0];
endmodule


module testbench_run_network;
	reg clk = 0;
	reg [6:0] pixels = 7'b1111111;
	reg start = 0;
	wire [1:0] neuron_out;
	
	run_network #(.WEIGHTS('{9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260})) RN (
		.clk(clk),
		.pixels(pixels),
		.start(start),
		.neuron_out(neuron_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < 100; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 1;
		start = 1;
		#50 clk = 0;
		start = 0;
		for (i = 0; i < 1200; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 1;
		start = 1;
		#50 clk = 0;
		start = 0;
		for (i = 0; i < 1023; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
