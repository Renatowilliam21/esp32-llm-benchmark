float calcularIndiceCalor(float temperaturaC, float umidadeRelativa) {
    if (temperaturaC < 26.7f) {
        return temperaturaC;
    }

    const float T = temperaturaC * 9.0f / 5.0f + 32.0f;
    const float RH = umidadeRelativa;

    const float hiF =
        -42.379f +
        2.04901523f * T +
        10.14333127f * RH -
        0.22475541f * T * RH -
        0.00683783f * T * T -
        0.05481717f * RH * RH +
        0.00122874f * T * T * RH +
        0.00085282f * T * RH * RH -
        0.00000199f * T * T * RH * RH;

    const float hiC = (hiF - 32.0f) * 5.0f / 9.0f;

    if (hiC < -50.0f || hiC > 100.0f) {
        return NAN;
    }

    return hiC;
}