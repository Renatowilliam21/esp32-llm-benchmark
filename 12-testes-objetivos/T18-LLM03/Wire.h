#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t enderecoBegin = 0;
    uint8_t enderecoRequest = 0;

    uint8_t bytes[10];
    int quantidadeBytes = 0;

    uint8_t quantidadeSolicitada = 0;

    bool disponivel = false;
    uint8_t valorLeitura = 0;

    int chamadasBegin = 0;
    int chamadasEnd = 0;
    int chamadasRequest = 0;
    int chamadasRead = 0;

    bool ultimoStop = true;

    void reset() {
        enderecoBegin = 0;
        enderecoRequest = 0;

        quantidadeBytes = 0;
        quantidadeSolicitada = 0;

        disponivel = false;
        valorLeitura = 0;

        chamadasBegin = 0;
        chamadasEnd = 0;
        chamadasRequest = 0;
        chamadasRead = 0;

        ultimoStop = true;

        for (int i = 0; i < 10; i++) {
            bytes[i] = 0;
        }
    }

    void beginTransmission(uint8_t endereco) {
        enderecoBegin = endereco;
        chamadasBegin++;
    }

    size_t write(uint8_t valor) {
        if (quantidadeBytes < 10) {
            bytes[quantidadeBytes++] = valor;
        }
        return 1;
    }

    uint8_t endTransmission() {
        chamadasEnd++;
        ultimoStop = true;
        return 0;
    }

    uint8_t endTransmission(bool stop) {
        chamadasEnd++;
        ultimoStop = stop;
        return 0;
    }

    uint8_t requestFrom(uint8_t endereco, uint8_t quantidade) {
        enderecoRequest = endereco;
        quantidadeSolicitada = quantidade;
        chamadasRequest++;

        return disponivel ? quantidade : 0;
    }

    int available() {
        return disponivel ? 1 : 0;
    }

    int read() {
        chamadasRead++;
        return valorLeitura;
    }
};

extern MockWire Wire;

#endif
