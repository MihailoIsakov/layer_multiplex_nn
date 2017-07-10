module error_fetcher
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              FRACTION_WIDTH      = 0,
              ACTIVATION_FILE     = "sigmoid.list",
              ACTIVATION_DER_FILE = "derivative.list"
)(
    input clk,
    input rst,
    // Sample 
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]    y,
    input                                      y_valid,
    output                                     y_ready,
    // Neuron input
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z,
    input                                      z_valid,
    output                                     z_ready,
    // Delta output
    output [NEURON_NUM*DELTA_CELL_WIDTH-1:0]   delta_output,
    output                                     delta_output_valid,
    input                                      delta_output_ready,
    // Overflow error
    output                                     error
);
    // z splitter
    wire [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z_fifo_1, z_fifo_2;
    wire z_fifo_1_valid, z_fifo_1_ready, z_fifo_2_valid, z_fifo_2_ready;
    // sigma module
    wire sigma_result_valid;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a; 
    // sigma derivative module
    wire sigma_der_result_ready, sigma_der_result_valid;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] sigma_der_result; 
    // subtracter module
    wire subtracter_result_ready, subtracter_result_valid;
    wire [NEURON_NUM*(ACTIVATION_WIDTH+1)-1:0] subtracter_result; 
    wire                                       subtracter_input_ready;
    // doter module
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] dot_result; 
    wire dot_result_ready, dot_result_valid;

    wire dot_error, subtracter_error, activation_1_of, activation_2_of;

    fifo_splitter2 #(NEURON_NUM*NEURON_OUTPUT_WIDTH)
    z_splitter (
        .clk            (clk),
        .rst            (rst),
        .data_in        (z),
        .data_in_valid  (z_valid),
        .data_in_ready  (z_ready),
        .data_out1      (z_fifo_1),
        .data_out1_valid(z_fifo_1_valid),
        .data_out1_ready(z_fifo_1_ready),
        .data_out2      (z_fifo_2),
        .data_out2_valid(z_fifo_2_valid),
        .data_out2_ready(z_fifo_2_ready)
    );

    lut #(
        .NEURON_NUM    (NEURON_NUM              ),
        .FRACTION_WIDTH(FRACTION_WIDTH          ),
        .LUT_ADDR_SIZE (NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH     (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH     (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE (ACTIVATION_FILE         ))
    sigma (
        .clk          (clk                   ),
        .rst          (rst                   ),
        .inputs       (z_fifo_1              ),
        .inputs_valid (z_fifo_1_valid        ),
        .inputs_ready (z_fifo_1_ready        ),
        .outputs      (a                     ),
        .overflow     (activation_1_of       ),
        .outputs_valid(sigma_result_valid    ),
        .outputs_ready(subtracter_input_ready)
    );

    lut #(
        .NEURON_NUM    (NEURON_NUM              ),
        .FRACTION_WIDTH(FRACTION_WIDTH          ),
        .LUT_ADDR_SIZE (NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH     (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH     (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE (ACTIVATION_DER_FILE     )) 
    sigma_derivative (
        .clk          (clk                   ),
        .rst          (rst                   ),
        .inputs       (z_fifo_2              ),
        .inputs_valid (z_fifo_2_valid        ),
        .inputs_ready (z_fifo_2_ready        ),
        .outputs      (sigma_der_result      ),
        .overflow     (activation_2_of       ),
        .outputs_valid(sigma_der_result_valid),
        .outputs_ready(sigma_der_result_ready)
    );


    // FIXME possibly need to switch a and b
    vector_subtract #(  
        .VECTOR_LEN       (NEURON_NUM        ),
        .A_CELL_WIDTH     (ACTIVATION_WIDTH  ),
        .B_CELL_WIDTH     (ACTIVATION_WIDTH  ),
        .RESULT_CELL_WIDTH(ACTIVATION_WIDTH+1),
        .TILING           (2                 )
    ) subtracter (
        .clk         (clk                    ),
        .rst         (rst                    ),
        .a           (y                      ),
        .a_valid     (y_valid                ),
        .a_ready     (y_ready                ),
        .b           (a                      ),
        .b_valid     (sigma_result_valid     ),
        .b_ready     (subtracter_input_ready ),
        .result      (subtracter_result      ),
        .result_valid(subtracter_result_valid),
        .result_ready(subtracter_result_ready),
        .error       (subtracter_error       )
    );

    vector_dot #(
        .VECTOR_LEN       (NEURON_NUM        ),
        .A_CELL_WIDTH     (ACTIVATION_WIDTH+1),
        .B_CELL_WIDTH     (ACTIVATION_WIDTH  ),
        .RESULT_CELL_WIDTH(DELTA_CELL_WIDTH  ),
        .FRACTION_WIDTH   (FRACTION_WIDTH    ),
        .TILING           (2                 )
    ) doter (
        .clk         (clk                    ),
        .rst         (rst                    ),
        .a           (subtracter_result      ),
        .a_valid     (subtracter_result_valid),
        .a_ready     (subtracter_result_ready),
        .b           (sigma_der_result       ),
        .b_valid     (sigma_der_result_valid ),
        .b_ready     (sigma_der_result_ready ),
        .result      (dot_result             ),
        .result_valid(dot_result_valid       ),
        .result_ready(dot_result_ready       ),
        .error       (dot_error              )
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    assign delta_output       = dot_result;
    assign delta_output_valid = dot_result_valid;
    assign dot_result_ready   = delta_output_ready;
    assign error              = dot_error | subtracter_error | activation_1_of | activation_2_of;

    //////////////////////////////////////////////////////////////////////////
    // Testing 
    //////////////////////////////////////////////////////////////////////////
    
    //wire [NEURON_OUTPUT_WIDTH-1:0] z_mem      [0:NEURON_NUM-1];
    //wire [ACTIVATION_WIDTH-1   :0] a_mem      [0:NEURON_NUM-1];
    //wire [ACTIVATION_WIDTH-1   :0] y_mem      [0:NEURON_NUM-1];
    //wire [ACTIVATION_WIDTH-1   :0] a_prim_mem [0:NEURON_NUM-1];
    //wire [ACTIVATION_WIDTH     :0] sub_mem    [0:NEURON_NUM-1];
    //wire [DELTA_CELL_WIDTH-1   :0] dot_mem    [0:NEURON_NUM-1];
    //wire [DELTA_CELL_WIDTH-1   :0] out_mem    [0:NEURON_NUM-1];

    //genvar i; 
    //generate 
    //for (i=0; i<NEURON_NUM; i=i+1) begin:MEM
        //assign z_mem[i]      = z                [i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
        //assign a_mem[i]      = a                [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        //assign y_mem[i]      = y                [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        //assign a_prim_mem[i] = sigma_der_result [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        //assign sub_mem[i]    = subtracter_result[i*(1+ACTIVATION_WIDTH)+:(1+ACTIVATION_WIDTH)];
        //assign dot_mem[i]    = dot_result       [i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
        //assign out_mem[i]    = delta_output     [i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    //end
    //endgenerate

endmodule
