`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:54:53 01/15/2017
// Design Name:   activation_stack
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_stack.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: activation_stack
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_stack;
    parameter NEURON_NUM       = 6, 
              ACTIVATION_WIDTH = 8,
              STACK_ADDR_WIDTH = 10;
    localparam STACK_WIDTH = NEURON_NUM*ACTIVATION_WIDTH; 

    reg clk; 
    // one write port - data
    reg  [STACK_WIDTH-1:0]      input_data;
    reg                         input_data_valid;
    wire                        input_data_ready;
    // one write port - addr
    reg  [STACK_ADDR_WIDTH-1:0] input_addr;
    reg                         input_addr_valid;
    wire                        input_addr_ready;
    // two read ports - addr
    reg  [STACK_ADDR_WIDTH-1:0] output_addr;
    reg                         output_addr_valid;
    wire                        output_addr_ready;
    // first read port
    wire [STACK_WIDTH-1:0]      output_data_lower;
    wire                        output_data_lower_valid;
    reg                         output_data_lower_ready;
    // second read port 
    wire [STACK_WIDTH-1:0]      output_data_higher;
    wire                        output_data_higher_valid;
    reg                         output_data_higher_ready;

	// Instantiate the Unit Under Test (UUT)
	activation_stack #(
        .NEURON_NUM(NEURON_NUM),
        .ACTIVATION_WIDTH(ACTIVATION_WIDTH),
        .STACK_ADDR_WIDTH(STACK_ADDR_WIDTH)
    ) uut (
        .clk                     (clk                     ),
        .input_data              (input_data              ),
        .input_data_valid        (input_data_valid        ),
        .input_data_ready        (input_data_ready        ),
        .input_addr              (input_addr              ),
        .input_addr_valid        (input_addr_valid        ),
        .input_addr_ready        (input_addr_ready        ),
        .output_addr             (output_addr             ),
        .output_addr_valid       (output_addr_valid       ),
        .output_addr_ready       (output_addr_ready       ),
        .output_data_lower       (output_data_lower       ),
        .output_data_lower_valid (output_data_lower_valid ),
        .output_data_lower_ready (output_data_lower_ready ),
        .output_data_higher      (output_data_higher      ),
        .output_data_higher_valid(output_data_higher_valid),
        .output_data_higher_ready(output_data_higher_ready)
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;

		input_data       <= 0;
        input_data_valid <= 0;

		input_addr       <= 0;
		input_addr_valid <= 0;

		output_addr       <= 0;
		output_addr_valid <= 0;

        output_data_lower_ready  <= 1;
        output_data_higher_ready <= 1;


        #1 
        #10 input_addr_valid <= 1;
            input_data_valid <= 1;
            input_addr       <= 0;
            input_data       <= 100;
        #2  input_addr_valid <= 0;
            input_data_valid <= 0;

        #10 input_addr_valid <= 1;
            input_data_valid <= 1;
            input_addr       <= 1;
            input_data       <= 200;
        #2  input_addr_valid <= 0;
            input_data_valid <= 0;

        #10 input_addr_valid <= 1;
            input_data_valid <= 1;
            input_addr       <= 2;
            input_data       <= 300;
        #2  input_addr_valid <= 0;
            input_data_valid <= 0;

        #10 input_addr_valid <= 1;
            input_data_valid <= 1;
            input_addr       <= 3;
            input_data       <= 400;
        #2  input_addr_valid <= 0;
            input_data_valid <= 0;


        #20 output_addr       <= 0;
            output_addr_valid <= 1;
        #2  output_addr_valid <= 0;

        #20 output_addr       <= 1;
            output_addr_valid <= 1;
        #2  output_addr_valid <= 0;

        #20 output_addr       <= 2;
            output_addr_valid <= 1;
        #2  output_addr_valid <= 0;

        #20 output_addr       <= 3;
            output_addr_valid <= 1;
        #2  output_addr_valid <= 0;


    end

endmodule
