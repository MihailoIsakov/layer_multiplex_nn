module fifo_mux2 #(
    parameter INPUT_WIDTH = 32
) (
    input  clk,
    // a signal
    input  [INPUT_WIDTH-1:0] a,
    input                    a_valid,
    output reg               a_ready,
    // b signal
    input  [INPUT_WIDTH-1:0] b,
    input                    b_valid,
    output reg               b_ready,
    // select signal
    input                    select,
    input                    select_valid,
    output reg               select_ready,
    // result signal
    output [INPUT_WIDTH-1:0] result,
    output                   result_valid,
    input                    result_ready
);

    always @ (posedge clk) begin
        if (select_valid && result_ready) begin
            if ((select == 1'b0) && a_valid) begin
                a_ready      <= 1'b1;
                b_ready      <= 1'b0;
                select_ready <= 1'b1;
            end
            else if ((select == 1'b1) && b_valid) begin
                a_ready      <= 1'b0;
                b_ready      <= 1'b1;
                select_ready <= 1'b1;
            end
            else begin
                a_ready      <= 1'b0;
                b_ready      <= 1'b0;
                select_ready <= 1'b0;
            end
        end 
        else begin
            a_ready      <= 1'b0;
            b_ready      <= 1'b0;
            select_ready <= 1'b0;
        end
    end

    assign result       = select ? b : a;
    assign result_valid = (select ? b_valid : a_valid) && select_valid;

endmodule
