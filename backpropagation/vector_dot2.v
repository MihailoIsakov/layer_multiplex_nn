module vector_dot2
#(
    parameter VECTOR_SIZE = 5,
              CELL_A_WIDTH  = 8,
              CELL_B_WIDTH  = 8,
              TILING      = 1
)(
    input clk,
    input rst,
    input start,
    input [VECTOR_SIZE*CELL_A_WIDTH-1:0]  a,
    input [VECTOR_SIZE*CELL_B_WIDTH-1:0]  b,
    output [VECTOR_SIZE*RESULT_WIDTH-1:0] result,
    output                                valid
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

    localparam RESULT_WIDTH = CELL_A_WIDTH + CELL_B_WIDTH;

    reg [VECTOR_SIZE*RESULT_WIDTH-1:0] result_buffer;
    reg                                valid_buffer;
    reg [log2(VECTOR_SIZE):0]          counter;

    // adders
    wire [TILING*RESULT_WIDTH-1:0] tiling_sum;
    genvar i;
    generate 
    for (i=0; i<TILING; i=i+1) begin: ADDERS
        assign tiling_sum[i*RESULT_WIDTH+:RESULT_WIDTH] = $signed(a[(counter+i)*CELL_A_WIDTH+:CELL_A_WIDTH]) * $signed(b[(counter+i)*CELL_B_WIDTH+:CELL_B_WIDTH]);
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
            valid_buffer         <= 0;
        end
        else begin
            if (state == IDLE) begin
                counter       <= 0;
                state         <= start? RUN : IDLE;
                valid_buffer         <= start? 0   : valid_buffer; // on start, reset valid_buffer
            end
            else begin
                result_buffer[counter*RESULT_WIDTH+:TILING*RESULT_WIDTH] <= tiling_sum;
                if (counter >= VECTOR_SIZE - 1) begin
                    counter       <= 0;
                    state         <= IDLE;
                    valid_buffer         <= 1;
                end
                else begin
                    counter <= counter + TILING;
                    state   <= RUN;
                    valid_buffer   <= 0;
                end
            end
        end
    end

    //output
    assign result = result_buffer;
    assign valid  = valid_buffer;

endmodule
