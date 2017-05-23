module fifo_splitter4 #(
    parameter DATA_WIDTH=32
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
    input                   data_out2_ready,
    // data out 3
    output [DATA_WIDTH-1:0] data_out3,
    output                  data_out3_valid,
    input                   data_out3_ready,
    // data out 4
    output [DATA_WIDTH-1:0] data_out4,
    output                  data_out4_valid,
    input                   data_out4_ready
);

    reg [DATA_WIDTH-1:0] data_buffer;
    reg valid1, valid2, valid3, valid4;

    always @ (posedge clk) begin
        if (rst) begin
            data_buffer <= 0;
            valid1      <= 0;
            valid2      <= 0;
            valid3      <= 0;
            valid4      <= 0;
        end
        else begin
            if (~valid1 && ~valid2 && ~valid3 && ~valid4 && data_in_valid) begin // ask for next data
                data_buffer <= data_in;
                valid1      <= 1;
                valid2      <= 1; 
                valid3      <= 1;
                valid4      <= 1;
            end
            else begin
                valid1 <= (valid1 && data_out1_ready) ? 0 : valid1;
                valid2 <= (valid2 && data_out2_ready) ? 0 : valid2;
                valid3 <= (valid3 && data_out3_ready) ? 0 : valid3;
                valid4 <= (valid4 && data_out4_ready) ? 0 : valid4;
            end
        end
    end

    // outputs
    assign data_out1       = data_buffer;
    assign data_out2       = data_buffer;
    assign data_out3       = data_buffer;
    assign data_out4       = data_buffer;
    assign data_in_ready   = (~valid1 && ~valid2 && ~valid3 && ~valid4);
    assign data_out1_valid = valid1;
    assign data_out2_valid = valid2;
    assign data_out3_valid = valid3;
    assign data_out4_valid = valid4;

endmodule
