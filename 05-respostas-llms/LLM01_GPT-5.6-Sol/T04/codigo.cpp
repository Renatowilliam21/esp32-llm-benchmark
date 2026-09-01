float lerUV(int pinoUV) {
    int leitura = analogRead(pinoUV);
    float tensao = leitura * (3.3f / 4095.0f);
    float indiceUV = tensao * 10.0f;
    return indiceUV < 0.0f ? 0.0f : indiceUV;
}