#include <WebServer.h>
#include <Preferences.h>

extern WebServer server;
extern Preferences preferences;

extern int contadorFila;
extern int contadorBuffer;
extern bool sensorTemperaturaDisponivel;
extern bool sensorUmidadeDisponivel;
extern bool sensorPresencaDisponivel;
extern String fonteAmbienteAtual;
extern bool ultimoEnvioSucesso;

static void handleRootAdmin() {
  String urlLocal = preferences.getString("urlLocal", "");
  String tokenLocal = preferences.getString("tokenLocal", "");
  String urlProducao = preferences.getString("urlProd", "");
  String tokenProducao = preferences.getString("tokenProd", "");

  String html = "<!DOCTYPE html><html><head><meta charset='UTF-8'>";
  html += "<title>Administracao</title></head><body>";
  html += "<h1>Painel Administrativo</h1>";

  html += "<h2>Estado da Fila/Buffer</h2>";
  html += "<p>Itens na fila: " + String(contadorFila) + "</p>";
  html += "<p>Itens no buffer: " + String(contadorBuffer) + "</p>";

  html += "<h2>Disponibilidade dos Sensores</h2>";
  html += "<p>Temperatura: " + String(sensorTemperaturaDisponivel ? "Disponivel" : "Indisponivel") + "</p>";
  html += "<p>Umidade: " + String(sensorUmidadeDisponivel ? "Disponivel" : "Indisponivel") + "</p>";
  html += "<p>Presenca: " + String(sensorPresencaDisponivel ? "Disponivel" : "Indisponivel") + "</p>";

  html += "<h2>Fonte de Ambiente</h2>";
  html += "<p>" + fonteAmbienteAtual + "</p>";

  html += "<h2>Status de Envio</h2>";
  html += "<p>" + String(ultimoEnvioSucesso ? "Sucesso" : "Falha") + "</p>";

  html += "<h2>Configuracao</h2>";
  html += "<form method='POST' action='/salvar'>";
  html += "URL Local:<br><input type='text' name='urlLocal' value='" + urlLocal + "'><br>";
  html += "Token Local:<br><input type='text' name='tokenLocal' value='" + tokenLocal + "'><br>";
  html += "URL Producao:<br><input type='text' name='urlProducao' value='" + urlProducao + "'><br>";
  html += "Token Producao:<br><input type='text' name='tokenProducao' value='" + tokenProducao + "'><br><br>";
  html += "<input type='submit' value='Salvar'>";
  html += "</form>";

  html += "</body></html>";

  server.send(200, "text/html", html);
}

static void handleSalvarAdmin() {
  if (server.hasArg("urlLocal")) {
    preferences.putString("urlLocal", server.arg("urlLocal"));
  }
  if (server.hasArg("tokenLocal")) {
    preferences.putString("tokenLocal", server.arg("tokenLocal"));
  }
  if (server.hasArg("urlProducao")) {
    preferences.putString("urlProd", server.arg("urlProducao"));
  }
  if (server.hasArg("tokenProducao")) {
    preferences.putString("tokenProd", server.arg("tokenProducao"));
  }

  server.sendHeader("Location", "/");
  server.send(303);
}

void configurarServidorAdmin() {
  server.on("/", HTTP_GET, handleRootAdmin);
  server.on("/salvar", HTTP_POST, handleSalvarAdmin);
  server.begin();
}