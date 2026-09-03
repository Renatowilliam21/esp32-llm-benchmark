#include <Arduino.h>
#include <string.h>

/*
 * Contexto padronizado T20.
 *
 * checksum Ã© uint32_t e Ãºltimo campo,
 * coerente com T19 e com o prompt oficial.
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

const uint16_t ENDERECO_DADOS = 100;
const uint16_t TAM_REGISTRO = sizeof(RegistroMeteorologico);

const int EEPROM_MOCK_SIZE = 4096;

uint8_t memoriaEEPROM[EEPROM_MOCK_SIZE];

uint32_t enderecosLidos[256];
int quantidadeLeituras = 0;

/*
 * Mesmo algoritmo oficial de T19.
 */
uint32_t calcularChecksum(const RegistroMeteorologico &registro) {

    const uint8_t *bytes =
        reinterpret_cast<const uint8_t *>(&registro);

    const size_t tamanho =
        sizeof(RegistroMeteorologico) - sizeof(uint32_t);

    uint32_t soma = 0;

    for (size_t i = 0; i < tamanho; ++i) {
        soma = (soma * 31U) + bytes[i];
    }

    return soma;
}

/*
 * Mock de leitura da EEPROM.
 */
uint8_t lerEEPROM(uint16_t endereco) {

    if (quantidadeLeituras < 256) {
        enderecosLidos[quantidadeLeituras] = endereco;
    }

    quantidadeLeituras++;

    if (endereco >= EEPROM_MOCK_SIZE) {
        return 0;
    }

    return memoriaEEPROM[endereco];
}

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

void limparMock() {

    memset(memoriaEEPROM, 0, sizeof(memoriaEEPROM));

    quantidadeLeituras = 0;

    for (int i = 0; i < 256; i++) {
        enderecosLidos[i] = 0;
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

    r.checksum = calcularChecksum(r);

    return r;
}

void gravarMock(
    uint16_t indice,
    const RegistroMeteorologico &registro
) {

    uint32_t inicio =
        ENDERECO_DADOS +
        static_cast<uint32_t>(indice) * TAM_REGISTRO;

    const uint8_t *dados =
        reinterpret_cast<const uint8_t *>(&registro);

    for (size_t i = 0;
         i < sizeof(RegistroMeteorologico);
         i++) {

        memoriaEEPROM[inicio + i] = dados[i];
    }
}

bool registrosIguais(
    const RegistroMeteorologico &a,
    const RegistroMeteorologico &b
) {
    return memcmp(
        &a,
        &b,
        sizeof(RegistroMeteorologico)
    ) == 0;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T20 - lerRegistro");
    Serial.println("======================================");

    // ======================================================
    // CT01 - Registro Ã­ntegro
    // ======================================================

    limparMock();

    RegistroMeteorologico original1 =
        criarRegistroBase();

    gravarMock(0, original1);

    RegistroMeteorologico lido1 = {};

    bool retorno1 =
        lerRegistro(0, lido1);

    bool ct01 =
        retorno1 &&
        registrosIguais(original1, lido1);

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Registro corrompido
    //
    // ApÃ³s gravar um registro vÃ¡lido,
    // altera-se um byte dos dados antes do checksum.
    // ======================================================

    limparMock();

    RegistroMeteorologico original2 =
        criarRegistroBase();

    gravarMock(0, original2);

    /*
     * Corrompe primeiro byte do timestamp.
     */
    memoriaEEPROM[ENDERECO_DADOS] ^= 0x01;

    RegistroMeteorologico lido2 = {};

    bool retorno2 =
        lerRegistro(0, lido2);

    bool ct02 =
        (retorno2 == false);

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - EndereÃ§o Ã­ndice 0
    // ======================================================

    limparMock();

    RegistroMeteorologico original3 =
        criarRegistroBase();

    gravarMock(0, original3);

    RegistroMeteorologico lido3 = {};

    lerRegistro(0, lido3);

    bool ct03 =
        quantidadeLeituras > 0 &&
        enderecosLidos[0] == ENDERECO_DADOS;

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - EndereÃ§o Ã­ndice N
    //
    // N = 3
    // ======================================================

    limparMock();

    const uint16_t indiceN = 3;

    RegistroMeteorologico original4 =
        criarRegistroBase();

    gravarMock(indiceN, original4);

    RegistroMeteorologico lido4 = {};

    lerRegistro(indiceN, lido4);

    uint32_t enderecoEsperado =
        ENDERECO_DADOS +
        static_cast<uint32_t>(indiceN) * TAM_REGISTRO;

    bool ct04 =
        quantidadeLeituras > 0 &&
        enderecosLidos[0] == enderecoEsperado;

    registrar("CT04", ct04);

    // ======================================================
    // CT05 - Cobertura
    //
    // Deve ler exatamente TAM_REGISTRO bytes.
    // ======================================================

    limparMock();

    RegistroMeteorologico original5 =
        criarRegistroBase();

    gravarMock(0, original5);

    RegistroMeteorologico lido5 = {};

    lerRegistro(0, lido5);

    bool ct05 =
        quantidadeLeituras == TAM_REGISTRO;

    registrar("CT05", ct05);

    Serial.println();

    Serial.print("TAM_REGISTRO=");
    Serial.println(TAM_REGISTRO);

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
