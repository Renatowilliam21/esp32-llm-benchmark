#include <Arduino.h>
#include <math.h>

// Contexto global fornecido Ã  tarefa T24.
// Os nomes correspondem ao contrato do benchmark.

bool sht41Saudavel = false;
float sht41Temperatura = NAN;
float sht41Umidade = NAN;

bool bme280Saudavel = false;
float bme280Temperatura = NAN;
float bme280Umidade = NAN;

bool aht10Saudavel = false;
float aht10Temperatura = NAN;
float aht10Umidade = NAN;

float ultimaTempDHT = NAN;
float ultimaUmidDHT = NAN;

String fonteAmbienteAtual = "nenhuma";
unsigned long trocasDeFonteAmbiente = 0;

void lerAmbiente(float &temperatura, float &umidade);

#include "candidato.inc"

void setup() {
  Serial.begin(115200);

  // ForÃ§a integraÃ§Ã£o/link da funÃ§Ã£o candidata.
  float t = NAN;
  float u = NAN;
  lerAmbiente(t, u);
}

void loop() {
}
