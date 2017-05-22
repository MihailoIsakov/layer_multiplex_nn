module time_posedge #(
    parameter NAME = "SETME"
) (
    input signal
);

    integer old_time;

    always @ (posedge signal) begin
        $display("%s: %d ns", NAME, $stime - old_time);
        old_time <= $stime;
    end

endmodule
        
