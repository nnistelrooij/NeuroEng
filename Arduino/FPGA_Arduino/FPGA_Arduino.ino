
#include "FPGA_Controller.h"

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
  delayMicroseconds(1000);

  // Write new data, note that the data indices must be inverted
  bool setArray[32] = {};
  setArray[31] = true;
  setArray[30] = finish;
  for (int i = 0; i < 30; i++) {
    setArray[31-(i+2)] = arr[i];
  }
  
  uint32_t output = bitArrayToInt32(setArray, 32);
  writeJTAG(0, output); 
  Serial.print("SNN_IN: ");
  Serial.println(output);
  delayMicroseconds(1000);
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
 * len(image) >= 728
 */
void writeImageToJTAG(bool *image) {
  writeChunksToJTAG(image, 28);
}

void loop()
{
  if (Serial.available() > 0) {
    String strValueToSet = Serial.readStringUntil('\n');
    int valueToSet = strValueToSet.toInt();
    
    if (valueToSet == 0 || valueToSet == 1) {
      // Demo
      bool dataArray[60] = {};
      //dataArray[26] = valueToSet;
      dataArray[56] = valueToSet;
      writeChunksToJTAG(dataArray, 2);

      // Wait
      delay(500);
  
      // Get result
      uint32_t inputs = readJTAG(0);
      Serial.print("SNN_OUT: ");
      Serial.println(inputs);
    } else {
      Serial.println("Input can only be 0 or 1!");
    }
  }
}
