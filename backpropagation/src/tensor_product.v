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
    // a
    input  [A_VECTOR_LEN*A_CELL_WIDTH-1:0]                   a,
    input                                                    a_valid,
    output                                                   a_ready,
    // b
    input  [B_VECTOR_LEN*B_CELL_WIDTH-1:0]                   b,
    input                                                    b_valid,
    output                                                   b_ready,
    // result
    output [A_VECTOR_LEN*B_VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result,
    output                                                   result_valid,
    input                                                    result_ready,
    // overflow
    output                                                   error
);

    `include "log2.v"
    localparam AB_SUM_WIDTH = A_CELL_WIDTH + B_CELL_WIDTH;

    reg [A_VECTOR_LEN*A_CELL_WIDTH-1:0] a_buffer;
    reg [B_VECTOR_LEN*B_CELL_WIDTH-1:0] b_buffer;
    reg a_set, b_set;
    reg  [RESULT_CELL_WIDTH-1:0] result_buffer [B_VECTOR_LEN-1:0][A_VECTOR_LEN-1:0];
    reg  error_buffer;

    reg  [log2(A_VECTOR_LEN > B_VECTOR_LEN ? A_VECTOR_LEN : B_VECTOR_LEN):0] counter_h, counter_v; // size of counter can be optimized, should be VECTOR_SIZE/TILING rounded up

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Tile product combinational logic
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    wire [TILING_V*A_CELL_WIDTH-1:0] tile_a;
    wire [TILING_H*B_CELL_WIDTH-1:0] tile_b;
    wire [AB_SUM_WIDTH-1:0] tile_product [TILING_H-1:0][TILING_V-1:0]; // FIXME the second index controls row?!?

    assign tile_a = a_buffer[counter_v*TILING_V*A_CELL_WIDTH+:TILING_V*A_CELL_WIDTH];
    assign tile_b = b_buffer[counter_h*TILING_H*B_CELL_WIDTH+:TILING_H*B_CELL_WIDTH];

    genvar i, j;
    generate
    for (i=0; i<TILING_V; i=i+1) begin: HEIGHT_TILING
        for (j=0; j<TILING_H; j=j+1) begin: WIDTH_TILING
            assign tile_product[j][i] = 
                ($signed(tile_a[i*A_CELL_WIDTH+:A_CELL_WIDTH]) * $signed(tile_b[j*B_CELL_WIDTH+:B_CELL_WIDTH])) >>> FRACTION_WIDTH;
        end 
    end
    endgenerate

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // State logic
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            a_buffer      <= 0;
            a_set         <= 0;
            b_buffer      <= 0;
            b_set         <= 0;
            counter_h     <= 0;
            counter_v     <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state        <= (a_set && b_set) ? CALC : IDLE; // 1 if start
                    a_buffer     <= (!a_set && a_valid) ? a : a_buffer;
                    a_set        <= (!a_set && a_valid) ? 1 : a_set;
                    b_buffer     <= (!b_set && b_valid) ? b : b_buffer;
                    b_set        <= (!b_set && b_valid) ? 1 : b_set;
                    counter_h    <= 0;
                    counter_v    <= 0;
                end
                CALC: begin
                    state     <= (((counter_h+1)*TILING_H >= B_VECTOR_LEN) && ((counter_v+1)*TILING_V >= A_VECTOR_LEN)) ? DONE : CALC;
                    a_buffer  <= a_buffer;
                    a_set     <= a_set;
                    b_buffer  <= b_buffer;
                    b_set     <= b_set;
                    counter_h <= ((counter_h+1)*TILING_H >= B_VECTOR_LEN) ? 0             : counter_h + 1;
                    counter_v <= ((counter_h+1)*TILING_H >= B_VECTOR_LEN) ? counter_v + 1 : counter_v;
                end
                DONE: begin
                    state     <= result_ready ? IDLE : DONE;
                    a_buffer  <= 0;
                    a_set     <= result_ready ? 0    : 1;
                    b_buffer  <= 0;
                    b_set     <= result_ready ? 0    : 1;
                    counter_h <= 0;
                    counter_v <= 0;
                end
                default: begin
                    state         <= IDLE;
                    a_buffer      <= 0;
                    a_set         <= 0;
                    b_buffer      <= 0;
                    b_set         <= 0;
                    counter_h     <= 0;
                    counter_v     <= 0;
                end
            endcase
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // saving tile products into the result buffer
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    // for cleaning up memory
    integer x, y;
    genvar k, l;

    generate
        for (k=0; k<TILING_V; k=k+1) begin: RESULT_V
            for (l=0; l<TILING_H; l=l+1) begin: RESULT_H
                always @ (posedge clk) begin
                    if (rst) begin 
                        for (x=0; x<A_VECTOR_LEN; x=x+1)
                            for (y=0; y<B_VECTOR_LEN; y=y+1)
                                result_buffer[y][x] <= 0;
                        error_buffer = 0;
                    end
                    else case(state)
                        // FIXME doesn't depend on k and l
                        IDLE: begin
                            // clean up result_buffer
                            for (x=0; x<A_VECTOR_LEN; x=x+1)
                                for (y=0; y<B_VECTOR_LEN; y=y+1)
                                    result_buffer[y][x] <= 0;
                            error_buffer = 0;
                        end
                        CALC: begin
                            // this is where the truncating of result happens
                            result_buffer[counter_v*TILING_V+k][counter_h*TILING_H+l] <= tile_product[l][k];
                            if (AB_SUM_WIDTH > RESULT_CELL_WIDTH && (counter_v*TILING_V+k<A_VECTOR_LEN) && (counter_h*TILING_H+l<B_VECTOR_LEN))
                                error_buffer = error_buffer ||
                                    ~(&(tile_product[l][k][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH-1]) || 
                                     &(~tile_product[l][k][AB_SUM_WIDTH-1:RESULT_CELL_WIDTH-1]));
                            else error_buffer = error_buffer;
                        end
                        DONE: begin
                            for (x=0; x<A_VECTOR_LEN; x=x+1)
                                for (y=0; y<B_VECTOR_LEN; y=y+1)
                                    result_buffer[y][x] <= result_buffer[y][x];
                            error_buffer  = error_buffer;
                        end
                    endcase
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
    
    assign result_valid = state == DONE;
    assign a_ready      = ~a_set;
    assign b_ready      = ~b_set;
    assign error        = error_buffer;

endmodule
