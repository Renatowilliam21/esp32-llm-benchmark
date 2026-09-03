/***************************************************************************
 * SMART WEATHER PLATFORM
 * Firmware v2.10 (ESP32 WROOM-32 / WeMos, GPIO18/22 - sem GPIO21 disponivel)
 *
 * Sensores suportados (deteccao automatica por chip ID + redundancia):
 *   - DHT22 (globo negro) - sempre obrigatorio
 *   - Ambiente (temperatura/umidade): SHT41 > BME280 > AHT10 > DHT22 (fallback)
 *   - Pressao/altitude: BME280 ou BMP280 (identificado pelo chip ID)
 *   - Qualidade do ar: ENS160 (CO2 equivalente, TVOC, AQI) - o AHT21 do
 *     modulo combo e detectado pelo mesmo codigo do AHT10 (endereco 0x38
 *     compartilhado - nao ligar os dois juntos no mesmo barramento)
 *   - GUVA-S12SD (UV) e LDR (luminosidade)
 * Modulos OPCIONAIS (detectados automaticamente no boot):
 *   - RTC DS3231: se ausente, usa o horario do proprio servidor ao receber
 *   - EEPROM AT24C32: se ausente, usa fila de 1 posicao na RAM (sem
 *     persistencia contra queda de energia, mas com nova tentativa ate
 *     conseguir enviar). Assim que a EEPROM for instalada fisicamente,
 *     o firmware passa a usar a fila completa (~90 registros) sozinho.
 *
 * Diferenca em relacao ao firmware esp32-estacao/: SDA no GPIO18, pois
 * este modelo especifico de placa WeMos nao expoe o GPIO21.
 *
 * Historico resumido de versoes (detalhes completos no README.md):
 *   v2.2: EEPROM/RTC opcionais, com deteccao automatica e fallback em RAM
 *   v2.3: fórmula do ITU corrigida para Buffington et al. (1982)
 *   v2.4: corrige conflito de inicializacao do Watchdog Timer
 *   v2.5: adiciona sensor SHT41 (alta precisao) como prioridade maxima
 *   v2.6: adiciona sensor ENS160 (qualidade do ar: CO2eq/TVOC/AQI)
 *   v2.7: nao descarta o ciclo inteiro se so o sensor UV falhar
 *   v2.8: adiciona Teste de Degrau (OMM) e Indice de Calor NOAA
 *   v2.9: corrige validacao do indice "proximoRegistro" da EEPROM (antes
 *         so "totalRegistros" era validado, permitindo indice fora dos
 *         limites fisicos se a EEPROM tivesse dado corrompido/nao
 *         inicializado, travando o envio silenciosamente)
 *   v2.10: adiciona pluviometro de bascula (chuva_mm), anemometro
 *          (vel_vento) e sensor VEML7700 (luminosidade em lux, prioridade
 *          sobre o LDR analogico)
 ***************************************************************************/

//==============================
// BIBLIOTECAS
//==============================
#include <WiFi.h>
#include <WiFiManager.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
#include <Adafruit_BMP280.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_SHT4x.h>
#include <Adafruit_VEML7700.h>
#include "ScioSense_ENS160.h"
#include <RTClib.h>
#include <Preferences.h>
#include <esp_task_wdt.h>
#include <math.h>

//==============================
// PINOS ESP32 WROOM-32 (WeMos - GPIO21 indisponivel nesta placa)
//==============================
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define LDR_PIN 34
#define UV_PIN 35
#define SDA_PIN 18
#define SCL_PIN 22
#define BOTAO_RESET_PIN 0
#define PLUVIOMETRO_PIN 26
#define ANEMOMETRO_PIN 27
#define ENDERECO_EEPROM_I2C 0x50

//==============================
// WATCHDOG
//==============================
const int WDT_TIMEOUT_SEGUNDOS = 90;

//==============================
// FAIXAS FISICAS PLAUSIVEIS
//==============================
const float TEMP_MIN_VALIDA = -10.0;
const float TEMP_MAX_VALIDA = 65.0;
const float UMIDADE_MIN_VALIDA = 5.0;
const float UMIDADE_MAX_VALIDA = 100.0;
const float UV_MAX_VALIDO = 15.0;
const float PRESSAO_MIN_VALIDA = 800.0;
const float PRESSAO_MAX_VALIDA = 1100.0;

//==============================
// OBJETOS DE SENSOR
//==============================
DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_BME280 bme;
Adafruit_BMP280 bmp;
Adafruit_AHTX0 aht;
Adafruit_SHT4x sht4 = Adafruit_SHT4x();
Adafruit_VEML7700 veml = Adafruit_VEML7700();
ScioSense_ENS160 ens160_addr52(ENS160_I2CADDR_0); // 0x52
ScioSense_ENS160 ens160_addr53(ENS160_I2CADDR_1); // 0x53
ScioSense_ENS160* ens160 = nullptr;
RTC_DS3231 rtc;
Preferences preferencias;
WebServer servidorAdmin(80);

//==============================
// DISPONIBILIDADE DOS SENSORES/MODULOS (detectada no boot)
//==============================
bool bmeDisponivel = false;
bool bmpDisponivel = false;
bool ahtDisponivel = false;
bool sht4Disponivel = false;
bool vemlDisponivel = false;
bool ens160Disponivel = false;
bool rtcDisponivel = false;
bool eepromDisponivel = false;

bool bmeSaudavel = false;
bool ahtSaudavel = false;
bool sht4Saudavel = false;

String fonteAmbienteAtual = "nenhuma";

//==============================
// CONFIGURACAO SERVIDORES (LOCAL + PRODUCAO)
//==============================
String servidorUrlLocal, tokenLocal;
String servidorUrlProducao, tokenProducao;

String ultimoStatusLocal = "aguardando";
String ultimoStatusProducao = "aguardando";

//==============================
// INTERVALOS
//==============================
const unsigned long INTERVALO_COLETA_MS = 60000;
const unsigned long INTERVALO_AGREGACAO_MS = 600000;
const unsigned long INTERVALO_TENTATIVA_ENVIO_MS = 60000;

unsigned long ultimaColeta = 0;
unsigned long ultimaAgregacao = 0;
unsigned long ultimaTentativaEnvio = 0;

