#include <Arduino.h>

/*
 * T19 - calcularChecksum
 *
 * O campo checksum permanece obrigatoriamente por ultimo.
 * A estrutura e zerada antes de cada uso para evitar que
 * bytes de padding nao inicializados interfiram nos testes.
 */

struct RegistroMeteorologico {
    uint32_t timestamp;
    float temperatura;
    float umidade;
    float pressao;
    uint16_t chuva;
    uint16_t vento;
    uint32_t checksum;
};

#define TAM_REGISTRO sizeof(RegistroMeteorologico)

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

RegistroMeteorologico criarRegistroBase() {

    RegistroMeteorologico r = {};

    r.timestamp   = 123456789UL;
    r.temperatura = 28.5f;
    r.umidade     = 65.0f;
    r.pressao     = 1012.3f;
    r.chuva       = 17;
    r.vento       = 42;
    r.checksum    = 0;

    return r;
}

/*
 * Implementacao de referencia congelada para CT04.
 *
 * Percorre exatamente todos os bytes anteriores ao campo
 * checksum e aplica:
 *
 * soma = (soma * 31) + byte
 */
uint32_t checksumReferencia(const RegistroMeteorologico &registro) {

    const uint8_t *dados =
        reinterpret_cast<const uint8_t *>(&registro);

    uint32_t soma = 0;

    const size_t tamanhoDados =
        TAM_REGISTRO - sizeof(uint32_t);

    for (size_t i = 0; i < tamanhoDados; i++) {
        soma = (soma * 31U) + dados[i];
    }

    return soma;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T19 - calcularChecksum");
    Serial.println("======================================");

    // ======================================================
    // CT01 - determinismo
    // Mesmo registro duas vezes deve gerar o mesmo checksum.
    // ======================================================

    RegistroMeteorologico r1 = criarRegistroBase();

    uint32_t c1a = calcularChecksum(r1);
    uint32_t c1b = calcularChecksum(r1);

    bool ct01 = (c1a == c1b);

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - sensibilidade aos dados
    // Alterar um byte dos dados deve alterar o checksum.
    // ======================================================

    RegistroMeteorologico r2a = criarRegistroBase();
    RegistroMeteorologico r2b = r2a;

    uint8_t *dadosR2 =
        reinterpret_cast<uint8_t *>(&r2b);

    dadosR2[0] ^= 0x01;

    uint32_t c2a = calcularChecksum(r2a);
    uint32_t c2b = calcularChecksum(r2b);

    bool ct02 = (c2a != c2b);

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - campo checksum excluido
    // Alterar apenas o proprio checksum nao pode mudar
    // o checksum calculado.
    // ======================================================

    RegistroMeteorologico r3a = criarRegistroBase();
    RegistroMeteorologico r3b = r3a;

    r3a.checksum = 0x00000000UL;
    r3b.checksum = 0xDEADBEEFUL;

    uint32_t c3a = calcularChecksum(r3a);
    uint32_t c3b = calcularChecksum(r3b);

    bool ct03 = (c3a == c3b);

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - algoritmo conhecido
    //
    // O resultado da funcao candidata deve ser exatamente
    // igual ao algoritmo congelado:
    //
    // soma = (soma * 31) + byte
    //
    // em todos os bytes de:
    // TAM_REGISTRO - sizeof(uint32_t)
    // ======================================================

    RegistroMeteorologico r4 = criarRegistroBase();

    /*
     * Valor propositalmente diferente de zero para garantir
     * que o campo checksum seja realmente ignorado.
     */
    r4.checksum = 0xA5A5A5A5UL;

    uint32_t esperadoCT04 = checksumReferencia(r4);
    uint32_t obtidoCT04   = calcularChecksum(r4);

    bool ct04 = (obtidoCT04 == esperadoCT04);

    registrar("CT04", ct04);

    Serial.println();

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void loop() {
}
