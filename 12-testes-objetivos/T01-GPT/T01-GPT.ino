#include <Arduino.h>
#include <math.h>

// ============================================================
// ESP32-LLM Benchmark
// T01 - passaTesteDegrau
// Código candidato incluído sem alteração de conteúdo
// ============================================================

#include "candidato.inc"

int testesExecutados = 0;
int testesAprovados = 0;

void verificar(const char *id, bool condicao) {
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
    // Primeiro valor: ultimoValor inicialmente NaN
    // ========================================================

    {
        float ultimoValor = NAN;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                25.0f,
                ultimoValor,
                2.0f,
                rejeicoes
            );

        verificar(
            "CT01_retorno",
            retorno == true
        );

        verificar(
            "CT01_ultimoValor",
            fabs(ultimoValor - 25.0f) < 0.001f
        );

        verificar(
            "CT01_rejeicoes",
            rejeicoes == 0
        );
    }


    // ========================================================
    // CT02
    // Diferença menor que o limite
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                26.0f,
                ultimoValor,
                2.0f,
                rejeicoes
            );

        verificar(
            "CT02_retorno",
            retorno == true
        );

        verificar(
            "CT02_ultimoValor",
            fabs(ultimoValor - 26.0f) < 0.001f
        );

        verificar(
            "CT02_rejeicoes",
            rejeicoes == 0
        );
    }


    // ========================================================
    // CT03
    // Diferença exatamente igual ao limite
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                27.0f,
                ultimoValor,
                2.0f,
                rejeicoes
            );

        verificar(
            "CT03_retorno",
            retorno == true
        );

        verificar(
            "CT03_ultimoValor",
            fabs(ultimoValor - 27.0f) < 0.001f
        );

        verificar(
            "CT03_rejeicoes",
            rejeicoes == 0
        );
    }


    // ========================================================
    // CT04
    // Diferença maior que o limite
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                30.0f,
                ultimoValor,
                2.0f,
                rejeicoes
            );

        verificar(
            "CT04_retorno",
            retorno == false
        );

        verificar(
            "CT04_ultimoValor",
            fabs(ultimoValor - 25.0f) < 0.001f
        );

        verificar(
            "CT04_rejeicoes",
            rejeicoes == 1
        );
    }


    // ========================================================
    // CT05
    // Degrau negativo maior que o limite
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                20.0f,
                ultimoValor,
                2.0f,
                rejeicoes
            );

        verificar(
            "CT05_retorno",
            retorno == false
        );

        verificar(
            "CT05_ultimoValor",
            fabs(ultimoValor - 25.0f) < 0.001f
        );

        verificar(
            "CT05_rejeicoes",
            rejeicoes == 1
        );
    }


    // ========================================================
    // RESUMO
    // ========================================================

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