//==============================
// ACUMULADORES
//==============================
struct Acumulador {
    double soma = 0;
    int quantidade = 0;

    void adicionar(float valor) {
        if (!isnan(valor)) {
            soma += valor;
            quantidade++;
        }
    }

    float media() const {
        return quantidade > 0 ? (float)(soma / quantidade) : NAN;
    }

    void limpar() {
        soma = 0;
        quantidade = 0;
    }
};

Acumulador acTempGloboNegro, acUmidGloboNegro;
Acumulador acTempAr, acUmidAr;
Acumulador acPressao, acAltitude;
Acumulador acCo2, acTvoc, acAqi;
Acumulador acUV, acLDR;

//==============================
// CONTADORES DE DIAGNOSTICO
//==============================
unsigned long leiturasDescartadasFaixa = 0;
unsigned long registrosDescartadosChecksum = 0;
unsigned long trocasDeFonteAmbiente = 0;

// Teste de Degrau (WMO): rejeita saltos bruscos e fisicamente implausiveis
// entre leituras consecutivas (variacao maxima de 3.0C por minuto),
// complementando a validacao de faixa absoluta ja existente.
const float DEGRAU_MAX_VARIACAO_C = 3.0;
float ultimaTempGloboNegroValida = NAN;
float ultimaTempArValida = NAN;
unsigned long degrauRejeicoes = 0;

bool passaTesteDegrau(float novoValor, float &ultimoValorValido) {
    if (isnan(ultimoValorValido)) {
        ultimoValorValido = novoValor;
        return true;
    }
    if (fabs(novoValor - ultimoValorValido) > DEGRAU_MAX_VARIACAO_C) {
        degrauRejeicoes++;
        return false;
    }
    ultimoValorValido = novoValor;
    return true;
}

//==============================
// REGISTRO (usado tanto na fila EEPROM quanto no fallback em RAM)
//==============================
struct RegistroMeteorologico {
    uint16_t ano;
    uint8_t mes, dia, hora, minuto, segundo;
    float tempGloboNegro, umidGloboNegro;
    float tempAr, umidAr;
    float pressao, altitude;
    float indiceUV, luminosidade;
    float co2, tvoc, aqi;
    float ITGU, ITU;
    float indiceCalor;
    float chuvaMm, velVento;
    bool enviado;
    uint32_t checksum;
};

const int TAM_REGISTRO = sizeof(RegistroMeteorologico);
const int ENDERECO_CONTROLE = 0;
const int ENDERECO_DADOS = 32;
const int CAPACIDADE_EEPROM_BYTES = 4096;
const int MAX_REGISTROS = (CAPACIDADE_EEPROM_BYTES - ENDERECO_DADOS) / TAM_REGISTRO;

const float MM_POR_PULSO_CHUVA = 0.5;
volatile unsigned long pulsosChuvaContador = 0;
volatile unsigned long ultimoPulsoChuvaMs = 0;

const float CONSTANTE_ANEMOMETRO = 2.4;
volatile unsigned long pulsosVentoContador = 0;
volatile unsigned long ultimoPulsoVentoMs = 0;

void IRAM_ATTR isrPluviometro() {
    unsigned long agora = millis();
    if (agora - ultimoPulsoChuvaMs > 15) {
        pulsosChuvaContador++;
        ultimoPulsoChuvaMs = agora;
    }
}

void IRAM_ATTR isrAnemometro() {
    unsigned long agora = millis();
    if (agora - ultimoPulsoVentoMs > 5) {
        pulsosVentoContador++;
        ultimoPulsoVentoMs = agora;
    }
}

int totalRegistros = 0;
int proximoRegistro = 0;

RegistroMeteorologico registroPendenteRAM;
bool registroPendenteRAMValido = false;

//==============================
// PROTOTIPOS
//==============================
void inicializarSensores();
byte identificarChipBmx(byte endereco);
bool detectarEeprom();
void coletarAmostra();
void lerAmbiente(float &temperatura, float &umidade, float dhtTempJaLido, float dhtUmidJaLido);
void lerPressaoAltitude(float &pressao, float &altitude);
void lerQualidadeAr(float &co2, float &tvoc, float &aqi);
float lerUV();
float lerLDR();
bool faixaValida(float valor, float minimo, float maximo);
void escreverEEPROM(int endereco, byte valor);
byte lerEEPROM(int endereco);
void salvarControleEEPROM();
void carregarControleEEPROM();
uint32_t calcularChecksum(const RegistroMeteorologico &r);
void gravarRegistroPendente();
bool lerRegistro(int indice, RegistroMeteorologico &registro);
void gravarRegistro(int indice, RegistroMeteorologico registro);
void tentarDrenarFila();
String montarJSON(const RegistroMeteorologico &r);
bool enviarParaUmServidor(const char* url, const char* token, const String& json, String& status);
float calcularPontoOrvalho(float temperatura, float umidade);
float calcularITGU(float temperatura, float umidade);
float calcularITU(float temperatura, float umidade);
float calcularIndiceCalor(float temperatura, float umidade);
String classificarIndiceCalor(float indiceCalor);
String classificar(float indice);
void carregarConfiguracao();
void configurarWiFi();
void configurarServidorAdmin();

