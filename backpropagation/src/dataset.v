module dataset #(
    parameter NEURON_NUM          = 5,
              ACTIVATION_WIDTH    = 9,
              DATASET_ADDR_WIDTH  = 10,
              MAX_SAMPLES         = 1000,
              INPUT_SAMPLES_FILE  = "inputs.list",
              OUTPUT_SAMPLES_FILE = "outputs.list"
) (
    input clk,
    input rst,
    // inputs to the network
    output [NEURON_NUM*ACTIVATION_WIDTH-1:0] network_inputs,
    output                                   network_inputs_valid,
    input                                    network_inputs_ready,
    // outputs expected from network
    output [NEURON_NUM*ACTIVATION_WIDTH-1:0] network_outputs,
    output                                   network_outputs_valid,
    input                                    network_outputs_ready
);

    wire [DATASET_ADDR_WIDTH-1:0] counter, counter_1, counter_2;
    wire counter_valid, counter_ready;
    wire counter_1_valid, counter_1_ready, counter_2_valid, counter_2_ready;

    counter #(
        .WIDTH(DATASET_ADDR_WIDTH),
        .MAX_VALUE(MAX_SAMPLES)
    ) sample_counter (
        .clk        (clk          ),
        .rst        (rst          ),
        .count      (counter      ),
        .count_valid(counter_valid),
        .count_ready(counter_ready)
    );


    fifo_splitter2 #(DATASET_ADDR_WIDTH) 
    split (
        .clk            (clk            ),
        .rst            (rst            ),
        .data_in        (counter        ),
        .data_in_valid  (counter_valid  ),
        .data_in_ready  (counter_ready  ),
        .data_out1      (counter_1      ),
        .data_out1_valid(counter_1_valid),
        .data_out1_ready(counter_1_ready),
        .data_out2      (counter_2      ),
        .data_out2_valid(counter_2_valid),
        .data_out2_ready(counter_2_ready)
    );


    bram_wrapper #(
        .DATA_WIDTH(NEURON_NUM*ACTIVATION_WIDTH),
        .ADDR_WIDTH(DATASET_ADDR_WIDTH         ),
        .INIT_FILE (INPUT_SAMPLES_FILE         )
    ) inputs_bram (
	    .clk             (clk                 ),
        .rst             (rst                 ),
        .read_addr       (counter_1           ),
        .read_addr_valid (counter_1_valid     ),
        .read_addr_ready (counter_1_ready     ),
   	    .read_data       (network_inputs      ),
        .read_data_valid (network_inputs_valid),
        .read_data_ready (network_inputs_ready),
        .write_addr      (0                   ),
        .write_addr_valid(1'b0                ),
        .write_addr_ready(                    ),
        .write_data      (0                   ),
        .write_data_valid(1'b0                ),
        .write_data_ready(                    )
    );


    bram_wrapper #(
        .DATA_WIDTH(NEURON_NUM*ACTIVATION_WIDTH),
        .ADDR_WIDTH(DATASET_ADDR_WIDTH         ),
        .INIT_FILE (OUTPUT_SAMPLES_FILE        )
    ) outputs_bram (
	    .clk             (clk                  ),
        .rst             (rst                  ),
        .read_addr       (counter_2            ),
        .read_addr_valid (counter_2_valid      ),
        .read_addr_ready (counter_2_ready      ),
   	    .read_data       (network_outputs      ),
        .read_data_valid (network_outputs_valid),
        .read_data_ready (network_outputs_ready),
        .write_addr      (0                    ),
        .write_addr_valid(1'b0                 ),
        .write_addr_ready(                     ),
        .write_data      (0                    ),
        .write_data_valid(1'b0                 ),
        .write_data_ready(                     )
    );

endmodule
