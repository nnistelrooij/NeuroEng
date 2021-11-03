
#include "FPGA_Controller.h"

#define JTAG_REGS 15

const int INPUT_BUFFER_SIZE = 98;
char inputBuffer[INPUT_BUFFER_SIZE]; // Used to store data from the serial input

void setup()
{

  Serial.begin(115200); // Serial.begin() should be called before uploadBitstream

  // Upload the bitstream to the FPGA
  uploadBitstream();

  while (!Serial)
    ;

  // Warning: The digital pins 6, 7 and 8 are configured as outputs
  // on the FPGA, so shortening them out or configuring them as outputs
  // on the CPU as well may kill your Arduino permanently

  initJTAG();
}

void writePixelsToJTAG() {
  uint32_t value;
  int offset;

  // Two cycles to write 784 bits to FPGA
  for (int JTAGOffset = 0; JTAGOffset < 98; JTAGOffset += 56) {
    // Signal FPGA to start accepting inputs
    writeJTAG(JTAG_REGS - 1, 0);

    // Write pixel values to FPGA 
    for (int registerOffset = 0; registerOffset < JTAG_REGS - 1; registerOffset++) {
      value = 0;
      for (int byteOffset = 0; byteOffset < 4; byteOffset++) {
        offset = JTAGOffset + 4 * registerOffset + byteOffset;
        if (offset < 98) {
          value |= (uint32_t)(inputBuffer[offset]) << (8 * byteOffset); // 24 - 
        }
      }

      writeJTAG(registerOffset, value);
    }

    // Signal FPGA to store data from JTAG in register
    writeJTAG(JTAG_REGS - 1, (JTAGOffset == 56) ? 3 : 1);
    delay(10);
  }
}

void loop()
{
  if (Serial.available() > 0) {

    int bytesRead = Serial.readBytes(inputBuffer, INPUT_BUFFER_SIZE);
    if (bytesRead >= INPUT_BUFFER_SIZE) {
      // Process serial input
      writePixelsToJTAG();

      // Wait, just to be sure
      delay(1000);
  
      // Get and output result
      uint32_t output = readJTAG(0);
      Serial.print("In (byte0) / Out: ");
      int intBuffer = inputBuffer[0];
      Serial.print(intBuffer);
      Serial.print(" / ");
      Serial.println(output);
      Serial.println((uint32_t)(readJTAG(1)));
      
    } else {
      Serial.println("Image is invalid!");
    }
  }
}
