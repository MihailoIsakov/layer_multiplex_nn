import seaborn as sns
import numpy as np
from sklearn.cross_validation import train_test_split
from sklearn.linear_model import LogisticRegressionCV
from keras.models import Sequential
from keras.layers import Dense, Dropout
from keras.regularizers import l2
from keras.utils import np_utils

# Prepare data
iris = sns.load_dataset("iris")
X = iris.values[:, 0:4] / 10.0
y = iris.values[:, 4]

# Make test and train set
train_X, test_X, train_y, test_y = train_test_split(X, y,
                                                    train_size=0.5,
                                                    random_state=0)

################################
# Evaluate Logistic Regression
################################
lr = LogisticRegressionCV()
lr.fit(train_X, train_y)
pred_y = lr.predict(test_X)



################################
# Evaluate Keras Neural Network
################################

# Make ONE-HOT
def one_hot_encode_object_array(arr):
    '''One hot encode a numpy array of objects (e.g. strings)'''
    uniques, ids = np.unique(arr, return_inverse=True)
    return np_utils.to_categorical(ids, len(uniques))


train_y_ohe = one_hot_encode_object_array(train_y)
test_y_ohe = one_hot_encode_object_array(test_y)

model = Sequential()
model.add(Dense(6, input_shape=(4,),
                activation="sigmoid",
                W_regularizer=l2(0.0)))
# model.add(Dropout(0.2))
model.add(Dense(6,
                activation="sigmoid",
                W_regularizer=l2(0.0)))
# model.add(Dropout(0.2))
# model.add(Dense(,
                # activation="sigmoid",
                # W_regularizer=l2(0.0)))
# model.add(Dropout(0.2))
model.add(Dense(3, activation="sigmoid"))

model.compile(loss='categorical_crossentropy',
              metrics=['accuracy'],
              optimizer='adam')

# Actual modelling
model.fit(train_X, train_y_ohe, verbose=1, batch_size=1, nb_epoch=100)

model.save("model.h5")

score, accuracy = model.evaluate(test_X, test_y_ohe, batch_size=16, verbose=0)
print("Test fraction correct (LR-Accuracy) = {:.2f}".format(lr.score(test_X, test_y)))
print("Test fraction correct (NN-Score) = {:.2f}".format(score))
print("Test fraction correct (NN-Accuracy) = {:.2f}".format(accuracy))
