module output2
#(
	parameter WIDTH = 8,
	parameter HEIGHT = 7,
	parameter NUM_POS_WEIGHTS = 3
)
(
	input wire clk,
	input wire rst,
	input wire [HEIGHT - 1:0] inputs,
	output neuron_out,
	output [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance_out
);
	
	// reg [$clog2(HEIGHT * (2 ** WIDTH - 1) + 1) - 1:0] balance = NUM_POS_WEIGHTS * (2 ** WIDTH - 1); //2 ** $clog2(HEIGHT * (2 ** WIDTH)) - HEIGHT * (2 ** WIDTH);
	reg [13:0] balance = NUM_POS_WEIGHTS * (2 ** WIDTH - 1);
	reg [$clog2(HEIGHT) - 1:0] idx = HEIGHT - 1;
	reg [$clog2(HEIGHT * 4 + 1) - 1:0] cnt = 0;
	
	integer i;	
	always @(posedge clk, negedge rst) begin
		if (!rst) begin			
			balance = NUM_POS_WEIGHTS * (2 ** WIDTH - 1); // 2 ** $clog2(HEIGHT * (2 ** WIDTH)) - HEIGHT * (2 ** WIDTH);
			idx = HEIGHT - 1;
			cnt = 0;
		end else if (cnt == (HEIGHT * 4)) begin
			if (idx == (HEIGHT - 1)) begin
				idx = 0;
			end else begin
				idx = idx + 1;
			end
			
			if (balance != HEIGHT * (2 ** WIDTH - 1)) begin  // has not yet overflowed
				balance = balance + inputs[idx];
			end
		end else begin
			cnt = cnt + 1;
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
		.inputs(inputs),
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
