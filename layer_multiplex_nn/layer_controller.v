module layer_controller
#(
    parameter NUM_NEURON = 6,
              INPUT_SIZE = 9,      // width of the input signals
              WEIGHT_SIZE = 17,    // width of the weight signals
              OUTPUT_SIZE = 10,    // width of the output signal 
              INPUT_FRACTION = 8,  // number of bits below the radix point in the input
              WEIGHT_FRACTION = 8, // number of bits below the radix point in the weight
              FRACTION_BITS = 7,   // for the output of OUTPUT_SIZE, FRACTION_BITS is the number of bits 
                                   // below the radix point that are taken into account
              LAYER_MAX = 4,
              ADDR_SIZE = 10,
              WEIGHTS_INIT = "weights.list"
)
(
    input clk,
    input rst,
    input                             start,           // start signal received from the outside
    input [NUM_NEURON*INPUT_SIZE-1:0] start_input,     // outside input received at the start
    input [NUM_NEURON*ADDR_SIZE-1:0]  layer_output,
    input [NUM_NEURON-1:0]            layer_output_valid,
    output                                         layer_start,
    output [NUM_NEURON-1:0]                        active,
    output [NUM_NEURON*INPUT_SIZE-1:0]             layer_input,
    output [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] layer_weights,
    output [NUM_NEURON*INPUT_SIZE-1:0]             final_output   
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
    wire [log2(LAYER_MAX):0]          layer_num;
    //wire [NUM_NEURON*INPUT_SIZE-1:0]  final_output;

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
        .final_output(final_output)
    );


    output_aggregator #(
        .NUM_NEURON(NUM_NEURON),
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

