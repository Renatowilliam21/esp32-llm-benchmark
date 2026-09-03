#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClient.h>
#include <WiFiClientSecure.h>

// ============================================================
// CANDIDATO ORIGINAL
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link
// ============================================================

void setup() {
    Serial.begin(115200);

    String status;

    bool resultado = enviarParaUmServidor(
        "http://127.0.0.1:8080/benchmark",
        "token-benchmark",
        "{\"teste\":1}",
        status
    );

    Serial.println(resultado ? "true" : "false");
    Serial.println(status);
}

void loop() {
}
