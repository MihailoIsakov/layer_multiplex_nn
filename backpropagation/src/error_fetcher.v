module error_fetcher
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              FRACTION_WIDTH      = 0,
              LAYER_ADDR_WIDTH    = 2,  // size of the layer number 
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list"

)(
    input clk,
    input rst,
    // Meta
    input [LAYER_ADDR_WIDTH-1:0]               layer,
    input [SAMPLE_ADDR_SIZE-1:0]               sample_index,
    // Neuron input
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z,
    input                                      z_valid,
    output                                     z_ready,
    // Delta input
    input [NEURON_NUM*DELTA_CELL_WIDTH-1:0]    delta_input,
    input                                      delta_input_valid,
    output                                     delta_input_ready,
    // Delta output
    output [NEURON_NUM*DELTA_CELL_WIDTH-1:0]   delta_output,
    output                                     delta_output_valid,
    input                                      delta_output_ready,
    // Overflow error
    output                                     error
);

    // sigma module
    wire sigma_result_valid, z_sigma_ready;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a; 
    // sigma derivative module
    wire sigma_der_result_ready, sigma_der_result_valid, z_sigma_der_ready;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] sigma_der_result; 
    // subtracter module
    wire subtracter_result_ready, subtracter_result_valid;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] y; 
    wire [NEURON_NUM*(ACTIVATION_WIDTH+1)-1:0] subtracter_result; 
    wire                                       subtracter_input_ready;
    // doter module
    wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] dot_result; 
    wire dot_result_ready, dot_result_valid;

    wire dot_error, subtracter_error;

    lut #(
        .NEURON_NUM   (NEURON_NUM              ),
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE("sigmoid.list"          ))
    sigma (
        .clk          (clk                   ),
        .rst          (rst                   ),
        .inputs       (z                     ),
        .inputs_valid (z_valid               ),
        .inputs_ready (z_sigma_ready         ),
        .outputs      (a                     ),
        .outputs_valid(sigma_result_valid    ),
        .outputs_ready(subtracter_input_ready)
    );

    lut #(
        .NEURON_NUM   (NEURON_NUM              ),
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH        ),
        .LUT_INIT_FILE("derivative.list"       )) 
    sigma_derivative(
        .clk          (clk                   ),
        .rst          (rst                   ),
        .inputs       (z                     ),
        .inputs_valid (z_valid               ),
        .inputs_ready (z_sigma_der_ready     ),
        .outputs      (sigma_der_result      ),
        .outputs_valid(sigma_der_result_valid),
        .outputs_ready(sigma_der_result_ready)
    );

    BRAM #(
        .DATA_WIDTH(NEURON_NUM*ACTIVATION_WIDTH),
        .ADDR_WIDTH(SAMPLE_ADDR_SIZE           ),
        .INIT_FILE (TARGET_FILE                )) 
    targets_bram (
		.clock       (clk         ),
    	.readEnable  (1'b1        ),
    	.readAddress (sample_index),
   		.readData    (y           ),
    	.writeEnable (1'b0        ),
    	.writeAddress(            ),
    	.writeData   (            )
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
        .a_valid     (1'b1                   ),
        .a_ready     (                       ),
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

    // outputs
    assign delta_output       = (layer==LAYER_MAX) ? dot_result       : delta_input;
    assign delta_output_valid = (layer==LAYER_MAX) ? dot_result_valid : delta_input_valid;
    // tricky part: if the layer is max, ready should go to the doter module, otherwise go to delta_input_ready
    assign delta_input_ready  = (layer==LAYER_MAX) ? 1'b0               : delta_output_ready;
    assign dot_result_ready   = (layer==LAYER_MAX) ? delta_output_ready : 1'b0;
    
    assign z_ready = z_sigma_ready && z_sigma_der_ready;

    assign error = dot_error | subtracter_error;

    //////////////////////////////////////////////////////////////////////////
    // testing 
    //////////////////////////////////////////////////////////////////////////
    
    wire [NEURON_OUTPUT_WIDTH-1:0] z_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH-1   :0] a_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH-1   :0] y_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH-1   :0] a_prim_mem [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH     :0] sub_mem    [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1   :0] dot_mem    [0:NEURON_NUM-1];

    genvar i; 
    generate 
    for (i=0; i<NEURON_NUM; i=i+1) begin:MEM
        assign z_mem[i]      = z                [i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
        assign a_mem[i]      = a                [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign y_mem[i]      = y                [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign a_prim_mem[i] = sigma_der_result [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign sub_mem[i]    = subtracter_result[i*(1+ACTIVATION_WIDTH)+:(1+ACTIVATION_WIDTH)];
        assign dot_mem[i]    = dot_result       [i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end
    endgenerate

endmodule
