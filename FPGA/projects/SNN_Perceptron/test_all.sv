module test_all (
	input wire clk,
	input wire [6:0] pixels,
	input wire NEXT,
	input wire FINISH,
	output wire start_SNN2,
	output wire [1:0] neurons_out,
	output wire [10:0] balance_out,
	output wire [9:0] reg_offset2,
	output wire progressed2,
	output wire [1:0] status2
);	
	reg [31:0] DATA [0:13] = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
	reg [799:0] IMAGE; // Room for 800 bits of data (25*32 bits)

	reg start_SNN = 0;  // spike to reset and start SNN
	wire slow_clock;
	divide_clock #(.DENOM(2)) DC (
		.clk(clk),
		.rst(!start_SNN),
		.clk_out(slow_clock)
	);

	reg [1:0] status = 0; // status to finish and reset in order
	run_network #(
		.WIDTH(8),
		.HEIGHT(7),
		.WEIGHTS('{9'd255, 9'd257, 9'd511, 9'd260, 9'd260, 9'd257, 9'd511})
	) SNN (
		.clk((status == 0) & slow_clock),
		.pixels(pixels),
		.start(clk & start_SNN),
		.neuron_out(neurons_out),
		.balance_out(balance_out)
	);


	reg [9:0] reg_offset = 0;  // which pixel is being written
	reg progressed = 0;  // whether we have written something in IMAGE


	integer i;
	integer j;
	always @(posedge clk) begin
		if (NEXT && !progressed) begin
			status = 1;
			progressed = 1;
			for (i = 0; i < 14; i = i + 1) begin
				reg_offset = 448 * FINISH + 32 * i;
				if (!FINISH || i < 11) begin
					for (j = 0; j < 32; j = j + 1) begin
						IMAGE[reg_offset + j] <= DATA[i][j];
					end
				end
			end
		end else if (!NEXT) begin
			progressed = 0;
		end
		
		if (FINISH && reg_offset > 0) begin
			reg_offset = 0;
			status = 2;
		end else if (status == 2) begin
			start_SNN = 1;
			status = 3;
		end else if (status == 3) begin
			start_SNN = 0;
			status = 0;
		end
	end
	
	assign start_SNN2 = start_SNN;
	assign progressed2 = progressed;
	assign reg_offset2 = reg_offset;
	assign status2 = status;
endmodule


module testbench_test_all;
	reg clk = 1;
	reg NEXT;
	reg FINISH = 0;
	reg [6:0] pixels = 7'b0000111;
	wire [1:0] neurons_out;
	wire start_SNN;
	wire [9:0] reg_offset;
	wire progressed;
	wire [10:0] balance_out;
	wire [1:0] status;
	
	test_all TA (
		.clk(clk),
		.pixels(pixels),
		.NEXT(NEXT),
		.FINISH(FINISH),
		.start_SNN2(start_SNN),
		.neurons_out(neurons_out),
		.reg_offset2(reg_offset),
		.progressed2(progressed),
		.balance_out(balance_out),
		.status2(status)
	);
	
	initial begin
		integer i;
		#100;
		NEXT = 0;
		for (i = 0; i < 100; i = i + 1) begin
			#50;
			clk = !clk;
		end
		NEXT = 1;
		#50;
		clk = !clk;
		#50
		clk = !clk;
		NEXT = 0;
		for (i = 0; i < 100; i = i + 1) begin
			#50;
			clk = !clk;
		end
		NEXT = 1;
		FINISH = 1;
		for (i = 0; i < 30000; i = i + 1) begin
			#50;
			clk = !clk;
		end	
		
		NEXT = 0;
		FINISH = 0;
		for (i = 0; i < 100; i = i + 1) begin
			#50;
			clk = !clk;
		end
		pixels = 7'b1111111;
		NEXT = 1;
		#50;
		clk = !clk;
		#50
		clk = !clk;
		NEXT = 0;
		for (i = 0; i < 100; i = i + 1) begin
			#50;
			clk = !clk;
		end
		NEXT = 1;
		FINISH = 1;
		for (i = 0; i < 30000; i = i + 1) begin
			#50;
			clk = !clk;
		end	
	end
endmodule
