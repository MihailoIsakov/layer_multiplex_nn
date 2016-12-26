`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: sivaperumal
// 
// Create Date:    14:43:25 12/22/2016 
// Design Name: 
// Module Name:    multiplier 
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
//
//////////////////////////////////////////////////////////////////////////////////
module multiplier(
		  input_a,	//input a
		  input_a_stb,	//input a valid signal
        input_b,	// input b
		  input_b_stb,	//input a valid signal	
		  output_z,	//output z
	     output_z_stb,	//output z valid signal
        clk,	//input clk
        rst 	//input reset
		  );

  input     clk;
  input     rst;
  input 		[7:0]input_a;
  input 		[7:0]input_b;
  output 	[7:0]output_z;
  input     input_a_stb;
  input     input_b_stb;
  output    output_z_stb;
  reg       [3:0] state;//States of FSM
  reg       s_output_z_stb;
  reg       [7:0] s_output_z;
  reg 		[11:0] product;
  
// State values  
  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            normalise_a   = 4'd4,
            normalise_b   = 4'd5,
            multiply_0    = 4'd6,
            multiply_1    = 4'd7,
            normalise_1   = 4'd8,
            normalise_2   = 4'd9,
            round         = 4'd10,
            pack          = 4'd11,
            put_z         = 4'd12;
				
  reg       [7:0] a, b, z;
  reg       [4:0] a_m, b_m, z_m;
  reg       [4:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  
  always@(posedge clk)
  begin
  
  case(state)
  
  get_a:
  begin
  if(input_a_stb)
  begin
	a <= input_a;
	state <= get_b;
  end
  end
	
 get_b:
 begin
 if(input_b_stb)
 begin
  b <= input_b;
  state <= unpack;
 end
 end
 
 unpack:
 begin
 a_m <= a[3: 0];//mantissa
 b_m <= b[3 : 0];
 a_e <= a[6: 4] - 3; //exponential - bias
 b_e <= b[6 : 4] - 3;
 a_s <= a[7];//sign bit
 b_s <= b[7];
 state <= special_cases;
 end
 
 special_cases:
 begin //1
 //if a is NaN or b is NaN return NaN 
 if ((a_e == 7 && a_m != 0) || (b_e == 7 && b_m != 0))
	begin//2
    z[7] <= 1;//sign bit
    z[6:4] <= 7;// all ones in exponent
    z[3] <= 1;
    z[2:0] <= 0;
	 state <= put_z;
	end//2
 else 
 if (a_e == 7)
	begin//3
    z[7] <= a_s ^ b_s;
    z[6:4] <= 7;
    z[3:0] <= 0;
    state <= put_z;
 end//3
  else
  if (b_e == 7)
  begin//5
    z[7] <= a_s ^ b_s;
    z[6:4] <= 7;
    z[3:0] <= 0;
    state <= put_z;
       
   end//5
else if (a_e[2:0] == 0) && (a_m == 0)) begin//6
          z[7] <= a_s ^ b_s;
          z[6:4] <= 0;
          z[2:0] <= 0;
          state <= put_z;
     
        end//6
		  
else if ((b_e[2:0] == 0) && (b_m == 0)) begin//7
          z[7] <= a_s ^ b_s;
          z[6:4] <= 0;
          z[2:0] <= 0;
          state <= put_z;
     
        end 
		
    multiply_0:
      begin
        z_s <= a_s ^ b_s;
        z_e <= a_e + b_e;
        product <= a_m * b_m * 4;
        state <= multiply_1;
      end
		
     multiply_1:
      begin
        z_m <= product[11:7];
        guard <= product[6];
        round_bit <= product[5];
        sticky <= (product[2:0] != 0);
        state <= normalise_1;
      end
		
		
      normalise_1:
      begin
        if (z_m[4] == 0) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end
		
      normalise_2:
      begin
        if ($signed(z_e) < -2) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end 
		  else begin
          state <= round;
			       end
		end
      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 4'b1111) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end
		
		pack:
      begin
        z[3 : 0] <= z_m[3:0];
        z[6 : 4] <= z_e[3:0] + 3;
        z[7] <= z_s;
        if ($signed(z_e) == -2 && z_m[4] == 0) begin
          z[6 : 4] <= 0;
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 7) begin
          z[3 : 0] <= 0;
          z[6 : 4] <= 7;
          z[7] <= z_s;
        end
        state <= put_z;
      end
		
      put_z:
      begin
        s_output_z_stb <= 1;
        s_output_z <= z;
        if (s_output_z_stb ) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end
 endcase 
 if (rst == 1) begin
      state <= get_a;
      s_output_z_stb <= 0;
    end

  end
  assign output_z_stb = s_output_z_stb;
  assign output_z = s_output_z;
 




endmodule
