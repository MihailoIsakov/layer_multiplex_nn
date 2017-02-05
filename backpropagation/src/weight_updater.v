module weight_updater
#(
    parameter NEURON_NUM        = 5,  // size of the vectors a and delta
              ACTIVATION_WIDTH  = 9,  // width of each signal from the neurons
              DELTA_CELL_WIDTH  = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH = 16, // width of individual weights
              FRACTION_WIDTH    = 0
)
(
    input clk,
    input rst,
    input start,
    input  [NEURON_NUM*ACTIVATION_WIDTH-1:0]             a,
    input  [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta,
    input  [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w,
    output [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] result,
    output                                               valid,
    output                                               error
);

    reg  product_start, adder_start, valid_buffer;
    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] result_buffer;
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] product_result, adder_result;
    wire product_valid, adder_valid;
    wire product_error, adder_error;

    tensor_product #(
        .A_VECTOR_LEN     (NEURON_NUM       ),
        .B_VECTOR_LEN     (NEURON_NUM       ),
        .A_CELL_WIDTH     (ACTIVATION_WIDTH ),
        .B_CELL_WIDTH     (DELTA_CELL_WIDTH ),
        .RESULT_CELL_WIDTH(WEIGHT_CELL_WIDTH),
        .FRACTION_WIDTH   (FRACTION_WIDTH   ),
        .TILING_H         (2                ),
        .TILING_V         (2                )
    ) tensor_product (
        .clk   (clk           ),
        .rst   (rst           ),
        .start (product_start ),
        .a     (a             ),
        .b     (delta         ),
        .result(product_result),
        .valid (product_valid ),
        .error (product_error )
    );

    vector_add
    #(
        .VECTOR_LEN       (NEURON_NUM*NEURON_NUM),
        .A_CELL_WIDTH     (WEIGHT_CELL_WIDTH    ),
        .B_CELL_WIDTH     (WEIGHT_CELL_WIDTH    ),
        .RESULT_CELL_WIDTH(WEIGHT_CELL_WIDTH    ),
        .TILING           (2                    )
    ) vector_add (
        .clk   (clk           ),
        .rst   (rst           ),
        .start (adder_start   ),
        .a     (product_result),
        .b     (w             ),
        .result(adder_result  ),
        .valid (adder_valid   ),
        .error (adder_error   )
    );

    localparam IDLE=0, MULTIPLYING=1, ADDING=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            product_start <= 0;
            adder_start   <= 0;
            state         <= IDLE;
            valid_buffer  <= 0;
            result_buffer <= 0;
        end
        else begin
            case (state)
            IDLE: begin
                product_start <= start ? 1           : 0;
                adder_start   <= 0;
                state         <= start ? MULTIPLYING : IDLE;
                valid_buffer  <= start ? 0           : valid_buffer;
                result_buffer <= start ? 0           : result_buffer;
            end
            MULTIPLYING: begin
                product_start <= 0;
                adder_start   <= product_valid ? 1      : 0;
                state         <= product_valid ? ADDING : MULTIPLYING;
                valid_buffer  <= 0;
                result_buffer <= 0;
            end
            ADDING: begin
                product_start <= 0;
                adder_start   <= 0;
                state         <= adder_valid ? IDLE         : ADDING;
                valid_buffer  <= adder_valid ? 1            : 0;
                result_buffer <= adder_valid ? adder_result : 0;
            end
            default: begin
                product_start <= 0;
                adder_start   <= 0;
                state         <= IDLE;
                valid_buffer  <= 0;
                result_buffer <= 0;
            end
            endcase
        end
    end

    //outputs
    assign result = result_buffer;
    assign valid  = valid_buffer;
    assign error  = product_error | adder_error;

    //testing
    genvar i;
    wire [WEIGHT_CELL_WIDTH-1:0] product_result_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] adder_result_mem   [0:NEURON_NUM*NEURON_NUM-1];
    wire [WEIGHT_CELL_WIDTH-1:0] w_mem              [0:NEURON_NUM*NEURON_NUM-1];

    generate
    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM
        assign product_result_mem[i] = product_result[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign adder_result_mem[i]   = adder_result  [i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
        assign w_mem[i]              = w             [i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    endgenerate

endmodule
