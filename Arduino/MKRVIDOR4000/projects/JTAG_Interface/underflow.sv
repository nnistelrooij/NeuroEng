module underflow(
	input wire clk,
	output wire [2:0] under
);
	reg [2:0] under2 = 3'b111;
	
	always @(posedge clk) begin
		under2 = under2 - 3;
	end
	
	assign under = under2;
endmodule

module testbench_underflow;
	reg clk = 0;
	wire [2:0] under;
	
	underflow U (
		.clk(clk),
		.under(under)
	);
	
	integer i;
	initial begin
		for (i = 0; i < 100; i = i + 1) begin
			#50;
			clk = !clk;
		end
	end
endmodule