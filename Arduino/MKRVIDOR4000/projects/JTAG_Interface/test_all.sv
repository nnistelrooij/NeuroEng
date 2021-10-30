module test_all (
	input wire clk,
	input wire [6:0] pixels,
	input wire NEXT,
	input wire FINISH,
	output wire start_SNN2,
	output wire [1:0] neurons_out,
	output wire reg_offset2,
	output wire progressed2
);
	wire [31:0] DATA [13:0] = '{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};  // Data from the JTAG
	wire [1:0] SNN_OUT;  // Data to the JTAG

	reg [799:0] IMAGE; // Room for 800 bits of data (25*32 bits)
	
	reg [9:0] reg_offset = 0;
	integer i;
	integer j;

	reg progressed = 0;
	reg start_SNN = 0;

	run_network #(
		.WIDTH(8),
		.HEIGHT(7),
		.WEIGHTS('{9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260, 9'd260})
	) SNN (
		.clk(clk),
		.pixels(pixels),
		.start(clk & start_SNN),
		.neuron_out(neurons_out)
	);

	always @(posedge clk) begin
		if (NEXT & !progressed) begin
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
		
		if (FINISH & reg_offset > 0) begin
			reg_offset = 0;
			start_SNN = 1;
		end else begin
			start_SNN = 0;
		end
	end
	
	assign start_SNN2 = start_SNN;
	assign progressed2 = progressed;
	assign reg_offset2 = reg_offset;

endmodule


module testbench_test_all;
	reg clk = 0;
	reg NEXT;
	reg FINISH = 0;
	reg [6:0] pixels = 7'b0000000;
	wire [1:0] neurons_out;
	wire start_SNN;
	wire reg_offset;
	wire progressed;
	
	test_all TA (
		.clk(clk),
		.pixels(pixels),
		.NEXT(NEXT),
		.FINISH(FINISH),
		.start_SNN2(start_SNN),
		.neurons_out(neurons_out),
		.reg_offset2(reg_offset),
		.progressed2(progressed)
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
		for (i = 0; i < 15000; i = i + 1) begin
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
		for (i = 0; i < 15000; i = i + 1) begin
			#50;
			clk = !clk;
		end	
	end
endmodule
