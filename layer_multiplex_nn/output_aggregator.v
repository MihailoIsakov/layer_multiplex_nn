module output_aggregator
#(
    parameter NUM_NEURON = 6,
              ADDR_SIZE = 10,    // width of the output signal 
              VALUE_SIZE = 9
)
(
    input clk,
    input rst,
    input [NUM_NEURON*ADDR_SIZE-1:0]   inputs_values,  // inputs from the layer's neurons
    input [NUM_NEURON-1:0]             inputs_valid,   // validity of the neuron's outputs
    output [NUM_NEURON*VALUE_SIZE-1:0] outputs_values, // values passed through the sigmoid activation
    output [NUM_NEURON-1:0]            outputs_valid   // their validity
);

    reg [NUM_NEURON*VALUE_SIZE-1:0] outputs_buffer;
    reg [NUM_NEURON-1:0]            valid_buffer;  

    wire                             lut_stable;
    wire [NUM_NEURON*VALUE_SIZE-1:0] lut_outputs;
    activation #(
        .NUM_NEURON(NUM_NEURON), 
        .LUT_ADDR_SIZE(ADDR_SIZE), 
        .LUT_DEPTH(1<<ADDR_SIZE), 
        .LUT_WIDTH(VALUE_SIZE)
    )
    activation (
        .clk(clk), 
        .rst(rst), 
        .inputs(inputs_values), 
        .outputs(lut_outputs), 
        .stable(lut_stable)
    );

    always @ (posedge clk) begin
        if (rst) begin
            outputs_buffer <= 0;
            valid_buffer   <= 0;
        end
        else begin
            outputs_buffer <= lut_outputs ;
            valid_buffer   <= (lut_stable) ? inputs_valid : 0;
        end
    end

    // outputs
    assign outputs_valid  = valid_buffer;
    assign outputs_values = outputs_buffer;

endmodule
