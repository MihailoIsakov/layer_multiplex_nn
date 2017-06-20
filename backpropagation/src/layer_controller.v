module layer_controller #(
    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10, // size of neuron sum
              ACTIVATION_WIDTH    = 9,  // size of the neuron's activation
              LAYER_ADDR_WIDTH    = 1,  // width of the layer number 
              LAYER_MAX           = 0   // number of layers in the network
) (
    input clk,
    input rst,
    // input layer values
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]     start_inputs, 
    input                                       start_inputs_valid,
    output                                      start_inputs_ready,
    // current layer number 
    input [LAYER_ADDR_WIDTH-1:0]                layer_number, 
    input                                       layer_number_valid,
    output                                      layer_number_ready,
    // outputs from the layer module, input to this module
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]  layer_outputs,
    input                                       layer_outputs_valid,
    output                                      layer_outputs_ready,
    // inputs to the layer module, output from this module
    output [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] layer_inputs,
    output                                      layer_inputs_valid,
    input                                       layer_inputs_ready
);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] activations, mux_activations, gate_activations;
    wire activations_valid, activations_ready, mux_activations_valid, mux_activations_ready;
    wire gate_activations_valid, gate_activations_ready;

    wire [LAYER_ADDR_WIDTH-1:0] layer_number_1, layer_number_2;
    wire layer_number_1_valid, layer_number_1_ready, layer_number_2_valid, layer_number_2_ready;


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Datapath
    ////////////////////////////////////////////////////////////////////////////////////////////////////


    lut #(
        .NEURON_NUM   (NEURON_NUM         ),
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH   ),
        .LUT_INIT_FILE("sigmoid.list"     )
    ) sigmoid (
        .clk          (clk                ),
        .rst          (rst                ),
        .inputs       (layer_outputs      ),
        .inputs_valid (layer_outputs_valid),
        .inputs_ready (layer_outputs_ready),
        .outputs      (activations        ),
        .outputs_valid(activations_valid  ),
        .outputs_ready(activations_ready  )
    );  


    fifo_splitter2 #(LAYER_ADDR_WIDTH) 
    layer_splitter (
        .clk            (clk),
        .rst            (rst),
        .data_in        (layer_number),
        .data_in_valid  (layer_number_valid),
        .data_in_ready  (layer_number_ready),
        .data_out1      (layer_number_1),
        .data_out1_valid(layer_number_1_valid),
        .data_out1_ready(layer_number_1_ready),
        .data_out2      (layer_number_2),
        .data_out2_valid(layer_number_2_valid),
        .data_out2_ready(layer_number_2_ready)
    );


    fifo_mux2 #(NEURON_NUM*ACTIVATION_WIDTH)
    input_mux (
        .clk         (clk),
        .rst         (rst),
        .a           (start_inputs),
        .a_valid     (start_inputs_valid),
        .a_ready     (start_inputs_ready),
        .b           (activations),
        .b_valid     (activations_valid),
        .b_ready     (activations_ready),
        .select      (layer_number_2!=0),
        .select_valid(layer_number_2_valid),
        .select_ready(layer_number_2_ready),
        .result      (mux_activations),
        .result_valid(mux_activations_valid),
        .result_ready(mux_activations_ready)
    );


    fifo_gate #(NEURON_NUM*ACTIVATION_WIDTH) 
    gate (
        .clk         (clk                      ),
        .rst         (rst                      ),
        .data        (mux_activations          ),
        .data_valid  (mux_activations_valid    ),
        .data_ready  (mux_activations_ready    ),
        .pass        (layer_number_1!=LAYER_MAX),
        .pass_valid  (layer_number_1_valid     ),
        .pass_ready  (layer_number_1_ready     ),
        .result      (gate_activations         ),
        .result_valid(gate_activations_valid   ),
        .result_ready(gate_activations_ready   )
    ); 

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Extend signed values from ACTIVATION_WIDTH to NEURON_OUTPUT_WIDTH
    // The activations are 9 bits wide and always positive (leading 0), so adding 3 zeros in front should work
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////

    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: EXTEND
        assign layer_inputs[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH] = {3'b000, gate_activations[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]};
    end
    endgenerate

    assign layer_inputs_valid = gate_activations_valid;
    assign gate_activations_ready = layer_inputs_ready;

endmodule;
