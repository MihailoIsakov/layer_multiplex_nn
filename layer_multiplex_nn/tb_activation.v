`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:27:20 01/02/2017
// Design Name:   activation
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_activation.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: activation
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_activation;

	// Inputs
	reg clk;
	reg rst;
	reg enable;
	reg [59:0] inputs;
	reg [5:0] inputs_valid;
	reg [5:0] active;

	// Outputs
	wire [47:0] outputs;
	wire [5:0] outputs_valid;
    wire [7:0] activations_mem [5:0];

    genvar i;
    generate
        for (i=0; i<6; i=i+1) begin: FOR_LOOP
            assign activations_mem[i] = outputs[i*8+:8];
        end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	activation uut (
		.clk(clk), 
		.rst(rst), 
		.enable(enable), 
		.inputs(inputs), 
		.inputs_valid(inputs_valid), 
		.active(active), 
		.outputs(outputs), 
		.outputs_valid(outputs_valid)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		enable = 0;
		inputs = 0;
		inputs_valid = 0;
		active = 0;


        #20 rst = 1;
        #20 rst = 0;

        #20 enable = 1;
            inputs = {
                10'd0,
                10'd200,
                10'd400,
                10'd600,
                10'd800,
                10'd1023
            };
            inputs_valid = 6'b001111;
            active       = 6'b010111;

        #20 inputs = {
                10'd1023,
                10'd800,
                10'd600,
                10'd400,
                10'd200,
                10'd0
            };
            active       = 6'b110010;
            inputs_valid = 6'b101010;


	end
      
endmodule

