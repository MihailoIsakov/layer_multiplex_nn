`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        ASCS LAB
// Engineer:       G Sivaperumal
// 
// Create Date:    04:52:53 01/16/2017 
// Design Name: 
// Module Name:    MVM_element 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//////////////////////////////////////////////////////////////////////////////////
module MVM_element(vector,matrix_column,out);
	 parameter vector_size = 3;// Vector_size
	 parameter width_element = 5;// Width of each element
	 
	 
	 input [vector_size*width_element-1 : 0] vector,matrix_column;//input vector and column of the matrix(remember the matrix is transposed)
	 output [2*width_element+vector_size-1:0]out;// output of the column and the vector multiplication
	 

	
	 wire [2*width_element + vector_size-1:0] outwire[2*vector_size-2:0];

	 genvar j;
	 generate
	 for( j = 0; j < 2*vector_size -1; j = j + 1)
	 begin : outwire_x
		if (j < vector_size)
			assign outwire[j] = $signed(vector[(j+1)*width_element-1 -: width_element])* 
					    $signed(matrix_column[(j+1'b1)*width_element-1 -: width_element]);
		else
			assign outwire[j] = outwire[2*( j - vector_size)] + outwire[ 1 + 2*( j - vector_size)];
	 end       
	 endgenerate            
	          
	 
	 assign out = outwire[2*vector_size - 2];//putting the output on the output port
	    
         
	      
endmodule  

     
	 

    

