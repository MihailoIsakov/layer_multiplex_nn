module error_propagator
#(
    parameter MATRIX_WIDTH      = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT     = 5,  // height of the weight matrix aka the number of rows and size of vector
              VECTOR_CELL_WIDTH = 8,  // width of each vector cell in bits
              MATRIX_CELL_WIDTH = 8,  // widht of each matrix cell in bits
              NEURON_ADDR_WIDTH = 10, // activations from neurons before the sigmoid
              ACTIVATION_WIDTH  = 9,  // width after sigmoid
              TILING_ROW        = 3,  // number of vector_mac units to create
              TILING_COL        = 3   // number of multipliers per vector_mac unit
)(
    input clk,
    input rst,
    input                                                     start,
    input  [VECTOR_WIDTH*VECTOR_CELL_WIDTH-1:0]               delta_input,
    input  [MATRIX_WIDTH*NEURON_ADDR_WIDTH-1:0]               z,
    input  [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] w,
    output [MATRIX_WIDTH*RESULT_WIDTH-1:0]               delta_output,
    output                                                    valid
);

    //define the log2 function
    function integer log2;
        input integer num;
        integer i, result;
        begin
            for (i = 0; 2 ** i < num; i = i + 1)
                result = i + 1;
            log2 = result;
        end
    endfunction
    //

    localparam VECTOR_WIDTH = MATRIX_HEIGHT;
    localparam MVM_RESULT_WIDTH = VECTOR_CELL_WIDTH + MATRIX_CELL_WIDTH + log2(VECTOR_WIDTH) + 1;
    localparam RESULT_WIDTH = MVM_RESULT_WIDTH + ACTIVATION_WIDTH;

    wire [MATRIX_WIDTH*MVM_RESULT_WIDTH-1:0] mvm_result;
    wire [MATRIX_WIDTH*ACTIVATION_WIDTH-1:0] lut_result;
    wire [MATRIX_WIDTH*RESULT_WIDTH-1:0]     dot_result;
    wire mvm_valid, lut_valid, dot_valid;
    reg inner_start, dot_start;

    mvm #(
        .MATRIX_WIDTH     (MATRIX_WIDTH     ),
        .MATRIX_HEIGHT    (MATRIX_HEIGHT    ),
        .VECTOR_CELL_WIDTH(VECTOR_CELL_WIDTH),
        .MATRIX_CELL_WIDTH(MATRIX_CELL_WIDTH),
        .TILING_ROW       (TILING_ROW       ),
        .TILING_COL       (TILING_COL       )) 
    mvm(
        .clk(clk),
        .rst(rst),
        .start(inner_start),
        .vector(delta_input),
        .matrix(w),
        .result(mvm_result),
        .valid(mvm_valid)
    );

    lut #(
        .NEURON_NUM(MATRIX_WIDTH),
        .LUT_ADDR_SIZE(NEURON_ADDR_WIDTH),
        .LUT_DEPTH(1 << NEURON_ADDR_WIDTH),
        .LUT_WIDTH(ACTIVATION_WIDTH),
        .LUT_INIT_FILE("activations.list")
    ) sigmoid (
        .clk(clk),
        .rst(rst),
        .start(inner_start),
        .inputs(z),
        .outputs(lut_result),
        .valid(lut_valid)
    );

    vector_dot2 #(
        .VECTOR_SIZE(MATRIX_WIDTH),
        .CELL_A_WIDTH(MVM_RESULT_WIDTH),
        .CELL_B_WIDTH(ACTIVATION_WIDTH),
        .TILING(2)
    ) dot (
        .clk(clk),
        .rst(rst),
        .start(dot_start),
        .a(mvm_result),
        .b(lut_result),
        .result(dot_result),
        .valid(dot_valid)
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
    
endmodule
