import numpy as np


def twos_complement(num, bits):
    return format(num if num >= 0 else (1 << bits) + num, '0' + str(bits) + 'b')


def gen_weights(width, height, bits, max=10):
    matrix = np.random.randint(-max, max, (width, height))
    matrix = matrix.flatten()

    return [twos_complement(x, bits) for x in matrix]


def save_weights(path, matrices):
    f = open(path, 'w')

    for matrix in matrices:
        for x in matrix: 
            f.write(x)
        f.write("\n")

    f.close()


def main(path, layers, width, height, bits, max):
    matrices = [gen_weights(width, height, bits, max) for _ in range(layers)]
    save_weights(path, matrices)


if __name__ == "__main__":
    import sys
    argv = sys.argv

    path = argv[1]
    layers, width, height, bits, max = int(argv[2]), int(argv[3]), int(argv[4]), int(argv[5]), int(argv[6])
    main(path, layers, width, height, bits)

