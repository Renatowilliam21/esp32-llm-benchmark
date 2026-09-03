bool passaTesteDegrau(float novoValor, float &ultimoValor, float limite, unsigned long &contadorRejeicoes) {
    if (isnan(ultimoValor) || fabs(novoValor - ultimoValor) <= limite) {
        ultimoValor = novoValor;
        return true;
    }

    ++contadorRejeicoes;
    return false;
}