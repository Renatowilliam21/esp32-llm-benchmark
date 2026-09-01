#include <WiFi.h>
#include <esp_task_wdt.h>

static void processarComandosSeriais() {
  while (Serial.available() > 0) {
    String comando = Serial.readStringUntil('\n');
    comando.trim();
    if (comando.length() == 0) {
      continue;
    }
    Serial.print("Comando recebido: ");
    Serial.println(comando);
  }
}

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
    coletarAmostra();
    ultimaColeta = agora;
  }

  if (agora - ultimaAgregacao >= INTERVALO_AGREGACAO) {
    gravarRegistroPendente();
    ultimaAgregacao = agora;
  }

  if (agora - ultimaTentativaEnvio >= INTERVALO_ENVIO) {
    tentarDrenarFila();
    ultimaTentativaEnvio = agora;
  }
}