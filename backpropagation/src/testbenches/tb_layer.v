module tb_layer;

    parameter NEURON_NUM = 5,
              NEURON_OUTPUT_WIDTH = 10,
              WEIGHT_CELL_WIDTH   = 16,
              FRACTION            = 0;

    `include "log2.v"

    reg clk, rst;

    reg [log2(NEURON_NUM):0]                          curr_neurons; // number of neurons in the current layer
    reg                                               curr_neurons_valid;
    wire                                              curr_neurons_ready;

    reg [log2(NEURON_NUM):0]                          prev_neurons; // number of neurons in the previous layer 
    reg                                               prev_neurons_valid;
    wire                                              prev_neurons_ready;

    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          inputs;       // inputs from the previous layer
    reg                                               inputs_valid;
    wire                                              inputs_ready;

    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;      // layer weights
    reg                                               weights_valid;
    wire                                              weights_ready;

    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]         outputs;      // outputs of the current neurons
    wire                                              overflow;     // overflow of any neuron
    wire                                              outputs_valid;
    reg                                               outputs_ready;

    wire [NEURON_OUTPUT_WIDTH-1:0] output_mem [0:NEURON_NUM-1];
    genvar i;
    generate 
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM
        assign output_mem[i] = outputs[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
    end
    endgenerate


    layer #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION           (FRACTION           )  
    ) uut (
        .clk               (clk               ),
        .rst               (rst               ),
        .curr_neurons      (curr_neurons      ),
        .curr_neurons_valid(curr_neurons_valid),
        .curr_neurons_ready(curr_neurons_ready),
        .prev_neurons      (prev_neurons      ),
        .prev_neurons_valid(prev_neurons_valid),
        .prev_neurons_ready(prev_neurons_ready),
        .inputs            (inputs            ),
        .inputs_valid      (inputs_valid      ),
        .inputs_ready      (inputs_ready      ),
        .weights           (weights           ),
        .weights_valid     (weights_valid     ),
        .weights_ready     (weights_ready     ),
        .outputs           (outputs           ),
        .overflow          (overflow          ),
        .outputs_valid     (outputs_valid     ),
        .outputs_ready     (outputs_ready     )
    );

    always 
        #1 clk <= ~clk;


    initial begin
        clk <= 0;
        rst <= 1;        

        curr_neurons       <= 5;
        curr_neurons_valid <= 1;

        prev_neurons       <= 5;
        prev_neurons_valid <= 1;

        inputs             <= {10'd5, 10'd4, 10'd3, 10'd2, 10'd1};
        inputs_valid       <= 1;

        weights            <= {16'd5, 16'd4, 16'd3, 16'd2, 16'd1,
                               16'd6, 16'd5, 16'd4, 16'd3, 16'd2,
                               16'd7, 16'd6, 16'd5, 16'd4, 16'd3,
                               16'd8, 16'd7, 16'd6, 16'd5, 16'd4,
                               16'd9, 16'd8, 16'd7, 16'd6, 16'd5};
        weights_valid      <= 1;

        outputs_ready      <= 0;

        #10 rst            <= 0;
        #40 outputs_ready  <= 1;

    end

endmodule
