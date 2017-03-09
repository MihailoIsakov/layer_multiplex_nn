`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:28:17 01/19/2017
// Design Name:   lut
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_lut.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lut
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_lut;

    parameter NEURON_NUM    = 6,
              LUT_ADDR_SIZE = 10,
              LUT_DEPTH     = 1 << LUT_ADDR_SIZE,
              LUT_WIDTH     = 9,
              LUT_INIT_FILE = "sigmoid.list";

	// Inputs
	reg clk;
	reg rst;

	reg [59:0] inputs;
	reg inputs_valid;
    reg outputs_ready;

	// Outputs
	wire [53:0] outputs;
	wire inputs_ready, outputs_valid;

    // Memory
    wire [8:0] outputs_mem [0:5];
    genvar i;
    generate
    for (i=0; i<6; i=i+1) begin: MEM
        assign outputs_mem[i] = outputs[i*9+:9];
    end
    endgenerate

    lut
    #(
        .NEURON_NUM   (NEURON_NUM   ),
        .LUT_ADDR_SIZE(LUT_ADDR_SIZE),
        .LUT_DEPTH    (LUT_DEPTH    ),
        .LUT_WIDTH    (LUT_WIDTH    ),
        .LUT_INIT_FILE(LUT_INIT_FILE)
    ) lut (
        .clk          (clk          ),
        .rst          (rst          ),
        .inputs       (inputs       ),
        .inputs_valid (inputs_valid ),
        .inputs_ready (inputs_ready ),
        .outputs      (outputs      ),
        .outputs_valid(outputs_valid),
        .outputs_ready(outputs_ready)
    );


    always 
        #1 clk <= ~clk;
    
    initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;
        inputs_valid <= 0;
        outputs_ready <= 0;
		inputs <= {10'd0, 10'd200, 10'd400, 10'd600, 10'd800, 10'd1000};

        #10 rst <= 0;

        #20 inputs_valid <= 1;
        #20 outputs_ready <= 1;
        #20 inputs_valid <= 0;
        #20 outputs_ready <= 0;
	end
      
endmodule

