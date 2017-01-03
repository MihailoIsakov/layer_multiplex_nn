module input_aggregator
#(
    parameter LAYER_MAX = 4,
              NUM_NEURON = 6,      // max number of neurons
              INPUT_SIZE = 9,      // width of the input signals
              WEIGHT_SIZE = 17,    // width of the weight signals
              LAYER_SIZE // TODO
              WEIGHTS_INIT = "weights612.list"
)
(
    input clk,
    input rst, 
    input start,
    input [NUM_NEURON*INPUT_SIZE-1:0]  start_input,     // outside input received at the start
    input [NUM_NEURON*INPUT_SIZE-1:0]  layer_input,       // input received from a layer n
    input                              layer_input_valid, // validity of layer input
    output [NUM_NEURON*INPUT_SIZE-1:0]             out_inputs,
    output [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] out_weights,
    output [NUM_NEURON-1:0]                        active,
    output [log2(LAYER_MAX):0]                     layer_num,
    output                                         layer_start
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


    // weight BRAM
    reg weight_read; 
    wire [log2(LAYER_MAX):0] read_address;
    wire [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] weights; // FIXME the layer must accept NUM_NEURON^2 weights, not NUM_NEURON*NUM_INPUTS
    assign read_address = layer;

    BRAM #(.DATA_WIDTH(NUM_NEURON*NUM_NEURON*WEIGHT_SIZE), .ADDR_WIDTH(log2(LAYER_MAX)+1), .INIT_FILE(WEIGHTS_INIT)) 
        weight_bram(clk, weight_read, read_address, weights, 0, 0, 0);
    // weight BRAM

    localparam IDLE = 0, WAIT = 1, START = 2;
    
    reg [NUM_NEURON*INPUT_SIZE-1:0]             outputs_buffer;
    reg [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] weights_buffer; 
    reg [log2(LAYER_MAX):0]                     layer;
    reg [1:0]                                   state;
    reg                                         start_out;
    
    always @ (posedge clk) begin
        if (rst) begin
            outputs_buffer <= 0; 
            weights_buffer <= 0;
            layer          <= 0;
            state          <= IDLE;
            start_out      <= 0;
            weight_read    <= 1;
        end
        else begin
            case (state)

                IDLE: begin // TODO combine finish+idle
                    outputs_buffer <= start_input;
                    weights_buffer <= weights;
                    layer       <= 0;
                    state       <= (start) ? START : IDLE;
                    start_out   <= 0;
                end

                START: begin
                    outputs_buffer <= outputs_buffer;
                    weights_buffer <= weights_buffer;
                    layer          <= layer;
                    state          <= WAIT;
                    start_out      <= 1;
                end

                WAIT: begin
                    if (layer_input_valid) begin
                        if (layer_num == LAYER_MAX-1) begin // last layer
                            layer <= 0;
                            state <= IDLE;
                        end
                        else begin // not last layer
                            layer <= layer + 1;
                            state <= START;
                        end
                        outputs_buffer <= layer_input;
                        weights_buffer <= weights;
                        start_out      <= 0;
                    end
                    else begin
                        outputs_buffer <= outputs_buffer;
                        weights_buffer <= weights_buffer;
                        layer          <= layer;
                        state          <= WAIT;
                        start_out      <= 0;
                    end
                end

                default: begin
                    outputs_buffer <= outputs_buffer;
                    weights_buffer <= weights_buffer;
                    layer          <= layer;
                    state          <= state;
                    start_out      <= 0;
                end

            endcase 

            //outputs_buffer <= (layer_num == 0) ? start_input : layer_input;
            //weights_buffer <= weights;
            //start_out      <= 
        end
    end

    // outputs 
    assign out_inputs = outputs_buffer;
    assign out_weights = weights_buffer;
    assign layer_start = start_out;
    assign layer_num   = layer;

endmodule
