 
(* ram_style = "block" *)
module BRAM #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 8, INIT_FILE="") (
		clock,
    	readEnable,
    	readAddress,
   		readData,
    	writeEnable,
    	writeAddress,
    	writeData
); 

    localparam MEM_DEPTH = 1 << ADDR_WIDTH;

    input clock; 
    input readEnable;
    input [ADDR_WIDTH-1:0]   readAddress;
    output [DATA_WIDTH-1:0]  readData;
    input writeEnable;
    input [ADDR_WIDTH-1:0]   writeAddress;
    input [DATA_WIDTH-1:0]   writeData;
     
    reg [DATA_WIDTH-1:0]     readData;
    reg [DATA_WIDTH-1:0]     ram [0:MEM_DEPTH-1];
 
	//--------------Code Starts Here------------------ 
    always@(posedge clock) begin : RAM_READ
            readData <= (readEnable & writeEnable & (readAddress == writeAddress))? 
						writeData : readEnable? ram[readAddress] : 0;
    end

    always@(posedge clock) begin : RAM_WRITE
        if(writeEnable)
            ram[writeAddress] <= writeData;
    end
    
    initial begin
        $readmemb(INIT_FILE, ram);
    end

    /*  
    always @ (posedge clock) begin 
        if(readEnable | writeEnable) begin 
              $display ("-------------------------------BRAM-------------------------------------------");  
              $display ("Read [%b]\t\t\tWrite [%b]", readEnable, writeEnable);
              $display ("Read Address [%h] \t\t Write Address [%h]", readAddress, writeAddress); 
              $display ("Read Data [%h]", readData);
              $display ("Write Data [%h]",writeData);
              $display ("-----------------------------------------------------------------------------");
        end 
     end  
     //*/
endmodule

