uint8_t identificarChipBmx(uint8_t endereco) {
  Wire.beginTransmission(endereco);
  Wire.write(0xD0);

  if (Wire.endTransmission(false) != 0) {
    return 0;
  }

  Wire.requestFrom(endereco, static_cast<uint8_t>(1));

  if (Wire.available() < 1) {
    return 0;
  }

  return static_cast<uint8_t>(Wire.read());
}