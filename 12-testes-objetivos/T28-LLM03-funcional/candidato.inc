#include <Arduino.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

bool enviarParaUmServidor(const String &url, const String &token, const String &json, String &status) {
    if (url.length() == 0 || token.length() == 0) {
        status = "nao configurado";
        return true;
    }

    HTTPClient http;
    int httpCode = -1;
    bool sucesso = false;

    if (url.startsWith("https://")) {
        WiFiClientSecure client;
        client.setInsecure();
        client.setTimeout(60000);

        if (!http.begin(client, url)) {
            status = "falha ao iniciar conexao https";
            return false;
        }

        http.setConnectTimeout(8000);
        http.setTimeout(60000);
        http.addHeader("Content-Type", "application/json");
        http.addHeader("X-API-Token", token);

        httpCode = http.POST(json);

        if (httpCode > 0) {
            if (httpCode >= 200 && httpCode < 300) {
                status = "sucesso: " + String(httpCode);
                sucesso = true;
            } else {
                String resposta = http.getString();
                status = "erro http: " + String(httpCode) + " - " + resposta;
                sucesso = false;
            }
        } else {
            status = "erro de transporte: " + http.errorToString(httpCode);
            sucesso = false;
        }

        http.end();
    } else {
        if (!http.begin(url)) {
            status = "falha ao iniciar conexao http";
            return false;
        }

        http.setConnectTimeout(8000);
        http.setTimeout(60000);
        http.addHeader("Content-Type", "application/json");
        http.addHeader("X-API-Token", token);

        httpCode = http.POST(json);

        if (httpCode > 0) {
            if (httpCode >= 200 && httpCode < 300) {
                status = "sucesso: " + String(httpCode);
                sucesso = true;
            } else {
                String resposta = http.getString();
                status = "erro http: " + String(httpCode) + " - " + resposta;
                sucesso = false;
            }
        } else {
            status = "erro de transporte: " + http.errorToString(httpCode);
            sucesso = false;
        }

        http.end();
    }

    return sucesso;
}