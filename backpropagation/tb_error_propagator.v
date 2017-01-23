`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:01:04 01/23/2017
// Design Name:   error_propagator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_error_propagator.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: error_propagator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_error_propagator;
    parameter MATRIX_WIDTH      = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT     = 5,  // height of the weight matrix aka the number of rows and size of vector
              VECTOR_CELL_WIDTH = 8,  // width of each vector cell in bits
              MATRIX_CELL_WIDTH = 8,  // widht of each matrix cell in bits
              NEURON_ADDR_WIDTH = 10, // activations from neurons before the sigmoid
              ACTIVATION_WIDTH  = 9,  // width after sigmoid
              TILING_ROW        = 3,  // number of vector_mac units to create
              TILING_COL        = 3;  // number of multipliers per vector_mac unit

    //define the log2 function
    function integer log2;
        input integer num;
        integer i, result;
        begin
            for (i = 0; 2 ** i < num; i = i + 1)
                result = i + 1;
            log2 = result;
        end
    endfunction
    //
    
    localparam VECTOR_WIDTH = MATRIX_HEIGHT;
    localparam MVM_RESULT_WIDTH = VECTOR_CELL_WIDTH + MATRIX_CELL_WIDTH + log2(VECTOR_WIDTH) + 1;
    localparam RESULT_WIDTH = MVM_RESULT_WIDTH + ACTIVATION_WIDTH;

	// Inputs
	reg clk;
	reg rst;
	reg                                                    start;
	reg [VECTOR_WIDTH*VECTOR_CELL_WIDTH-1:0]               delta_input;
	reg [MATRIX_WIDTH*NEURON_ADDR_WIDTH-1:0]               z;
	reg [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] w;

	// Outputs
	wire [MATRIX_WIDTH*RESULT_WIDTH-1:0] delta_output;
	wire valid;

    // Memory
    wire [RESULT_WIDTH-1:0] delta_output_mem [MATRIX_WIDTH-1:0];
    genvar i;
    for (i=0; i<MATRIX_WIDTH; i=i+1) begin: MEM
        assign delta_output_mem[i] = delta_output[i*RESULT_WIDTH+:RESULT_WIDTH];
    end


	// Instantiate the Unit Under Test (UUT)
    error_propagator #(
        .MATRIX_WIDTH     (MATRIX_WIDTH     ),
        .MATRIX_HEIGHT    (MATRIX_HEIGHT    ),
        .VECTOR_CELL_WIDTH(VECTOR_CELL_WIDTH),
        .MATRIX_CELL_WIDTH(MATRIX_CELL_WIDTH),
        .NEURON_ADDR_WIDTH(NEURON_ADDR_WIDTH),
        .ACTIVATION_WIDTH (ACTIVATION_WIDTH ),
        .TILING_ROW       (TILING_ROW       ),
        .TILING_COL       (TILING_COL       )
    ) 
    uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.delta_input(delta_input), 
		.z(z), 
		.w(w), 
		.delta_output(delta_output), 
		.valid(valid)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		//delta_input = {8'd50,  8'd40,  8'd30,  8'd20,   8'd10}; // 10, 20, 30, 40, 50
		delta_input = {8'd1,  8'd1,  8'd1,  8'd1,   8'd1}; // 10, 20, 30, 40, 50
		//z = {10'd100, 10'd300,  10'd500, -10'd700,  10'd900};  // 5,  4,  3,  2,  1
		z = {10'd120, 10'd185, 10'd220, 10'd250, 10'd260};  // 5,  4,  3,  2,  1
		//w = {8'd101,  8'd100,  8'd99,  8'd98,  8'd97,  8'd96,  8'd95,  8'd94,  8'd93,  8'd92,  8'd91,  8'd90,  8'd89,  8'd88,  8'd87,  8'd86,  8'd85,  8'd84,  8'd83,  8'd82,  8'd81,  8'd80,  8'd79,  8'd78,  8'd77,  8'd76,  8'd75,  8'd74,  8'd73,  8'd72,  8'd71,  8'd70,  8'd69,  8'd68,  8'd67,  8'd66,  8'd65,  8'd64,  8'd63,  8'd62,  8'd61,  8'd60,  8'd59,  8'd58,  8'd57,  8'd56,  8'd55,  8'd54,  8'd53,  8'd52,  8'd51,  8'd50,  8'd49,  8'd48,  8'd47,  8'd46,  8'd45,  8'd44,  8'd43,  8'd42,  8'd41,  8'd40,  8'd39,  8'd38,  8'd37,  8'd36,  8'd35,  8'd34,  8'd33,  8'd32,  8'd31,  8'd30,  8'd29,  8'd28,  8'd27,  8'd26,  8'd25,  8'd24,  8'd23,  8'd22,  8'd21,  8'd20,  8'd19,  8'd18,  8'd17,  8'd16,  8'd15,  8'd14,  8'd13,  8'd12,  8'd11,  8'd10,  8'd9,  8'd8,  8'd7,  8'd6,  8'd5,  8'd4,  8'd3,  8'd2, 8'd1};
        w = {8'd20, 8'd19, 8'd18, 8'd17, 8'd16, 8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        
        // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be 
        // 
        // // output should be [ 120.,  165.,  200.,  225.]

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

