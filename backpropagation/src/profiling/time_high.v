module time_high #(
    parameter NAME = "SETME"
)(
    input clk,
    input rst,
    input signal
);

    integer cycles;

    always @ (posedge clk) begin
        if (rst)
            cycles <= 0;
        else 
            if (signal)
                cycles <= cycles + 1;
            else if (cycles != 0) begin
                $display("%s: %d ns", NAME, cycles);
                cycles <= 0;
            end
    end

endmodule
