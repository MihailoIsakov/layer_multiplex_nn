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
// start signals to the layer. Input_aggregator prepares the inputs to the layer, and output_aggregator 
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
    parameter NUM_NEURON = 6,   // number of neurons to be synthesized
              INPUT_SIZE = 9,   // width of the input signals
              OUTPUT_SIZE = 10, // width of the output signal 
              LAYER_MAX = 4,    // number of layers
              ADDR_SIZE = 10    // size of the outputs from the layer's neurons
)
(
    input clk,
    input rst,
    input                              start,              // start signal received from the outside
    input [NUM_NEURON*INPUT_SIZE-1:0]  start_input,        // input layer values
    input [log2(LAYER_MAX):0]          layer_number,       // layer number, goes from 0 to LAYER_MAX-1
    input [NUM_NEURON*ADDR_SIZE-1:0]   layer_output,       // input from previous layer, in case the layer number is > 1
    input [NUM_NEURON-1:0]             layer_output_valid, // validity of layer's inputs
    output                             layer_start,        // start signal sent to neurons
    output [NUM_NEURON-1:0]            active,             // activation signal to each neuron
    output [NUM_NEURON*INPUT_SIZE-1:0] layer_input,        // inputs sent to all neurons
    output [NUM_NEURON*INPUT_SIZE-1:0] outputs,            // values of neurons when the layer is done
    output                             outputs_valid       // outputs valid
);

    `include "../log2.v"

    wire [NUM_NEURON*INPUT_SIZE-1:0]  OA_output;
    wire [NUM_NEURON-1:0]             OA_output_valid;

    input_aggregator #(
        .LAYER_MAX(LAYER_MAX),
        .NUM_NEURON(NUM_NEURON),
        .INPUT_SIZE(INPUT_SIZE)
    )
    IA (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .start_input(start_input), 
        .layer(layer_number),
        .layer_input(OA_output), 
        .layer_input_valid(OA_output_valid), 
        .out_inputs(layer_input), 
        .active(active), 
        .layer_start(layer_start)
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

    localparam IDLE=0, RUN=1;
    reg state;
    reg valid_buffer;

    reg OA_valid, OA_valid_prev;
    always @ (posedge clk) begin
        if (OA_output_valid == active && OA_valid_prev != active)
            OA_valid = 1;
        else 
            OA_valid = 0;
        OA_valid_prev = OA_output_valid;
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            valid_buffer <= 0;
        end
        else case(state)
            IDLE: begin
                state        <= start ? RUN : IDLE;
                valid_buffer <= start ? 0   : valid_buffer;
            end
            RUN: begin
                state        <= OA_valid ? IDLE : RUN;
                valid_buffer <= OA_valid ? 1    : 0;
            end
            default: begin
                state        <= IDLE;
                valid_buffer <= 0;
            end
        endcase
    end
    
    assign outputs       = OA_output;
    assign outputs_valid = valid_buffer;

endmodule

