$ErrorActionPreference = "Continue"

# ============================================================
# ESP32-LLM BENCHMARK
# T28 - enviarParaUmServidor()
# FASE A: COMPILACAO / INTEGRACAO REAL
#
# Ambiente congelado:
# Arduino CLI 1.5.1
# ESP32 core 3.3.8
# FQBN esp32:esp32:esp32
# ============================================================

$root = "C:\Users\renat\Documents\esp32-llm-benchmark"
$fqbn = "esp32:esp32:esp32"

$saidaCsv = Join-Path $root "12-testes-objetivos\resultados_T28_compilacao_real.csv"
$dirLogs  = Join-Path $root "12-testes-objetivos\logs\T28"

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
    Write-Host "T28 - $($m.modelo_id) - $($m.modelo)"
    Write-Host "============================================================"

    $codigoOriginal = Join-Path `
        $root `
        "05-respostas-llms\$($m.pasta)\T28\codigo.cpp"

    if (-not (Test-Path $codigoOriginal)) {
        throw "Codigo candidato nao encontrado: $codigoOriginal"
    }

    $nomeSketch = "T28-$($m.modelo_id)-real"
    $dirSketch = Join-Path `
        $root `
        "12-testes-objetivos\$nomeSketch"

    if (Test-Path $dirSketch) {
        Remove-Item $dirSketch -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $dirSketch | Out-Null

    $arquivoInc = Join-Path $dirSketch "candidato.inc"
    $arquivoIno = Join-Path $dirSketch "$nomeSketch.ino"

    # Preserva o candidato sem alteracoes
    Copy-Item $codigoOriginal $arquivoInc -Force

    $harness = @'
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
'@

    Set-Content `
        -Path $arquivoIno `
        -Value $harness `
        -Encoding UTF8

    $arquivoLog = Join-Path `
        $dirLogs `
        "T28-$($m.modelo_id)-compile.txt"

    Write-Host "Compilando..."

    $saida = & arduino-cli compile `
        --fqbn $fqbn `
        $dirSketch 2>&1

    $codigoSaida = $LASTEXITCODE
    $textoSaida = ($saida | Out-String)

    $textoSaida | Set-Content `
        -Path $arquivoLog `
        -Encoding UTF8

    $compilou = 0
    $c100 = 0
    $status = "COMPILE_FAIL"

    $flash = ""
    $ram = ""

    if ($codigoSaida -eq 0) {

        $compilou = 1
        $c100 = 100
        $status = "PASS"

        if ($textoSaida -match 'Sketch uses\s+([0-9]+)\s+bytes') {
            $flash = $matches[1]
        }

        if ($textoSaida -match 'Global variables use\s+([0-9]+)\s+bytes') {
            $ram = $matches[1]
        }

        Write-Host "RESULTADO: COMPILOU"
        Write-Host "Flash: $flash"
        Write-Host "RAM:   $ram"
    }
    else {

        Write-Host "RESULTADO: COMPILE_FAIL"

        Write-Host ""
        Write-Host "Ultimas linhas do erro:"
        Write-Host "------------------------------------------------------------"

        $saida |
            Select-Object -Last 30 |
            ForEach-Object {
                Write-Host $_
            }

        Write-Host "------------------------------------------------------------"
    }

    $resultados += [PSCustomObject]@{
        tarefa      = "T28"
        modelo_id   = $m.modelo_id
        modelo      = $m.modelo
        compilou    = $compilou
        C_0_100     = $c100
        status      = $status
        flash_bytes = $flash
        ram_bytes   = $ram
        log          = $arquivoLog
    }
}

$resultados |
    Export-Csv `
        -Path $saidaCsv `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "RESULTADOS - T28 - FASE A"
Write-Host "============================================================"
Write-Host ""

$resultados |
    Format-Table `
        tarefa,
        modelo_id,
        modelo,
        compilou,
        C_0_100,
        status,
        flash_bytes,
        ram_bytes `
        -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $saidaCsv

Write-Host ""
Write-Host "Logs salvos em:"
Write-Host $dirLogs