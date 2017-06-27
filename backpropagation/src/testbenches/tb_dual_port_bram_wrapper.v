`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:03:20 03/27/2017
// Design Name:   bram_wrapper
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/src/testbenches/tb_bram_wrapper.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: bram_wrapper
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_dual_port_bram_wrapper;

	// Inputs
	reg clk;
	reg rst;
    // first port 
	reg [7:0] read_addr_0;
	reg read_addr_0_valid;
    reg read_data_0_ready;
    reg [7:0] write_addr_0;
	reg write_addr_0_valid;
	reg [31:0] write_data_0;
	reg write_data_0_valid;
	wire read_addr_0_ready;
	wire [31:0] read_data_0;
	wire read_data_0_valid;
	wire write_addr_0_ready;
	wire write_data_0_ready;
    
    // second port 
	reg [7:0] read_addr_1;
	reg read_addr_1_valid;
	reg read_data_1_ready;
	reg [7:0] write_addr_1;
	reg write_addr_1_valid;
	reg [31:0] write_data_1;
	reg write_data_1_valid;
	wire read_addr_1_ready;
	wire [31:0] read_data_1;
	wire read_data_1_valid;
	wire write_addr_1_ready;
	wire write_data_1_ready;

	// Instantiate the Unit Under Test (UUT)
	dual_port_bram_wrapper #(
        .INIT_FILE("") 
    ) uut (
		.clk               (clk               ),
		.rst               (rst               ),
		.read_addr_0       (read_addr_0       ),
		.read_addr_0_valid (read_addr_0_valid ),
		.read_addr_0_ready (read_addr_0_ready ),
		.read_data_0       (read_data_0       ),
		.read_data_0_valid (read_data_0_valid ),
		.read_data_0_ready (read_data_0_ready ),
		.write_addr_0      (write_addr_0      ),
		.write_addr_0_valid(write_addr_0_valid),
		.write_addr_0_ready(write_addr_0_ready),
		.write_data_0      (write_data_0      ),
		.write_data_0_valid(write_data_0_valid),
		.write_data_0_ready(write_data_0_ready),
        // second r/w ports
		.read_addr_1       (read_addr_1       ),
		.read_addr_1_valid (read_addr_1_valid ),
		.read_addr_1_ready (read_addr_1_ready ),
		.read_data_1       (read_data_1       ),
		.read_data_1_valid (read_data_1_valid ),
		.read_data_1_ready (read_data_1_ready ),
		.write_addr_1      (write_addr_1      ),
		.write_addr_1_valid(write_addr_1_valid),
		.write_addr_1_ready(write_addr_1_ready),
		.write_data_1      (write_data_1      ),
		.write_data_1_valid(write_data_1_valid),
		.write_data_1_ready(write_data_1_ready)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;

		read_addr_0 = 0;
		read_addr_0_valid = 0;

		read_data_0_ready = 0;

		write_addr_0 = 0;
		write_addr_0_valid = 0;

		write_data_0 = 0;
		write_data_0_valid = 0;

        // second 
		read_addr_1 = 0;
		read_addr_1_valid = 0;

		read_data_1_ready = 0;

		write_addr_1 = 0;
		write_addr_1_valid = 0;

		write_data_1 = 0;
		write_data_1_valid = 0;


        #20 rst = 0;

        #20 read_addr_0 = 2;
            read_addr_0_valid = 1;
        #2  read_addr_0_valid = 0; 
        // should be 0

        #10 read_data_0_ready = 1;
        #2  read_data_0_ready = 0;
        

        // overwrite
        #10 write_addr_0 = 2;
            write_addr_0_valid = 1;
        #2  write_addr_0_valid = 0;
            
        
        #10 write_data_0 = 100;
            write_data_0_valid = 1;
        #2  write_data_0_valid = 0;

        #20 read_addr_0 = 2;
            read_addr_0_valid = 1;
        #2  read_addr_0_valid = 0; 
        // should be 100

        #10 read_data_0_ready = 1;
        #2  read_data_0_ready = 0;

        #10 write_data_1 = 1000;
            write_data_1_valid = 1;
            write_addr_1 = 3;
            write_addr_1_valid = 1;
        #2  write_data_1 = 0;
            write_data_1_valid = 0;
            write_addr_1 = 0;
            write_addr_1_valid = 0;

        #20 read_addr_0 = 3;
            read_addr_0_valid = 1;

        #20 read_addr_1 = 2;
            read_addr_1_valid = 1;


	end
      
endmodule

