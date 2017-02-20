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
              INPUT_SIZE   = 9, // width of the input signals
)
(
    input clk,
    input rst, 
    input                                          start,
    input [NUM_NEURON*INPUT_SIZE-1:0]              start_input,     // outside input received at the start
    input [NUM_NEURON*INPUT_SIZE-1:0]              layer_input,       // input received from a layer n
    input [NUM_NEURON-1:0]                         layer_input_valid, // validity of layer input
    output [NUM_NEURON*INPUT_SIZE-1:0]             out_inputs,
    output [NUM_NEURON-1:0]                        active,
    //output [log2(LAYER_MAX):0]                     layer_num,
    output                                         layer_start,
    output reg [NUM_NEURON*INPUT_SIZE-1:0]         final_output,
    output reg                                     final_output_valid
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
    
    reg [NUM_NEURON*LAYER_MAX-1:0]              layer_sizes; 
    reg [NUM_NEURON-1:0]                        active_buffer;
    reg [NUM_NEURON*INPUT_SIZE-1:0]             outputs_buffer;
    reg [log2(LAYER_MAX):0]                     layer;
    reg [1:0]                                   state;
    reg                                         start_out;
    // when IA sends out the start signal, the valid input from OA changes after 3 cycles. 
    // This timer prevents IA to fire multiple times before the signal makes a full circle.
    reg [5:0]                                   timer; 

    localparam IDLE = 0, WAIT = 1, START = 2;
    
    always @ (posedge clk) begin
        if (rst) begin
            active_buffer  <= 0;
            outputs_buffer <= 0; 
            layer          <= 0;
            state          <= IDLE;
            start_out      <= 0;
            timer          <= 0;
            layer_sizes    <= {7'b1111111, 7'b1111111, 7'b1111111, 7'b1111111}; //activation for each neuron, per each layer
            //finals
            final_output       <= 0;
            final_output_valid <= 0;
        end
        else begin
            //active_buffer <= LAYER_SIZES[layer*NUM_NEURON+:NUM_NEURON];
            active_buffer <= layer_sizes[layer*NUM_NEURON+:NUM_NEURON];
            case (state)

                IDLE: begin
                    outputs_buffer <= outputs_buffer;
                    layer       <= 0;
                    state       <= (start) ? START : IDLE;
                    start_out   <= 0;
                end

                START: begin
                    outputs_buffer     <= (layer == 0) ? start_input : layer_input;
                    layer              <= layer;
                    state              <= WAIT;
                    start_out          <= 1;
                    timer              <= 0;
                    final_output       <= 0;
                    final_output_valid <= 0;
                end

                WAIT: begin
                    timer <= timer + 1;
                    if ((layer_input_valid & active_buffer) == active_buffer && timer > 10) begin // FIXME
                        if (layer == LAYER_MAX-1) begin // last layer
                            layer <= 0;
                            state <= IDLE;
                            final_output       <= layer_input;
                            final_output_valid <= 1;
                        end
                        else begin // not last layer
                            layer <= layer + 1;
                            state <= START;
                        end
                        //outputs_buffer <= layer_input;
                        outputs_buffer <= outputs_buffer;
                        start_out      <= 0;
                    end
                    else begin
                        outputs_buffer <= outputs_buffer;
                        layer          <= layer;
                        state          <= WAIT;
                        start_out      <= 0;
                    end
                end

                default: begin
                    outputs_buffer <= outputs_buffer;
                    layer          <= layer;
                    state          <= state;
                    start_out      <= 0;
                end

            endcase 
        end
    end

    // outputs 
    assign out_inputs  = outputs_buffer;
    assign layer_start = start_out;
    //assign layer_num   = layer;
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
