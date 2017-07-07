module forward #(
    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10, // size of neuron sum
              ACTIVATION_WIDTH    = 9,  // size of the neuron's activation
              LAYER_ADDR_WIDTH    = 2,  // width of the layer number 
              LAYER_MAX           = 0,  // number of layers in the network
              WEIGHT_CELL_WIDTH   = 16, // weight width, counting fractions
              FRACTION            = 0   // bits spent on the fraction part in fixed point notation
) (
    input clk,
    input rst,
    // number of neurons in the current layer
    input [log2(NEURON_NUM):0]                          curr_neurons, 
    input                                               curr_neurons_valid,
    output                                              curr_neurons_ready,
    // number of neurons in the previous layer
    input [log2(NEURON_NUM):0]                          prev_neurons, 
    input                                               prev_neurons_valid,
    output                                              prev_neurons_ready,
    // input layer values
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]             start_inputs, 
    input                                               start_inputs_valid,
    output                                              start_inputs_ready,
    // weights for this layer
    input [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights,
    input                                               weights_valid,
    output                                              weights_ready,
    // current layer number 
    input [LAYER_ADDR_WIDTH-1:0]                        layer_number,
    input                                               layer_number_valid,
    output                                              layer_number_ready,
    // outputs from the layer module
    output [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]         current_layer_outputs,
    output                                              overflow,
    output                                              current_layer_outputs_valid,
    input                                               current_layer_outputs_ready
);

    `include "log2.v"

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] layer_inputs;
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] layer_outputs, layer_outputs_1, layer_outputs_2; 
    wire layer_outputs_valid, layer_outputs_ready, layer_inputs_valid, layer_inputs_ready;
    wire layer_outputs_1_valid, layer_outputs_1_ready, layer_outputs_2_valid, layer_outputs_2_ready;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Datapath
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    layer #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ), 
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION           (FRACTION           )
    ) layer (
        .clk               (clk                ),
        .rst               (rst                ),
        .curr_neurons      (curr_neurons       ),
        .curr_neurons_valid(curr_neurons_valid ),
        .curr_neurons_ready(curr_neurons_ready ),
        .prev_neurons      (prev_neurons       ),
        .prev_neurons_valid(prev_neurons_valid ),
        .prev_neurons_ready(prev_neurons_ready ),
        .inputs            (layer_inputs       ),
        .inputs_valid      (layer_inputs_valid ),
        .inputs_ready      (layer_inputs_ready ),
        .weights           (weights            ),
        .weights_valid     (weights_valid      ),
        .weights_ready     (weights_ready      ),
        .outputs           (layer_outputs      ),
        .overflow          (overflow           ),
        .outputs_valid     (layer_outputs_valid),
        .outputs_ready     (layer_outputs_ready)
    );

    
    fifo_splitter2 #(NEURON_NUM*NEURON_OUTPUT_WIDTH) 
    splitter (
        .clk            (clk                  ),
        .rst            (rst                  ),
        .data_in        (layer_outputs        ),
        .data_in_valid  (layer_outputs_valid  ),
        .data_in_ready  (layer_outputs_ready  ),
        .data_out1      (layer_outputs_1      ),
        .data_out1_valid(layer_outputs_1_valid),
        .data_out1_ready(layer_outputs_1_ready),
        .data_out2      (layer_outputs_2      ),
        .data_out2_valid(layer_outputs_2_valid),
        .data_out2_ready(layer_outputs_2_ready)
    );


    layer_controller #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          )
    ) layer_controller (
        .clk                (clk                  ),
        .rst                (rst                  ),
        .start_inputs       (start_inputs         ),
        .start_inputs_valid (start_inputs_valid   ),
        .start_inputs_ready (start_inputs_ready   ),
        .layer_number       (layer_number         ),
        .layer_number_valid (layer_number_valid   ),
        .layer_number_ready (layer_number_ready   ),
        .layer_outputs      (layer_outputs_2      ),
        .layer_outputs_valid(layer_outputs_2_valid),
        .layer_outputs_ready(layer_outputs_2_ready),
        .layer_inputs       (layer_inputs         ),
        .layer_inputs_valid (layer_inputs_valid   ),
        .layer_inputs_ready (layer_inputs_ready   )
    );
  
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    assign current_layer_outputs       = layer_outputs_1;
    assign current_layer_outputs_valid = layer_outputs_1_valid;
    assign layer_outputs_1_ready       = current_layer_outputs_ready;


endmodule
