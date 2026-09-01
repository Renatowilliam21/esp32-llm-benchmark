String montarJSON(const RegistroMeteorologico &r) {
    DynamicJsonDocument doc(1024);

    doc["tipo_agregacao"] = "agregado";

    if (!isnan(r.temperatura)) doc["temperatura"] = r.temperatura;
    if (!isnan(r.umidade)) doc["umidade"] = r.umidade;
    if (!isnan(r.pressao)) doc["pressao"] = r.pressao;
    if (!isnan(r.altitude)) doc["altitude"] = r.altitude;

    if (!isnan(r.itgu)) {
        doc["itgu"] = r.itgu;
        doc["classificacao_itgu"] = classificar(r.itgu);
    }

    if (!isnan(r.itu)) {
        doc["itu"] = r.itu;
        doc["classificacao_itu"] = classificar(r.itu);
    }

    if (!isnan(r.indiceCalor)) {
        doc["indice_calor"] = r.indiceCalor;
        doc["classificacao_indice_calor"] = classificarIndiceCalor(r.indiceCalor);
    }

    if (!isnan(r.aqi)) {
        doc["aqi"] = static_cast<long>(lroundf(r.aqi));
    }

    if (r.ano > 0) {
        char dataHora[20];
        snprintf(
            dataHora,
            sizeof(dataHora),
            "%04d-%02d-%02d %02d:%02d:%02d",
            r.ano,
            r.mes,
            r.dia,
            r.hora,
            r.minuto,
            r.segundo
        );
        doc["registrado_em"] = dataHora;
    }

    String json;
    serializeJson(doc, json);
    return json;
}