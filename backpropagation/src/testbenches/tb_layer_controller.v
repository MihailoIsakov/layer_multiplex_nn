module tb_layer_controller;

    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10, // size of neuron sum
              ACTIVATION_WIDTH    = 9,  // size of the neuron's activation
              LAYER_ADDR_WIDTH    = 1,  // width of the layer number 
              LAYER_MAX           = 3;   // number of layers in the network


    reg clk;
    reg rst;
    // reg layer values
    reg [NEURON_NUM*ACTIVATION_WIDTH-1:0]     start_inputs; 
    reg                                       start_inputs_valid;
    wire                                      start_inputs_ready;
    // current layer number 
    reg [LAYER_ADDR_WIDTH-1:0]                layer_number; 
    reg                                       layer_number_valid;
    wire                                      layer_number_ready;
    // outputs from the layer module; reg to this module
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]  layer_outputs;
    reg                                       layer_outputs_valid;
    wire                                      layer_outputs_ready;
    // regs to the layer module; output from this module
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] layer_inputs;
    wire                                      layer_inputs_valid;
    reg                                       layer_inputs_ready;

    layer_controller #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          )
    ) uut (
        .clk                (clk                ),
        .rst                (rst                ),
        .start_inputs       (start_inputs       ),
        .start_inputs_valid (start_inputs_valid ),
        .start_inputs_ready (start_inputs_ready ),
        .layer_number       (layer_number       ),
        .layer_number_valid (layer_number_valid ),
        .layer_number_ready (layer_number_ready ),
        .layer_outputs      (layer_outputs      ),
        .layer_outputs_valid(layer_outputs_valid),
        .layer_outputs_ready(layer_outputs_ready),
        .layer_inputs       (layer_inputs       ),
        .layer_inputs_valid (layer_inputs_valid ),
        .layer_inputs_ready (layer_inputs_ready )
    );

    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;

        start_inputs        <= {9'd5, 9'd4, 9'd3, 9'd2, 9'd1};
        start_inputs_valid  <= 0;

        layer_number        <= 0;
        layer_number_valid  <= 0;

        layer_outputs       <= {12'd3500, 12'd3000, 12'd2500, 12'd2000, 12'd1500};
        layer_outputs_valid <= 0;

        layer_inputs_ready  <= 0;

        #10 rst <= 0;
            
        // inputs arrive
        #10 start_inputs_valid  <= 1;
        #2  start_inputs_valid  <= 0;

        // also the zero layer number 
        #10 layer_number_valid  <= 1;
        #2  layer_number_valid  <= 0;

        // the layer accepts layer zero inputs
        #10 layer_inputs_ready  <= 1;
        #2  layer_inputs_ready  <= 0;

        // layer finished processing, returns first hidden layer activations
        #20 layer_outputs_valid <= 1;
        #2  layer_outputs_valid <= 0;

        // layer 1 number comes in
        #20 layer_number        <= 1;
            layer_number_valid  <= 1;
        #2  layer_number_valid  <= 0;

        // next layer comes in
        #20 layer_outputs_valid <= 1;
            layer_number_valid  <= 1;
        #2  layer_number_valid  <= 0;
            layer_outputs_valid <= 0;

        // layer accepts input
        #10 layer_inputs_ready  <= 1;
        #2  layer_inputs_ready  <= 0;

        // next layer comes in
        #20 layer_outputs_valid <= 1;
            layer_number_valid  <= 1;
        #2  layer_number_valid  <= 0;
            layer_outputs_valid <= 0;

        // layer accepts input
        #10 layer_inputs_ready  <= 1;
        #2  layer_inputs_ready  <= 0;

    end


endmodule
