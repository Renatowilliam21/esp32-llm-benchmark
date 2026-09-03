$ErrorActionPreference = "Continue"

# ============================================================
# ESP32-LLM BENCHMARK
# T28 - enviarParaUmServidor()
# FASE B: TESTES FUNCIONAIS CONTROLADOS
#
# CT01..CT06 congelados
# Arduino CLI 1.5.1
# ESP32 core 3.3.8
# FQBN esp32:esp32:esp32
# Porta: COM5
# Baud: 115200
# ============================================================

$root  = "C:\Users\renat\Documents\esp32-llm-benchmark"
$fqbn  = "esp32:esp32:esp32"
$porta = "COM5"

$dirLogs = Join-Path $root "12-testes-objetivos\logs\T28-funcional"
$saidaCsv = Join-Path $root "12-testes-objetivos\resultados_T28_funcional.csv"

New-Item -ItemType Directory -Force -Path $dirLogs | Out-Null

$modelos = @(
    @{
        modelo_id = "LLM01"
        modelo    = "GPT-5.6-Sol"
        pasta     = "LLM01_GPT-5.6-Sol"
    },
    @{
        modelo_id = "LLM02"
        modelo    = "DeepSeek-V4-Pro"
        pasta     = "LLM02_DeepSeek-V4-Pro"
    },
    @{
        modelo_id = "LLM03"
        modelo    = "Claude-Sonnet-5"
        pasta     = "LLM03_Claude-Sonnet-5"
    }
)

$resultados = @()

