module tensor_product
#(
    parameter A_VECTOR_LEN         = 5, // length of vector a
              B_VECTOR_LEN         = 5, // length of vector b
              A_CELL_WIDTH         = 8, // width of the integer part of fixed point vector values of a
              B_CELL_WIDTH         = 8, // width of the integer part of fixed point vector values of b
              RESULT_CELL_WIDTH    = 8, // width of the integer part of the result vector values
              FRACTION_WIDTH       = 4, // width of the fraction of both a and b values
              TILING_H             = 1, // the number of cells from vector b processed each turn
              TILING_V             = 1  // the number of rows being processed each turn.
)(
    input clk,
    input rst,
    input                                                    start,
    input  [A_VECTOR_LEN*A_CELL_WIDTH-1:0]                   a,
    input  [B_VECTOR_LEN*B_CELL_WIDTH-1:0]                   b,
    output [A_VECTOR_LEN*B_VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result,
    output                                                   valid,
    output                                                   error
);

    `include "log2.v"
    localparam AB_SUM_WIDTH = A_CELL_WIDTH + B_CELL_WIDTH;

    reg  [log2(A_VECTOR_LEN > B_VECTOR_LEN ? A_VECTOR_LEN : B_VECTOR_LEN):0] counter_h, counter_v; // size of counter can be optimized, should be VECTOR_SIZE/TILING rounded up
    reg  [RESULT_CELL_WIDTH-1:0] result_buffer [B_VECTOR_LEN-1:0][A_VECTOR_LEN-1:0];
    reg  valid_buffer, error_buffer;

    wire [TILING_V*A_CELL_WIDTH-1:0] tile_a;
    wire [TILING_H*B_CELL_WIDTH-1:0] tile_b;
    wire [AB_SUM_WIDTH-1:0]         tile_product [TILING_H-1:0][TILING_V-1:0]; // FIXME the second index controls row?!?

    assign tile_a = a[counter_v*TILING_V*A_CELL_WIDTH+:TILING_V*A_CELL_WIDTH];
    assign tile_b = b[counter_h*TILING_H*B_CELL_WIDTH+:TILING_H*B_CELL_WIDTH];


    genvar i, j;
    generate
    for (i=0; i<TILING_V; i=i+1) begin: HEIGHT_TILING
        for (j=0; j<TILING_H; j=j+1) begin: WIDTH_TILING
            assign tile_product[j][i] = 
                ($signed(tile_a[i*A_CELL_WIDTH+:A_CELL_WIDTH]) * $signed(tile_b[j*B_CELL_WIDTH+:B_CELL_WIDTH])) >>> FRACTION_WIDTH;
        end 
    end
    endgenerate

    localparam IDLE=0, RUN=1;
    reg state;


    // counter control
    always @ (posedge clk) begin
        if (rst) begin
            counter_h    <= 0;
            counter_v    <= 0;
            valid_buffer <= 0;
            state        <= IDLE;
            error_buffer = 0;
        end
        else begin
            if (state == IDLE) begin
                counter_h    <= 0;
                counter_v    <= 0;
                valid_buffer <= valid_buffer;
                state        <= start ? RUN : IDLE; // 1 if start
            end
            else if (state == RUN) begin
                if ((counter_h + 1) * TILING_H >= B_VECTOR_LEN) begin // go one row down
                    if ((counter_v + 1) * TILING_V >= A_VECTOR_LEN) begin
                        valid_buffer <= 1;
                        state        <= IDLE;
                    end else begin
                        counter_v    <= counter_v + 1;
                        counter_h    <= 0;
                    end
                end else begin
                    counter_h <= counter_h + 1;
                end
            end
        end
    end


    // saving tile products into the result buffer
    genvar k, l;
    generate
        for (k=0; k<TILING_V; k=k+1) begin: RESULT_V
            for (l=0; l<TILING_H; l=l+1) begin: RESULT_H
                always @ (posedge clk) begin
                    if (state == RUN) begin
                        // this is where the truncating of result happens
                        result_buffer[counter_v*TILING_V+k][counter_h*TILING_H+l] <= tile_product[l][k];
                        if (AB_SUM_WIDTH > RESULT_CELL_WIDTH && (counter_v*TILING_V+k<A_VECTOR_LEN) && (counter_h*TILING_H+l<B_VECTOR_LEN))
                            error_buffer = error_buffer ||
                                ~(&(tile_product[l][k][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH]) || 
                                 &(~tile_product[l][k][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH]));
                        else error_buffer = error_buffer;
                    end
                end
            end
        end
    endgenerate


    // outputs
    generate 
    for (i=0; i<A_VECTOR_LEN; i=i+1) begin: OUTPUT_RESULT_V
        for (j=0; j<B_VECTOR_LEN; j=j+1) begin: OUTPUT_RESULT_H
            assign result[i*B_VECTOR_LEN*RESULT_CELL_WIDTH+j*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH] = result_buffer[i][j];
        end
    end
    endgenerate
    assign valid = valid_buffer;
    assign error = error_buffer;

endmodule