//====================================================
// SETUP
//====================================================
void setup() {
    Serial.begin(115200);
    delay(1000);

    pinMode(BOTAO_RESET_PIN, INPUT_PULLUP);

    pinMode(PLUVIOMETRO_PIN, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(PLUVIOMETRO_PIN), isrPluviometro, FALLING);
    pinMode(ANEMOMETRO_PIN, INPUT_PULLUP);
    attachInterrupt(digitalPinToInterrupt(ANEMOMETRO_PIN), isrAnemometro, FALLING);

    Serial.println("\n==============================");
    Serial.println(" SMART WEATHER PLATFORM v2.10 ");
    Serial.println(" ESP32 WeMos (GPIO18/22) ");
    Serial.println("==============================");

    // O core Arduino-ESP32 ja inicializa um watchdog padrao (com timeout
    // curto) antes do nosso setup() rodar. Se nao desativarmos esse
    // watchdog padrao primeiro, nossa configuracao de tempo maior e
    // ignorada silenciosamente (erro "TWDT already initialized"), e o
    // watchdog padrao acaba reiniciando o ESP32 no meio de operacoes
    // legitimas - como aguardar o servidor de producao "acordar" de
    // hibernacao, o que pode levar ate 50s.
    esp_task_wdt_deinit();

    esp_task_wdt_config_t configuracaoWdt = {
        .timeout_ms = (uint32_t)(WDT_TIMEOUT_SEGUNDOS * 1000),
        .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
        .trigger_panic = true,
    };
    esp_task_wdt_init(&configuracaoWdt);
    esp_task_wdt_add(NULL);
    Serial.printf("Watchdog ativo (timeout %ds).\n", WDT_TIMEOUT_SEGUNDOS);

    inicializarSensores();

    if (eepromDisponivel) {
        carregarControleEEPROM();
        Serial.printf("Fila persistente ativa (EEPROM). Capacidade: %d registros.\n", MAX_REGISTROS);
    } else {
        Serial.println("AVISO: EEPROM nao detectada. Usando buffer de 1 registro na RAM (sem protecao contra queda de energia).");
    }

    carregarConfiguracao();
    configurarWiFi();
    configurarServidorAdmin();

    Serial.println("Sistema pronto!");
}

//====================================================
// LOOP PRINCIPAL
//====================================================
void loop() {
    esp_task_wdt_reset();

    servidorAdmin.handleClient();

    if (Serial.available()) {
        String comando = Serial.readStringUntil('\n');
        comando.trim();
        if (comando == "resetar_wifi") {
            WiFiManager wm;
            wm.resetSettings();
            delay(1000);
            ESP.restart();
        }
        if (comando == "status_fila") {
            if (eepromDisponivel) {
                Serial.printf("Fila (EEPROM): %d/%d | Fonte ambiente: %s | Trocas: %lu | Descartes faixa: %lu | Descartes checksum: %lu\n",
                    totalRegistros, MAX_REGISTROS, fonteAmbienteAtual.c_str(), trocasDeFonteAmbiente,
                    leiturasDescartadasFaixa, registrosDescartadosChecksum);
            } else {
                Serial.printf("Fila (RAM, sem EEPROM): %s | Fonte ambiente: %s | Trocas: %lu | Descartes faixa: %lu\n",
                    registroPendenteRAMValido ? "1 pendente" : "vazia", fonteAmbienteAtual.c_str(),
                    trocasDeFonteAmbiente, leiturasDescartadasFaixa);
            }
        }
        if (comando == "sensores") {
            Serial.printf("SHT41: %s | BME280: %s | BMP280: %s | AHT10: %s | ENS160: %s | RTC: %s | EEPROM: %s\n",
                sht4Disponivel ? "sim" : "nao",
                bmeDisponivel ? "sim" : "nao",
                bmpDisponivel ? "sim" : "nao",
                ahtDisponivel ? "sim" : "nao",
                ens160Disponivel ? "sim" : "nao",
                rtcDisponivel ? "sim" : "nao",
                eepromDisponivel ? "sim" : "nao");
        }
    }

    if (WiFi.status() != WL_CONNECTED) {
        WiFi.reconnect();
        delay(5000);
        return;
    }

    unsigned long agora = millis();

    if (agora - ultimaColeta >= INTERVALO_COLETA_MS || ultimaColeta == 0) {
        coletarAmostra();
        ultimaColeta = agora;
    }

    if (agora - ultimaAgregacao >= INTERVALO_AGREGACAO_MS || ultimaAgregacao == 0) {
        gravarRegistroPendente();
        ultimaAgregacao = agora;
    }

    if (agora - ultimaTentativaEnvio >= INTERVALO_TENTATIVA_ENVIO_MS || ultimaTentativaEnvio == 0) {
        tentarDrenarFila();
        ultimaTentativaEnvio = agora;
    }
}

//====================================================
// SENSORES - INICIALIZACAO (deteccao automatica)
//====================================================

byte identificarChipBmx(byte endereco) {
    Wire.beginTransmission(endereco);
    Wire.write(0xD0);
    if (Wire.endTransmission(false) != 0) return 0;

    Wire.requestFrom(endereco, (byte)1);
    if (!Wire.available()) return 0;

    return Wire.read();
}

bool detectarEeprom() {
    Wire.beginTransmission(ENDERECO_EEPROM_I2C);
    return Wire.endTransmission() == 0;
}

