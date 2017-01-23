module mvm
#(
    parameter MATRIX_WIDTH      = 4, // width of the matrix aka the number of columns
              MATRIX_HEIGHT     = 5, // height of the matrix aka the number of rows and size of vector
              VECTOR_CELL_WIDTH = 8, // width of each vector cell in bits
              MATRIX_CELL_WIDTH = 8, // widht of each matrix cell in bits
              TILING_ROW        = 3, // number of vector_mac units to create
              TILING_COL        = 3  // number of multipliers per vector_mac unit
)(
    input clk,
    input rst,
    input                                                    start,
    input [VECTOR_WIDTH*VECTOR_CELL_WIDTH-1:0]               vector,
    input [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] matrix,
    output [MATRIX_WIDTH*RESULT_WIDTH-1:0]                   result,
    output                                                   valid
);

    //define the log2 function
    function integer log2;
        input integer num;
        integer i, result;
        begin
            for (i = 0; 2 ** i < num; i = i + 1)
                result = i + 1;
            log2 = result;
        end
    endfunction

    localparam VECTOR_WIDTH = MATRIX_HEIGHT;
    localparam RESULT_WIDTH = VECTOR_CELL_WIDTH + MATRIX_CELL_WIDTH + log2(VECTOR_WIDTH) + 1;

    reg [MATRIX_WIDTH*RESULT_WIDTH-1:0] result_buffer;
    reg [log2((MATRIX_WIDTH>MATRIX_HEIGHT) ? MATRIX_WIDTH :MATRIX_HEIGHT):0] row;
    reg mac_start, valid_buffer;

    // matrix transpose logic
    wire [MATRIX_WIDTH*MATRIX_HEIGHT*MATRIX_CELL_WIDTH-1:0] matrix_transpose;
    transpose#(.WIDTH(MATRIX_WIDTH), .HEIGHT(MATRIX_HEIGHT), .ELEMENT_WIDTH(MATRIX_CELL_WIDTH))
    transpose(.input_matrix(matrix), .output_matrix(matrix_transpose));
    //

    // Vector MAC units
    wire [RESULT_WIDTH-1:0] mac_results [TILING_ROW-1:0];
    wire [TILING_ROW-1:0] mac_valids;
    
    genvar i;
    generate
    for (i=0; i<TILING_ROW; i=i+1) begin: MEM
        vector_mac #(.VECTOR_SIZE(VECTOR_WIDTH), .WIDTH1(VECTOR_CELL_WIDTH), .WIDTH2(MATRIX_CELL_WIDTH), .TILING(TILING_COL))
        vector_mac (
            .clk(clk),
            .rst(rst),
            .start(mac_start),
            .a(vector),
            .b(matrix_transpose[(row+i)*VECTOR_WIDTH*MATRIX_CELL_WIDTH+:VECTOR_WIDTH*MATRIX_CELL_WIDTH]),
            .result(mac_results[i]),
            .valid(mac_valids[i])
        );
    end
    endgenerate
    //


    localparam IDLE=0, RUN=1;
    reg state;

    //integer x;

    always @ (posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            row           <= 0;
            mac_start     <= 0;
            result_buffer <= 0;
            valid_buffer  <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    state         <= start ? RUN : IDLE;
                    row           <= 0;
                    mac_start     <= start ? 1   : 0;
                    result_buffer <= start ? 0   : result_buffer;
                    valid_buffer  <= start ? 0   : valid_buffer;
                end
                RUN: begin
                    state         <= (row >= MATRIX_WIDTH) ? IDLE             : RUN; 
                    row           <= mac_valids[0]         ? row + TILING_ROW : row; // change row once mac units are done
                    mac_start     <= mac_valids[0]         ? 1                : 0;   // 
                    valid_buffer  <= (row >= MATRIX_WIDTH) ? 1                : 0;
                end
            endcase
        end
    end

    // assigning the MAC results to the buffer
    genvar x;
    generate
        for (x=0; x<TILING_ROW; x=x+1) begin: RES
            always @ (posedge mac_valids[x]) begin
                if (~valid_buffer) // if not done
                    result_buffer[(row+x)*RESULT_WIDTH+:RESULT_WIDTH] <= mac_results[x];
            end
        end
    endgenerate

    // outputs
    assign result = result_buffer;
    assign valid  = valid_buffer;

endmodule