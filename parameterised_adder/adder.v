`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:       sivaperumal
// 
// Create Date:    13:49:40 12/29/2016 
// Design Name:    
// Module Name:    adder 
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
//thanks to JON DAWSON
//https://github.com/dawsonjon/fpu
//////////////////////////////////////////////////////////////////////////////////

module adder(
        input_a,//first input
        input_b,//second input
        input_valid,
        clk,
        rst,
        output_z,//output
        output_valid//output valid
       );

  input     clk;
  input     rst;
  //enter the parameters here
  parameter n = 32,
	    exponent = 8,
	    fraction = 23;

  input     [n-1:0] input_a;
  input     [n-1:0] input_b;
  input     input_valid;   
  
  

  output    [n-1:0] output_z;
  output    output_valid;


  reg       s_output_valid;
  reg       [n-1:0] s_output_z;


  reg       [3:0] state;
  
  parameter get_input     = 4'd0,
            special_cases = 4'd1,
            align         = 4'd2,
            add_0         = 4'd3,
            add_1         = 4'd4,
            normalise_1   = 4'd5,
            round         = 4'd6,
            pack          = 4'd7,   
            put_z         = 4'd8;

  reg       [n-1:0]z;
  reg       [fraction+3:0] a_m, b_m;
  reg       [fraction:0] z_m;
  reg       [exponent+1:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [fraction+4:0] sum;
  reg       flag;

  
 
  
  always @(posedge clk)
  begin

  case(state)
 //#########################################################################################################//
 //seperate both the numbers into mantissa,exponent and sign bits
 get_input:
  begin
   if(input_valid)
    begin
	a_m <= {input_a[(fraction-1): 0], 3'd0};//mantissa
 	b_m <= {input_b[(fraction-1) : 0], 3'd0};

	a_e <= input_a[fraction+exponent-1:fraction] - {(exponent-1){1'b1}}; //exponential - bias
 	b_e <= input_b[fraction+exponent-1:fraction] - {(exponent-1){1'b1}};
	    
 	a_s <= input_a[n-1];//sign bit
 	b_s <= input_b[n-1];
 
 state <= special_cases;
end 
end	
 //#########################################################################################################//
//consider the special cases that can affect the output 
special_cases:
 begin //1
 //if a is NaN or b is NaN return NaN 
 if ((a_e == {1'b1,{(exponent-1){1'b0}}} && a_m != 0) || b_e =={1'b1,{(exponent-1){1'b0}}} && b_m != 0)
 //all ones in exponent and not all 0s in mantissa would activate this
	begin
    z[n-1] <= 1;
    z[fraction+exponent-1:fraction] <= {exponent{1'b1}};
    z[fraction-1] <= 1;
    z[(fraction-2): 0] <= 0;
	 state <= put_z;   
	end
	
 //if a is infinity result is infinity
 else if (a_e == {1'b1,{(exponent-1){1'b0}}})
 //all ones in exponent and  all 0s in mantissa in a would activate this
 begin
  z[n-1] <= a_s;
  z[fraction+exponent-1:fraction] <= {exponent{1'b1}};
  z[fraction-1:0] <= 0;
  state <= put_z;
 end 
 
 //if b is infinity result is infinity	
 else if (b_e == {1'b1,{(exponent-1){1'b0}}})
 //all ones in exponent and  all 0s in mantissa in b would activate this
 begin
  z[n-1] <= a_s;
  z[fraction+exponent-1:fraction] <= {exponent{1'b1}};
  z[fraction-1:0] <= 0;
  state <= put_z;  
 end 
 
  //if a and b are zero return 0 
  else if ((($signed(a_e) == -{exponent-1{1'b1}}) && (a_m == 0)) && (($signed(b_e) == -{exponent-1{1'b1}}) && (b_m == 0)))
//all zeros in a and b would activate this  
  begin
          z[n-1] <= a_s & b_s;
          z[fraction+exponent-1:fraction] <= 0;
          z[fraction-1:0] <= 0;
          state <= put_z;
  end 
  //if a is zero return b 
  else if (($signed(a_e) == -{exponent-1{1'b1}}) && (a_m == 0)) 
  //all zeros in a would return b
  begin
          z[n-1] <= b_s;
          z[fraction+exponent-1:fraction] <= b_e[exponent-1:0] + {exponent-1{1'b1}};
          z[fraction-1:0] <= b_m[fraction+3:3];
          state <= put_z;
  end 
  
  //if b is zero return a 
  else if (($signed(b_e) == -{exponent-1{1'b1}}) && (b_m == 0))
  //all zeros in a would return b
  begin
          z[n-1] <= a_s;
          z[fraction+exponent-1:fraction] <= a_e[exponent-1:0] + {exponent-1{1'b1}};
          z[fraction-1:0] <= a_m[fraction+3:3];
          state <= put_z;
  end
  
  else   
			 a_m[fraction+3] <= 1;
			 b_m[fraction+3] <= 1;
			 state <= align;
  end
 //#########################################################################################################//
  //make the exponents of the two numbers same by increasing the power of the smaller number to match the power of the bigger number
align:
 begin
   if ($signed(a_e) > $signed(b_e)) begin
     b_e <= b_e + 1;
     b_m <= b_m >> 1;
     b_m[0] <= b_m[0] | b_m[1];
   end else if ($signed(a_e) < $signed(b_e)) begin
     a_e <= a_e + 1;
     a_m <= a_m >> 1;
     a_m[0] <= a_m[0] | a_m[1];
   end else begin
     state <= add_0;
   end
 end
 //#########################################################################################################//
  // Add the mantissa depending upon the sign bit 
add_0:
 begin
   z_e <= a_e;
   if (a_s == b_s) begin
     sum <= {1'd0, a_m} + b_m;
     z_s <= a_s;
   end else begin
     if (a_m > b_m) begin
       sum <= {1'd0, a_m} - b_m;
       z_s <= a_s;
     end else begin
       sum <= {1'd0, b_m} - a_m;
       z_s <= b_s;
     end
   end
   state <= add_1;
 end
//#########################################################################################################//
  //calculate the mantissa
add_1:
 begin
   if (sum[fraction+4]) begin
     z_m <= sum[fraction+4:4];
     guard <= sum[3];
     round_bit <= sum[2];
     sticky <= sum[1] | sum[0];
     z_e <= z_e + 1;
   end else begin
     z_m <= sum[fraction+3:3];
     guard <= sum[2];
     round_bit <= sum[1];
     sticky <= sum[0];
   end
   state <= normalise_1;
 end
//#########################################################################################################//
normalise_1:
  //normalise the number 
 begin
   if (z_m[fraction] == 0) begin
     z_e <= z_e - 1;
     z_m <= z_m << 1;
     z_m[0] <= guard;
     guard <= round_bit;
     round_bit <= 0;
   end else begin
     state <= round;
   end
 end
//#########################################################################################################//
round:
//round the number
 begin
   if (guard && (round_bit | sticky | z_m[0])) begin
     z_m <= z_m + 1;
     if (z_m == {(fraction+1){1'b1}}) begin
       z_e <=z_e + 1;
     end
   end
   state <= pack;    
 end
//#########################################################################################################//
//get the result in the output format  
pack:
 begin
  z[fraction-1:0] <= z_m[fraction-1:0];
  z[fraction+exponent-1:fraction] <= $signed(z_e) + $signed({1'b0,{(exponent-1){1'b1}}});
  z[n-1] <= z_s;
  if ($signed(z_e) < $signed({1'b1,{exponent-3{1'b0}},1'b1})) begin
	 flag <= 1;
    z[fraction+exponent-1:fraction] <= 0;   
  end
 //if overflow occurs, return inf
 if ($signed(z_e)> $signed({1'b0,{(exponent-1){1'b1}}})) begin
   z[fraction-1:0] <= 0;
   z[fraction+exponent-1:fraction] <= {(exponent){1'b1}};
   z[n-1] <= z_s;
 end
  state <= put_z;
 end   
//#########################################################################################################//
 //put the output on the output port	 
put_z:
 begin
   s_output_valid <= 1;
   s_output_z <= z;
   if (s_output_valid ) begin
     s_output_valid <= 0;
     state <= get_input;
   end
 end
 endcase 
 
 if (rst == 1) 
 begin
      state <= get_input;
      s_output_valid <= 0;
		flag <= 0;
 end

 end
  assign output_valid = s_output_valid;
  assign output_z = s_output_z;
 endmodule



