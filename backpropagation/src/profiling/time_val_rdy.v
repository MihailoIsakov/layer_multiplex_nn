module time_val_rdy #(
    parameter NAME = "SETME"
) (
    input clk,
    input rst,
    input val,
    input rdy
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
