import numpy as np
from sklearn.datasets import fetch_mldata
import quantization as q

np.random.seed(0xdeadbeec)

INPUT_WIDTH  = 16 
OUTPUT_WIDTH = 16 
FRACTION     = 12

mnist = fetch_mldata('MNIST original')
inputs = (mnist['data'].astype(float) / 255.0)
outputs = np.zeros((len(inputs), 10))
outputs[np.arange(len(inputs)).astype(int), mnist['target'].astype(int)] = 1.0
shuffle = np.random.permutation(np.arange(len(inputs)))
inputs = inputs[shuffle]
outputs = outputs[shuffle].astype(int)


with open("mnist_input_{}bit.mem".format(INPUT_WIDTH), "w") as inputfile:
    for row in inputs:
        for el in row:
            inputfile.write(q._twos_complement_hex(q.quantize(el, INPUT_WIDTH, FRACTION), INPUT_WIDTH))
        
        inputfile.write("\n")


with open("mnist_output_{}bit.mem".format(OUTPUT_WIDTH), "w") as outputfile:
    for row in outputs:
        for el in row:
            outputfile.write(q._twos_complement_hex((q.quantize(el, OUTPUT_WIDTH, FRACTION)), OUTPUT_WIDTH))

        outputfile.write("\n")
