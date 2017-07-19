import numpy as np

from activations import linear, relu, linear_derivative, relu_derivative, sigmoid, sigmoid_derivative
from backprop import *
from sklearn.datasets import fetch_mldata

np.random.seed(0xdeadbeef)

mnist = fetch_mldata('MNIST original')
x = mnist['data'] / 256.0
y = np.zeros((len(x), 10))
y[np.arange(len(x)).astype(int), mnist['target'].astype(int)] = 1.0
shuffle = np.random.permutation(np.arange(len(x)))
x = x[shuffle]
y = y[shuffle]

w = np.random.normal(0, 0.01, (10, 784))

MAX_SAMPLES = 70000
ITER        = 2000000
FRACTION    = 24
FUNC        = relu
FUNC_DER    = relu_derivative
LR          = 12
VERBOSITY   = "low"

err = 1000

for i in range(ITER): 
    sample = i % MAX_SAMPLES
    z0 = x[sample]
    
    target = y[sample]

    z1, a1 = forward(z0, w, FUNC)

    error = np.sum(np.abs(target - a1))

    delta = top_delta(target, a1, z1, FUNC_DER)

    # updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
    updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
    # updates = signed_shift(updates, FRACTION+LR)
    updates = updates / 2.0**LR

    w = w + updates

    err = 999/1000.0 * err + 1/1000*error
    
    if VERBOSITY == "low":
        # print("ERROR: {0:0}".format(error))
        print(err)

    if VERBOSITY == "medium":
        print("ERROR: {0:10}".format(error)),
        print("   update_avg {0:10.0f}".format(np.mean(np.abs(updates)))),
        print(w)

    if VERBOSITY == "high":
        print("inputs", z0)
        print("target", target)
        print("sums", z1)
        print("output", a1)
        print("errors", target - a1)
        print("ERROR", error)
        print("delta", delta)
        print("updates", updates)
