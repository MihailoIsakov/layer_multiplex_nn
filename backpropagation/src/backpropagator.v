module backpropagator
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 18, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 8,
              LEARNING_RATE_SHIFT = 0,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list",
              WEIGHT_INIT_FILE    = "weight_init.list"

)(
    input clk,
    input rst,
    // layer
    input [LAYER_ADDR_WIDTH-1:0]                         layer,
    input                                                layer_valid,
    output                                               layer_ready,
    // sample
    input [SAMPLE_ADDR_SIZE-1:0]                         sample,
    input                                                sample_valid,
    output                                               sample_ready,
    // z
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z,
    input                                                z_valid,
    output                                               z_ready,
    // z_prev
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z_prev,
    input                                                z_prev_valid,
    output                                               z_prev_ready,
    // weights
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights,
    output                                               weights_valid,
    input                                                weights_ready,
    // overflow
    output                                               error
);

    // delta wires
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta_ef, delta_prev, delta_fifo_1, delta_fifo_2;
    wire delta_ef_valid, delta_ef_ready, delta_prev_valid, delta_prev_ready;
    wire delta_fifo_1_ready, delta_fifo_1_valid, delta_fifo_2_ready, delta_fifo_2_valid;

    // z wires
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z_prev_fifo_1, z_prev_fifo_2; 
    wire z_prev_fifo_1_ready, z_prev_fifo_1_valid, z_prev_fifo_2_ready, z_prev_fifo_2_valid;
    
    // weight wires
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_wc, w_fifo_1, w_fifo_2;
    wire w_fifo_1_valid, w_fifo_1_ready, w_fifo_2_valid, w_fifo_2_ready;
    wire w_wc_valid, w_wc_ready;
    
    // layer fifo wires
    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4;
    wire layer_fifo_1_valid, layer_fifo_1_ready, layer_fifo_2_valid, layer_fifo_2_ready;
    wire layer_fifo_3_valid, layer_fifo_3_ready, layer_fifo_4_valid, layer_fifo_4_ready;

    // mux
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] mux_output;
    wire mux_output_valid, mux_output_ready;

    // overflow errors
    wire wc_error, ef_error, ep_error;
    

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Modules
    //////////////////////////////////////////////////////////////////////////////////////////////////// 

    weight_controller #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) weight_controller (
        .clk        (clk                ),
        .rst        (rst                ),
        .layer      (layer_fifo_1       ),
        .layer_valid(layer_fifo_1_valid ),
        .layer_ready(layer_fifo_1_ready ),
        .z          (z_prev_fifo_1      ),
        .z_valid    (z_prev_fifo_1_valid),
        .z_ready    (z_prev_fifo_1_ready),
        .delta      (delta_fifo_1       ),
        .delta_valid(delta_fifo_1_valid ),
        .delta_ready(delta_fifo_1_ready ),
        .w          (w_wc               ),
        .w_valid    (w_wc_valid         ),
        .w_ready    (w_wc_ready         ),
        .error      (wc_error           )
    );


    error_fetcher #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        )
    ) error_fetcher (
        .clk               (clk               ),
        .rst               (rst               ),
        .sample_index      (sample            ),
        .sample_index_valid(sample_valid      ),
        .sample_index_ready(sample_ready      ),
        .z                 (z                 ),
        .z_valid           (z_valid           ),
        .z_ready           (z_ready           ),
        .delta_output      (delta_ef          ),
        .delta_output_valid(delta_ef_valid    ),
        .delta_output_ready(delta_ef_ready    ),
        .error             (ef_error          )
    );


    error_propagator #(
        .MATRIX_WIDTH      (NEURON_NUM         ),
        .MATRIX_HEIGHT     (NEURON_NUM         ),
        .DELTA_CELL_WIDTH  (DELTA_CELL_WIDTH   ),
        .WEIGHTS_CELL_WIDTH(WEIGHT_CELL_WIDTH  ),
        .NEURON_ADDR_WIDTH (NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH  (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH    (FRACTION_WIDTH     ),
        .TILING_ROW        (2                  ),
        .TILING_COL        (2                  )
    ) error_propagator (
        .clk               (clk                ),
        .rst               (rst                ),
        .layer             (layer_fifo_4       ),
        .layer_valid       (layer_fifo_4_valid ),
        .layer_ready       (layer_fifo_4_ready ),
        .delta_input       (delta_fifo_2       ),
        .delta_input_valid (delta_fifo_2_valid ),
        .delta_input_ready (delta_fifo_2_ready ),
        .z                 (z_prev_fifo_2      ),
        .z_valid           (z_prev_fifo_2_valid),
        .z_ready           (z_prev_fifo_2_ready),
        .w                 (w_fifo_2           ),
        .w_valid           (w_fifo_2_valid     ),
        .w_ready           (w_fifo_2_ready     ),
        .delta_output      (delta_prev         ),
        .delta_output_valid(delta_prev_valid   ),
        .delta_output_ready(delta_prev_ready   ),
        .error             (ep_error           )
    );

    delta_picker #(
        .DELTA_WIDTH     (NEURON_NUM*DELTA_CELL_WIDTH),
        .LAYER_ADDR_WIDTH(LAYER_ADDR_WIDTH           ),
        .LAYER_MAX       (LAYER_MAX                  )
    ) delta_picker (
        .clk             (clk               ),
        .rst             (rst               ),
        .layer           (layer_fifo_3      ),
        .layer_valid     (layer_fifo_3_valid),
        .layer_ready     (layer_fifo_3_ready),
        .fetcher         (delta_ef          ),
        .fetcher_valid   (delta_ef_valid    ),
        .fetcher_ready   (delta_ef_ready    ),
        .propagator      (delta_prev        ),
        .propagator_valid(delta_prev_valid  ),
        .propagator_ready(delta_prev_ready  ),
        .result          (mux_output        ),
        .result_valid    (mux_output_valid  ),
        .result_ready    (mux_output_ready  )
    );

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // FIFO splitters 
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    fifo_splitter2 #(NEURON_NUM*DELTA_CELL_WIDTH) 
    delta_splitter (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (mux_output        ),
        .data_in_valid  (mux_output_valid  ),
        .data_in_ready  (mux_output_ready  ),
        .data_out1      (delta_fifo_1      ),
        .data_out1_valid(delta_fifo_1_valid),
        .data_out1_ready(delta_fifo_1_ready),
        .data_out2      (delta_fifo_2      ),
        .data_out2_valid(delta_fifo_2_valid),
        .data_out2_ready(delta_fifo_2_ready)
    );

    fifo_splitter2 #(NEURON_NUM*NEURON_OUTPUT_WIDTH) 
    z_prev_splitter (
        .clk            (clk                ),
        .rst            (rst                ),
        .data_in        (z_prev             ),
        .data_in_valid  (z_prev_valid       ),
        .data_in_ready  (z_prev_ready       ),
        .data_out1      (z_prev_fifo_1      ),
        .data_out1_valid(z_prev_fifo_1_valid),
        .data_out1_ready(z_prev_fifo_1_ready),
        .data_out2      (z_prev_fifo_2      ),
        .data_out2_valid(z_prev_fifo_2_valid),
        .data_out2_ready(z_prev_fifo_2_ready)
    );

    fifo_splitter2 #(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH)
    weight_splitter (
        .clk            (clk           ),
        .rst            (rst           ),
        .data_in        (w_wc          ),
        .data_in_valid  (w_wc_valid    ),
        .data_in_ready  (w_wc_ready    ),
        .data_out1      (w_fifo_1      ),
        .data_out1_valid(w_fifo_1_valid),
        .data_out1_ready(w_fifo_1_ready),
        .data_out2      (w_fifo_2      ),
        .data_out2_valid(w_fifo_2_valid),
        .data_out2_ready(w_fifo_2_ready)
    );

    fifo_splitter2 #(LAYER_ADDR_WIDTH)
    layer_splitter1 (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (layer             ),
        .data_in_valid  (layer_valid       ),
        .data_in_ready  (layer_ready       ),
        .data_out1      (layer_fifo_1      ),
        .data_out1_valid(layer_fifo_1_valid),
        .data_out1_ready(layer_fifo_1_ready),
        .data_out2      (layer_fifo_2      ),
        .data_out2_valid(layer_fifo_2_valid),
        .data_out2_ready(layer_fifo_2_ready)
    );

    fifo_splitter2 #(LAYER_ADDR_WIDTH)
    layer_splitter2 (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (layer_fifo_2      ),
        .data_in_valid  (layer_fifo_2_valid),
        .data_in_ready  (layer_fifo_2_ready),
        .data_out1      (layer_fifo_3      ),
        .data_out1_valid(layer_fifo_3_valid),
        .data_out1_ready(layer_fifo_3_ready),
        .data_out2      (layer_fifo_4      ),
        .data_out2_valid(layer_fifo_4_valid),
        .data_out2_ready(layer_fifo_4_ready)
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Outputs 
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    // weigths
    assign weights        = w_fifo_1;
    assign weights_valid  = w_fifo_1_valid;
    assign w_fifo_1_ready = weights_ready;
    // overflow
    assign error          = ef_error | ep_error | wc_error;


    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Testing
    //////////////////////////////////////////////////////////////////////////////////////////////////// 

    wire [WEIGHT_CELL_WIDTH  -1:0] weights_mem [0:NEURON_NUM*NEURON_NUM-1];

    genvar i;
    generate
    for(i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM2
        assign weights_mem[i] = weights[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate
    
endmodule

