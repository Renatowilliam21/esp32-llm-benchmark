#include <Wire.h>

uint8_t identificarChipBmx(uint8_t endereco) {
  Wire.beginTransmission(endereco);
  Wire.write(0xD0);
  if (Wire.endTransmission(false) != 0) {
    return 0;
  }
  if (Wire.requestFrom((uint8_t)endereco, (uint8_t)1) == 0) {
    return 0;
  }
  return Wire.read();
}