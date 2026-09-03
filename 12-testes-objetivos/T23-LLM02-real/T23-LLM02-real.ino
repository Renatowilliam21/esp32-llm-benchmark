#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_BME280.h>
#include <Adafruit_BMP280.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_SHT4x.h>
#include <Adafruit_VEML7700.h>
#include <ScioSense_ENS160.h>
#include <RTClib.h>
#include <EEPROM.h>

// ============================================================
// CONTEXTO PADRONIZADO DO PROJETO
// ============================================================

#define PIN_DHT 4
#define DHTTYPE DHT22

DHT dht(PIN_DHT, DHTTYPE);

Adafruit_BME280 bme;
Adafruit_BMP280 bmp;
Adafruit_AHTX0 aht10;
Adafruit_SHT4x sht41;
Adafruit_VEML7700 veml7700;

// Biblioteca ENS160 congelada no ambiente experimental.
ScioSense_ENS160 ens160(ENS160_I2CADDR_1);

RTC_DS3231 rtc;

// ------------------------------------------------------------
// Flags de disponibilidade/saÃºde do firmware-base
// ------------------------------------------------------------

bool dhtDisponivel = false;
bool dhtSaudavel = false;

bool bme280Disponivel = false;
bool bme280Saudavel = false;

bool bmp280Disponivel = false;
bool bmp280Saudavel = false;

bool aht10Disponivel = false;
bool aht10Saudavel = false;

bool sht41Disponivel = false;
bool sht41Saudavel = false;

bool veml7700Disponivel = false;
bool veml7700Saudavel = false;

bool ens160Disponivel = false;
bool ens160Saudavel = false;

bool rtcDisponivel = false;
bool rtcSaudavel = false;

bool eepromDisponivel = false;
bool eepromSaudavel = false;

bool ldrDisponivel = false;
bool ldrSaudavel = false;

bool usarLDR = false;

const size_t TAMANHO_EEPROM = 4096;

// ProtÃ³tipo presente no firmware.
void inicializarSensores();

// ============================================================
// CÃ“DIGO CANDIDATO â€” NÃƒO ALTERAR
// ============================================================

#include "candidato.inc"

// ============================================================
// FORÃ‡A INTEGRAÃ‡ÃƒO/LINK DA FUNÃ‡ÃƒO
// ============================================================

void setup() {
    Serial.begin(115200);
    inicializarSensores();
}

void loop() {
}
