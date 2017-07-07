module backpropagator
#(
    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 8,
              LEARNING_RATE_SHIFT = 0,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 0,  // number of layers in the network
              WEIGHT_INIT_FILE    = "weights4x4.list"
)(
    input clk,
    input rst,
    // layer
    input [LAYER_ADDR_WIDTH-1:0]                         layer_bw,
    input                                                layer_bw_valid,
    output                                               layer_bw_ready,
    // layer
    input [LAYER_ADDR_WIDTH-1:0]                         layer_fw,
    input                                                layer_fw_valid,
    output                                               layer_fw_ready,
    // sample
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]              sample,
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

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Wires
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    // delta wires
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta;
    wire delta_valid, delta_ready;

    // z wires
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z_prev_fifo_1, z_prev_fifo_2; 
    wire z_prev_fifo_1_ready, z_prev_fifo_1_valid, z_prev_fifo_2_ready, z_prev_fifo_2_valid;
    
    // weight wires
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights_bw;
    wire weights_bw_valid, weights_bw_ready;
    
    // layer fifo wires
    wire [LAYER_ADDR_WIDTH-1:0] layer_wc, layer_ec;
    wire layer_wc_valid, layer_wc_ready, layer_ec_valid, layer_ec_ready;

    // overflow errors
    wire wc_error, ec_error;
    

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Modules
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    fifo_splitter2 #(LAYER_ADDR_WIDTH) 
    layer_splitter (
        .clk            (clk           ),
        .rst            (rst           ),
        .data_in        (layer_bw      ),
        .data_in_valid  (layer_bw_valid),
        .data_in_ready  (layer_bw_ready),
        .data_out1      (layer_wc      ),
        .data_out1_valid(layer_wc_valid),
        .data_out1_ready(layer_wc_ready),
        .data_out2      (layer_ec      ),
        .data_out2_valid(layer_ec_valid),
        .data_out2_ready(layer_ec_ready)
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
        .clk           (clk                ),
        .rst           (rst                ),
        .layer_bw      (layer_wc           ),
        .layer_bw_valid(layer_wc_valid     ),
        .layer_bw_ready(layer_wc_ready     ),
        .layer_fw      (layer_fw           ),
        .layer_fw_valid(layer_fw_valid     ),
        .layer_fw_ready(layer_fw_ready     ),
        .z             (z_prev_fifo_1      ),
        .z_valid       (z_prev_fifo_1_valid),
        .z_ready       (z_prev_fifo_1_ready),
        .delta         (delta              ),
        .delta_valid   (delta_valid        ),
        .delta_ready   (delta_ready        ),
        .w_fw          (weights            ),
        .w_fw_valid    (weights_valid      ),
        .w_fw_ready    (weights_ready      ),
        .w_bw          (weights_bw         ),
        .w_bw_valid    (weights_bw_valid   ),
        .w_bw_ready    (weights_bw_ready   ),
        .error         (wc_error           )
    );


    error_calculator #(
        .NEURON_NUM         (NEURON_NUM         ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          )
    ) error_calculator (
        .clk               (clk                ),
        .rst               (rst                ),
        .layer             (layer_ec           ),
        .layer_valid       (layer_ec_valid     ),
        .layer_ready       (layer_ec_ready     ),
        .y                 (sample             ),
        .y_valid           (sample_valid       ),
        .y_ready           (sample_ready       ),
        .z_prev            (z_prev_fifo_2      ),
        .z_prev_valid      (z_prev_fifo_2_valid),
        .z_prev_ready      (z_prev_fifo_2_ready),
        .z                 (z                  ),
        .z_valid           (z_valid            ),
        .z_ready           (z_ready            ),
        .w                 (weights_bw         ),
        .w_valid           (weights_bw_valid   ),
        .w_ready           (weights_bw_ready   ),
        .delta_output      (delta              ),
        .delta_output_valid(delta_valid        ),
        .delta_output_ready(delta_ready        ),
        .error             (ec_error           )
    );


    assign error = wc_error || ec_error;

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

