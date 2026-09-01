float calcularPontoOrvalho(float temperaturaC, float umidadeRelativa) {
    const float a = 17.27f;
    const float b = 237.7f;
    const float alpha = (a * temperaturaC) / (b + temperaturaC)
                      + log(umidadeRelativa / 100.0f);
    return (b * alpha) / (a - alpha);
}