#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.02f) {
    return fabsf(a - b) <= tolerancia;
}

void registrar(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

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

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T16 - calcularIndiceCalor");
    Serial.println("======================================");

    // CT01
    // 20 C / 50%
    // Esperado ~= 20.0000
    float r1 = calcularIndiceCalor(20.0f, 50.0f);

    registrar(
        "CT01",
        quaseIgual(r1, 20.0000f)
    );

    // CT02
    // 26.6 C / 90%
    // Esperado ~= 26.6000
    float r2 = calcularIndiceCalor(26.6f, 90.0f);

    registrar(
        "CT02",
        quaseIgual(r2, 26.6000f)
    );

    // CT03
    // 30 C / 70%
    // Esperado ~= 35.0380
    float r3 = calcularIndiceCalor(30.0f, 70.0f);

    registrar(
        "CT03",
        quaseIgual(r3, 35.0380f)
    );

    // CT04
    // 35 C / 80%
    // Esperado ~= 56.5466
    float r4 = calcularIndiceCalor(35.0f, 80.0f);

    registrar(
        "CT04",
        quaseIgual(r4, 56.5466f)
    );

    // CT05
    // CenÃ¡rio cujo Ã­ndice calculado ultrapassa 100 C.
    // Deve retornar NaN.
    float r5 = calcularIndiceCalor(50.0f, 100.0f);

    registrar(
        "CT05",
        isnan(r5)
    );

    Serial.println();

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
}

void loop() {
}
