module delay(
	input wire clk,
	input wire rst,
	input wire signal,
	output neuron_out
);
	reg previous_signal = 0;
	reg current_signal = 0;
	
	always @(posedge clk, posedge signal, negedge rst) begin
		current_signal	= rst & signal;
	end
	
	always @(negedge clk, negedge signal, negedge rst) begin
		previous_signal = rst & current_signal;
	end
	
	assign neuron_out = clk & previous_signal;
endmodule


module testbench_delay;
	reg clk = 0;
	reg rst = 1;
	reg signal_tmp = 0;
	wire signal;
	wire neuron_out;
	
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
			if (i & 1'b1 == 1) begin
				signal_tmp = !signal_tmp;
			end
		end
	end
	
	// assign signal = !clk;
	assign signal = clk & signal_tmp;
endmodule
