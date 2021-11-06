module divide_clock
#(
	parameter DENOM = 2  // constant denominator
)
(
	input wire clk,
	input wire rst,
	output wire clk_out
);
	reg [$clog2(DENOM):0] num = 2 * DENOM - 1;  // numerator
	
	always @(posedge clk, negedge rst) begin
		if (!rst) begin
			num = 2 * DENOM - 1;
		end else begin
			if (num == (2 * DENOM - 1)) begin
				num = 0;
			end else begin
				num = num + 1;
			end
		end
	end
	
	assign clk_out = num < DENOM;
endmodule


module testbench_divide_clock;
	reg rst = 1;
	reg clk = 0;
	wire clk_out;
	
	divide_clock #(.DENOM(33)) DC (
		.clk(clk),
		.rst(rst),
		.clk_out(clk_out)
	);
	
	initial begin
		integer i;
		for (i = 0; i < 100; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 1;
		rst = 0;
		#50 clk = 0;
		rst = 1;
		for (i = 0; i < 1200; i = i + 1) begin
			#50 clk = !clk;
		end
		#50 clk = 1;
		rst = 0;
		#50 clk = 0;
		rst = 1;
		for (i = 0; i < 1023; i = i + 1) begin
			#50 clk = !clk;
		end
	end
endmodule