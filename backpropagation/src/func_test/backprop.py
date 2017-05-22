import numpy as np

import activations


def get_target(neuron_num):
    y = np.array([0]*neuron_num)
    y = np.vstack(y) 
    return y


def get_z():
    z = np.array([0, 0.3, 0.6, 0.9])
    z = np.vstack(z)
    return z


def init_weights(neuron_num):
    w = np.random.normal(0, 0.1, [neuron_num, neuron_num])
    return w 


def top_delta(y, a, z): 
    """ Calculates the error of the top layer from the target (y), top activations before sigmoid (z), and after (a) """
    delta = (y - a) * activations.sigmoid_derivative(z)

    assert np.all(delta == np.vstack(delta))
    return delta


def next_delta(delta, w, z_prev):
    delta_prev = np.matmul(w.transpose(), delta) * activations.sigmoid_derivative(z_prev)
    
    assert np.all(delta_prev == np.vstack(delta_prev))
    return delta_prev


def weight_delta(a_prev, delta):
    w_update = np.matmul(delta, a_prev.transpose())

    # assert np.all(w_update.shape == (NEURON_NUM, NEURON_NUM))
    return w_update


def update_layer(y, a, a_prev, z, w):
    delta = top_delta(y, a, z)
    weight_update = weight_delta(a_prev, delta)
    w_new = w + weight_update

    return delta, weight_update, w_new


def forward(z0, w): 
    a0 = z0  # no activation applied to inputs

    z1 = np.matmul(w, a0)
    a1 = activations.sigmoid(z1)

    return z1, a1


