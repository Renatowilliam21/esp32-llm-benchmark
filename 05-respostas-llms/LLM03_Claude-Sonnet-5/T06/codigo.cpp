float calcularPontoOrvalho(float temperaturaC, float umidadeRelativa) {
    const float a = 17.27;
    const float b = 237.7;
    float alpha = (a * temperaturaC) / (b + temperaturaC) + log(umidadeRelativa / 100.0);
    float Td = (b * alpha) / (a - alpha);
    return Td;
}