module weight_updater
#(
    parameter NEURON_NUM          = 5,  // size of the vectors a and delta
              ACTIVATION_WIDTH    = 9,  // width of each signal from the neurons
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 0,
              LEARNING_RATE_SHIFT = 0
)
(
    input clk,
    input rst,
    // a
    input  [NEURON_NUM*ACTIVATION_WIDTH-1:0]             a,
    input                                                a_valid,
    output                                               a_ready,
    // delta
    input  [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta,
    input                                                delta_valid,
    output                                               delta_ready,
    // w
    input  [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w,
    input                                                w_valid,
    output                                               w_ready,
    // result
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] result,
    output                                               result_valid,
    input                                                result_ready,
    // overflow
    output                                               error
);

    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] product_result, adder_result;
    wire product_result_valid, product_result_ready, adder_result_valid, adder_result_ready;
    wire product_error, adder_error;

    tensor_product #(
        .A_VECTOR_LEN     (NEURON_NUM       ),
        .B_VECTOR_LEN     (NEURON_NUM       ),
        .A_CELL_WIDTH     (ACTIVATION_WIDTH ),
        .B_CELL_WIDTH     (DELTA_CELL_WIDTH ),
        .RESULT_CELL_WIDTH(WEIGHT_CELL_WIDTH),
        .FRACTION_WIDTH   (FRACTION_WIDTH   ),
        .TILING_H         (2                ),
        .TILING_V         (2                )
    ) tensor_product (
        .clk         (clk                 ),
        .rst         (rst                 ),
        .a           (a                   ),
        .a_valid     (a_valid             ),
        .a_ready     (a_ready             ),
        .b           (delta               ),
        .b_valid     (delta_valid         ),
        .b_ready     (delta_ready         ),
        .result      (product_result      ),
        .result_valid(product_result_valid),
        .result_ready(product_result_ready),
        .error       (product_error       )
    );
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////  
    // learning rate shift
    ////////////////////////////////////////////////////////////////////////////////////////////////////  
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] product_result_shifted;
    genvar x;

    generate
        for (x=0; x<NEURON_NUM*NEURON_NUM; x=x+1) begin: LEARNING_RATE
            assign product_result_shifted[x*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH] 
                = (product_result[x*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH] >>> LEARNING_RATE_SHIFT);
        end
    endgenerate


    vector_add
    #(
        .VECTOR_LEN       (NEURON_NUM*NEURON_NUM),
        .A_CELL_WIDTH     (WEIGHT_CELL_WIDTH    ),
        .B_CELL_WIDTH     (WEIGHT_CELL_WIDTH    ),
        .RESULT_CELL_WIDTH(WEIGHT_CELL_WIDTH    ),
        .TILING           (2                    )
    ) vector_add (
        .clk         (clk                   ),
        .rst         (rst                   ),
        .a           (product_result_shifted),
        .a_valid     (product_result_valid  ),
        .a_ready     (product_result_ready  ),
        .b           (w                     ),
        .b_valid     (w_valid               ),
        .b_ready     (w_ready               ),
        .result      (adder_result          ),
        .result_valid(adder_result_valid    ),
        .result_ready(adder_result_ready    ),
        .error       (adder_error           )
    );

    //outputs
    assign result             = adder_result;
    assign result_valid       = adder_result_valid;
    assign adder_result_ready = result_ready;
    assign error              = product_error | adder_error;

    //testing
    genvar i;
    wire [WEIGHT_CELL_WIDTH-1:0] product_result_mem         [0:NEURON_NUM*NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] product_result_shifted_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] adder_result_mem           [0:NEURON_NUM*NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] w_mem                      [0:NEURON_NUM*NEURON_NUM-1];

    generate
    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM
        assign product_result_mem[i]         = product_result[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign product_result_shifted_mem[i] = product_result_shifted[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign adder_result_mem[i]           = adder_result  [i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign w_mem[i]                      = w             [i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate

endmodule
