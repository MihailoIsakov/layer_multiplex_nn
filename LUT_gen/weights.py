import numpy as np


def generate_random_weights(path, width, depth):
    f = open(path, 'w')

    for row in range(depth):
        text = "".join([str(int(x)) for x in np.random.binomial(1, 0.5, width)])
        f.write(text + "\n")

    f.close()


def load_iris_weights(model_path):
    import h5py

    f = h5py.File(model_path)

    w1 = f['model_weights']['dense_1']['dense_1_W'].value
    b1 = f['model_weights']['dense_1']['dense_1_b'].value

    w2 = f['model_weights']['dense_2']['dense_2_W'].value
    b2 = f['model_weights']['dense_2']['dense_2_b'].value

    w3 = f['model_weights']['dense_3']['dense_3_W'].value
    b3 = f['model_weights']['dense_3']['dense_3_b'].value

    return w1, b1, w2, b2, w3, b3


def convert_to_fixed_point(matrix, bits_below_radix):
    matrix *= 2 ** bits_below_radix
    return matrix
 

def twos_complement17(values):
    assert np.all(np.array(values) >= -2**15)
    assert np.all(np.array(values) <= 2**15-1)

    return np.array(values) & 0x1ffff


def pad_bias(matrix, bias, size):
    """ Pads the matrix with the bias, zeros, and one in the corner, to avoid having to compute the bias separately """
    bias = np.pad(bias, [0, size - bias.size], 'constant')
    bias = bias.reshape((1, len(bias)))

    side = np.zeros((matrix.shape[0] + 1, 1))
    # side[-1] = 1

    matrix = np.concatenate((matrix, bias), axis=0)
    matrix = np.concatenate((matrix, side), axis=1)

    return matrix


def pad_to_size(matrix, size):
    height, width = matrix.shape
    right = size - width
    down  = size - height

    return np.pad(matrix, [[0, down], [0, right]], 'constant')


def save_weights(path, matrices, biases, bits_below_radix):
    f = open(path, 'w') 
    bin_format = "017b"  # 17 bits -_-

    largest_layer = 0
    for matrix in matrices:
        largest_layer = max(largest_layer, max(matrix.shape))

    print("largest layer: " + str(largest_layer))

    for matrix, bias in zip(matrices, biases):
        matrix = pad_to_size(matrix, largest_layer)
        matrix = pad_bias(matrix, bias, largest_layer)
        matrix[-1, -1] = 1
        matrix = convert_to_fixed_point(matrix, bits_below_radix)
        matrix = matrix.astype(int)
        matrix = matrix.flatten()
        matrix = twos_complement17(matrix)

        for cell in matrix:
            f.write(format(cell, bin_format))

        f.write("\n")


def process(matrices, biases, bits_below_radix):
    largest_layer = 0
    for matrix in matrices:
        largest_layer = max(largest_layer, max(matrix.shape))

    print("largest layer: " + str(largest_layer))
    results = []

    for matrix, bias in zip(matrices, biases):
        matrix = pad_to_size(matrix, largest_layer)
        matrix = pad_bias(matrix, bias, largest_layer)
        matrix[-1, -1] = 1
        matrix = convert_to_fixed_point(matrix, bits_below_radix)
        matrix = matrix.astype(int)
        matrix = matrix.flatten()
        matrix = twos_complement17(matrix)

        results.append(matrix)

    return results
