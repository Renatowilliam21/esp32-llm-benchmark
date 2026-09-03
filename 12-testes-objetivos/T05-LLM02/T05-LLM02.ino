#include <Arduino.h>
#include <math.h>

// CÃ³digo original gerado pela LLM
#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

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

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T05 - faixaValida");
    Serial.println("======================================");

    const float minimo = 0.0f;
    const float maximo = 10.0f;

    // CT01 - NaN
    caso(
        "CT01",
        faixaValida(NAN, minimo, maximo) == false
    );

    // CT02 - abaixo do mÃ­nimo
    caso(
        "CT02",
        faixaValida(-0.1f, minimo, maximo) == false
    );

    // CT03 - limite inferior
    caso(
        "CT03",
        faixaValida(0.0f, minimo, maximo) == true
    );

    // CT04 - limite superior
    caso(
        "CT04",
        faixaValida(10.0f, minimo, maximo) == true
    );

    // CT05 - acima do mÃ¡ximo
    caso(
        "CT05",
        faixaValida(10.1f, minimo, maximo) == false
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
