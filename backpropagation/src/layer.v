module layer #(
    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              FRACTION            = 0
) (
    input clk,
    input rst,

    input [log2(NEURON_NUM):0]                          curr_neurons, // number of neurons in the current layer
    input                                               curr_neurons_valid,
    output                                              curr_neurons_ready,

    input [log2(NEURON_NUM):0]                          prev_neurons, // number of neurons in the previous layer 
    input                                               prev_neurons_valid,
    output                                              prev_neurons_ready,

    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]             inputs,       // inputs from the previous layer
    input                                               inputs_valid,
    output                                              inputs_ready,

    input [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights,      // layer weights
    input                                               weights_valid,
    output                                              weights_ready,

    output [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]         outputs,      // outputs of the current neurons
    output                                              overflow,     // overflow of any neuron
    output                                              outputs_valid,
    input                                               outputs_ready
);

    `include "log2.v"

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Registers & wires
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    reg [log2(NEURON_NUM):0] curr_neurons_buffer;
    wire [NEURON_NUM-1:0] overflows; 
    wire [NEURON_NUM-1:0] prev_neurons_readys, inputs_readys, weights_readys, outputs_valids;

    // FIXME ugly synchronization, but should work well under assumption all neurons behave the same 
    wire all_ready = prev_neurons_valid && curr_neurons_valid && inputs_valid && weights_valid && 
                     &prev_neurons_readys && &inputs_readys && &weights_readys;

    wire all_done = &outputs_valids;
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Neurons
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: NEURONS
        neuron #(
            .NEURON_NUM         (NEURON_NUM         ),
            .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
            .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
            .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
            .FRACTION           (FRACTION           )
        ) neuron (
            .clk               (clk                                                                  ),
            .rst               (rst                                                                  ),
            // prev neurons #
            .input_number      (prev_neurons                                                         ),
            .input_number_valid(all_ready && prev_neurons_valid                                      ),
            .input_number_ready(prev_neurons_readys[i]                                               ),
            // input values
            .inputs            (inputs                                                               ),
            .inputs_valid      (all_ready && inputs_valid                                            ),
            .inputs_ready      (inputs_readys[i]                                                     ),
            // weights values
            .weights           (weights[i*NEURON_NUM*WEIGHT_CELL_WIDTH+:NEURON_NUM*WEIGHT_CELL_WIDTH]),
            .weights_valid     (all_ready && weights_valid                                           ),
            .weights_ready     (weights_readys[i]                                                    ),
            // neuron outputs
            .neuron_sum        (outputs[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH]                  ),
            .overflow          (overflows[i]                                                         ),
            .neuron_sum_valid  (outputs_valids[i]                                                    ),
            .neuron_sum_ready  (all_done && outputs_ready                                            )
        );  
    end
    endgenerate 

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // State machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state               <= IDLE;
            curr_neurons_buffer <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state               <= all_ready ? CALC : IDLE;
                    curr_neurons_buffer <= all_ready ? curr_neurons : curr_neurons_buffer;
                end
                CALC: begin
                    state               <= all_done ? DONE : CALC;
                    curr_neurons_buffer <= curr_neurons_buffer;
                end
                DONE: begin
                    state               <= outputs_ready ? IDLE : DONE;
                    curr_neurons_buffer <= 0;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    assign prev_neurons_ready = all_ready;
    assign curr_neurons_ready = all_ready;
    assign inputs_ready       = all_ready;
    assign weights_ready      = all_ready; 
    assign overflow           = |overflows;
    assign outputs_valid      = all_done;

endmodule
