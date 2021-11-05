import os 
import random
import time

import matplotlib.pyplot as plt
import numpy as np
import serial


def binarize_data(images, labels, pos_class=7, neg_class=3):
    # only retain two classes
    mask = (labels == pos_class) | (labels == neg_class)

    # make pixel values and labels binary
    images = (images[mask] >= 128).astype(int)
    labels = (labels[mask] == pos_class).astype(int)

    return images, labels


if __name__ == '__main__':
    # load test data and binarize images
    test_file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'test.npz')
    data = np.load(test_file_path)
    images, labels = binarize_data(data['arr_0'], data['arr_1'])

    # open serial port to Arduino, see Tools > Port in Arduino IDE for port name
    ser = serial.Serial(port='COM4', baudrate=115_200)
    def on_close(event):
        ser.close()
        exit()
    
    # make plot that shows digit that is sent to Arduino
    fig = plt.figure()
    fig.canvas.mpl_connect('close_event', on_close)

    plot = plt.imshow(images[0])
    plt.axis('off')
    plt.title('MNIST digit')
    plt.ion()
    plt.show()

    # send a random test image and get result from Arduino back
    while ser.isOpen():
        # pick random image and show on plot
        idx = random.randrange(images.shape[0])
        plot.set_data(images[idx])
        plt.title(f'MNIST digit {idx}')

        # encode image as string of bytes
        encodedImage = np.packbits(images[idx], bitorder='little').tobytes()
        print("Image encoded, now writing to the serial")

        # send string of bytes to Arduino
        ser.write(encodedImage)
        ser.flush()
        print("Image uploaded to Arduino")

        # wait for and print response of Arduino
        time.sleep(2)
        response = ser.read_all()
        if response:
            print(response.decode('utf-8'))
        else:
            print('Arduino did not output anything.')
        
        input('Press [Enter] for the next image.')

    print('Serial closed.')
