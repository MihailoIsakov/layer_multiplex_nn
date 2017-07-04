// For a LAYER_MAX number of layers, there are LAYER_MAX weight matrices, and LAYER_MAX+1 activations, including inputs
// and outputs. These LAYER_MAX+1 activations need to be saved in the stack and read afterwards. 
//
// The forward module and the input module start writing from 0, with the first value (the input activations) coming 
// from the input module, and the rest LAYER_MAX activations coming from the forward module.
//
// The activations are read in pairs, so that for an address addr, we read activations addr and addr+1
// Therefore the activations should be written with address in the [0, LAYER_MAX] range, and read with the address in
// the [0, LAYER_MAX-1] range.

module activation_stack 
#(
    parameter NEURON_NUM       = 6, 
              ACTIVATION_WIDTH = 8,
              STACK_ADDR_WIDTH = 10
)
(
    input clk, 
    input rst,
    // one write port - data
    input  [STACK_WIDTH-1:0]      input_data,
    input                         input_data_valid,
    output                        input_data_ready,
    // one write port - addr
    input  [STACK_ADDR_WIDTH-1:0] input_addr,
    input                         input_addr_valid,
    output                        input_addr_ready,
    // two read ports - addr
    input  [STACK_ADDR_WIDTH-1:0] output_addr,
    input                         output_addr_valid,
    output                        output_addr_ready,
    // first read port
    output [STACK_WIDTH-1:0]      output_data_lower,
    output                        output_data_lower_valid,
    input                         output_data_lower_ready,
    // second read port 
    output [STACK_WIDTH-1:0]      output_data_higher,
    output                        output_data_higher_valid,
    input                         output_data_higher_ready
);

    localparam STACK_WIDTH = NEURON_NUM*ACTIVATION_WIDTH; 

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Datapath
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    reg [STACK_ADDR_WIDTH-1:0] read_addr_buffer;
    localparam IDLE=0, CALC=1, DONE=2;
    reg [1:0] read_state;
    
    two_port_BRAM #(
        .DATA_WIDTH(STACK_WIDTH     ),
        .ADDR_WIDTH(STACK_ADDR_WIDTH),
        .INIT_FILE (""              )
    ) bram (
        .clock        (clk                                     ),
        .readEnable0  (read_state == CALC || read_state == DONE),
        .readAddress0 (read_addr_buffer                        ),
        .readData0    (output_data_lower                       ),
        .readEnable1  (read_state == CALC || read_state == DONE),
        .readAddress1 (read_addr_buffer + 1                    ),
        .readData1    (output_data_higher                      ),
        .writeEnable0 (input_data_valid && input_addr_valid    ),
        .writeAddress0(input_addr                              ),
        .writeData0   (input_data                              ),
        .writeEnable1 (0                                       ),
        .writeAddress1(0                                       ),
        .writeData1   (0                                       )
    ); 
    

    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    // Read state machine
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    reg read_addr_set, output_0_set, output_1_set;


    always @ (posedge clk) begin
        if (rst) begin
            read_state       <= IDLE;
            read_addr_buffer <= 0;
            read_addr_set    <= 0;
            output_0_set     <= 0;
            output_1_set     <= 0;
        end
        else begin
            case (read_state)
                IDLE: begin
                    read_state       <= output_addr_valid ? CALC        : IDLE;
                    read_addr_buffer <= output_addr_valid ? output_addr : 0;
                    read_addr_set    <= output_addr_valid ? 1           : 0;
                    output_0_set     <= 0;
                    output_1_set     <= 0;
                end  
                CALC: begin
                    read_state       <= DONE;
                    read_addr_buffer <= read_addr_buffer;
                    read_addr_set    <= 1;
                    output_0_set     <= 1;
                    output_1_set     <= 1;
                end
                DONE: begin
                    read_state       <= !output_0_set && !output_1_set ? IDLE : DONE;
                    read_addr_buffer <= read_addr_buffer;
                    read_addr_set    <= !output_0_set && !output_1_set ? 0    : 1;
                    output_0_set     <= output_data_lower_ready        ? 0    : output_0_set;
                    output_1_set     <= output_data_higher_ready       ? 0    : output_1_set;
                end  
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    // write
    assign input_addr_ready = input_data_valid && input_addr_valid;
    assign input_data_ready = input_data_valid && input_addr_valid;

    // read 
    assign output_addr_ready = !read_addr_set;
    assign output_data_lower_valid = output_0_set;
    assign output_data_higher_valid = output_1_set;

endmodule
