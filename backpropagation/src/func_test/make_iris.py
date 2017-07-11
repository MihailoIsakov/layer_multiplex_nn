import numpy as np
from sklearn import datasets
import quantization as q

NEURONS      = 4
INPUT_WIDTH  = 32
OUTPUT_WIDTH = 32 
FRACTION     = 24 

iris = datasets.load_iris()

inputs = iris["data"]
outputs = iris["target"]

order = np.random.permutation(len(inputs))

inputs = inputs[order]
outputs = outputs[order]

def one_hot(array, elements):
    result = np.zeros([len(array), elements])
    for idx, el in enumerate(array):
        # result[idx, el] = 1-1/256.0  # because 1 doesn't fit in 8 bits, this will work too
        result[idx, el] = 1

    return result


# normalize data over columns
inputs = inputs / (np.max(inputs, 0) + 1/1000.0)  # the extra is to prevent 1's happening,
outputs = one_hot(outputs, NEURONS)


with open("iris_input_{}neuron_{}bit.mem".format(NEURONS, INPUT_WIDTH), "w") as inputfile:
    for row in inputs:
        for el in row:
            inputfile.write(q._twos_complement(q.quantize(el, INPUT_WIDTH, FRACTION), INPUT_WIDTH))
        
        inputfile.write("\n")


with open("iris_output_{}neuron_{}bit.mem".format(NEURONS, OUTPUT_WIDTH), "w") as outputfile:
    for row in outputs:
        for el in row:
            outputfile.write(q._twos_complement((q.quantize(el, OUTPUT_WIDTH, FRACTION)), OUTPUT_WIDTH))

        outputfile.write("\n")
