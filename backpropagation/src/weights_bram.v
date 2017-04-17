module weights_bram #(
    parameter DATA_WIDTH = 32, 
              ADDR_WIDTH = 8, 
              INIT_FILE="weights.list"
) (
	input clk,
    input rst,
    // read addr
    input [ADDR_WIDTH-1:0]  read_addr,
    input                   read_addr_valid,
    output                  read_addr_ready,
    // read data
   	output [DATA_WIDTH-1:0] read_data,
    output                  read_data_valid,
    input                   read_data_ready,
    // write addr
    input [ADDR_WIDTH-1:0]  write_addr,
    input                   write_addr_valid,
    output                  write_addr_ready,
    // write data
    input [DATA_WIDTH-1:0]  write_data,
    input                   write_data_valid,
    output                  write_data_ready
);

    wire [DATA_WIDTH-1:0] read_data_wire;
    reg [ADDR_WIDTH-1:0] read_addr_buffer, write_addr_buffer;
    reg [DATA_WIDTH-1:0] read_data_buffer, write_data_buffer;

    reg read_addr_set, read_data_set, write_addr_set, write_data_set, read_data_valid_buffer;

    BRAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INIT_FILE(INIT_FILE)
    ) bram (
        .clock       (clk                             ),
        // read
        .readEnable  (read_addr_set                   ),
        .readAddress (read_addr_buffer                ),
        .readData    (read_data_wire                  ),
        // write
        .writeEnable (write_addr_set && write_data_set),
        .writeAddress(write_addr_buffer               ),
        .writeData   (write_data_buffer               )
    );
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Read State Machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    localparam IDLE=0, DONE=1;
    reg rstate;

    always @ (posedge clk) begin
        if (rst) begin
            rstate                 <= IDLE;
            read_data_buffer       <= 0;
            read_addr_buffer       <= 0;
            read_addr_set          <= 0;
            read_data_valid_buffer <= 0;
        end
        else begin
            case (rstate)
                IDLE: begin
                    rstate                 <= (read_addr_set && updated         ) ? DONE     : IDLE;
                    read_data_buffer       <= 0;
                    read_data_set          <= 0;
                    read_addr_buffer       <= (!read_addr_set && read_addr_valid) ? read_addr : read_addr_buffer;
                    read_addr_set          <= (!read_addr_set && read_addr_valid) ? 1         : read_addr_set;
                    read_data_valid_buffer <= 0;
                end
                DONE: begin
                    rstate                 <= read_data_ready ? IDLE             : DONE;
                    read_data_buffer       <= read_data_set   ? read_data_buffer : read_data_wire; // load from bram on entering state
                    read_data_set          <= 1; // set high to prevent further reading to buffer
                    read_addr_buffer       <= 0;
                    read_addr_set          <= read_data_ready ? 0                : read_addr_set; // leave high until leaving state, in order not to consume addresses
                    read_data_valid_buffer <= 1;
                end
            endcase
        end
    end
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Write State Machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    reg wstate;

    always @ (posedge clk) begin
        if (rst) begin
            wstate            <= IDLE;
            write_data_buffer <= 0;
            write_data_set    <= 0;
            write_addr_buffer <= 0;
            write_addr_set    <= 0;
        end
        else begin
            case (wstate)
                IDLE: begin
                    wstate <= (write_addr_set && write_data_set)               ? DONE       : IDLE;
                    write_data_buffer <= (!write_data_set && write_data_valid) ? write_data : write_data_buffer;
                    write_data_set    <= (!write_data_set && write_data_valid) ? 1          : write_data_set;
                    write_addr_buffer <= (!write_addr_set && write_addr_valid) ? write_addr : write_addr_buffer;
                    write_addr_set    <= (!write_addr_set && write_addr_valid) ? 1          : write_addr_set;
                end
                DONE: begin
                    wstate <= IDLE; // nothing to wait for
                    write_data_buffer <= 0;
                    write_data_set    <= 0;
                    write_addr_buffer <= 0;
                    write_addr_set    <= 0;
                end
            endcase
        end
    end
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Updated state machine
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    reg updated;

    always @ (posedge clk) begin
        if (rst) 
            updated <= 1;
        else 
            if (!updated)
                updated <= (write_addr_set && write_data_set) ? 1 : 0;
            else 
                updated <= (rstate == DONE && read_data_ready) ? 0 : 1;
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    assign read_data = read_data_buffer;
    assign read_addr_ready = !read_addr_set;
    assign read_data_valid = read_data_valid_buffer;
    assign write_addr_ready = !write_addr_set;
    assign write_data_ready = !write_data_set;

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
