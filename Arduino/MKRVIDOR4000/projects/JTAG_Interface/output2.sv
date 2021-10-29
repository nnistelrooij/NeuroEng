module output2
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7
)
(
	input wire clk,
	input wire rst,
	input wire [HEIGHT - 1:0] inputs,
	output neuron_out
);
	integer i;
	reg [$clog2(HEIGHT * (2 ** WIDTH - 1)) - 1:0] balance = 2 ** $clog2(HEIGHT * (2 ** WIDTH - 1)) - HEIGHT * (2 ** WIDTH - 1);
	reg [$clog2(HEIGHT) - 1:0] idx = HEIGHT - 1;
	
	always @(posedge clk, negedge rst) begin
		if (!rst) begin
			balance = 2 ** $clog2(HEIGHT * (2 ** WIDTH - 1)) - HEIGHT * (2 ** WIDTH - 1);
			idx = HEIGHT - 1;
		end else begin
			if (idx == (HEIGHT - 1)) begin
				idx = 0;
			end else begin
				idx = idx + 1;
			end
			
			if (balance != 0) begin  // has not yet overflowed
				balance = balance + inputs[idx];
			end
		end
	end
	
	assign neuron_out = balance == 0;
endmodule


module testbench_output;
	reg clk = 0;
	reg rst = 1;
	reg [6:0] inputs = 7'b1100011;
	wire neuron_out;
	
	output2 Out (
		.clk(clk),
		.rst(rst),
		.inputs(inputs),
		.neuron_out(neuron_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < 1024; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 rst = 0;
		#50 rst = 1;		
		for (i = 0; i < 1024; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
