import numpy as np

import backprop
from quantization import *


NEURON_NUM = 4
DELTA_WIDTH = 10
WEIGHT_WIDTH = 16
FRACTION = 8


np.random.seed(0xDEADBEEF)


def get_data():
    y = backprop.get_target(NEURON_NUM)
    w = backprop.init_weights(NEURON_NUM)

    z0 = backprop.get_z()
    a0 = z0

    z1, a1 = backprop.forward(z0, w)

    delta, w_update, w_new = backprop.update_layer(y, a1, a0, z1, w)

    print("delta", quantize_1d(delta, DELTA_WIDTH, FRACTION))
    print("w_update", quantize_2d(w_update, WEIGHT_WIDTH, FRACTION))
    print("w_new", quantize_2d(w_new, WEIGHT_WIDTH, FRACTION))
    print("w", quantize_2d(w, WEIGHT_WIDTH, FRACTION))


if __name__ == "__main__":
    get_data()
