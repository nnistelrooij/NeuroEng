module output2
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7
)
(
	input wire clk,
	input wire rst,
	input wire pixel,
	output neuron_out,
	output [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance_out
);
	reg [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance = 0;
	
	always @(posedge clk, negedge rst) begin
		if (!rst) begin			
			balance = 0;
		end else begin			
			if (balance != HEIGHT * (2 ** WIDTH - 1)) begin  // has not yet overflowed
				balance = balance + pixel;
			end
		end
	end
	
	assign neuron_out = balance == (HEIGHT * (2 ** WIDTH - 1));
	assign balance_out = balance;
endmodule


module testbench_output;
	reg clk = 0;
	reg rst = 1;
	reg [6:0] inputs = 7'b1100011;
	wire neuron_out;
	wire [31:0] balance_out;
	
	output2 Out (
		.clk(clk),
		.rst(rst),
		.pixel(1),
		.neuron_out(neuron_out),
		.balance_out(balance_out)
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
