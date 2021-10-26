import random

import matplotlib.pyplot as plt
import numpy as np
import serial


def binarize_data(images, labels, pos_class=7, neg_class=3):
    # only retain two classes
    mask = (labels == pos_class) | (labels == neg_class)

    # make pixel values and labels binary
    images = (images[mask] > 128).astype(int)
    labels = (labels[mask] == pos_class).astype(int)

    return images, labels



if __name__ == '__main__':
    data = np.load('test.npz')
    images, labels = binarize_data(data['arr_0'], data['arr_1'])

    plot = plt.imshow(np.zeros_like(images[0]))
    plt.axis('off')
    plt.title('MNIST digit')
    plt.ion()
    plt.show()

    ser = serial.Serial(port='COM1', baudrate=115_200)

    while True:
        idx = random.randrange(images.shape[0])
        plot.set_data(images[idx])
        plt.title(f'MNIST digit {idx}')

        with ser:
            bytes = np.packbits(images[idx]).tobytes()
            ser.write(bytes)
            ser.flush()
            print(ser.readline())
        
        input('Press [Enter] for the next image.')
