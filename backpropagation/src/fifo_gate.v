module fifo_gate #(
    parameter DATA_WIDTH = 32
) (
    input clk,
    input rst, 
    input [DATA_WIDTH-1:0]  data,
    input                   data_valid,
    output                  data_ready,
    input                   pass,
    input                   pass_valid,
    output                  pass_ready,
    output [DATA_WIDTH-1:0] result,
    output                  result_valid,
    input                   result_ready
); 

    reg [DATA_WIDTH-1:0] data_buffer;
    reg data_set;
    reg pass_buffer, pass_set;
    

    localparam IDLE=0, DONE=1;
    reg state;

    always @ (posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            data_buffer <= 0;
            data_set    <= 0;
            pass_buffer <= 0;
            pass_set    <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state       <= data_set && pass_set ? DONE : IDLE;
                    data_buffer <= !data_set && data_valid ? data : data_buffer;
                    data_set    <= data_set || data_valid;
                    pass_buffer <= !pass_set && pass_valid ? pass : pass_buffer;
                    pass_set    <= pass_set || pass_valid;
                end
                DONE: begin
                    state       <= pass_buffer ? result_ready ? IDLE : DONE        : IDLE;
                    data_buffer <= pass_buffer ? result_ready ? 0    : data_buffer : 0;
                    data_set    <= pass_buffer ? result_ready ? 0    : data_set    : 0;
                    pass_buffer <= pass_buffer ? result_ready ? 0    : pass_buffer : 0;
                    pass_set    <= pass_buffer ? result_ready ? 0    : pass_set    : 0;
                end
            endcase
        end
    end
    
    assign data_ready = !data_set;
    assign pass_ready = !pass_set;
    assign result     = data_buffer;
    assign result_valid = state == DONE && pass_buffer; // only valid if pass set

endmodule
