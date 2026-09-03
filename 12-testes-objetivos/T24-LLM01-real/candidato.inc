void lerAmbiente(float &temperatura, float &umidade) {
    float temp = NAN;
    float umid = NAN;
    const char *novaFonte = "nenhuma";

    if (sht41Disponivel) {
        temp = sht41.readTemperature();
        umid = sht41.readHumidity();

        if (isfinite(temp) && isfinite(umid) &&
            temp >= -40.0f && temp <= 85.0f &&
            umid >= 0.0f && umid <= 100.0f) {
            novaFonte = "SHT41";
        }
    }

    if (novaFonte[0] == 'n' && bme280Disponivel) {
        temp = bme280.readTemperature();
        umid = bme280.readHumidity();

        if (isfinite(temp) && isfinite(umid) &&
            temp >= -40.0f && temp <= 85.0f &&
            umid >= 0.0f && umid <= 100.0f) {
            novaFonte = "BME280";
        }
    }

    if (novaFonte[0] == 'n' && aht10Disponivel) {
        temp = aht10.readTemperature();
        umid = aht10.readHumidity();

        if (isfinite(temp) && isfinite(umid) &&
            temp >= -40.0f && temp <= 85.0f &&
            umid >= 0.0f && umid <= 100.0f) {
            novaFonte = "AHT10";
        }
    }

    if (novaFonte[0] == 'n' && dht22Disponivel) {
        temp = ultimaTempDHT;
        umid = ultimaUmidDHT;

        if (isfinite(temp) && isfinite(umid) &&
            temp >= -40.0f && temp <= 85.0f &&
            umid >= 0.0f && umid <= 100.0f) {
            novaFonte = "DHT22";
        }
    }

    if (novaFonte[0] == 'n') {
        temperatura = NAN;
        umidade = NAN;
    } else {
        temperatura = temp;
        umidade = umid;
    }

    if (fonteAmbienteAtual != novaFonte) {
        fonteAmbienteAtual = novaFonte;
        ++trocasDeFonteAmbiente;
    }
}