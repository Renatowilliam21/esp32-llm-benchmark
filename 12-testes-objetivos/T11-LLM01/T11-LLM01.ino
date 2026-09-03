#include <Arduino.h>

/*
 * Contexto original da aplicaÃ§Ã£o:
 * variÃ¡veis compartilhadas com ISR sÃ£o volatile.
 */
volatile unsigned long pulsosPluviometro = 0;
volatile unsigned long ultimoPulsoPluviometro = 0;

/*
 * Controle determinÃ­stico do tempo.
 */
unsigned long benchmarkMillisAtual = 0;

unsigned long benchmarkMillis() {
    return benchmarkMillisAtual;
}

/*
 * Durante a inclusÃ£o do candidato, millis()
 * Ã© substituÃ­do pelo relÃ³gio controlado do benchmark.
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
    Serial.println("T11 - isrPluviometro");
    Serial.println("======================================");

    /*
     * CT01
     * ultimoPulso=0
     * millis=100
     *
     * Esperado:
     * contador +1
     * ultimoPulso=100
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 0;
    benchmarkMillisAtual = 100;

    isrPluviometro();

    registrar(
        "CT01",
        pulsosPluviometro == 1 &&
        ultimoPulsoPluviometro == 100
    );

    /*
     * CT02
     * ultimoPulso=100
     * millis=115
     *
     * diferenÃ§a = 15
     * condiÃ§Ã£o deve ser > 15
     *
     * Esperado: rejeitar.
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 100;
    benchmarkMillisAtual = 115;

    isrPluviometro();

    registrar(
        "CT02",
        pulsosPluviometro == 0 &&
        ultimoPulsoPluviometro == 100
    );

    /*
     * CT03
     * ultimoPulso=100
     * millis=116
     *
     * diferenÃ§a = 16
     *
     * Esperado: aceitar.
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 100;
    benchmarkMillisAtual = 116;

    isrPluviometro();

    registrar(
        "CT03",
        pulsosPluviometro == 1 &&
        ultimoPulsoPluviometro == 116
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
