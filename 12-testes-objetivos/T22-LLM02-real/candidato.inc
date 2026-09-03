#include <WiFi.h>
#include <esp_task_wdt.h>

void loop() {
  esp_task_wdt_reset();

  server.handleClient();
  processarComandosSeriais();

  if (WiFi.status() != WL_CONNECTED) {
    WiFi.reconnect();
    return;
  }

  unsigned long agora = millis();

  if (agora - ultimaColeta >= INTERVALO_COLETA) {
    ultimaColeta = agora;
    coletarAmostra();
  }

  if (agora - ultimaAgregacao >= INTERVALO_AGREGACAO) {
    ultimaAgregacao = agora;
    gravarRegistroPendente();
  }

  if (agora - ultimaTentativaEnvio >= INTERVALO_ENVIO) {
    ultimaTentativaEnvio = agora;
    tentarDrenarFila();
  }
}