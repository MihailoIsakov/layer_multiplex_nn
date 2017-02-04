module backpropagator
#(
    parameter NEURON_NUM = 10,
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              LAYER_ADDR_WIDTH    = 2,  // size of the layer number 
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list"

)(
    input clk,
    input rst,
    input start,
    input [LAYER_ADDR_WIDTH-1:0]               current_layer,
    input [SAMPLE_ADDR_SIZE-1:0]               sample,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z_prev,

);

    localparam DELTA_WIDTH = 2*(1+ACTIVATION_WIDTH);

    reg fetcher_start, prop_start;

    wire [NEURON_NUM*DELTA_WIDTH-1:0] fetcher_delta, prop_delta;
    wire                              fetcher_delta_valid, prop_delta_valid;

    error_fetcher #(
        NEURON_NUM         (NEURON_NUM         ),
        NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        LAYER_MAX          (LAYER_MAX          ),
        SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        TARGET_FILE        (TARGET_FILE        )
    ) error_fetcher(
        .clk(clk),
        .rst(rst),
        .start(fetcher_start),
        .layer(current_layer),
        .sample_index(sample),
        .z(z),
        .delta_input(prop_delta),
        .delta_input_valid(prop_delta_valid),
        .delta_output(fetcher_delta),
        .delta_output_valid(fetcher_delta_valid)
    );

    error_propagator #(
        .MATRIX_WIDTH(NEURON_NUM),
        .MATRIX_HEIGHT(NEURON_NUM),
        .VECTOR_CELL_WIDTH()
        .MATRIX_CELL_WIDTH
        .NEURON_ADDR_WIDTH
        .ACTIVATION_WIDTH 
        .TILING_ROW       
        .TILING_COL       
    ) propagator (
        .clk(clk),
        .rst(rst),
        .start(prop_start),

    );

endmodule
