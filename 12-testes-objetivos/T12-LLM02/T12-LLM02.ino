#include <Arduino.h>

/*
 * Contexto fornecido pelo sistema original.
 * VariÃ¡veis compartilhadas com ISR sÃ£o volatile.
 */
volatile unsigned long pulsosAnemometro = 0;
volatile unsigned long ultimoPulsoAnemometro = 0;

/*
 * RelÃ³gio determinÃ­stico do benchmark.
 */
unsigned long benchmarkMillisAtual = 0;

unsigned long benchmarkMillis() {
    return benchmarkMillisAtual;
}

/*
 * Substitui millis() apenas durante a inclusÃ£o
 * do cÃ³digo candidato.
 */
#define millis() benchmarkMillis()

#include "candidato.inc"

#undef millis

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(
    const char *id,
    bool aprovado
) {
    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    }
    else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T12 - isrAnemometro");
    Serial.println("======================================");

    /*
     * CT01
     * ultimoPulso=0
     * millis=100
     *
     * Esperado:
     * contador incrementa
     * ultimoPulso=100
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 0;
    benchmarkMillisAtual = 100;

    isrAnemometro();

    registrar(
        "CT01",
        pulsosAnemometro == 1 &&
        ultimoPulsoAnemometro == 100
    );

    /*
     * CT02
     * ultimoPulso=100
     * millis=105
     *
     * diferenÃ§a = 5
     * condiÃ§Ã£o Ã© > 5
     *
     * Esperado: rejeitar
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 100;
    benchmarkMillisAtual = 105;

    isrAnemometro();

    registrar(
        "CT02",
        pulsosAnemometro == 0 &&
        ultimoPulsoAnemometro == 100
    );

    /*
     * CT03
     * ultimoPulso=100
     * millis=106
     *
     * diferenÃ§a = 6
     *
     * Esperado: aceitar
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 100;
    benchmarkMillisAtual = 106;

    isrAnemometro();

    registrar(
        "CT03",
        pulsosAnemometro == 1 &&
        ultimoPulsoAnemometro == 106
    );

    Serial.println();

    Serial.print("CASOS_RUNTIME_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_RUNTIME_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.println("FIM_RUNTIME=1");
}

void loop() {
}
