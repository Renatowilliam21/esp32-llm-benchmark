#include <cmath>

struct Acumulador {
    float soma;
    unsigned int quantidade;
    void adicionar(float valor);
    float media() const;
    void limpar();
};

void Acumulador::adicionar(float valor) {
    if (!isnan(valor)) {
        soma += valor;
        quantidade++;
    }
}

float Acumulador::media() const {
    if (quantidade == 0) {
        return NAN;
    }
    return soma / quantidade;
}

void Acumulador::limpar() {
    soma = 0.0f;
    quantidade = 0;
}