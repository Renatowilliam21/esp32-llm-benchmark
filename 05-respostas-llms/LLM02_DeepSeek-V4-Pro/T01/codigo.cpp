#include <math.h>

bool passaTesteDegrau(float novoValor, float &ultimoValor, float limite, unsigned long &contadorRejeicoes) {
    if (isnan(ultimoValor)) {
        ultimoValor = novoValor;
        return true;
    }
    if (fabs(novoValor - ultimoValor) <= limite) {
        ultimoValor = novoValor;
        return true;
    }
    contadorRejeicoes++;
    return false;
}