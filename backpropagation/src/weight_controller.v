module weight_controller
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              LAYER_ADDR_WIDTH    = 2,
              FRACTION_WIDTH      = 0,
              WEIGHT_INIT_FILE    = "weight_init.list"
)
(
    input clk,
    input rst,
    input                                                start,
    input  [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z,
    input  [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta,
    input  [LAYER_ADDR_WIDTH-1:0]                        layer,
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w,
    output                                               valid,
    output                                               error
);

    reg  weights_wr_en, updater_start, sigma_start, valid_buffer;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a; // neurons after activation
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights, updater_weights;
    wire sigma_valid, updater_valid, updater_error;

    lut #(
        .NEURON_NUM   (NEURON_NUM              ),
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE("sigmoid.list"      )
    ) sigma (
        .clk    (clk        ),
        .rst    (rst        ),
        .start  (sigma_start),
        .inputs (z          ),
        .outputs(a          ),
        .valid  (sigma_valid)
    );


    weight_updater #(
        .NEURON_NUM       (NEURON_NUM        ),
        .ACTIVATION_WIDTH (ACTIVATION_WIDTH  ),
        .DELTA_CELL_WIDTH (DELTA_CELL_WIDTH  ),
        .WEIGHT_CELL_WIDTH(WEIGHT_CELL_WIDTH ),
        .FRACTION_WIDTH   (FRACTION_WIDTH    )
    ) updater (
        .clk   (clk            ),
        .rst   (rst            ),
        .start (updater_start  ),
        .a     (a              ),
        .delta (delta          ),
        .w     (weights        ),
        .result(updater_weights),
        .valid (updater_valid  ),
        .error (updater_error  )
    );
  

    BRAM #(
        .DATA_WIDTH(NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH),
        .ADDR_WIDTH(LAYER_ADDR_WIDTH                       ),
        .INIT_FILE (WEIGHT_INIT_FILE                       ) )// TODO create a random weights initialization init file
    weight_loader (
		.clock       (clk            ),
    	.readEnable  (1'b1           ),
    	.readAddress (layer          ),
   		.readData    (weights        ),
    	.writeEnable (weights_wr_en  ),
    	.writeAddress(layer          ),
    	.writeData   (updater_weights)
    );

    // State machine
    localparam IDLE=0, SIGMA=1, UPDATE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            weights_wr_en <= 0;
            sigma_start   <= 0;
            updater_start <= 0;
            state         <= IDLE; 
            valid_buffer  <= 0;
        end
        else begin
            case (state)
            IDLE: begin
                weights_wr_en <= 0;
                sigma_start   <= start ? 1     : 0;
                updater_start <= 0;
                state         <= start ? SIGMA : IDLE; 
                valid_buffer  <= start ? 0     : valid_buffer;
            end
            SIGMA: begin
                weights_wr_en <= 0;
                sigma_start   <= 0;
                updater_start <= sigma_valid ? 1      : 0; // if the signal from the activation is stable, run weight_updater module
                state         <= sigma_valid ? UPDATE : SIGMA; 
                valid_buffer  <= 0;
            end
            UPDATE: begin
                weights_wr_en <= updater_valid ? 1    : 0;
                updater_start <= 0; // if the signal from the activation is stable, run weight_updater module
                state         <= updater_valid ? IDLE : UPDATE; 
                valid_buffer  <= updater_valid ? 1    : 0;
            end
            default: begin
                weights_wr_en     <= 0;
                sigma_start       <= 0;
                updater_start     <= 0;
                state             <= IDLE; 
            end
            endcase
        end
    end

    // outputs
    assign w     = weights;
    // since the valid signal will be set in update state, but need one cycle to write the weights
    assign valid = valid_buffer && (state == IDLE); 
    assign error = updater_error;


    // testing 
    wire [ACTIVATION_WIDTH-1:0]  a_mem [0:NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] updated_weights_mem  [0:NEURON_NUM*NEURON_NUM-1]; 
    wire [WEIGHT_CELL_WIDTH-1:0] weights_previous_mem [0:NEURON_NUM*NEURON_NUM-1]; 
    
    genvar i;
    generate
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM1
        assign a_mem[i] = a[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
    end
    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM2
        assign updated_weights_mem[i] = updater_weights[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign weights_previous_mem[i] = weights[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate

endmodule