void inicializarSensores() {
    Wire.begin(SDA_PIN, SCL_PIN);
    dht.begin();
    Serial.println("DHT22 configurado (sempre ativo, sem deteccao - e obrigatorio).");

    byte enderecoDetectado = 0;
    byte chipId = identificarChipBmx(0x76);
    if (chipId != 0) {
        enderecoDetectado = 0x76;
    } else {
        chipId = identificarChipBmx(0x77);
        if (chipId != 0) enderecoDetectado = 0x77;
    }

    if (chipId == 0x60) {
        bmeDisponivel = bme.begin(enderecoDetectado);
        bmeSaudavel = bmeDisponivel;
        Serial.println(bmeDisponivel ? "BME280 encontrado (ambiente + pressao/altitude)." : "BME280 detectado (chip ID) mas falhou ao iniciar a biblioteca.");
    } else if (chipId == 0x58) {
        bmpDisponivel = bmp.begin(enderecoDetectado);
        Serial.println(bmpDisponivel ? "BMP280 encontrado (pressao/altitude, sem umidade)." : "BMP280 detectado (chip ID) mas falhou ao iniciar a biblioteca.");
    } else {
        Serial.println("Nenhum sensor BME280/BMP280 detectado no barramento I2C.");
    }

    if (aht.begin()) {
        ahtDisponivel = true;
        ahtSaudavel = true;
        Serial.println("AHT10 encontrado (ambiente, backup do BME280).");
    } else {
        Serial.println("AHT10 nao encontrado.");
    }

    if (sht4.begin()) {
        sht4Disponivel = true;
        sht4Saudavel = true;
        sht4.setPrecision(SHT4X_HIGH_PRECISION);
        sht4.setHeater(SHT4X_NO_HEATER);
        Serial.println("SHT41 encontrado (0x44) - maior precisao, prioridade maxima para ambiente.");
    } else {
        Serial.println("SHT41 nao encontrado.");
    }

    if (ens160_addr52.begin()) {
        ens160 = &ens160_addr52;
        ens160Disponivel = true;
        ens160->setMode(ENS160_OPMODE_STD);
        Serial.println("ENS160 encontrado (0x52) - qualidade do ar (CO2eq/TVOC/AQI). O AHT21 deste modulo e detectado automaticamente pelo mesmo codigo do AHT10 (endereco 0x38 compartilhado).");
    } else if (ens160_addr53.begin()) {
        ens160 = &ens160_addr53;
        ens160Disponivel = true;
        ens160->setMode(ENS160_OPMODE_STD);
        Serial.println("ENS160 encontrado (0x53) - qualidade do ar (CO2eq/TVOC/AQI). O AHT21 deste modulo e detectado automaticamente pelo mesmo codigo do AHT10 (endereco 0x38 compartilhado).");
    } else {
        Serial.println("ENS160 nao encontrado.");
    }

    if (veml.begin()) {
        vemlDisponivel = true;
        Serial.println("VEML7700 encontrado (0x10) - luminosidade em lux, prioridade sobre o LDR analogico.");
    } else {
        Serial.println("VEML7700 nao encontrado. Luminosidade sera lida via LDR analogico (0-100).");
    }
    rtcDisponivel = rtc.begin();
    if (rtcDisponivel) {
        Serial.println("RTC DS3231 encontrado (0x68).");
        if (rtc.lostPower()) {
            Serial.println("RTC sem hora valida: ajustando pelo horario de compilacao.");
            rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
        }
    } else {
        Serial.println("RTC nao encontrado. O horario da leitura sera definido pelo servidor ao receber (registrado_em nao sera enviado pelo firmware).");
    }

    eepromDisponivel = detectarEeprom();
    Serial.println(eepromDisponivel ? "EEPROM AT24C32 encontrada (0x50)." : "EEPROM nao encontrada.");

    if (!bmeDisponivel && !bmpDisponivel && !ahtDisponivel) {
        Serial.println("AVISO: nenhum sensor de ambiente/pressao encontrado. Temperatura do ar sera obtida do DHT22 (globo negro) como fallback.");
    }

    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);
}

//====================================================
// LEITURA DE AMBIENTE COM REDUNDANCIA EM TEMPO REAL
//====================================================
void lerAmbiente(float &temperatura, float &umidade, float dhtTempJaLido, float dhtUmidJaLido) {
    temperatura = NAN;
    umidade = NAN;
    String fonteEscolhida = "nenhuma";

    if (sht4Disponivel) {
        sensors_event_t evUmidSht, evTempSht;
        sht4.getEvent(&evUmidSht, &evTempSht);

        if (faixaValida(evTempSht.temperature, TEMP_MIN_VALIDA, TEMP_MAX_VALIDA) &&
            faixaValida(evUmidSht.relative_humidity, UMIDADE_MIN_VALIDA, UMIDADE_MAX_VALIDA)) {
            temperatura = evTempSht.temperature;
            umidade = evUmidSht.relative_humidity;
            fonteEscolhida = "SHT41";
            sht4Saudavel = true;
        } else {
            if (sht4Saudavel) {
                Serial.println("AVISO: SHT41 parou de responder corretamente. Alternando para sensor de backup.");
            }
            sht4Saudavel = false;
        }
    }

    if (isnan(temperatura) && bmeDisponivel) {
        float t = bme.readTemperature();
        float u = bme.readHumidity();

        if (faixaValida(t, TEMP_MIN_VALIDA, TEMP_MAX_VALIDA) && faixaValida(u, UMIDADE_MIN_VALIDA, UMIDADE_MAX_VALIDA)) {
            temperatura = t;
            umidade = u;
            fonteEscolhida = "BME280";
            bmeSaudavel = true;
        } else {
            if (bmeSaudavel) {
                Serial.println("AVISO: BME280 parou de responder corretamente. Alternando para sensor de backup.");
            }
            bmeSaudavel = false;
        }
    }

    if (isnan(temperatura) && ahtDisponivel) {
        sensors_event_t evUmid, evTemp;
        aht.getEvent(&evUmid, &evTemp);

        if (faixaValida(evTemp.temperature, TEMP_MIN_VALIDA, TEMP_MAX_VALIDA) &&
            faixaValida(evUmid.relative_humidity, UMIDADE_MIN_VALIDA, UMIDADE_MAX_VALIDA)) {
            temperatura = evTemp.temperature;
            umidade = evUmid.relative_humidity;
            fonteEscolhida = "AHT10";
            ahtSaudavel = true;
        } else {
            ahtSaudavel = false;
        }
    }

    if (isnan(temperatura)) {
        if (faixaValida(dhtTempJaLido, TEMP_MIN_VALIDA, TEMP_MAX_VALIDA) && faixaValida(dhtUmidJaLido, UMIDADE_MIN_VALIDA, UMIDADE_MAX_VALIDA)) {
            temperatura = dhtTempJaLido;
            umidade = dhtUmidJaLido;
            fonteEscolhida = "DHT22 (fallback)";
        }
    }

    if (fonteEscolhida != fonteAmbienteAtual) {
        Serial.printf("Fonte de ambiente: %s -> %s\n", fonteAmbienteAtual.c_str(), fonteEscolhida.c_str());
        trocasDeFonteAmbiente++;
        fonteAmbienteAtual = fonteEscolhida;
    }
}

//====================================================
// LEITURA DE PRESSAO/ALTITUDE (BME280 ou BMP280)
//====================================================
void lerPressaoAltitude(float &pressao, float &altitude) {
    pressao = NAN;
    altitude = NAN;

    if (bmeDisponivel && bmeSaudavel) {
        pressao = bme.readPressure() / 100.0F;
        altitude = bme.readAltitude(1013.25);
    } else if (bmpDisponivel) {
        pressao = bmp.readPressure() / 100.0F;
        altitude = bmp.readAltitude(1013.25);
    }

    if (!isnan(pressao) && !faixaValida(pressao, PRESSAO_MIN_VALIDA, PRESSAO_MAX_VALIDA)) {
        pressao = NAN;
        altitude = NAN;
    }
}

