#include <Arduino.h>

#include "MockNetState.h"
#include "WiFi.h"
#include "WiFiClient.h"
#include "WiFiClientSecure.h"
#include "HTTPClient.h"

// ============================================================
// CANDIDATO ORIGINAL
// ============================================================

#include "candidato.inc"

// ============================================================
// Apoio
// ============================================================

int aprovados = 0;
const int TOTAL_CASOS = 6;

void resultadoCaso(
    const char *id,
    bool passou
) {
    Serial.print(id);
    Serial.print(":");
    Serial.println(passou ? "PASS" : "FAIL");

    if (passou) {
        aprovados++;
    }
}

// ============================================================
// CT01
// url ou token vazio
// true + "nao configurado" + sem POST
// ============================================================

void testarCT01() {

    mockHTTP().reset();

    String status = "";

    bool retorno = enviarParaUmServidor(
        "",
        "token",
        "{\"x\":1}",
        status
    );

    bool ok =
        retorno == true &&
        status == "nao configurado" &&
        mockHTTP().postCount == 0 &&
        mockHTTP().beginCount == 0;

    resultadoCaso("CT01", ok);
}

// ============================================================
// CT02
// HTTP + resposta 200 OK
// Headers presentes
// true
// status deve representar HTTP 200 OK
// ============================================================

void testarCT02() {

    mockHTTP().reset();

    mockHTTP().responseCode = 200;
    mockHTTP().responseBody = "OK";

    String status = "";

    bool retorno = enviarParaUmServidor(
        "http://servidor.local/api",
        "TOKEN123",
        "{\"valor\":10}",
        status
    );

    // O prompt nÃ£o definiu formato textual exato para "status".
    // Consideramos vÃ¡lida uma indicaÃ§Ã£o explÃ­cita do cÃ³digo HTTP 200
    // OU uma indicaÃ§Ã£o textual inequÃ­voca de sucesso.
    String statusNormalizado = status;
    statusNormalizado.toLowerCase();

    bool statusOk =
        status.indexOf("200") >= 0 ||
        statusNormalizado.indexOf("sucesso") >= 0;

    bool ok =
        retorno == true &&
        mockHTTP().postCount == 1 &&
        mockHTTP().url.startsWith("http://") &&
        mockHTTP().contentType == "application/json" &&
        mockHTTP().apiToken == "TOKEN123" &&
        statusOk;

    resultadoCaso("CT02", ok);
}

// ============================================================
// CT03
// HTTPS + resposta 201
// deve usar WiFiClientSecure
// ============================================================

void testarCT03() {

    mockHTTP().reset();

    mockHTTP().responseCode = 201;
    mockHTTP().responseBody = "";

    String status = "";

    bool retorno = enviarParaUmServidor(
        "https://servidor.local/api",
        "TOKEN123",
        "{\"valor\":20}",
        status
    );

    bool ok =
        retorno == true &&
        mockHTTP().postCount == 1 &&
        mockHTTP().secureCreated == true;

    resultadoCaso("CT03", ok);
}

// ============================================================
// CT04
// HTTP 404
// false + status contendo 404
// ============================================================

void testarCT04() {

    mockHTTP().reset();

    mockHTTP().responseCode = 404;
    mockHTTP().responseBody = "Not Found";

    String status = "";

    bool retorno = enviarParaUmServidor(
        "http://servidor.local/inexistente",
        "TOKEN123",
        "{}",
        status
    );

    bool ok =
        retorno == false &&
        mockHTTP().postCount == 1 &&
        status.indexOf("404") >= 0;

    resultadoCaso("CT04", ok);
}

// ============================================================
// CT05
// erro de transporte <= 0
// false + errorToString
// ============================================================

void testarCT05() {

    mockHTTP().reset();

    mockHTTP().responseCode = -1;
    mockHTTP().responseBody = "";

    String status = "";

    bool retorno = enviarParaUmServidor(
        "http://servidor.local/api",
        "TOKEN123",
        "{}",
        status
    );

    bool usaErrorToString =
        status.indexOf("connection refused") >= 0;

    bool ok =
        retorno == false &&
        mockHTTP().postCount == 1 &&
        usaErrorToString;

    resultadoCaso("CT05", ok);
}

// ============================================================
// CT06
// configuraÃ§Ã£o:
// connectTimeout = 8000
// timeout = 60000
// Content-Type JSON
// X-API-Token
// ============================================================

void testarCT06() {

    mockHTTP().reset();

    mockHTTP().responseCode = 200;
    mockHTTP().responseBody = "";

    String status = "";

    enviarParaUmServidor(
        "http://servidor.local/api",
        "TOKEN-CT06",
        "{\"teste\":6}",
        status
    );

    bool ok =
        mockHTTP().connectTimeout == 8000 &&
        mockHTTP().httpTimeout == 60000 &&
        mockHTTP().contentType == "application/json" &&
        mockHTTP().apiToken == "TOKEN-CT06";

    resultadoCaso("CT06", ok);
}

// ============================================================
// SETUP
// ============================================================

void setup() {

    Serial.begin(115200);

    delay(4000);

    Serial.println("BENCHMARK_T28_INICIO");

    testarCT01();
    testarCT02();
    testarCT03();
    testarCT04();
    testarCT05();
    testarCT06();

    Serial.print("APROVADOS:");
    Serial.print(aprovados);
    Serial.print("/");
    Serial.println(TOTAL_CASOS);

    Serial.println("BENCHMARK_T28_FIM");
}

void loop() {
}
