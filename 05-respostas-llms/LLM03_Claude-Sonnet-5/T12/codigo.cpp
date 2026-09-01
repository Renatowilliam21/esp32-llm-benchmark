void IRAM_ATTR isrAnemometro() {
  unsigned long agora = millis();
  if (agora - ultimoPulsoAnemometro > 5) {
    pulsosAnemometro++;
    ultimoPulsoAnemometro = agora;
  }
}