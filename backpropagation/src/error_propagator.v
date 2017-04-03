module error_propagator
#(
    parameter MATRIX_WIDTH       = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT      = 5,  // height of the weight matrix aka the number of rows and size of vector
              DELTA_CELL_WIDTH   = 8,  // width of each delta cell
              WEIGHTS_CELL_WIDTH = 8,  // widht of each matrix cell
              NEURON_ADDR_WIDTH  = 10, // width of activations from neurons before the sigmoid
              ACTIVATION_WIDTH   = 9,  // cell width after sigmoid
              FRACTION_WIDTH     = 4,
              LAYER_ADDR_WIDTH   = 2,
              TILING_ROW         = 3,  // number of vector_mac units to create
              TILING_COL         = 3   // number of multipliers per vector_mac unit
)(
    input clk,
    input rst,
    // layer input 
    input  [LAYER_ADDR_WIDTH-1:0]                              layer,
    input                                                      layer_valid,
    output                                                     layer_ready,
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
    
    // layer buffer
    reg [LAYER_ADDR_WIDTH-1:0] layer_buffer;
    reg layer_set;

    wire [MATRIX_HEIGHT*MATRIX_WIDTH*WEIGHTS_CELL_WIDTH-1:0] w_transposed;

    wire [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0] mvm_result;
    wire mvm_result_valid, mvm_result_ready;
    wire [MATRIX_HEIGHT*ACTIVATION_WIDTH-1:0] lut_result;
    wire lut_result_ready, lut_result_valid;
    wire mvm_error, dot_error;
    // dot product results
    wire [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0] dot_result;
    wire dot_result_valid, dot_result_ready;

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
        .clk         (clk             ),
        .rst         (rst             ),
        .a           (mvm_result      ),
        .a_valid     (mvm_result_valid),
        .a_ready     (mvm_result_ready),
        .b           (lut_result      ),
        .b_valid     (lut_result_valid),
        .b_ready     (lut_result_ready),
        .result      (dot_result      ),
        .result_valid(dot_result_valid),
        .result_ready(dot_result_ready),
        .error       (dot_error       )
    );


    localparam IDLE=0, PASS=1, IGNORE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
            layer_buffer <= 0;
            layer_set <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    state        <= (layer_set) ? (layer_buffer > 0) ? PASS : IGNORE : IDLE;
                    layer_buffer <= (!layer_set && layer_valid) ? layer : layer_buffer;
                    layer_set    <= (!layer_set && layer_valid) ? 1     : layer_set;
                end
                PASS: begin
                    state        <= (dot_result_valid && delta_output_ready) ? IDLE : PASS;
                    layer_buffer <= (dot_result_valid && delta_output_ready) ? 0    : layer_buffer;
                    layer_set    <= (dot_result_valid && delta_output_ready) ? 0    : layer_set;
                end
                IGNORE: begin
                    state        <= (dot_result_valid) ? IDLE : IGNORE;
                    layer_buffer <= (dot_result_valid) ? 0    : layer_buffer;
                    layer_set    <= (dot_result_valid) ? 0    : layer_set;
                end
            endcase
        end
    end


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    assign layer_ready        = !layer_set;
    assign error              = mvm_error | dot_error;
    assign delta_output       = dot_result;
    assign delta_output_valid = (state == PASS) ? dot_result_valid : 0;
    assign dot_result_ready   = (state == PASS) ? delta_output_ready : 1;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////  
    // Testing
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
