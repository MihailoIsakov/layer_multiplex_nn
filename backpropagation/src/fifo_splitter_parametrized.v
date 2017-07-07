module fifo_splitter_parametrized #(
    parameter DATA_WIDTH=32,
              SIGNALS   =4
) (
    input clk,
    input rst,
    // data in
    input  [DATA_WIDTH-1:0] data_in,
    input                   data_in_valid,
    output                  data_in_ready,
    // #SIGNALS data outputs
    output [DATA_WIDTH*SIGNALS-1:0] data_out,
    output [SIGNALS-1:0] data_out_valid,
    input  [SIGNALS-1:0] data_out_ready
);

    reg [DATA_WIDTH-1:0] data_buffer;
    reg [SIGNALS-1:0] out_valid;

    genvar i;
    generate 
    for (i=0; i<SIGNALS; i=i+1) begin: SIGNAL
        always @ (posedge clk) begin
            if (rst) begin
                data_buffer  <= 0;
                out_valid[i] <= 0;
            end
            else begin
                if (out_valid == 0 && data_in_valid) begin
                    data_buffer  <= data_in;
                    out_valid[i] <= 1;
                end
                else begin
                    data_buffer  <= data_buffer;
                    out_valid[i] <= (out_valid[i] && data_out_ready[i]) ? 0 : out_valid[i];
                end
            end
        end
    end
    endgenerate 

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs 
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    assign data_out = {SIGNALS{data_buffer}};
    assign data_in_ready   = out_valid == 0;
    assign data_out_valid  = out_valid;

endmodule
