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

    parameter MATRIX_WIDTH       = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT      = 5,  // height of the weight matrix aka the number of rows and size of vector
              DELTA_CELL_WIDTH   = 12,  // width of each delta cell in bits
              WEIGHTS_CELL_WIDTH = 8,  // widht of each matrix cell in bits
              NEURON_ADDR_WIDTH  = 10, // width of activations from neurons before the sigmoid
              ACTIVATION_WIDTH   = 9,  // cell width after sigmoid
              FRACTION_WIDTH     = 1,
              LAYER_ADDR_WIDTH   = 2,
              TILING_ROW         = 3,  // number of vector_mac units to create
              TILING_COL         = 3;  // number of multipliers per vector_mac unit


	// Inputs
	reg clk;
	reg rst;

    // layer 
    reg [LAYER_ADDR_WIDTH-1:0]                              layer;
    reg                                                     layer_valid;
    wire                                                    layer_ready;

    // delta input
	reg [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0]                 delta_input;
    reg                                                     delta_input_valid;
    wire                                                    delta_input_ready;
    
    // z
	reg [MATRIX_HEIGHT*NEURON_ADDR_WIDTH-1:0]               z;
    reg                                                     z_valid;
    wire                                                    z_ready;

    // w
	reg [MATRIX_WIDTH*MATRIX_HEIGHT*WEIGHTS_CELL_WIDTH-1:0] w;
    reg                                                     w_valid;
    wire                                                    w_ready;

	// delta output
	wire [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0]                delta_output;
    wire                                                    delta_output_valid;
    reg                                                     delta_output_ready;

	wire error;

    // Memory
    wire [DELTA_CELL_WIDTH-1:0] delta_output_mem [MATRIX_HEIGHT-1:0];
    genvar i;
    for (i=0; i<MATRIX_HEIGHT; i=i+1) begin: MEM
        assign delta_output_mem[i] = delta_output[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end


	// Instantiate the Unit Under Test (UUT)
    error_propagator #(
        .MATRIX_WIDTH      (MATRIX_WIDTH      ),
        .MATRIX_HEIGHT     (MATRIX_HEIGHT     ),
        .DELTA_CELL_WIDTH  (DELTA_CELL_WIDTH  ),
        .WEIGHTS_CELL_WIDTH(WEIGHTS_CELL_WIDTH),
        .NEURON_ADDR_WIDTH (NEURON_ADDR_WIDTH ),
        .ACTIVATION_WIDTH  (ACTIVATION_WIDTH  ),
        .FRACTION_WIDTH    (FRACTION_WIDTH    ),
        .TILING_ROW        (TILING_ROW        ),
        .TILING_COL        (TILING_COL        ),
        .LAYER_ADDR_WIDTH  (LAYER_ADDR_WIDTH  )
    ) uut (
		.clk         (clk         ),
		.rst         (rst         ),
        .layer             (layer             ),
        .layer_valid       (layer_valid       ),
        .layer_ready       (layer_ready       ),
        .delta_input       (delta_input       ),
        .delta_input_valid (delta_input_valid ),
        .delta_input_ready (delta_input_ready ),
        .z                 (z                 ),
        .z_valid           (z_valid           ),
        .z_ready           (z_ready           ),
        .w                 (w                 ),
        .w_valid           (w_valid           ),
        .w_ready           (w_ready           ),
        .delta_output      (delta_output      ),
        .delta_output_valid(delta_output_valid),
        .delta_output_ready(delta_output_ready),
        .error             (error             )
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk                    <= 0;
		rst                    <= 1;
        layer                  <= 3;
        layer_valid            <= 0;
		delta_input            <= {12'd1, 12'd1, 12'd1, 12'd1}; // 10, 20, 30, 40, 50
        delta_input_valid      <= 0;
		z                      <= {10'd270, 10'd250, 10'd230, 10'd220, 10'd200};  // 4,  3,  2,  1
        z_valid                <= 0;
        w                      <= {8'd20, 8'd19, 8'd18, 8'd17, 8'd16, 8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        w_valid                <= 0;
        // [  45.,  100.,  165.,  240.]
        delta_output_ready     <= 0;

        #20 rst                <= 0;

        // LAYER 2
        #10 layer <= 2;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        
        // LAYER 1
        #10 layer <= 1;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        
        // LAYER 0
        #10 layer <= 0;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        
        // LAYER 2
        #10 layer <= 2;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        
        // LAYER 0
        #10 layer <= 0;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        
        // LAYER 0
        #10 layer <= 0;
            layer_valid <= 1;
        #2  layer_valid <= 0;

        #10 delta_input_valid  <= 1;
        #2  delta_input_valid  <= 0;

        #10 z_valid            <= 1;
        #2  z_valid            <= 0;

        #10 w_valid            <= 1;
        #2  w_valid            <= 0;

        #40 delta_output_ready <= 1;
        #2  delta_output_ready <= 0;
        

	end
      
endmodule

