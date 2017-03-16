module fifo_splitter #(
    DATA_WIDTH=32
) (
    input clk,
    input rst,
    // data in
    input  [DATA_WIDTH-1:0] data_in,
    input                   data_in_valid,
    output                  data_in_ready,
    // data out 1
    output [DATA_WIDTH-1:0] data_out1,
    output                  data_out1_valid,
    input                   data_out1_ready,
    // data out 2
    output [DATA_WIDTH-1:0] data_out2,
    output                  data_out2_valid,
    input                   data_out2_ready
);

    reg [DATA_WIDTH-1:0] data_buffer;
    reg used1, used2;

    always @ (posedge clk) begin
        if (rst) begin
            data_buffer <= 0;
            used1       <= 1;
            used2       <= 1;
        end
        else begin
            if (used1 && used2 && data_in_valid) begin // ask for next data
                data_buffer <= data_in;
                used1       <= 0;
                used2       <= 0; 
            end
            else begin
                used1 <= (~used1 && data_out1_ready) ? 1 : used1;
                used2 <= (~used2 && data_out2_ready) ? 1 : used2;
            end
        end
    end

    // outputs
    assign data_out1       = data_buffer;
    assign data_out2       = data_buffer;
    assign data_in_ready   = (used1 && used2);
    assign data_out1_valid = ~used1;
    assign data_out2_valid = ~used2;

endmodule
