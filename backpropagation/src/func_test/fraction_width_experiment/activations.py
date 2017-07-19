import numpy as np


def linear(x):
    return x


def linear_derivative(x):
    return np.ones(x.shape).astype(int)


def sigmoid(x):
    return 1 / (1 + np.exp(-x))


def sigmoid_derivative(x):
    return sigmoid(x) * (1 - sigmoid(x))


def relu(x):
    return (x > 0) * x


def relu_derivative(x):
    return (x > 0) * np.ones(x.shape).astype(int)


def leaky_relu(x):
    result = np.copy(x)
    result[x < 0] /= 100
    return result


def leaky_relu_derivative(x):
    result = np.copy(x)
    result[x >= 0] = 1
    result[x < 0]  = 0.01
    return result
