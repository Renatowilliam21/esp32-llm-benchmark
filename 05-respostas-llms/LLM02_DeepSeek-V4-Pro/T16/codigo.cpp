#include <math.h>

float calcularIndiceCalor(float temperaturaC, float umidadeRelativa) {
    if (temperaturaC < 26.7f) {
        return temperaturaC;
    }

    float tempF = temperaturaC * 9.0f / 5.0f + 32.0f;

    float indiceF = -42.379f
                  + 2.04901523f * tempF
                  + 10.14333127f * umidadeRelativa
                  - 0.22475541f * tempF * umidadeRelativa
                  - 0.00683783f * tempF * tempF
                  - 0.05481717f * umidadeRelativa * umidadeRelativa
                  + 0.00122874f * tempF * tempF * umidadeRelativa
                  + 0.00085282f * tempF * umidadeRelativa * umidadeRelativa
                  - 0.00000199f * tempF * tempF * umidadeRelativa * umidadeRelativa;

    float indiceC = (indiceF - 32.0f) * 5.0f / 9.0f;

    if (indiceC < -50.0f || indiceC > 100.0f) {
        return NAN;
    }

    return indiceC;
}