//====================================================
// LEITURA DE QUALIDADE DO AR (ENS160: CO2 equivalente, TVOC, AQI)
//====================================================
void lerQualidadeAr(float &co2, float &tvoc, float &aqi) {
    co2 = NAN;
    tvoc = NAN;
    aqi = NAN;

    if (!ens160Disponivel || ens160 == nullptr) return;

    ens160->measure(true);
    co2 = ens160->geteCO2();
    tvoc = ens160->getTVOC();
    aqi = ens160->getAQI();
}

float lerUV() {
    float tensao = (analogRead(UV_PIN) * 3.3) / 4095.0;
    float uv = tensao / 0.1;
    return max(0.0f, uv);
}

float lerLDR() {
    if (vemlDisponivel) {
        return veml.readLux();
    }
    return map(analogRead(LDR_PIN), 0, 4095, 100, 0);
}

bool faixaValida(float valor, float minimo, float maximo) {
    return !isnan(valor) && valor >= minimo && valor <= maximo;
}

//====================================================
// COLETA DE UMA AMOSTRA (a cada 1 minuto)
//====================================================
void coletarAmostra() {
    float tempGloboNegro = dht.readTemperature();
    float umidGloboNegro = dht.readHumidity();

    if (isnan(tempGloboNegro) || isnan(umidGloboNegro)) {
        Serial.println("Falha ao ler DHT22 (globo negro) nesta amostra. Ignorando.");
    } else if (!faixaValida(tempGloboNegro, TEMP_MIN_VALIDA, TEMP_MAX_VALIDA) ||
               !faixaValida(umidGloboNegro, UMIDADE_MIN_VALIDA, UMIDADE_MAX_VALIDA)) {
        Serial.printf("DHT22 (globo negro) fora da faixa plausivel (temp=%.1f umid=%.1f). Descartando amostra.\n", tempGloboNegro, umidGloboNegro);
        leiturasDescartadasFaixa++;
    } else if (!passaTesteDegrau(tempGloboNegro, ultimaTempGloboNegroValida)) {
        Serial.printf("DHT22 (globo negro) reprovado no teste de degrau (variacao > %.1fC). Descartando amostra.\n", DEGRAU_MAX_VARIACAO_C);
    } else {
        acTempGloboNegro.adicionar(tempGloboNegro);
        acUmidGloboNegro.adicionar(umidGloboNegro);
    }

    float tempAr, umidAr;
    lerAmbiente(tempAr, umidAr, tempGloboNegro, umidGloboNegro);
    if (!isnan(tempAr) && !passaTesteDegrau(tempAr, ultimaTempArValida)) {
        Serial.printf("Temperatura do ar reprovada no teste de degrau (variacao > %.1fC). Descartando amostra.\n", DEGRAU_MAX_VARIACAO_C);
    } else if (!isnan(tempAr)) {
        acTempAr.adicionar(tempAr);
        acUmidAr.adicionar(umidAr);
    } else {
        leiturasDescartadasFaixa++;
    }

    float pressao, altitude;
    lerPressaoAltitude(pressao, altitude);
    if (!isnan(pressao)) {
        acPressao.adicionar(pressao);
        acAltitude.adicionar(altitude);
    }

    float co2, tvoc, aqiLido;
    lerQualidadeAr(co2, tvoc, aqiLido);
    if (!isnan(co2)) {
        acCo2.adicionar(co2);
        acTvoc.adicionar(tvoc);
        acAqi.adicionar(aqiLido);
    }

    float uv = lerUV();
    if (faixaValida(uv, 0.0, UV_MAX_VALIDO)) {
        acUV.adicionar(uv);
    } else {
        leiturasDescartadasFaixa++;
    }

    acLDR.adicionar(lerLDR());

    Serial.printf("Amostra coletada (%d acumuladas | ambiente via %s)\n", acUV.quantidade, fonteAmbienteAtual.c_str());
}

//====================================================
// CALCULOS (Buffington)
//====================================================
float calcularPontoOrvalho(float temperatura, float umidade) {
    float a = 17.27, b = 237.7;
    float alpha = ((a * temperatura) / (b + temperatura)) + log(umidade / 100.0);
    return (b * alpha) / (a - alpha);
}

float calcularITGU(float temperatura, float umidade) {
    return temperatura + (0.36 * calcularPontoOrvalho(temperatura, umidade)) + 41.5;
}

float calcularITU(float temperatura, float umidade) {
    // Buffington et al. (1982) - formula especifica de ITU, amplamente
    // citada na literatura brasileira de bioclimatologia zootecnica
    // (bovinos leiteiros, semiarido/caatinga). Usa umidade relativa
    // diretamente, diferente da forma do ITGU (que usa ponto de orvalho).
    return (0.8 * temperatura) + ((umidade / 100.0) * (temperatura - 14.3)) + 46.3;
}

// Indice de Calor NOAA (regressao de Rothfusz) - foco em seguranca humana,
// diferente do ITGU/ITU (focados em conforto termico animal). A formula
// so e valida a partir de ~26.7C (80F); abaixo disso, a propria NOAA
// recomenda usar a temperatura do ar sem ajuste.
float calcularIndiceCalor(float temperatura, float umidade) {
    if (temperatura < 26.7) {
        return temperatura;
    }
    float T = temperatura * 9.0 / 5.0 + 32.0;
    float RH = umidade;
    float HI = -42.379 + (2.04901523 * T) + (10.14333127 * RH)
        - (0.22475541 * T * RH) - (0.00683783 * T * T) - (0.05481717 * RH * RH)
        + (0.00122874 * T * T * RH) + (0.00085282 * T * RH * RH)
        - (0.00000199 * T * T * RH * RH);
    float resultado = (HI - 32.0) * 5.0 / 9.0;

    // Protecao de seguranca: se por algum motivo o resultado sair de uma
    // faixa fisicamente plausivel, descarta em vez de mandar lixo pro banco.
    if (resultado < -50.0 || resultado > 100.0) {
        return NAN;
    }
    return resultado;
}

