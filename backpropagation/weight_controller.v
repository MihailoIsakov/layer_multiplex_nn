module weight_controller
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              WEIGHT_WIDTH        = 16, // width of individual weights
              LAYER_ADDR_WIDTH    = 2
)
(
    input clk,
    input rst,
    input start,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]      z,
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]         delta,
    input [LAYER_ADDR_WIDTH-1:0]                    layer,
    output [NEURON_NUM*NEURON_NUM*WEIGHT_WIDTH-1:0] weights
);

    //wire [NEURON_NUM*NEURON_NUM*WEIGHT_WIDTH-1:0] weights;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_WIDTH-1:0] updated_weights;
    reg weights_wr_en;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a; // neurons after activation
    wire sigma_stable, update_finished;
    reg updater_start;

    activation #(
        .NEURON_NUM(NEURON_NUM), 
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH),
        .LUT_DEPTH(1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH(ACTIVATION_WIDTH),
        .LUT_INIT_FILE("activations.list"))
    sigma (
        .clk(clk),
        .rst(rst),
        .inputs(z),
        .outputs(a),
        .stable(sigma_stable)
    );

    weight_updater #(
        .NEURON_NUM(NEURON_NUM),
        .ACTIVATION_WIDTH(ACTIVATION_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH))
    updater (
        .clk(clk),
        .rst(rst),
        .start(updater_start),
        .a(a),
        .delta(delta),
        .w(weights),
        .result(updated_weights),
        .finish(update_finished)
    );
  
    // Weight loader
    BRAM #(
        .DATA_WIDTH(NEURON_NUM*NEURON_NUM*WEIGHT_WIDTH),
        .ADDR_WIDTH(LAYER_ADDR_WIDTH),
        .INIT_FILE("weights.list")) // TODO create a random weights initialization init file
    weight_loader (
		.clock(clk),
    	.readEnable(1'b1),
    	.readAddress(layer),
   		.readData(weights),
    	.writeEnable(weights_wr_en),
    	.writeAddress(layer),
    	.writeData(updated_weights)
    );

    // State machine
    localparam IDLE=0, SIGMA=1, UPDATE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            weights_wr_en <= 0;
            updater_start <= 0;
            state         <= IDLE; 
        end
        else begin
            case (state)
            IDLE: begin
                weights_wr_en <= 0;
                updater_start <= 0;
                state         <= start? SIGMA : IDLE; 
            end
            SIGMA: begin
                weights_wr_en <= 0;
                updater_start <= sigma_stable? 1 : 0; // if the signal from the activation is stable, run weight_updater module
                state         <= sigma_stable? UPDATE : SIGMA; 
            end
            UPDATE: begin
                weights_wr_en <= update_finished? 1 : 0;
                updater_start <= sigma_stable; // if the signal from the activation is stable, run weight_updater module
                state         <= sigma_stable? UPDATE : SIGMA; 
            end
            default: begin
                weights_wr_en <= 0;
                updater_start <= 0;
                state         <= IDLE; 
            end
            endcase
        end
    end

endmodule
