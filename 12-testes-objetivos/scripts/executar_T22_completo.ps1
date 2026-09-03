$root = (Get-Location).Path
$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$fqbn = "esp32:esp32:esp32"
$com = "COM5"
$baud = 115200

$modelos = @(
    @{ Id="LLM01"; Nome="GPT-5.6-Sol";     Pasta="LLM01_GPT-5.6-Sol" },
    @{ Id="LLM02"; Nome="DeepSeek-V4-Pro"; Pasta="LLM02_DeepSeek-V4-Pro" },
    @{ Id="LLM03"; Nome="Claude-Sonnet-5"; Pasta="LLM03_Claude-Sonnet-5" }
)

$resultados = @()

foreach ($modelo in $modelos) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T22 - $($modelo.Nome)"
    Write-Host "========================================"

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T22\codigo.cpp")

    if (-not (Test-Path $origem)) {
        throw "Arquivo nao encontrado: $origem"
    }

    # ========================================================
    # FASE A - COMPILACAO REAL
    # ========================================================

    $pastaReal = Join-Path `
        $baseTestes `
        ("T22-" + $modelo.Id + "-real")

    if (Test-Path $pastaReal) {
        Remove-Item $pastaReal -Recurse -Force
    }

    New-Item -ItemType Directory -Force $pastaReal | Out-Null

    Copy-Item `
        $origem `
        (Join-Path $pastaReal "candidato.inc") `
        -Force

    $sketchReal = Join-Path `
        $pastaReal `
        ("T22-" + $modelo.Id + "-real.ino")

    $codigoReal = @'
#include <Arduino.h>
#include "esp_task_wdt.h"
#include <WiFi.h>
#include <WebServer.h>
#include <esp_task_wdt.h>

WebServer server(80);

unsigned long ultimaColeta = 0;
unsigned long ultimaAgregacao = 0;
unsigned long ultimaTentativaEnvio = 0;

const unsigned long INTERVALO_COLETA = 1000;
const unsigned long INTERVALO_AGREGACAO = 5000;
const unsigned long INTERVALO_ENVIO = 10000;

/*
 * Funcoes que ja pertencem ao contexto do firmware.
 */
void processarComandosSeriais() {
}

void coletarAmostra() {
}

void gravarRegistroPendente() {
}

void tentarDrenarFila() {
}

/*
 * Codigo da LLM preservado sem modificacoes.
 */
#include "candidato.inc"

void setup() {
    Serial.begin(115200);
}
'@

    Set-Content `
        -Path $sketchReal `
        -Value $codigoReal `
        -Encoding UTF8

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaReal 2>&1

    $exitCompilacao = $LASTEXITCODE

    $saidaCompilacao |
        Tee-Object `
        -FilePath (Join-Path $pastaReal "compilacao.log")

    $textoCompilacao = $saidaCompilacao -join "`n"

    $flashBytes = ""
    $ramBytes = ""

    if ($textoCompilacao -match "Sketch uses\s+(\d+)\s+bytes") {
        $flashBytes = $matches[1]
    }

    if ($textoCompilacao -match "Global variables use\s+(\d+)\s+bytes") {
        $ramBytes = $matches[1]
    }

    if ($exitCompilacao -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T22"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=0
            C_0_100=0
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=0
            execucao_ok=0
            ct01=0
            ct02=0
            ct03=0
            ct04=0
            ct05=0
            casos_aprovados=0
            casos_executados=5
            F_0_100=0
            resultado="COMPILE_FAIL"
        }

        continue
    }

    # ========================================================
    # FASE B - HARNESS FUNCIONAL
    # ========================================================

    $pastaFunc = Join-Path `
        $baseTestes `
        ("T22-" + $modelo.Id + "-funcional")

    if (Test-Path $pastaFunc) {
        Remove-Item $pastaFunc -Recurse -Force
    }

    New-Item -ItemType Directory -Force $pastaFunc | Out-Null

    Copy-Item `
        $origem `
        (Join-Path $pastaFunc "candidato.inc") `
        -Force

    # ========================================================
    # WiFi.h MOCK
    # ========================================================

    $wifiHeader = @'
#ifndef BENCHMARK_WIFI_H
#define BENCHMARK_WIFI_H

#include <Arduino.h>

#ifndef WL_CONNECTED
#define WL_CONNECTED 3
#endif

class BenchmarkWiFiClass {
public:
    bool conectado = true;
    int chamadasStatus = 0;
    int chamadasReconnect = 0;

    int status() {
        chamadasStatus++;

        if (conectado) {
            return WL_CONNECTED;
        }

        return 0;
    }

    void reconnect() {
        chamadasReconnect++;
    }
};

extern BenchmarkWiFiClass WiFi;

#endif
'@

    Set-Content `
        -Path (Join-Path $pastaFunc "WiFi.h") `
        -Value $wifiHeader `
        -Encoding UTF8

    # ========================================================
    # esp_task_wdt.h MOCK
    # ========================================================

    $wdtHeader = @'
