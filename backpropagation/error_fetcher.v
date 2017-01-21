module error_fetcher
#(
    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              LAYER_ADDR_WIDTH    = 2,  // size of the layer number 
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list"

)(
    input clk,
    input rst,
    input start,
    input [LAYER_ADDR_WIDTH-1:0]               layer,
    input [SAMPLE_ADDR_SIZE-1:0]               sample_index,
    input [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z,
    input [NEURON_NUM*ACTIVATION_WIDTH-1:0]    delta_input,
    input                                      delta_input_valid,
    output [NEURON_NUM*ACTIVATION_WIDTH-1:0]   delta_output,
    output                                     delta_output_valid
);

    wire sigma_valid, sigma_der_valid, subtracter_finish, dot_finish;
    reg  sigma_start, sigma_start, subtract_start, dot_start;
    wire [NEURON_NUM*ACTIVATION_WIDTH-1:0] a, y; 
    wire [NEURON_NUM*  (1+ACTIVATION_WIDTH)-1:0] subtracter_result, sigma_der_out; 
    wire [NEURON_NUM*2*(1+ACTIVATION_WIDTH)-1:0] dot_result;


    lut #(
        .NEURON_NUM(NEURON_NUM), 
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH),
        .LUT_DEPTH(1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH(ACTIVATION_WIDTH),
        .LUT_INIT_FILE("activations.list"))
    sigma (
        .clk(clk),
        .rst(rst),
        .start(sigma_start),
        .inputs(z),
        .outputs(a),
        .valid(sigma_valid)
    );

    lut #(
        .NEURON_NUM(NEURON_NUM), 
        .LUT_ADDR_SIZE(NEURON_OUTPUT_WIDTH),
        .LUT_DEPTH(1 << NEURON_OUTPUT_WIDTH),
        .LUT_WIDTH(ACTIVATION_WIDTH+1), // padded to the left to have the same size with the result from subtraction
        .LUT_INIT_FILE("activations_padded.list")) // FIXME replace activations with their derivative LUT
    sigma_derivative (
        .clk(clk),
        .rst(rst),
        .start(sigma_start),
        .inputs(z),
        .outputs(sigma_der_out),
        .valid(sigma_der_valid)
    );

    BRAM #(
        .DATA_WIDTH(NEURON_NUM*ACTIVATION_WIDTH),
        .ADDR_WIDTH(SAMPLE_ADDR_SIZE),
        .INIT_FILE(TARGET_FILE)) // TODO create a random weights initialization init file
    targets_bram (
		.clock(clk),
    	.readEnable(1'b1),
    	.readAddress(sample_index),
   		.readData(y),
    	.writeEnable(0),
    	.writeAddress(),
    	.writeData()
    );

    vector_subtract
    #(.VECTOR_SIZE(NEURON_NUM), .CELL_WIDTH(ACTIVATION_WIDTH), .TILING(2))
    subtracter (
        .clk(clk),
        .rst(rst),
        .start(subtract_start),
        .a(a),
        .b(y),
        .result(subtracter_result),
        .finish(subtracter_finish)
    );

    vector_dot
    #(.VECTOR_SIZE(NEURON_NUM), .CELL_WIDTH(ACTIVATION_WIDTH+1), .TILING(2))
    doter (
        .clk(clk),
        .rst(rst),
        .start(dot_start),
        .a(subtracter_result),
        .b(sigma_der_out),
        .result(dot_result),
        .finish(dot_finish)
    );

    localparam IDLE=0, LUT=1, SUBTRACT=2, DOT=3, FINISH=4;
    reg [2:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state          <= IDLE;
            sigma_start    <= 0;
            subtract_start <= 0;
            dot_start      <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    state          <= (layer==LAYER_MAX && start) ? LUT : IDLE;
                    sigma_start    <= (layer==LAYER_MAX && start) ? 1   : 0;
                    subtract_start <= 0;
                    dot_start      <= 0;
                end
                LUT: begin
                    state          <= (sigma_valid && sigma_der_valid) ? SUBTRACT : LUT;
                    sigma_start    <= 0;
                    subtract_start <= (sigma_valid && sigma_der_valid) ? 1        : 0;
                    dot_start      <= 0;
                end
                SUBTRACT: begin
                    state          <= subtracter_finish ? DOT : SUBTRACT;
                    sigma_start    <= 0;
                    subtract_start <= 0;
                    dot_start      <= subtracter_finish ? 1 : 0;
                end
                DOT: begin
                    state          <= dot_finish ? FINISH : DOT;
                    sigma_start    <= 0;
                    subtract_start <= 0;
                    dot_start      <= 0;
                end
                FINISH: begin
                    state          <= (layer==LAYER_MAX) ? FINISH : IDLE;
                    sigma_start    <= 0;
                    subtract_start <= 0;
                    dot_start      <= 0;
                end
                default: begin
                    state          <= IDLE;
                    sigma_start    <= 0;
                    subtract_start <= 0;
                    dot_start      <= 0;
                end
            endcase
        end
    end

    // outputs
    assign delta_output       = (layer==LAYER_MAX) ? dot_result : delta_input;
    assign delta_output_valid = (layer==LAYER_MAX)
        ? (state==FINISH) // in case it's the last layer, test if state is FINISHED 
            ? 1
            : 0
        : delta_input_valid; // in case it's not the last layer, let delta_input and delta_input_valid through


    // testing 
    wire [NEURON_OUTPUT_WIDTH-1:0]    z_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH-1:0]       a_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH-1:0]       y_mem      [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH:0]         sub_mem    [0:NEURON_NUM-1];
    wire [ACTIVATION_WIDTH:0]         a_prim_mem [0:NEURON_NUM-1];
    wire [2*(ACTIVATION_WIDTH+1)-1:0] dot_mem    [0:NEURON_NUM-1];

    genvar i; 
    generate 
    for (i=0; i<NEURON_NUM; i=i+1) begin:MEM
        assign z_mem[i]      = z[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
        assign a_mem[i]      = a[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign y_mem[i]      = y[i*ACTIVATION_WIDTH+:ACTIVATION_WIDTH];
        assign sub_mem[i]    = subtracter_result[i*  (1+ACTIVATION_WIDTH)+:  (1+ACTIVATION_WIDTH)];
        assign a_prim_mem[i] = sigma_der_out    [i*  (1+ACTIVATION_WIDTH)+:  (1+ACTIVATION_WIDTH)];
        assign dot_mem[i]    = dot_result       [i*2*(1+ACTIVATION_WIDTH)+:2*(1+ACTIVATION_WIDTH)];
    end
    endgenerate

    

endmodule
