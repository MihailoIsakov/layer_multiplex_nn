module top #(
    parameter NEURON_NUM          = 4,
              NEURON_OUTPUT_WIDTH = 12,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              DELTA_CELL_WIDTH    = 9,
              FRACTION            = 8,
              DATASET_ADDR_WIDTH  = 10,
              MAX_SAMPLES         = 1000,
              LAYER_ADDR_WIDTH    = 2,
              LEARNING_RATE_SHIFT = 0,
              LAYER_MAX           = 2,
              WEIGHT_INIT_FILE    = "weights4x4.list",
              INPUT_SAMPLES_FILE  = "inputs4.list",
              OUTPUT_SAMPLES_FILE = "targets4.list"
) (
    input clk,
    input rst
);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires & regs
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] network_inputs, network_inputs_1, network_inputs_2;
    wire network_inputs_valid, network_inputs_ready;
    wire network_inputs_1_valid, network_inputs_1_ready; 
    wire network_inputs_2_valid, network_inputs_2_ready;

    // stack input & predecessors
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] stack_input, input_zero_extended; 
    wire stack_input_valid;
    wire stack_input_ready;

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] network_targets;
    wire network_targets_valid, network_targets_ready;

    // weights for this layer
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire                                               weights_valid;
    wire                                               weights_ready;
    // current layer number 
    reg [LAYER_ADDR_WIDTH-1:0] fw_layer_number;
    reg  fw_layer_number_valid;
    wire fw_layer_number_ready;

    // splitter
    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4, layer_fifo_5, layer_fifo_gate;
    wire layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_3_valid, layer_fifo_4_valid, layer_fifo_5_valid, layer_fifo_gate_valid;
    wire layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_ready, layer_fifo_4_ready, layer_fifo_5_ready, layer_fifo_gate_ready;

    // outputs from the layer module
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] current_layer_outputs;
    wire fw_overflow, bw_overflow;
    wire current_layer_outputs_valid;
    wire current_layer_outputs_ready;

    // backwards pass layer 
    reg [LAYER_ADDR_WIDTH-1:0] bw_layer_number;
    reg  bw_layer_number_valid;
    wire bw_layer_number_ready;

    // bw_layer splitter
    wire [LAYER_ADDR_WIDTH-1:0] bw_layer_fifo_1, bw_layer_fifo_2;
    wire bw_layer_fifo_1_valid, bw_layer_fifo_2_valid;
    wire bw_layer_fifo_1_ready, bw_layer_fifo_2_ready;

    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] stack_lower, stack_higher;
    wire stack_lower_valid, stack_lower_ready, stack_higher_valid, stack_higher_ready;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Datapath 
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    fifo_splitter_parametrized #(LAYER_ADDR_WIDTH, 5) 
    layer_splitter (
        .clk           (clk               ),
        .rst           (rst               ),
        .data_in       (fw_layer_number      ),
        .data_in_valid (fw_layer_number_valid),
        .data_in_ready (fw_layer_number_ready),
        .data_out      ({layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4, layer_fifo_5}),
        .data_out_valid({layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_3_valid, layer_fifo_4_valid, layer_fifo_5_valid}),
        .data_out_ready({layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_ready, layer_fifo_4_ready, layer_fifo_5_ready})
        //.data_out      ({layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4}),
        //.data_out_valid({layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_3_valid, layer_fifo_4_valid}),
        //.data_out_ready({layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_ready, layer_fifo_4_ready})
    );

    fifo_splitter_parametrized #(LAYER_ADDR_WIDTH, 2)
    bw_layer_splitter (
        .clk           (clk                                           ),
        .rst           (rst                                           ),
        .data_in       (bw_layer_number                               ),
        .data_in_valid (bw_layer_number_valid                         ),
        .data_in_ready (bw_layer_number_ready                         ),
        .data_out      ({bw_layer_fifo_1,       bw_layer_fifo_2      }),
        .data_out_valid({bw_layer_fifo_1_valid, bw_layer_fifo_2_valid}),
        .data_out_ready({bw_layer_fifo_1_ready, bw_layer_fifo_2_ready})
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
        .network_outputs      (network_targets      ),
        .network_outputs_valid(network_targets_valid),
        .network_outputs_ready(network_targets_ready)
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


    extend #(NEURON_NUM, ACTIVATION_WIDTH, NEURON_OUTPUT_WIDTH-ACTIVATION_WIDTH)
    extend (
        .in(network_inputs_2),
        .out(input_zero_extended)
    );


    fifo_gate #(LAYER_ADDR_WIDTH) 
    forward_gate (
        .clk         (clk                     ),
        .rst         (rst                     ),
        .data        (layer_fifo_4            ),
        .data_valid  (layer_fifo_4_valid      ),
        .data_ready  (layer_fifo_4_ready      ),
        .pass        (layer_fifo_1 < LAYER_MAX),
        .pass_valid  (layer_fifo_1_valid      ),
        .pass_ready  (layer_fifo_1_ready      ),
        .result      (layer_fifo_gate         ),
        .result_valid(layer_fifo_gate_valid   ),
        .result_ready(layer_fifo_gate_ready   )
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
        .layer_number               (layer_fifo_5               ),
        .layer_number_valid         (layer_fifo_5_valid         ),
        .layer_number_ready         (layer_fifo_5_ready         ),
        .current_layer_outputs      (current_layer_outputs      ),
        .overflow                   (fw_overflow                ),
        .current_layer_outputs_valid(current_layer_outputs_valid),
        .current_layer_outputs_ready(current_layer_outputs_ready)
    );


    fifo_mux2 #(NEURON_NUM*NEURON_OUTPUT_WIDTH)
    mux (
        .clk         (clk                        ),
        .rst         (rst                        ),
        .a           (current_layer_outputs      ),
        .a_valid     (current_layer_outputs_valid),
        .a_ready     (current_layer_outputs_ready),
        .b           (input_zero_extended        ),
        .b_valid     (network_inputs_2_valid     ),
        .b_ready     (network_inputs_2_ready     ),
        .select      (layer_fifo_2 == 0          ),
        .select_valid(layer_fifo_2_valid         ),
        .select_ready(layer_fifo_2_ready         ),
        .result      (stack_input                ),
        .result_valid(stack_input_valid          ),
        .result_ready(stack_input_ready          )
    );


    activation_stack 
    #(
        .NEURON_NUM      (NEURON_NUM         ),
        .ACTIVATION_WIDTH(NEURON_OUTPUT_WIDTH),
        .STACK_ADDR_WIDTH(LAYER_MAX          ))
    stack (
        .clk                     (clk                  ),
        .rst                     (rst                  ),
        .input_data              (stack_input          ),
        .input_data_valid        (stack_input_valid    ),
        .input_data_ready        (stack_input_ready    ),
        .input_addr              (layer_fifo_3         ),
        .input_addr_valid        (layer_fifo_3_valid   ),
        .input_addr_ready        (layer_fifo_3_ready   ),
        .output_addr             (bw_layer_fifo_1      ),
        .output_addr_valid       (bw_layer_fifo_1_valid),
        .output_addr_ready       (bw_layer_fifo_1_ready),
        .output_data_lower       (stack_lower          ),
        .output_data_lower_valid (stack_lower_valid    ),
        .output_data_lower_ready (stack_lower_ready    ),
        .output_data_higher      (stack_higher         ),
        .output_data_higher_valid(stack_higher_valid   ),
        .output_data_higher_ready(stack_higher_ready   )
    );



    backpropagator #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION           ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) backpropagator (
        .clk           (clk                  ),
        .rst           (rst                  ),
        .layer_bw      (bw_layer_fifo_2      ),
        .layer_bw_valid(bw_layer_fifo_2_valid),
        .layer_bw_ready(bw_layer_fifo_2_ready),
        .layer_fw      (layer_fifo_gate      ),
        .layer_fw_valid(layer_fifo_gate_valid),
        .layer_fw_ready(layer_fifo_gate_ready),
        .sample        (network_targets      ),
        .sample_valid  (network_targets_valid),
        .sample_ready  (network_targets_ready),
        .z             (stack_higher         ),
        .z_valid       (stack_higher_valid   ),
        .z_ready       (stack_higher_ready   ),
        .z_prev        (stack_lower          ),
        .z_prev_valid  (stack_lower_valid    ),
        .z_prev_ready  (stack_lower_ready    ),
        .weights       (weights              ),
        .weights_valid (weights_valid        ),
        .weights_ready (weights_ready        ),
        .error         (bw_overflow          )
    );

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // State machine controlling layer numbers:
    //
    // The state machine first increases the forward pass layer numbers: from 0 to LAYER_MAX (including LAYER_MAX).
    // After the updates are written to the stack, the state machine starts decreasing the backwards pass layer 
    // numbers: from LAYER_MAX-1 to 0. 
    // IMPORTANT: the backwards pass can only start after the forward pass has written the results!
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   
    wire top_stack_write, bottom_layer_write;
    assign top_stack_write   = stack.bram.writeEnable0 && stack.bram.writeAddress0 == LAYER_MAX;
    assign bottom_layer_write = backpropagator.weight_controller.weights_bram.bram.writeEnable0 &&
                                backpropagator.weight_controller.weights_bram.bram.writeAddress0 == 0;

    localparam FW=0, FW_STEP=1, BW=2, BW_STEP=3;
    reg [1:0] state;

    reg underflow; // the bw_layer_number underflows and causes issues. FIXME find a better way
    
    always @ (posedge clk) begin
        if (rst) begin
            state                 <= FW;
            fw_layer_number       <= 0;
            fw_layer_number_valid <= 0;
            bw_layer_number       <= 0;
            bw_layer_number_valid <= 0;
            underflow             <= 0;
        end
        else begin
            case (state)
                FW: begin
                    state                 <= top_stack_write ? BW : (fw_layer_number_ready && fw_layer_number <= LAYER_MAX) ? FW_STEP : FW;
                    fw_layer_number       <= fw_layer_number;
                    fw_layer_number_valid <= fw_layer_number_ready && fw_layer_number <= LAYER_MAX;
                    bw_layer_number       <= LAYER_MAX - 1;
                    bw_layer_number_valid <= 0;
                    underflow             <= 0;
                end
                FW_STEP: begin
                    state                 <= FW;
                    fw_layer_number       <= fw_layer_number + 1;
                    fw_layer_number_valid <= 0;
                    bw_layer_number       <= LAYER_MAX - 1;
                    bw_layer_number_valid <= 0;
                    underflow             <= 0;
                end
                BW: begin
                    state                 <= bottom_layer_write ? FW : (bw_layer_number_ready && bw_layer_number >= 0 && !underflow) ? BW_STEP : BW;
                    fw_layer_number       <= 0;
                    fw_layer_number_valid <= 0;
                    bw_layer_number       <= bw_layer_number;
                    bw_layer_number_valid <= bw_layer_number_ready && bw_layer_number >= 0 && !underflow;
                    underflow             <= underflow;
                end
                BW_STEP: begin
                    state                 <= BW;
                    fw_layer_number       <= 0;
                    fw_layer_number_valid <= 0;
                    {underflow, bw_layer_number} <= $signed(bw_layer_number - 1);
                    bw_layer_number_valid <= 0;
                end
            endcase
        end
    end

endmodule
