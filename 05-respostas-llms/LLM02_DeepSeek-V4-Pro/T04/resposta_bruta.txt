float lerUV(int pinoUV) {
  int leitura = analogRead(pinoUV);
  if (leitura < 0) {
    leitura = 0;
  }
  float tensao = leitura * (3.3f / 4095.0f);
  float indiceUV = tensao * 10.0f;
  if (indiceUV < 0.0f) {
    indiceUV = 0.0f;
  }
  return indiceUV;
}