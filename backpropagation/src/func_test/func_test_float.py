import numpy as np
from sklearn import datasets

from activations import *
from backprop import *
from data import w

w = w / (2.0**24)

iris = datasets.load_iris()
x = iris['data']
y_encoded = iris['target']
y = np.zeros((150, 4))
# y[np.arange(150), y_encoded] = 1

shuffle = np.random.permutation(150)
x = x[shuffle]
y = y[shuffle]


MAX_SAMPLES = 150
ITER        = 400000
FRACTION    = 24
FUNC        = linear
FUNC_DER    = linear_derivative
LR          = 11
VERBOSITY   = "low"


for i in range(ITER): 
    sample = i % MAX_SAMPLES
    z0 = x[sample]
    
    target = y[sample]

    z1, a1 = forward(z0, w, FUNC)

    error = np.sum(np.abs(target - a1))

    delta = top_delta(target, a1, z1, FUNC_DER)

    # delta_lr = signed_shift(delta, LR)

    updates = z0.reshape(len(z0), 1) * delta.reshape(1, len(delta))
    # updates = delta.reshape(len(delta), 1) * z0.reshape(1, len(z0))
    updates = updates / (2.0**LR)
    # updates = signed_shift(updates, FRACTION+LR)

    w = w + updates
    # w += (z0.T.dot(delta)

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
        # print("updates", updates)
        print("\n\n")
