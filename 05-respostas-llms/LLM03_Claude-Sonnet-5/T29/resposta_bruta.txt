void tentarDrenarFila() {
    if (eepromDisponivel) {
        if (totalRegistros == 0) {
            return;
        }

        RegistroSensor registro;
        bool checksumValido = lerRegistro(indiceRegistroAtual, registro);

        if (!checksumValido) {
            totalRegistros--;
            salvarControleEEPROM();
            return;
        }

        if (registro.enviado) {
            totalRegistros--;
            salvarControleEEPROM();
            return;
        }

        String json = montarJSON(registro);

        bool sucessoServidor1 = enviarParaUmServidor(0, json);
        bool sucessoServidor2 = enviarParaUmServidor(1, json);

        if (sucessoServidor1 && sucessoServidor2) {
            registro.enviado = true;
            gravarRegistro(indiceRegistroAtual, registro);
            totalRegistros--;
            salvarControleEEPROM();
        }
    } else {
        if (!registroPendenteRAM.valido) {
            return;
        }

        if (registroPendenteRAM.enviado) {
            registroPendenteRAM.valido = false;
            return;
        }

        String json = montarJSON(registroPendenteRAM);

        bool sucessoServidor1 = enviarParaUmServidor(0, json);
        bool sucessoServidor2 = enviarParaUmServidor(1, json);

        if (sucessoServidor1 && sucessoServidor2) {
            registroPendenteRAM.enviado = true;
            registroPendenteRAM.valido = false;
        }
    }
}