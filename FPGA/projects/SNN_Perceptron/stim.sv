module stim(
	input wire clk,
	input wire rst,
	output stim_out
);
	reg cnt = 0;
	
	always @(negedge clk, negedge rst) begin
		if (!rst) begin
			cnt = 0;
		end else begin
			cnt = !cnt;
		end
	end
	
	assign stim_out = clk & cnt;
endmodule


module testbench_stim;
	reg clk = 0;
	reg rst = 1;
	wire stim_out;

	stim S (
		.clk(clk),
		.rst(rst),
		.stim_out(stim_out)
	);

	initial begin
		integer i;
	   #200
		for (i = 0; i < 100; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
