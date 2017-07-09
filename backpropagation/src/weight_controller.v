module weight_controller
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              LEARNING_RATE_SHIFT = 0,
              LAYER_ADDR_WIDTH    = 2,
              FRACTION_WIDTH      = 0,
              WEIGHT_INIT_FILE    = "weight_init.list",
              ACTIVATION_FILE     = "sigmoid.list"
)
(
    input clk,
    input rst,
    // layer for backwards pass
    input  [LAYER_ADDR_WIDTH-1:0]                        layer_bw,
    input                                                layer_bw_valid,
    output                                               layer_bw_ready,
    // layer for forward pass
    input  [LAYER_ADDR_WIDTH-1:0]                        layer_fw,
    input                                                layer_fw_valid,
    output                                               layer_fw_ready,
    // z
    input  [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z,
    input                                                z_valid,
    output                                               z_ready,
    // delta
    input  [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta,
    input                                                delta_valid,
    output                                               delta_ready,
    // output to forward module 
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_fw,
    output                                               w_fw_valid,
    input                                                w_fw_ready,
    // output to backwards module
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_bw,
    output                                               w_bw_valid,
    input                                                w_bw_ready,
    // overflow
    output                                               error
);

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a, z_truncated, a_pick;
    wire a_valid, a_ready, a_pick_valid, a_pick_ready;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_bram_input, w_bram_output, w_updater;
    wire w_bram_input_valid, w_bram_input_ready, w_bram_output_valid, w_bram_output_ready;
    wire w_updater_valid, w_updater_ready;
    // layer fifo signals
    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2, layer_fifo_3, layer_fifo_4;
    wire layer_fifo_1_valid, layer_fifo_1_ready, layer_fifo_2_valid, layer_fifo_2_ready, layer_fifo_3_valid, layer_fifo_3_ready, layer_fifo_4_valid, layer_fifo_4_ready;
    // picker signals
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z0, z1;
    wire z0_valid, z0_ready, z1_valid, z1_ready;


    fifo_splitter4 #(LAYER_ADDR_WIDTH) 
    layer_splitter (
        .clk            (clk               ),
        .rst            (rst               ),
        .data_in        (layer_bw          ),
        .data_in_valid  (layer_bw_valid    ),
        .data_in_ready  (layer_bw_ready    ),
        .data_out1      (layer_fifo_1      ), // To the BRAM read address
        .data_out1_valid(layer_fifo_1_valid),
        .data_out1_ready(layer_fifo_1_ready),
        .data_out2      (layer_fifo_2      ), // To the BRAM write address
        .data_out2_valid(layer_fifo_2_valid),
        .data_out2_ready(layer_fifo_2_ready),
        .data_out3      (layer_fifo_3      ), // To the demux skipping the sigmoid
        .data_out3_valid(layer_fifo_3_valid),
        .data_out3_ready(layer_fifo_3_ready),
        .data_out4      (layer_fifo_4      ), // To the mux combining skipped and not skipped signals
        .data_out4_valid(layer_fifo_4_valid),
        .data_out4_ready(layer_fifo_4_ready)
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Bottom layer picker - pick whether to send input to activation or not
    // If not, the larger pre-activation inputs need to be cropped and checked for overflows
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    fifo_demux2 #(NEURON_NUM*NEURON_OUTPUT_WIDTH)
    input_demux (
        .clk         (clk               ),
        .rst         (rst               ),
        .in          (z                 ),
        .in_valid    (z_valid           ),
        .in_ready    (z_ready           ),
        .select      (layer_fifo_3==0   ),
        .select_valid(layer_fifo_3_valid),
        .select_ready(layer_fifo_3_ready),
        .out0        (z0                ),
        .out0_valid  (z0_valid          ),
        .out0_ready  (z0_ready          ),
        .out1        (z1                ),
        .out1_valid  (z1_valid          ),
        .out1_ready  (z1_ready          )
    );


    lut #(
        .NEURON_NUM     (NEURON_NUM              ),
        .LUT_ADDR_SIZE  (NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH      (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH      (ACTIVATION_WIDTH        ),
        .ACTIVATION_FILE(ACTIVATION_FILE         )
    ) sigma (
        .clk          (clk     ),
        .rst          (rst     ),
        .inputs       (z0      ),
        .inputs_valid (z0_valid),
        .inputs_ready (z0_ready),
        .outputs      (a       ),
        .outputs_valid(a_valid ),
        .outputs_ready(a_ready )
    );


    genvar x;
    generate
    for (x=0; x<NEURON_NUM; x=x+1) begin: TRUNCATE
        assign z_truncated[x*ACTIVATION_WIDTH+:ACTIVATION_WIDTH] = z1[x*NEURON_OUTPUT_WIDTH+ACTIVATION_WIDTH-1:x*NEURON_OUTPUT_WIDTH];
    end
    endgenerate

    fifo_mux2 #(NEURON_NUM*ACTIVATION_WIDTH) 
    fifo_mux (
        .clk         (clk               ),
        .rst         (rst               ),
        .a           (a                 ),
        .a_valid     (a_valid           ),
        .a_ready     (a_ready           ),
        .b           (z_truncated       ),
        .b_valid     (z1_valid          ),
        .b_ready     (z1_ready          ),
        .select      (layer_fifo_4 == 0 ),
        .select_valid(layer_fifo_4_valid),
        .select_ready(layer_fifo_4_ready),
        .result      (a_pick            ),
        .result_valid(a_pick_valid      ),
        .result_ready(a_pick_ready      )
    );
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // End of bottom layer picker
    ////////////////////////////////////////////////////////////////////////////////////////////////////


    weight_updater #(
        .NEURON_NUM         (NEURON_NUM         ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT)
    ) updater (
        .clk         (clk               ),
        .rst         (rst               ),
        .a           (a_pick            ),
        .a_valid     (a_pick_valid      ),
        .a_ready     (a_pick_ready      ),
        .delta       (delta             ),
        .delta_valid (delta_valid       ),
        .delta_ready (delta_ready       ),
        .w           (w_updater         ),
        .w_valid     (w_updater_valid   ),
        .w_ready     (w_updater_ready   ),
        .result      (w_bram_input      ),
        .result_valid(w_bram_input_valid),
        .result_ready(w_bram_input_ready),
        .error       (error             )
    );


    dual_port_bram_wrapper #(
        .DATA_WIDTH(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH),
        .ADDR_WIDTH(LAYER_ADDR_WIDTH),
        .INIT_FILE(WEIGHT_INIT_FILE)
    ) weights_bram (
        .clk               (clk                ),
        .rst               (rst                ),
        // backwards pass oriented read/write port
        .read_addr_0       (layer_fifo_1       ),
        .read_addr_0_valid (layer_fifo_1_valid ),
        .read_addr_0_ready (layer_fifo_1_ready ),
        .read_data_0       (w_bram_output      ),
        .read_data_0_valid (w_bram_output_valid),
        .read_data_0_ready (w_bram_output_ready),
        .write_addr_0      (layer_fifo_2       ),
        .write_addr_0_valid(layer_fifo_2_valid ),
        .write_addr_0_ready(layer_fifo_2_ready ),
        .write_data_0      (w_bram_input       ),
        .write_data_0_valid(w_bram_input_valid ),
        .write_data_0_ready(w_bram_input_ready ),
        // forward pass oriented read port.
        // forward pass performs no writing so it is left unconnected 
        .read_addr_1       (layer_fw      ),
        .read_addr_1_valid (layer_fw_valid),
        .read_addr_1_ready (layer_fw_ready),
        .read_data_1       (w_fw          ),
        .read_data_1_valid (w_fw_valid    ),
        .read_data_1_ready (w_fw_ready    ),
        .write_addr_1      (0             ),
        .write_addr_1_valid(1'b0          ),
        .write_addr_1_ready(              ),
        .write_data_1      (0             ),
        .write_data_1_valid(1'b0          ),
        .write_data_1_ready(              )
    );


    fifo_splitter2 #(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH) 
    weight_splitter (
        .clk            (clk                ),
        .rst            (rst                ),
        .data_in        (w_bram_output      ),
        .data_in_valid  (w_bram_output_valid),
        .data_in_ready  (w_bram_output_ready),
        .data_out1      (w_updater          ),
        .data_out1_valid(w_updater_valid    ),
        .data_out1_ready(w_updater_ready    ),
        .data_out2      (w_bw               ),
        .data_out2_valid(w_bw_valid         ),
        .data_out2_ready(w_bw_ready         )
    );



    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing 
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    wire [ACTIVATION_WIDTH-1:0]  a_mem [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1:0]  delta_mem [0:NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] updated_weights_mem  [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_previous_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    
    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM1
        assign a_mem[i]     = a[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign delta_mem[i] = delta[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end

    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM2
        assign weights_previous_mem[i] = w_bram_output[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign updated_weights_mem[i] =  w_bram_input[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate

    //always @ (posedge clk) begin
        //if (w_bram_input_valid && w_bram_input_ready)
            //$display("UPDATE - time: %d", $stime);
    //end

endmodule
