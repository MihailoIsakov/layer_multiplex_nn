`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:33:12 02/22/2017
// Design Name:   top
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_top.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_top;

    parameter NEURON_NUM          = 4,
              NEURON_OUTPUT_WIDTH = 12,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              DELTA_CELL_WIDTH    = 9,
              FRACTION            = 8,
              DATASET_ADDR_WIDTH  = 10,
              MAX_SAMPLES         = 1000,
              LAYER_ADDR_WIDTH    = 2,
              LEARNING_RATE_SHIFT = 0,
              LAYER_MAX           = 2,
              WEIGHT_INIT_FILE    = "weights4x4.list",
              INPUT_SAMPLES_FILE  = "inputs4.list",
              OUTPUT_SAMPLES_FILE = "targets4.list";

    reg clk, rst;


    top #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .FRACTION           (FRACTION           ),
        .DATASET_ADDR_WIDTH (DATASET_ADDR_WIDTH ),
        .MAX_SAMPLES        (MAX_SAMPLES        ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   ),
        .INPUT_SAMPLES_FILE (INPUT_SAMPLES_FILE ),
        .OUTPUT_SAMPLES_FILE(OUTPUT_SAMPLES_FILE)
    ) top (
        .clk(clk),
        .rst(rst)
    );


    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;

        #20 rst <= 0;

    end


endmodule

