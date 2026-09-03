void lerPressaoAltitude(float &pressaoHpa, float &altitudeM) {
    pressaoHpa = NAN;
    altitudeM = NAN;

    float pressaoPa;
    float altitudeLida;

    if (bmeDisponivel && bmeSaudavel) {
        pressaoPa = bme.readPressure();
        altitudeLida = bme.readAltitude();
    } else if (bmpDisponivel && bmpSaudavel) {
        pressaoPa = bmp.readPressure();
        altitudeLida = bmp.readAltitude();
    } else {
        return;
    }

    const float pressaoLidaHpa = pressaoPa / 100.0f;

    if (!isfinite(pressaoLidaHpa) ||
        pressaoLidaHpa < PRESSAO_MIN_VALIDA ||
        pressaoLidaHpa > PRESSAO_MAX_VALIDA) {
        return;
    }

    pressaoHpa = pressaoLidaHpa;
    altitudeM = altitudeLida;
}