import numpy as np
import seaborn 


def convert_to_fixed_point(matrix, bits_below_radix):
    matrix *= 2 ** bits_below_radix
    return matrix.astype(int)
 

def twos_complement9(values):
    assert np.all(np.array(values) >= -256)
    assert np.all(np.array(values) <= 255)

    return np.array(values) & 0x1ff


def save_iris_inputs(path, size, bits_below_radix):
    iris = seaborn.load_dataset('iris').values
    inputs = iris[:, :4] / 10.0
    inputs = np.pad(inputs, [[0, 0], [0, size - inputs.shape[1]]], 'constant')
    inputs[:, -1] = 0.9999

    f = open(path, 'w')
    bin_format = "09b"  # 17 bits -_-

    inputs = convert_to_fixed_point(inputs, bits_below_radix)
    inputs = twos_complement9(inputs)

    for row in inputs:
        for cell in row:
            f.write(format(cell, bin_format))

        f.write("\n")

    return inputs