String classificarIndiceCalor(float indiceCalor) {
    if (isnan(indiceCalor)) return "";
    if (indiceCalor > 54.0) return "perigo_extremo";
    if (indiceCalor > 41.0) return "perigo";
    if (indiceCalor > 32.0) return "atencao_extrema";
    if (indiceCalor > 27.0) return "atencao";
    return "normal";
}

String classificar(float indice) {
    if (isnan(indice)) return "";
    if (indice > 78.0) return "perigo";
    if (indice > 72.0) return "alerta";
    return "normal";
}

//====================================================
// EEPROM - LEITURA/ESCRITA BRUTA (AT24C32, endereco I2C 0x50)
//====================================================
void escreverEEPROM(int endereco, byte valor) {
    Wire.beginTransmission(ENDERECO_EEPROM_I2C);
    Wire.write(endereco >> 8);
    Wire.write(endereco & 0xFF);
    Wire.write(valor);
    Wire.endTransmission();
    delay(5);
}

byte lerEEPROM(int endereco) {
    Wire.beginTransmission(ENDERECO_EEPROM_I2C);
    Wire.write(endereco >> 8);
    Wire.write(endereco & 0xFF);
    Wire.endTransmission();
    Wire.requestFrom(ENDERECO_EEPROM_I2C, 1);
    return Wire.available() ? Wire.read() : 0;
}

void salvarControleEEPROM() {
    Wire.beginTransmission(ENDERECO_EEPROM_I2C);
    Wire.write(0);
    Wire.write((totalRegistros >> 8) & 0xFF);
    Wire.write(totalRegistros & 0xFF);
    Wire.write((proximoRegistro >> 8) & 0xFF);
    Wire.write(proximoRegistro & 0xFF);
    Wire.endTransmission();
    delay(5);
}

void carregarControleEEPROM() {
    totalRegistros = (lerEEPROM(0) << 8) | lerEEPROM(1);
    proximoRegistro = (lerEEPROM(2) << 8) | lerEEPROM(3);

    // Valida os DOIS contadores independentemente. Antes, so
    // "totalRegistros" era validado - se "proximoRegistro" viesse
    // corrompido/nunca inicializado da EEPROM (ex: fila nova, dados de
    // fabrica), o sistema aceitava um indice fora dos limites fisicos,
    // gravando em endereco de memoria invalido e travando o envio
    // silenciosamente, sem nenhuma mensagem de erro.
    if (totalRegistros > MAX_REGISTROS || totalRegistros < 0
        || proximoRegistro >= MAX_REGISTROS || proximoRegistro < 0) {
        totalRegistros = 0;
        proximoRegistro = 0;
    }

    Serial.printf("Fila recuperada da EEPROM: %d registros pendentes/historicos.\n", totalRegistros);
}

uint32_t calcularChecksum(const RegistroMeteorologico &r) {
    const byte *dados = (const byte *)&r;
    int tamanhoSemChecksum = TAM_REGISTRO - sizeof(uint32_t);

    uint32_t soma = 0;
    for (int i = 0; i < tamanhoSemChecksum; i++) {
        soma = (soma * 31) + dados[i];
    }
    return soma;
}

void gravarRegistro(int indice, RegistroMeteorologico registro) {
    registro.checksum = calcularChecksum(registro);

    int endereco = ENDERECO_DADOS + (indice * TAM_REGISTRO);
    const byte *dados = (const byte *)&registro;
    for (int i = 0; i < TAM_REGISTRO; i++) {
        escreverEEPROM(endereco + i, dados[i]);
    }
}

bool lerRegistro(int indice, RegistroMeteorologico &registro) {
    int endereco = ENDERECO_DADOS + (indice * TAM_REGISTRO);
    byte *dados = (byte *)&registro;
    for (int i = 0; i < TAM_REGISTRO; i++) {
        dados[i] = lerEEPROM(endereco + i);
    }

    return registro.checksum == calcularChecksum(registro);
}

//====================================================
// GRAVA A MEDIA DO CICLO (na EEPROM se disponivel, senao na RAM)
//====================================================
void gravarRegistroPendente() {
    // So pula o ciclo inteiro se NENHUM sensor conseguiu nenhuma leitura
    // valida - antes, um sensor especifico com falha (ex: UV com contato
    // instavel) descartava tambem temperatura/umidade/ITGU/pressao que
    // estavam funcionando bem, perdendo dados bons por causa de um sensor
    // ruim.
    bool nenhumaAmostraValida = acTempGloboNegro.quantidade == 0
        && acTempAr.quantidade == 0
        && acPressao.quantidade == 0
        && acUV.quantidade == 0
        && acLDR.quantidade == 0
        && acCo2.quantidade == 0;

    if (nenhumaAmostraValida) {
        Serial.println("Nenhuma amostra acumulada em nenhum sensor. Pulando agregacao deste ciclo.");
        return;
    }

    RegistroMeteorologico registro = {};

    if (rtcDisponivel) {
        DateTime agora = rtc.now();
        registro.ano = agora.year();
        registro.mes = agora.month();
        registro.dia = agora.day();
        registro.hora = agora.hour();
        registro.minuto = agora.minute();
        registro.segundo = agora.second();
    }

    registro.tempGloboNegro = acTempGloboNegro.media();
    registro.umidGloboNegro = acUmidGloboNegro.media();
    registro.tempAr = acTempAr.media();
    registro.umidAr = acUmidAr.media();
    registro.pressao = acPressao.media();
    registro.altitude = acAltitude.media();
    registro.indiceUV = acUV.media();
    registro.luminosidade = acLDR.media();
    registro.co2 = acCo2.media();
    registro.tvoc = acTvoc.media();
    registro.aqi = acAqi.media();

    registro.ITGU = (!isnan(registro.tempGloboNegro) && !isnan(registro.umidGloboNegro))
        ? calcularITGU(registro.tempGloboNegro, registro.umidGloboNegro) : NAN;

    registro.ITU = (!isnan(registro.tempAr) && !isnan(registro.umidAr))
        ? calcularITU(registro.tempAr, registro.umidAr) : NAN;

    registro.indiceCalor = (!isnan(registro.tempAr) && !isnan(registro.umidAr))
        ? calcularIndiceCalor(registro.tempAr, registro.umidAr) : NAN;


    noInterrupts();
    unsigned long pulsosChuva = pulsosChuvaContador;
    pulsosChuvaContador = 0;
    interrupts();
    registro.chuvaMm = pulsosChuva * MM_POR_PULSO_CHUVA;

    noInterrupts();
    unsigned long pulsosVento = pulsosVentoContador;
    pulsosVentoContador = 0;
    interrupts();
    float segundosCiclo = INTERVALO_AGREGACAO_MS / 1000.0;
    registro.velVento = (pulsosVento / segundosCiclo) * CONSTANTE_ANEMOMETRO;

    registro.enviado = false;

    if (eepromDisponivel) {
        int indice = proximoRegistro;
        gravarRegistro(indice, registro);

        proximoRegistro = (proximoRegistro + 1) % MAX_REGISTROS;
        if (totalRegistros < MAX_REGISTROS) {
            totalRegistros++;
        }
        salvarControleEEPROM();

        Serial.printf("Registro persistido na fila EEPROM (indice %d). Total pendentes/historico: %d\n", indice, totalRegistros);
    } else {
        registroPendenteRAM = registro;
        registroPendenteRAMValido = true;
        Serial.println("Registro guardado no buffer RAM (sem EEPROM disponivel).");
    }

    acTempGloboNegro.limpar();
    acUmidGloboNegro.limpar();
    acTempAr.limpar();
    acUmidAr.limpar();
    acPressao.limpar();
    acAltitude.limpar();
    acUV.limpar();
    acLDR.limpar();
    acCo2.limpar();
    acTvoc.limpar();
    acAqi.limpar();
}

