#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(
    float obtido,
    float esperado,
    float tolerancia = 0.01f
) {
    return fabs(obtido - esperado) <= tolerancia;
}

void caso(
    const char *id,
    float obtido,
    float esperado
) {

    casosExecutados++;

    bool aprovado =
        quaseIgual(
            obtido,
            esperado,
            0.01f
        );

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
    Serial.println(
        "======================================"
    );

    Serial.println(
        "ESP32-LLM BENCHMARK"
    );

    Serial.println(
        "T07 - calcularITGU"
    );

    Serial.println(
        "======================================"
    );

    // CT01
    caso(
        "CT01",
        calcularITGU(
            20.0f,
            50.0f
        ),
        64.8315f
    );

    // CT02
    caso(
        "CT02",
        calcularITGU(
            25.0f,
            60.0f
        ),
        72.5063f
    );

    // CT03
    caso(
        "CT03",
        calcularITGU(
            30.0f,
            70.0f
        ),
        80.1094f
    );

    // CT04
    caso(
        "CT04",
        calcularITGU(
            35.0f,
            80.0f
        ),
        87.6660f
    );

    Serial.println();

    Serial.println(
        "======================================"
    );

    Serial.print(
        "CASOS_APROVADOS="
    );

    Serial.println(
        casosAprovados
    );

    Serial.print(
        "CASOS_EXECUTADOS="
    );

    Serial.println(
        casosExecutados
    );

    Serial.print(
        "RESULTADO="
    );

    if (
        casosAprovados ==
        casosExecutados
    ) {

        Serial.println("PASS");

    } else {

        Serial.println("FAIL");
    }

    Serial.println(
        "======================================"
    );
}

void loop() {
}
