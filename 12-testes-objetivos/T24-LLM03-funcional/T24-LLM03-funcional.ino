#include <Arduino.h>
#include <math.h>

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

static int aprovados = 0;
static const int TOTAL = 6;

bool quaseIgual(float a, float b, float tol = 0.001f) {
  if (isnan(a) || isnan(b)) return false;
  return fabs(a - b) <= tol;
}

void registrar(int numero, bool passou) {
  Serial0.print("CT");
  if (numero < 10) Serial0.print("0");
  Serial0.print(numero);
  Serial0.print(" -> ");
  Serial0.println(passou ? "PASS" : "FAIL");

  if (passou) aprovados++;
}

void resetarSensores() {
  sht41Saudavel = false;
  sht41Temperatura = NAN;
  sht41Umidade = NAN;

  bme280Saudavel = false;
  bme280Temperatura = NAN;
  bme280Umidade = NAN;

  aht10Saudavel = false;
  aht10Temperatura = NAN;
  aht10Umidade = NAN;

  ultimaTempDHT = NAN;
  ultimaUmidDHT = NAN;

  fonteAmbienteAtual = "nenhuma";
  trocasDeFonteAmbiente = 0;
}

void setup() {
  Serial0.begin(115200);
  delay(4000);

  Serial0.println("======================================");
  Serial0.println("ESP32-LLM BENCHMARK");
  Serial0.println("T24 - lerAmbiente");
  Serial0.println("======================================");

  float t = NAN;
  float u = NAN;

  // --------------------------------------------------------
  // CT01
  // SHT41 vÃ¡lido; demais tambÃ©m vÃ¡lidos.
  // Deve selecionar SHT41.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 25.0f;
  sht41Umidade = 60.0f;

  bme280Saudavel = true;
  bme280Temperatura = 30.0f;
  bme280Umidade = 70.0f;

  aht10Saudavel = true;
  aht10Temperatura = 35.0f;
  aht10Umidade = 80.0f;

  ultimaTempDHT = 20.0f;
  ultimaUmidDHT = 50.0f;

  lerAmbiente(t, u);

  registrar(
    1,
    quaseIgual(t, 25.0f) &&
    quaseIgual(u, 60.0f) &&
    fonteAmbienteAtual == "SHT41"
  );

  // --------------------------------------------------------
  // CT02
  // SHT41 invÃ¡lido; BME280 vÃ¡lido.
  // Deve selecionar BME280.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 100.0f; // fora de -40..85
  sht41Umidade = 60.0f;

  bme280Saudavel = true;
  bme280Temperatura = 26.0f;
  bme280Umidade = 61.0f;

  aht10Saudavel = true;
  aht10Temperatura = 27.0f;
  aht10Umidade = 62.0f;

  ultimaTempDHT = 28.0f;
  ultimaUmidDHT = 63.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    2,
    quaseIgual(t, 26.0f) &&
    quaseIgual(u, 61.0f) &&
    fonteAmbienteAtual == "BME280"
  );

  // --------------------------------------------------------
  // CT03
  // SHT41/BME280 invÃ¡lidos; AHT10 vÃ¡lido.
  // Deve selecionar AHT10.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 25.0f;
  sht41Umidade = 120.0f; // invÃ¡lida

  bme280Saudavel = true;
  bme280Temperatura = -50.0f; // invÃ¡lida
  bme280Umidade = 50.0f;

  aht10Saudavel = true;
  aht10Temperatura = 24.0f;
  aht10Umidade = 55.0f;

  ultimaTempDHT = 23.0f;
  ultimaUmidDHT = 54.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    3,
    quaseIgual(t, 24.0f) &&
    quaseIgual(u, 55.0f) &&
    fonteAmbienteAtual == "AHT10"
  );

  // --------------------------------------------------------
  // CT04
  // SHT/BME/AHT invÃ¡lidos; DHT previamente lido vÃ¡lido.
  // Deve selecionar DHT22.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = false;

  bme280Saudavel = true;
  bme280Temperatura = NAN;
  bme280Umidade = 50.0f;

  aht10Saudavel = true;
  aht10Temperatura = 25.0f;
  aht10Umidade = NAN;

  ultimaTempDHT = 22.0f;
  ultimaUmidDHT = 65.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    4,
    quaseIgual(t, 22.0f) &&
    quaseIgual(u, 65.0f) &&
    fonteAmbienteAtual == "DHT22"
  );

  // --------------------------------------------------------
  // CT05
  // Todos invÃ¡lidos.
  // Deve retornar NAN/NAN e fonte "nenhuma".
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = false;
  bme280Saudavel = false;
  aht10Saudavel = false;

  ultimaTempDHT = NAN;
  ultimaUmidDHT = NAN;

  t = 123.0f;
  u = 123.0f;

  lerAmbiente(t, u);

  registrar(
    5,
    isnan(t) &&
    isnan(u) &&
    fonteAmbienteAtual == "nenhuma"
  );

  // --------------------------------------------------------
  // CT06
  // Fonte muda entre chamadas.
  // Deve atualizar fonteAmbienteAtual e incrementar
  // trocasDeFonteAmbiente.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 21.0f;
  sht41Umidade = 51.0f;

  bme280Saudavel = true;
  bme280Temperatura = 22.0f;
  bme280Umidade = 52.0f;

  t = NAN;
  u = NAN;

  lerAmbiente(t, u);

  unsigned long trocasAposPrimeira = trocasDeFonteAmbiente;

  // Torna SHT invÃ¡lido para obrigar fallback para BME.
  sht41Temperatura = 100.0f;

  lerAmbiente(t, u);

  registrar(
    6,
    fonteAmbienteAtual == "BME280" &&
    quaseIgual(t, 22.0f) &&
    quaseIgual(u, 52.0f) &&
    trocasDeFonteAmbiente == (trocasAposPrimeira + 1)
  );

  Serial0.println();
  Serial0.print("CASOS_APROVADOS=");
  Serial0.println(aprovados);

  Serial0.print("CASOS_EXECUTADOS=");
  Serial0.println(TOTAL);

  Serial0.print("RESULTADO=");
  Serial0.println(aprovados == TOTAL ? "PASS" : "FAIL");
}

void loop() {
}