//====================================================
// MONTA O JSON NO FORMATO ESPERADO PELA API LARAVEL
//====================================================
String montarJSON(const RegistroMeteorologico &r) {
    JsonDocument json;

    if (!isnan(r.tempGloboNegro)) json["temp_globo_negro"] = r.tempGloboNegro;
    if (!isnan(r.umidGloboNegro)) json["umid_globo_negro"] = r.umidGloboNegro;
    if (!isnan(r.tempAr)) json["temperatura_ar"] = r.tempAr;
    if (!isnan(r.umidAr)) json["umidade_ar"] = r.umidAr;
    if (!isnan(r.pressao)) json["pressao"] = r.pressao;
    if (!isnan(r.altitude)) json["altitude"] = r.altitude;
    if (!isnan(r.co2)) json["co2_ppm"] = r.co2;
    if (!isnan(r.tvoc)) json["tvoc_ppb"] = r.tvoc;
    if (!isnan(r.aqi)) json["aqi"] = (int)round(r.aqi);
    json["indice_uv"] = r.indiceUV;
    json["luminosidade"] = r.luminosidade;

    if (!isnan(r.ITGU)) {
        json["itgu"] = r.ITGU;
        json["itgu_classificacao"] = classificar(r.ITGU);
    }
    if (!isnan(r.ITU)) {
        json["itu"] = r.ITU;
        json["itu_classificacao"] = classificar(r.ITU);
    }
    if (!isnan(r.indiceCalor)) {
        json["indice_calor"] = r.indiceCalor;
        json["indice_calor_classificacao"] = classificarIndiceCalor(r.indiceCalor);
    }

    json["chuva_mm"] = r.chuvaMm;
    json["vel_vento"] = r.velVento;
    json["tipo_agregacao"] = "agregado";

    if (r.ano > 0) {
        char timestamp[20];
        snprintf(timestamp, sizeof(timestamp), "%04d-%02d-%02d %02d:%02d:%02d",
                 r.ano, r.mes, r.dia, r.hora, r.minuto, r.segundo);
        json["registrado_em"] = timestamp;
    }

    String saida;
    serializeJson(json, saida);
    return saida;
}

//====================================================
// ENVIO HTTP PARA UM DESTINO
//====================================================
bool enviarParaUmServidor(const char* url, const char* token, const String& json, String& status) {
    if (strlen(url) == 0 || strlen(token) == 0) {
        status = "nao configurado";
        return true;
    }

    HTTPClient http;
    WiFiClientSecure clienteSeguro;
    bool usarHttps = String(url).startsWith("https://");

    if (usarHttps) {
        clienteSeguro.setInsecure();
        http.begin(clienteSeguro, url);
    } else {
        http.begin(url);
    }

    http.setConnectTimeout(8000);
    http.setTimeout(60000);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-API-Token", token);

    int codigo = http.POST(json);
    bool sucesso = codigo >= 200 && codigo < 300;

    status = sucesso
        ? ("HTTP " + String(codigo) + " OK")
        : ("erro: " + (codigo > 0 ? String(codigo) : http.errorToString(codigo)));

    Serial.printf("[%s] %s\n", url, status.c_str());

    http.end();
    return sucesso;
}

//====================================================
// TENTA ENVIAR O REGISTRO PENDENTE MAIS ANTIGO
//====================================================
void tentarDrenarFila() {
    if (eepromDisponivel) {
        if (totalRegistros == 0) return;

        int indiceMaisAntigo = (proximoRegistro - totalRegistros + MAX_REGISTROS) % MAX_REGISTROS;

        RegistroMeteorologico registro;
        bool integro = lerRegistro(indiceMaisAntigo, registro);

        if (!integro) {
            Serial.printf("Registro no indice %d esta corrompido (checksum invalido). Descartando.\n", indiceMaisAntigo);
            registrosDescartadosChecksum++;
            totalRegistros--;
            salvarControleEEPROM();
            return;
        }

        if (registro.enviado) {
            totalRegistros--;
            salvarControleEEPROM();
            return;
        }

        String json = montarJSON(registro);
        Serial.println("Tentando enviar registro pendente da fila (EEPROM)...");

        bool sucessoLocal = enviarParaUmServidor(servidorUrlLocal.c_str(), tokenLocal.c_str(), json, ultimoStatusLocal);
        bool sucessoProducao = enviarParaUmServidor(servidorUrlProducao.c_str(), tokenProducao.c_str(), json, ultimoStatusProducao);

        if (sucessoLocal && sucessoProducao) {
            registro.enviado = true;
            gravarRegistro(indiceMaisAntigo, registro);
            totalRegistros--;
            salvarControleEEPROM();
            Serial.printf("Registro enviado com sucesso. Restam %d na fila.\n", totalRegistros);
        } else {
            Serial.println("Falha no envio. Registro permanece na fila para nova tentativa.");
        }
    } else {
        if (!registroPendenteRAMValido) return;

        String json = montarJSON(registroPendenteRAM);
        Serial.println("Tentando enviar registro pendente do buffer RAM...");

        bool sucessoLocal = enviarParaUmServidor(servidorUrlLocal.c_str(), tokenLocal.c_str(), json, ultimoStatusLocal);
        bool sucessoProducao = enviarParaUmServidor(servidorUrlProducao.c_str(), tokenProducao.c_str(), json, ultimoStatusProducao);

        if (sucessoLocal && sucessoProducao) {
            registroPendenteRAMValido = false;
            Serial.println("Registro (RAM) enviado com sucesso.");
        } else {
            Serial.println("Falha no envio. Registro (RAM) permanece para nova tentativa.");
        }
    }
}

