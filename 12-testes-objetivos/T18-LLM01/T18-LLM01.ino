#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

#include "candidato.inc"

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

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T18 - lerEEPROM");
    Serial.println("======================================");

    // ======================================================
    // CT01
    //
    // endereco = 0x1234
    // available = true
    // read = 0xAB
    //
    // Esperado:
    // - escreve 0x12 e 0x34
    // - solicita 1 byte
    // - retorna 0xAB
    // ======================================================

    Wire.reset();

    Wire.disponivel = true;
    Wire.valorLeitura = 0xAB;

    uint8_t r1 = lerEEPROM(0x1234);

    bool ct01 =
        Wire.quantidadeBytes == 2 &&
        Wire.bytes[0] == 0x12 &&
        Wire.bytes[1] == 0x34 &&
        Wire.quantidadeSolicitada == 1 &&
        r1 == 0xAB;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    //
    // Nenhum byte disponÃ­vel.
    //
    // Esperado:
    // retorno = 0
    // ======================================================

    Wire.reset();

    Wire.disponivel = false;
    Wire.valorLeitura = 0xAB;

    uint8_t r2 = lerEEPROM(0x1234);

    bool ct02 =
        r2 == 0 &&
        Wire.chamadasRead == 0;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    //
    // Tanto beginTransmission quanto requestFrom
    // devem utilizar o endereÃ§o 0x50.
    // ======================================================

    Wire.reset();

    Wire.disponivel = true;
    Wire.valorLeitura = 0x55;

    lerEEPROM(0x1234);

    bool ct03 =
        Wire.enderecoBegin == 0x50 &&
        Wire.enderecoRequest == 0x50 &&
        Wire.quantidadeSolicitada == 1;

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
