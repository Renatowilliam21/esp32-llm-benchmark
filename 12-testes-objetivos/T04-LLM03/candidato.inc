float lerUV(int pinoUV) {
  int leitura = analogRead(pinoUV);
  if (leitura < 0) {
    leitura = 0;
  }
  float tensao = (leitura / 4095.0f) * 3.3f;
  float indiceUV = tensao * 10.0f;
  if (indiceUV < 0.0f) {
    indiceUV = 0.0f;
  }
  return indiceUV;
}