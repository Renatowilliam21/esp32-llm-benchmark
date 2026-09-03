#include <Arduino.h>
#include <Wire.h>
#include <esp_task_wdt.h>

const uint8_t PINO_PLUVIOMETRO = 25;
const uint8_t PINO_ANEMOMETRO  = 26;

void isrPluviometro() {}
void isrAnemometro() {}

void inicializarSensores() {}

bool detectarEeprom() {
    return true;
}

void carregarControleEEPROM() {}
void carregarConfiguracao() {}
void configurarWiFi() {}
void configurarServidorAdmin() {}

#include "candidato.inc"

void loop() {
}
