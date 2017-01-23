module vector_mac
#(
    parameter VECTOR_SIZE = 5, // number of elements in the vectors
              WIDTH1      = 8, // width of elements in the vector a
              WIDTH2      = 8, // width of elements in the vector b
              TILING      = 2  // number of mults generated for dot
                               // please keep comment lengths syncd
)(
    input clk,
    input rst,
    input                          start,
    input [VECTOR_SIZE*WIDTH1-1:0] a,
    input [VECTOR_SIZE*WIDTH2-1:0] b,
    output [RESULT_WIDTH-1:0]      result,
    output                         valid
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
    
    // width needed to store the multiplication
    localparam MULT_WIDTH   = WIDTH1 + WIDTH2;
    // result size accomodating for the sum and +1 for log2 rounding up
    localparam RESULT_WIDTH = WIDTH1 + WIDTH2 + log2(VECTOR_SIZE) + 1; 

    reg signed [RESULT_WIDTH-1:0] result_buffer, sum;
    reg valid_buffer;
    reg [log2(VECTOR_SIZE):0] counter; // +1 to round up log2

    // FIXME The current reduce sum operation is serial - the vector is summed up one element at a time combinatorially.
    // This may create a critical path, and should be replaced with an adder tree
    //genvar i;
    //generate 
    integer i;
    always @ (posedge clk) begin
        sum = 0;
        for (i=0; i<TILING; i=i+1) begin: MULTIPLIERS
            if (counter+i<VECTOR_SIZE)
                sum = sum + $signed(a[(counter+i)*WIDTH1+:WIDTH1]) * $signed(b[(counter+i)*WIDTH2+:WIDTH2]);
        end
    end
    //endgenerate

    // state
    localparam IDLE=0, RUN=1;
    reg state;

    always @ (posedge clk) begin
        if (rst) begin
            counter       <= 0;
            result_buffer <= 0;
            state         <= IDLE;
            valid_buffer  <= 0;
            sum           = 0;
        end
        else begin
            if (state == IDLE) begin
                counter       <= 0;
                state         <= start ? RUN : IDLE;
                valid_buffer  <= start ? 0   : valid_buffer; // on start, reset valid_buffer
                result_buffer = 0;
            end
            else begin
                result_buffer = result_buffer + sum;
                if (counter >= VECTOR_SIZE - 1) begin
                    counter       <= 0;
                    state         <= IDLE;
                    valid_buffer  <= 1;
                end
                else begin
                    counter       <= counter + TILING;
                    state         <= RUN;
                    valid_buffer  <= 0;
                end
            end
        end
    end

    //output
    assign result = result_buffer;
    assign valid  = valid_buffer && ~start;

endmodule
