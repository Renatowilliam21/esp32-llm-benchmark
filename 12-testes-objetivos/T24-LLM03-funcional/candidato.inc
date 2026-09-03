extern bool sht41Saudavel;
extern float sht41Temperatura;
extern float sht41Umidade;

extern bool bme280Saudavel;
extern float bme280Temperatura;
extern float bme280Umidade;

extern bool aht10Saudavel;
extern float aht10Temperatura;
extern float aht10Umidade;

extern float ultimaTempDHT;
extern float ultimaUmidDHT;

extern String fonteAmbienteAtual;
extern unsigned long trocasDeFonteAmbiente;

static bool valoresValidos(float temp, float umid) {
    if (isnan(temp) || isnan(umid)) return false;
    if (temp < -40.0f || temp > 85.0f) return false;
    if (umid < 0.0f || umid > 100.0f) return false;
    return true;
}

void lerAmbiente(float &temperatura, float &umidade) {
    String novaFonte = "nenhuma";
    float tempSelecionada = NAN;
    float umidSelecionada = NAN;

    if (sht41Saudavel && valoresValidos(sht41Temperatura, sht41Umidade)) {
        novaFonte = "SHT41";
        tempSelecionada = sht41Temperatura;
        umidSelecionada = sht41Umidade;
    } else if (bme280Saudavel && valoresValidos(bme280Temperatura, bme280Umidade)) {
        novaFonte = "BME280";
        tempSelecionada = bme280Temperatura;
        umidSelecionada = bme280Umidade;
    } else if (aht10Saudavel && valoresValidos(aht10Temperatura, aht10Umidade)) {
        novaFonte = "AHT10";
        tempSelecionada = aht10Temperatura;
        umidSelecionada = aht10Umidade;
    } else if (valoresValidos(ultimaTempDHT, ultimaUmidDHT)) {
        novaFonte = "DHT22";
        tempSelecionada = ultimaTempDHT;
        umidSelecionada = ultimaUmidDHT;
    }

    if (novaFonte != fonteAmbienteAtual) {
        fonteAmbienteAtual = novaFonte;
        trocasDeFonteAmbiente++;
    }

    temperatura = tempSelecionada;
    umidade = umidSelecionada;
}