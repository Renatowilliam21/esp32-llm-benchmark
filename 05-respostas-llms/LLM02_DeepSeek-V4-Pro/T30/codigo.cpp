extern String obterEstadoFila();
extern String obterDisponibilidadeSensores();
extern String obterFonteAmbiente();
extern String obterStatusEnvio();

void handleRoot() {
  String html = "<!DOCTYPE html><html><head><title>Admin</title></head><body>";
  html += "<h1>Painel Administrativo</h1>";
  html += "<h2>Estado do Sistema</h2>";
  html += "<p>Fila/Buffer: " + obterEstadoFila() + "</p>";
  html += "<p>Disponibilidade dos Sensores: " + obterDisponibilidadeSensores() + "</p>";
  html += "<p>Fonte de Ambiente: " + obterFonteAmbiente() + "</p>";
  html += "<p>Status de Envio: " + obterStatusEnvio() + "</p>";
  html += "<h2>Configuracao</h2>";
  html += "<form action=\"/salvar\" method=\"post\">";
  html += "<label>URL Local:</label><input type=\"text\" name=\"urlLocal\" value=\"" + server.htmlEscape(preferences.getString("urlLocal", "")) + "\"><br>";
  html += "<label>Token Local:</label><input type=\"text\" name=\"tokenLocal\" value=\"" + server.htmlEscape(preferences.getString("tokenLocal", "")) + "\"><br>";
  html += "<label>URL Producao:</label><input type=\"text\" name=\"urlProducao\" value=\"" + server.htmlEscape(preferences.getString("urlProducao", "")) + "\"><br>";
  html += "<label>Token Producao:</label><input type=\"text\" name=\"tokenProducao\" value=\"" + server.htmlEscape(preferences.getString("tokenProducao", "")) + "\"><br>";
  html += "<input type=\"submit\" value=\"Salvar\">";
  html += "</form>";
  html += "</body></html>";
  server.send(200, "text/html", html);
}

void handleSave() {
  String urlLocal = server.arg("urlLocal");
  String tokenLocal = server.arg("tokenLocal");
  String urlProducao = server.arg("urlProducao");
  String tokenProducao = server.arg("tokenProducao");
  preferences.putString("urlLocal", urlLocal);
  preferences.putString("tokenLocal", tokenLocal);
  preferences.putString("urlProducao", urlProducao);
  preferences.putString("tokenProducao", tokenProducao);
  server.sendHeader("Location", "/", true);
  server.send(303);
}

void configurarServidorAdmin() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/salvar", HTTP_POST, handleSave);
  server.begin();
}