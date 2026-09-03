#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float obtido, float esperado) {
    return fabs(obtido - esperado) <= 0.01f;
}

void caso(const char *id, float obtido, float esperado) {

    casosExecutados++;

    bool aprovado = quaseIgual(obtido, esperado);

    Serial.print(id);
    Serial.print(": obtido=");
    Serial.print(obtido, 4);

    Serial.print(" esperado=");
    Serial.print(esperado, 4);

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
    Serial.println("T08 - calcularITU");
    Serial.println("======================================");

    // CT01
    caso(
        "CT01",
        calcularITU(20.0f, 50.0f),
        65.1500f
    );

    // CT02
    caso(
        "CT02",
        calcularITU(25.0f, 60.0f),
        72.7200f
    );

    // CT03
    caso(
        "CT03",
        calcularITU(30.0f, 70.0f),
        81.2900f
    );

    // CT04
    caso(
        "CT04",
        calcularITU(35.0f, 80.0f),
        90.8600f
    );

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
