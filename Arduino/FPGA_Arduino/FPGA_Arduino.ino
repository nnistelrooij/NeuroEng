
#include "FPGA_Controller.h"

const int INPUT_BUFFER_SIZE = 102;
char inputBuffer[INPUT_BUFFER_SIZE]; // Used to store data from the serial input
const int IMAGE_MIN_SIZE = 784;
const int IMAGE_MAX_SIZE = 810;
bool image[IMAGE_MAX_SIZE]; // Used to store data to send to the JTAG

void setup()
{

  Serial.begin(115200); // Serial.begin() should be called before uploadBitstream

  // Upload the bitstream to the FPGA
  uploadBitstream();

  while (!Serial)
    ;

  Serial.println("Welcome!");

  // Warning: The digital pins 6, 7 and 8 are configured as outputs
  // on the FPGA, so shortening them out or configuring them as outputs
  // on the CPU as well may kill your Arduino permanently

  initJTAG();
}



int bitArrayToInt32(bool arr[], int count)
{
    int ret = 0;
    int tmp;
    for (int i = 0; i < count; i++) {
        tmp = arr[i];
        ret |= tmp << (count - i - 1);
    }
    return ret;
}

/**
 * arr be a reference to an array with at least 30 elements
 */ 
void writeChunkToJTAG(bool *arr, bool finish) {
  // Reset progress bit
  bool resetProgressArray[32] = {}; // Array with only false values
  uint32_t resetOutput = bitArrayToInt32(resetProgressArray, 32);
  writeJTAG(0, resetOutput); 
  delayMicroseconds(1);

  // Write new data, note that the data indices must be inverted
  bool setArray[32] = {};
  setArray[31] = true;
  setArray[30] = finish;
  for (int i = 0; i < 30; i++) {
    setArray[31-(i+2)] = arr[i];
  }
  
  uint32_t output = bitArrayToInt32(setArray, 32);
  writeJTAG(0, output); 
  //Serial.print("SNN_IN: ");
  //Serial.println(output);
  delayMicroseconds(1);
}

/**
 * len(data) >= chunks * 30
 */ 
void writeChunksToJTAG(bool *data, int chunks) {
  for (int i = 0; i < chunks; i++) {
    bool finish = (i+1)==chunks;
    writeChunkToJTAG(&data[i * 30], finish);
  }
}

/**
 * len(image) >= 810
 */
void writeImageToJTAG(bool *image) {
  writeChunksToJTAG(image, 27);
}

void loop()
{
  if (Serial.available() > 0) {

    int bytesRead = Serial.readBytesUntil('\n', inputBuffer, INPUT_BUFFER_SIZE);
    if (bytesRead >= IMAGE_MIN_SIZE / 8) {
      // Process serial input
      for (int i = 0; i < bytesRead; i++) {
        for (int j = 0; j < 8; j++) {
          image[i*8 + j] = inputBuffer[i*8] & (1 << j); // Convert byte to binary
        }
      }
      // Make sure the bit not set by serial input are cleared
      for (int i = bytesRead*8; i < IMAGE_MAX_SIZE; i++) {
        image[i] = false;
      }

      // Write image to JTAG
      writeImageToJTAG(image);

      // Wait
      delay(500);
  
      // Get and output result
      uint32_t inputs = readJTAG(0);
      Serial.println(inputs);
    } else {
      Serial.println("Image is invalid!");
    }
  }
}
