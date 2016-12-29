// global
    parameter layers = 3;
    parameter weights_file="weights.list";

// lut
    parameter lut_depth = 1024;
    parameter lut_addr_size = $clog2(lut_depth);
    parameter lut_width = 8;
    parameter lut_init = "activations.list";

// layer parameters
    parameter max_neurons = 10;
    parameter weights_rom_depth = 10000;


// neuron parameters
    parameter input_size = 9;
    parameter input_fraction_size=8; // the integer has input_fraction_size bits after radix

    parameter weight_size = 17;
    parameter weight_fraction_size=8;


    // accomodate for the multiplication, plus a sum enough for max_neurons 
    parameter sum_size   = input_size+weight_size+$clog2(max_neurons); 

