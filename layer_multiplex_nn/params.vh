// layer parameters
    parameter max_neurons = 10;


// neuron parameters
    parameter input_size = 9;
    parameter input_fraction_size=8; // the integer has input_fraction_size bits after radix

    parameter weight_size = 17;
    parameter weight_fraction_size=8;


    // accomodate for the multiplication, plus a sum enough for max_neurons 
    parameter sum_size   = input_size+weight_size+$clog2(max_neurons); 

    parameter lut_addr_size = 10;
