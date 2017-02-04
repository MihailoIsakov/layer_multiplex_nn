
/** @module : TWO_PORT_BRAM
 *  @author : Michel Kinsy
 
 *  Copyright (c) 2012 Heracles (CSG/CSAIL/MIT)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */
 
 (* ram_style = "block" *)
module two_port_BRAM #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 8, INIT_FILE="activations.list") (
		clock,
    	readEnable0,
    	readAddress0,
   		readData0,
    	readEnable1,
    	readAddress1,
   		readData1,
    	writeEnable0,
    	writeAddress0,
    	writeData0, 
		writeEnable1,
    	writeAddress1,
    	writeData1
); 

localparam MEM_DEPTH = 1 << ADDR_WIDTH;

input clock; 
input readEnable0;
input [ADDR_WIDTH-1:0]   readAddress0;
output [DATA_WIDTH-1:0]  readData0;
input readEnable1;
input [ADDR_WIDTH-1:0]   readAddress1;
output [DATA_WIDTH-1:0]  readData1;

input writeEnable0;
input [ADDR_WIDTH-1:0]   writeAddress0;
input [DATA_WIDTH-1:0]   writeData0;
input writeEnable1;
input [ADDR_WIDTH-1:0]   writeAddress1;
input [DATA_WIDTH-1:0]   writeData1;
 
reg [DATA_WIDTH-1:0]     readData0;
reg [DATA_WIDTH-1:0]     readData1;
reg [DATA_WIDTH-1:0]     ram [0:MEM_DEPTH-1];
 
//--------------Code Starts Here------------------ 
always@(posedge clock) begin : RAM_READ
		readData0 <= (readEnable0 & writeEnable0 & (readAddress0 == writeAddress0))? writeData0 : 
					 (readEnable0 & writeEnable1 & (readAddress0 == writeAddress1))? writeData1 : 
					 readEnable0? ram[readAddress0] : 0;
		readData1 <= (readEnable1 & writeEnable0 & (readAddress1 == writeAddress0))? writeData0 : 
					 (readEnable1 & writeEnable1 & (readAddress1 == writeAddress1))? writeData1 : 
					 readEnable1? ram[readAddress1] : 0;
end

always@(posedge clock) begin : RAM_WRITE
	if(writeEnable0 & writeEnable1 & ( writeAddress0 == writeAddress1))
		ram[writeAddress0] <= writeData0;
	else begin 
		if(writeEnable0) ram[writeAddress0] <= writeData0;
		if(writeEnable1) ram[writeAddress1] <= writeData1;
	end 
end

initial begin
    $readmemb(INIT_FILE, ram);
end
    
/*  
always @ (posedge clock) begin 
          $display ("-------------------------------BRAM-------------------------------------------");  
          $display ("Read [%b]\t\t\tWrite [%b]", readEnable0, writeEnable0);
          $display ("Read Address [%h] \t\t Write Address [%h]", readAddress0, writeAddress0); 
          $display ("Read Data [%h]", readData0);
          $display ("Write Data [%h]",writeData0);
          $display ("Read1 [%b]\t\t\tWrite1 [%b]", readEnable1, writeEnable1);
          $display ("Read Address1 [%h] \t\t Write Address1 [%h]", readAddress1, writeAddress1); 
          $display ("Read Data1 [%h]", readData1);
          $display ("Write Data1 [%h]",writeData1);
          $display ("-----------------------------------------------------------------------------");
 end  
 //*/
endmodule

