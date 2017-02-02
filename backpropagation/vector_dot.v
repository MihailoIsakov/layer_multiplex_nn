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
    input                                     start,
    input  [VECTOR_LEN*A_CELL_WIDTH-1:0]      a,
    input  [VECTOR_LEN*B_CELL_WIDTH-1:0]      b,
    output [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result,
    output                                    valid,
    output                                    error
);

    `include "log2.v"

    localparam AB_SUM_WIDTH = A_CELL_WIDTH + B_CELL_WIDTH;

    reg [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result_buffer;
    reg                                    valid_buffer, error_buffer;
    reg [log2(VECTOR_LEN):0]               counter;

    // adders
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
    localparam IDLE=0, RUN=1;
    reg state;
    integer x;

    always @ (posedge clk) begin
        if (rst) begin
            counter       <= 0;
            result_buffer <= 0;
            state         <= IDLE;
            valid_buffer  <= 0;
            error_buffer  = 0;
        end
        else begin
            if (state == IDLE) begin
                counter      <= 0;
                state        <= start? RUN : IDLE;
                valid_buffer <= start? 0   : valid_buffer; // on start, reset valid_buffer
                error_buffer = start? 0   : error_buffer; // on start, reset error_buffer
            end
            else begin
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
                if (counter >= VECTOR_LEN - 1 - TILING) begin
                    counter      <= 0;
                    state        <= IDLE;
                    valid_buffer <= 1;
                end
                else begin
                    counter      <= counter + TILING;
                    state        <= RUN;
                    valid_buffer <= 0;
                end
            end
        end
    end

    //output
    assign result = result_buffer;
    assign valid  = valid_buffer;
    assign error  = error_buffer;

endmodule
