import numpy as np


def quantize(value, bits, fraction_bits):
    quantized = int(value * (2**fraction_bits))
    # assert np.abs(quantized) < 2**(bits-1)
    if not np.abs(quantized) < 2**(bits-1):
        print quantized
    return quantized


def twos_complement(num, bits):
    return format(num if num >= 0 else (1 << bits) + num, '0' + str(bits) + 'b')


def gen_inputs(samples, dimensions):
    inputs = np.random.rand(samples, dimensions)
    return inputs


def gen_outputs(inputs, fun, noise=0.0):
    return [fun(i, noise=noise) for i in inputs]


def f1(inp, noise=0.01):
    return np.abs(np.sum(inp**2) - 2) / 2 #+ np.random.rand(inp[0]) * noise
        

def save_inputs(input_path, output_path, samples, dimensions, fun, input_bits, output_bits, fraction_bits):
    """
    Creates two files, input_path and output_path.
    In input_path saves a $samples$ inputs, each with $dimensions$ dimensions, with input_bits bitwidth.
    In output_path saves $samples$ outputs, produced from inputs and the $fun$ function, with output_bits bitwidth.
    """
    f_input  = open(input_path,  'w')
    f_output = open(output_path, 'w')

    inputs = gen_inputs(samples, dimensions)

    for row in inputs:
        for el in row:
            el = quantize(el, input_bits, fraction_bits)
            el = twos_complement(el, input_bits)
            f_input.write(el)
        f_input.write('\n')

        output = gen_outputs(row, fun, 0.0)
        for el in output:
            el = quantize(el, output_bits, fraction_bits)
            el = twos_complement(el, output_bits)
            f_output.write(el)
        f_output.write('\n')
