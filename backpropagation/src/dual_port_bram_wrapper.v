module dual_port_bram_wrapper #(
    parameter DATA_WIDTH = 32, 
              ADDR_WIDTH = 8, 
              INIT_FILE="weights.list"
) (
	input clk,
    input rst,
    // read addr 0
    input [ADDR_WIDTH-1:0]  read_addr_0,
    input                   read_addr_0_valid,
    output                  read_addr_0_ready,
    // read data 0
   	output [DATA_WIDTH-1:0] read_data_0,
    output                  read_data_0_valid,
    input                   read_data_0_ready,
    // read addr 1
    input [ADDR_WIDTH-1:0]  read_addr_1,
    input                   read_addr_1_valid,
    output                  read_addr_1_ready,
    // read data 1
   	output [DATA_WIDTH-1:0] read_data_1,
    output                  read_data_1_valid,
    input                   read_data_1_ready,
    // write addr 0
    input [ADDR_WIDTH-1:0]  write_addr_0,
    input                   write_addr_0_valid,
    output                  write_addr_0_ready,
    // write data 0
    input [DATA_WIDTH-1:0]  write_data_0,
    input                   write_data_0_valid,
    output                  write_data_0_ready,
    // write addr
    input [ADDR_WIDTH-1:0]  write_addr_1,
    input                   write_addr_1_valid,
    output                  write_addr_1_ready,
    // write data
    input [DATA_WIDTH-1:0]  write_data_1,
    input                   write_data_1_valid,
    output                  write_data_1_ready
);

    wire [DATA_WIDTH-1:0] read_data_0_wire, read_data_1_wire;
    reg [ADDR_WIDTH-1:0] read_addr_0_buffer, write_addr_0_buffer, read_addr_1_buffer, write_addr_1_buffer;
    reg [DATA_WIDTH-1:0] read_data_0_buffer, write_data_0_buffer, read_data_1_buffer, write_data_1_buffer;

    reg read_addr_0_set, read_data_0_set, write_addr_0_set, write_data_0_set, read_data_0_valid_buffer;
    reg read_addr_1_set, read_data_1_set, write_addr_1_set, write_data_1_set, read_data_1_valid_buffer;

    two_port_BRAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INIT_FILE(INIT_FILE)
    ) bram (
        .clock       (clk                                  ),
        // read 0
        .readEnable0  (read_addr_0_set                     ),
        .readAddress0 (read_addr_0_buffer                  ),
        .readData0    (read_data_0_wire                    ),
        // read 1
        .readEnable1  (read_addr_1_set                     ),
        .readAddress1 (read_addr_1_buffer                  ),
        .readData1    (read_data_1_wire                    ),
        // write 0
        .writeEnable0 (write_addr_0_set && write_data_0_set),
        .writeAddress0(write_addr_0_buffer                 ),
        .writeData0   (write_data_0_buffer                 ),
        // write 1
        .writeEnable1 (write_addr_1_set && write_data_1_set),
        .writeAddress1(write_addr_1_buffer                 ),
        .writeData1   (write_data_1_buffer                 )
    );
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Read State Machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    localparam IDLE=0, DONE=1;
    reg rstate_0, rstate_1;

    always @ (posedge clk) begin
        if (rst) begin
            rstate_0                 <= IDLE;
            read_data_0_buffer       <= 0;
            read_addr_0_buffer       <= 0;
            read_addr_0_set          <= 0;
            read_data_0_valid_buffer <= 0;
        end
        else begin
            case (rstate_0)
                IDLE: begin
                    rstate_0                 <= (read_addr_0_set                    ) ? DONE     : IDLE;
                    read_data_0_buffer       <= 0;
                    read_data_0_set          <= 0;
                    read_addr_0_buffer       <= (!read_addr_0_set && read_addr_0_valid) ? read_addr_0 : read_addr_0_buffer;
                    read_addr_0_set          <= (!read_addr_0_set && read_addr_0_valid) ? 1           : read_addr_0_set;
                    read_data_0_valid_buffer <= 0;
                end
                DONE: begin
                    rstate_0                 <= read_data_0_ready ? IDLE             : DONE;
                    read_data_0_buffer       <= read_data_0_set   ? read_data_0_buffer : read_data_0_wire; // load from bram on entering state
                    read_data_0_set          <= 1; // set high to prevent further reading to buffer
                    read_addr_0_buffer       <= 0;
                    read_addr_0_set          <= read_data_0_ready ? 0                : read_addr_0_set; // leave high until leaving state, in order not to consume addresses
                    read_data_0_valid_buffer <= 1;
                end
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            rstate_1                 <= IDLE;
            read_data_1_buffer       <= 0;
            read_addr_1_buffer       <= 0;
            read_addr_1_set          <= 0;
            read_data_1_valid_buffer <= 0;
        end
        else begin
            case (rstate_1)
                IDLE: begin
                    rstate_1                 <= (read_addr_1_set                      ) ? DONE        : IDLE;
                    read_data_1_buffer       <= 0;
                    read_data_1_set          <= 0;
                    read_addr_1_buffer       <= (!read_addr_1_set && read_addr_1_valid) ? read_addr_1 : read_addr_1_buffer;
                    read_addr_1_set          <= (!read_addr_1_set && read_addr_1_valid) ? 1           : read_addr_1_set;
                    read_data_1_valid_buffer <= 0;
                end
                DONE: begin
                    rstate_1                 <= read_data_1_ready ? IDLE               : DONE;
                    read_data_1_buffer       <= read_data_1_set   ? read_data_1_buffer : read_data_1_wire; // load from bram on entering state
                    read_data_1_set          <= 1; // set high to prevent further reading to buffer
                    read_addr_1_buffer       <= 0;
                    read_addr_1_set          <= read_data_1_ready ? 0                  : read_addr_1_set; // leave high until leaving state, in order not to consume addresses
                    read_data_1_valid_buffer <= 1;
                end
            endcase
        end
    end
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Write State Machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    reg wstate_0, wstate_1;

    always @ (posedge clk) begin
        if (rst) begin
            wstate_0            <= IDLE;
            write_data_0_buffer <= 0;
            write_data_0_set    <= 0;
            write_addr_0_buffer <= 0;
            write_addr_0_set    <= 0;
        end
        else begin
            case (wstate_0)
                IDLE: begin
                    wstate_0 <= (write_addr_0_set && write_data_0_set)               ? DONE         : IDLE;
                    write_data_0_buffer <= (!write_data_0_set && write_data_0_valid) ? write_data_0 : write_data_0_buffer;
                    write_data_0_set    <= (!write_data_0_set && write_data_0_valid) ? 1            : write_data_0_set;
                    write_addr_0_buffer <= (!write_addr_0_set && write_addr_0_valid) ? write_addr_0 : write_addr_0_buffer;
                    write_addr_0_set    <= (!write_addr_0_set && write_addr_0_valid) ? 1            : write_addr_0_set;
                end
                DONE: begin
                    wstate_0 <= IDLE; // nothing to wait for
                    write_data_0_buffer <= 0;
                    write_data_0_set    <= 0;
                    write_addr_0_buffer <= 0;
                    write_addr_0_set    <= 0;
                end
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            wstate_1            <= IDLE;
            write_data_1_buffer <= 0;
            write_data_1_set    <= 0;
            write_addr_1_buffer <= 0;
            write_addr_1_set    <= 0;
        end
        else begin
            case (wstate_1)
                IDLE: begin
                    wstate_1 <= (write_addr_1_set && write_data_1_set)               ? DONE         : IDLE;
                    write_data_1_buffer <= (!write_data_1_set && write_data_1_valid) ? write_data_1 : write_data_1_buffer;
                    write_data_1_set    <= (!write_data_1_set && write_data_1_valid) ? 1            : write_data_1_set;
                    write_addr_1_buffer <= (!write_addr_1_set && write_addr_1_valid) ? write_addr_1 : write_addr_1_buffer;
                    write_addr_1_set    <= (!write_addr_1_set && write_addr_1_valid) ? 1            : write_addr_1_set;
                end
                DONE: begin
                    wstate_1 <= IDLE; // nothing to wait for
                    write_data_1_buffer <= 0;
                    write_data_1_set    <= 0;
                    write_addr_1_buffer <= 0;
                    write_addr_1_set    <= 0;
                end
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    assign read_data_0 = read_data_0_buffer;
    assign read_data_1 = read_data_1_buffer;
    assign read_addr_0_ready = !read_addr_0_set;
    assign read_addr_1_ready = !read_addr_1_set;
    assign read_data_0_valid = read_data_0_valid_buffer;
    assign read_data_1_valid = read_data_1_valid_buffer;
    assign write_addr_0_ready = !write_addr_0_set;
    assign write_addr_1_ready = !write_addr_1_set;
    assign write_data_0_ready = !write_data_0_set;
    assign write_data_1_ready = !write_data_1_set;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //always @ (posedge clk) begin
        //$display("RA r/v: %b/%b | RD r/v: %b/%b | WA r/v: %b/%b | WD r/v: %b/%b", 
            //read_addr_ready, read_addr_valid, read_data_ready, read_data_valid,
            //write_addr_ready, write_addr_valid, write_data_ready, write_data_valid);
    //end
    
    // print writes
    //always @ (posedge clk) begin
        //if (write_addr_set && write_data_set)
            //$display("write at layer %d, data: %h", write_addr_buffer, write_data_buffer);
    //end
    
    // print diffs
    //reg [16*16-1:0] buffer1, buffer2, buffer3, buffer4;
    //integer i = 0;
    //always @ (posedge clk) begin
        //if (write_data_set && write_addr_set) begin
            ////$display("%4d: %h, %h, %h, %h", i, bram.ram[0], bram.ram[1], bram.ram[2], bram.ram[3]);
            //$display("%4d: %h, %h, %h, %h", i, buffer1-bram.ram[0], buffer2-bram.ram[1], buffer3-bram.ram[2], buffer4-bram.ram[3]);
            //i = i+1;
            //buffer1 <= bram.ram[0];
            //buffer2 <= bram.ram[1];
            //buffer3 <= bram.ram[2];
            //buffer4 <= bram.ram[3];
        //end
    //end


endmodule
