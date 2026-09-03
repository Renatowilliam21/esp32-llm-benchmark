#include <Arduino.h>

/*
 * Contexto padronizado do benchmark.
 */
const int PIN_LDR = 34;

bool vemlDisponivel = false;

/*
 * Mock do VEML7700.
 */
class MockVEML7700 {
public:
    float luxConfigurado = 0.0f;
    int chamadasReadLux = 0;

    void reset() {
        luxConfigurado = 0.0f;
        chamadasReadLux = 0;
    }

    float readLux() {
        chamadasReadLux++;
        return luxConfigurado;
    }
};

MockVEML7700 veml;

/*
 * Mock determinÃ­stico do ADC.
 */
int benchmarkADC = 0;
int chamadasAnalogRead = 0;
int ultimoPinoAnalogico = -1;

int benchmarkAnalogRead(int pino) {
    chamadasAnalogRead++;
    ultimoPinoAnalogico = pino;
    return benchmarkADC;
}

#define analogRead(pino) benchmarkAnalogRead(pino)

#include "candidato.inc"

#undef analogRead

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
    return fabsf(a - b) <= tolerancia;
}

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

void resetarTudo() {

    veml.reset();

    vemlDisponivel = false;

    benchmarkADC = 0;
    chamadasAnalogRead = 0;
    ultimoPinoAnalogico = -1;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T15 - lerLDR");
    Serial.println("======================================");

    // ======================================================
    // CT01 - Digital prioritÃ¡rio
    //
    // VEML disponÃ­vel
    // readLux = 450.5
    //
    // Esperado:
    // retorna 450.5
    // nÃ£o usa ADC
    // ======================================================

    resetarTudo();

    vemlDisponivel = true;
    veml.luxConfigurado = 450.5f;

    benchmarkADC = 1234;

    float r1 = lerLDR();

    bool ct01 =
        quaseIgual(r1, 450.5f) &&
        veml.chamadasReadLux == 1 &&
        chamadasAnalogRead == 0;

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Fallback ADC mÃ­nimo
    //
    // VEML indisponÃ­vel
    // ADC = 0
    //
    // map(0,4095,100,0) = 100
    // ======================================================

    resetarTudo();

    vemlDisponivel = false;
    benchmarkADC = 0;

    float r2 = lerLDR();

    bool ct02 =
        quaseIgual(r2, 100.0f) &&
        chamadasAnalogRead == 1 &&
        ultimoPinoAnalogico == PIN_LDR;

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - Fallback ADC mÃ¡ximo
    //
    // VEML indisponÃ­vel
    // ADC = 4095
    //
    // Esperado: 0
    // ======================================================

    resetarTudo();

    vemlDisponivel = false;
    benchmarkADC = 4095;

    float r3 = lerLDR();

    bool ct03 =
        quaseIgual(r3, 0.0f) &&
        chamadasAnalogRead == 1 &&
        ultimoPinoAnalogico == PIN_LDR;

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - Prioridade
    //
    // VEML disponÃ­vel e ADC tambÃ©m configurado.
    // Resultado deve vir do VEML7700.
    // ======================================================

    resetarTudo();

    vemlDisponivel = true;
    veml.luxConfigurado = 321.75f;

    benchmarkADC = 4095;

    float r4 = lerLDR();

    bool ct04 =
        quaseIgual(r4, 321.75f) &&
        veml.chamadasReadLux == 1 &&
        chamadasAnalogRead == 0;

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
