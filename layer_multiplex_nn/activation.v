module activation
#(
    parameter NUM_NEURON    = 6,
              LUT_ADDR_SIZE = 10,
              LUT_DEPTH     = 1 << LUT_ADDR_SIZE,
              LUT_WIDTH     = 9,
              LUT_INIT_FILE = "activations.list"
) (
    input clk,
    input rst,
    input [NUM_NEURON*LUT_ADDR_SIZE-1:0] inputs,
    output [NUM_NEURON*LUT_WIDTH-1:0]    outputs,
    output                               stable
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

    // inputs into memory, used for testing /////////////////////
    wire [LUT_ADDR_SIZE-1:0]  inputs_mem [NUM_NEURON-1:0];
    wire [LUT_ADDR_SIZE-1:0]  outputs_mem [NUM_NEURON-1:0];
    genvar i;
    generate
    for (i=0; i<NUM_NEURON; i=i+1) begin: MEM_INPUTS
        assign inputs_mem[i] = inputs[i*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
        assign outputs_mem[i] = outputs[i*LUT_WIDTH+:LUT_WIDTH];
    end
    endgenerate 
    /////////////////////////////////////////////////////////////

    reg                     read;
    reg [LUT_ADDR_SIZE-1:0] read_address;
    wire [LUT_WIDTH-1:0]    read_value;
    BRAM #(.DATA_WIDTH(LUT_WIDTH), .ADDR_WIDTH(LUT_ADDR_SIZE), .INIT_FILE(LUT_INIT_FILE)) 
        activation_bram (clk, read, read_address, read_value, 1'b0, 2'b0, 612'b0);

    reg [log2(NUM_NEURON):0]           counter, counter_old1, counter_old2; // can be one bigger than necessary, since log2 rounds down
    reg [NUM_NEURON*LUT_ADDR_SIZE-1:0] inputs_buffer;
    reg [NUM_NEURON*LUT_WIDTH-1:0]     outputs_buffer;
    reg stable_buffer;

    always @ (posedge clk) begin
        if (rst) begin
            counter        <= 0;
            counter_old1   <= 0;
            counter_old2   <= 0;
            inputs_buffer  <= {NUM_NEURON*LUT_ADDR_SIZE{1'b1}}; // to avoid the case when inputs are 0 and stable goes up
            outputs_buffer <= 0;
            stable_buffer  <= 0;
            read_address   <= 0;
            read           <= 1; // always read
        end
        else begin
            {counter, counter_old1, counter_old2} <= {((counter == NUM_NEURON-1) ? 0 : counter + 1), counter, counter_old1};
            inputs_buffer[counter_old1*LUT_ADDR_SIZE+:LUT_ADDR_SIZE]  <= inputs[counter_old1*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
            outputs_buffer[counter_old2*LUT_WIDTH+:LUT_WIDTH]         <= read_value;
            read_address                                              <= inputs[counter*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
            stable_buffer                                             <= (inputs == inputs_buffer);
        end
    end

    // outputs
    assign outputs = outputs_buffer;
    assign stable = stable_buffer; // when the inputs settle and are processed, raise stable

endmodule

