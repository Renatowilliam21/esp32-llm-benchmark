#include <math.h>

float calcularITGU(float temperaturaC, float umidadeRelativa) {
    const float a = 17.27f;
    const float b = 237.7f;
    float alfa = logf(umidadeRelativa / 100.0f) +
                 (a * temperaturaC) / (b + temperaturaC);
    float pontoOrvalho = (b * alfa) / (a - alfa);

    return temperaturaC + 0.36f * pontoOrvalho + 41.5f;
}