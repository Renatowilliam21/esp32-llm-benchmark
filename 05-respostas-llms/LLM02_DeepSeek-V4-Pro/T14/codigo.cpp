void lerPressaoAltitude(float &pressaoHpa, float &altitudeM) {
  float pressaoPa = NAN;
  bool sensorUsavel = false;

  if (bmeDisponivel && bmeSaudavel) {
    pressaoPa = bme.readPressure();
    sensorUsavel = true;
  } else if (bmpDisponivel && bmpSaudavel) {
    pressaoPa = bmp.readPressure();
    sensorUsavel = true;
  }

  if (!sensorUsavel) {
    pressaoHpa = NAN;
    altitudeM = NAN;
    return;
  }

  float pressaoHpaCalculada = pressaoPa / 100.0f;

  if (isnan(pressaoHpaCalculada) || pressaoHpaCalculada < PRESSAO_MIN_VALIDA || pressaoHpaCalculada > PRESSAO_MAX_VALIDA) {
    pressaoHpa = NAN;
    altitudeM = NAN;
    return;
  }

  pressaoHpa = pressaoHpaCalculada;
  altitudeM = 44330.0f * (1.0f - powf(pressaoHpaCalculada / 1013.25f, 0.1903f));
}