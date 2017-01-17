module weight_updater
#(
    parameter NEURON_NUM       = 5,  // size of the vectors a and delta
              ACTIVATION_WIDTH = 8,  // width of each signal from the neurons
              WEIGHT_WIDTH     = 16  // width of individual weights
)
(
    input clk,
    input rst,
    input start,
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]              a,
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]              delta,
    input [NEURON_NUM*NEURON_NUM*WEIGHT_WIDTH-1:0]       w,
    output [NEURON_NUM*NEURON_NUM*(WEIGHT_WIDTH+1)-1:0]  result,
    output                                               finish
);

    reg [NEURON_NUM*NEURON_NUM*(WEIGHT_WIDTH+1)-1:0] result_buffer;
    reg  product_start, adder_start, finish_buffer;
    wire product_finish, adder_finish;
    wire [NEURON_NUM*NEURON_NUM*2*ACTIVATION_WIDTH-1:0]     product_result;
    wire [NEURON_NUM*NEURON_NUM*(1+2*ACTIVATION_WIDTH)-1:0] adder_result;

    tensor_product 
    #(.VECTOR_SIZE(NEURON_NUM), .CELL_WIDTH(ACTIVATION_WIDTH), .TILING_H(2), .TILING_V(2))
    tensor_product (
        .clk(clk),
        .rst(rst),
        .start(product_start),
        .a(a),
        .b(delta),
        .result(product_result),
        .finish(product_finish)
    );

    vector_add
    #(.VECTOR_SIZE(NEURON_NUM*NEURON_NUM), .CELL_WIDTH(2*ACTIVATION_WIDTH), .TILING(2))
    vector_add(
        .clk(clk),
        .rst(rst),
        .start(adder_start),
        .a(product_result),
        .b(w),
        .result(adder_result),
        .finish(adder_finish)
    );

    localparam IDLE=0, MULTIPLYING=1, ADDING=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            product_start <= 0;
            adder_start   <= 0;
            state         <= IDLE;
            finish_buffer <= 0;
            result_buffer <= 0;
        end
        else begin
            case (state)
            IDLE: begin
                product_start <= start? 1 : 0;
                adder_start   <= 0;
                state         <= start? MULTIPLYING : IDLE;
                finish_buffer <= start? 0 : finish_buffer;
                result_buffer <= start? 0 : result_buffer;
            end
            MULTIPLYING: begin
                product_start <= 0;
                adder_start   <= product_finish? 1 : 0;
                state         <= product_finish? ADDING: MULTIPLYING;
                finish_buffer <= 0;
                result_buffer <= 0;
            end
            ADDING: begin
                product_start <= 0;
                adder_start   <= 0;
                state         <= adder_finish? IDLE: ADDING;
                finish_buffer <= adder_finish? 1: 0;
                result_buffer <= adder_finish? adder_result: 0;
            end
            default: begin
                product_start <= 0;
                adder_start   <= 0;
                state         <= IDLE;
                finish_buffer <= 0;
                result_buffer <= 0;
            end
            endcase
        end
    end

    //outputs
    assign result = result_buffer;
    assign finish = finish_buffer;

endmodule
