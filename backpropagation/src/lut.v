module lut
#(
    parameter NEURON_NUM    = 6,
              LUT_ADDR_SIZE = 10,
              LUT_DEPTH     = 1 << LUT_ADDR_SIZE,
              LUT_WIDTH     = 9,
              LUT_INIT_FILE = "sigmoid.list"
)(
    input clk,
    input rst,
    // Input
    input  [NEURON_NUM*LUT_ADDR_SIZE-1:0] inputs,  // number of signals from the input
    input                                 inputs_valid,
    output reg                            inputs_ready,
    // Output
    output [NEURON_NUM*LUT_WIDTH-1:0]     outputs,
    output reg                            outputs_valid,
    input                                 outputs_ready
);

    `include "log2.v"

    reg  [log2(NEURON_NUM):0]       counter;
    //reg                             valid_buffer;
    reg  [NEURON_NUM*LUT_WIDTH-1:0] outputs_buffer;
    // READY/VALID protocol
    //reg inputs_ready, outputs_valid;

    wire [LUT_WIDTH-1:0]     data0,  data1;
    wire [LUT_ADDR_SIZE-1:0] input0, input1;
    assign input0 = inputs[(counter  )*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];
    assign input1 = inputs[(counter+1)*LUT_ADDR_SIZE+:LUT_ADDR_SIZE];

    two_port_BRAM 
    #(
        .DATA_WIDTH(LUT_WIDTH), 
        .ADDR_WIDTH(LUT_ADDR_SIZE),
        .INIT_FILE(LUT_INIT_FILE)
    ) LUT (
        .clock        (clk   ),
        .readEnable0  (1'b1  ),
        .readAddress0 (input0),
   		.readData0    (data0 ),
    	.readEnable1  (1'b1  ),
    	.readAddress1 (input1),
   		.readData1    (data1 ),
        //not used
    	.writeEnable0 (1'b0  ),
    	.writeAddress0(      ),
    	.writeData0   (      ),
		.writeEnable1 (1'b0  ),
    	.writeAddress1(      ),
    	.writeData1   (      )
    );

    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            counter        <= 0;
            outputs_buffer <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    counter        <= 0;
                    outputs_buffer <= 0;
                end
                CALC: begin
                    counter                                          <= counter + 2;
                    outputs_buffer[(counter-2)*LUT_WIDTH+:LUT_WIDTH] <= data0;
                    outputs_buffer[(counter-1)*LUT_WIDTH+:LUT_WIDTH] <= data1;
                end
                DONE: begin
                    counter <= 0;
                    outputs_buffer <= outputs_buffer;
                end
            endcase
        end
    end
    
    // valid / ready protocol
    always @ (posedge clk) begin
        if (rst) begin
            inputs_ready  <= 0;
            outputs_valid <= 0;
            state         <= IDLE;
        end
        else case (state)
            IDLE: begin
                inputs_ready  <= 1;
                outputs_valid <= 0;
                state         <= inputs_valid ? CALC : IDLE;
            end
            CALC: begin
                inputs_ready  <= 0;
                outputs_valid <= 0;
                state         <= (counter >= NEURON_NUM) ? DONE : CALC;
            end
            DONE: begin
                inputs_ready  <= 0;
                outputs_valid <= 1;
                state         <= outputs_ready ? IDLE : DONE;
            end
        endcase
    end

    // outputs
    assign outputs = outputs_buffer;

endmodule
