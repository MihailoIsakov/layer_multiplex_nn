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
    input                                                      start,
    input  [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0]                delta_input,
    input  [MATRIX_WIDTH*NEURON_ADDR_WIDTH-1:0]                z,
    input  [MATRIX_WIDTH*MATRIX_HEIGHT*WEIGHTS_CELL_WIDTH-1:0] w,
    output [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0]                 delta_output,
    output                                                     valid,
    output                                                     error
);

    `include "log2.v"

    reg inner_start, dot_start; // inner start starts both the MVM and the sigmoid
    wire [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0] mvm_result;
    wire [MATRIX_WIDTH*ACTIVATION_WIDTH-1:0] lut_result;
    wire [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0] dot_result;
    wire mvm_valid, lut_valid, dot_valid;
    wire mvm_error, dot_error;

    mvm #(
        .MATRIX_WIDTH     (MATRIX_WIDTH      ),
        .MATRIX_HEIGHT    (MATRIX_HEIGHT     ),
        .VECTOR_CELL_WIDTH(DELTA_CELL_WIDTH  ),
        .MATRIX_CELL_WIDTH(WEIGHTS_CELL_WIDTH),
        .RESULT_CELL_WIDTH(DELTA_CELL_WIDTH  ),
        .FRACTION_WIDTH   (FRACTION_WIDTH    ),
        .TILING_ROW       (TILING_ROW        ),
        .TILING_COL       (TILING_COL        )) 
    mvm(
        .clk   (clk        ),
        .rst   (rst        ),
        .start (inner_start),
        .vector(delta_input),
        .matrix(w          ),
        .result(mvm_result ),
        .valid (mvm_valid  ),
        .error (mvm_error  )
    );

    lut #(
        .NEURON_NUM   (MATRIX_WIDTH          ),
        .LUT_ADDR_SIZE(NEURON_ADDR_WIDTH     ),
        .LUT_DEPTH    (1 << NEURON_ADDR_WIDTH),
        .LUT_WIDTH    (ACTIVATION_WIDTH      ),
        .LUT_INIT_FILE("derivative.list"    )
    ) sigmoid_derivative (
        .clk    (clk        ),
        .rst    (rst        ),
        .start  (inner_start),
        .inputs (z          ),
        .outputs(lut_result ),
        .valid  (lut_valid  )
    );

    vector_dot #(
        .VECTOR_LEN       (MATRIX_WIDTH    ),
        .A_CELL_WIDTH     (DELTA_CELL_WIDTH),
        .B_CELL_WIDTH     (ACTIVATION_WIDTH),
        .RESULT_CELL_WIDTH(DELTA_CELL_WIDTH),
        .FRACTION_WIDTH   (FRACTION_WIDTH  ),
        .TILING           (2               )
    ) dot (
        .clk   (clk       ),
        .rst   (rst       ),
        .start (dot_start ),
        .a     (mvm_result),
        .b     (lut_result),
        .result(dot_result),
        .valid (dot_valid ),
        .error (dot_error )
    );

    localparam IDLE=0, MVM=1, DOT=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            inner_start <= 0;
            dot_start   <= 0;
        end
        else begin
            case (state)
            IDLE: begin
                state       <= start ? MVM : IDLE;
                inner_start <= start ? 1   : 0;
                dot_start   <= 0;
            end
            MVM: begin
                state       <= (mvm_valid && lut_valid) ? DOT : MVM;
                inner_start <= 0;
                dot_start   <= (mvm_valid && lut_valid) ? 1 : 0;
            end
            DOT: begin
                state       <= dot_valid ? IDLE : DOT;
                inner_start <= 0;
                dot_start   <= 0;
            end
            default: begin
                state       <= IDLE;
                inner_start <= 0;
                dot_start   <= 0;
            end
            endcase
        end
    end

    // outputs
    assign delta_output = dot_result;
    assign valid        = dot_valid;
    assign error        = mvm_error | dot_error;

    // testing
    wire [ACTIVATION_WIDTH-1:0] activation_mem [MATRIX_WIDTH-1:0];
    wire [DELTA_CELL_WIDTH-1:0] mvm_mem        [MATRIX_WIDTH-1:0];
    wire [DELTA_CELL_WIDTH-1:0] dot_mem        [MATRIX_WIDTH-1:0];
    //wire [DELTA_CELL_WIDTH-1:0] delta_mem      [MATRIX_WIDTH-1:0];

    genvar i;
    generate
    for (i=0; i<MATRIX_WIDTH; i=i+1) begin: MEM
        assign activation_mem[i] = lut_result[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign mvm_mem[i]        = mvm_result[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
        assign dot_mem[i]        = dot_result[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end
    endgenerate
    
endmodule
