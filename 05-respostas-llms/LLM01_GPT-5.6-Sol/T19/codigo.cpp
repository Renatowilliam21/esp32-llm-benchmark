uint32_t calcularChecksum(const RegistroMeteorologico &registro) {
    const uint8_t *bytes = reinterpret_cast<const uint8_t *>(&registro);
    const size_t tamanho = sizeof(RegistroMeteorologico) - sizeof(uint32_t);
    uint32_t soma = 0;

    for (size_t i = 0; i < tamanho; ++i) {
        soma = (soma * 31U) + bytes[i];
    }

    return soma;
}