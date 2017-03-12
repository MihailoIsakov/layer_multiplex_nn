module vector_mac
#(
    parameter VECTOR_LEN        = 5, // number of elements in the vectors
              A_CELL_WIDTH      = 8, // width of elements in the vector a
              B_CELL_WIDTH      = 8, // width of elements in the vector b
              RESULT_CELL_WIDTH = 8, // width of elements in the output vector
              TILING            = 2  // number of mults generated for dot product
)(
    input clk,
    input rst,
    // a signal
    input  [VECTOR_LEN*A_CELL_WIDTH-1:0] a,
    input                                a_valid,
    output                               a_ready,
    // b signal
    input  [VECTOR_LEN*B_CELL_WIDTH-1:0] b,
    input                                b_valid,
    output                               b_ready,
    // result 
    output [RESULT_CELL_WIDTH-1:0]       result,
    output                               result_valid,
    input                                result_ready,
    // overflow signal
    output                               error
);

    `include "log2.v"
    
    // result size accomodating for the sum and +1 for log2 rounding up
    localparam AB_SUM_WIDTH = A_CELL_WIDTH + B_CELL_WIDTH + log2(VECTOR_LEN) + 1; 

    reg a_set, b_set;
    reg [VECTOR_LEN*A_CELL_WIDTH-1:0] a_buffer;
    reg [VECTOR_LEN*B_CELL_WIDTH-1:0] b_buffer;

    reg signed [AB_SUM_WIDTH-1:0] result_buffer, sum;
    reg valid_buffer;
    reg [log2(VECTOR_LEN):0] counter; // +1 to round up log2

    // FIXME The current reduce sum operation is serial - the vector is summed up one element at a time combinatorially.
    // This may create a critical path, and should be replaced with an adder tree
    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            sum <= 0;
        end
        else begin
            sum = 0;
            for (i=0; i<TILING; i=i+1) begin: MULTIPLIERS
                if (counter+i<VECTOR_LEN)
                    sum = sum + $signed(a[(counter+i)*A_CELL_WIDTH+:A_CELL_WIDTH]) * $signed(b[(counter+i)*B_CELL_WIDTH+:B_CELL_WIDTH]);
            end
        end
    end


    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    //always @ (posedge clk) begin
        //if (rst) begin
            //counter       <= 0;
            //result_buffer <= 0;
            //state         <= IDLE;
            //valid_buffer  <= 0;
        //end
        //else begin
            //if (state == IDLE) begin
                //counter       <= 0;
                //state         <= start ? RUN : IDLE;
                //valid_buffer  <= start ? 0   : valid_buffer; // on start, reset valid_buffer
                //result_buffer = start  ? 0   : result_buffer;
            //end
            //else begin
                //if (counter >= VECTOR_LEN - 1) begin
                    //result_buffer = result_buffer;
                    //counter       <= 0;
                    //state         <= IDLE;
                    //valid_buffer  <= 1;
                //end
                //else begin
                    //result_buffer = result_buffer + sum;
                    //counter       <= counter + TILING;
                    //state         <= RUN;
                    //valid_buffer  <= 0;
                //end
            //end
        //end
    //end

    always @ (posedge clk) begin
        if (rst) begin 
            state         <= IDLE;
            a_buffer      <= 0;
            a_set         <= 0;
            b_buffer      <= 0;
            b_set         <= 0;
            counter       <= 0;
            result_buffer <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state         <= (a_set && b_set);
                    a_buffer      <= (a_valid) ? a : a_buffer;
                    a_set         <= (a_valid) ? 1 : a_set;
                    b_buffer      <= (b_valid) ? b : b_buffer;
                    b_set         <= (b_valid) ? 1 : b_set;
                    counter       <= 0;
                    result_buffer <= 0;
                end
                CALC: begin
                    state         <= (counter >= VECTOR_LEN - TILING) ? DONE : CALC;
                    a_buffer      <= a_buffer;
                    a_set         <= a_set;     
                    b_buffer      <= b_buffer;  
                    b_set         <= b_set;     
                    counter       <= counter + TILING;
                    result_buffer <= result_buffer + sum;
                end
                DONE: begin
                    state         <= result_ready ? IDLE : DONE;
                    a_buffer      <= 0;
                    a_set         <= 0;     
                    b_buffer      <= 0;  
                    b_set         <= 0;     
                    counter       <= 0;
                    result_buffer <= result_buffer;
                end
            endcase
        end
    end

    //output
    assign result       = result_buffer[RESULT_CELL_WIDTH-1:0];  // truncated
    assign result_valid = state == DONE;
    assign a_ready      = !a_set;
    assign b_ready      = !b_set;
    // checks if the truncated part is not all zeros of ones
    assign error  = 
        (|result_buffer[AB_SUM_WIDTH-1:RESULT_CELL_WIDTH] == 1) &&  // does not work for all 1s
        (|(~result_buffer[AB_SUM_WIDTH-1:RESULT_CELL_WIDTH]) == 1); // does not work for all 0s

endmodule
