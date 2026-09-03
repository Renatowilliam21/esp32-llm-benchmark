#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t enderecoI2C = 0;
    uint8_t bytes[10];
    int quantidadeBytes = 0;
    int chamadasBegin = 0;
    int chamadasEnd = 0;

    void reset() {
        enderecoI2C = 0;
        quantidadeBytes = 0;
        chamadasBegin = 0;
        chamadasEnd = 0;

        for (int i = 0; i < 10; i++) {
            bytes[i] = 0;
        }
    }

    void beginTransmission(uint8_t endereco) {
        enderecoI2C = endereco;
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
        return 0;
    }
};

extern MockWire Wire;

#endif
