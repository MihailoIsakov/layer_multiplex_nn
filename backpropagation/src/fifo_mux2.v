module fifo_mux2 #(
    parameter INPUT_WIDTH = 32
) (
    input  clk,
    input  rst,
    // a signal
    input  [INPUT_WIDTH-1:0] a,
    input                    a_valid,
    output                   a_ready,
    // b signal
    input  [INPUT_WIDTH-1:0] b,
    input                    b_valid,
    output                   b_ready,
    // select signal
    input                    select,
    input                    select_valid,
    output                   select_ready,
    // result signal
    output [INPUT_WIDTH-1:0] result,
    output                   result_valid,
    input                    result_ready
);

    localparam IDLE=0, DONE=1;
    reg state;

    reg select_buffer;
    reg [INPUT_WIDTH-1:0] a_buffer, b_buffer;
    reg a_set, b_set, select_set;

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            a_buffer      <= 0;
            a_set         <= 0;
            b_buffer      <= 0;
            b_set         <= 0;
            select_buffer <= 0;
            select_set    <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    // if the select and the appropriate input are set, move to DONE
                    state         <= (select_set && (select_buffer ? b_set : a_set)) ? DONE : IDLE;
                    a_buffer      <= (!a_set && a_valid)            ? a      : a_buffer;
                    a_set         <= (!a_set && a_valid)            ? 1      : a_set;
                    b_buffer      <= (!b_set && b_valid)            ? b      : b_buffer;
                    b_set         <= (!b_set && b_valid)            ? 1      : b_set;
                    select_buffer <= (!select_set && select_valid)  ? select : select_buffer;
                    select_set    <= (!select_set && select_valid)  ? 1      : select_set;
                end
                DONE: begin
                    // if ready, move to IDLE
                    state         <= result_ready ? IDLE : DONE;
                    // reset only the used side of the mux, keep the other one
                    if (select_buffer == 0) begin
                        a_buffer  <= result_ready ? 0 : a_buffer;
                        a_set     <= result_ready ? 0 : a_set;
                        b_buffer  <= b_buffer;
                        b_set     <= b_set;
                    end
                    else begin
                        a_buffer  <= a_buffer;
                        a_set     <= a_set;
                        b_buffer  <= result_ready ? 0 : b_buffer;
                        b_set     <= result_ready ? 0 : b_set;
                    end
                    select_buffer <= result_ready ? 0 : select_buffer;
                    select_set    <= result_ready ? 0 : select_set;
                end
                default: begin
                    state         <= IDLE;
                    a_buffer      <= 0;
                    a_set         <= 0;
                    b_buffer      <= 0;
                    b_set         <= 0;
                    select_buffer <= 0;
                    select_set    <= 0;
                end
            endcase
        end
    end

    assign a_ready      = !a_set;
    assign b_ready      = !b_set;
    assign select_ready = !select_set;
    assign result       = select_buffer ? b_buffer : a_buffer;
    assign result_valid = (select_buffer ? b_set : a_set) && select_set && (state == DONE);

endmodule
