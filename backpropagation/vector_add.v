module vector_add
#(
    parameter VECTOR_SIZE = 5,
              CELL_WIDTH  = 8,
              TILING      = 1
)(
    input clk,
    input rst,
    input start,
    input [VECTOR_SIZE*CELL_WIDTH-1:0] a,
    input [VECTOR_SIZE*CELL_WIDTH-1:0] b,
    output [VECTOR_SIZE*(CELL_WIDTH+1)-1:0] result,
    output reg                              finish
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

    reg [VECTOR_SIZE*(CELL_WIDTH+1)-1:0] result_buffer;
    reg [log2(VECTOR_SIZE):0]            counter;

    // adders
    wire [TILING*(CELL_WIDTH+1)-1:0] tiling_sum;
    genvar i;
    generate 
    for (i=0; i<TILING; i=i+1) begin: ADDERS
        assign tiling_sum[i*(CELL_WIDTH+1)+:CELL_WIDTH+1] = a[(counter+i)*CELL_WIDTH+:CELL_WIDTH] + b[(counter+i)*CELL_WIDTH+:CELL_WIDTH];
    end
    endgenerate

    // state
    localparam IDLE=0, RUN=1;
    reg state;

    always @ (posedge clk) begin
        if (rst) begin
            counter       <= 0;
            result_buffer <= 0;
            state         <= IDLE;
            finish        <= 0;
        end
        else begin
            if (state == IDLE) begin
                counter       <= 0;
                state         <= start? RUN : IDLE;
                finish        <= 0;
            end
            else begin
                result_buffer[counter*(CELL_WIDTH+1)+:TILING*(CELL_WIDTH+1)] <= tiling_sum;
                if (counter >= VECTOR_SIZE - 1) begin
                    counter       <= 0;
                    state         <= IDLE;
                    finish        <= 1;
                end
                else begin
                    counter <= counter + TILING;
                    state   <= RUN;
                    finish  <= 0;
                end
            end
        end
    end

    //output
    assign result = result_buffer;

endmodule
