#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

/*
 * InterceptaÃ§Ã£o determinÃ­stica de delay().
 */
unsigned long benchmarkDelayMs = 0;
int benchmarkChamadasDelay = 0;

void benchmarkDelay(unsigned long ms) {
    benchmarkDelayMs = ms;
    benchmarkChamadasDelay++;
}

#define delay(ms) benchmarkDelay(ms)

#include "candidato.inc"

#undef delay

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void resetarTudo() {
    Wire.reset();
    benchmarkDelayMs = 0;
    benchmarkChamadasDelay = 0;
}

void setup() {

    Serial.begin(115200);

    /*
     * Aqui usamos ::delay para garantir o delay real do harness,
     * pois a macro jÃ¡ foi removida apÃ³s candidato.inc.
     */
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T17 - escreverEEPROM");
    Serial.println("======================================");

    // ======================================================
    // CT01
    // endereco = 0x1234
    // valor    = 0xAB
    //
    // Esperado:
    // Wire.write recebe 0x12, 0x34, 0xAB nessa ordem.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct01 =
        Wire.quantidadeBytes == 3 &&
        Wire.bytes[0] == 0x12 &&
        Wire.bytes[1] == 0x34 &&
        Wire.bytes[2] == 0xAB;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    // beginTransmission deve utilizar 0x50.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct02 =
        Wire.chamadasBegin == 1 &&
        Wire.enderecoI2C == 0x50;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    // Deve existir espera de 5 ms apÃ³s endTransmission().
    //
    // Aqui verificamos:
    // - endTransmission chamado;
    // - delay chamado;
    // - valor exatamente 5 ms.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct03 =
        Wire.chamadasEnd == 1 &&
        benchmarkChamadasDelay == 1 &&
        benchmarkDelayMs == 5;

    registrar("CT03", ct03);

    Serial.println();

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
}

void loop() {
}
