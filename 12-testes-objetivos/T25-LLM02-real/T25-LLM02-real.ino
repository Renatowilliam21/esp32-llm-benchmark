#include <Arduino.h>
#include <math.h>

// ============================================================
// Estrutura real de acumulacao
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

// ============================================================
// Acumuladores globais reais
// ============================================================

Acumulador acTempGloboNegro;
Acumulador acUmidGloboNegro;

Acumulador acTempAr;
Acumulador acUmidAr;

Acumulador acPressao;
Acumulador acAltitude;

Acumulador acCo2;
Acumulador acTvoc;
Acumulador acAqi;

Acumulador acUV;
Acumulador acLDR;

// ============================================================
// Contadores e estado reais relevantes
// ============================================================

unsigned long leiturasDescartadasFaixa = 0;

const float TEMP_MIN_VALIDA = -40.0f;
const float TEMP_MAX_VALIDA = 85.0f;

const float UMIDADE_MIN_VALIDA = 0.0f;
const float UMIDADE_MAX_VALIDA = 100.0f;

const float PRESSAO_MIN_VALIDA = 300.0f;
const float PRESSAO_MAX_VALIDA = 1100.0f;

const float UV_MAX_VALIDO = 20.0f;

const float DEGRAU_MAX_VARIACAO_C = 3.0f;

float ultimaTempGloboNegroValida = NAN;
float ultimaTempArValida = NAN;

unsigned long degrauRejeicoes = 0;

String fonteAmbienteAtual = "nenhuma";

// ============================================================
// Contratos reais das funcoes auxiliares
// ============================================================

bool faixaValida(float valor, float minimo, float maximo) {
    if (isnan(valor)) {
        return false;
    }

    return valor >= minimo && valor <= maximo;
}

bool passaTesteDegrau(
    float novoValor,
    float &ultimoValorValido
) {
    if (isnan(ultimoValorValido)) {
        ultimoValorValido = novoValor;
        return true;
    }

    if (fabs(novoValor - ultimoValorValido) <= DEGRAU_MAX_VARIACAO_C) {
        ultimoValorValido = novoValor;
        return true;
    }

    degrauRejeicoes++;
    return false;
}

void lerAmbiente(
    float &temperatura,
    float &umidade,
    float dhtTempJaLido,
    float dhtUmidJaLido
) {
    temperatura = dhtTempJaLido;
    umidade = dhtUmidJaLido;
}

void lerPressaoAltitude(
    float &pressao,
    float &altitude
) {
    pressao = 1013.25f;
    altitude = 100.0f;
}

void lerQualidadeAr(
    float &co2,
    float &tvoc,
    float &aqi
) {
    co2 = 500.0f;
    tvoc = 10.0f;
    aqi = 1.0f;
}

float lerUV() {
    return 1.0f;
}

float lerLDR() {
    return 50.0f;
}

// ============================================================
// CANDIDATO - COPIADO SEM ALTERACAO
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link da tarefa
// ============================================================

void setup() {
    Serial.begin(115200);

    // Forca referencia real a funcao solicitada.
    coletarAmostra();
}

void loop() {
}
