#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

bool enviarParaUmServidor(const String &url, const String &token, const String &json, String &status) {
    if (url.isEmpty() || token.isEmpty()) {
        status = "nao configurado";
        return true;
    }

    HTTPClient http;
    WiFiClient* transport = nullptr;
    WiFiClientSecure* secureTransport = nullptr;
    bool isHttps = url.startsWith("https://");

    if (isHttps) {
        secureTransport = new WiFiClientSecure();
        secureTransport->setInsecure();
        transport = secureTransport;
    } else {
        transport = new WiFiClient();
    }

    http.setConnectTimeout(8000);
    http.setTimeout(60000);

    bool beginOk = http.begin(*transport, url);
    if (!beginOk) {
        status = "falha ao iniciar conexao";
        delete transport;
        return false;
    }

    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-API-Token", token);

    int httpCode = http.POST(json);

    if (httpCode > 0) {
        if (httpCode >= 200 && httpCode < 300) {
            http.end();
            delete transport;
            status = "sucesso";
            return true;
        } else {
            http.end();
            delete transport;
            status = "HTTP " + String(httpCode);
            return false;
        }
    } else {
        http.end();
        delete transport;
        status = "erro de transporte: " + http.errorToString(httpCode);
        return false;
    }
}