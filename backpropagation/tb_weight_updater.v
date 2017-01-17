`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:06:26 01/17/2017
// Design Name:   weight_updater
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_weight_updater.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: weight_updater
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_weight_updater;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [39:0] a;
	reg [39:0] delta;
	reg [399:0] w;

	// Outputs
	wire [424:0] result;
	wire finish;

    // Memories
    wire [16:0] result_mem [24:0];
    genvar i;
    generate
    for (i=0; i<25; i=i+1) begin: MEM
        assign result_mem[i] = result[i*17+:17];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	weight_updater uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.a(a), 
		.delta(delta), 
		.w(w), 
		.result(result), 
		.finish(finish)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		a = {8'd50, 8'd40, 8'd30, 8'd20, 8'd10}; // 10, 20, 30, 40, 50
		delta = {8'd1,  8'd2,  8'd3,  8'd4,  8'd5};  // 5,  4,  3,  2,  1
		w = {16'd0, 16'd1, 16'd2, 16'd3, 16'd4, 16'd5, 16'd6, 16'd7, 16'd8, 16'd9, 16'd10, 16'd11, 16'd12, 16'd13, 16'd14, 16'd15, 16'd16, 16'd17, 16'd18, 16'd19, 16'd20, 16'd21, 16'd22, 16'd23, 16'd24};

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

