#include <Arduino.h>
#include <ArduinoJson.h>
#include <math.h>

// ============================================================
// Estrutura real do firmware
// ============================================================

struct RegistroMeteorologico {
    uint16_t ano;
    uint8_t mes, dia, hora, minuto, segundo;

    float tempGloboNegro, umidGloboNegro;
    float tempAr, umidAr;

    float pressao, altitude;
    float indiceUV, luminosidade;

    float co2, tvoc, aqi;

    float ITGU, ITU;
    float indiceCalor;

    float chuvaMm, velVento;

    bool enviado;
    uint32_t checksum;
};

// ============================================================
// Contratos reais utilizados pela tarefa
// ============================================================

String classificar(float indice) {
    if (isnan(indice)) return "";

    if (indice > 78.0f) return "perigo";
    if (indice > 72.0f) return "alerta";

    return "normal";
}

String classificarIndiceCalor(float indiceCalor) {
    if (isnan(indiceCalor)) return "";

    if (indiceCalor > 54.0f) return "perigo_extremo";
    if (indiceCalor > 41.0f) return "perigo";
    if (indiceCalor > 32.0f) return "atencao_extrema";
    if (indiceCalor > 27.0f) return "atencao";

    return "normal";
}

// ============================================================
// CANDIDATO ORIGINAL
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link
// ============================================================

void setup() {
    Serial.begin(115200);

    RegistroMeteorologico r = {};

    r.ano = 2026;
    r.mes = 8;
    r.dia = 31;
    r.hora = 20;
    r.minuto = 5;
    r.segundo = 9;

    r.tempGloboNegro = 30.0f;
    r.umidGloboNegro = 60.0f;
    r.tempAr = 28.0f;
    r.umidAr = 65.0f;
    r.pressao = 1013.25f;
    r.altitude = 100.0f;
    r.indiceUV = 5.0f;
    r.luminosidade = 500.0f;
    r.co2 = 450.0f;
    r.tvoc = 12.0f;
    r.aqi = 2.6f;
    r.ITGU = 78.0f;
    r.ITU = 74.0f;
    r.indiceCalor = 31.0f;
    r.chuvaMm = 1.0f;
    r.velVento = 2.4f;

    String json = montarJSON(r);

    Serial.println(json);
}

void loop() {
}
