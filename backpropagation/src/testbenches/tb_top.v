`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:33:12 02/22/2017
// Design Name:   top
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_top.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_top;

    parameter NEURON_NUM          = 30, 
              NEURON_OUTPUT_WIDTH = 20,
              ACTIVATION_WIDTH    = 20,
              WEIGHT_CELL_WIDTH   = 20,
              DELTA_CELL_WIDTH    = 20,
              FRACTION            = 16,
              DATASET_ADDR_WIDTH  = 10,
              MAX_SAMPLES         = 569,
              //MAX_SAMPLES         = 10,
              LAYER_ADDR_WIDTH    = 2,
              LEARNING_RATE_SHIFT = 9,
              LAYER_MAX           = 1,
              WEIGHT_INIT_FILE    = "weights_30x30_20bit_16frac.mem",
              INPUT_SAMPLES_FILE  = "breast_input_30neuron_20bit_16frac.mem",
              OUTPUT_SAMPLES_FILE = "breast_output_30neuron_20bit_16frac.mem",
              ACTIVATION_FILE     = "linear",
              ACTIVATION_DER_FILE = "linear_derivative",
              SMOOTH_WINDOW       = 100;

    reg clk, rst;


    top #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .FRACTION           (FRACTION           ),
        .DATASET_ADDR_WIDTH (DATASET_ADDR_WIDTH ),
        .MAX_SAMPLES        (MAX_SAMPLES        ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   ),
        .INPUT_SAMPLES_FILE (INPUT_SAMPLES_FILE ),
        .OUTPUT_SAMPLES_FILE(OUTPUT_SAMPLES_FILE),
        .ACTIVATION_FILE    (ACTIVATION_FILE    ),
        .ACTIVATION_DER_FILE(ACTIVATION_DER_FILE)
    ) top (
        .clk(clk),
        .rst(rst)
    );


    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;
        max_act_buffer <= 0;
        max_target_buffer <=0;
        classification_buffer <= 0;
        #20 rst <= 0;

    end

    localparam W=WEIGHT_CELL_WIDTH;

    wire [NEURON_NUM*(ACTIVATION_WIDTH+1)-1:0] subtract;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] targets, results, derivative, wu_activations;
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] deltas, wu_deltas;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights, updates, updates_shifted, updated;
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] pre_activations;

    wire signed [31:0] sum, abs_delta_sum;
    reg  signed [48:0] sum_buffer, average, abs_delta_sum_buffer, classification_buffer_int;
    real classification_buffer;
    wire max_act, max_target;
    reg [0:0] max_act_buffer, max_target_buffer;

    assign subtract        = top.backpropagator.error_calculator.error_fetcher.subtracter_result;
    assign targets         = top.backpropagator.error_calculator.error_fetcher.y;
    assign results         = top.backpropagator.error_calculator.error_fetcher.a;
    assign deltas          = top.backpropagator.error_calculator.error_fetcher.delta_output;
    assign derivative      = top.backpropagator.error_calculator.error_fetcher.sigma_der_result;
    assign weights         = top.backpropagator.weight_controller.updater.w;
    assign updates         = top.backpropagator.weight_controller.updater.product_result;
    assign updates_shifted = top.backpropagator.weight_controller.updater.product_result_shifted;
    assign updated         = top.backpropagator.weight_controller.updater.adder_result;
    assign wu_deltas       = top.backpropagator.weight_controller.updater.delta;
    assign wu_activations  = top.backpropagator.weight_controller.updater.a;
    assign pre_activations = top.forward.layer_outputs;

    assign max_act    = ($signed(results[29*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]) > $signed(results[28*ACTIVATION_WIDTH+:ACTIVATION_FILE])) ? 0 : 1;
    assign max_target = ($signed(targets[29*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]) > $signed(targets[28*ACTIVATION_WIDTH+:ACTIVATION_FILE])) ? 0 : 1;

    integer i, j, k, l, m, n;

    always @ (posedge clk) begin
        if (top.backpropagator.error_calculator.error_fetcher.y_valid &&
            top.backpropagator.error_calculator.error_fetcher.y_ready) begin
            $write("target: ");
            for (i=NEURON_NUM-1; i>=0; i=i-1) begin
                $write("%d, ", $signed(targets[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]));
            end
            $write("\n");
            max_target_buffer <= max_target;
        end
        
        if (top.forward.layer_outputs_valid && top.forward.layer_outputs_ready) begin
            $write("sums: "); 
            for (j=NEURON_NUM-1; j>=0; j=j-1) begin
                $write("%d, ", $signed(pre_activations[j*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH]));
            end
            $write("\n");
        end
        
        if (top.backpropagator.error_calculator.error_fetcher.sigma_result_valid &&
            top.backpropagator.error_calculator.error_fetcher.subtracter_input_ready) begin
            max_act_buffer <= max_act;
        end

        if (top.backpropagator.error_calculator.error_fetcher.subtracter_result_valid && 
            top.backpropagator.error_calculator.error_fetcher.subtracter_result_ready) begin
            $write("errors: ");
            for (k=NEURON_NUM-1; k>=0; k=k-1) begin
                $write("%d, ", $signed(subtract[k*(ACTIVATION_WIDTH+1)+:(ACTIVATION_WIDTH+1)]));
            end
            $write("\n");
        end
        
        if (top.backpropagator.error_calculator.error_fetcher.subtracter_result_valid && 
            top.backpropagator.error_calculator.error_fetcher.subtracter_result_ready) begin
            classification_buffer <= classification_buffer * ((SMOOTH_WINDOW- 1.0) / SMOOTH_WINDOW) + (max_act_buffer == max_target_buffer) * (1.0 / SMOOTH_WINDOW);
            classification_buffer_int <= $rtoi(classification_buffer * 100.0);
        end

        if (top.backpropagator.error_calculator.error_fetcher.delta_output_valid && 
            top.backpropagator.error_calculator.error_fetcher.delta_output_ready) begin
            $write("delta: ");
            for (l=NEURON_NUM-1; l>=0; l=l-1) begin
                $write("%d, ", $signed(deltas[l*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]));
            end
            $write("\n");
        end

        if (top.backpropagator.weight_controller.updater.product_result_valid &&
            top.backpropagator.weight_controller.updater.product_result_ready) begin
            $write("changes: ");
            for (i=NEURON_NUM-1; i>=0; i=i-1) begin
                for (j=NEURON_NUM-1; j>=0; j=j-1) begin
                    $write("%d, ", $signed(updates[(i*NEURON_NUM+j)*W+:W]));
                end
                $write("\n");
            end
        end

        if (top.backpropagator.weight_controller.updater.product_result_valid &&
            top.backpropagator.weight_controller.updater.product_result_ready) begin
            $write("shifted: ");
            for (i=NEURON_NUM-1; i>=0; i=i-1) begin
                for (j=NEURON_NUM-1; j>=0; j=j-1) begin
                    $write("%d, ", $signed(updates_shifted[(i*NEURON_NUM+j)*W+:W]));
                end
                $write("\n");
            end
        end

        if (top.backpropagator.weight_controller.updater.adder_result_valid &&
            top.backpropagator.weight_controller.updater.adder_result_ready) begin
            $write("weights: ");
            for (i=NEURON_NUM-1; i>=0; i=i-1) begin
                for (j=NEURON_NUM-1; j>=0; j=j-1) begin
                    $write("%d, ", $signed(weights[(i*NEURON_NUM+j)*W+:W]));
                end
                $write("\n");
            end
        end

    end


endmodule

