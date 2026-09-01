void IRAM_ATTR isrPluviometro() {
    unsigned long agora = millis();
    if (agora - ultimoPulsoPluviometro > 15) {
        pulsosPluviometro++;
        ultimoPulsoPluviometro = agora;
    }
}