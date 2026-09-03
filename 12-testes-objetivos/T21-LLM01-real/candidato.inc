#include <Arduino.h>
#include <Wire.h>
#include <esp_task_wdt.h>
#include <esp_idf_version.h>

void setup() {
    Serial.begin(115200);

    pinMode(PINO_PLUVIOMETRO, INPUT_PULLUP);
    pinMode(PINO_ANEMOMETRO, INPUT_PULLUP);

    attachInterrupt(digitalPinToInterrupt(PINO_PLUVIOMETRO), isrPluviometro, FALLING);
    attachInterrupt(digitalPinToInterrupt(PINO_ANEMOMETRO), isrAnemometro, FALLING);

#if ESP_IDF_VERSION_MAJOR >= 5
    esp_task_wdt_config_t watchdogConfig = {
        .timeout_ms = 30000,
        .idle_core_mask = (1U << portNUM_PROCESSORS) - 1U,
        .trigger_panic = true
    };

    if (esp_task_wdt_init(&watchdogConfig) == ESP_ERR_INVALID_STATE) {
        esp_task_wdt_reconfigure(&watchdogConfig);
    }
#else
    esp_task_wdt_init(30, true);
#endif

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