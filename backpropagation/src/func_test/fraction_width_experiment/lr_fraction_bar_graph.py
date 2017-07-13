import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D


def get_data():
    from lr_fraction_data import data

    lr = np.array([x[0] for x in data]).reshape(15, 16)
    fraction = np.array([x[1] for x in data]).reshape(15, 16)
    error = np.array([x[2] for x in data]).reshape(15, 16)
    
    return lr, fraction, error


def main():
    lr, fraction, error = get_data()
    
    fig = plt.figure(figsize=(8, 3))
    ax1 = fig.add_subplot(111, projection='3d')
    surface = ax1.plot_surface(lr, fraction, error, cmap=cm.coolwarm, linewidth=1, antialiased=True)

    # axis labels
    ax1.set_xlabel("Learning rate")
    ax1.set_ylabel("Fraction bitwidth")
    ax1.set_zlabel("Error")

    # learning rate tick labels
    labels = np.arange(np.min(lr), np.max(lr)+1)
    labels_adjusted = ["1/{}".format(2**x) for x in labels]
    ax1.set_xticklabels(labels_adjusted)

    # colorbar
    cbar = fig.colorbar(surface)

    plt.show()


if __name__ == "__main__":
    main()
