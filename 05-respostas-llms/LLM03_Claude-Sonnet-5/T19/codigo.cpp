uint32_t calcularChecksum(const RegistroMeteorologico &registro) {
    uint32_t soma = 0;
    const uint8_t *bytes = reinterpret_cast<const uint8_t*>(&registro);
    size_t tamanho = sizeof(RegistroMeteorologico) - sizeof(uint32_t);

    for (size_t i = 0; i < tamanho; i++) {
        soma = (soma * 31) + bytes[i];
    }

    return soma;
}