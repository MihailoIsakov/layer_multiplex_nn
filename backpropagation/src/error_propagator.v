module error_propagator
#(
    parameter MATRIX_WIDTH       = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT      = 5,  // height of the weight matrix aka the number of rows and size of vector
              DELTA_CELL_WIDTH   = 8,  // width of each delta cell
              WEIGHTS_CELL_WIDTH = 8,  // widht of each matrix cell
              NEURON_ADDR_WIDTH  = 10, // width of activations from neurons before the sigmoid
              ACTIVATION_WIDTH   = 9,  // cell width after sigmoid
              FRACTION_WIDTH     = 4,
              TILING_ROW         = 3,  // number of vector_mac units to create
              TILING_COL         = 3   // number of multipliers per vector_mac unit
)(
    input clk,
    input rst,
    // delta input 
    input  [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0]                 delta_input,
    input                                                      delta_input_valid,
    output                                                     delta_input_ready,
    // z 
    input  [MATRIX_HEIGHT*NEURON_ADDR_WIDTH-1:0]               z,
    input                                                      z_valid,
    output                                                     z_ready,
    // w 
    input  [MATRIX_WIDTH*MATRIX_HEIGHT*WEIGHTS_CELL_WIDTH-1:0] w,
    input                                                      w_valid,
    output                                                     w_ready,
    // delta output
    output [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0]                delta_output,
    output                                                     delta_output_valid,
    input                                                      delta_output_ready, 
    // overflow
    output                                                     error
);

    wire [MATRIX_HEIGHT*MATRIX_WIDTH*WEIGHTS_CELL_WIDTH-1:0] w_transposed;

    wire [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0] mvm_result;
    wire mvm_result_valid, mvm_result_ready;
    wire [MATRIX_HEIGHT*ACTIVATION_WIDTH-1:0] lut_result;
    wire lut_result_ready, lut_result_valid;
    wire mvm_error, dot_error;

    transpose #(
        .WIDTH        (MATRIX_WIDTH      ),
        .HEIGHT       (MATRIX_HEIGHT     ),
        .ELEMENT_WIDTH(WEIGHTS_CELL_WIDTH)
    ) transpose (
        .input_matrix(w),
        .output_matrix(w_transposed)
    );

    mvm #(
        .MATRIX_WIDTH     (MATRIX_HEIGHT     ), // transposed!
        .MATRIX_HEIGHT    (MATRIX_WIDTH      ), // transposed!
        .VECTOR_CELL_WIDTH(DELTA_CELL_WIDTH  ),
        .MATRIX_CELL_WIDTH(WEIGHTS_CELL_WIDTH),
        .RESULT_CELL_WIDTH(DELTA_CELL_WIDTH  ),
        .FRACTION_WIDTH   (FRACTION_WIDTH    ),
        .TILING_ROW       (TILING_ROW        ),
        .TILING_COL       (TILING_COL        )) 
    mvm(
        .clk         (clk              ),
        .rst         (rst              ),
        .vector      (delta_input      ),
        .vector_valid(delta_input_valid),
        .vector_ready(delta_input_ready),
        .matrix      (w_transposed     ),
        .matrix_valid(w_valid          ),
        .matrix_ready(w_ready          ),
        .result      (mvm_result       ),
        .result_valid(mvm_result_valid ),
        .result_ready(mvm_result_ready ),
        .error       (mvm_error        )
    );

    lut #(
        .NEURON_NUM   (MATRIX_HEIGHT         ),
        .LUT_ADDR_SIZE(NEURON_ADDR_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_ADDR_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH      ),
        .LUT_INIT_FILE("derivative.list"     )
    ) sigmoid_derivative (
        .clk          (clk             ),
        .rst          (rst             ),
        .inputs       (z               ),
        .inputs_valid (z_valid         ),
        .inputs_ready (z_ready         ),
        .outputs      (lut_result      ),
        .outputs_valid(lut_result_valid),
        .outputs_ready(lut_result_ready)
    );

    vector_dot #(
        .VECTOR_LEN       (MATRIX_HEIGHT   ),
        .A_CELL_WIDTH     (DELTA_CELL_WIDTH),
        .B_CELL_WIDTH     (ACTIVATION_WIDTH),
        .RESULT_CELL_WIDTH(DELTA_CELL_WIDTH),
        .FRACTION_WIDTH   (FRACTION_WIDTH  ),
        .TILING           (2               )
    ) dot (
        .clk         (clk),
        .rst         (rst),
        .a           (mvm_result),
        .a_valid     (mvm_result_valid),
        .a_ready     (mvm_result_ready),
        .b           (lut_result),
        .b_valid     (lut_result_valid),
        .b_ready     (lut_result_ready),
        .result      (delta_output),
        .result_valid(delta_output_valid),
        .result_ready(delta_output_ready),
        .error       (dot_error)
    );

    // outputs
    assign error = mvm_error | dot_error;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////  
    // testing
    ////////////////////////////////////////////////////////////////////////////////////////////////////  
    wire [ACTIVATION_WIDTH-1:0] activation_mem [MATRIX_HEIGHT-1:0];
    wire [DELTA_CELL_WIDTH-1:0] mvm_mem        [MATRIX_HEIGHT-1:0];
    wire [DELTA_CELL_WIDTH-1:0] dot_mem        [MATRIX_HEIGHT-1:0];
    //wire [DELTA_CELL_WIDTH-1:0] delta_mem      [MATRIX_WIDTH-1:0];

    genvar i;
    generate
    for (i=0; i<MATRIX_HEIGHT; i=i+1) begin: MEM
        assign activation_mem[i] = lut_result  [i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign mvm_mem[i]        = mvm_result  [i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
        assign dot_mem[i]        = delta_output[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end
    endgenerate
    
endmodule
