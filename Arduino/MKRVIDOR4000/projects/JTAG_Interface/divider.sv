module divider
#(
	parameter WIDTH = 8
)
(
	input wire clk,
	input wire rst,
	input wire [WIDTH - 1:0] w,
	output neuron_out
);
	reg [WIDTH - 1:0] membrane_potential = 0;
	reg spike = 0;
	
	always @(negedge clk, negedge rst) begin
		if (!rst) begin
			membrane_potential = 0;
			spike = 0;
		end else begin
			if ((2**WIDTH - 1) - membrane_potential <= w) begin
				spike = 1;
				membrane_potential = w - ((2**WIDTH - 1) - membrane_potential);
			end else begin
				spike = 0;
				membrane_potential = membrane_potential + w;
			end
			//membrane_potential = membrane_potential + w;
			//spike = membrane_potential < w;
		end
	end
	
	assign neuron_out = clk & spike;
endmodule


module testbench_divider;
	reg clk = 0;
	reg rst = 1;
	wire neuron_out;

	divider #(.WIDTH(8)) D (
		.clk(clk),
		.rst(rst),
		.w(8'd191),
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
