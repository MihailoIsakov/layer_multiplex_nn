`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   05:07:26 12/29/2016
// Design Name:   param_rom
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/t_param_rom.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: param_rom
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module t_param_rom;

	// Inputs
	reg enable;
	reg [9:0] addr;

	// Outputs
	wire [7:0] data;

	// Instantiate the Unit Under Test (UUT)
	param_rom 
    # (
        .width(8),
        .depth(1024),
        .init_file("sigmoid.list")
    ) 
    rom (
		.enable(enable), 
		.addr(addr), 
		.data(data)
	);

    always 
        #10 addr = addr + 10;

	initial begin
		// Initialize Inputs
		enable = 1;
		addr = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

