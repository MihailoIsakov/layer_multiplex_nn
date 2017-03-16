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
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w_bram, w_updated;
    wire w_updated_valid;

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
        .clk         (clk            ),
        .rst         (rst            ),
        .a           (a              ),
        .a_valid     (a_valid        ),
        .a_ready     (a_ready        ),
        .delta       (delta          ),
        .delta_valid (delta_valid    ),
        .delta_ready (delta_ready    ),
        .w           (w_bram         ),
        .w_valid     (1'b1           ), // hack, assumes that the weights read are always valid
        .w_ready     (               ), // hack, nobody cares if 
        .result      (w_updated      ),
        .result_valid(w_updated_valid),
        .result_ready(1'b1           ), // hack, assumes that the weights are always able to be stored
        .error       (error          )
    );
  

    BRAM #(
        .DATA_WIDTH(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH),
        .ADDR_WIDTH(LAYER_ADDR_WIDTH                       ),
        .INIT_FILE (WEIGHT_INIT_FILE                       ) 
    ) weight_loader (
		.clock       (clk            ),
    	.readEnable  (1'b1           ), // always reads
    	.readAddress (layer          ),
   		.readData    (w_bram         ), // goes to weight_updater and out
    	.writeEnable (w_updated_valid), // writes if weights are valid, should last a single cycle since the ready==1 always
    	.writeAddress(layer          ), 
    	.writeData   (w_updated      )  
    );

    // outputs
    assign w       = w_bram;
    assign w_valid = 1'b1; // always valid since the memory is never dirty

    // testing 
    wire [ACTIVATION_WIDTH-1:0]  a_mem [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1:0]  delta_mem [0:NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] updated_weights_mem  [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_previous_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_current_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    
    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM1
        assign a_mem[i] = a[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign delta_mem[i] = delta[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end

    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM2
        assign weights_previous_mem[i] = w_bram[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign updated_weights_mem[i] = w_updated[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign weights_current_mem[i] = w[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate

endmodule
