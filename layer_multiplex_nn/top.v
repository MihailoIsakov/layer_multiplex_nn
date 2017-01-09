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
    parameter LAYER_MAX       = 3,
              NUM_NEURON      = 7,      // max number of neurons
              WEIGHTS_INIT    = "weights.list"
              INPUT_SIZE      = 9,      // width of the input signals
              WEIGHT_SIZE     = 17,    // width of the weight signals
              ADDR_SIZE       = 10,
              INPUT_FRACTION  = 8,  // number of bits below the radix point in the input
              WEIGHT_FRACTION = 8, // number of bits below the radix point in the weight
              FRACTION_BITS   = 6    // for the output of OUTPUT_SIZE, FRACTION_BITS is the number of bits 
                                   // below the radix point that are taken into account
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
    // output wires
    wire [NUM_NEURON*INPUT_SIZE-1:0] final_output_wire;
    wire [NUM_NEURON-1:0]            final_output_valid_wire;

    layer_controller #(
        .NUM_NEURON(NUM_NEURON), 
        .INPUT_SIZE(INPUT_SIZE), 
        .WEIGHT_SIZE(WEIGHT_SIZE), 
        .OUTPUT_SIZE(ADDR_SIZE), 
        .LAYER_MAX(LAYER_MAX), 
        .ADDR_SIZE(ADDR_SIZE), 
        .WEIGHTS_INIT(WEIGHTS_INIT)
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
        .layer_weights(layer_weights),
        .final_output(final_output_wire),
        .final_output_valid(final_output_valid_wire) 
    );

    layer #(
        .NUM_NEURON(NUM_NEURON), 
        .NUM_INPUTS(NUM_NEURON), 
        .INPUT_SIZE(INPUT_SIZE), 
        .WEIGHT_SIZE(WEIGHT_SIZE), 
        .OUTPUT_SIZE(ADDR_SIZE),
        .INPUT_FRACTION(INPUT_FRACTION),
        .WEIGHT_FRACTION(WEIGHT_FRACTION),
        .FRACTION_BITS(FRACTION_BITS)
    )
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
    assign final_output = final_output_wire;
    assign final_output_valid = final_output_valid_wire;

endmodule
