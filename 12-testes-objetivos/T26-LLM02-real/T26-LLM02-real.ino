#include <Arduino.h>
#include <math.h>
#include <RTClib.h>

// ============================================================
// Estruturas reais
// ============================================================

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
        if (quantidade == 0) {
            return NAN;
        }

        return soma / quantidade;
    }

    void limpar() {
        soma = 0;
        quantidade = 0;
    }
};

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

// ============================================================
// Acumuladores globais reais
// ============================================================

Acumulador acTempGloboNegro;
Acumulador acUmidGloboNegro;

Acumulador acTempAr;
Acumulador acUmidAr;

Acumulador acPressao;
Acumulador acAltitude;

Acumulador acUV;
Acumulador acLDR;

Acumulador acCo2;
Acumulador acTvoc;
Acumulador acAqi;

// ============================================================
// RTC e estado global real
// ============================================================

RTC_DS3231 rtc;

bool rtcDisponivel = false;
bool eepromDisponivel = false;

const int MAX_REGISTROS = 50;

int totalRegistros = 0;
int proximoRegistro = 0;

RegistroMeteorologico registroPendenteRAM;
bool registroPendenteRAMValido = false;

// ============================================================
// Chuva e vento
// ============================================================

const float MM_POR_PULSO_CHUVA = 0.5f;
const float CONSTANTE_ANEMOMETRO = 2.4f;

const unsigned long INTERVALO_AGREGACAO_MS = 60000UL;

volatile unsigned long pulsosChuvaContador = 0;
volatile unsigned long pulsosVentoContador = 0;

// ============================================================
// Funcoes reais utilizadas pela tarefa
// ============================================================

float calcularPontoOrvalho(
    float temperatura,
    float umidade
) {
    float a = 17.27f;
    float b = 237.7f;

    float alpha =
        ((a * temperatura) / (b + temperatura)) +
        log(umidade / 100.0f);

    return (b * alpha) / (a - alpha);
}

float calcularITGU(
    float temperatura,
    float umidade
) {
    return temperatura +
           (0.36f * calcularPontoOrvalho(temperatura, umidade)) +
           41.5f;
}

float calcularITU(
    float temperatura,
    float umidade
) {
    return (0.8f * temperatura) +
           ((umidade / 100.0f) * (temperatura - 14.3f)) +
           46.3f;
}

float calcularIndiceCalor(
    float temperatura,
    float umidade
) {
    if (temperatura < 26.7f) {
        return temperatura;
    }

    float T = temperatura * 9.0f / 5.0f + 32.0f;
    float RH = umidade;

    float HI =
        -42.379f +
        (2.04901523f * T) +
        (10.14333127f * RH) -
        (0.22475541f * T * RH) -
        (0.00683783f * T * T) -
        (0.05481717f * RH * RH) +
        (0.00122874f * T * T * RH) +
        (0.00085282f * T * RH * RH) -
        (0.00000199f * T * T * RH * RH);

    float resultado =
        (HI - 32.0f) * 5.0f / 9.0f;

    if (resultado < -50.0f || resultado > 100.0f) {
        return NAN;
    }

    return resultado;
}

// ============================================================
// Contratos reais da persistencia
// ============================================================

void gravarRegistro(
    int indice,
    RegistroMeteorologico registro
) {
    (void)indice;
    (void)registro;
}

void salvarControleEEPROM() {
}

// ============================================================
// CANDIDATO ORIGINAL
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link
// ============================================================

void setup() {
    Serial.begin(115200);

    gravarRegistroPendente();
}

void loop() {
}
