void tentarDrenarFila() {
    if (eepromDisponivel) {
        if (totalRegistros == 0) {
            return;
        }

        Registro registro;

        if (!lerRegistro(indiceLeitura, registro)) {
            indiceLeitura = (indiceLeitura + 1) % MAX_REGISTROS;
            --totalRegistros;
            salvarControleEEPROM();
            return;
        }

        if (registro.enviado) {
            indiceLeitura = (indiceLeitura + 1) % MAX_REGISTROS;
            --totalRegistros;
            salvarControleEEPROM();
            return;
        }

        String json = montarJSON(registro);
        bool sucessoDestino1 = enviarParaUmServidor(urlServidor1, json);
        bool sucessoDestino2 = enviarParaUmServidor(urlServidor2, json);

        if (!sucessoDestino1 || !sucessoDestino2) {
            return;
        }

        registro.enviado = true;
        gravarRegistro(indiceLeitura, registro);

        indiceLeitura = (indiceLeitura + 1) % MAX_REGISTROS;
        --totalRegistros;
        salvarControleEEPROM();
        return;
    }

    if (!temRegistroPendenteRAM) {
        return;
    }

    if (registroPendenteRAM.enviado) {
        temRegistroPendenteRAM = false;
        return;
    }

    String json = montarJSON(registroPendenteRAM);
    bool sucessoDestino1 = enviarParaUmServidor(urlServidor1, json);
    bool sucessoDestino2 = enviarParaUmServidor(urlServidor2, json);

    if (!sucessoDestino1 || !sucessoDestino2) {
        return;
    }

    registroPendenteRAM.enviado = true;
    temRegistroPendenteRAM = false;
}