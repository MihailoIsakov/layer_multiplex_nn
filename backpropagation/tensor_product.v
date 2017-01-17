module tensor_product
#(
    parameter VECTOR_SIZE    = 5,
              CELL_WIDTH     = 8,
              TILING_H       = 4, // the number of cells from vector b processed each turn
              TILING_V       = 1  // the number of rows being processed each turn. 
)(
    input clk,
    input rst,
    input start,
    input [VECTOR_SIZE*CELL_WIDTH-1:0] a,
    input [VECTOR_SIZE*CELL_WIDTH-1:0] b,
    output [VECTOR_SIZE*2*VECTOR_SIZE*CELL_WIDTH-1:0] result,
    output reg                                        finish
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

    reg  [log2(VECTOR_SIZE)-1:0]              counter_h, counter_v; // size of counter can be optimized, should be VECTOR_SIZE/TILING rounded up
    wire [TILING_V*CELL_WIDTH-1:0]            tile_a;
    wire [TILING_H*CELL_WIDTH-1:0]            tile_b;
    wire [TILING_H*2*CELL_WIDTH-1:0] tile_product [TILING_V-1:0];
    reg  [VECTOR_SIZE*2*CELL_WIDTH-1:0] result_buffer [VECTOR_SIZE-1:0];

    assign tile_a = a[counter_v*TILING_V*CELL_WIDTH+:TILING_V*CELL_WIDTH];
    assign tile_b = b[counter_h*TILING_H*CELL_WIDTH+:TILING_H*CELL_WIDTH];

    genvar i, j;
    generate
    for (i=0; i<TILING_V; i=i+1) begin: HEIGHT_TILING
        for (j=0; j<TILING_H; j=j+1) begin: WIDTH_TILING
            assign tile_product[i][j*2*CELL_WIDTH+:2*CELL_WIDTH] = tile_a[i*CELL_WIDTH+:CELL_WIDTH] * tile_b[j*CELL_WIDTH+:CELL_WIDTH];
        end 
    end
    endgenerate

    localparam IDLE=0, RUN=1;
    reg state;

    // counter control
    always @ (posedge clk) begin
        if (rst) begin
            counter_h <= 0;
            counter_v <= 0;
            finish    <= 0;
            state     <= IDLE;
        end
        else begin
            if (state == RUN)
                if ((counter_h + 1) * TILING_H >= VECTOR_SIZE) begin // go one row down
                    if ((counter_v + 1) * TILING_V >= VECTOR_SIZE) begin
                        finish <= 1;
                        state  <= IDLE;
                    end else begin
                        counter_v <= counter_v + 1;
                        counter_h <= 0;
                    end
                end else begin
                    counter_h <= counter_h + 1;
                end
            else if (state == IDLE) begin
                counter_h <= 0;
                counter_v <= 0;
                finish    <= finish;
                state     <= start; // 1 if start 
            end
        end
    end

    // saving tile products into the result buffer
    genvar k;
    generate
        for (k=0; k<TILING_V; k=k+1) begin: RESULT_V
            always @ (posedge clk) begin
                if (state == RUN)
                    result_buffer[counter_v*TILING_V+k][counter_h*TILING_H*2*CELL_WIDTH+:TILING_H*2*CELL_WIDTH] <= tile_product[k];
            end
        end
    endgenerate


    // outputs
    generate 
    for (i=0; i<VECTOR_SIZE; i=i+1) begin: OUTPUT_RESULT_V
        for (j=0; j<VECTOR_SIZE; j=j+1) begin: OUTPUT_RESULT_H
            assign result[i*VECTOR_SIZE*2*CELL_WIDTH+j*2*CELL_WIDTH+:2*CELL_WIDTH] = result_buffer[i][j*2*CELL_WIDTH+:2*CELL_WIDTH];
        end
    end
    endgenerate


endmodule