#ifndef BENCHMARK_ESP_TASK_WDT_H
#define BENCHMARK_ESP_TASK_WDT_H

typedef int esp_err_t;

#define ESP_OK 0

extern int benchmarkWdtReset;

inline esp_err_t esp_task_wdt_reset() {
    benchmarkWdtReset++;
    return ESP_OK;
}

#endif
'@

    Set-Content `
        -Path (Join-Path $pastaFunc "esp_task_wdt.h") `
        -Value $wdtHeader `
        -Encoding UTF8

    # ========================================================
    # HARNESS FUNCIONAL
    # ========================================================

    $sketchFunc = Join-Path `
        $pastaFunc `
        ("T22-" + $modelo.Id + "-funcional.ino")

    $harness = @'
#include <Arduino.h>
#include "esp_task_wdt.h"

/*
 * ==========================================================
 * ESTADO CONTROLADO
 * ==========================================================
 */

unsigned long benchmarkAgora = 0;

unsigned long ultimaColeta = 0;
unsigned long ultimaAgregacao = 0;
unsigned long ultimaTentativaEnvio = 0;

const unsigned long INTERVALO_COLETA = 1000;
const unsigned long INTERVALO_AGREGACAO = 5000;
const unsigned long INTERVALO_ENVIO = 10000;

int benchmarkWdtReset = 0;

int chamadasHandleClient = 0;
int chamadasProcessarSerial = 0;

int chamadasColetar = 0;
int chamadasGravar = 0;
int chamadasDrenar = 0;

/*
 * ==========================================================
 * Wi-Fi
 * ==========================================================
 */

#include "WiFi.h"

BenchmarkWiFiClass WiFi;

/*
 * ==========================================================
 * SERVER MOCK
 * ==========================================================
 */

class BenchmarkServer {
public:
    void handleClient() {
        chamadasHandleClient++;
    }
};

BenchmarkServer server;

/*
 * ==========================================================
 * millis() CONTROLADO
 * ==========================================================
 */

unsigned long benchmarkMillis() {
    return benchmarkAgora;
}

/*
 * ==========================================================
 * FUNCOES DO FIRMWARE
 * ==========================================================
 */

void benchmarkProcessarComandosSeriais() {
    chamadasProcessarSerial++;
}

void benchmarkColetarAmostra() {
    chamadasColetar++;
}

void benchmarkGravarRegistroPendente() {
    chamadasGravar++;
}

void benchmarkTentarDrenarFila() {
    chamadasDrenar++;
}

/*
 * ==========================================================
 * INTERCEPTACOES
 * ==========================================================
 *
 * O arquivo candidato permanece byte a byte inalterado.
 */

#define millis benchmarkMillis

#define processarComandosSeriais \
    benchmarkProcessarComandosSeriais

#define coletarAmostra \
    benchmarkColetarAmostra

#define gravarRegistroPendente \
    benchmarkGravarRegistroPendente

#define tentarDrenarFila \
    benchmarkTentarDrenarFila

#define loop loopCandidato

#include "candidato.inc"

#undef loop
#undef millis
#undef processarComandosSeriais
#undef coletarAmostra
#undef gravarRegistroPendente
#undef tentarDrenarFila

/*
 * ==========================================================
 * UTILITARIOS
 * ==========================================================
 */

int casosAprovados = 0;
int casosExecutados = 0;

void registrarCaso(
    const char *id,
    bool resultado
) {

    casosExecutados++;

    Serial0.print(id);
    Serial0.print(" -> ");

    if (resultado) {
        casosAprovados++;
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void limparContadores() {

    benchmarkWdtReset = 0;

    chamadasHandleClient = 0;
    chamadasProcessarSerial = 0;

    chamadasColetar = 0;
    chamadasGravar = 0;
    chamadasDrenar = 0;

    WiFi.chamadasStatus = 0;
    WiFi.chamadasReconnect = 0;
}

/*
 * ==========================================================
 * SETUP DO HARNESS
 * ==========================================================
 */

void setup() {

    Serial0.begin(115200);

    /*
     * Tempo para a captura serial apos o upload/reset.
     */
    delay(4000);

    Serial0.println();
    Serial0.println("======================================");
    Serial0.println("ESP32-LLM BENCHMARK");
    Serial0.println("T22 - loop");
    Serial0.println("======================================");

    /*
     * ======================================================
     * CT01
     * Wi-Fi desconectado.
     * Deve tentar reconectar e retornar sem realizar
     * coleta, agregacao ou envio.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = false;

    benchmarkAgora = 20000;

    ultimaColeta = 0;
    ultimaAgregacao = 0;
    ultimaTentativaEnvio = 0;

    loopCandidato();

    bool ct01 =
        WiFi.chamadasReconnect >= 1 &&
        chamadasColetar == 0 &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0 &&
        ultimaColeta == 0 &&
        ultimaAgregacao == 0 &&
        ultimaTentativaEnvio == 0;

    registrarCaso("CT01", ct01);

    /*
     * ======================================================
     * CT02
     * Primeira coleta.
     *
     * ultimaColeta = 0 e intervalo de coleta atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_COLETA;

    ultimaColeta = 0;

    /*
     * Evita disparar agregacao e envio neste CT.
     */
    ultimaAgregacao = benchmarkAgora;
    ultimaTentativaEnvio = benchmarkAgora;

    loopCandidato();

    bool ct02 =
        chamadasColetar == 1 &&
        ultimaColeta == benchmarkAgora &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0;

    registrarCaso("CT02", ct02);

    /*
     * ======================================================
     * CT03
     * Intervalo de agregacao atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_AGREGACAO;

    ultimaColeta = benchmarkAgora;
    ultimaAgregacao = 0;
    ultimaTentativaEnvio = benchmarkAgora;

    loopCandidato();

    bool ct03 =
        chamadasGravar == 1 &&
        ultimaAgregacao == benchmarkAgora &&
        chamadasColetar == 0 &&
        chamadasDrenar == 0;

    registrarCaso("CT03", ct03);

    /*
     * ======================================================
     * CT04
     * Intervalo de envio atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = INTERVALO_ENVIO;

    ultimaColeta = benchmarkAgora;
    ultimaAgregacao = benchmarkAgora;
    ultimaTentativaEnvio = 0;

    loopCandidato();

    bool ct04 =
        chamadasDrenar == 1 &&
        ultimaTentativaEnvio == benchmarkAgora &&
        chamadasColetar == 0 &&
        chamadasGravar == 0;

    registrarCaso("CT04", ct04);

    /*
     * ======================================================
     * CT05
     * Nenhum intervalo atingido.
     * ======================================================
     */

    limparContadores();

    WiFi.conectado = true;

    benchmarkAgora = 20000;

    ultimaColeta =
        benchmarkAgora - INTERVALO_COLETA + 1;

    ultimaAgregacao =
        benchmarkAgora - INTERVALO_AGREGACAO + 1;

    ultimaTentativaEnvio =
        benchmarkAgora - INTERVALO_ENVIO + 1;

    unsigned long coletaAntes = ultimaColeta;
    unsigned long agregacaoAntes = ultimaAgregacao;
    unsigned long envioAntes = ultimaTentativaEnvio;

    loopCandidato();

    bool ct05 =
        chamadasColetar == 0 &&
        chamadasGravar == 0 &&
        chamadasDrenar == 0 &&
        ultimaColeta == coletaAntes &&
        ultimaAgregacao == agregacaoAntes &&
        ultimaTentativaEnvio == envioAntes;

    registrarCaso("CT05", ct05);

    /*
     * ======================================================
     * RESULTADO
     * ======================================================
     */

    Serial0.println();

    Serial0.print("CASOS_APROVADOS=");
    Serial0.println(casosAprovados);

    Serial0.print("CASOS_EXECUTADOS=");
    Serial0.println(casosExecutados);

    Serial0.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void loop() {
}
'@

    Set-Content `
        -Path $sketchFunc `
        -Value $harness `
        -Encoding UTF8

    # ========================================================
    # COMPILACAO DO HARNESS
    # ========================================================

    $saidaFuncional = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaFunc 2>&1

    $exitFuncional = $LASTEXITCODE

    $saidaFuncional |
        Tee-Object `
        -FilePath (Join-Path $pastaFunc "compilacao_funcional.log")

    if ($exitFuncional -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T22"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=0
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            ct04=""
            ct05=""
            casos_aprovados=""
            casos_executados=5
            F_0_100=""
            resultado="HARNESS_COMPILE_FAIL"
        }

        continue
    }

    # ========================================================
    # UPLOAD
    # ========================================================

    $saidaUpload = & arduino-cli upload `
        -p $com `
        --fqbn $fqbn `
        $pastaFunc 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object `
        -FilePath (Join-Path $pastaFunc "upload.log")

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T22"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=1
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            ct04=""
            ct05=""
            casos_aprovados=""
            casos_executados=5
            F_0_100=""
            resultado="UPLOAD_FAIL"
        }

        continue
    }

    # ========================================================
    # CAPTURA SERIAL
    # ========================================================

    Start-Sleep -Milliseconds 1000

    $textoSerial = ""

    try {

        $portaSerial = [System.IO.Ports.SerialPort]::new(
            $com,
            $baud,
            [System.IO.Ports.Parity]::None,
            8,
            [System.IO.Ports.StopBits]::One
        )

        $portaSerial.ReadTimeout = 500

        $portaSerial.Open()

        $cronometro = [System.Diagnostics.Stopwatch]::StartNew()

        while ($cronometro.Elapsed.TotalSeconds -lt 15) {

            try {

                $linha = $portaSerial.ReadLine()

                if ($null -ne $linha) {

                    Write-Host $linha

                    $textoSerial += $linha + "`n"

                    if ($linha -match "RESULTADO=(PASS|FAIL)") {
                        break
                    }
                }
            }
            catch [System.TimeoutException] {
            }
        }

        $cronometro.Stop()
    }
    catch {

        Write-Host "ERRO SERIAL: $($_.Exception.Message)"
    }
    finally {

        if ($null -ne $portaSerial) {

            if ($portaSerial.IsOpen) {
                $portaSerial.Close()
            }

            $portaSerial.Dispose()
        }
    }

    $textoSerial |
        Set-Content `
        -Path (Join-Path $pastaFunc "execucao_serial.log") `
        -Encoding UTF8

    # ========================================================
    # FALHA DE INFRAESTRUTURA SERIAL
    # ========================================================

    if ($textoSerial -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa="T22"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=1
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            ct04=""
            ct05=""
            casos_aprovados=""
            casos_executados=5
            F_0_100=""
            resultado="INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # PARSE DOS CTs
    # ========================================================

    $ct01 = if ($textoSerial -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($textoSerial -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($textoSerial -match "CT03 -> PASS") { 1 } else { 0 }
    $ct04 = if ($textoSerial -match "CT04 -> PASS") { 1 } else { 0 }
    $ct05 = if ($textoSerial -match "CT05 -> PASS") { 1 } else { 0 }

    $aprovados =
        $ct01 +
        $ct02 +
        $ct03 +
        $ct04 +
        $ct05

    $F = [math]::Round(
        ($aprovados / 5) * 100,
        2
    )

    $resultadoFinal = if ($aprovados -eq 5) {
        "PASS"
    }
    else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa="T22"
        modelo_id=$modelo.Id
        modelo=$modelo.Nome
        compilou=1
        C_0_100=100
        flash_bytes=$flashBytes
        ram_bytes=$ramBytes
        funcional_compilou=1
        execucao_ok=1
        ct01=$ct01
        ct02=$ct02
        ct03=$ct03
        ct04=$ct04
        ct05=$ct05
        casos_aprovados=$aprovados
        casos_executados=5
        F_0_100=$F
        resultado=$resultadoFinal
    }
}

# ============================================================
# CSV
# ============================================================

$arquivoCSV = Join-Path `
    $baseTestes `
    "resultados_T22.csv"

$resultados |
    Export-Csv `
        $arquivoCSV `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T22"
Write-Host "========================================"

$resultados |
    Format-Table `
        tarefa,
        modelo_id,
        modelo,
        compilou,
        C_0_100,
        flash_bytes,
        ram_bytes,
        funcional_compilou,
        execucao_ok,
        ct01,
        ct02,
        ct03,
        ct04,
        ct05,
        casos_aprovados,
        casos_executados,
        F_0_100,
        resultado `
        -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $arquivoCSV
