module vector_add
#(
    parameter VECTOR_LEN        = 5,
              A_CELL_WIDTH      = 8,
              B_CELL_WIDTH      = 8,
              RESULT_CELL_WIDTH = 8,
              TILING            = 1
)(
    input  clk,
    input  rst,
    // input a
    input  [VECTOR_LEN*A_CELL_WIDTH-1:0]      a,
    input                                     a_valid,
    output                                    a_ready, 
    // input b
    input  [VECTOR_LEN*B_CELL_WIDTH-1:0]      b,
    input                                     b_valid,
    output                                    b_ready, 
    // result
    output [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result,
    output                                    result_valid,
    input                                     result_ready,
    // overflow flag
    output                                    error
);

    `include "log2.v"

    reg [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result_buffer;
    reg                                    error_buffer;
    reg [log2(VECTOR_LEN):0]               counter;
    integer x;
    genvar i;

    // adders
    wire [RESULT_CELL_WIDTH-1:0] tiling_sum [TILING-1:0];
    wire [TILING-1:0] extra, overflow, underflow;

    generate 
    for (i=0; i<TILING; i=i+1) begin: ADDERS
        assign {extra[i], tiling_sum[i]} = 
            $signed(a[(counter+i)*A_CELL_WIDTH+:A_CELL_WIDTH]) + 
            $signed(b[(counter+i)*B_CELL_WIDTH+:B_CELL_WIDTH]);
        assign overflow[i]  = ({extra[i], tiling_sum[i][RESULT_CELL_WIDTH-1]} == 2'b01); // FIXME possible error when unused TILING causes X's on the signal
        assign underflow[i] = ({extra[i], tiling_sum[i][RESULT_CELL_WIDTH-1]} == 2'b10);
    end
    endgenerate

    // state
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state <= IDLE;
            counter <= 0;
            result_buffer <= 0;
            error_buffer <= 0;
        end
        else case(state)
            IDLE: begin
                state <= (a_valid && b_valid) ? CALC : IDLE;
                counter <= 0;
                result_buffer <= 0;
                error_buffer <= 0;
            end
            CALC: begin
                state <= (counter >= VECTOR_LEN - TILING) ? DONE : CALC;
                counter <= counter + TILING;
                for (x=0; x<TILING; x=x+1) begin: RES_MEM
                    result_buffer[(counter+x)*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] <= tiling_sum[x];
                end
                error_buffer <= error_buffer | underflow | overflow;
            end
            DONE: begin
                state <= result_ready ? IDLE : DONE;
                counter <= 0;
                result_buffer <= result_buffer;
                error_buffer <= error_buffer;
            end
        endcase
    end

    //output
    assign result = result_buffer;
    assign result_valid = state == DONE;
    assign a_ready = state == IDLE;
    assign b_ready = state == IDLE;
    assign error  = error_buffer;

endmodule
