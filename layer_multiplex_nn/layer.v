module layer
#(
    parameter NUM_NEURON = 6,
    parameter NUM_INPUTS = 5,      // number of neurons from the previous layer connected to this neuron
    parameter INPUT_SIZE = 9,      // width of the input signals
    parameter WEIGHT_SIZE = 17,    // width of the weight signals
    parameter OUTPUT_SIZE = 10,    // width of the output signal 
    parameter INPUT_FRACTION = 8,  // number of bits below the radix point in the input
    parameter WEIGHT_FRACTION = 8, // number of bits below the radix point in the weight
    parameter FRACTION_BITS = 6    // for the output of OUTPUT_SIZE, FRACTION_BITS is the number of bits 
                                   // below the radix point that are taken into account
)(
    input clk,
    input rst,
    input start,
    input [NUM_NEURON-1:0] active,
    input [NUM_INPUTS*INPUT_SIZE-1:0] inputs,
    input [NUM_NEURON*NUM_INPUTS*WEIGHT_SIZE-1:0] weights,
    output [NUM_NEURON*OUTPUT_SIZE-1:0] out_values,
    output [NUM_NEURON-1:0] out_valid
);

    wire [NUM_NEURON*OUTPUT_SIZE-1:0] values;
    wire [NUM_NEURON-1:0] neuron_valid;
    reg  internal_start; 

    genvar i;
    generate
        for (i=0; i<NUM_NEURON; i=i+1) begin: NEURONS
            neuron #( 
                .NUM_INPUTS(NUM_INPUTS), .INPUT_SIZE(INPUT_SIZE), .WEIGHT_SIZE(WEIGHT_SIZE), .OUTPUT_SIZE(OUTPUT_SIZE),
                .INPUT_FRACTION(INPUT_FRACTION), .WEIGHT_FRACTION(WEIGHT_FRACTION), .FRACTION_BITS(FRACTION_BITS)
            ) 
            neuron (
                .clk(clk),
                .rst(rst),
                .start(internal_start & active[i]),
                .inputs(inputs),
                .weights(weights[i*NUM_INPUTS*WEIGHT_SIZE+:NUM_INPUTS*WEIGHT_SIZE]),
                .out_value(values[i*OUTPUT_SIZE+:OUTPUT_SIZE]),
                .out_valid(neuron_valid[i])
            );
        end
    endgenerate


    localparam IDLE = 0, RUN = 2, DONE=3;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            internal_start <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    if (start) begin
                        state          <= RUN;  
                        internal_start <= 1;
                    end
                    else begin
                        state          <= IDLE;  
                        internal_start <= 0;
                    end
                end
                RUN : begin
                    state          <= DONE;  
                    internal_start <= 0;
                end
                DONE: begin
                    if (~(neuron_valid | ~active) == 0) begin
                        state <= IDLE;
                        internal_start <= 0;
                    end
                    else begin
                        state <= DONE;
                        internal_start <= 0;
                    end
                end
                default: begin
                    state <= IDLE;
                    internal_start <= 0;
                end
            endcase
        end
    end
    
    //output signals
    assign out_valid = neuron_valid; // add register to decrease longest line 
    assign out_values = values;

endmodule
