float lerLDR() {
  if (vemlDisponivel) {
    return veml.readLux();
  } else {
    int leitura = analogRead(PIN_LDR);
    return (float)map(leitura, 0, 4095, 100, 0);
  }
}