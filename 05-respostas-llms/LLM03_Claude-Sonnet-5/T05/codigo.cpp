bool faixaValida(float valor, float minimo, float maximo) {
    if (isnan(valor)) {
        return false;
    }
    return valor >= minimo && valor <= maximo;
}