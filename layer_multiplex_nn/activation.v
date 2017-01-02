module activation
#(
    parameter NUM_NEURON    = 6,
              LUT_ADDR_SIZE = 10,
              LUT_DEPTH     = 1 << LUT_ADDR_SIZE,
              LUT_WIDTH     = 8,
              LUT_INIT_FILE = "activations.list"
) (
    input clk,
    input rst,
    input enable,
    input [NUM_NEURON*LUT_ADDR_SIZE-1:0] inputs,
    input [NUM_NEURON-1:0]               inputs_valid,
    input [NUM_NEURON-1:0]               active,
    output [NUM_NEURON*LUT_WIDTH-1:0]    outputs,
    output [NUM_NEURON-1:0]              outputs_valid
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

    reg [NUM_NEURON*LUT_ADDR_SIZE-1:0] inputs_buffer;
    reg [NUM_NEURON-1:0]               input_fresh; // input_fresh is high if the input is the same as the processed output
    reg [log2(NUM_NEURON)-1:0]         counter;
    reg [NUM_NEURON*LUT_WIDTH-1:0]     activations;
    reg [NUM_NEURON-1:0]               activations_valid;

    wire [LUT_WIDTH-1:0] lut_out;
    param_rom #(.width(LUT_WIDTH), .depth(LUT_DEPTH), .init_file(LUT_INIT_FILE)) 
        LUT (.enable(1'b1), .addr(inputs[counter*LUT_ADDR_SIZE+:LUT_ADDR_SIZE]), .data(lut_out));


    always @ (posedge clk) begin
        if (rst) begin
            inputs_buffer     <= 0;
            input_fresh       <= 0;
            counter           <= 0;
            activations       <= 0;
            activations_valid <= 0;
        end 
        else if (enable) begin
            if (active[counter] && inputs_valid[counter]) begin
                activations[counter*LUT_WIDTH+:LUT_WIDTH] <= lut_out;
                activations_valid[counter] <= 1;
                inputs_buffer[counter*LUT_ADDR_SIZE+:LUT_ADDR_SIZE] = inputs[counter*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
            end
            counter <= (counter < NUM_NEURON-1) ? counter + 1 : 0;
        end
    end

    // in case the input changes, activations_valid is reset to 0 
    genvar i;
    generate
        for (i=0; i<NUM_NEURON; i=i+1) begin: MONITOR
            always @ (posedge clk) begin
                input_fresh[i] = (inputs_buffer[i*LUT_ADDR_SIZE+:LUT_ADDR_SIZE] == inputs[i*LUT_ADDR_SIZE+:LUT_ADDR_SIZE]);
            end
        end
    endgenerate

    // activations
    assign outputs_valid = inputs_valid & active & activations_valid & input_fresh;
    assign outputs       = activations;

endmodule

