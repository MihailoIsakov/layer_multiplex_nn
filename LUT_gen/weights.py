import numpy as np


def generate_random_weights(path, width, depth):
    f = open(path, 'w')

    for row in range(depth):
        text = "".join([str(int(x)) for x in np.random.binomial(1, 0.5, width)])
        f.write(text + "\n")

    f.close()

