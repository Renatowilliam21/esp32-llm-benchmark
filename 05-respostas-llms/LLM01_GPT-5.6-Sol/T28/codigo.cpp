#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

static bool executarPost(HTTPClient &http, const String &token, const String &json, String &status) {
    http.setConnectTimeout(8000);
    http.setTimeout(60000);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-API-Token", token);

    int codigo = http.POST(json);

    if (codigo < 0) {
        status = String("erro de transporte: ") + HTTPClient::errorToString(codigo);
        http.end();
        return false;
    }

    status = String("HTTP ") + String(codigo);

    if (codigo < 200 || codigo >= 300) {
        String resposta = http.getString();
        if (resposta.length() > 0) {
            status += String(": ") + resposta;
        }
        http.end();
        return false;
    }

    http.end();
    return true;
}

bool enviarParaUmServidor(const String &url, const String &token, const String &json, String &status) {
    if (url.length() == 0 || token.length() == 0) {
        status = "nao configurado";
        return true;
    }

    HTTPClient http;

    if (url.startsWith("https://")) {
        WiFiClientSecure cliente;
        cliente.setInsecure();
        cliente.setTimeout(60000);

        if (!http.begin(cliente, url)) {
            status = "falha ao iniciar requisicao HTTPS";
            return false;
        }

        return executarPost(http, token, json, status);
    }

    if (url.startsWith("http://")) {
        WiFiClient cliente;
        cliente.setTimeout(60000);

        if (!http.begin(cliente, url)) {
            status = "falha ao iniciar requisicao HTTP";
            return false;
        }

        return executarPost(http, token, json, status);
    }

    status = "protocolo de URL invalido";
    return false;
}