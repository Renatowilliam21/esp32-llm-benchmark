#include <math.h>

struct Acumulador {
    float soma = 0.0f;
    unsigned int quantidade = 0;

    void adicionar(float valor) {
        if (!isnan(valor)) {
            soma += valor;
            quantidade++;
        }
    }

    float media() const {
        return quantidade == 0 ? NAN : soma / quantidade;
    }

    void limpar() {
        soma = 0.0f;
        quantidade = 0;
    }
};