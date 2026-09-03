#ifndef BENCHMARK_FAKE_WIRE_H
#define BENCHMARK_FAKE_WIRE_H

#include <Arduino.h>

class MockWireClass {
public:

    uint8_t enderecoBegin = 0;
    uint8_t registradorEscrito = 0;

    uint8_t enderecoRequest = 0;
    uint8_t quantidadeRequest = 0;

    uint8_t retornoEndTransmission = 0;
    uint8_t retornoRequestFrom = 1;

    int quantidadeDisponivel = 1;
    int valorLeitura = 0;

    int chamadasBeginTransmission = 0;
    int chamadasWrite = 0;
    int chamadasEndTransmission = 0;
    int chamadasRequestFrom = 0;
    int chamadasAvailable = 0;
    int chamadasRead = 0;

    bool ultimoStop = true;

    void reset() {

        enderecoBegin = 0;
        registradorEscrito = 0;

        enderecoRequest = 0;
        quantidadeRequest = 0;

        retornoEndTransmission = 0;
        retornoRequestFrom = 1;

        quantidadeDisponivel = 1;
        valorLeitura = 0;

        chamadasBeginTransmission = 0;
        chamadasWrite = 0;
        chamadasEndTransmission = 0;
        chamadasRequestFrom = 0;
        chamadasAvailable = 0;
        chamadasRead = 0;

        ultimoStop = true;
    }

    void beginTransmission(uint8_t endereco) {
        chamadasBeginTransmission++;
        enderecoBegin = endereco;
    }

    size_t write(uint8_t valor) {
        chamadasWrite++;
        registradorEscrito = valor;
        return 1;
    }

    uint8_t endTransmission(bool stopBit = true) {
        chamadasEndTransmission++;
        ultimoStop = stopBit;
        return retornoEndTransmission;
    }

    uint8_t requestFrom(uint8_t endereco, uint8_t quantidade) {
        chamadasRequestFrom++;
        enderecoRequest = endereco;
        quantidadeRequest = quantidade;
        return retornoRequestFrom;
    }

    int available() {
        chamadasAvailable++;
        return quantidadeDisponivel;
    }

    int read() {
        chamadasRead++;
        return valorLeitura;
    }
};

extern MockWireClass Wire;

#endif
