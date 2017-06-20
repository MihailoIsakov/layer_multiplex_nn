`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2017 12:17:01 PM
// Design Name: 
// Module Name: tb_neuron
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_neuron;
    
    parameter NEURON_NUM          = 5,
              NEURON_OUTPUT_WIDTH = 10,
              WEIGHT_CELL_WIDTH   = 16,
              FRACTION            = 1;

    `include "log2.v"

    reg clk;
    reg rst;
    reg   [log2(NEURON_NUM):0]                 input_number; 
    reg                                        input_number_valid;
    wire                                       input_number_ready;
    reg   [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] inputs;    
    reg                                        inputs_valid;
    wire                                       inputs_ready;
    reg   [NEURON_NUM*WEIGHT_CELL_WIDTH-1  :0] weights;    
    reg                                        weights_valid;
    wire                                       weights_ready;
    wire   [NEURON_OUTPUT_WIDTH-1:0]           neuron_sum;  
    wire                                       overflow;     
    wire                                       neuron_sum_valid;
    reg                                        neuron_sum_ready;

    neuron #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION           (FRACTION           )
    ) neuron (
        .clk               (clk               ),
        .rst               (rst               ),
        .input_number      (input_number      ),
        .input_number_valid(input_number_valid),
        .input_number_ready(input_number_ready),
        .inputs            (inputs            ),
        .inputs_valid      (inputs_valid      ),
        .inputs_ready      (inputs_ready      ),
        .weights           (weights           ),
        .weights_valid     (weights_valid     ),
        .weights_ready     (weights_ready     ),
        .neuron_sum        (neuron_sum        ),
        .overflow          (overflow          ),
        .neuron_sum_valid  (neuron_sum_valid  ),
        .neuron_sum_ready  (neuron_sum_ready  )
    );

    always 
        #1 clk = ~clk;

    initial begin
        clk                    <= 0;
        rst                    <= 1;

        input_number           <= NEURON_NUM;
        input_number_valid     <= 1;

        inputs                 <= {10'd5, 10'd4, 10'd3, 10'd2, 10'd1};
        inputs_valid           <= 1;

        weights                <= {16'd10, 16'd8, 16'd6, 16'd4, 16'd2};
        weights_valid          <= 1;

        neuron_sum_ready       <= 0;

        #10 rst                <= 0;

        #4 inputs_valid        <= 0;
           weights_valid       <= 0;
           input_number_valid  <= 0;

        #20 neuron_sum_ready   <= 1;

        #10 inputs_valid       <= 1;
            weights_valid      <= 1;
            input_number_valid <= 1;
            weights            <= {16'd100, 16'd80, 16'd60, 16'd40, 16'd20};

    end

endmodule
