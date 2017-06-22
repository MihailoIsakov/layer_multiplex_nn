module tb_forward;

    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10, // size of neuron sum
              ACTIVATION_WIDTH    = 9,  // size of the neuron's activation
              LAYER_ADDR_WIDTH    = 2,  // width of the layer number 
              LAYER_MAX           = 3,  // number of layers in the network
              WEIGHT_CELL_WIDTH   = 16, // weight width, counting fractions
              FRACTION            = 0;  // bits spent on the fraction part in fixed point notation

    `include "log2.v"

    reg clk;
    reg rst;
    // number of neurons in the current layer
    reg [log2(NEURON_NUM):0]                          curr_neurons; 
    reg                                               curr_neurons_valid;
    wire                                              curr_neurons_ready;
    // number of neurons in the previous layer
    reg [log2(NEURON_NUM):0]                          prev_neurons; 
    reg                                               prev_neurons_valid;
    wire                                              prev_neurons_ready;
    // reg layer values
    reg [NEURON_NUM*ACTIVATION_WIDTH-1:0]             start_inputs; 
    reg                                               start_inputs_valid;
    wire                                              start_inputs_ready;
    // weights for this layer
    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    reg                                               weights_valid;
    wire                                              weights_ready;
    // current layer number 
    reg [LAYER_ADDR_WIDTH-1:0]                        layer_number;
    reg                                               layer_number_valid;
    wire                                              layer_number_ready;
    // outputs from the layer module
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]         current_layer_outputs;
    wire                                              overflow;
    wire                                              current_layer_outputs_valid;
    reg                                               current_layer_outputs_ready;

    wire [NEURON_OUTPUT_WIDTH-1:0] current_layer_outputs_mem [0:NEURON_NUM-1];
    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM
        assign current_layer_outputs_mem[i] = current_layer_outputs[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
    end
    endgenerate


    forward #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION           (FRACTION           )
    ) uut (
        .clk                        (clk                        ),
        .rst                        (rst                        ),
        .curr_neurons               (curr_neurons               ),
        .curr_neurons_valid         (curr_neurons_valid         ),
        .curr_neurons_ready         (curr_neurons_ready         ),
        .prev_neurons               (prev_neurons               ),
        .prev_neurons_valid         (prev_neurons_valid         ),
        .prev_neurons_ready         (prev_neurons_ready         ),
        .start_inputs               (start_inputs               ),
        .start_inputs_valid         (start_inputs_valid         ),
        .start_inputs_ready         (start_inputs_ready         ),
        .weights                    (weights                    ),
        .weights_valid              (weights_valid              ),
        .weights_ready              (weights_ready              ),
        .layer_number               (layer_number               ),
        .layer_number_valid         (layer_number_valid         ),
        .layer_number_ready         (layer_number_ready         ),
        .current_layer_outputs      (current_layer_outputs      ),
        .overflow                   (overflow                   ),
        .current_layer_outputs_valid(current_layer_outputs_valid),
        .current_layer_outputs_ready(current_layer_outputs_ready)
    );

    
    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;
        
        curr_neurons       <= NEURON_NUM;
        curr_neurons_valid <= 1;

        prev_neurons       <= NEURON_NUM;
        prev_neurons_valid <= 1;

        start_inputs       <= {9'd5, 9'd4, 9'd3, 9'd2, 9'd1};
        start_inputs_valid <= 1;

        //weights <= {16'd1, 16'd0, 16'd0, 16'd0, 16'd0,
                    //16'd0, 16'd1, 16'd0, 16'd0, 16'd0,
                    //16'd0, 16'd0, 16'd1, 16'd0, 16'd0,
                    //16'd0, 16'd0, 16'd0, 16'd1, 16'd0,
                    //16'd0, 16'd0, 16'd0, 16'd0, 16'd1};
        weights <= {16'd5, 16'd4, 16'd3, 16'd2, 16'd1,
                    16'd6, 16'd5, 16'd4, 16'd3, 16'd2,
                    16'd7, 16'd6, 16'd5, 16'd4, 16'd3,
                    16'd8, 16'd7, 16'd6, 16'd5, 16'd4,
                    16'd9, 16'd8, 16'd7, 16'd6, 16'd5};
        weights_valid <= 1;

        layer_number       <= 0;
        layer_number_valid <= 1;

        current_layer_outputs_ready <= 1;

        #10 rst <= 0;
    end

endmodule
