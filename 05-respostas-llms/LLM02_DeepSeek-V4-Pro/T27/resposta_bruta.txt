#include <ArduinoJson.h>
#include <math.h>

String montarJSON(const RegistroMeteorologico &r) {
  DynamicJsonDocument doc(2048);

  doc["tipo_agregacao"] = "agregado";

  if (!isnan(r.temperatura)) doc["temperatura"] = r.temperatura;
  if (!isnan(r.umidade)) doc["umidade"] = r.umidade;
  if (!isnan(r.pressao)) doc["pressao"] = r.pressao;
  if (!isnan(r.altitude)) doc["altitude"] = r.altitude;
  if (!isnan(r.velocidade_vento)) doc["velocidade_vento"] = r.velocidade_vento;
  if (!isnan(r.direcao_vento)) doc["direcao_vento"] = r.direcao_vento;
  if (!isnan(r.rajada_vento)) doc["rajada_vento"] = r.rajada_vento;
  if (!isnan(r.radiacao_solar)) doc["radiacao_solar"] = r.radiacao_solar;
  if (!isnan(r.indice_uv)) doc["indice_uv"] = r.indice_uv;
  if (!isnan(r.precipitacao)) doc["precipitacao"] = r.precipitacao;

  if (!isnan(r.itgu)) {
    doc["itgu"] = r.itgu;
    doc["itgu_classificacao"] = classificar(r.itgu, "ITGU");
  }

  if (!isnan(r.itu)) {
    doc["itu"] = r.itu;
    doc["itu_classificacao"] = classificar(r.itu, "ITU");
  }

  if (!isnan(r.indice_calor)) {
    doc["indice_calor"] = r.indice_calor;
    doc["indice_calor_classificacao"] = classificarIndiceCalor(r.indice_calor);
  }

  if (!isnan(r.aqi)) {
    doc["aqi"] = (int)round(r.aqi);
  }

  if (r.ano > 0) {
    char buffer[20];
    snprintf(buffer, sizeof(buffer), "%04d-%02d-%02d %02d:%02d:%02d",
             r.ano, r.mes, r.dia, r.hora, r.minuto, r.segundo);
    doc["registrado_em"] = buffer;
  }

  String json;
  serializeJson(doc, json);
  return json;
}