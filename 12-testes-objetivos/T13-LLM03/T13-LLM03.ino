#include <Arduino.h>
#include "Wire.h"

MockWireClass Wire;

#include "candidato.inc"

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
    Serial.println("T13 - identificarChipBmx");
    Serial.println("======================================");

    const uint8_t enderecoTeste = 0x76;

    // ======================================================
    // CT01
    // Falha em endTransmission(false)
    // Esperado: retorna 0
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 4;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    uint8_t r1 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT01",
        r1 == 0
    );

    // ======================================================
    // CT02
    // TransmissÃ£o OK, porÃ©m available() = false.
    //
    // requestFrom() retorna 1 para representar que a
    // solicitaÃ§Ã£o I2C foi realizada. Entretanto nenhum byte
    // estÃ¡ disponÃ­vel para leitura.
    //
    // Esperado: retorna 0.
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 0;

    /*
     * Valor sentinela proposital.
     * Caso uma implementaÃ§Ã£o faÃ§a read() sem verificar
     * available(), nÃ£o poderÃ¡ passar acidentalmente.
     */
    Wire.valorLeitura = 0xA5;

    uint8_t r2 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT02",
        r2 == 0
    );

    // ======================================================
    // CT03
    // CHIP ID BME280 = 0x60
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    uint8_t r3 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT03",
        r3 == 0x60
    );

    // ======================================================
    // CT04
    // CHIP ID BMP280 = 0x58
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x58;

    uint8_t r4 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT04",
        r4 == 0x58
    );

    // ======================================================
    // CT05
    // Contrato I2C:
    // - beginTransmission(endereco informado)
    // - write(0xD0)
    // - endTransmission(false)
    // - requestFrom(endereco, 1)
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    identificarChipBmx(enderecoTeste);

    bool contratoOK =
        Wire.chamadasBeginTransmission == 1 &&
        Wire.enderecoBegin == enderecoTeste &&
        Wire.chamadasWrite == 1 &&
        Wire.registradorEscrito == 0xD0 &&
        Wire.chamadasEndTransmission == 1 &&
        Wire.ultimoStop == false &&
        Wire.chamadasRequestFrom == 1 &&
        Wire.enderecoRequest == enderecoTeste &&
        Wire.quantidadeRequest == 1;

    registrar(
        "CT05",
        contratoOK
    );

    Serial.println();

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial.println("PASS");
    }
    else {
        Serial.println("FAIL");
    }
}

void loop() {
}
