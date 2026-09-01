static String escaparHtmlAdmin(const String &valor) {
  String resultado;
  resultado.reserve(valor.length() + 16);

  for (size_t i = 0; i < valor.length(); ++i) {
    const char c = valor.charAt(i);
    switch (c) {
      case '&': resultado += F("&amp;"); break;
      case '<': resultado += F("&lt;"); break;
      case '>': resultado += F("&gt;"); break;
      case '"': resultado += F("&quot;"); break;
      case '\'': resultado += F("&#39;"); break;
      default: resultado += c; break;
    }
  }

  return resultado;
}

void configurarServidorAdmin() {
  preferences.begin("config", false);

  server.on("/", HTTP_GET, []() {
    const String urlLocal = preferences.getString("url_local", "");
    const String tokenLocal = preferences.getString("token_local", "");
    const String urlProducao = preferences.getString("url_producao", "");
    const String tokenProducao = preferences.getString("token_producao", "");

    String estadoEnvio;
    if (preferences.isKey("status_envio")) {
      estadoEnvio = preferences.getString("status_envio", "Não informado");
    } else {
      const bool localConfigurado = !urlLocal.isEmpty() && !tokenLocal.isEmpty();
      const bool producaoConfigurada = !urlProducao.isEmpty() && !tokenProducao.isEmpty();

      if (localConfigurado && producaoConfigurada) {
        estadoEnvio = "Local e produção configurados";
      } else if (localConfigurado) {
        estadoEnvio = "Somente ambiente local configurado";
      } else if (producaoConfigurada) {
        estadoEnvio = "Somente produção configurada";
      } else {
        estadoEnvio = "Envio não configurado";
      }
    }

    const String estadoFila = preferences.getString("estado_fila", "Não informado");
    const String sensores = preferences.getString("sensores", "Não informada");
    const String fonteAmbiente = preferences.getString("fonte_ambiente", "Não informada");

    String pagina;
    pagina.reserve(2800);

    pagina += F("<!doctype html><html lang=\"pt-BR\"><head>");
    pagina += F("<meta charset=\"utf-8\">");
    pagina += F("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
    pagina += F("<title>Administração</title>");
    pagina += F("<style>"
                "body{font-family:Arial,sans-serif;max-width:760px;margin:30px auto;padding:0 16px;background:#f5f5f5;color:#222}"
                "section{background:#fff;padding:20px;margin-bottom:18px;border-radius:8px;box-shadow:0 1px 4px #bbb}"
                "dl{display:grid;grid-template-columns:max-content 1fr;gap:10px 18px}"
                "dt{font-weight:bold}dd{margin:0;overflow-wrap:anywhere}"
                "label{display:block;font-weight:bold;margin-top:14px}"
                "input{box-sizing:border-box;width:100%;padding:9px;margin-top:5px}"
                "button{margin-top:20px;padding:10px 20px;cursor:pointer}"
                "</style></head><body>");

    pagina += F("<h1>Administração</h1><section><h2>Estado</h2><dl>");
    pagina += F("<dt>Fila/buffer</dt><dd>");
    pagina += escaparHtmlAdmin(estadoFila);
    pagina += F(" — heap livre: ");
    pagina += String(ESP.getFreeHeap());
    pagina += F(" bytes</dd><dt>Sensores disponíveis</dt><dd>");
    pagina += escaparHtmlAdmin(sensores);
    pagina += F("</dd><dt>Fonte de ambiente</dt><dd>");
    pagina += escaparHtmlAdmin(fonteAmbiente);
    pagina += F("</dd><dt>Status de envio</dt><dd>");
    pagina += escaparHtmlAdmin(estadoEnvio);
    pagina += F("</dd></dl></section>");

    pagina += F("<section><h2>Configuração</h2>"
                "<form method=\"post\" action=\"/salvar\" autocomplete=\"off\">"
                "<label for=\"url_local\">URL local</label>"
                "<input id=\"url_local\" name=\"url_local\" type=\"url\" value=\"");
    pagina += escaparHtmlAdmin(urlLocal);
    pagina += F("\">"
                "<label for=\"token_local\">Token local</label>"
                "<input id=\"token_local\" name=\"token_local\" type=\"password\" value=\"");
    pagina += escaparHtmlAdmin(tokenLocal);
    pagina += F("\" autocomplete=\"new-password\">"
                "<label for=\"url_producao\">URL de produção</label>"
                "<input id=\"url_producao\" name=\"url_producao\" type=\"url\" value=\"");
    pagina += escaparHtmlAdmin(urlProducao);
    pagina += F("\">"
                "<label for=\"token_producao\">Token de produção</label>"
                "<input id=\"token_producao\" name=\"token_producao\" type=\"password\" value=\"");
    pagina += escaparHtmlAdmin(tokenProducao);
    pagina += F("\" autocomplete=\"new-password\">"
                "<button type=\"submit\">Salvar</button>"
                "</form></section></body></html>");

    server.sendHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    server.sendHeader("Pragma", "no-cache");
    server.sendHeader("X-Content-Type-Options", "nosniff");
    server.send(200, "text/html; charset=utf-8", pagina);
  });

  server.on("/salvar", HTTP_POST, []() {
    preferences.putString("url_local", server.arg("url_local"));
    preferences.putString("token_local", server.arg("token_local"));
    preferences.putString("url_producao", server.arg("url_producao"));
    preferences.putString("token_producao", server.arg("token_producao"));

    server.sendHeader("Location", "/", true);
    server.sendHeader("Cache-Control", "no-store");
    server.send(303, "text/plain; charset=utf-8", "");
  });

  server.begin();
}