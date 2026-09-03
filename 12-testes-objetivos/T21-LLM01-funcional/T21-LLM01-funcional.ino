#include <Arduino.h>

/*
 * ==========================================================
 * ESTADO DOS MOCKS
 * ==========================================================
 */

int benchmarkSerialBegin = 0;
unsigned long benchmarkSerialBaud = 0;

int benchmarkPinModeChamadas = 0;
bool benchmarkPluvInputPullup = false;
bool benchmarkAnemoInputPullup = false;

int benchmarkAttachChamadas = 0;
bool benchmarkPluvISRCorreta = false;
bool benchmarkAnemoISRCorreta = false;

int benchmarkWdtInit = 0;
int benchmarkWdtReconfigure = 0;
int benchmarkWdtAdd = 0;

int benchmarkInicializarSensores = 0;
int benchmarkDetectarEeprom = 0;
int benchmarkCarregarControle = 0;
int benchmarkCarregarConfiguracao = 0;
int benchmarkConfigurarWiFi = 0;
int benchmarkConfigurarServidor = 0;

int benchmarkSequencia = 0;
int ordemDetectar = 0;
int ordemCarregarControle = 0;

bool benchmarkEepromDisponivel = true;

/*
 * ==========================================================
 * PINOS OFICIAIS
 * ==========================================================
 */

const uint8_t PINO_PLUVIOMETRO = 25;
const uint8_t PINO_ANEMOMETRO  = 26;

/*
 * ==========================================================
 * SERIAL MOCK
 * ==========================================================
 */

class BenchmarkSerialClass {
public:
    void begin(unsigned long baud) {
        benchmarkSerialBegin++;
        benchmarkSerialBaud = baud;
    }
};

BenchmarkSerialClass benchmarkSerial;

/*
 * ==========================================================
 * GPIO MOCK
 * ==========================================================
 */

void benchmarkPinMode(
    uint8_t pin,
    uint8_t mode
) {

    benchmarkPinModeChamadas++;

    if (
        pin == PINO_PLUVIOMETRO &&
        mode == INPUT_PULLUP
    ) {
        benchmarkPluvInputPullup = true;
    }

    if (
        pin == PINO_ANEMOMETRO &&
        mode == INPUT_PULLUP
    ) {
        benchmarkAnemoInputPullup = true;
    }
}

/*
 * ==========================================================
 * ISRs OFICIAIS
 * ==========================================================
 */

void isrPluviometro() {}
void isrAnemometro() {}

/*
 * ==========================================================
 * INTERRUPCOES MOCK
 * ==========================================================
 */

int benchmarkDigitalPinToInterrupt(uint8_t pin) {
    return pin;
}

void benchmarkAttachInterrupt(
    int pin,
    void (*func)(),
    int mode
) {

    benchmarkAttachChamadas++;

    if (
        pin == PINO_PLUVIOMETRO &&
        func == isrPluviometro &&
        mode == FALLING
    ) {
        benchmarkPluvISRCorreta = true;
    }

    if (
        pin == PINO_ANEMOMETRO &&
        func == isrAnemometro &&
        mode == FALLING
    ) {
        benchmarkAnemoISRCorreta = true;
    }
}

/*
 * ==========================================================
 * Wire
 * ==========================================================
 */

#include "Wire.h"

BenchmarkWireClass Wire;

/*
 * ==========================================================
 * AUXILIARES
 * ==========================================================
 */

void inicializarSensores() {
    benchmarkInicializarSensores++;
}

bool detectarEeprom() {

    benchmarkDetectarEeprom++;

    benchmarkSequencia++;
    ordemDetectar = benchmarkSequencia;

    return benchmarkEepromDisponivel;
}

void carregarControleEEPROM() {

    benchmarkCarregarControle++;

    benchmarkSequencia++;
    ordemCarregarControle = benchmarkSequencia;
}

void carregarConfiguracao() {
    benchmarkCarregarConfiguracao++;
}

void configurarWiFi() {
    benchmarkConfigurarWiFi++;
}

void configurarServidorAdmin() {
    benchmarkConfigurarServidor++;
}

/*
 * ==========================================================
 * INTERCEPTACOES
 * ==========================================================
 */

#define Serial benchmarkSerial

#define pinMode(pin, mode) \
    benchmarkPinMode(pin, mode)

#define digitalPinToInterrupt(pin) \
    benchmarkDigitalPinToInterrupt(pin)

#define attachInterrupt(pin, func, mode) \
    benchmarkAttachInterrupt(pin, func, mode)

/*
 * Renomeia somente durante a inclusÃ£o.
 *
 * candidato.inc permanece fisicamente inalterado.
 */
#define setup setupCandidato

#include "candidato.inc"

#undef setup
#undef Serial
#undef pinMode
#undef digitalPinToInterrupt
#undef attachInterrupt

/*
 * ==========================================================
 * RESULTADOS
 * ==========================================================
 */

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(
    const char *id,
    bool aprovado
) {

    casosExecutados++;

    Serial0.print(id);
    Serial0.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void setup() {

    Serial0.begin(115200);
    delay(4000);

    Serial0.println();
    Serial0.println("======================================");
    Serial0.println("ESP32-LLM BENCHMARK");
    Serial0.println("T21 - setup");
    Serial0.println("======================================");

    /*
     * CenÃ¡rio congelado:
     * EEPROM disponÃ­vel.
     */
    benchmarkEepromDisponivel = true;

    /*
     * Executa explicitamente o setup gerado pela LLM.
     */
    setupCandidato();

    // ======================================================
    // CT01
    // Boot normal / integraÃ§Ã£o
    // ======================================================

    bool ct01 =
        benchmarkSerialBegin >= 1 &&
        benchmarkSerialBaud == 115200 &&
        benchmarkPluvInputPullup &&
        benchmarkAnemoInputPullup &&
        benchmarkPluvISRCorreta &&
        benchmarkAnemoISRCorreta &&
        benchmarkWdtInit >= 1 &&
        benchmarkWdtAdd >= 1 &&
        Wire.chamadasBegin >= 1 &&
        benchmarkInicializarSensores >= 1 &&
        benchmarkCarregarConfiguracao >= 1 &&
        benchmarkConfigurarWiFi >= 1 &&
        benchmarkConfigurarServidor >= 1;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    // EEPROM disponÃ­vel
    // ======================================================

    bool ct02 =
        benchmarkDetectarEeprom >= 1 &&
        benchmarkCarregarControle >= 1 &&
        ordemDetectar > 0 &&
        ordemCarregarControle > ordemDetectar;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    // GPIO + interrupÃ§Ãµes
    // ======================================================

    bool ct03 =
        benchmarkPluvInputPullup &&
        benchmarkAnemoInputPullup &&
        benchmarkPluvISRCorreta &&
        benchmarkAnemoISRCorreta;

    registrar("CT03", ct03);

    // ======================================================
    // CT04
    // Watchdog
    // ======================================================

    bool ct04 =
        benchmarkWdtInit >= 1 &&
        benchmarkWdtAdd >= 1;

    registrar("CT04", ct04);

    Serial0.println();

    Serial0.print("CASOS_APROVADOS=");
    Serial0.println(casosAprovados);

    Serial0.print("CASOS_EXECUTADOS=");
    Serial0.println(casosExecutados);

    Serial0.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void loop() {
}