foreach ($m in $modelos) {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "T28 FUNCIONAL - $($m.modelo_id) - $($m.modelo)"
    Write-Host "============================================================"

    $codigoOriginal = Join-Path `
        $root `
        "05-respostas-llms\$($m.pasta)\T28\codigo.cpp"

    if (-not (Test-Path $codigoOriginal)) {
        throw "Codigo candidato nao encontrado: $codigoOriginal"
    }

    $nomeSketch = "T28-$($m.modelo_id)-funcional"
    $dirSketch = Join-Path `
        $root `
        "12-testes-objetivos\$nomeSketch"

    if (Test-Path $dirSketch) {
        Remove-Item $dirSketch -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $dirSketch | Out-Null

    # ========================================================
    # Preserva candidato sem modificar
    # ========================================================

    $arquivoInc = Join-Path $dirSketch "candidato.inc"

    [IO.File]::WriteAllBytes(
        $arquivoInc,
        [IO.File]::ReadAllBytes($codigoOriginal)
    )

    # ========================================================
    # Mock state
    # ========================================================

    $mockState = @'
#ifndef MOCK_NET_STATE_H
#define MOCK_NET_STATE_H

#include <Arduino.h>

struct MockHTTPState {
    int responseCode;
    String responseBody;

    int postCount;
    int beginCount;
    int endCount;

    bool secureCreated;
    bool insecureCalled;

    int connectTimeout;
    int httpTimeout;
    int clientTimeout;

    String contentType;
    String apiToken;

    String url;
    String postedJson;

    void reset() {
        responseCode = 200;
        responseBody = "";

        postCount = 0;
        beginCount = 0;
        endCount = 0;

        secureCreated = false;
        insecureCalled = false;

        connectTimeout = -1;
        httpTimeout = -1;
        clientTimeout = -1;

        contentType = "";
        apiToken = "";

        url = "";
        postedJson = "";
    }
};

inline MockHTTPState &mockHTTP() {
    static MockHTTPState estado;
    return estado;
}

#endif
'@

    Set-Content `
        -Path (Join-Path $dirSketch "MockNetState.h") `
        -Value $mockState `
        -Encoding UTF8

    # ========================================================
    # Fake WiFiClient
    # ========================================================

    $wifiClient = @'
#ifndef WIFI_CLIENT_H
#define WIFI_CLIENT_H

#include <Arduino.h>
#include "MockNetState.h"

class WiFiClient {
public:
    WiFiClient() {
    }

    virtual ~WiFiClient() {
    }

    void setTimeout(uint32_t timeout) {
        mockHTTP().clientTimeout = (int)timeout;
    }
};

#endif
'@

    Set-Content `
        -Path (Join-Path $dirSketch "WiFiClient.h") `
        -Value $wifiClient `
        -Encoding UTF8

    # ========================================================
    # Fake WiFiClientSecure
    # ========================================================

    $wifiSecure = @'
#ifndef WIFI_CLIENT_SECURE_H
#define WIFI_CLIENT_SECURE_H

#include <Arduino.h>
#include "WiFiClient.h"
#include "MockNetState.h"

class WiFiClientSecure : public WiFiClient {
public:
    WiFiClientSecure() : WiFiClient() {
        mockHTTP().secureCreated = true;
    }

    void setInsecure() {
        mockHTTP().insecureCalled = true;
    }
};

#endif
'@

    Set-Content `
        -Path (Join-Path $dirSketch "WiFiClientSecure.h") `
        -Value $wifiSecure `
        -Encoding UTF8

    # ========================================================
    # Fake WiFi
    # ========================================================

    $wifi = @'
#ifndef WIFI_H
#define WIFI_H

#include <Arduino.h>
#include "WiFiClient.h"

#endif
'@

    Set-Content `
        -Path (Join-Path $dirSketch "WiFi.h") `
        -Value $wifi `
        -Encoding UTF8

    # ========================================================
    # Fake HTTPClient
    # ========================================================

    $httpClient = @'
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
'@

    Set-Content `
        -Path (Join-Path $dirSketch "HTTPClient.h") `
        -Value $httpClient `
        -Encoding UTF8

    # ========================================================
    # Sketch de testes
    # ========================================================

    $harness = @'
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

    // O prompt não definiu formato textual exato para "status".
    // Consideramos válida uma indicação explícita do código HTTP 200
    // OU uma indicação textual inequívoca de sucesso.
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
// configuração:
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
'@

    $arquivoIno = Join-Path $dirSketch "$nomeSketch.ino"

    Set-Content `
        -Path $arquivoIno `
        -Value $harness `
        -Encoding UTF8

    # ========================================================
    # COMPILACAO DO HARNESS FUNCIONAL
    # ========================================================

    $logCompile = Join-Path `
        $dirLogs `
        "T28-$($m.modelo_id)-functional-compile.txt"

    Write-Host "Compilando harness funcional..."

    $saidaCompile = & arduino-cli compile `
        --fqbn $fqbn `
        $dirSketch 2>&1

    $exitCompile = $LASTEXITCODE

    ($saidaCompile | Out-String) |
        Set-Content $logCompile -Encoding UTF8

    if ($exitCompile -ne 0) {

        Write-Host "HARNESS/CANDIDATO NAO COMPILOU NA FASE FUNCIONAL"

        $saidaCompile |
            Select-Object -Last 30 |
            ForEach-Object {
                Write-Host $_
            }

        $resultados += [PSCustomObject]@{
            tarefa          = "T28"
            modelo_id       = $m.modelo_id
            modelo          = $m.modelo
            casos_aprovados = 0
            casos_total     = 6
            F_0_100         = 0
            status_funcional = "FUNCTIONAL_COMPILE_FAIL"
            CT01 = ""
            CT02 = ""
            CT03 = ""
            CT04 = ""
            CT05 = ""
            CT06 = ""
        }

        continue
    }

    # ========================================================
    # UPLOAD
    # ========================================================

    Write-Host "Enviando para ESP32..."

    $logUpload = Join-Path `
        $dirLogs `
        "T28-$($m.modelo_id)-upload.txt"

    $saidaUpload = & arduino-cli upload `
        -p $porta `
        --fqbn $fqbn `
        $dirSketch 2>&1

    $exitUpload = $LASTEXITCODE

    ($saidaUpload | Out-String) |
        Set-Content $logUpload -Encoding UTF8

    if ($exitUpload -ne 0) {

        Write-Host "ERRO DE INFRAESTRUTURA: UPLOAD FALHOU"

        $resultados += [PSCustomObject]@{
            tarefa          = "T28"
            modelo_id       = $m.modelo_id
            modelo          = $m.modelo
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            status_funcional = "UPLOAD_INFRA_FAIL"
            CT01 = ""
            CT02 = ""
            CT03 = ""
            CT04 = ""
            CT05 = ""
            CT06 = ""
        }

        continue
    }

    # ========================================================
    # CAPTURA SERIAL
    # ========================================================

    Write-Host "Capturando Serial..."

    $logSerial = Join-Path `
        $dirLogs `
        "T28-$($m.modelo_id)-serial.txt"

    Start-Sleep -Milliseconds 1000

    $serialText = ""

    try {

        $sp = New-Object System.IO.Ports.SerialPort `
            $porta,
            115200,
            ([System.IO.Ports.Parity]::None),
            8,
            ([System.IO.Ports.StopBits]::One)

        $sp.ReadTimeout = 500
        $sp.DtrEnable = $false
        $sp.RtsEnable = $false

        $sp.Open()

        $inicio = Get-Date

        while (((Get-Date) - $inicio).TotalSeconds -lt 15) {

            try {
                $linha = $sp.ReadLine()

                if ($linha) {
                    $serialText += $linha + "`n"
                    Write-Host $linha
                }

                if ($linha -match "BENCHMARK_T28_FIM") {
                    break
                }
            }
            catch {
                # timeout de leitura: continua
            }
        }

        $sp.Close()
    }
    catch {

        Write-Host "ERRO DE INFRAESTRUTURA NA SERIAL:"
        Write-Host $_.Exception.Message

        $resultados += [PSCustomObject]@{
            tarefa          = "T28"
            modelo_id       = $m.modelo_id
            modelo          = $m.modelo
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            status_funcional = "SERIAL_INFRA_FAIL"
            CT01 = ""
            CT02 = ""
            CT03 = ""
            CT04 = ""
            CT05 = ""
            CT06 = ""
        }

        continue
    }

    $serialText |
        Set-Content `
        -Path $logSerial `
        -Encoding UTF8

    # ========================================================
    # Valida captura
    # ========================================================

    if (
        $serialText -notmatch "BENCHMARK_T28_INICIO" -or
        $serialText -notmatch "BENCHMARK_T28_FIM"
    ) {

        Write-Host "CAPTURA SERIAL INCOMPLETA - RESULTADO INVALIDO"

        $resultados += [PSCustomObject]@{
            tarefa          = "T28"
            modelo_id       = $m.modelo_id
            modelo          = $m.modelo
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            status_funcional = "SERIAL_INCOMPLETE"
            CT01 = ""
            CT02 = ""
            CT03 = ""
            CT04 = ""
            CT05 = ""
            CT06 = ""
        }

        continue
    }

    # ========================================================
    # Extrai resultados
    # ========================================================

    $ct01 = if ($serialText -match "CT01:PASS") { 1 } else { 0 }
    $ct02 = if ($serialText -match "CT02:PASS") { 1 } else { 0 }
    $ct03 = if ($serialText -match "CT03:PASS") { 1 } else { 0 }
    $ct04 = if ($serialText -match "CT04:PASS") { 1 } else { 0 }
    $ct05 = if ($serialText -match "CT05:PASS") { 1 } else { 0 }
    $ct06 = if ($serialText -match "CT06:PASS") { 1 } else { 0 }

    $aprovados =
        $ct01 +
        $ct02 +
        $ct03 +
        $ct04 +
        $ct05 +
        $ct06

    $f100 = [math]::Round(
        ($aprovados / 6.0) * 100,
        2
    )

    Write-Host ""
    Write-Host "Resultado funcional:"
    Write-Host "$aprovados/6 casos"
    Write-Host "F = $f100"

    $resultados += [PSCustomObject]@{
        tarefa          = "T28"
        modelo_id       = $m.modelo_id
        modelo          = $m.modelo
        casos_aprovados = $aprovados
        casos_total     = 6
        F_0_100         = $f100
        status_funcional = "VALID"
        CT01 = $ct01
        CT02 = $ct02
        CT03 = $ct03
        CT04 = $ct04
        CT05 = $ct05
        CT06 = $ct06
    }
}

# ============================================================
# EXPORTA RESULTADOS
# ============================================================

$resultados |
    Export-Csv `
        -Path $saidaCsv `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "RESULTADOS FUNCIONAIS - T28"
Write-Host "============================================================"
Write-Host ""

$resultados |
    Format-Table `
        modelo_id,
        modelo,
        casos_aprovados,
        casos_total,
        F_0_100,
        CT01,
        CT02,
        CT03,
        CT04,
        CT05,
        CT06,
        status_funcional `
        -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $saidaCsv