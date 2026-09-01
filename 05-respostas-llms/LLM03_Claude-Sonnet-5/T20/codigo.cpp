bool lerRegistro(uint16_t indice, RegistroMeteorologico &registro) {
    uint16_t endereco = ENDERECO_DADOS + indice * TAM_REGISTRO;
    uint8_t buffer[TAM_REGISTRO];

    for (uint16_t i = 0; i < TAM_REGISTRO; i++) {
        buffer[i] = lerEEPROM(endereco + i);
    }

    memcpy(&registro, buffer, sizeof(RegistroMeteorologico));

    uint8_t checksumArmazenado = registro.checksum;
    uint8_t checksumCalculado = calcularChecksum(registro);

    return checksumArmazenado == checksumCalculado;
}