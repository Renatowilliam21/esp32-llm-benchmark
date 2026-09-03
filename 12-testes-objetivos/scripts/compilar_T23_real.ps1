$ErrorActionPreference = "Continue"

$raiz = (Resolve-Path ".").Path
$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{
        id     = "LLM01"
        nome   = "GPT-5.6-Sol"
        pasta  = "LLM01_GPT-5.6-Sol"
    },
    @{
        id     = "LLM02"
        nome   = "DeepSeek-V4-Pro"
        pasta  = "LLM02_DeepSeek-V4-Pro"
    },
    @{
        id     = "LLM03"
        nome   = "Claude-Sonnet-5"
        pasta  = "LLM03_Claude-Sonnet-5"
    }
)

$resultados = @()

foreach ($modelo in $modelos) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T23 - $($modelo.nome)"
    Write-Host "========================================"

    $arquivoCandidato = Join-Path `
        $raiz `
        "05-respostas-llms\$($modelo.pasta)\T23\codigo.cpp"

    $pastaTeste = Join-Path `
        $raiz `
        "12-testes-objetivos\T23-$($modelo.id)-real"

    if (Test-Path $pastaTeste) {
        Remove-Item $pastaTeste -Recurse -Force
    }

    New-Item -ItemType Directory `
        -Path $pastaTeste `
        -Force | Out-Null

    $arquivoInc = Join-Path $pastaTeste "candidato.inc"

    # Preserva literalmente a resposta candidata
    Copy-Item $arquivoCandidato $arquivoInc -Force

    $arquivoINO = Join-Path `
        $pastaTeste `
        "T23-$($modelo.id)-real.ino"

    $codigoReal = @'
#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_BME280.h>
#include <Adafruit_BMP280.h>
#include <Adafruit_AHTX0.h>
#include <Adafruit_SHT4x.h>
#include <Adafruit_VEML7700.h>
#include <ScioSense_ENS160.h>
#include <RTClib.h>
#include <EEPROM.h>

// ============================================================
// CONTEXTO PADRONIZADO DO PROJETO
// ============================================================

#define PIN_DHT 4
#define DHTTYPE DHT22

DHT dht(PIN_DHT, DHTTYPE);

Adafruit_BME280 bme;
Adafruit_BMP280 bmp;
Adafruit_AHTX0 aht10;
Adafruit_SHT4x sht41;
Adafruit_VEML7700 veml7700;

// Biblioteca ENS160 congelada no ambiente experimental.
ScioSense_ENS160 ens160(ENS160_I2CADDR_1);

RTC_DS3231 rtc;

// ------------------------------------------------------------
// Flags de disponibilidade/saúde do firmware-base
// ------------------------------------------------------------

bool dhtDisponivel = false;
bool dhtSaudavel = false;

bool bme280Disponivel = false;
bool bme280Saudavel = false;

bool bmp280Disponivel = false;
bool bmp280Saudavel = false;

bool aht10Disponivel = false;
bool aht10Saudavel = false;

bool sht41Disponivel = false;
bool sht41Saudavel = false;

bool veml7700Disponivel = false;
bool veml7700Saudavel = false;

bool ens160Disponivel = false;
bool ens160Saudavel = false;

bool rtcDisponivel = false;
bool rtcSaudavel = false;

bool eepromDisponivel = false;
bool eepromSaudavel = false;

bool ldrDisponivel = false;
bool ldrSaudavel = false;

bool usarLDR = false;

const size_t TAMANHO_EEPROM = 4096;

// Protótipo presente no firmware.
void inicializarSensores();

// ============================================================
// CÓDIGO CANDIDATO — NÃO ALTERAR
// ============================================================

#include "candidato.inc"

// ============================================================
// FORÇA INTEGRAÇÃO/LINK DA FUNÇÃO
// ============================================================

void setup() {
    Serial.begin(115200);
    inicializarSensores();
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoINO `
        -Value $codigoReal `
        -Encoding UTF8

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $codigoSaida = $LASTEXITCODE

    $saidaTexto = $saidaCompilacao -join "`n"

    Write-Host $saidaTexto

    $compilou = 0
    $flash = $null
    $ram = $null
    $resultado = "COMPILE_FAIL"

    if ($codigoSaida -eq 0) {

        $compilou = 1
        $resultado = "COMPILE_PASS"

        if (
            $saidaTexto -match
            'Sketch uses\s+([0-9]+)\s+bytes'
        ) {
            $flash = [int]$Matches[1]
        }

        if (
            $saidaTexto -match
            'Global variables use\s+([0-9]+)\s+bytes'
        ) {
            $ram = [int]$Matches[1]
        }
    }

    $resultados += [PSCustomObject]@{
        tarefa      = "T23"
        modelo_id   = $modelo.id
        modelo      = $modelo.nome
        compilou    = $compilou
        C_0_100     = if ($compilou) { 100 } else { 0 }
        flash_bytes = $flash
        ram_bytes   = $ram
        resultado   = $resultado
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO REAL T23"
Write-Host "========================================"

$resultados | Format-Table -AutoSize

$csv = Join-Path `
    $raiz `
    "12-testes-objetivos\resultados_T23_compilacao_real.csv"

$resultados |
    Export-Csv `
        -Path $csv `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $csv
