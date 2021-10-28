#include "FPGA_Controller.h"

#define JTAG_REGS 15

byte pixels[98];
bool receivedPixels;

void setup() {
  // Start serial port with data rate of 115.2 kB/s
  Serial.begin(115200);
  
  // Upload bitstream to FPGA
  uploadBitstream();

  while (!Serial)
    ;
  Serial.println("Welcome!");  

  // Wait for pixels from serial port
  receivedPixels = false;

  // Initialize JTAG interface between CPU and FPGA
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
          value |= pixels[offset] << (24 - 8 * byteOffset);
        }
      }

      writeJTAG(registerOffset, value);
    }

    // Signal FPGA to store data from JTAG in register
    writeJTAG(JTAG_REGS - 1, (JTAGOffset == 56) ? 3 : 1);
  }
}

void loop() {
  if (receivedPixels) {    
    writePixelsToJTAG();
  }

  switch (readJTAG(0)) {
    case 1:
      Serial.println("I think it is a 7!");
      Serial.flush();
      break;
    case 2:
      Serial.println("I think it is a 3!");
      Serial.flush();
      break;
  }

  receivedPixels = false;
}

void serialEvent() {
  Serial.readBytes(pixels, 98);
  receivedPixels = true;
}
