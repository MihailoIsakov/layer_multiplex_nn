//////////////////////////////////////////////////////////////////////////////////
// Company:        ASCS Lab, Boston University
// Engineer:       Mihailo Isakov
// 
// Create Date:    00:02:18 01/03/2017 
// Design Name:    
// Module Name:    top 
// Project Name:   Layer-multiplexed neural network
// Target Devices: 
// Tool versions: 
// Description:    Receives the start inputs and signal, connects to layer module and feeds the correct inputs and 
// start signals to the layer. Input_aggregator prepares the inputs and weights to the layer, and output_aggregator 
// processes outputs from the layer. 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module layer_controller
#(
    parameter NUM_NEURON = 6,               // number of neurons to be synthesized
              INPUT_SIZE = 9,               // width of the input signals
              WEIGHT_SIZE = 17,             // width of the weight signals
              OUTPUT_SIZE = 10,             // width of the output signal 
              LAYER_MAX = 4,                // number of layers
              ADDR_SIZE = 10,               // size of the outputs from the layer's neurons
              WEIGHTS_INIT = "weights.list" // file containing initialization values for the BRAM
)
(
    input clk,
    input rst,
    input                             start,              // start signal received from the outside
    input [NUM_NEURON*INPUT_SIZE-1:0] start_input,        // outside input received at the start
    input [NUM_NEURON*ADDR_SIZE-1:0]  layer_output,       // input from previous layer, in case the layer is > 1
    input [NUM_NEURON-1:0]            layer_output_valid, //validity of layer's inputs
    output                                         layer_start,        // start signal sent to neurons
    output [NUM_NEURON-1:0]                        active,             // activation signal to each neuron
    output [NUM_NEURON*INPUT_SIZE-1:0]             layer_input,        // inputs sent to all neurons
    output [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] layer_weights,      // weights sent to neurons, each neuron has different weights
    output [NUM_NEURON*INPUT_SIZE-1:0]             final_output,       // final output when the layer counter is LAYER_MAX
    output                                         final_output_valid  // 1 bit validity of the final output
);

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

    wire [NUM_NEURON*INPUT_SIZE-1:0]  OA_output;
    wire [NUM_NEURON-1:0]             OA_output_valid;
    wire [log2(LAYER_MAX):0]          layer_num;  // number of the current layer, generated in input_aggregator

    input_aggregator #(
        .LAYER_MAX(LAYER_MAX),
        .NUM_NEURON(NUM_NEURON),
        .INPUT_SIZE(INPUT_SIZE),
        .WEIGHT_SIZE(WEIGHT_SIZE),
        .WEIGHTS_INIT(WEIGHTS_INIT)
    )
    IA (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .start_input(start_input), 
        .layer_input(OA_output), 
        .layer_input_valid(OA_output_valid), 
        .out_inputs(layer_input), 
        .out_weights(layer_weights), 
        .active(active), 
        .layer_num(layer_num), 
        .layer_start(layer_start),
        .final_output(final_output),
        .final_output_valid(final_output_valid)
    );


    output_aggregator #(
        .NUM_NEURON(NUM_NEURON),
        .ADDR_SIZE(ADDR_SIZE),
        .VALUE_SIZE(INPUT_SIZE)
    )
    OA (
        .clk(clk), 
        .rst(rst), 
        .inputs_values(layer_output), 
        .inputs_valid(layer_output_valid), 
        .outputs_values(OA_output), 
        .outputs_valid(OA_output_valid)
    );
endmodule

