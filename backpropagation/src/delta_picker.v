/** 
  * Fifo_mux_valid assumes that only one or zero of the two valid signals are active at a single time.
  * It then connects the valid one to the output.
  *
  */

module delta_picker #(
    parameter DELTA_WIDTH      = 32,
              LAYER_ADDR_WIDTH = 2,
              LAYER_MAX        = 3
) (
    input clk,
    input rst,
    // layer 
    input [LAYER_ADDR_WIDTH-1:0] layer,
    input                        layer_valid,
    output                       layer_ready,
    
    // a
    input [DELTA_WIDTH-1:0]      fetcher,
    input                        fetcher_valid,
    output                       fetcher_ready,
    // b
    input [DELTA_WIDTH-1:0]      propagator,
    input                        propagator_valid,
    output                       propagator_ready,
    // output
    output [DELTA_WIDTH-1:0]     result,
    output                       result_valid,
    input                        result_ready
);

    reg [LAYER_ADDR_WIDTH-1:0] layer_buffer;
    reg layer_set;

    reg [DELTA_WIDTH-1:0] fetcher_buffer, propagator_buffer;
    reg fetcher_set, propagator_set;

    localparam IDLE=0, DONE=1;
    reg state;

    always @ (posedge clk) begin
        if (rst) begin
            state             <= IDLE;
            layer_buffer      <= 0;
            layer_set         <= 0;
            fetcher_buffer    <= 0;
            fetcher_set       <= 0;
            propagator_buffer <= 0;
            propagator_set    <= 0;
        end
        else begin
            case (state) 
                IDLE: begin
                    state             <= (layer_set && (((layer_buffer == LAYER_MAX) && fetcher_set) || ((layer_buffer != LAYER_MAX) && propagator_set))) ? DONE : IDLE;
                    layer_buffer      <= (!layer_set && layer_valid) ? layer : layer_buffer;
                    layer_set         <= (!layer_set && layer_valid) ? 1     : layer_set;
                    fetcher_buffer    <= (!fetcher_set && fetcher_valid) ? fetcher : fetcher_buffer;
                    fetcher_set       <= (!fetcher_set && fetcher_valid) ? 1       : fetcher_set;
                    propagator_buffer <= (!propagator_set && propagator_valid) ? propagator : propagator_buffer;
                    propagator_set    <= (!propagator_set && propagator_valid) ? 1          : propagator_set;
                end
                DONE: begin
                    if (layer_buffer == LAYER_MAX) begin
                        state             <= result_ready ? IDLE : DONE;
                        layer_buffer      <= layer_buffer;
                        layer_set         <= result_ready ? 0    : layer_set;
                        fetcher_buffer    <= fetcher_buffer;
                        fetcher_set       <= result_ready ? 0    : fetcher_set;
                        propagator_buffer <= propagator_buffer;
                        propagator_set    <= propagator_set;
                    end
                    else begin
                        state             <= result_ready ? IDLE : DONE;
                        layer_buffer      <= layer_buffer;
                        layer_set         <= result_ready ? 0 : layer_set;
                        fetcher_buffer    <= fetcher_buffer;
                        fetcher_set       <= fetcher_set;
                        propagator_buffer <= propagator_buffer;
                        propagator_set    <= result_ready ? 0 : propagator_set;
                    end
                end
            endcase
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Outputs
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    assign layer_ready = !layer_set;
    assign fetcher_ready = !fetcher_set;
    assign propagator_ready = !propagator_set;
    assign result = (layer_set) ? (layer_buffer == LAYER_MAX) ? fetcher_buffer : propagator_buffer : 0;
    assign result_valid = (layer_set && state == DONE) ? (layer_buffer == LAYER_MAX) ? fetcher_set : propagator_set : 0;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Testing
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    integer i;    

    // FIXME has to be set manually
    localparam VECTOR_LEN = 4, DELTA_CELL_WIDTH=10;
    
    //always @ (posedge result_valid) begin
        //$write("DELTA - time: %d, pick: %d: ", $stime, layer_buffer == LAYER_MAX);
        //for (i=0; i<VECTOR_LEN; i=i+1) begin
            //$write("%d, ", result[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH]);
        //end
        //$write("\n");
    //end

endmodule

