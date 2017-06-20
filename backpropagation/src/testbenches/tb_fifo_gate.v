module tb_fifo_gate;

    parameter DATA_WIDTH = 32;

    reg clk;
    reg rst; 
    reg [DATA_WIDTH-1:0]  data;
    reg                   data_valid;
    wire                  data_ready;
    reg                   pass;
    reg                   pass_valid;
    wire                  pass_ready;
    wire [DATA_WIDTH-1:0] result;
    wire                  result_valid;
    reg                   result_ready;

    fifo_gate #(
        .DATA_WIDTH(DATA_WIDTH) 
    ) uut (
        .clk         (clk         ),
        .rst         (rst         ),
        .data        (data        ),
        .data_valid  (data_valid  ),
        .data_ready  (data_ready  ),
        .pass        (pass        ),
        .pass_valid  (pass_valid  ),
        .pass_ready  (pass_ready  ),
        .result      (result      ),
        .result_valid(result_valid),
        .result_ready(result_ready)
    ); 

    always 
        #1 clk <= ~clk;

    initial begin
        clk              <= 0;
        rst              <= 1;

        data             <= 10;
        data_valid       <= 0;

        pass             <= 0;
        pass_valid       <= 0;

        result_ready     <= 0;

        #10 rst          <= 0;

        #10 data_valid   <= 1;
        #10 pass_valid   <= 1;
        #10 result_ready <= 1;

        #20 pass         <= 1;

        #20 pass         <= 0;
        #20 result_ready <= 0;
    end

endmodule
