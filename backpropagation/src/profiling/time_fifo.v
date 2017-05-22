module time_fifo #(
    parameter NAME = "SETME"
) (
    input clk,
    input rst,
    input [1:0] state,
    input print 
);

    real idle, calc, done, sum;

    always @ (posedge clk) begin
        if (rst) begin
            idle = 0;
            calc = 0;
            done = 0;
        end
        else begin
            case (state)
                0: idle = idle + 1;
                1: calc = calc + 1;
                2: done = done + 1;
            endcase

            if (print) begin
                sum = idle + calc + done;
                $display("%s fifo breakdown: idle: %f, calc: %f, done: %f", NAME, idle/sum, calc/sum, done/sum);
            end
        end
    end

endmodule
