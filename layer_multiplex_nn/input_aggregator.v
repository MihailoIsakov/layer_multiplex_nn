module input_aggregator
#(
    parameter LAYER_MAX = 4,
              NUM_NEURON = 6,      // max number of neurons
              INPUT_SIZE = 9,      // width of the input signals
              WEIGHT_SIZE = 17,    // width of the weight signals
              WEIGHTS_INIT = "weights612.list",
    parameter [NUM_NEURON*LAYER_MAX-1:0] LAYER_SIZES = {6'b101010, 6'b111010, 6'b111110, 6'b111111}
)
(
    input clk,
    input rst, 
    input start,
    input [NUM_NEURON*INPUT_SIZE-1:0]  start_input,     // outside input received at the start
    input [NUM_NEURON*INPUT_SIZE-1:0]  layer_input,       // input received from a layer n
    input [NUM_NEURON-1:0]             layer_input_valid, // validity of layer input
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
    
    reg [NUM_NEURON-1:0]                        active_buffer;
    reg [NUM_NEURON*INPUT_SIZE-1:0]             outputs_buffer;
    reg [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] weights_buffer; 
    reg [log2(LAYER_MAX):0]                     layer;
    reg [1:0]                                   state;
    reg                                         start_out;
    // when IA sends out the start signal, the valid input from OA changes after 3 cycles. 
    // This timer prevents IA to fire multiple times before the signal makes a full circle.
    reg [2:0]                                   timer; 
    
    always @ (posedge clk) begin
        if (rst) begin
            active_buffer  <= 0;
            outputs_buffer <= 0; 
            weights_buffer <= 0;
            layer          <= 0;
            state          <= IDLE;
            start_out      <= 0;
            weight_read    <= 1;
            timer          <= 0;
        end
        else begin
            active_buffer <= LAYER_SIZES[layer*NUM_NEURON+:NUM_NEURON];
            case (state)

                IDLE: begin
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
                    timer          <= 0;
                end

                WAIT: begin
                    timer <= timer + 1;
                    //if (layer_input_valid == active_buffer) begin // FIXME
                    if ((layer_input_valid & active) == active && timer > 3) begin // FIXME
                        if (layer == LAYER_MAX-1) begin // last layer
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
        end
    end

    // outputs 
    assign out_inputs  = outputs_buffer;
    assign out_weights = weights_buffer;
    assign layer_start = start_out;
    assign layer_num   = layer;
    assign active      = active_buffer;

endmodule
