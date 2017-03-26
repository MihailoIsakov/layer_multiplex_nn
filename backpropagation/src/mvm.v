module mvm
#(
    parameter MATRIX_WIDTH      = 4, // width of the matrix aka the number of columns
              MATRIX_HEIGHT     = 5, // height of the matrix aka the number of rows and size of vector
              VECTOR_CELL_WIDTH = 8, // width of each vector cell in bits
              MATRIX_CELL_WIDTH = 8, // width of each matrix cell in bits
              RESULT_CELL_WIDTH = 8, // width of each result cell in bits
              FRACTION_WIDTH    = 4, // width of the fraction of matrix and vector cells
              TILING_ROW        = 3, // number of vector_mac units to create
              TILING_COL        = 3  // number of multipliers per vector_mac unit
)(
    input clk,
    input rst,
    // input vector
    input [MATRIX_HEIGHT*VECTOR_CELL_WIDTH-1:0]              vector,
    input                                                    vector_valid,
    output                                                   vector_ready,
    // input matrix
    input [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] matrix,
    input                                                    matrix_valid,
    output                                                   matrix_ready,
    // output result
    output [MATRIX_WIDTH*RESULT_CELL_WIDTH-1:0]              result,
    output                                                   result_valid,
    input                                                    result_ready,
    // overflow 
    output                                                   error
);

    `include "log2.v"
    
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // buffers
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    reg vector_set, matrix_set;
    reg [MATRIX_HEIGHT*VECTOR_CELL_WIDTH-1:0]              vector_buffer;
    reg [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] matrix_buffer;
    reg [MATRIX_WIDTH*RESULT_CELL_WIDTH-1:0]               result_buffer;
    reg                                                    error_buffer;

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // state logic
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            vector_buffer <= 0;
            vector_set    <= 0;
            matrix_buffer <= 0;
            matrix_set    <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    state         <= (matrix_set && vector_set) ? CALC : IDLE;
                    vector_buffer <= vector_valid ? vector           : vector_buffer;
                    vector_set    <= vector_valid ? 1                : vector_set;
                    //matrix_buffer <= matrix_valid ? matrix_transpose : matrix_buffer;
                    matrix_buffer <= matrix_valid ? matrix : matrix_buffer;
                    matrix_set    <= matrix_valid ? 1                : matrix_set;
                end
                CALC: begin
                    state         <= (counter_w > MATRIX_WIDTH) ? DONE : CALC;
                    vector_buffer <= vector_buffer;
                    vector_set    <= vector_set;
                    matrix_buffer <= matrix_buffer;
                    matrix_set    <= matrix_set;
                end
                DONE: begin
                    state         <= result_ready ? IDLE : DONE;
                    vector_buffer <= 0;
                    vector_set    <= result_ready ? 0    : 1;
                    matrix_buffer <= 0;
                    matrix_set    <= result_ready ? 0    : 1;
                end
                default: begin
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // matrix vector multiplication logic
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    reg [log2(MATRIX_HEIGHT):0] counter_h; // goes down the matrix columns, goes up to TILING_ROW
    reg [log2(MATRIX_WIDTH):0]  counter_w; // goes across columns, goes up to TILING_COL

    genvar h, w, i;

    generate 
    always @ (posedge clk) begin
        if (rst) begin
            counter_h     <= 0;
            counter_w     <= 0;
            result_buffer = 0;
            error_buffer  = 0;
        end
        case(state)
            IDLE: begin
                counter_h     <= 0;
                counter_w     <= 0;
                result_buffer = 0;
                error_buffer  = 0;
            end
            CALC: begin
                counter_h     <= (counter_h + TILING_ROW < MATRIX_HEIGHT) ? counter_h + TILING_ROW : 0;
                counter_w     <= (counter_h + TILING_ROW < MATRIX_HEIGHT) ? counter_w : counter_w + TILING_COL;
                error_buffer  = 0;
            end
            DONE: begin
                counter_h     <= 0;
                counter_w     <= 0;
                result_buffer = result_buffer;
                error_buffer  = 0;
            end
            default: begin
                counter_h     <= 0;
                counter_w     <= 0;
                result_buffer = 0;
                error_buffer  = 0;
            end
        endcase
    end
    endgenerate

    // FIXME ugly solution
    generate 
    for (w=0; w<TILING_COL; w=w+1) begin: LEFTRIGHT
        for (h=0; h<TILING_ROW; h=h+1) begin: UPDOWN
            always @ (posedge clk) begin
                case (state)
                    IDLE:
                        result_buffer = 0;
                    CALC: begin
                        result_buffer[(counter_w+w)*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] = 
                            result_buffer[(counter_w+w)*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] + // old result 
                            ((counter_h+h < MATRIX_HEIGHT) 
                                ? vector_buffer[(counter_h+h)*VECTOR_CELL_WIDTH+:VECTOR_CELL_WIDTH] 
                                : 0
                            ) *
                            ((counter_w+w < MATRIX_WIDTH && counter_h+h < MATRIX_HEIGHT)  
                                ? matrix_buffer[((counter_h+h)*MATRIX_WIDTH+counter_w+w)*MATRIX_CELL_WIDTH+:MATRIX_CELL_WIDTH] 
                                : 0
                            );
                    end
                    DONE:
                        result_buffer = result_ready ? 0 : result_buffer;
                endcase
            end
        end
    end
    endgenerate

    // shift by FRACTION_WIDTH
    generate 
    for (i=0; i<MATRIX_WIDTH; i=i+1) begin: SHIFT
        assign result[i*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] = result_buffer[i*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] >> FRACTION_WIDTH;
    end
    endgenerate
    //assign result       = result_buffer;
    assign result_valid = state == DONE;
    assign vector_ready = !vector_set;
    assign matrix_ready = !matrix_set;
    assign error        = error_buffer;

endmodule
