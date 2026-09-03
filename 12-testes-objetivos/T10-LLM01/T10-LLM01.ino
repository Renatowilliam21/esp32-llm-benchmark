#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

void caso(
    const char *id,
    float entrada,
    const char *esperado
) {
    casosExecutados++;

    String obtido = classificar(entrada);

    bool aprovado = (obtido == String(esperado));

    Serial.print(id);
    Serial.print(": obtido=\"");
    Serial.print(obtido);
    Serial.print("\" esperado=\"");
    Serial.print(esperado);
    Serial.print("\" -> ");

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
    Serial.println("T10 - classificar");
    Serial.println("======================================");

    // CT01
    caso(
        "CT01",
        NAN,
        ""
    );

    // CT02
    caso(
        "CT02",
        72.0f,
        "normal"
    );

    // CT03
    caso(
        "CT03",
        72.01f,
        "alerta"
    );

    // CT04
    caso(
        "CT04",
        78.0f,
        "alerta"
    );

    // CT05
    caso(
        "CT05",
        78.01f,
        "perigo"
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
