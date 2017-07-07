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

    parameter NEURON_NUM          = 4,
              NEURON_OUTPUT_WIDTH = 12,
              ACTIVATION_WIDTH    = 9,
              WEIGHT_CELL_WIDTH   = 16,
              DELTA_CELL_WIDTH    = 12,
              FRACTION            = 8,
              DATASET_ADDR_WIDTH  = 8,
              MAX_SAMPLES         = 150,
              //MAX_SAMPLES         = 1,
              LAYER_ADDR_WIDTH    = 2,
              LEARNING_RATE_SHIFT = 12,
              LAYER_MAX           = 1,
              WEIGHT_INIT_FILE    = "weights4x4.list",
              INPUT_SAMPLES_FILE  = "iris_input_4neuron_9bit.list",
              OUTPUT_SAMPLES_FILE = "iris_output_4neuron_9bit.list";

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
        .OUTPUT_SAMPLES_FILE(OUTPUT_SAMPLES_FILE)
    ) top (
        .clk(clk),
        .rst(rst)
    );


    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;

        #20 rst <= 0;

    end

    localparam W=WEIGHT_CELL_WIDTH;

    wire [NEURON_NUM*(ACTIVATION_WIDTH+1)-1:0] subtract;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] targets, results, derivative, wu_activations;
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] deltas, wu_deltas;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights, updates, updated;

    wire signed [ACTIVATION_WIDTH-1:0] y1, y2, y3, y4;
    wire signed [ACTIVATION_WIDTH-1:0] a1, a2, a3, a4;
    wire signed [ACTIVATION_WIDTH:0] s1, s2, s3, s4;
    wire signed [DELTA_CELL_WIDTH-1:0] d1, d2, d3, d4;
    wire signed [ACTIVATION_WIDTH:0] p1, p2, p3, p4;

    assign subtract       = top.backpropagator.error_calculator.error_fetcher.subtracter_result;
    assign targets        = top.backpropagator.error_calculator.error_fetcher.y;
    assign results        = top.backpropagator.error_calculator.error_fetcher.a;
    assign deltas         = top.backpropagator.error_calculator.error_fetcher.delta_output;
    assign derivative     = top.backpropagator.error_calculator.error_fetcher.sigma_der_result;
    assign weights        = top.backpropagator.weight_controller.updater.w;
    assign updates        = top.backpropagator.weight_controller.updater.product_result_shifted;
    assign updated        = top.backpropagator.weight_controller.updater.adder_result;
    assign wu_deltas      = top.backpropagator.weight_controller.updater.delta;
    assign wu_activations = top.backpropagator.weight_controller.updater.a;

    assign y1 = targets[1*ACTIVATION_WIDTH-1:0*ACTIVATION_WIDTH];
    assign y2 = targets[2*ACTIVATION_WIDTH-1:1*ACTIVATION_WIDTH];
    assign y3 = targets[3*ACTIVATION_WIDTH-1:2*ACTIVATION_WIDTH];
    assign y4 = targets[4*ACTIVATION_WIDTH-1:3*ACTIVATION_WIDTH];

    assign a1 = results[1*ACTIVATION_WIDTH-1:0*ACTIVATION_WIDTH];
    assign a2 = results[2*ACTIVATION_WIDTH-1:1*ACTIVATION_WIDTH];
    assign a3 = results[3*ACTIVATION_WIDTH-1:2*ACTIVATION_WIDTH];
    assign a4 = results[4*ACTIVATION_WIDTH-1:3*ACTIVATION_WIDTH];

    assign s1 = subtract[1*(ACTIVATION_WIDTH+1)-1:0*(ACTIVATION_WIDTH+1)];
    assign s2 = subtract[2*(ACTIVATION_WIDTH+1)-1:1*(ACTIVATION_WIDTH+1)];
    assign s3 = subtract[3*(ACTIVATION_WIDTH+1)-1:2*(ACTIVATION_WIDTH+1)];
    assign s4 = subtract[4*(ACTIVATION_WIDTH+1)-1:3*(ACTIVATION_WIDTH+1)];

    assign d1 = deltas[0*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    assign d2 = deltas[1*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    assign d3 = deltas[2*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    assign d4 = deltas[3*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];

    assign p1 = derivative[0*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
    assign p2 = derivative[1*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
    assign p3 = derivative[2*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
    assign p4 = derivative[3*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];

    always @ (posedge clk) begin
        if (top.backpropagator.error_calculator.error_fetcher.y_valid &&
            top.backpropagator.error_calculator.error_fetcher.y_ready)
            $display("targets:    %d %d %d %d", y1, y2, y3, y4);

        if (top.backpropagator.error_calculator.error_fetcher.sigma_result_valid &&
            top.backpropagator.error_calculator.error_fetcher.subtracter_input_ready)
            $display("outputs:    %d %d %d %d", a1, a2, a3, a4);

        //if (top.backpropagator.error_calculator.error_fetcher.subtracter_result_valid && 
            //top.backpropagator.error_calculator.error_fetcher.subtracter_result_ready) 
            //$display("errors:     %d %d %d %d", s1, s2, s3, s4);
        
        //if (top.backpropagator.error_calculator.error_fetcher.sigma_der_result_valid &&
            //top.backpropagator.error_calculator.error_fetcher.sigma_der_result_ready)
            //$display("derivative: %d %d %d %d", p1, p2, p3, p4);

        //if (top.backpropagator.error_calculator.error_fetcher.delta_output_valid && 
            //top.backpropagator.error_calculator.error_fetcher.delta_output_ready)
            //$display("delta:      %d %d %d %d", $signed(d1), $signed(d2), $signed(d3), $signed(d4));

        //if (top.backpropagator.weight_controller.updater.delta_valid &&
            //top.backpropagator.weight_controller.updater.delta_valid)
            //$display("wu_delta: %d %d %d %d", 
                //$signed(wu_deltas[0*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]), 
                //$signed(wu_deltas[1*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]), 
                //$signed(wu_deltas[2*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]), 
                //$signed(wu_deltas[3*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]));

        //if (top.backpropagator.weight_controller.updater.a_valid &&
            //top.backpropagator.weight_controller.updater.a_ready)
            //$display("wu_activ: %d %d %d %d",
                //$signed(wu_activations[0*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]),
                //$signed(wu_activations[1*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]),
                //$signed(wu_activations[2*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]),
                //$signed(wu_activations[3*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]));

        //if (top.backpropagator.weight_controller.updater.w_valid &&
            //top.backpropagator.weight_controller.updater.w_ready)
            //$display("weights: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", 
                //$signed(weights[ 0*W+:W]), $signed(weights[ 1*W+:W]), $signed(weights[ 2*W+:W]), $signed(weights[ 3*W+:W]), 
                //$signed(weights[ 4*W+:W]), $signed(weights[ 5*W+:W]), $signed(weights[ 6*W+:W]), $signed(weights[ 7*W+:W]), 
                //$signed(weights[ 8*W+:W]), $signed(weights[ 9*W+:W]), $signed(weights[10*W+:W]), $signed(weights[11*W+:W]), 
                //$signed(weights[12*W+:W]), $signed(weights[13*W+:W]), $signed(weights[14*W+:W]), $signed(weights[15*W+:W]));

        if (top.backpropagator.weight_controller.updater.product_result_valid &&
            top.backpropagator.weight_controller.updater.product_result_ready)
            $display("changes: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", 
                $signed(updates[ 0*W+:W]), $signed(updates[ 1*W+:W]), $signed(updates[ 2*W+:W]), $signed(updates[ 3*W+:W]), 
                $signed(updates[ 4*W+:W]), $signed(updates[ 5*W+:W]), $signed(updates[ 6*W+:W]), $signed(updates[ 7*W+:W]), 
                $signed(updates[ 8*W+:W]), $signed(updates[ 9*W+:W]), $signed(updates[10*W+:W]), $signed(updates[11*W+:W]), 
                $signed(updates[12*W+:W]), $signed(updates[13*W+:W]), $signed(updates[14*W+:W]), $signed(updates[15*W+:W]));

        //if (top.backpropagator.weight_controller.updater.adder_result_valid &&
            //top.backpropagator.weight_controller.updater.adder_result_ready)
            //$display("updated: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", 
                //$signed(updated[ 0*W+:W]), $signed(updated[ 1*W+:W]), $signed(updated[ 2*W+:W]), $signed(updated[ 3*W+:W]), 
                //$signed(updated[ 4*W+:W]), $signed(updated[ 5*W+:W]), $signed(updated[ 6*W+:W]), $signed(updated[ 7*W+:W]), 
                //$signed(updated[ 8*W+:W]), $signed(updated[ 9*W+:W]), $signed(updated[10*W+:W]), $signed(updated[11*W+:W]), 
                //$signed(updated[12*W+:W]), $signed(updated[13*W+:W]), $signed(updated[14*W+:W]), $signed(updated[15*W+:W]));

    end


endmodule

