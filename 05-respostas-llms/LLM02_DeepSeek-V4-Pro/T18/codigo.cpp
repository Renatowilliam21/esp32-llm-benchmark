#include <Wire.h>

uint8_t lerEEPROM(uint16_t endereco) {
  Wire.beginTransmission(0x50);
  Wire.write((uint8_t)(endereco >> 8));
  Wire.write((uint8_t)(endereco & 0xFF));
  Wire.endTransmission(false);
  Wire.requestFrom(0x50, 1);
  if (Wire.available()) {
    return (uint8_t)Wire.read();
  }
  return 0;
}