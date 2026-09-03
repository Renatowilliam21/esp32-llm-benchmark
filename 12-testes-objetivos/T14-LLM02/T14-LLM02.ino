#include <Arduino.h>
#include <math.h>

/*
 * Faixa fornecida pelo contexto da aplicaÃ§Ã£o.
 * Para o benchmark interessa principalmente o comportamento
 * dentro e fora dos limites.
 */
const float PRESSAO_MIN_VALIDA = 300.0f;
const float PRESSAO_MAX_VALIDA = 1100.0f;

/*
 * Mock comum para BME/BMP.
 *
 * Possui as duas formas de readAltitude() para permitir
 * compilar respostas que utilizem ambas as assinaturas.
 */
class MockSensorPressao {
public:

    float pressaoPa = 100000.0f;
    float altitudeConfigurada = 0.0f;

    int chamadasPressao = 0;
    int chamadasAltitudeSemParametro = 0;
    int chamadasAltitudeComParametro = 0;

    float ultimoParametroAltitude = NAN;

    void reset() {
        pressaoPa = 100000.0f;
        altitudeConfigurada = 0.0f;

        chamadasPressao = 0;
        chamadasAltitudeSemParametro = 0;
        chamadasAltitudeComParametro = 0;

        ultimoParametroAltitude = NAN;
    }

    float readPressure() {
        chamadasPressao++;
        return pressaoPa;
    }

    float readAltitude() {
        chamadasAltitudeSemParametro++;
        return altitudeConfigurada;
    }

    float readAltitude(float parametro) {
        chamadasAltitudeComParametro++;
        ultimoParametroAltitude = parametro;
        return altitudeConfigurada;
    }
};

MockSensorPressao bme;
MockSensorPressao bmp;

bool bmeDisponivel = false;
bool bmeSaudavel = false;

bool bmpDisponivel = false;
bool bmpSaudavel = false;

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
    if (isnan(a) || isnan(b)) {
        return false;
    }

    return fabsf(a - b) <= tolerancia;
}

void registrar(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    }
    else {
        Serial.println("FAIL");
    }
}

void resetarTudo() {

    bme.reset();
    bmp.reset();

    bmeDisponivel = false;
    bmeSaudavel = false;

    bmpDisponivel = false;
    bmpSaudavel = false;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T14 - lerPressaoAltitude");
    Serial.println("======================================");

    float pressao = NAN;
    float altitude = NAN;

    // ======================================================
    // CT01 - Prioridade BME
    //
    // BME disponÃ­vel/saudÃ¡vel e BMP disponÃ­vel.
    // Esperado:
    // - usar BME
    // - pressÃ£o BME convertida Pa -> hPa
    // - altitude fornecida pelo BME
    // ======================================================

    resetarTudo();

    bmeDisponivel = true;
    bmeSaudavel = true;

    bmpDisponivel = true;
    bmpSaudavel = true;

    bme.pressaoPa = 100000.0f;       // 1000 hPa
    bme.altitudeConfigurada = 123.45f;

    bmp.pressaoPa = 95000.0f;
    bmp.altitudeConfigurada = 987.65f;

    pressao = NAN;
    altitude = NAN;

    lerPressaoAltitude(pressao, altitude);

    bool ct01 =
        quaseIgual(pressao, 1000.0f) &&
        quaseIgual(altitude, 123.45f) &&
        bme.chamadasPressao == 1 &&
        bmp.chamadasPressao == 0;

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Fallback BMP
    //
    // BME indisponÃ­vel; BMP disponÃ­vel.
    // Esperado:
    // pressÃ£o e altitude do BMP.
    // ======================================================

    resetarTudo();

    bmeDisponivel = false;
    bmeSaudavel = false;

    bmpDisponivel = true;
    bmpSaudavel = true;

    bmp.pressaoPa = 98000.0f;        // 980 hPa
    bmp.altitudeConfigurada = 222.22f;

    pressao = NAN;
    altitude = NAN;

    lerPressaoAltitude(pressao, altitude);

    bool ct02 =
        quaseIgual(pressao, 980.0f) &&
        quaseIgual(altitude, 222.22f) &&
        bmp.chamadasPressao == 1 &&
        bme.chamadasPressao == 0;

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - Sem sensor
    //
    // BME e BMP indisponÃ­veis.
    // Esperado:
    // pressÃ£o = NaN
    // altitude = NaN
    // ======================================================

    resetarTudo();

    pressao = 123.0f;
    altitude = 456.0f;

    lerPressaoAltitude(pressao, altitude);

    bool ct03 =
        isnan(pressao) &&
        isnan(altitude);

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - PressÃ£o invÃ¡lida
    //
    // Sensor disponÃ­vel, mas pressÃ£o abaixo do mÃ­nimo.
    // Esperado:
    // pressÃ£o = NaN
    // altitude = NaN
    // ======================================================

    resetarTudo();

    bmeDisponivel = true;
    bmeSaudavel = true;

    bme.pressaoPa =
        (PRESSAO_MIN_VALIDA - 1.0f) * 100.0f;

    bme.altitudeConfigurada = 999.0f;

    pressao = 123.0f;
    altitude = 456.0f;

    lerPressaoAltitude(pressao, altitude);

    bool ct04 =
        isnan(pressao) &&
        isnan(altitude);

    registrar("CT04", ct04);

    Serial.println();

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial.println("PASS");
    }
    else {
        Serial.println("FAIL");
    }
}

void loop() {
}
