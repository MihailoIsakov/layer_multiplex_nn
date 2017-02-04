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
    input                                     start,
    input  [VECTOR_LEN*A_CELL_WIDTH-1:0]      a,
    input  [VECTOR_LEN*B_CELL_WIDTH-1:0]      b,
    output [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result,
    output                                    valid,
    output                                    error
);

    `include "log2.v"

    reg [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result_buffer;
    reg                                    valid_buffer, error_buffer;
    reg [log2(VECTOR_LEN):0]               counter;

    // adders
    wire [RESULT_CELL_WIDTH-1:0] tiling_sum [TILING-1:0];
    wire [TILING-1:0] extra, overflow, underflow;
    genvar i;
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
    localparam IDLE=0, RUN=1;
    reg state;

    integer x;

    always @ (posedge clk) begin
        if (rst) begin
            counter       <= 0;
            result_buffer <= 0;
            state         <= IDLE;
            valid_buffer  <= 0;
            error_buffer  <= 0;
        end
        else begin
            if (state == IDLE) begin
                counter      <= 0;
                state        <= start? RUN : IDLE;
                valid_buffer <= start? 0   : valid_buffer; // on start, reset valid_buffer
                error_buffer <= start? 0   : error_buffer;
            end
            else begin
                for (x=0; x<TILING; x=x+1) begin: RES_MEM
                    result_buffer[(counter+x)*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] <= tiling_sum[x];
                end
                if (counter >= VECTOR_LEN - 1) begin
                    counter      <= 0;
                    state        <= IDLE;
                    valid_buffer <= 1;
                end
                else begin
                    counter      <= counter + TILING;
                    state        <= RUN;
                    valid_buffer <= 0;
                end
                error_buffer  <= error_buffer | underflow | overflow;
            end
        end
    end

    //output
    assign result = result_buffer;
    assign valid  = valid_buffer;
    assign error  = error_buffer;

endmodule
