import numpy as np
from sklearn import datasets
import quantization as q

iris = datasets.load_iris()

inputs = iris["data"]
outputs = iris["target"]


def one_hot(array, elements):
    result = np.zeros([len(array), elements])
    for idx, el in enumerate(array):
        result[idx, el] = 1-1/256.0 # because 1 doesn't fit in 8 bits, this will work too

    return result


# normalize data over columns
inputs = inputs / np.max(inputs, 0)
outputs = one_hot(outputs, 4)


with open("iris_input_4neuron_12bit", "w") as inputfile:
    for row in inputs:
        for el in row:
            inputfile.write(q._twos_complement(q.quantize(el, 12, 8), 12))
        
        inputfile.write("\n")


with open("iris_output_4neuron_9bit", "w") as outputfile:
    for row in outputs:
        for el in row:
            outputfile.write(q._twos_complement((q.quantize(el, 9, 8)), 9))

        outputfile.write("\n")
