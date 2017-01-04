`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:02:18 01/03/2017 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top
#(
    parameter LAYER_MAX = 4,
              NUM_NEURON = 6,      // max number of neurons
              INPUT_SIZE = 9,      // width of the input signals
              WEIGHT_SIZE = 17,    // width of the weight signals
              ADDR_SIZE = 10,
              WEIGHTS_INIT = "weights612.list",
    parameter [NUM_NEURON*LAYER_MAX-1:0] LAYER_SIZES = {6'b101010, 6'b111010, 6'b111110, 6'b111111}
)
(
    input clk,
    input rst,
    input start,
    input [NUM_NEURON*INPUT_SIZE-1:0]  start_input,     // outside input received at the start
    output [NUM_NEURON*INPUT_SIZE-1:0] final_output,
    output [NUM_NEURON-1:0]            final_output_valid
);

   
    wire [NUM_NEURON-1:0]                        active;
    wire [NUM_NEURON*INPUT_SIZE-1:0]             layer_input;
    wire [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] layer_weights;
    wire [NUM_NEURON*ADDR_SIZE-1:0]              layer_output;
    wire [NUM_NEURON-1:0]                        layer_output_valid;
    wire                                         layer_start;

    layer_controller #(
        .NUM_NEURON(NUM_NEURON), .INPUT_SIZE(INPUT_SIZE), .WEIGHT_SIZE(WEIGHT_SIZE), .OUTPUT_SIZE(ADDR_SIZE), 
        .LAYER_MAX(LAYER_MAX), .ADDR_SIZE(ADDR_SIZE), .WEIGHTS_INIT(WEIGHTS_INIT)
    )
    layer_controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .start_input(start_input),
        .layer_output(layer_output),
        .layer_output_valid(layer_output_valid),
        .layer_start(layer_start),
        .active(active),
        .layer_input(layer_input),
        .layer_weights(layer_weights)
    );

    layer #(.NUM_NEURON(NUM_NEURON), .NUM_INPUTS(NUM_NEURON), .INPUT_SIZE(INPUT_SIZE), .WEIGHT_SIZE(WEIGHT_SIZE), .OUTPUT_SIZE(ADDR_SIZE))
    layer (
        .clk(clk),
        .rst(rst),
        .start(layer_start),
        .active(active),
        .inputs(layer_input),
        .weights(layer_weights),
        .out_values(layer_output),
        .out_valid(layer_output_valid)
    );
    
    // outputs
    assign final_output = layer_input;

endmodule
