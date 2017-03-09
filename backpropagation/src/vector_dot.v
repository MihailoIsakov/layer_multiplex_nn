module vector_dot
#(
    parameter VECTOR_LEN        = 5,
              A_CELL_WIDTH      = 8,
              B_CELL_WIDTH      = 8,
              RESULT_CELL_WIDTH = 8,
              FRACTION_WIDTH    = 4,
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
    // overflow
    output                                    error
);

    `include "log2.v"

    localparam AB_SUM_WIDTH = A_CELL_WIDTH + B_CELL_WIDTH;

    reg [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result_buffer;
    reg                                    error_buffer;
    reg [log2(VECTOR_LEN):0]               counter;
    integer x;

    // multipliers
    wire signed [AB_SUM_WIDTH-1:0] tiling_sum [TILING-1:0];
    genvar i;
    generate 
    for (i=0; i<TILING; i=i+1) begin: ADDERS
        assign tiling_sum[i] = 
            ($signed(a[(counter+i)*A_CELL_WIDTH+:A_CELL_WIDTH]) *
            $signed(b[(counter+i)*B_CELL_WIDTH+:B_CELL_WIDTH])) >>> FRACTION_WIDTH;
    end
    endgenerate

    // state
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            result_buffer <= 0;            
            error_buffer   = 0;
            counter       <= 0;
        end
        else case (state) 
            IDLE: begin
                state <= (a_valid && b_valid) ? CALC : IDLE;
                result_buffer <= 0;            
                error_buffer   = 0;
                counter       <= 0;
            end
            CALC: begin
                state         <= (counter >= VECTOR_LEN - TILING) ? DONE : CALC;

                // calculation
                for (x=0; x<TILING; x=x+1) begin: RES_MEM
                    result_buffer[(counter+x)*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] <= tiling_sum[x];
                    // check for overflow
                    if (AB_SUM_WIDTH > RESULT_CELL_WIDTH)
                        if (counter + x < VECTOR_LEN) 
                            error_buffer = error_buffer ||
                                ~(&(tiling_sum[x][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH-1]) || 
                                 &(~tiling_sum[x][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH-1]));
                        else 
                            error_buffer = error_buffer;
                    else 
                        error_buffer = 0;
                end

                counter <= counter + TILING;
            end
            DONE: begin
                state         <= result_ready ? IDLE : DONE;
                result_buffer <= result_buffer;
                error_buffer   = error_buffer;
                counter       <= 0;
            end
        endcase
    end

    //output
    assign result = result_buffer;
    assign a_ready = state == IDLE;
    assign b_ready = state == IDLE;
    assign result_valid = state == DONE;
    assign error  = error_buffer;

endmodule
