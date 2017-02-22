module top #(
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
              MAX_SAMPLES         = 10000,
              TARGET_FILE         = "targets.list",
              WEIGHT_INIT_FILE    = "weight_init.list"
) (
    input clk,
    input rst,
    input start
);

    reg [LAYER_ADDR_WIDTH-1:0] current_layer;
    reg [SAMPLE_ADDR_SIZE-1:0] current_sample;
    reg bp_start, fp_start;

    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire bp_valid, bp_error;
    
    // forward prop module
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0]    fp_start_input;
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] fp_output;
    wire                                      fp_output_valid;

    // stack 
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z, z_prev;


    BRAM #(
        .DATA_WIDTH(NEURON_NUM*ACTIVATION_WIDTH),
        .ADDR_WIDTH(SAMPLE_ADDR_SIZE),
        .INIT_FILE("inputs.list")
    ) inputs_BRAM (
		.clock       (clk),   
    	.readEnable  (1'b1),
    	.readAddress (current_sample),
   		.readData    (fp_start_input),
    	.writeEnable (1'b0),
    	.writeAddress(),
    	.writeData   () 
    ); 

    backpropagator #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_MAX          (LAYER_MAX          ),
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) backpropagator (
        .clk          (clk           ),
        .rst          (rst           ),
        .start        (bp_start      ),
        .current_layer(current_layer ),
        .sample       (current_sample),
        .z            (z             ),
        .z_prev       (z_prev        ),
        .weights      (weights       ),
        .valid        (bp_valid      ),
        .error        (bp_error      )
    );


    forward #(
        .LAYER_ADDR_WIDTH(LAYER_ADDR_WIDTH   ),
        .LAYER_MAX       (LAYER_MAX          ),
        .NUM_NEURON      (NEURON_NUM         ),
        .INPUT_SIZE      (ACTIVATION_WIDTH   ),
        .WEIGHT_SIZE     (WEIGHT_CELL_WIDTH  ),
        .ADDR_SIZE       (NEURON_OUTPUT_WIDTH),
        .INPUT_FRACTION  (FRACTION_WIDTH     ), // FIXME
        .WEIGHT_FRACTION (FRACTION_WIDTH     ), // FIXME
        .FRACTION_BITS   (FRACTION_WIDTH     )// FIXME
    ) forward_pass (
        .clk               (clk            ),
        .rst               (rst            ),
        .start             (fp_start       ),
        .start_input       (fp_start_input ),     // outside input received at the start
        .weights           (weights        ),
        .layer_number      (current_layer  ),
        .final_output      (fp_output      ),
        .final_output_valid(fp_output_valid)
    );


    activation_stack #(
        .NEURON_NUM      (NEURON_NUM         ),
        .ACTIVATION_WIDTH(NEURON_OUTPUT_WIDTH),
        .STACK_ADDR_WIDTH(LAYER_ADDR_WIDTH   )
    ) stack (
        .clk        (clk               ),
        // one write port
        .input_data (fp_output      ),
        .input_addr (current_layer     ),
        .input_wr_en(fp_output_valid),
        // two read ports
        .output_addr(current_layer     ),
        .output_data0(z                 ),
        .output_data1(z_prev            )
    );


    localparam IDLE=0, FP=1, BP=2; 
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            current_layer  <= 0;
            current_sample <= 0;
            fp_start       <= 0;
            bp_start       <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state          <= (start && (current_sample < MAX_SAMPLES)) ? FP : IDLE;
                    current_layer  <= 0;
                    current_sample <= current_sample;
                    fp_start       <= (start && (current_sample < MAX_SAMPLES)) ? 1  : 0;
                    bp_start       <= 0;
                end
                FP: begin
                    // if the forward pass is valid and we have reached the top layer, switch to backprop state 
                    state          <= (fp_output_valid && current_layer == (LAYER_MAX - 1)) ? BP : FP;
                    // FIXME possible issue with the current layer going too far
                    current_layer  <= fp_output_valid ? current_layer + 1 : current_layer; 
                    current_sample <= current_sample;
                    fp_start       <= fp_output_valid ? 1 : 0;
                    // if the forward pass is valid and we have reached the top layer, start the backprop module
                    bp_start       <= (fp_output_valid && current_layer == (LAYER_MAX - 1)) ? 1  : 0;
                end
                BP: begin
                    // FIXME == 0 or == 1? 
                    // if we came down to layer 1, go to idle, otherwise keep going down layers
                    state          <= (bp_valid && current_layer == 1) ? IDLE : BP;
                    // if BP finished, go down a layer
                    current_layer  <= bp_valid ? current_layer - 1 : current_layer;
                    // if BP finished, increment the sample index
                    current_sample <= (bp_valid && current_layer == 1) ? current_sample + 1 : 0; 
                    fp_start       <= 0;
                    bp_start       <= 0;
                end
                default: begin
                    state          <= IDLE;
                    current_layer  <= 0;
                    current_sample <= 0;
                    fp_start       <= 0;
                    bp_start       <= 0;
                end
            endcase
        end
    end

endmodule
