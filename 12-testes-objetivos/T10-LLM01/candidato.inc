String classificar(float indice) {
    if (isnan(indice)) {
        return String();
    }
    if (indice <= 72.0f) {
        return String("normal");
    }
    if (indice <= 78.0f) {
        return String("alerta");
    }
    return String("perigo");
}