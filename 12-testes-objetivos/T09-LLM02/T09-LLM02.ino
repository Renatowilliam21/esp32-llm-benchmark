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

    String obtido = classificarIndiceCalor(entrada);

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
    Serial.println("T09 - classificarIndiceCalor");
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
        27.0f,
        "normal"
    );

    // CT03
    caso(
        "CT03",
        27.01f,
        "atencao"
    );

    // CT04
    caso(
        "CT04",
        32.0f,
        "atencao"
    );

    // CT05
    caso(
        "CT05",
        32.01f,
        "atencao_extrema"
    );

    // CT06
    caso(
        "CT06",
        41.0f,
        "atencao_extrema"
    );

    // CT07
    caso(
        "CT07",
        41.01f,
        "perigo"
    );

    // CT08
    caso(
        "CT08",
        54.0f,
        "perigo"
    );

    // CT09
    caso(
        "CT09",
        54.01f,
        "perigo_extremo"
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
