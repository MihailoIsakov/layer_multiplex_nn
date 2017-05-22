import numpy as np


def _twos_complement(num, bits):
    return format(num if num >= 0 else (1 << bits) + num, '0' + str(bits) + 'b')


def quantize(value, bits, fraction_bits):
    quantized = int(value * (2**fraction_bits))
    assert np.abs(quantized) < 2**(bits-1)

    # quantized = _twos_complement(quantized, bits)
    return quantized


def quantize_1d(array, bits, fraction_bits):
    return [quantize(x, bits, fraction_bits) for x in array]


def quantize_2d(matrix, bits, fraction_bits):
    return [quantize_1d(array, bits, fraction_bits) for array in matrix]


