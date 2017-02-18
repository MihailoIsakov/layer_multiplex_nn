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
    input start,
    input  [NEURON_NUM*LUT_ADDR_SIZE-1:0] inputs,  // number of signals from the input
    output [NEURON_NUM*LUT_WIDTH-1:0]     outputs,
    output                                valid
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

    reg  [log2(NEURON_NUM):0]       counter;
    reg                             valid_buffer;
    reg  [NEURON_NUM*LUT_WIDTH-1:0] outputs_buffer;

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

    localparam IDLE=0, RUN=1;
    reg state;

    always @ (posedge clk) begin
        if (rst) begin
            counter        <= 0;
            outputs_buffer <= 0;
            valid_buffer   <= 0;
            state          <= IDLE;
        end
        else begin
            if (state == IDLE) begin
                counter        <= 0;
                outputs_buffer <= start ? 0 : outputs_buffer;
                valid_buffer   <= start ? 0 : valid_buffer;
                state          <= start ? RUN : IDLE;
            end
            else begin
                counter                                          <= counter + 2;
                outputs_buffer[(counter-2)*LUT_WIDTH+:LUT_WIDTH] <= data0;
                outputs_buffer[(counter-1)*LUT_WIDTH+:LUT_WIDTH] <= data1;
                valid_buffer                                     <= (counter >= NEURON_NUM) ? 1    : 0;
                state                                            <= (counter >= NEURON_NUM) ? IDLE : RUN;
            end
        end
    end


    // outputs
    assign outputs = outputs_buffer;
    assign valid   = valid_buffer;

endmodule
