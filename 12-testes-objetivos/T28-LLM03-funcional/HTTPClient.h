#ifndef HTTP_CLIENT_H
#define HTTP_CLIENT_H

#include <Arduino.h>
#include "WiFiClient.h"
#include "WiFiClientSecure.h"
#include "MockNetState.h"

class HTTPClient {
public:

    HTTPClient() {
    }

    void setConnectTimeout(int timeout) {
        mockHTTP().connectTimeout = timeout;
    }

    void setTimeout(uint16_t timeout) {
        mockHTTP().httpTimeout = timeout;
    }

    bool begin(
        WiFiClient &cliente,
        const String &url
    ) {
        (void)cliente;

        mockHTTP().beginCount++;
        mockHTTP().url = url;

        return true;
    }

    bool begin(
        WiFiClientSecure &cliente,
        const String &url
    ) {
        (void)cliente;

        mockHTTP().beginCount++;
        mockHTTP().url = url;
        mockHTTP().secureCreated = true;

        return true;
    }

    bool begin(const String &url) {
        mockHTTP().beginCount++;
        mockHTTP().url = url;

        return true;
    }

    void addHeader(
        const String &nome,
        const String &valor
    ) {
        if (nome == "Content-Type") {
            mockHTTP().contentType = valor;
        }

        if (nome == "X-API-Token") {
            mockHTTP().apiToken = valor;
        }
    }

    int POST(const String &json) {
        mockHTTP().postCount++;
        mockHTTP().postedJson = json;

        return mockHTTP().responseCode;
    }

    String getString() {
        return mockHTTP().responseBody;
    }

    void end() {
        mockHTTP().endCount++;
    }

    static String errorToString(int codigo) {
        if (codigo == -1) {
            return "connection refused";
        }

        if (codigo == 0) {
            return "connection failed";
        }

        return String("transport error ") + String(codigo);
    }
};

#endif
