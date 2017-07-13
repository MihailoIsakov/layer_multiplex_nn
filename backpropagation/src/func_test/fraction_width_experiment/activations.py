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
    return (x>0) * x


def relu_derivative(x):
    return (x>0) * np.ones(x.shape).astype(int)
