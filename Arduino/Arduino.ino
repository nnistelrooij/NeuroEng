
#include "FPGA_Controller.h"

#define JTAG_REGS 15
#define INPUT_BUFFER_SIZE 98


char inputBuffer[INPUT_BUFFER_SIZE];  // Used to store data from the serial bus


void setup()
{

  Serial.begin(115200);  // Serial.begin() should be called before uploadBitstream

  // Upload the bitstream to the FPGA
  uploadBitstream();

  while (!Serial)
    ;

  initJTAG();
}

void writePixelsToJTAG() {
  uint32_t value;
  int offset;

  // Two cycles to write 784 bits to FPGA
  for (int cycleOffset = 0; cycleOffset < (INPUT_BUFFER_SIZE - 1) / (4 * (JTAG_REGS - 1)) + 1; cycleOffset++) {
    // Signal FPGA to start accepting inputs
    writeJTAG(JTAG_REGS - 1, 0);

    // Write pixel values to FPGA 
    for (int regOffset = 0; regOffset < JTAG_REGS - 1; regOffset++) {
      value = 0;
      for (int byteOffset = 0; byteOffset < 4; byteOffset++) {
        offset = 4 * (JTAG_REGS - 1) * cycleOffset + 4 * regOffset + byteOffset;
        if (offset < INPUT_BUFFER_SIZE) {
          value |= ((uint32_t)inputBuffer[offset]) << (8 * byteOffset);
        }
      }

      writeJTAG(regOffset, value);
    }

    // Signal FPGA to store data from JTAG in register
    writeJTAG(JTAG_REGS - 1, ((INPUT_BUFFER_SIZE - 4 * (JTAG_REGS - 1) * cycleOffset) <= (4 * (JTAG_REGS - 1))) ? 3 : 1);
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
      Serial.println((uint32_t)readJTAG(1));      
    } else {
      Serial.println("Image is invalid!");
    }
  }
}
