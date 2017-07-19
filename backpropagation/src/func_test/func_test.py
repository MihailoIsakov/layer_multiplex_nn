import numpy as np
from sklearn.datasets import load_iris

from activations import *
from backprop import *
from data import w, x, y


MAX_SAMPLES = 150
ITER        = 100000
FRACTION    = 24
FUNC        = linear
FUNC_DER    = linear_derivative
LR          = 10
VERBOSITY   = "low"

iris = load_iris()

x = iris.data
# one hot vector
y = np.zeros((len(x), 4))
y[range(len(x)), iris.target] = 1

# normalize
x /= np.max(x, axis=0)

# shift right by fraction size
x *= 2**FRACTION
y *= 2**FRACTION

x = x.astype(int)
y = y.astype(int)

shuffle = np.random.permutation(np.arange(len(x)))
x = x[shuffle]
y = y[shuffle]


for i in range(ITER): 
    sample = i % MAX_SAMPLES
    z0 = x[sample]
    
    target = y[sample]

    z1 = np.matmul(w, z0)
    a1 = z1
    z1 = np.right_shift(z1, FRACTION)
    a1 = np.right_shift(a1, FRACTION)

    error = np.sum(np.abs(target - a1))

    delta = (target - a1)

    # delta_lr = signed_shift(delta, LR)

    # updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
    updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
    updates = np.right_shift(updates, FRACTION+LR)

    w = w + updates

    if VERBOSITY == "low":
        print("ERROR: {0:0}".format(error))

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
