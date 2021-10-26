
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

void loop()
{
  if (Serial.available() > 0) {
    String strValueToSet = Serial.readStringUntil('\n');
    int valueToSet = strValueToSet.toInt();
    
    if (valueToSet == 0 || valueToSet == 1) {
      // Set value
      bool setArray[8] = { true, false, false, false, false, false, false, valueToSet };
      uint32_t output = bitArrayToInt32(setArray, 8);
      writeJTAG(0, output); 
      Serial.print("SNN_IN: ");
      Serial.println(output);
  
      // Unset the set bit
      bool unsetArray[8] = { false, false, false, false, false, false, false, false };
      output = bitArrayToInt32(unsetArray, 8);
      writeJTAG(0, output); 

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
