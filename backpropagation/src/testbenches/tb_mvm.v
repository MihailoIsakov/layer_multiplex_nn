`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:17:48 01/22/2017
// Design Name:   mvm
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_mvm.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mvm
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_mvm;

    `include "log2.v"

    parameter MATRIX_WIDTH      = 20, // width of the matrix aka the number of columns
              MATRIX_HEIGHT     = 5, // height of the matrix aka the number of rows and size of vector
              VECTOR_CELL_WIDTH = 8, // width of each vector cell in bits
              MATRIX_CELL_WIDTH = 8, // widht of each matrix cell in bits
              RESULT_CELL_WIDTH = 12, // width of each result cell in bits
              FRACTION_WIDTH    = 4,
              TILING_ROW        = 3, // number of vector_mac units to create
              TILING_COL        = 2;  // number of multipliers per vector_mac unit

    localparam VECTOR_WIDTH = MATRIX_HEIGHT;

	reg clk;
	reg rst;

    // vector signals
	reg [MATRIX_HEIGHT*VECTOR_CELL_WIDTH-1:0] vector;
    reg                                       vector_valid;
    wire                                      vector_ready;

    // matrix signals
	reg [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] matrix;
    reg                                                    matrix_valid;
    wire                                                   matrix_ready;

    // result signals
	wire [MATRIX_WIDTH*RESULT_CELL_WIDTH-1:0] result;
    wire                                      result_valid;
    reg                                       result_ready;
    wire                                      error;

    // Memories
    wire [RESULT_CELL_WIDTH-1:0] result_mem [0:MATRIX_WIDTH-1];
    genvar i;
    generate
    for (i=0; i<MATRIX_WIDTH; i=i+1) begin: MEM
        assign result_mem[i] = result[i*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH];
    end
    endgenerate


    mvm #(
    .MATRIX_WIDTH     (MATRIX_WIDTH     ),
    .MATRIX_HEIGHT    (MATRIX_HEIGHT    ),
    .VECTOR_CELL_WIDTH(VECTOR_CELL_WIDTH),
    .MATRIX_CELL_WIDTH(MATRIX_CELL_WIDTH),
    .RESULT_CELL_WIDTH(RESULT_CELL_WIDTH),
    .FRACTION_WIDTH   (FRACTION_WIDTH   ),
    .TILING_ROW       (TILING_ROW       ),
    .TILING_COL       (TILING_COL       )
    ) mvm (
        .clk         (clk         ),
        .rst         (rst         ),
        .vector      (vector      ),
        .vector_valid(vector_valid),
        .vector_ready(vector_ready),
        .matrix      (matrix      ),
        .matrix_valid(matrix_valid),
        .matrix_ready(matrix_ready),
        .result      (result      ),
        .result_valid(result_valid),
        .result_ready(result_ready),
        .error       (error       )
    );

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;
        vector_valid <= 0;
        matrix_valid <= 0;
        result_ready <= 0;

		vector <= {8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        vector_valid <= 0;

		matrix <= {8'd101,  8'd100,  8'd99,  8'd98,  8'd97,  8'd96,  8'd95,  8'd94,  8'd93,  8'd92,  8'd91,  8'd90,  8'd89,  8'd88,  8'd87,  8'd86,  8'd85,  8'd84,  8'd83,  8'd82,  8'd81,  8'd80,  8'd79,  8'd78,  8'd77,  8'd76,  8'd75,  8'd74,  8'd73,  8'd72,  8'd71,  8'd70,  8'd69,  8'd68,  8'd67,  8'd66,  8'd65,  8'd64,  8'd63,  8'd62,  8'd61,  8'd60,  8'd59,  8'd58,  8'd57,  8'd56,  8'd55,  8'd54,  8'd53,  8'd52,  8'd51,  8'd50,  8'd49,  8'd48,  8'd47,  8'd46,  8'd45,  8'd44,  8'd43,  8'd42,  8'd41,  8'd40,  8'd39,  8'd38,  8'd37,  8'd36,  8'd35,  8'd34,  8'd33,  8'd32,  8'd31,  8'd30,  8'd29,  8'd28,  8'd27,  8'd26,  8'd25,  8'd24,  8'd23,  8'd22,  8'd21,  8'd20,  8'd19,  8'd18,  8'd17,  8'd16,  8'd15,  8'd14,  8'd13,  8'd12,  8'd11,  8'd10,  8'd9,  8'd8,  8'd7,  8'd6,  8'd5,  8'd4,  8'd3,  8'd2, 8'd1};
        matrix_valid <= 0;
        // expected result <= [50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 65, 66, 67, 68]

        
        #20 rst <= 0;

        #20 vector_valid <= 1;
        #10 vector_valid <= 0;
        #20 matrix_valid <= 1;
        #10 matrix_valid <= 0;

        #100 result_ready <= 1;
        
        #100 vector_valid <= 1;
             matrix_valid <= 1;
             result_ready <= 1;

        #500 result_ready  <= 0;

	end
      
endmodule

