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
			spike = 0;
			membrane_potential = 0;
		end else begin
			spike = (2 ** WIDTH - 1) - membrane_potential <= w;
			membrane_potential = membrane_potential + w + spike;
		end
	end
	
	assign neuron_out = clk & spike;
endmodule


module testbench_divider;
	reg clk = 0;
	reg rst = 0;
	wire neuron_out;

	divider #(.WIDTH(8)) D (
		.clk(clk),
		.rst(rst),
		.w(8'd255),
		.neuron_out(neuron_out)
	);

	initial begin
		integer i;
	   #200
		rst = 1;
		#50;
		for (i = 0; i < 10000; i = i + 1) begin
			#50 clk = !clk;
		end
		rst = 0;
		#50;
		rst = 1;
		#50;
		for (i = 0; i < 10000; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule
