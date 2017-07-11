from activations import *
import numpy as np
from sklearn import datasets

iris = datasets.load_iris()
x = iris['data']
y_encoded = iris['target']
y = np.zeros((150, 4))
y[np.arange(150), y_encoded] = 1

shuffle = np.random.permutation(150)
X = x[shuffle]
y = y[shuffle]

# X = np.array([ [0,0,1],[0,1,1],[1,0,1],[1,1,1] ])
# y = np.array([[0,1,1,0]]).T
syn0 = 2*np.random.random((4,4)) - 1
syn1 = 2*np.random.random((4,4)) - 1
for j in xrange(6):
    # l1 = 1/(1+np.exp(-(np.dot(X,syn0))))
    l1 = np.dot(X, syn0)
    l1_delta = (y-l1) / 1000.0
    # l2 = 1/(1+np.exp(-(np.dot(l1,syn1))))
    # l2_delta = (y - l2)*(l2*(1-l2))
    # l1_delta = l2_delta.dot(syn1.T) * (l1 * (1-l1))
    # syn1 += l1.T.dot(l2_delta)
    syn0 += X.T.dot(l1_delta)

    print np.mean(np.abs(y - l1))
    # print y-l1
