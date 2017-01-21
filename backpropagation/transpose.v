module transpose
#(
    parameter WIDTH  = 4,
              HEIGHT = 3,
              ELEMENT_WIDTH = 8
)(
    input  [WIDTH*HEIGHT*ELEMENT_WIDTH-1:0] input_matrix,
    output [WIDTH*HEIGHT*ELEMENT_WIDTH-1:0] output_matrix
);

    genvar row, col;
    generate
    for (row=0; row<HEIGHT; row=row+1) begin: ROWS
        for (col=0; col<WIDTH; col=col+1) begin: COLS
            assign output_matrix[col*HEIGHT*ELEMENT_WIDTH+row*ELEMENT_WIDTH+:ELEMENT_WIDTH] 
                 = input_matrix [row*WIDTH*ELEMENT_WIDTH+col*ELEMENT_WIDTH+:ELEMENT_WIDTH];
        end
    end
    endgenerate

endmodule
