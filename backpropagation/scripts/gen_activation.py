#! /usr/bin/env python

import numpy as np


def twos_complement(num, bits):
    return format(num if num >= 0 else (1 << bits) + num, '0' + str(bits) + 'b')


def relu(x):
    return (x > 0) * x / 8.0


def relu_derivative(x):
    return (x >= 0) * 255.0/256.0


def leaky_relu(x):
    if x >= 0:
        return x / 8.0
    else:
        return x / 32.0


def leaky_relu_derivative(x):
    if x >= 0:
        return 255.0 / 256.0
    else:
        return 64.0 / 256.0


def sigmoid(x):
    return 1 / (1 + np.exp(-x))


def sigmoid_derivative(x):
    return sigmoid(x) * (1 - sigmoid(x))


def sample_function(fun, low, high, steps):
    space = np.linspace(low, high, steps+1, endpoint=False)[:-1]
    space = np.concatenate((space[steps/2:], space[:steps/2]), axis=0)
    return [fun(x) for x in space]


def quantize(value, bits, fraction_bits):
    quantized = int(value * (2**fraction_bits))
    if not (np.abs(quantized) <= 2**(bits-1)):
        print "error: " + str(quantized) + " !<= " + str(2**(bits-1))
    assert np.abs(quantized) <= 2**(bits-1)
    return quantized


def generate(path, fun, low, high, steps, bits, fraction_bits):
    f = open(path, 'w')

    samples = sample_function(fun, low, high, steps)
    for sample in samples:
        sample = quantize(sample, bits, fraction_bits)
        f.write(twos_complement(sample, bits) + "\n")


def main():
    import sys
    argv = sys.argv

    if len(sys.argv) < 8:
        print("the gen_activation needs to be called with 'python gen_activation.py FILEPATH FUNCTION LOWEST_VALUE HIGHEST_VALUE STEPS BITS FRACTION_BITS")
        return

    path = argv[1]

    if argv[2] == "sigmoid":
        fun = sigmoid
    elif argv[2] == "derivative":
        fun = sigmoid_derivative
    elif argv[2] == "relu":
        fun = relu
    elif argv[2] == "relu_derivative":
        fun = relu_derivative
    elif argv[2] == "leaky_relu":
        fun = leaky_relu
    elif argv[2] == "leaky_relu_derivative":
        fun = leaky_relu_derivative
    else: 
        print("function must be 'sigmoid' or 'derivative'")

    low  = float(argv[3])
    high = float(argv[4])
    steps = int(argv[5])
    bits = int(argv[6])
    fraction_bits = int(argv[7])

    generate(path, fun, low, high, steps, bits, fraction_bits)


if __name__ == "__main__":
    main()

