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
              WEIGHT_INIT_FILE    = "weight_init.list"
)
(
    input clk,
    input rst,
    // layer
    input  [LAYER_ADDR_WIDTH-1:0]                        layer,
    input                                                layer_valid,
    output                                               layer_ready,
    // z
    input  [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z,
    input                                                z_valid,
    output                                               z_ready,
    // delta
    input  [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta,
    input                                                delta_valid,
    output                                               delta_ready,
    // w
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w,
    output                                               w_valid,
    input                                                w_ready,
    // overflow
    output                                               error
);

    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a;
    wire a_valid, a_ready;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_bram_input, w_bram_output, w_bram_fifo_1, w_bram_fifo_2;
    wire w_bram_input_valid, w_bram_input_ready, w_bram_output_valid, w_bram_output_ready;
    wire w_bram_fifo_1_valid, w_bram_fifo_1_ready, w_bram_fifo_2_valid, w_bram_fifo_2_ready;
    // layer fifo signals
    wire [LAYER_ADDR_WIDTH-1:0] layer_fifo_1, layer_fifo_2;
    wire layer_fifo_1_valid, layer_fifo_1_ready, layer_fifo_2_valid, layer_fifo_2_ready;




    lut #(
        .NEURON_NUM   (NEURON_NUM              ),
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE("sigmoid.list"          )
    ) sigma (
        .clk          (clk    ),
        .rst          (rst    ),
        .inputs       (z      ),
        .inputs_valid (z_valid),
        .inputs_ready (z_ready),
        .outputs      (a      ),
        .outputs_valid(a_valid),
        .outputs_ready(a_ready)
    );


    weight_updater #(
        .NEURON_NUM         (NEURON_NUM         ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT)
    ) updater (
        .clk         (clk                ),
        .rst         (rst                ),
        .a           (a                  ),
        .a_valid     (a_valid            ),
        .a_ready     (a_ready            ),
        .delta       (delta              ),
        .delta_valid (delta_valid        ),
        .delta_ready (delta_ready        ),
        .w           (w_bram_fifo_1      ),
        .w_valid     (w_bram_fifo_1_valid),
        .w_ready     (w_bram_fifo_1_ready),
        .result      (w_bram_input       ),
        .result_valid(w_bram_input_valid ),
        .result_ready(w_bram_input_ready ),
        .error       (error              )
    );

    fifo_splitter2 #(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH) 
    layer_splitter (
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

    bram_wrapper #(
        .DATA_WIDTH(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH),
        .ADDR_WIDTH(LAYER_ADDR_WIDTH),
        .INIT_FILE(WEIGHT_INIT_FILE)
    ) bram_wrapper (
        .clk             (clk),
        .rst             (rst),
        .read_addr       (layer_fifo_1),
        .read_addr_valid (layer_fifo_1_valid),
        .read_addr_ready (layer_fifo_1_ready),
        .read_data       (w_bram_output),
        .read_data_valid (w_bram_output_valid),
        .read_data_ready (w_bram_output_ready),
        .write_addr      (layer_fifo_2),
        .write_addr_valid(layer_fifo_2_valid),
        .write_addr_ready(layer_fifo_2_ready),
        .write_data      (w_bram_input),
        .write_data_valid(w_bram_input_valid),
        .write_data_ready(w_bram_input_ready)
    );

    fifo_splitter2 #(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH) 
    weight_splitter (
        .clk            (clk                ),
        .rst            (rst                ),
        .data_in        (w_bram_output      ),
        .data_in_valid  (w_bram_output_valid),
        .data_in_ready  (w_bram_output_ready),
        .data_out1      (w_bram_fifo_1      ),
        .data_out1_valid(w_bram_fifo_1_valid),
        .data_out1_ready(w_bram_fifo_1_ready),
        .data_out2      (w_bram_fifo_2      ),
        .data_out2_valid(w_bram_fifo_2_valid),
        .data_out2_ready(w_bram_fifo_2_ready)
    );

    //////////////////////////////////////////////////////////////////////////////////////////////////////    
    //// Weight BRAM state machine
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //localparam IDLE=0, DONE=1; // no calc state needed, as result written in a single cycle
    //reg state;
    
    //always @ (posedge clk) begin
        //if (rst) begin
            //state <= DONE; // since we have initializad weights
        //end
        //else begin 
            //case (state)
                //IDLE: begin
                    //state <= w_bram_input_valid ? DONE : IDLE;
                //end
                //DONE: begin
                    //state <= w_bram_output_ready ? IDLE : DONE;
                //end
            //endcase 
        //end
    //end
    
    //assign w_bram_output_valid = (state == DONE) ? 1 : 0;
    //assign w_bram_input_ready  = (state == IDLE) ? 1 : 0;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    assign w                   = w_bram_fifo_2;
    assign w_valid             = w_bram_fifo_2_valid;
    assign w_bram_fifo_2_ready = w_ready;


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing 
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    wire [ACTIVATION_WIDTH-1:0]  a_mem [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1:0]  delta_mem [0:NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] updated_weights_mem  [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_previous_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_current_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    
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

endmodule
