import numpy as np

from activations import linear, relu, linear_derivative, relu_derivative
from backprop import *
from sklearn.datasets import fetch_mldata

np.random.seed(0xdeadbeec)

MAX_SAMPLES = 70000
ITER        = 1000000
FRACTION    = 16 
# FUNC        = linear
# FUNC_DER    = linear_derivative
FUNC        = relu
FUNC_DER    = relu_derivative
LR          = 7
VERBOSITY   = "low"


mnist = fetch_mldata('MNIST original')
x = (mnist['data'] * 2**(FRACTION-8)).astype(int)
y = np.zeros((len(x), 10))
y[np.arange(len(x)).astype(int), mnist['target'].astype(int)] = 2**FRACTION
shuffle = np.random.permutation(np.arange(len(x)))
x = x[shuffle]
y = y[shuffle].astype(int)

w = np.random.randint(-1000, 1000, (10, 784))

err = 1000

for i in range(ITER): 
    sample = i % MAX_SAMPLES
    z0 = x[sample]
    
    target = y[sample]

    z1, a1 = forward(z0, w, FUNC)
    z1 = signed_shift(z1, FRACTION)
    a1 = signed_shift(a1, FRACTION)

    error = np.sum(np.abs(target - a1))

    delta = top_delta(target, a1, z1, FUNC_DER)

    # updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
    updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
    updates = signed_shift(updates, FRACTION+LR)
    # updates = updates / 1000

    w = w + updates

    err = 149/150.0 * err + 1/150.0 * (error / 2.0**FRACTION)

    if VERBOSITY == "low":
        # print("ERROR: {0:0}".format(error / 2.0**FRACTION))
        print("ERROR: {0:0}".format(err))
        # if error / 2**24 == 1:
            # print target, a1

    if VERBOSITY == "medium":
        print("ERROR: {0:10}".format(error / 2.0**FRACTION))
        print("target", target) 
        print("a", a1)
        # print("   update_avg {0:10.0f}".format(np.mean(np.abs(updates)))),
        # print(w)

    if VERBOSITY == "high":
        print("inputs", z0)
        print("target", target)
        print("sums", z1)
        print("output", a1)
        print("errors", target - a1)
        print("ERROR", error)
        print("delta", delta)
        print("updates", updates)
