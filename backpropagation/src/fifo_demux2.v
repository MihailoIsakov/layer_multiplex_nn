module fifo_demux2 #(
    parameter INPUT_WIDTH = 32
) (
    input clk,
    input rst,
    // input signal
    input [INPUT_WIDTH-1:0] in,
    input                   in_valid,
    output                  in_ready,
    // select signal
    input                   select,
    input                   select_valid,
    output                  select_ready,
    // output a
    output [INPUT_WIDTH-1:0] out0,
    output                   out0_valid,
    input                    out0_ready,
    // output b
    output [INPUT_WIDTH-1:0] out1,
    output                   out1_valid,
    input                    out1_ready
);
    
    localparam IDLE=0, DONE=1;
    reg state;

    reg select_buffer;
    reg [INPUT_WIDTH-1:0] in_buffer;
    reg select_set, in_set;

    wire result_ready;
    assign result_ready = ((select_buffer && out1_ready) || (!select_buffer && out0_ready));

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            select_buffer <= 0;
            select_set    <= 0;
            in_buffer     <= 0;
            in_set        <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    state         <= (select_set && in_set)        ? DONE   : IDLE;
                    select_buffer <= (!select_set && select_valid) ? select : select_buffer;
                    select_set    <= (!select_set && select_valid) ? 1      : select_set;
                    in_buffer     <= (!in_set && in_valid)         ? in     : in_buffer;
                    in_set        <= (!in_set && in_valid)         ? 1      : in_set;
                end
                DONE: begin
                    state         <= result_ready ? IDLE : DONE;
                    select_buffer <= result_ready ? 0    : select_buffer;
                    select_set    <= result_ready ? 0    : select_set;
                    in_buffer     <= result_ready ? 0    : in_buffer;
                    in_set        <= result_ready ? 0    : in_set;
                end
            endcase
        end
    end

    assign in_ready = !in_set;
    assign select_ready = !select_set;
    assign out0 = in_buffer;
    assign out0_valid = (state==DONE) && !select_buffer;
    assign out1 = in_buffer;
    assign out1_valid = (state==DONE) && select_buffer;

endmodule
