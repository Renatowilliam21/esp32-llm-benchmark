bool faixaValida(float valor, float minimo, float maximo) {
    return !isnan(valor) && valor >= minimo && valor <= maximo;
}