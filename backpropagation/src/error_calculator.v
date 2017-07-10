module error_calculator #(
    parameter NEURON_NUM          = 4,
              DELTA_CELL_WIDTH    = 8,  // width of each delta cell
              WEIGHT_CELL_WIDTH   = 8,  // widht of each matrix cell
              NEURON_OUTPUT_WIDTH = 10, // width of activations from neurons before the sigmoid
              ACTIVATION_WIDTH    = 9,  // cell width after sigmoid
              FRACTION_WIDTH      = 4,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 2,
              ACTIVATION_FILE     = "sigmoid.list",
              ACTIVATION_DER_FILE = "derivative.list"
) (
    input clk,
    input rst,
    // Layer
    input  [LAYER_ADDR_WIDTH-1:0]                       layer,
    input                                               layer_valid,
    output                                              layer_ready,
    // Targets
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]             y,
    input                                               y_valid,
    output                                              y_ready,
    // Previous neuron input
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z_prev,
    input                                               z_prev_valid,
    output                                              z_prev_ready,
    // Neuron input
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z,
    input                                               z_valid,
    output                                              z_ready,
    // Weights 
    input [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w,
    input                                               w_valid,
    output                                              w_ready,
    // Delta output
    output [NEURON_NUM*DELTA_CELL_WIDTH-1:0]            delta_output,
    output                                              delta_output_valid,
    input                                               delta_output_ready,
    // Overflow error
    output                                              error
);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires & regs
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z_gated;
    wire z_gated_valid, z_gated_ready;

    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] ef_delta, ep_delta, mux_output, gate_output;
    wire ef_delta_valid, ef_delta_ready, ef_error, ep_delta_valid, ep_delta_ready, ep_error, mux_output_valid, mux_output_ready, gate_output_valid, gate_output_ready;

    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2, layer_fifo_3;
    wire layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_valid, layer_fifo_3_ready;

    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] split;
    wire                                   split_valid, split_ready;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Modules
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    fifo_gate #(NEURON_NUM*NEURON_OUTPUT_WIDTH)
    top_layer_z_gate (
        .clk         (clk                          ),
        .rst         (rst                          ),
        .data        (z                            ),
        .data_valid  (z_valid                      ),
        .data_ready  (z_ready                      ),
        .pass        (layer_fifo_3 == LAYER_MAX - 1),
        .pass_valid  (layer_fifo_3_valid           ),
        .pass_ready  (layer_fifo_3_ready           ),
        .result      (z_gated                      ),
        .result_valid(z_gated_valid                ),
        .result_ready(z_gated_ready                )
    );

    error_fetcher #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .ACTIVATION_FILE    (ACTIVATION_FILE    ),
        .ACTIVATION_DER_FILE(ACTIVATION_DER_FILE)
    ) error_fetcher (
        .clk               (clk           ),
        .rst               (rst           ),
        .y                 (y             ),
        .y_valid           (y_valid       ),
        .y_ready           (y_ready       ),
        .z                 (z_gated       ),
        .z_valid           (z_gated_valid ),
        .z_ready           (z_gated_ready ),
        .delta_output      (ef_delta      ),
        .delta_output_valid(ef_delta_valid),
        .delta_output_ready(ef_delta_ready),
        .error             (ef_error      )
    );


    fifo_mux2 #(NEURON_NUM*DELTA_CELL_WIDTH) 
    mux (
        .clk         (clk                          ),
        .rst         (rst                          ),
        .a           (ef_delta                     ),
        .a_valid     (ef_delta_valid               ),
        .a_ready     (ef_delta_ready               ),
        .b           (gate_output                  ),
        .b_valid     (gate_output_valid            ),
        .b_ready     (gate_output_ready            ),
        .select      (layer_fifo_1 != LAYER_MAX - 1),
        .select_valid(layer_fifo_1_valid           ),
        .select_ready(layer_fifo_1_ready           ),
        .result      (mux_output                   ),
        .result_valid(mux_output_valid             ),
        .result_ready(mux_output_ready             )
    );


    fifo_splitter2 #(NEURON_NUM*DELTA_CELL_WIDTH) 
    delta_splitter (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (mux_output        ),
        .data_in_valid  (mux_output_valid  ),
        .data_in_ready  (mux_output_ready  ),
        .data_out1      (split             ),
        .data_out1_valid(split_valid       ),
        .data_out1_ready(split_ready       ),
        .data_out2      (delta_output      ),
        .data_out2_valid(delta_output_valid),
        .data_out2_ready(delta_output_ready)
    );


    fifo_splitter_parametrized #(LAYER_ADDR_WIDTH, 3) 
    layer_splitter (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (layer             ),
        .data_in_valid  (layer_valid       ),
        .data_in_ready  (layer_ready       ),
        .data_out       ({layer_fifo_1      , layer_fifo_2      , layer_fifo_3      }),
        .data_out_valid ({layer_fifo_1_valid, layer_fifo_2_valid, layer_fifo_3_valid}),
        .data_out_ready ({layer_fifo_1_ready, layer_fifo_2_ready, layer_fifo_3_ready})
    );

    
    // FIXME extract parameters
    error_propagator #(
        .MATRIX_WIDTH       (NEURON_NUM         ),
        .MATRIX_HEIGHT      (NEURON_NUM         ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHTS_CELL_WIDTH (WEIGHT_CELL_WIDTH  ),
        .NEURON_ADDR_WIDTH  (NEURON_OUTPUT_WIDTH), // FIXME rename 
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .ACTIVATION_DER_FILE(ACTIVATION_DER_FILE),
        .TILING_ROW         (1                  ),
        .TILING_COL         (1                  )
    ) error_propagator (
        .clk               (clk           ),
        .rst               (rst           ),
        .delta_input       (split         ),
        .delta_input_valid (split_valid   ),
        .delta_input_ready (split_ready   ),
        .z                 (z_prev        ),
        .z_valid           (z_prev_valid  ),
        .z_ready           (z_prev_ready  ),
        .w                 (w             ),
        .w_valid           (w_valid       ),
        .w_ready           (w_ready       ),
        .delta_output      (ep_delta      ),
        .delta_output_valid(ep_delta_valid),
        .delta_output_ready(ep_delta_ready),
        .error             (ep_error      )
    );

    fifo_gate #(NEURON_NUM*DELTA_CELL_WIDTH) 
    gate (
        .clk         (clk               ),
        .rst         (rst               ),
        .data        (ep_delta          ),
        .data_valid  (ep_delta_valid    ),
        .data_ready  (ep_delta_ready    ),
        .pass        (layer_fifo_2 != 0 ),
        .pass_valid  (layer_fifo_2_valid),
        .pass_ready  (layer_fifo_2_ready),
        .result      (gate_output       ),
        .result_valid(gate_output_valid ),
        .result_ready(gate_output_ready )
    );

    assign error = ep_error || ef_error;

endmodule
