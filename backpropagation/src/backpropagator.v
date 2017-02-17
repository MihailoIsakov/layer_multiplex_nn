module backpropagator
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 0,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list",
              WEIGHT_INIT_FILE    = "weight_init.list"

)(
    input clk,
    input rst,
    input                                                start,
    input [LAYER_ADDR_WIDTH-1:0]                         current_layer,
    input [SAMPLE_ADDR_SIZE-1:0]                         sample,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z_prev,
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights,
    output                                               valid,
    output                                               error
);

    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights_buffer;
    reg valid_buffer;

    reg wc_start, ef_start, ep_start; 
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta, delta_prev;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w;
    wire ef_valid, ep_valid, wc_valid, wc_error, ef_error, ep_error;

    weight_controller #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) weight_controller (
        .clk  (clk          ),
        .rst  (rst          ),
        .start(wc_start     ),
        .z    (z_prev       ),
        .delta(delta        ),
        .layer(current_layer),
        .w    (w            ),
        .valid(wc_valid     ),
        .error(wc_error     )
    );


    error_fetcher #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        )
    ) error_fetcher (
        .clk               (clk          ),
        .rst               (rst          ),
        .start             (ef_start     ),
        .layer             (current_layer),
        .sample_index      (sample       ),
        .z                 (z            ),
        .delta_input       (delta_prev   ),
        .delta_input_valid (ep_valid     ),
        .delta_output      (delta        ),
        .delta_output_valid(ef_valid     ),
        .error             (ef_error     )
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
        .clk         (clk       ),
        .rst         (rst       ),
        .start       (ep_start  ),
        .delta_input (delta     ),
        .z           (z_prev    ),
        .w           (w         ),
        .delta_output(delta_prev),
        .valid       (ep_valid  ),
        .error       (ep_error  )
    );

    localparam IDLE = 0, FETCH=1, PROPAGATE=2, UPDATE=3;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            wc_start       <= 0;
            ef_start       <= 0;
            ep_start       <= 0;
            // output buffers
            valid_buffer   <= 0;
            weights_buffer <= 0;
        end
        else begin
            if (wc_valid)
                weights_buffer <= w;

            case (state)
                IDLE: begin
                    state        <= start ? FETCH : IDLE;
                    ef_start     <= start ? 1     : 0;
                    ep_start     <= 0;
                    wc_start     <= 0;
                    valid_buffer <= start ? 0 : valid_buffer;
                end
                FETCH: begin
                    state        <= ef_valid ? PROPAGATE : FETCH;
                    ef_start     <= 0;
                    ep_start     <= ef_valid ? 1         : 0;
                    wc_start     <= 0;
                    valid_buffer <= 0;
                end
                PROPAGATE: begin
                    state        <= ep_valid ? UPDATE : PROPAGATE;
                    ef_start     <= 0;
                    ep_start     <= 0;
                    wc_start     <= ep_valid ? 1      : 0;
                    valid_buffer <= 0;
                end
                UPDATE: begin
                    state        <= wc_valid ? IDLE : UPDATE;
                    ef_start     <= 0;
                    ep_start     <= 0;
                    wc_start     <= 0;
                    valid_buffer <= wc_valid ? 1    : 0;
                end
                default: begin
                    state        <= IDLE;
                    ef_start     <= 0;
                    ep_start     <= 0;
                    wc_start     <= 0;
                    valid_buffer <= 0;
                end
            endcase
        end
    end

    // outputs 
    assign weights = weights_buffer;
    assign valid = valid_buffer;
    assign error = ef_error | ep_error | wc_error;

endmodule

