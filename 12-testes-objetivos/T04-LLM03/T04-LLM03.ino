#include <Arduino.h>
#include <math.h>

// ============================================================
// Mock de analogRead
// ============================================================

int adcSimulado = 0;
int ultimoPinoLido = -1;

int mockAnalogRead(int pino) {
    ultimoPinoLido = pino;
    return adcSimulado;
}

#define analogRead mockAnalogRead

// CÃ³digo original da LLM
#include "candidato.inc"

#undef analogRead

// ============================================================
// Infraestrutura
// ============================================================

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
    return fabs(a - b) <= tolerancia;
}

void caso(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(": ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    const int PINO_TESTE = 35;

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T04 - lerUV");
    Serial.println("======================================");


    // ========================================================
    // CT01 - ADC mÃ­nimo
    // ADC=0 -> UV=0.0
    // ========================================================

    adcSimulado = 0;
    ultimoPinoLido = -1;

    float uv1 = lerUV(PINO_TESTE);

    caso(
        "CT01",
        quaseIgual(uv1, 0.0f)
    );


    // ========================================================
    // CT02 - ADC intermediÃ¡rio
    // ADC=2048 -> UV aproximadamente 16.504
    // ========================================================

    adcSimulado = 2048;

    float uv2 = lerUV(PINO_TESTE);

    caso(
        "CT02",
        quaseIgual(uv2, 16.504f)
    );


    // ========================================================
    // CT03 - ADC mÃ¡ximo
    // ADC=4095 -> UV=33.0
    // ========================================================

    adcSimulado = 4095;

    float uv3 = lerUV(PINO_TESTE);

    caso(
        "CT03",
        quaseIgual(uv3, 33.0f)
    );


    // ========================================================
    // CT04 - NÃ£o-negatividade
    // Um ADC vÃ¡lido 0..4095 nunca pode produzir valor negativo.
    // Percorremos todo o domÃ­nio do ADC de 12 bits.
    // ========================================================

    bool naoNegativo = true;

    for (int adc = 0; adc <= 4095; adc++) {

        adcSimulado = adc;

        float uv = lerUV(PINO_TESTE);

        if (uv < 0.0f) {
            naoNegativo = false;
            break;
        }
    }

    caso(
        "CT04",
        naoNegativo
    );


    // ========================================================
    // Resultado
    // ========================================================

    Serial.println();
    Serial.println("======================================");

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }

    Serial.println("======================================");
}

void loop() {
}
