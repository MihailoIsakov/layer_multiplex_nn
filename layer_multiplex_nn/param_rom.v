module param_rom
#(
    parameter width = 8,
    parameter depth = 1024,
    parameter init_file = ""
)
(
    input enable,
    input [$clog2(depth)-1:0] addr,
    output [width-1:0] data
);
    
    reg [width-1:0] mem [0:depth-1];

    assign data = (enable) ? mem[addr] : 0;

    initial begin
        $readmemb(init_file, mem);
    end

endmodule
