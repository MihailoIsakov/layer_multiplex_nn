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

module tb_backprop_func_test;

    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 12, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 8,
              LAYER_ADDR_WIDTH    = 1,
              LAYER_MAX           = 0,  // number of layers in the network
              LEARNING_RATE_SHIFT = 0,
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets4.list",
              WEIGHT_INIT_FILE    = "weights4x4.list";

	// Inputs
	reg clk;
	reg rst;

    // layer
    reg [LAYER_ADDR_WIDTH-1:0]                         layer;
    reg                                                layer_valid;
    wire                                               layer_ready;

    // sample
    reg [SAMPLE_ADDR_SIZE-1:0]                         sample;
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
    
	// Outputs
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire                                               weights_valid;
    reg                                                weights_ready;

    // overflow
    wire                                               error;

    integer i, j;
	// Instantiate the Unit Under Test (UUT)
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
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) bp (
        .clk          (clk          ),
        .rst          (rst          ),
        .layer        (layer        ),
        .layer_valid  (layer_valid  ),
        .layer_ready  (layer_ready  ),
        .sample       (sample       ),
        .sample_valid (sample_valid ),
        .sample_ready (sample_ready ),
        .z            (z            ),
        .z_valid      (z_valid      ),
        .z_ready      (z_ready      ),
        .z_prev       (z_prev       ),
        .z_prev_valid (z_prev_valid ),
        .z_prev_ready (z_prev_ready ),
        .weights      (weights      ),
        .weights_valid(weights_valid),
        .weights_ready(weights_ready),
        .error        (error        )
    );

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk           <= 0;
		rst           <= 1;

		layer         <= LAYER_MAX;
        layer_valid   <= 0;

		sample        <= 0;
        sample_valid  <= 0;

        bp.weight_controller.weights_bram.bram.ram[0] = {16'd17, -16'd18, -16'd32, 16'd14, 16'd9, 16'd40, 16'd12, -16'd27, 16'd42, 16'd36, -16'd54, -16'd14, 16'd32, 16'd7, -16'd29, 16'd7};
        bp.weight_controller.weights_bram.bram.ram[1] = {16'd17, -16'd18, -16'd32, 16'd14, 16'd9, 16'd40, 16'd12, -16'd27, 16'd42, 16'd36, -16'd54, -16'd14, 16'd32, 16'd7, -16'd29, 16'd7};

        bp.error_fetcher.targets_bram.ram[0] = 0;

		z             <= {-12'd11, -12'd5, -12'd34, -12'd8};
        z_valid       <= 1'b0;

		z_prev        <= {12'd0, 12'd76, 12'd153, 12'd230};
        z_prev_valid  <= 1'b0;

        weights_ready <= 1'b1;

        #10 rst       <= 0;

        #4 layer_valid   <= 1;
        #4 sample_valid  <= 1;
        #4 z_valid       <= 1;
        #4 z_prev_valid  <= 1;

        //for (i=0; i<1000; i=i+1) begin

            //#4 layer_valid   <= 1;
            //#2  layer_valid  <= 0;

            //#4 sample_valid  <= 1;
            //#2  sample_valid <= 0;

            //#4 z_valid       <= 1;
            //#2  z_valid      <= 0;

            //#4 z_prev_valid  <= 1;
            //#2  z_prev_valid <= 0;
            
        //end
        #100 $finish;

	end
    
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Testing
    //////////////////////////////////////////////////////////////////////////////////////////////////// 

    wire signed [WEIGHT_CELL_WIDTH  -1:0] weights_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire signed [WEIGHT_CELL_WIDTH-1:0] product_result_shifted_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire signed product_result_shifted_mem_valid;

    genvar x;
    generate
    for (x=0; x<NEURON_NUM*NEURON_NUM; x=x+1) begin: MEM2
        assign weights_mem[x] = $signed(bp.w_wc[x*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH]);
        assign product_result_shifted_mem[x] = bp.weight_controller.updater.product_result_shifted_mem[x];
        assign product_result_shifted_mem_valid = bp.weight_controller.updater.product_result_valid;
    end
    endgenerate
    
    always @ (posedge clk) begin
        //if (bp.error_fetcher.subtracter_result_valid && bp.error_fetcher.subtracter_result_ready) begin
            //$write("Target: ");
            //for (j=0; j<NEURON_NUM; j=j+1) begin
                //$write("%d, ", $signed(bp.error_fetcher.y[j*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]));
            //end
            //$write("\n");
        //end

        //if (bp.error_fetcher.z_valid && bp.error_fetcher.z_ready) begin
            //$write("z1: ");
            //for (j=0; j<NEURON_NUM; j=j+1) begin
                //$write("%d, ", $signed(bp.error_fetcher.z[j*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH]));
            //end
            //$write("\n");
        //end

        //if (bp.error_fetcher.sigma_result_valid && bp.error_fetcher.subtracter_input_ready) begin
            //$write("a1: ");
            //for (j=0; j<NEURON_NUM; j=j+1) begin
                //$write("%d, ", $signed(bp.error_fetcher.a[j*ACTIVATION_WIDTH+:ACTIVATION_WIDTH]));
            //end
            //$write("\n");
        //end

        //if (bp.error_fetcher.subtracter_result_valid && bp.error_fetcher.subtracter_result_ready) begin
            //$write("Subtracter: ");
            //for (j=0; j<NEURON_NUM; j=j+1) begin
                //$write("%d, ", $signed(bp.error_fetcher.subtracter_result[j*(ACTIVATION_WIDTH+1)+:(ACTIVATION_WIDTH+1)]));
            //end
            //$write("\n");
        //end

        //if (bp.delta_ef_valid && bp.delta_ef_ready) begin
            //$write("Delta top:");
            //for (j=0; j<NEURON_NUM; j=j+1) begin
                //$write("%d, ", $signed(bp.delta_ef[j*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]));
            //end
            //$write("\n");
        //end


        // print weights when valid
        if (weights_valid && weights_ready) begin
            $write("w_old: ");
            for (j=0; j<NEURON_NUM*NEURON_NUM; j=j+1) begin
                $write("%d,      ", weights_mem[j]);
            end
            $write("\n");
        end
        
        if (bp.weight_controller.updater.product_result_valid && bp.weight_controller.updater.product_result_ready) begin
            $write("w_update: ", layer, $stime);
            for (j=0; j<NEURON_NUM*NEURON_NUM; j=j+1) begin
                $write("%d,      ", $signed(bp.weight_controller.updater.product_result[j*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH]));
            end
            $write("\n");
        end

        if (bp.weight_controller.updater.adder_result_valid && bp.weight_controller.updater.adder_result_ready) begin
            $write("W_new: ", layer, $stime);
            for (j=0; j<NEURON_NUM*NEURON_NUM; j=j+1) begin
                $write("%d,      ", $signed(bp.weight_controller.updater.adder_result[j*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH]));
            end
            $write("\n");
        end
    end


endmodule

