#include <cmath>

struct Acumulador {
    float soma;
    unsigned int quantidade;

    void adicionar(float valor) {
        if (isnan(valor)) {
            return;
        }
        soma += valor;
        quantidade++;
    }

    float media() const {
        if (quantidade == 0) {
            return NAN;
        }
        return soma / quantidade;
    }

    void limpar() {
        soma = 0;
        quantidade = 0;
    }
};