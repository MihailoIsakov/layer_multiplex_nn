module activation
#(
    parameter NEURON_NUM    = 6,
              LUT_ADDR_SIZE = 10,
              LUT_DEPTH     = 1 << LUT_ADDR_SIZE,
              LUT_WIDTH     = 9,
              LUT_INIT_FILE = "sigmoid.list"
) (
    input clk,
    input rst,
    input [NEURON_NUM*LUT_ADDR_SIZE-1:0] inputs,  // number of signals from the input
    output [NEURON_NUM*LUT_WIDTH-1:0]    outputs,
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

    reg                     read;
    reg [LUT_ADDR_SIZE-1:0] read_address;
    wire [LUT_WIDTH-1:0]    read_value;
    BRAM #(.DATA_WIDTH(LUT_WIDTH), .ADDR_WIDTH(LUT_ADDR_SIZE), .INIT_FILE(LUT_INIT_FILE)) 
        activation_bram (clk, read, read_address, read_value, 0, 0, 0);

    reg [log2(NEURON_NUM):0]           counter, counter_old1, counter_old2; // can be one bigger than necessary, since log2 rounds down
    reg [NEURON_NUM*LUT_ADDR_SIZE-1:0] inputs_buffer;
    reg [NEURON_NUM*LUT_WIDTH-1:0]     outputs_buffer;
    reg stable_buffer;

    always @ (posedge clk) begin
        if (rst) begin
            counter        <= 0;
            counter_old1   <= 0;
            counter_old2   <= 0;
            inputs_buffer  <= {NEURON_NUM*LUT_ADDR_SIZE{1'b1}}; // to avoid the case when inputs are 0 and stable goes up
            outputs_buffer <= 0;
            stable_buffer  <= 0;
            read_address   <= 0;
            read           <= 1; // always read
        end
        else begin
            {counter, counter_old1, counter_old2} <= {((counter == NEURON_NUM-1) ? 0 : counter + 1), counter, counter_old1};
            inputs_buffer[counter_old1*LUT_ADDR_SIZE+:LUT_ADDR_SIZE]  <= inputs[counter_old1*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
            outputs_buffer[counter_old2*LUT_WIDTH+:LUT_WIDTH]         <= read_value;
            read_address                                              <= inputs[counter*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
            stable_buffer                                             <= (inputs == inputs_buffer);
        end
    end

    // outputs
    assign outputs = outputs_buffer;
    assign stable = stable_buffer; // when the inputs settle and are processed, raise stable
    
    // inputs into memory, used for testing /////////////////////
    //wire [LUT_ADDR_SIZE-1:0]  inputs_mem [NEURON_NUM-1:0];
    //wire [LUT_ADDR_SIZE-1:0]  outputs_mem [NEURON_NUM-1:0];
    //genvar i;
    //generate
    //for (i=0; i<NEURON_NUM; i=i+1) begin: MEM_INPUTS
        //assign inputs_mem[i] = inputs[i*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
        //assign outputs_mem[i] = outputs[i*LUT_WIDTH+:LUT_WIDTH];
    //end
    //endgenerate 
    /////////////////////////////////////////////////////////////

endmodule

