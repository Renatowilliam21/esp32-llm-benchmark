#include <math.h>

float calcularPontoOrvalho(float temperaturaC, float umidadeRelativa) {
    const float a = 17.27;
    const float b = 237.7;
    float gamma = log(umidadeRelativa / 100.0) + (a * temperaturaC) / (b + temperaturaC);
    return (b * gamma) / (a - gamma);
}

float calcularITGU(float temperaturaC, float umidadeRelativa) {
    float pontoOrvalho = calcularPontoOrvalho(temperaturaC, umidadeRelativa);
    return temperaturaC + 0.36 * pontoOrvalho + 41.5;
}