//====================================================
// CONFIGURACAO (WiFi + Preferences)
//====================================================
void carregarConfiguracao() {
    preferencias.begin("estacao", false);
    servidorUrlLocal = preferencias.getString("server_local", "");
    tokenLocal = preferencias.getString("token_local", "");
    servidorUrlProducao = preferencias.getString("server_prod", "");
    tokenProducao = preferencias.getString("token_prod", "");
}

void configurarWiFi() {
    WiFiManager wm;
    wm.setConfigPortalTimeout(180);

    if (!wm.autoConnect("EstacaoMeteo-Config")) {
        Serial.println("Falha ao conectar WiFi. Reiniciando em 3s...");
        delay(3000);
        ESP.restart();
    }

    Serial.print("WiFi conectado! Acesse a pagina de administracao em: http://");
    Serial.println(WiFi.localIP());
}

//====================================================
// PAGINA DE ADMINISTRACAO
//====================================================
void configurarServidorAdmin() {
    servidorAdmin.on("/", HTTP_GET, []() {
        String html = "<!DOCTYPE html><html lang='pt-BR'><head><meta charset='UTF-8'>";
        html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
        html += "<title>Estacao Meteorologica - Config</title>";
        html += "<style>body{font-family:Arial,sans-serif;max-width:600px;margin:2rem auto;padding:0 1rem;background:#f4f4f4;}";
        html += ".card{background:#fff;border-radius:8px;padding:1.5rem;margin-bottom:1rem;box-shadow:0 1px 3px rgba(0,0,0,.1);}";
        html += "label{display:block;font-weight:bold;margin-top:1rem;font-size:.9rem;}";
        html += "input{width:100%;padding:.5rem;margin-top:.3rem;box-sizing:border-box;border:1px solid #ccc;border-radius:4px;}";
        html += "button{margin-top:1.5rem;padding:.7rem 1.5rem;background:#1f2937;color:#fff;border:none;border-radius:4px;cursor:pointer;}";
        html += ".status{font-size:.85rem;color:#555;}</style></head><body>";
        html += "<h1>Estacao Meteorologica &mdash; Administracao</h1>";

        html += "<div class='card status'><strong>Status atual</strong><br>";
        html += "IP: " + WiFi.localIP().toString() + "<br>";
        if (eepromDisponivel) {
            html += "Fila pendente (EEPROM): " + String(totalRegistros) + " / " + String(MAX_REGISTROS) + "<br>";
        } else {
            html += "Fila (RAM, sem EEPROM): " + String(registroPendenteRAMValido ? "1 pendente" : "vazia") + "<br>";
        }
        html += "Sensores: SHT41=" + String(sht4Disponivel ? "sim" : "nao");
        html += " | BME280=" + String(bmeDisponivel ? "sim" : "nao");
        html += " | BMP280=" + String(bmpDisponivel ? "sim" : "nao");
        html += " | AHT10=" + String(ahtDisponivel ? "sim" : "nao");
        html += " | ENS160=" + String(ens160Disponivel ? "sim" : "nao");
        html += " | RTC=" + String(rtcDisponivel ? "sim" : "nao");
        html += " | EEPROM=" + String(eepromDisponivel ? "sim" : "nao") + "<br>";
        html += "Fonte de ambiente atual: " + fonteAmbienteAtual + "<br>";
        html += "Descartes (faixa invalida): " + String(leiturasDescartadasFaixa) + "<br>";
        html += "Ultimo envio local: " + ultimoStatusLocal + "<br>";
        html += "Ultimo envio producao: " + ultimoStatusProducao + "</div>";

        html += "<form class='card' method='POST' action='/salvar'><strong>Servidores</strong>";
        html += "<label>URL do servidor LOCAL</label><input name='local_url' value='" + servidorUrlLocal + "'>";
        html += "<label>Token da estacao LOCAL</label><input name='local_token' value='" + tokenLocal + "'>";
        html += "<label>URL do servidor de PRODUCAO</label><input name='prod_url' value='" + servidorUrlProducao + "'>";
        html += "<label>Token da estacao de PRODUCAO</label><input name='prod_token' value='" + tokenProducao + "'>";
        html += "<button type='submit'>Salvar configuracao</button></form>";

        html += "</body></html>";
        servidorAdmin.send(200, "text/html; charset=utf-8", html);
    });

    servidorAdmin.on("/salvar", HTTP_POST, []() {
        servidorUrlLocal = servidorAdmin.arg("local_url");
        tokenLocal = servidorAdmin.arg("local_token");
        servidorUrlProducao = servidorAdmin.arg("prod_url");
        tokenProducao = servidorAdmin.arg("prod_token");

        preferencias.putString("server_local", servidorUrlLocal);
        preferencias.putString("token_local", tokenLocal);
        preferencias.putString("server_prod", servidorUrlProducao);
        preferencias.putString("token_prod", tokenProducao);

        servidorAdmin.sendHeader("Location", "/");
        servidorAdmin.send(303);
    });

    servidorAdmin.begin();
}
