#include <Arduino.h>
#include <math.h>

// CÃ³digo original da LLM
#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float obtido, float esperado, float tolerancia = 0.01f) {
    return fabs(obtido - esperado) <= tolerancia;
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
    Serial.println("T06 - calcularPontoOrvalho");
    Serial.println("======================================");

    // CT01
    caso(
        "CT01",
        calcularPontoOrvalho(20.0f, 50.0f),
        9.2543f
    );

    // CT02
    caso(
        "CT02",
        calcularPontoOrvalho(25.0f, 60.0f),
        16.6842f
    );

    // CT03
    caso(
        "CT03",
        calcularPontoOrvalho(30.0f, 70.0f),
        23.9150f
    );

    // CT04
    caso(
        "CT04",
        calcularPontoOrvalho(35.0f, 80.0f),
        31.0167f
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
