#ifndef BENCHMARK_WIRE_H
#define BENCHMARK_WIRE_H

class BenchmarkWireClass {
public:
    int chamadasBegin = 0;

    void begin() {
        chamadasBegin++;
    }
};

extern BenchmarkWireClass Wire;

#endif
