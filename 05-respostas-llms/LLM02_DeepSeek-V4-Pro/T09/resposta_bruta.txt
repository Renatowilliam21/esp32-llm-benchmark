String classificarIndiceCalor(float indiceCalor) {
  if (isnan(indiceCalor)) {
    return String();
  }
  if (indiceCalor <= 27.0f) {
    return "normal";
  } else if (indiceCalor <= 32.0f) {
    return "atencao";
  } else if (indiceCalor <= 41.0f) {
    return "atencao_extrema";
  } else if (indiceCalor <= 54.0f) {
    return "perigo";
  } else {
    return "perigo_extremo";
  }
}