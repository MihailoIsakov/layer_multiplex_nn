module activation_stack 
#(
    parameter NEURON_NUM       = 6, 
              ACTIVATION_WIDTH = 8,
              STACK_ADDR_WIDTH = 10
)
(
    input clk, 
    // one write port 
    input  [STACK_WIDTH-1:0]      input_data,
    input  [STACK_ADDR_WIDTH-1:0] input_addr,
    input                         input_wr_en,
    // two read ports
    input  [STACK_ADDR_WIDTH-1:0] output_addr,
    output [STACK_WIDTH-1:0]      output_data0,
    output [STACK_WIDTH-1:0]      output_data1
);

    localparam STACK_WIDTH = NEURON_NUM*ACTIVATION_WIDTH; 

    two_port_BRAM 
    #(
        .DATA_WIDTH(STACK_WIDTH), 
        .ADDR_WIDTH(STACK_ADDR_WIDTH)
    ) stack (
        .clock(clk),
        .readEnable0(1'b1),
        .readAddress0(output_addr),
   		.readData0(output_data0),
    	.readEnable1(1'b1),
    	.readAddress1(output_addr-1),
   		.readData1(output_data1),
    	.writeEnable0(input_wr_en),
    	.writeAddress0(input_addr),
    	.writeData0(input_data), 
		.writeEnable1(1'b0),
    	.writeAddress1(0),
    	.writeData1(0)
    );

endmodule
