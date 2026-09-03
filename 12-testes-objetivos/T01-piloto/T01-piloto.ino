#include <Arduino.h>
#include <math.h>

// ============================================================
// ESP32-LLM Benchmark
// Piloto de validação do harness - T01 passaTesteDegrau
// ============================================================

struct Acumulador {
    float ultimoValido;
    uint32_t rejeicoes;
};

// ------------------------------------------------------------
// CÓDIGO DO CANDIDATO
// Nesta primeira execução vamos usar uma implementação de
// referência apenas para validar o mecanismo de teste.
// ------------------------------------------------------------

bool passaTesteDegrau(
    float valor,
    Acumulador &a,
    float limite
) {
    if (isnan(a.ultimoValido)) {
        a.ultimoValido = valor;
        return true;
    }

    if (fabs(valor - a.ultimoValido) <= limite) {
        a.ultimoValido = valor;
        return true;
    }

    a.rejeicoes++;
    return false;
}

// ------------------------------------------------------------
// Infraestrutura do benchmark
// ------------------------------------------------------------

int testesExecutados = 0;
int testesAprovados = 0;

void verificar(
    const char *id,
    bool condicao
) {
    testesExecutados++;

    Serial.print(id);
    Serial.print(": ");

    if (condicao) {
        testesAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK - T01");
    Serial.println("Funcao: passaTesteDegrau");
    Serial.println("======================================");

    // CT01
    // Primeiro valor deve ser aceito quando ultimoValido = NaN.

    Acumulador a1 = {NAN, 0};

    bool r1 = passaTesteDegrau(25.0, a1, 2.0);

    verificar(
        "T01_CT01_retorno",
        r1 == true
    );

    verificar(
        "T01_CT01_atualizacao",
        fabs(a1.ultimoValido - 25.0) < 0.001
    );

    verificar(
        "T01_CT01_rejeicoes",
        a1.rejeicoes == 0
    );


    // CT02
    // Diferenca menor que o limite.

    Acumulador a2 = {25.0, 0};

    bool r2 = passaTesteDegrau(26.0, a2, 2.0);

    verificar(
        "T01_CT02_retorno",
        r2 == true
    );

    verificar(
        "T01_CT02_atualizacao",
        fabs(a2.ultimoValido - 26.0) < 0.001
    );


    // CT03
    // Diferenca exatamente igual ao limite deve ser aceita.

    Acumulador a3 = {25.0, 0};

    bool r3 = passaTesteDegrau(27.0, a3, 2.0);

    verificar(
        "T01_CT03_limite",
        r3 == true
    );

    verificar(
        "T01_CT03_atualizacao",
        fabs(a3.ultimoValido - 27.0) < 0.001
    );


    // CT04
    // Valor acima do limite deve ser rejeitado.

    Acumulador a4 = {25.0, 0};

    bool r4 = passaTesteDegrau(30.0, a4, 2.0);

    verificar(
        "T01_CT04_retorno",
        r4 == false
    );

    verificar(
        "T01_CT04_nao_atualiza",
        fabs(a4.ultimoValido - 25.0) < 0.001
    );

    verificar(
        "T01_CT04_rejeicoes",
        a4.rejeicoes == 1
    );


    // CT05
    // Teste com diferenca negativa.

    Acumulador a5 = {25.0, 0};

    bool r5 = passaTesteDegrau(20.0, a5, 2.0);

    verificar(
        "T01_CT05_retorno",
        r5 == false
    );

    verificar(
        "T01_CT05_nao_atualiza",
        fabs(a5.ultimoValido - 25.0) < 0.001
    );

    verificar(
        "T01_CT05_rejeicoes",
        a5.rejeicoes == 1
    );


    // --------------------------------------------------------
    // Resultado
    // --------------------------------------------------------

    Serial.println();
    Serial.println("======================================");

    Serial.print("TESTES_APROVADOS=");
    Serial.println(testesAprovados);

    Serial.print("TESTES_EXECUTADOS=");
    Serial.println(testesExecutados);

    Serial.print("RESULTADO=");

    if (testesAprovados == testesExecutados) {
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }

    Serial.println("======================================");
}

void loop() {
}