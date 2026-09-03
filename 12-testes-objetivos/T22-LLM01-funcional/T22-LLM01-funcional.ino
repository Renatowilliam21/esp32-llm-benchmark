#include <Arduino.h>
#include "esp_task_wdt.h"

/*
 * ==========================================================
 * ESTADO CONTROLADO
 * ==========================================================
 */

unsigned long benchmarkAgora = 0;

unsigned long ultimaColeta = 0;
unsigned long ultimaAgregacao = 0;
unsigned long ultimaTentativaEnvio = 0;

const unsigned long INTERVALO_COLETA = 1000;
const unsigned long INTERVALO_AGREGACAO = 5000;
const unsigned long INTERVALO_ENVIO = 10000;

int benchmarkWdtReset = 0;

int chamadasHandleClient = 0;
int chamadasProcessarSerial = 0;

int chamadasColetar = 0;
int chamadasGravar = 0;
int chamadasDrenar = 0;

/*
 * ==========================================================
 * Wi-Fi
 * ==========================================================
 */

#include "WiFi.h"

BenchmarkWiFiClass WiFi;

/*
 * ==========================================================
 * SERVER MOCK
 * ==========================================================
 */

class BenchmarkServer {
public:
    void handleClient() {
        chamadasHandleClient++;
    }
};

BenchmarkServer server;

/*
 * ==========================================================
 * millis() CONTROLADO
 * ==========================================================
 */

unsigned long benchmarkMillis() {
    return benchmarkAgora;
}

/*
 * ==========================================================
 * FUNCOES DO FIRMWARE
 * ==========================================================
 */

void benchmarkProcessarComandosSeriais() {
    chamadasProcessarSerial++;
}

void benchmarkColetarAmostra() {
    chamadasColetar++;
}

void benchmarkGravarRegistroPendente() {
    chamadasGravar++;
}

void benchmarkTentarDrenarFila() {
    chamadasDrenar++;
}

/*
 * ==========================================================
 * INTERCEPTACOES
 * ==========================================================
 *
 * O arquivo candidato permanece byte a byte inalterado.
 */

#define millis benchmarkMillis

#define processarComandosSeriais \
    benchmarkProcessarComandosSeriais

#define coletarAmostra \
    benchmarkColetarAmostra

#define gravarRegistroPendente \
    benchmarkGravarRegistroPendente

#define tentarDrenarFila \
    benchmarkTentarDrenarFila

#define loop loopCandidato

#include "candidato.inc"

#undef loop
#undef millis
#undef processarComandosSeriais
#undef coletarAmostra
#undef gravarRegistroPendente
#undef tentarDrenarFila

/*
 * ==========================================================
 * UTILITARIOS
 * ==========================================================
 */

int casosAprovados = 0;
int casosExecutados = 0;

void registrarCaso(
    const char *id,
    bool resultado
) {

    casosExecutados++;

    Serial0.print(id);
    Serial0.print(" -> ");

    if (resultado) {
        casosAprovados++;
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void limparContadores() {

    benchmarkWdtReset = 0;

    chamadasHandleClient = 0;
    chamadasProcessarSerial = 0;

    chamadasColetar = 0;
    chamadasGravar = 0;
    chamadasDrenar = 0;

    WiFi.chamadasStatus = 0;
    WiFi.chamadasReconnect = 0;
}

/*
 * ==========================================================
 * SETUP DO HARNESS
 * ==========================================================
 */

void setup() {

    Serial0.begin(115200);

    /*
     * Tempo para a captura serial apos o upload/reset.
     */
    delay(4000);

    Serial0.println();
    Serial0.println("======================================");
    Serial0.println("ESP32-LLM BENCHMARK");
    Serial0.println("T22 - loop");
    Serial0.println("======================================");

    /*
     * ======================================================
     * CT01
     * Wi-Fi desconectado.
     * Deve tentar reconectar e retornar sem realizar
     * coleta, agregacao ou envio.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = false;

    benchmarkAgora = 20000;

    ultimaColeta = 0;
    ultimaAgregacao = 0;
    ultimaTentativaEnvio = 0;

    loopCandidato();

    bool ct01 =
        WiFi.chamadasReconnect >= 1 &&
        chamadasColetar == 0 &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0 &&
        ultimaColeta == 0 &&
        ultimaAgregacao == 0 &&
        ultimaTentativaEnvio == 0;

    registrarCaso("CT01", ct01);

    /*
     * ======================================================
     * CT02
     * Primeira coleta.
     *
     * ultimaColeta = 0 e intervalo de coleta atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_COLETA;

    ultimaColeta = 0;

    /*
     * Evita disparar agregacao e envio neste CT.
     */
    ultimaAgregacao = benchmarkAgora;
    ultimaTentativaEnvio = benchmarkAgora;

    loopCandidato();

    bool ct02 =
        chamadasColetar == 1 &&
        ultimaColeta == benchmarkAgora &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0;

    registrarCaso("CT02", ct02);

    /*
     * ======================================================
     * CT03
     * Intervalo de agregacao atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_AGREGACAO;

    ultimaColeta = benchmarkAgora;
    ultimaAgregacao = 0;
    ultimaTentativaEnvio = benchmarkAgora;

    loopCandidato();

    bool ct03 =
        chamadasGravar == 1 &&
        ultimaAgregacao == benchmarkAgora &&
        chamadasColetar == 0 &&
        chamadasDrenar == 0;

    registrarCaso("CT03", ct03);

    /*
     * ======================================================
     * CT04
     * Intervalo de envio atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_ENVIO;

    ultimaColeta = benchmarkAgora;
    ultimaAgregacao = benchmarkAgora;
    ultimaTentativaEnvio = 0;

    loopCandidato();

    bool ct04 =
        chamadasDrenar == 1 &&
        ultimaTentativaEnvio == benchmarkAgora &&
        chamadasColetar == 0 &&
        chamadasGravar == 0;

    registrarCaso("CT04", ct04);

    /*
     * ======================================================
     * CT05
     * Nenhum intervalo atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = 20000;

    ultimaColeta =
        benchmarkAgora - INTERVALO_COLETA + 1;

    ultimaAgregacao =
        benchmarkAgora - INTERVALO_AGREGACAO + 1;

    ultimaTentativaEnvio =
        benchmarkAgora - INTERVALO_ENVIO + 1;

    unsigned long coletaAntes = ultimaColeta;
    unsigned long agregacaoAntes = ultimaAgregacao;
    unsigned long envioAntes = ultimaTentativaEnvio;

    loopCandidato();

    bool ct05 =
        chamadasColetar == 0 &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0 &&
        ultimaColeta == coletaAntes &&
        ultimaAgregacao == agregacaoAntes &&
        ultimaTentativaEnvio == envioAntes;

    registrarCaso("CT05", ct05);

    /*
     * ======================================================
     * RESULTADO
     * ======================================================
     */

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
