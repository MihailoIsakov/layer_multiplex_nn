`timescale 1s / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        ASCS LAB- BOSTON UNIVERSITY
// Engineer:       G Sivaperumal
// 
// Create Date:    16:07:30 01/17/2017 
// Design Name: 
// Module Name:    MVM_top 
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
//This module assumes that the matrix is transposed before this module
//////////////////////////////////////////////////////////////////////////////////
module MVM_top(vector,matrix,out);

parameter                vector_size    = 3,//size of the vector
			 matrix_columns = 3,//number of columns in the matrix
			 width_element  = 5;//width of each element 
			 
input [ vector_size * width_element -1 :0] vector;//input_vector
input [vector_size *matrix_columns*width_element-1:0] matrix;//input_matrix as one huge vector


output [(2*width_element + vector_size)*matrix_columns-1:0] out;//output of MVM

wire [2*width_element + vector_size-1:0] out_wire[matrix_columns-1 :0];
wire [width_element * vector_size-1:0] matrix_wire[matrix_columns-1 :0];//each row grouped into wire(remember that the matrix is transposed)
wire [(2*width_element + vector_size)*matrix_columns-1:0] out_group;// Group all the outputs from the MVM_element module

genvar i;
generate
for ( i = 0; i < matrix_columns ; i = i + 1)
begin: MAT_COLUM_X_VECTOR
	assign matrix_wire[i] = matrix[(i+1)*vector_size*width_element -1 -: vector_size*width_element];//grouping elements of each row into a wire
	MVM_element E( vector, matrix_wire[i],out_wire[i]); //instantiating the MVM_element module
	assign out_group[(i+1)*(2*width_element + vector_size)-1:i*(2*width_element + vector_size)] = out_wire[i];//Group all the outputs from the MVM_element module
end
endgenerate    
    
assign out = out_group;//putting the grouped output on the output port
			
endmodule
