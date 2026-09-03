#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t ultimoEndereco = 0;
    uint8_t retornoEndTransmission = 0;

    void beginTransmission(uint8_t endereco) {
        ultimoEndereco = endereco;
    }

    uint8_t endTransmission() {
        return retornoEndTransmission;
    }
};

extern MockWire Wire;

#endif
