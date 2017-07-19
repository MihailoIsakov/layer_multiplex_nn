import numpy as np

from activations import relu, relu_derivative
from backprop import top_delta
from sklearn.datasets import fetch_mldata

np.random.seed(0xdeadbeec)


def test(fraction, lr, weight_mean=0, weight_variance=500, iter=10000, classification_number=1000, func=relu, func_der=relu_derivative, verbosity="low"):

    mnist = fetch_mldata('MNIST original')

    x = (mnist['data'].astype(float) * 2**(fraction-8)).astype(int)
    y = np.zeros((len(x), 10))
    y[np.arange(len(x)).astype(int), mnist['target'].astype(int)] = 2**fraction

    shuffle = np.random.permutation(np.arange(len(x)))
    x = x[shuffle]
    y = y[shuffle].astype(int)

    MAX_SAMPLES = len(x)

    w = np.random.normal(0, weight_variance, (10, 784))
    w = np.rint(w).astype(int)

    accuracy = []
    classifications = np.zeros(1000)

    for i in range(iter): 
        sample = i % MAX_SAMPLES
        z0 = x[sample]
        
        target = y[sample]

        z1 = np.matmul(w, z0)
        a1 = func(z1)
        print a1
        z1 = np.right_shift(z1, fraction)
        a1 = np.right_shift(a1, fraction)

        error = np.sum(np.abs(target - a1))

        delta = (target - a1) * func_der(z1)
        delta = np.round(delta).astype(int)

        # updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
        updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
        updates = np.right_shift(updates, fraction+lr)
        # updates = updates / 1000

        w = w + updates

        classifications[i % 1000] = np.argmax(a1) == np.argmax(target)
        accuracy.append(np.mean(np.argmax(a1) == np.argmax(target)))

        if verbosity == "low":
            print("accuracy: {}".format(np.mean(classifications)))

    return np.mean(classifications), accuracy


def main():
    accuracy = []

    for lr in range(-3, 15):
        for fraction in range(5, 32):
            acc = test(fraction, lr, iter=1000000, func=relu, func_der=relu_derivative, verbosity="none")
            accuracy.append((lr, fraction, acc))

    return accuracy


if __name__ == "__main__":
    test(20, 8, 100000, func=relu, func_der=relu_derivative, verbosity="low")
    # main()
