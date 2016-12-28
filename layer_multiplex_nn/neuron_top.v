`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:36:51 12/26/2016 
// Design Name: 
// Module Name:    neuron_top 
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
module neuron_top
(
    input clk,
    input rst,
    input start,
    // the number of neurons in the previous layer. Even though each neuron has 
    // max_neurons connections, we don't want to spend time on all of them.
    input [$clog2(max_neurons)-1:0] input_signals,
    // max_neurons connections and weights, accomodating the worst case scenario
    input [max_neurons*weight_size-1:0] weights,
    input [max_neurons*input_size-1 :0] inputs,
    output [lut_addr_size-1:0] addr,
    output lut_valid
);

    `include "params.vh"

    // rewire the large vector into a wire memory
    wire signed [weight_size-1:0] weights_mem [max_neurons-1:0];
    wire signed [input_size-1:0]  inputs_mem  [max_neurons-1:0];
    genvar i;
    generate
    for (i=0; i<max_neurons; i=i+1) begin : MEMS
        assign weights_mem[i] = weights[weight_size*i+:weight_size];
        assign inputs_mem[i]  = inputs[input_size*i+:input_size];
    end
    endgenerate
    //
    
    // sum of weights * inputs
    reg signed [sum_size-1:0] sum;

    // LUT address function
    wire [9:0] logsig_addr;
    // takes the 3 bits above the radix, and 7 bits below the radix 
    assign logsig_addr = ((sum >>> (weight_fraction_size + input_fraction_size - 7)) + 512);
   
    // if the sum is larger than 8 or smaller than -8,  set address manually to 255/0
    assign addr = (sum > ( 8<<<(weight_fraction_size + input_fraction_size)))  ? 1023
                : (sum < (-8<<<(weight_fraction_size + input_fraction_size))) ? 0
                : logsig_addr[9:0];

    // the next input to be processed
    reg [$clog2(input_size)-1:0] counter;
    assign lut_valid = counter == input_signals;

    always @ (posedge clk) begin
        if (rst) begin
            counter <= 0;
            sum <= 0;
        end

        else if (start) begin
            if (counter < input_signals) begin // multiplying weights and values
                sum <= sum + inputs_mem[counter] * weights_mem[counter];
                counter <= counter + 1;
            end 
            else begin // sending the data to the LUT
                sum <= 0;
                counter <= 0;
            end
        end
    end


endmodule
