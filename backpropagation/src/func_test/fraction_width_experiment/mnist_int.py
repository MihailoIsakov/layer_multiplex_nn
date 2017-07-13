import numpy as np

from activations import relu, relu_derivative
from backprop import forward, signed_shift, top_delta
from sklearn.datasets import fetch_mldata

np.random.seed(0xdeadbeec)


def test(fraction, lr, weight_variance=500, iter=10000, func=relu, func_der=relu_derivative, verbosity="low"):

    mnist = fetch_mldata('MNIST original')

    x = (mnist['data'] * 2**(fraction-8)).astype(int)
    y = np.zeros((len(x), 10))
    y[np.arange(len(x)).astype(int), mnist['target'].astype(int)] = 2**fraction

    shuffle = np.random.permutation(np.arange(len(x)))
    x = x[shuffle]
    y = y[shuffle].astype(int)

    MAX_SAMPLES = len(x)

    w = np.random.normal(0, weight_variance, (10, 784))
    w = np.rint(w).astype(int)

    classifications = np.zeros(100)

    for i in range(iter): 
        sample = i % MAX_SAMPLES
        z0 = x[sample]
        
        target = y[sample]

        z1, a1 = forward(z0, w, func)
        z1 = signed_shift(z1, fraction)
        a1 = signed_shift(a1, fraction)

        error = np.sum(np.abs(target - a1))

        delta = top_delta(target, a1, z1, func_der)

        # updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
        updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
        updates = signed_shift(updates, fraction+lr)
        # updates = updates / 1000

        w = w + updates

        classifications[i%100] = np.argmax(a1) == np.argmax(target)

        if verbosity == "low":
            print("ERROR: {0:0}".format(np.mean(classifications)))

    return np.mean(classifications)


def main():
    errors = []

    for lr in range(0, 15):
        for fraction in range(8, 24):
            err = test(fraction, lr, iter=1000000, func=relu, func_der=relu_derivative)
            errors.append((lr, fraction, err))
            print(lr, fraction, err)
    
    print errors


if __name__ == "__main__":
    # test(20, 3, 100000, func=relu, func_der=relu_derivative, verbosity="low")
    main()
