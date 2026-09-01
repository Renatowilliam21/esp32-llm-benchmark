void gravarRegistroPendente() {
    if (numeroAmostras == 0) {
        return;
    }

    RegistroMeteorologico registro{};

    registro.temperatura = somaTemperatura / numeroAmostras;
    registro.umidade = somaUmidade / numeroAmostras;
    registro.pressao = somaPressao / numeroAmostras;
    registro.luminosidade = somaLuminosidade / numeroAmostras;
    registro.temperaturaGlobo = somaTemperaturaGlobo / numeroAmostras;

    if (rtcDisponivel) {
        registro.timestamp = rtc.now().unixtime();
    }

    if (isfinite(registro.temperatura) && isfinite(registro.umidade)) {
        registro.itu = calcularITU(registro.temperatura, registro.umidade);
        registro.indiceCalor =
            calcularIndiceCalor(registro.temperatura, registro.umidade);
    } else {
        registro.itu = NAN;
        registro.indiceCalor = NAN;
    }

    if (isfinite(registro.temperaturaGlobo) &&
        isfinite(registro.temperatura) &&
        isfinite(registro.umidade)) {
        registro.itgu = calcularITGU(
            registro.temperaturaGlobo,
            registro.temperatura,
            registro.umidade
        );
    } else {
        registro.itgu = NAN;
    }

    uint32_t chuvaPulsos;
    uint32_t ventoPulsos;

    portENTER_CRITICAL(&muxPulsos);
    chuvaPulsos = pulsosChuva;
    ventoPulsos = pulsosVento;
    pulsosChuva = 0;
    pulsosVento = 0;
    portEXIT_CRITICAL(&muxPulsos);

    registro.chuva = chuvaPulsos * MM_POR_PULSO_CHUVA;
    registro.velocidadeVento = ventoPulsos * KMH_POR_PULSO_VENTO;

    if (eepromDisponivel) {
        gravarRegistro(proximoRegistro, registro);
        proximoRegistro = (proximoRegistro + 1) % MAX_REGISTROS;

        if (totalRegistros < MAX_REGISTROS) {
            ++totalRegistros;
        }

        salvarControleEEPROM();
    } else {
        registroPendenteRAM = registro;
        registroPendenteRAMValido = true;
    }

    somaTemperatura = 0;
    somaUmidade = 0;
    somaPressao = 0;
    somaLuminosidade = 0;
    somaTemperaturaGlobo = 0;
    numeroAmostras = 0;
}