void coletarAmostra() {
    float temperatura, umidade;
    if (lerAmbiente(temperatura, umidade)) {
        if (faixaValida(temperatura, TipoSensor::TEMPERATURA)) {
            if (passaTesteDegrau(temperatura)) {
                somaTemperatura += temperatura;
                contagemTemperatura++;
            } else {
                descarteTemperatura++;
            }
        } else {
            descarteTemperatura++;
        }

        if (faixaValida(umidade, TipoSensor::UMIDADE)) {
            somaUmidade += umidade;
            contagemUmidade++;
        } else {
            descarteUmidade++;
        }
    }

    float pressao, altitude;
    if (lerPressaoAltitude(pressao, altitude)) {
        if (faixaValida(pressao, TipoSensor::PRESSAO)) {
            somaPressao += pressao;
            contagemPressao++;
        } else {
            descartePressao++;
        }

        if (faixaValida(altitude, TipoSensor::ALTITUDE)) {
            somaAltitude += altitude;
            contagemAltitude++;
        } else {
            descarteAltitude++;
        }
    }

    float uv;
    if (lerUV(uv)) {
        if (faixaValida(uv, TipoSensor::UV)) {
            somaUV += uv;
            contagemUV++;
        } else {
            descarteUV++;
        }
    }

    float ldr;
    if (lerLDR(ldr)) {
        if (faixaValida(ldr, TipoSensor::LDR)) {
            somaLDR += ldr;
            contagemLDR++;
        } else {
            descarteLDR++;
        }
    }

    float qualidadeAr;
    if (lerQualidadeAr(qualidadeAr)) {
        if (faixaValida(qualidadeAr, TipoSensor::QUALIDADE_AR)) {
            somaQualidadeAr += qualidadeAr;
            contagemQualidadeAr++;
        } else {
            descarteQualidadeAr++;
        }
    }
}