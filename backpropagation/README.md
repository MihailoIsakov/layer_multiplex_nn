# Backpropagation in hardware

To run: 
- create a project in vivado 
- add all the verilog files in the src/ directory as source files
- add all .mem & .list files in the project root directory as simulation files
- run the src/testbenches/tb_top.v testbench

To test training, observe the "classification_buffer_int" signal in the testbench (right click on the signal, select
Waveform style / Analog for a better presentation).
