#include <Arduino.h>
#include <Wire.h>
#include <esp_task_wdt.h>

extern const uint8_t PINO_PLUVIOMETRO;
extern const uint8_t PINO_ANEMOMETRO;

void isrPluviometro();
void isrAnemometro();

void inicializarSensores();
bool detectarEeprom();
void carregarControleEEPROM();
void carregarConfiguracao();
void configurarWiFi();
void configurarServidorAdmin();

void setup() {
    Serial.begin(115200);

    pinMode(PINO_PLUVIOMETRO, INPUT_PULLUP);
    pinMode(PINO_ANEMOMETRO, INPUT_PULLUP);

    attachInterrupt(digitalPinToInterrupt(PINO_PLUVIOMETRO), isrPluviometro, FALLING);
    attachInterrupt(digitalPinToInterrupt(PINO_ANEMOMETRO), isrAnemometro, FALLING);

    esp_task_wdt_init(30, true);
    esp_task_wdt_add(NULL);

    Wire.begin();

    inicializarSensores();

    if (detectarEeprom()) {
        carregarControleEEPROM();
    }

    carregarConfiguracao();

    configurarWiFi();

    configurarServidorAdmin();
}