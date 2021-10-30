module delay(
	input wire clk,
	input wire rst,
	input wire signal,
	output neuron_out
);
	reg previous_signal = 0;
	reg current_signal = 0;
	
	always @(posedge clk, negedge rst) begin
		current_signal = rst & signal;
	end
	
	always @(negedge clk, negedge rst) begin
		previous_signal = rst & current_signal;
	end
	
	assign neuron_out = clk & previous_signal;
endmodule


module testbench_delay;
	reg clk = 0;
	reg rst = 1;
	wire signal;
	wire neuron_out;
	
	stim S (
		.clk(clk),
		.rst(rst),
		.stim_out(signal)
	);
	
	delay D (
		.clk(clk),
		.rst(rst),
		.signal(signal),
		.neuron_out(neuron_out)
	);
	
	initial begin
		integer i;
		#200
		for (i = 0; i < 100; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
