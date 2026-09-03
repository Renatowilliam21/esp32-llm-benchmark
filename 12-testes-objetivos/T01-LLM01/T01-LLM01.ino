#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int testesExecutados = 0;
int testesAprovados = 0;

void verificarCaso(const char *id, bool condicao) {

    testesExecutados++;

    Serial.print(id);
    Serial.print(": ");

    if (condicao) {
        testesAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T01 - passaTesteDegrau");
    Serial.println("======================================");

    // ========================================================
    // CT01
    // ultimo = NaN; novo = 25.0
    // esperado: true e ultimo = 25.0
    // ========================================================

    {
        float ultimoValor = NAN;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                25.0f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct01 =
            (retorno == true) &&
            (fabs(ultimoValor - 25.0f) < 0.001f);

        verificarCaso("CT01", ct01);
    }

    // ========================================================
    // CT02
    // ultimo = 25.0; novo = 28.0; limite = 3.0
    // esperado: true e ultimo = 28.0
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                28.0f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct02 =
            (retorno == true) &&
            (fabs(ultimoValor - 28.0f) < 0.001f);

        verificarCaso("CT02", ct02);
    }

    // ========================================================
    // CT03
    // ultimo = 25.0; novo = 28.1; limite = 3.0
    // esperado: false, ultimo permanece 25.0,
    // contador de rejeicoes incrementa
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                28.1f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct03 =
            (retorno == false) &&
            (fabs(ultimoValor - 25.0f) < 0.001f) &&
            (rejeicoes == 1);

        verificarCaso("CT03", ct03);
    }

    // ========================================================
    // CT04
    // ultimo = 25.0; novo = 21.9; limite = 3.0
    // esperado: false
    // testa diferenca absoluta
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                21.9f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct04 =
            (retorno == false) &&
            (fabs(ultimoValor - 25.0f) < 0.001f) &&
            (rejeicoes == 1);

        verificarCaso("CT04", ct04);
    }

    Serial.println();
    Serial.println("======================================");

    Serial.print("TESTES_APROVADOS=");
    Serial.println(testesAprovados);

    Serial.print("TESTES_EXECUTADOS=");
    Serial.println(testesExecutados);

    Serial.print("RESULTADO=");

    if (testesAprovados == testesExecutados) {
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }

    Serial.println("======================================");
}

void loop() {
}
