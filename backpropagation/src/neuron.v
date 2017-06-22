module neuron #(
    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              FRACTION            = 0
) (
    input clk,
    input rst,
    input [log2(NEURON_NUM):0]                 input_number, // number of neurons from previous layer
    input                                      input_number_valid,
    output                                     input_number_ready,
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]    inputs,       // values of these inputs
    input                                      inputs_valid,
    output                                     inputs_ready,
    input [NEURON_NUM*WEIGHT_CELL_WIDTH-1  :0] weights,      // values of corresponding weights
    input                                      weights_valid,
    output                                     weights_ready,
    output [NEURON_OUTPUT_WIDTH-1:0]           neuron_sum,   // sum of inputs multiplied by values
    output                                     overflow,     // overflow/underflow flag, paired with neuron sum, read at same time
    output                                     neuron_sum_valid,
    input                                      neuron_sum_ready
);

    `include "log2.v"

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Registers
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    reg [log2(NEURON_NUM)                :0] input_number_buffer;
    reg                                      input_number_set;
    reg [NEURON_NUM*ACTIVATION_WIDTH-1:0]    inputs_buffer;
    reg                                      inputs_set;
    reg [NEURON_NUM*WEIGHT_CELL_WIDTH  -1:0] weights_buffer;
    reg                                      weights_set;

    reg signed [NEURON_OUTPUT_WIDTH+FRACTION-1:0] sum; // current sum of input-weight products
    wire signed [NEURON_OUTPUT_WIDTH-1:0] product;
    reg overflow_buffer;                      // flag indicating an overflow/underflow happened during summing
    wire extra, of, uf;                       // wires used for determining overflow/underflow

    assign of = ({extra, sum[NEURON_OUTPUT_WIDTH-1]} == 2'b01);
    assign uf = ({extra, sum[NEURON_OUTPUT_WIDTH-1]} == 2'b10);
    assign {extra, product} = $signed(inputs_buffer[counter*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]) * $signed(weights_buffer[counter*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH]);

    reg [log2(NEURON_NUM):0] counter;         // current input connection being processed (counter < NEURON_NUM)

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // State machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state               <= IDLE;
            input_number_buffer <= 0;
            input_number_set    <= 0;
            inputs_buffer       <= 0;
            inputs_set          <= 0;
            weights_buffer      <= 0;
            weights_set         <= 0;
            sum                 <= 0;
            overflow_buffer     <= 0;
            counter             <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    state               <= (input_number_set && inputs_set && weights_set) ? CALC : IDLE;
                    input_number_buffer <= (!input_number_set && input_number_valid) ? input_number : input_number_buffer;
                    input_number_set    <= input_number_set || input_number_valid;
                    inputs_buffer       <= (!inputs_set && inputs_valid) ? inputs : inputs_buffer;
                    inputs_set          <= inputs_set || inputs_valid;
                    weights_buffer      <= (!weights_set && weights_valid) ? weights : weights_buffer;
                    weights_set         <= weights_set || weights_valid;
                    sum                 <= 0;
                    overflow_buffer     <= 0;
                    counter             <= 0;
                end
                CALC: begin
                    state               <= (counter == (input_number_buffer - 1)) ? DONE : CALC;
                    input_number_buffer <= input_number_buffer;
                    input_number_set    <= input_number_set;
                    inputs_buffer       <= inputs_buffer;
                    inputs_set          <= inputs_set;
                    weights_buffer      <= weights_buffer;
                    weights_set         <= weights_set;             
                    sum                 <= sum + product;
                    overflow_buffer     <= overflow_buffer || of || uf;
                    counter             <= (counter >= (input_number_buffer - 1)) ? 0    : counter + 1;
                end
                DONE: begin
                    state               <= neuron_sum_ready ? IDLE : DONE;
                    input_number_buffer <= 0;
                    input_number_set    <= 0;
                    inputs_buffer       <= 0; 
                    inputs_set          <= 0; 
                    weights_buffer      <= 0; 
                    weights_set         <= 0; 
                    sum                 <= neuron_sum_ready ? 0    : sum;
                    overflow_buffer     <= neuron_sum_ready ? 0    : overflow;
                    counter             <= 0;
                end
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    assign input_number_ready = !input_number_set;
    assign inputs_ready       = !inputs_set; 
    assign weights_ready      = !weights_set;
    assign neuron_sum         = sum[NEURON_OUTPUT_WIDTH+FRACTION-1:FRACTION]; 
    assign overflow           = overflow_buffer;
    assign neuron_sum_valid   = state == DONE;

endmodule
