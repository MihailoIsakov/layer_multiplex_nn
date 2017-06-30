module extend #(
    parameter INPUT_NUM    = 4,
              INPUT_WIDTH  = 9,
              EXTRA        = 3 
) (
    input [INPUT_NUM*INPUT_WIDTH-1:0]           in,
    output [INPUT_NUM*(INPUT_WIDTH+EXTRA)-1:0] out
);

    genvar i;
    generate
    for (i=0; i<INPUT_NUM; i=i+1) begin: EXTEND
        assign out[i*(INPUT_WIDTH+EXTRA)+:(INPUT_WIDTH+EXTRA)] 
            = {{EXTRA{in[(i+1)*INPUT_WIDTH-1]}}, in[i*INPUT_WIDTH+:INPUT_WIDTH]};
    end
    endgenerate

endmodule
