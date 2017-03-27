module bram_wrapper #(
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
    )bram (
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
                    rstate                 <= (read_addr_set                    ) ? DONE     : IDLE;
                    read_data_buffer       <= 0;
                    read_data_set          <= 0;
                    read_addr_buffer       <= (!read_addr_set && read_addr_valid) ? read_addr : read_addr_buffer;
                    read_addr_set          <= (!read_addr_set && read_addr_valid) ? 1         : read_addr_set;
                    read_data_valid_buffer <= 0;
                end
                DONE: begin
                    rstate                 <= read_data_ready ? IDLE : DONE;
                    read_data_buffer       <= read_data_set ? read_data_buffer : read_data_wire;
                    read_data_set          <= 1;
                    read_addr_buffer       <= 0;
                    read_addr_set          <= read_data_ready ? 0     : read_addr_set;
                    read_data_valid_buffer <= read_data_ready ? 0     : 1;
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
    // Outputs
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    assign read_data = read_data_buffer;
    assign read_addr_ready = !read_addr_set;
    assign read_data_valid = read_data_valid_buffer;
    assign write_addr_ready = !write_addr_set;
    assign write_data_ready = !write_data_set;

endmodule
