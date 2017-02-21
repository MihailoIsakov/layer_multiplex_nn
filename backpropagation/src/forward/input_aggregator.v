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
// Description:    Top level module of the desing, connects the outside start input to network, a layer of neurons, 
// and a layer controller. Outputs the activations of neurons in the output layer, with a valid signal.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module input_aggregator
#(
    parameter LAYER_MAX    = 3,
              NUM_NEURON   = 6, // max number of neurons
              INPUT_SIZE   = 9 // width of the input signals
)
(
    input clk,
    input rst, 
    input                                  start,
    input [NUM_NEURON*INPUT_SIZE-1:0]      start_input,     // outside input received at the start
    input [log2(LAYER_MAX):0]              layer,
    input [NUM_NEURON*INPUT_SIZE-1:0]      layer_input,       // input received from a layer n
    input [NUM_NEURON-1:0]                 layer_input_valid, // validity of layer input
    output [NUM_NEURON*INPUT_SIZE-1:0]     out_inputs,        // sent to the layer module
    output [NUM_NEURON-1:0]                active,            // sent to the layer module
    output                                 layer_start,       // sent to the layer module
);

    `include "../log2.v"
    
    reg [NUM_NEURON-1:0] active_buffer;
    reg                  state;
    reg                  layer_start_buffer;
    // when IA sends out the start signal, the valid input from OA changes after 3 cycles. 
    // This timer prevents IA to fire multiple times before the signal makes a full circle.
    reg [5:0]                       timer; 

    localparam IDLE = 0, WAIT = 1;
    
    always @ (posedge clk) begin
        if (rst) begin
            active_buffer  <= 0;
            state          <= IDLE;
            layer_start_buffer      <= 0;
            timer          <= 0;
            active_buffer  <= {NUM_NEURON{1'b1}};
        end
        else begin
            case (state)
                IDLE: begin
                    state              <= start ? WAIT : IDLE;
                    layer_start_buffer <= start ? 1     : 0;
                    timer              <= 0;
                end

                WAIT: begin
                    timer <= timer + 1;
                    if ((layer_input_valid & active_buffer) == active_buffer && timer > 5) begin // FIXME
                        state              <= IDLE;
                        layer_start_buffer <= 0;
                    end
                    else begin
                        state              <= WAIT;
                        layer_start_buffer <= 0;
                    end
                end

                default: begin
                    state              <= IDLE;
                    layer_start_buffer <= 0;
                    timer              <= 0;
                end

            endcase 
        end
    end

    // outputs 
    assign out_inputs = (layer == 0) ? start_input : layer_input;
    assign layer_start = layer_start_buffer;
    assign active      = active_buffer;


    // unpacking inputs for testing purposes ///////////
    //wire [INPUT_SIZE-1:0]  outputs_mem [NUM_NEURON-1:0];
    //genvar i, j;
    //generate
    //for (i=0; i<NUM_NEURON; i=i+1) begin: MEM_INPUTS
        //assign outputs_mem[i] = out_inputs[i*INPUT_SIZE+:INPUT_SIZE];
    //end
    //endgenerate 
    ////////////////////////////////////////////////////////////////

endmodule
