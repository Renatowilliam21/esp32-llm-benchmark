#include <Arduino.h>
#include <Wire.h>
#include <esp_task_wdt.h>

void setup() {
  Serial.begin(115200);

  pinMode(PLUVIOMETER_PIN, INPUT_PULLUP);
  pinMode(ANEMOMETER_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(PLUVIOMETER_PIN), pluviometerISR, FALLING);
  attachInterrupt(digitalPinToInterrupt(ANEMOMETER_PIN), anemometerISR, FALLING);

  esp_task_wdt_init(10, true);
  esp_task_wdt_add(nullptr);

  Wire.begin();
  inicializarSensores();

  if (detectarEeprom()) {
    carregarControleEEPROM();
  }

  carregarConfiguracao();
  configurarWiFi();
  configurarServidorAdmin();
}