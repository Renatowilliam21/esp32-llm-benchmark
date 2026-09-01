String classificarIndiceCalor(float indiceCalor) {
    if (isnan(indiceCalor)) {
        return String();
    }
    if (indiceCalor <= 27.0f) {
        return String("normal");
    }
    if (indiceCalor <= 32.0f) {
        return String("atencao");
    }
    if (indiceCalor <= 41.0f) {
        return String("atencao_extrema");
    }
    if (indiceCalor <= 54.0f) {
        return String("perigo");
    }
    return String("perigo_extremo");
}