# Backpropagation in hardware

### To run: 
- create a project in vivado 
- add all the verilog files in the src/ directory as source files
- add all .mem & .list files in the project root directory as simulation files
- run the src/testbenches/tb_top.v testbench

To test training, observe the "classification_buffer_int" signal in the testbench (right click on the signal, select
Waveform style / Analog for a better presentation). This signal ranges in [0, 100] and represents the percentage of examples correctly classified on the training set. It is
ran through a low pass to increase visibility.

### Testing
The `tb_top.v` file in `backpropagation/src/testbenches` is a top module testbench which trains the network.
The testbench can print out the values of each of the signals during training (inputs, activations, targets, errors,
deltas, weights, weight updates, updated weights, etc.), along with a classification accuracy signal
`classification_buffer_int`. We can see that in a couple of hundred samples the classification converges. 

### Dataset
The dataset we use to train on is the Breast Cancer Wisconsin (Diagnostic) dataset [http://archive.ics.uci.edu/ml/datasets/breast+cancer+wisconsin+%28diagnostic%29](link). 
The dataset has 30 features and 569 samples, each categorized in benign or malign. We create a 30 neuron layer network
and train it ***achieving 99%*** classification accuracy on the training set. We have not tested test time accuracy as
it is out of scope.

### Functional tests
We have confirmed that the network trains properly by replicating fixed point training in an ipython notebook.
We have shown that the python implementation converges, and that the values of all signals in the python implementation
are identical to those in our implementation.
The notebook can be located in `backpropagation/src/func_test/Test hardware.ipynb`, and ran by running `jupyter
notebook` in the same directory (**It should also be readable from github, as github renders results online**).

