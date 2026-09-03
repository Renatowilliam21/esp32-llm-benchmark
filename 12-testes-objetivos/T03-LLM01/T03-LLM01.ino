#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

// ============================================================
// CÃ³digo candidato - preservado sem alteraÃ§Ã£o
// ============================================================

#include "candidato.inc"

// ============================================================
// Infraestrutura de testes
// ============================================================

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
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T03 - detectarEeprom");
    Serial.println("======================================");

    // ========================================================
    // CT01
    // ACK em 0x50 -> true
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 0;

    bool r1 = detectarEeprom();

    bool ct01 =
        (r1 == true) &&
        (Wire.ultimoEndereco == 0x50);

    verificarCaso("CT01", ct01);


    // ========================================================
    // CT02
    // NACK -> false
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 2;

    bool r2 = detectarEeprom();

    bool ct02 =
        (r2 == false);

    verificarCaso("CT02", ct02);


    // ========================================================
    // CT03
    // deve iniciar transmissÃ£o em 0x50
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 4;

    detectarEeprom();

    bool ct03 =
        (Wire.ultimoEndereco == 0x50);

    verificarCaso("CT03", ct03);


    // ========================================================
    // Resultado
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
