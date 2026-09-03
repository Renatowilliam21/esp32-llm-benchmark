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

bool quaseIgual(float a, float b, float tolerancia = 0.001f) {
    return fabs(a - b) <= tolerancia;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T02 - Acumulador");
    Serial.println("======================================");


    // ========================================================
    // CT01
    // adicionar 10, 20, 30
    // esperado: soma=60, quantidade=3, media=20
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(20.0f);
        a.adicionar(30.0f);

        bool ct01 =
            quaseIgual(a.soma, 60.0f) &&
            (a.quantidade == 3) &&
            quaseIgual(a.media(), 20.0f);

        verificarCaso("CT01", ct01);
    }


    // ========================================================
    // CT02
    // adicionar 10, NaN, 20
    // esperado: soma=30, quantidade=2, media=15
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(NAN);
        a.adicionar(20.0f);

        bool ct02 =
            quaseIgual(a.soma, 30.0f) &&
            (a.quantidade == 2) &&
            quaseIgual(a.media(), 15.0f);

        verificarCaso("CT02", ct02);
    }


    // ========================================================
    // CT03
    // acumulador novo
    // esperado: media = NaN
    // ========================================================

    {
        Acumulador a{};

        bool ct03 =
            isnan(a.media());

        verificarCaso("CT03", ct03);
    }


    // ========================================================
    // CT04
    // apos adicionar valores, limpar()
    // esperado: soma=0, quantidade=0, media=NaN
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(20.0f);

        a.limpar();

        bool ct04 =
            quaseIgual(a.soma, 0.0f) &&
            (a.quantidade == 0) &&
            isnan(a.media());

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
