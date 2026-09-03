#include <Arduino.h>
#include <math.h>

float calcularIndiceCalor(float temperaturaC, float umidadeRelativa) {
    if (temperaturaC < 26.7) {
        return temperaturaC;
    }

    float T = temperaturaC * 9.0 / 5.0 + 32.0;
    float RH = umidadeRelativa;

    float HI = -42.379
        + 2.04901523 * T
        + 10.14333127 * RH
        - 0.22475541 * T * RH
        - 0.00683783 * T * T
        - 0.05481717 * RH * RH
        + 0.00122874 * T * T * RH
        + 0.00085282 * T * RH * RH
        - 0.00000199 * T * T * RH * RH;

    float resultadoC = (HI - 32.0) * 5.0 / 9.0;

    if (resultadoC < -50.0 || resultadoC > 100.0) {
        return NAN;
    }

    return resultadoC;
}