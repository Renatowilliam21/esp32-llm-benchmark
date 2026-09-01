float calcularITU(float temperaturaC, float umidadeRelativa) {
    return 0.8f * temperaturaC
         + (umidadeRelativa / 100.0f) * (temperaturaC - 14.3f)
         + 46.3f;
}