static uint8_t lerIdSensor280(uint8_t endereco) {
  Wire.beginTransmission(endereco);
  Wire.write(0xD0);
  if (Wire.endTransmission(false) != 0) {
    return 0;
  }

  if (Wire.requestFrom(endereco, static_cast<uint8_t>(1)) != 1) {
    return 0;
  }

  return Wire.read();
}

void inicializarSensores() {
  dhtDisponivel = false;
  dhtSaudavel = false;
  bme280Disponivel = false;
  bme280Saudavel = false;
  bmp280Disponivel = false;
  bmp280Saudavel = false;
  aht10Disponivel = false;
  aht10Saudavel = false;
  sht41Disponivel = false;
  sht41Saudavel = false;
  veml7700Disponivel = false;
  veml7700Saudavel = false;
  ens160Disponivel = false;
  ens160Saudavel = false;
  rtcDisponivel = false;
  rtcSaudavel = false;
  eepromDisponivel = false;
  eepromSaudavel = false;

  Wire.begin();

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);
  ldrDisponivel = true;
  ldrSaudavel = true;

  dht.begin();
  delay(2100);
  const float umidadeDht = dht.readHumidity();
  const float temperaturaDht = dht.readTemperature();
  dhtDisponivel = !isnan(umidadeDht) || !isnan(temperaturaDht);
  dhtSaudavel = !isnan(umidadeDht) && !isnan(temperaturaDht);

  const uint8_t enderecos280[] = {0x76, 0x77};
  for (uint8_t i = 0; i < 2; ++i) {
    const uint8_t endereco = enderecos280[i];
    const uint8_t id = lerIdSensor280(endereco);

    if (id == 0x60 && !bme280Disponivel) {
      bme280Disponivel = bme.begin(endereco, &Wire);
      bme280Saudavel = bme280Disponivel;
    } else if (id == 0x58 && !bmp280Disponivel) {
      bmp280Disponivel = bmp.begin(endereco, 0x58);
      bmp280Saudavel = bmp280Disponivel;
    }
  }

  aht10Disponivel = aht10.begin(&Wire);
  aht10Saudavel = aht10Disponivel;

  sht41Disponivel = sht41.begin(&Wire);
  if (sht41Disponivel) {
    sht41.setPrecision(SHT4X_HIGH_PRECISION);
    sht41.setHeater(SHT4X_NO_HEATER);
    sht41Saudavel = true;
  }

  veml7700Disponivel = veml7700.begin(&Wire);
  veml7700Saudavel = veml7700Disponivel;
  usarLDR = !veml7700Disponivel;

  ens160Disponivel = ens160.begin(0x52, &Wire);
  if (!ens160Disponivel) {
    ens160Disponivel = ens160.begin(0x53, &Wire);
  }
  if (ens160Disponivel) {
    ens160Saudavel = ens160.setMode(ENS160_OPMODE_STD);
  }

  rtcDisponivel = rtc.begin();
  if (rtcDisponivel) {
    if (rtc.lostPower()) {
      rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    }
    rtcSaudavel = true;
  }

  eepromDisponivel = EEPROM.begin(TAMANHO_EEPROM);
  eepromSaudavel = eepromDisponivel;
}