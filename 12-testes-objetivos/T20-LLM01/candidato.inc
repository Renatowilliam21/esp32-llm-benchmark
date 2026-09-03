bool lerRegistro(uint16_t indice, RegistroMeteorologico &registro) {
    uint32_t endereco = ENDERECO_DADOS + static_cast<uint32_t>(indice) * TAM_REGISTRO;
    uint8_t *dados = reinterpret_cast<uint8_t *>(&registro);

    for (size_t i = 0; i < sizeof(RegistroMeteorologico); ++i) {
        dados[i] = lerEEPROM(endereco + i);
    }

    auto checksumArmazenado = registro.checksum;
    auto checksumCalculado = calcularChecksum(registro);

    return checksumArmazenado == checksumCalculado;
}