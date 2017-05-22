module counter #(
    parameter WIDTH = 10,
              MAX_VALUE = 100
) (
    input clk,
    input rst,
    output [WIDTH-1:0] count,
    output             count_valid,
    input              count_ready
);

    reg [WIDTH-1:0] count_buffer;

    always @ (posedge clk) begin
        if (rst) begin
            count_buffer <= 0;
        end
        else count_buffer <= count_ready ? count_buffer + 1 : count_buffer;
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    assign count = count_buffer;
    assign count_valid = 1'b1;

endmodule
