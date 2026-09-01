bool lerRegistro(uint16_t indice, RegistroMeteorologico &registro) {
  uint16_t endereco = ENDERECO_DADOS + (indice * TAM_REGISTRO);
  uint8_t *bytes = reinterpret_cast<uint8_t *>(&registro);

  for (uint16_t i = 0; i < TAM_REGISTRO; i++) {
    bytes[i] = lerEEPROM(endereco + i);
  }

  uint16_t checksumArmazenado = registro.checksum;
  uint16_t checksumCalculado = calcularChecksum(registro);

  return checksumArmazenado == checksumCalculado;
}