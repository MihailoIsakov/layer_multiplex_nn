#! /usr/bin/env python

import numpy as np


def twos_complement(num, bits):
    return format(num if num >= 0 else (1 << bits) + num, '0' + str(bits) + 'b')


def sigmoid(x):
    return 1 / (1 + np.exp(-x))


def sigmoid_derivative(x):
    return sigmoid(x) * (1 - sigmoid(x))


# def sample_function(fun, low, high, steps):
    # space = np.linspace(low, high, steps)
    # return [fun(x) for x in space]
def sample_function(fun, low, high, steps):
    space = np.linspace(low, high, steps+1)[:-1]
    space = np.concatenate((space[steps/2:], space[:steps/2]), axis=0)
    return [fun(x) for x in space]


def quantize(value, bits, fraction_bits):
    quantized = int(value * (2**fraction_bits))
    assert np.abs(quantized) < 2**(bits-1)
    return quantized


def main(path, fun, low, high, steps, bits, fraction_bits):
    f = open(path, 'w')

    samples = sample_function(fun, low, high, steps)
    for sample in samples:
        sample = quantize(sample, bits, fraction_bits)
        f.write(twos_complement(sample, bits) + "\n")


if __name__ == "__main__":
    import sys
    argv = sys.argv

    path = argv[1]

    if argv[2] == "sigmoid":
        fun = sigmoid
    elif argv[2] == "derivative":
        fun = sigmoid_derivative
    else: 
        print("function must be 'sigmoid' or 'derivative'")

    low  = float(argv[3])
    high = float(argv[4])
    steps = int(argv[5])
    bits = int(argv[6])
    fraction_bits = int(argv[7])

    main(path, fun, low, high, steps, bits, fraction_bits)

