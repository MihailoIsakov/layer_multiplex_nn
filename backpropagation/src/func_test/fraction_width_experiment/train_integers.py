import numpy as np

from activations import relu, relu_derivative
from scipy.signal import savgol_filter


def test(inputs, targets, fraction, lr, conf, weight_mean=0, weight_variance=500, iter=10000, \
        func=relu, func_der=relu_derivative, verbosity="low"):
    """
    Trains a neural network with integer inputs and weights, where the integer values are treated as fixed point values.

    Args:
        inputs (sample # x input width numpy array): a floating point network inputs array, each row is an individual
        sample.
        targets (sample # x output width numpy array): a floating point network outputs array, each row is an individual
        target.
        fraction (int): the number of bits used for representing the fraction.
        lr (int): value by which we shift gradients to the right. We calculate the learning rate as 1 / 2**lr. 
        conf (list): a list if layer neuron numbers.
        weight_mean (float): the normal distribution mean used for weight initialization.
        weight_variance (float): the normal distribution variance used for weight initialization.
        iter (int): the number of samples to train on.
        func (function): the neuron activation function.
        func_der (function): the derivative of the activation function.
        verbosity (string): verbosity level.
        low_pass_width (int): since the data is noisy, we measure accuracy by averaging the last $low_pass_width$
        errors.
        ...
    """
    assert len(conf) == 2

    np.random.seed(0xdeadbeec)

    x = np.rint(inputs * 2**fraction).astype(int)
    y = np.rint(targets * 2**fraction).astype(int)

    shuffle = np.random.permutation(np.arange(len(x)))
    x, y  = x[shuffle], y[shuffle]

    w = np.random.normal(0, weight_variance, (conf[1], conf[0]))
    w = np.rint(w).astype(int)

    activations = np.zeros((iter, conf[1]))

    for i in range(iter): 
        sample = i % len(x)

        z0     = x[sample]
        target = y[sample]

        z1 = np.matmul(w, z0)
        a1 = func(z1)
        z1 = np.right_shift(z1, fraction)
        a1 = np.right_shift(a1, fraction)

        delta = (target - a1) * func_der(z1)
        delta = np.round(delta).astype(int)

        updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
        updates = np.right_shift(updates, fraction+lr)

        w = w + updates

        activations[i] = a1

        if verbosity == "low": 
            print np.sum(np.abs(target - a1)) / 2.0**fraction

    return activations


def test_classification(inputs, labels, fraction, lr, conf, weight_mean=0, weight_variance=500, iter=10000, 
        func=relu, func_der=relu_derivative, verbosity="low", smooth_window=101):

    targets = np.zeros((len(inputs), conf[1]))
    targets[np.arange(len(inputs)).astype(int), labels] = 1.0

    activations = test(inputs=inputs, targets=targets, fraction=fraction, lr=lr, conf=conf, weight_mean=weight_mean,
            weight_variance=weight_variance, iter=iter, func=func, func_der=func_der, verbosity=verbosity)
    
    classification = np.argmax(activations, axis=1) == np.tile(labels, iter/len(inputs)+1)[:iter]
    smooth_error = savgol_filter(classification, smooth_window, 2, mode="mirror")

    return smooth_error


def test_classification_error(inputs, labels, fraction, lr, conf, weight_mean=0, weight_variance=1000, iter=10000, 
        func=relu, func_der=relu_derivative, verbosity="low", smooth_window=101):

    targets = np.zeros((len(inputs), conf[1]))
    targets[range(len(inputs)), labels] = 1.0

    activations = test(inputs, targets, fraction, lr, conf, weight_mean, weight_variance, iter, func, func_der, verbosity)
    
    errors = np.sum(np.abs(activations - np.tile(targets, (iter/len(inputs)+1, 1))[:iter]), axis=1)
    # smooth_error = savgol_filter(errors, smooth_window, 1)#, mode="mirror")
    return errors

    return smooth_error
