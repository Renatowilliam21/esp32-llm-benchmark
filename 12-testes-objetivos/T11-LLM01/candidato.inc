void IRAM_ATTR isrPluviometro() {
    unsigned long agora = millis();
    if (agora - ultimoPulsoPluviometro > 15UL) {
        pulsosPluviometro++;
        ultimoPulsoPluviometro = agora;
    }
}