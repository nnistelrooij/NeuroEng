import random

import matplotlib.pyplot as plt
import numpy as np
import serial
import os 
import time


def binarize_data(images, labels, pos_class=7, neg_class=3):
    # only retain two classes
    mask = (labels == pos_class) | (labels == neg_class)

    # make pixel values and labels binary
    images = (images[mask] > 128).astype(int)
    labels = (labels[mask] == pos_class).astype(int)

    return images, labels


if __name__ == '__main__':
    test_file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'test.npz')
    data = np.load(test_file_path)
    images, labels = binarize_data(data['arr_0'], data['arr_1'])

    ser = serial.Serial(port='COM4', baudrate=115_200)
    def on_close(event):
        ser.close()
        exit()
    
    fig = plt.figure()
    fig.canvas.mpl_connect('close_event', on_close)

    plot = plt.imshow(images[0])
    plt.axis('off')
    plt.title('MNIST digit')
    plt.ion()
    plt.show()

    while ser.isOpen():
        idx = random.randrange(images.shape[0])
        plot.set_data(images[idx])
        plt.title(f'MNIST digit {idx}')

        encodedImage = np.packbits(images[idx]).tobytes()
        print("Image encoded, now writing to the serial")
        ser.write(encodedImage)
        ser.flush()
        print("Image uploaded to Arduino")
        time.sleep(1)
        from_arduino = ser.read_all()
        if from_arduino:
            print(from_arduino.decode("utf-8"))
        else:
            print('Arduino did not output anything')
        
        input('Press [Enter] for the next image.')

    print('Serial closed')