module neuron
#(
    parameter NUM_INPUTS = 5,
    parameter INPUT_SIZE = 9,
    parameter WEIGHT_SIZE = 17,
    parameter OUTPUT_SIZE = 10,
    parameter WEIGHT_FRACTION = 8,
    parameter INPUT_FRACTION = 8,
    parameter FRACTION_BITS = 7
)
(
    input clk,
    input rst,
    input start,
    input [NUM_INPUTS*INPUT_SIZE-1:0] inputs,
    input [NUM_INPUTS*WEIGHT_SIZE-1:0] weights,
    output [OUTPUT_SIZE-1:0] out_value,
    output out_valid
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

    // rewire the large vector into a wire memory
    wire signed [WEIGHT_SIZE-1:0] weights_mem [NUM_INPUTS-1:0];
    wire signed [INPUT_SIZE-1:0]  inputs_mem  [NUM_INPUTS-1:0];
    genvar i;
    generate
    for (i=0; i<NUM_INPUTS; i=i+1) begin : MEMS
        assign weights_mem[i] = weights[WEIGHT_SIZE*i+:WEIGHT_SIZE];
        assign inputs_mem[i]  = inputs[INPUT_SIZE*i+:INPUT_SIZE];
    end
    endgenerate
    //
    
    localparam SUM_SIZE = INPUT_SIZE+WEIGHT_SIZE+log2(NUM_INPUTS);
    localparam SIGNIFICANT = WEIGHT_FRACTION + INPUT_FRACTION - FRACTION_BITS;
    localparam FUNCTION_RANGE_HIGH = 8;
    localparam FUNCTION_RANGE_LOW  = -8;

    reg signed [SUM_SIZE-1:0] sum;

    localparam IDLE = 0, RUN = 1;

    reg busy;
    reg state;
    reg buffer_valid;

    // the next input to be processed
    reg [log2(NUM_INPUTS)-1:0] counter;

    always @ (posedge clk) begin
        if (rst) begin
            counter      <= 0;
            sum          <= 0;
            busy         <= 0;
            state        <= IDLE;
            buffer_valid <= 0;
        end
        else begin
            if (state == IDLE) begin
                if (start) begin
                    buffer_valid <= 0;
                    busy         <= 1; 
                    counter      <= 0;
                    sum          <= 0;
                    state        <= RUN;
                end
                else begin
                    buffer_valid <= buffer_valid;
                    busy         <= 0; 
                    counter      <= counter;
                    sum          <= sum;
                    state        <= IDLE;
                end
            end
            else if (state == RUN) begin
                if (counter == (NUM_INPUTS - 1)) begin
                    buffer_valid <= 1;
                    state   <= IDLE;
                end
                else begin
                    buffer_valid <= 0;
                    state <= RUN;
                end
                busy    <= 1;
                counter <= counter + 1;
                sum     <= sum + $signed(inputs_mem[counter]) * $signed(weights_mem[counter]);
            end
        end
    end

    // output signals
    assign out_valid = buffer_valid;

    // if the sum is larger than 8 or smaller than -8,  set address manually to 255/0
    assign out_value = (sum > (FUNCTION_RANGE_HIGH <<< (WEIGHT_FRACTION + INPUT_FRACTION))) ? {OUTPUT_SIZE{1'b1}} 
                     : (sum < (FUNCTION_RANGE_LOW  <<< (WEIGHT_FRACTION + INPUT_FRACTION))) ? 0
                     : ((sum >>> SIGNIFICANT) + (1 << (OUTPUT_SIZE - 1)));

endmodule

