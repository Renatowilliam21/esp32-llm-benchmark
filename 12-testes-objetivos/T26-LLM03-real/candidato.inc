void gravarRegistroPendente() {
  bool temAmostras = (accTemperatura.contagem > 0) ||
                      (accUmidade.contagem > 0) ||
                      (accTemperaturaGlobo.contagem > 0) ||
                      (accPressao.contagem > 0);

  if (!temAmostras) {
    return;
  }

  RegistroMeteorologico reg;
  memset(&reg, 0, sizeof(reg));

  if (rtcDisponivel) {
    DateTime agora = rtc.now();
    reg.timestamp = agora.unixtime();
  } else {
    reg.timestamp = 0;
  }

  if (accTemperatura.contagem > 0) {
    reg.temperatura = accTemperatura.soma / accTemperatura.contagem;
  }

  if (accUmidade.contagem > 0) {
    reg.umidade = accUmidade.soma / accUmidade.contagem;
  }

  if (accPressao.contagem > 0) {
    reg.pressao = accPressao.soma / accPressao.contagem;
  }

  if (accTemperaturaGlobo.contagem > 0) {
    reg.temperaturaGlobo = accTemperaturaGlobo.soma / accTemperaturaGlobo.contagem;
  }

  if (accTemperaturaGlobo.contagem > 0 && accUmidade.contagem > 0) {
    reg.itgu = calcularITGU(reg.temperaturaGlobo, reg.umidade);
  }

  if (accTemperatura.contagem > 0 && accUmidade.contagem > 0) {
    reg.itu = calcularITU(reg.temperatura, reg.umidade);
    reg.indiceCalor = calcularIndiceCalor(reg.temperatura, reg.umidade);
  }

  uint32_t pulsosChuvaLocal = 0;
  uint32_t pulsosVentoLocal = 0;

  noInterrupts();
  pulsosChuvaLocal = pulsosChuva;
  pulsosVentoLocal = pulsosVento;
  pulsosChuva = 0;
  pulsosVento = 0;
  interrupts();

  reg.chuva = pulsosChuvaLocal * MM_POR_PULSO;
  reg.velocidadeVento = pulsosVentoLocal * FATOR_VENTO_KMH;

  if (eepromDisponivel) {
    gravarRegistro(reg, proximoRegistro);
    proximoRegistro = (proximoRegistro + 1) % MAX_REGISTROS;
    if (totalRegistros < MAX_REGISTROS) {
      totalRegistros++;
    }
    salvarControleEEPROM();
  } else {
    registroPendenteRAM = reg;
    registroPendenteRAMValido = true;
  }

  accTemperatura.reset();
  accUmidade.reset();
  accPressao.reset();
  accTemperaturaGlobo.reset();
}