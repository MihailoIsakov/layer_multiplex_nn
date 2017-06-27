`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:12:49 02/16/2017
// Design Name:   backpropagator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_backpropagator.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: backpropagator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_backprop_single_layer;

    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 8,
              LEARNING_RATE_SHIFT = 0,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 0,  // number of layers in the network
              WEIGHT_INIT_FILE    = "weights4x4.list";

    reg clk;
    reg rst;
    // layer
    reg [LAYER_ADDR_WIDTH-1:0]                         layer_bw;
    reg                                                layer_bw_valid;
    wire                                               layer_bw_ready;
    // layer
    reg [LAYER_ADDR_WIDTH-1:0]                         layer_fw;
    reg                                                layer_fw_valid;
    wire                                               layer_fw_ready;
    // sample
    reg [NEURON_NUM*ACTIVATION_WIDTH-1:0]              sample;
    reg                                                sample_valid;
    wire                                               sample_ready;
    // z
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z;
    reg                                                z_valid;
    wire                                               z_ready;
    // z_prev
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z_prev;
    reg                                                z_prev_valid;
    wire                                               z_prev_ready;
    // weights
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire                                               weights_valid;
    reg                                                weights_ready;
    // overflow
    wire                                               error;
    
    backpropagator
    #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) uut (
        .clk           (clk           ),
        .rst           (rst           ),
        .layer_bw      (layer_bw      ),
        .layer_bw_valid(layer_bw_valid),
        .layer_bw_ready(layer_bw_ready),
        .layer_fw      (layer_fw      ),
        .layer_fw_valid(layer_fw_valid),
        .layer_fw_ready(layer_fw_ready),
        .sample        (sample        ),
        .sample_valid  (sample_valid  ),
        .sample_ready  (sample_ready  ),
        .z             (z             ),
        .z_valid       (z_valid       ),
        .z_ready       (z_ready       ),
        .z_prev        (z_prev        ),
        .z_prev_valid  (z_prev_valid  ),
        .z_prev_ready  (z_prev_ready  ),
        .weights       (weights       ),
        .weights_valid (weights_valid ),
        .weights_ready (weights_ready ),
        .error         (error         )
    );


    always 
        #1 clk = ~clk;


    initial begin
        clk <= 0;
        rst <= 1;

        layer_bw         <= 0;
        layer_bw_valid   <= 0;

        layer_fw         <= 0;
        layer_fw_valid   <= 1;

        sample           <= 0;
        sample_valid     <= 0;

		z                <= {10'd800, 10'd700, 10'd600, 10'd500}; // 10, 20, 30, 40, 50
        z_valid          <= 0;

		z_prev           <= {10'd800, 10'd700, 10'd600, 10'd500}; // 10, 20, 30, 40, 50
        z_prev_valid     <= 0;

        weights_ready    <= 1;

        #10 rst          <= 0;

        #10 layer_bw_valid <= 1;
            sample_valid <= 1;
            z_valid      <= 1;
            z_prev_valid <= 1;

    end



    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Testing
    //////////////////////////////////////////////////////////////////////////////////////////////////// 

//    wire signed [WEIGHT_CELL_WIDTH  -1:0] weights_mem [0:NEURON_NUM*NEURON_NUM-1];
//    wire signed [WEIGHT_CELL_WIDTH-1:0] product_result_shifted_mem [0:NEURON_NUM*NEURON_NUM-1];
//    wire signed product_result_shifted_mem_valid;
//
//    genvar x;
//    generate
//    for (x=0; x<NEURON_NUM*NEURON_NUM; x=x+1) begin: MEM2
//        assign weights_mem[x] = $signed(bp.w_wc[x*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH]);
//        assign product_result_shifted_mem[x] = bp.weight_controller.updater.product_result_shifted_mem[x];
//        assign product_result_shifted_mem_valid = bp.weight_controller.updater.product_result_valid;
//    end
//    endgenerate
//    
//    always @ (posedge clk) begin
//        if (bp.delta_ef_valid && bp.delta_ef_ready) begin
//            $write("Delta top:");
//            for (j=0; j<NEURON_NUM; j=j+1) begin
//                $write("%d, ", bp.delta_ef[j*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]);
//            end
//            $write("\n");
//        end
//
//        // print weights when valid
//        //if (weights_valid && weights_ready) begin
//            //$write("WEIGHTS - layer: %d, time: %0d:  ", layer, $stime);
//            //for (j=0; j<NEURON_NUM*NEURON_NUM; j=j+1) begin
//                //$write("%d,      ", weights_mem[j]);
//            //end
//            //$write("\n");
//        //end
//    end


endmodule

