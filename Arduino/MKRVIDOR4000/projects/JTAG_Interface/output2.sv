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
	
	always @(posedge clk, negedge rst) begin
		if (!rst) begin
			balance = 2 ** $clog2(HEIGHT * (2 ** WIDTH - 1)) - HEIGHT * (2 ** WIDTH - 1);
		end else begin
			if (balance >= HEIGHT) begin
				for (i = 0; i < HEIGHT; i = i + 1) begin
					balance = balance + inputs[i];
				end
			end
		end
	end
	
	assign neuron_out = balance < HEIGHT;
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
