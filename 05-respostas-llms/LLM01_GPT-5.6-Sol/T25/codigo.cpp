void coletarAmostra() {
    float temperaturaAmbiente;
    float umidade;

    if (lerAmbiente(temperaturaAmbiente, umidade)) {
        if (faixaValida(temperaturaAmbiente, -40.0f, 85.0f)) {
            if (passaTesteDegrau(temperaturaAmbiente)) {
                acumuladorTemperaturaAmbiente += temperaturaAmbiente;
            }
        } else {
            contadorDescartesFaixa++;
        }

        if (faixaValida(umidade, 0.0f, 100.0f)) {
            acumuladorUmidade += umidade;
        } else {
            contadorDescartesFaixa++;
        }
    }

    float temperaturaPressao;
    float pressao;
    float altitude;

    if (lerPressaoAltitude(temperaturaPressao, pressao, altitude)) {
        if (faixaValida(temperaturaPressao, -40.0f, 85.0f)) {
            if (passaTesteDegrau(temperaturaPressao)) {
                acumuladorTemperaturaPressao += temperaturaPressao;
            }
        } else {
            contadorDescartesFaixa++;
        }

        if (faixaValida(pressao, 300.0f, 1100.0f)) {
            acumuladorPressao += pressao;
        } else {
            contadorDescartesFaixa++;
        }

        if (faixaValida(altitude, -500.0f, 10000.0f)) {
            acumuladorAltitude += altitude;
        } else {
            contadorDescartesFaixa++;
        }
    }

    float uv;
    if (lerUV(uv)) {
        if (faixaValida(uv, 0.0f, 15.0f)) {
            acumuladorUV += uv;
        } else {
            contadorDescartesFaixa++;
        }
    }

    float ldr;
    if (lerLDR(ldr)) {
        if (faixaValida(ldr, 0.0f, 4095.0f)) {
            acumuladorLDR += ldr;
        } else {
            contadorDescartesFaixa++;
        }
    }

    float qualidadeAr;
    if (lerQualidadeAr(qualidadeAr)) {
        if (faixaValida(qualidadeAr, 0.0f, 4095.0f)) {
            acumuladorQualidadeAr += qualidadeAr;
        } else {
            contadorDescartesFaixa++;
        }
    }
}