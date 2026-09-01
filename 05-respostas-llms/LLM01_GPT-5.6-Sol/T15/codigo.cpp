float lerLDR() {
  if (vemlDisponivel) {
    return veml.readLux();
  }

  return static_cast<float>(map(analogRead(PIN_LDR), 0, 4095, 100, 0));
}