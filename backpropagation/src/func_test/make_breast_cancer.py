import numpy as np
from sklearn import datasets
import quantization as q

NEURONS      = 30 
INPUT_WIDTH  = 20 
OUTPUT_WIDTH = 20 
FRACTION     = 16 

breast = datasets.load_breast_cancer()

inputs = breast.data / np.max(breast.data, axis=0)
outputs = np.zeros((len(inputs), 2))
outputs[range(len(inputs)), breast.target] = 2

order = np.random.permutation(len(inputs))

inputs = inputs[order]
outputs = outputs[order]

with open("breast_input_{}neuron_{}bit_{}frac.mem".format(NEURONS, INPUT_WIDTH, FRACTION), "w") as inputfile:
    for row in inputs:
        for el in row:
            inputfile.write(q._twos_complement(q.quantize(el, INPUT_WIDTH, FRACTION), INPUT_WIDTH))
        
        inputfile.write("\n")


with open("breast_output_{}neuron_{}bit_{}frac.mem".format(NEURONS, OUTPUT_WIDTH, FRACTION), "w") as outputfile:
    for row in outputs:
        for el in row:
            outputfile.write(q._twos_complement((q.quantize(el, OUTPUT_WIDTH, FRACTION)), OUTPUT_WIDTH))

        outputfile.write("\n")
