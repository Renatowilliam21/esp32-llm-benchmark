uint8_t lerEEPROM(uint16_t endereco) {
  Wire.beginTransmission(0x50);
  Wire.write(static_cast<uint8_t>(endereco >> 8));
  Wire.write(static_cast<uint8_t>(endereco & 0xFF));
  Wire.endTransmission();

  Wire.requestFrom(static_cast<uint8_t>(0x50), static_cast<uint8_t>(1));
  return Wire.available() ? static_cast<uint8_t>(Wire.read()) : 0;
}