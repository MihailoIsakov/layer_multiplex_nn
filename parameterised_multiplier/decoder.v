
module decoder(
		  input_a,	//input a
        input_b,	// input b
		  input_valid,
		  output_z,	//output z
	     output_valid,	//output z valid signal  
        clk,	//input clk
        rst 	//input reset
		  );
		  
//enter the parameters here		  
  parameter n = 32;
  parameter fraction = 23;
  
  
  
  parameter exponent = 8;
  input     clk;
  input     rst;
  input 		[n-1:0]input_a;
  input 		[n-1:0]input_b;
  output 	[n-1:0]output_z;
  input     input_valid;
  output    output_valid;   
  reg       [3:0] state;//States of FSM
  reg       s_output_valid;
  reg       [n-1:0] s_output_z;
  reg       flag;

  
// State values  
  parameter 
				get_input = 4'd1,
            special_cases = 4'd2,
            multiply_0    = 4'd3,
            multiply_1    = 4'd4,
            normalise_1   = 4'd5,
            round         = 4'd6,
            pack          = 4'd7,
            put_z         = 4'd8;
				
  reg       [(exponent+1):0] temp_ze;   
  reg        [n-1:0]  z;
  reg       [(fraction):0] a_m, b_m, z_m;
  reg       [(exponent+1):0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [(fraction+1)*2 + 1:0] product;
  
  always@(posedge clk)
  begin
  
  case(state)
//#########################################################################################################//	
	get_input:
	begin
	if(input_valid)
	begin
	{a_s, a_e, a_m[fraction-1:0]} <= {input_a[n-1],input_a[n-2:fraction] - {3'b000,{exponent-1{1'b1}}},input_a[fraction-1:0]};
	{b_s, b_e, b_m[fraction-1:0]} <= {input_b[n-1],input_b[n-2:fraction] - {3'b000,{exponent-1{1'b1}}},input_b[fraction-1:0]};
	a_m[fraction] = 0;
	b_m[fraction] = 0;
	flag = 0;
	state <= special_cases;
	end   
	end
//#########################################################################################################//	
	special_cases:
	begin
	
	 //if a is NaN or b is NaN return NaN 
 if ((a_e == {1'b1,{(exponent-1){1'b0}}} && a_m != 0) || b_e =={1'b1,{(exponent-1){1'b0}}} && b_m != 0)
 // all ones in the exponent of a or b and not all zeros in the mantissa of a or b
	begin
    z[n-1] <= 1;//sign bit
    z[fraction+exponent-1:fraction] <= {exponent{1'b1}};// all ones in exponent
    z[fraction-1] <= 1;
    z[(fraction-2): 0] <= 0;
	 state <= put_z;
	end

else
	 if ($signed(a_e) == -{exponent-1{1'b1}} && a_m == 0)
 // if the exponents bits in a and the mantissa in a is zero return zero
 begin
    z[n-1] <= a_s ^ b_s;
    z[fraction+exponent-1:fraction] <= 0;
    z[(fraction-1) : 0] <= 0;
    state <= put_z;   
 end
		  
else
 if      
($signed(b_e == -{exponent{1'b1}}) && b_m == 0)
// if the exponents bits in b and the mantissa in a is zero return zero 
begin

    z[n-1] <= a_s ^ b_s;
    z[fraction+exponent-1:fraction] <= 0;
    z[(fraction-1) : 0] <= 0;
    state <= put_z;   
end 
	
else	

begin
    a_m[fraction] <= 1'b1;
	 b_m[fraction] <= 1'b1;
    state <= multiply_0; 
end
end
//#########################################################################################################//
multiply_0:
 begin
    z_s <= a_s ^ b_s;
    z_e <= a_e + b_e + 1;
	
    product <= a_m * b_m * 4;
    state <= multiply_1;
 end
 
//#########################################################################################################//
multiply_1:
 begin
    z_m <= product[(fraction+1)*2 + 1:(fraction+1)*2 + 1-fraction];
    guard <= product[(fraction+1)*2 -fraction ];
    round_bit <= product[(fraction+1)*2 -fraction - 1];
    sticky <= (product[(fraction+1)*2 -fraction - 2:0] != 0);
    state <= normalise_1;
 end
		
//#########################################################################################################//
//normalise the number 
normalise_1:
 begin
  if (z_m[(fraction)] == 0) begin       
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
 //rounding the number
round:
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
 //putting the number into the output format
pack:
 begin
  z[fraction-1:0] <= z_m[fraction-1:0];
  temp_ze <= $signed(z_e) + $signed({1'b0,{(exponent-1){1'b1}}});
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
//putting it on the output port 
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

















