#include <math.h>

float calcularPontoOrvalho(float temperaturaC, float umidadeRelativa) {
  const float a = 17.27f;
  const float b = 237.7f;
  float alpha = (a * temperaturaC) / (b + temperaturaC) + log(umidadeRelativa / 100.0f);
  return (b * alpha) / (a - alpha);
}

float calcularITGU(float temperaturaC, float umidadeRelativa) {
  float pontoOrvalho = calcularPontoOrvalho(temperaturaC, umidadeRelativa);
  return temperaturaC + 0.36f * pontoOrvalho + 41.5f;
}