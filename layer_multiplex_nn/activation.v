module activation(
    input clk,
    input rst,
    input [lut_addr_size*max_neurons-1:0] addr,
    input [max_neurons-1:0] valid_addr,
    input [$clog2(max_neurons):0] neuron_count,
    output reg [lut_width*max_neurons-1:0] activations,
    output reg [max_neurons-1:0] activations_valid
);

    `include "params.vh"

    reg [$clog2(max_neurons)-1:0] lut_pos;
    wire [lut_width-1:0] lut_out;

    param_rom 
    #(
        .width(lut_width),
        .depth(lut_depth),
        .init_file(lut_init)
    ) lut (
        .enable(1),
        .addr(addr[lut_pos*lut_addr_size+:lut_addr_size]),
        .data(lut_out)
    );

    always @ (posedge clk) begin
        if (rst) begin
            lut_pos = 0;
            activations  = 0;
            activations_valid = 0;
        end 
        else begin
            // if the input addresss is valid, but not processed yet
            if (valid_addr[lut_pos] && ~activations_valid[lut_pos]) begin
                activations[lut_pos*lut_width+:lut_width] <= lut_out;
                activations_valid[lut_pos] <= 1;

            end
            lut_pos <= (lut_pos < neuron_count) ? lut_pos + 1 : 0;
        end
    end

endmodule

