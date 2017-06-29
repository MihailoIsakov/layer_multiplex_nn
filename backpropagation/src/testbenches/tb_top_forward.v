module tb_top_forward;

    parameter NEURON_NUM          = 4,
              NEURON_OUTPUT_WIDTH = 12,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              FRACTION            = 8,
              DATASET_ADDR_WIDTH  = 10,
              MAX_SAMPLES         = 1000,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 2,
              INPUT_SAMPLES_FILE  = "inputs4.list",
              OUTPUT_SAMPLES_FILE = "targets4.list";

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires & regs
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    reg clk, rst;

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] network_inputs, network_inputs_1, network_inputs_2, input_zero, stack_input;
    wire network_inputs_valid, network_inputs_ready;
    wire network_inputs_1_valid, network_inputs_1_ready; 
    wire network_inputs_2_valid, network_inputs_2_ready;
    wire input_zero_valid, input_zero_ready;
    wire stack_input_valid;
    wire stack_input_ready;

    // weights for this layer
    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    reg                                               weights_valid;
    wire                                              weights_ready;
    // current layer number 
    reg [LAYER_ADDR_WIDTH-1:0] layer_number;
    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4;
    reg  layer_number_valid;
    wire layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_3_valid, layer_fifo_4_valid;
    wire layer_number_ready, layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_ready, layer_fifo_4_ready;

    // outputs from the layer module
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] current_layer_outputs;
    wire overflow;
    wire current_layer_outputs_valid;
    wire current_layer_outputs_ready;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Datapath 
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    fifo_splitter4 #(LAYER_ADDR_WIDTH) 
    layer_splitter (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (layer_number      ),
        .data_in_valid  (layer_number_valid),
        .data_in_ready  (layer_number_ready),
        .data_out1      (layer_fifo_1      ),
        .data_out1_valid(layer_fifo_1_valid),
        .data_out1_ready(layer_fifo_1_ready),
        .data_out2      (layer_fifo_2      ),
        .data_out2_valid(layer_fifo_2_valid),
        .data_out2_ready(layer_fifo_2_ready),
        .data_out3      (layer_fifo_3      ),
        .data_out3_valid(layer_fifo_3_valid),
        .data_out3_ready(layer_fifo_3_ready),
        .data_out4      (layer_fifo_4      ),
        .data_out4_valid(layer_fifo_4_valid),
        .data_out4_ready(layer_fifo_4_ready)
    );


    dataset #(
        .NEURON_NUM         (NEURON_NUM         ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DATASET_ADDR_WIDTH (DATASET_ADDR_WIDTH ),
        .MAX_SAMPLES        (MAX_SAMPLES        ),
        .INPUT_SAMPLES_FILE (INPUT_SAMPLES_FILE ),
        .OUTPUT_SAMPLES_FILE(OUTPUT_SAMPLES_FILE)
    ) dataset (
        .clk                  (clk                  ),
        .rst                  (rst                  ),
        .network_inputs       (network_inputs       ),
        .network_inputs_valid (network_inputs_valid ),
        .network_inputs_ready (network_inputs_ready ),
        .network_outputs      (                     ),
        .network_outputs_valid(                     ),
        .network_outputs_ready(1'b1                 )
    );


    fifo_splitter2 #(NEURON_NUM*ACTIVATION_WIDTH) 
    input_splitter (
        .clk            (clk                   ),
        .rst            (rst                   ),
        .data_in        (network_inputs        ),
        .data_in_valid  (network_inputs_valid  ),
        .data_in_ready  (network_inputs_ready  ),
        .data_out1      (network_inputs_1      ),
        .data_out1_valid(network_inputs_1_valid),
        .data_out1_ready(network_inputs_1_ready),
        .data_out2      (network_inputs_2      ),
        .data_out2_valid(network_inputs_2_valid),
        .data_out2_ready(network_inputs_2_ready)
    );


    fifo_gate #(NEURON_NUM*ACTIVATION_WIDTH) 
    gate (
        .clk         (clk                   ),
        .rst         (rst                   ),
        .data        (network_inputs_2      ),
        .data_valid  (network_inputs_2_valid),
        .data_ready  (network_inputs_2_ready),
        .pass        (layer_fifo_1 == 0     ),
        .pass_valid  (layer_fifo_1_valid    ),
        .pass_ready  (layer_fifo_1_ready    ),
        .result      (input_zero            ),
        .result_valid(input_zero_valid      ),
        .result_ready(input_zero_ready      )
    );


    forward #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION           (FRACTION           )
    ) forward (
        .clk                        (clk                        ),
        .rst                        (rst                        ),
        .curr_neurons               (NEURON_NUM                 ),
        .curr_neurons_valid         (1'b1                       ),
        .curr_neurons_ready         (                           ),
        .prev_neurons               (NEURON_NUM                 ),
        .prev_neurons_valid         (1'b1                       ),
        .prev_neurons_ready         (                           ),
        .start_inputs               (network_inputs_1           ),
        .start_inputs_valid         (network_inputs_1_valid     ),
        .start_inputs_ready         (network_inputs_1_ready     ),
        .weights                    (weights                    ),
        .weights_valid              (weights_valid              ),
        .weights_ready              (weights_ready              ),
        .layer_number               (layer_fifo_4               ),
        .layer_number_valid         (layer_fifo_4_valid         ),
        .layer_number_ready         (layer_fifo_4_ready         ),
        .current_layer_outputs      (current_layer_outputs      ),
        .overflow                   (overflow                   ),
        .current_layer_outputs_valid(current_layer_outputs_valid),
        .current_layer_outputs_ready(current_layer_outputs_ready)
    );


    fifo_mux2 #(NEURON_NUM*ACTIVATION_WIDTH)
    mux (
        .clk         (clk                        ),
        .rst         (rst                        ),
        .a           (current_layer_outputs      ),
        .a_valid     (current_layer_outputs_valid),
        .a_ready     (current_layer_outputs_ready),
        .b           (input_zero                 ),
        .b_valid     (input_zero_valid           ),
        .b_ready     (input_zero_ready           ),
        .select      (layer_fifo_2 == 0          ),
        .select_valid(layer_fifo_2_valid         ),
        .select_ready(layer_fifo_2_ready         ),
        .result      (stack_input                ),
        .result_valid(stack_input_valid          ),
        .result_ready(stack_input_ready          )
    );


    activation_stack 
    #(
        .NEURON_NUM      (NEURON_NUM      ),
        .ACTIVATION_WIDTH(ACTIVATION_WIDTH),
        .STACK_ADDR_WIDTH(LAYER_MAX       ))
    stack (
        .clk                     (clk               ),
        .input_data              (stack_input       ),
        .input_data_valid        (stack_input_valid ),
        .input_data_ready        (stack_input_ready ),
        .input_addr              (layer_fifo_3      ),
        .input_addr_valid        (layer_fifo_3_valid),
        .input_addr_ready        (layer_fifo_3_ready),
        .output_addr             (0                 ),
        .output_addr_valid       (0                 ),
        .output_addr_ready       (                  ),
        .output_data_lower       (                  ),
        .output_data_lower_valid (                  ),
        .output_data_lower_ready (0                 ),
        .output_data_higher      (                  ),
        .output_data_higher_valid(                  ),
        .output_data_higher_ready(0                 )
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing  
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    always 
        #1 clk <= ~clk;
    

    initial begin
        clk <= 0;
        rst <= 1;

        layer_number <= 0;
        layer_number_valid <= 0;

        //weights <= {16'd5, 16'd4, 16'd3, 16'd2, 16'd1,
                    //16'd6, 16'd5, 16'd4, 16'd3, 16'd2,
                    //16'd7, 16'd6, 16'd5, 16'd4, 16'd3,
                    //16'd8, 16'd7, 16'd6, 16'd5, 16'd4,
                    //16'd9, 16'd8, 16'd7, 16'd6, 16'd5};
        weights <= {16'd4, 16'd3, 16'd2, 16'd1,
                    16'd5, 16'd4, 16'd3, 16'd2,
                    16'd6, 16'd5, 16'd4, 16'd3,
                    16'd7, 16'd6, 16'd5, 16'd4};
        weights_valid <= 1;
        
        #20 rst <= 0;

        #20 layer_number <= 0;
            layer_number_valid <= 1;
        #2  layer_number_valid <= 0;

        #40 layer_number <= 1;
            layer_number_valid <= 1;
        #2  layer_number_valid <= 0;

        #40 layer_number <= 2;
            layer_number_valid <= 1;
        #2  layer_number_valid <= 0;

    end

endmodule
