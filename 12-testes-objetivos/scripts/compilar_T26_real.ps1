$ErrorActionPreference = "Continue"

# ============================================================
# ESP32-LLM BENCHMARK
# T26 - gravarRegistroPendente()
# FASE A: COMPILACAO / INTEGRACAO
#
# Ambiente congelado:
# Arduino CLI 1.5.1
# ESP32 core 3.3.8
# FQBN esp32:esp32:esp32
# ============================================================

$root = "C:\Users\renat\Documents\esp32-llm-benchmark"
$fqbn = "esp32:esp32:esp32"

$saidaCsv = Join-Path $root "12-testes-objetivos\resultados_T26_compilacao_real.csv"
$dirLogs  = Join-Path $root "12-testes-objetivos\logs\T26"

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
    Write-Host "T26 - $($m.modelo_id) - $($m.modelo)"
    Write-Host "============================================================"

    $codigoOriginal = Join-Path `
        $root `
        "05-respostas-llms\$($m.pasta)\T26\codigo.cpp"

    if (-not (Test-Path $codigoOriginal)) {
        throw "Codigo candidato nao encontrado: $codigoOriginal"
    }

    $nomeSketch = "T26-$($m.modelo_id)-real"
    $dirSketch = Join-Path `
        $root `
        "12-testes-objetivos\$nomeSketch"

    if (Test-Path $dirSketch) {
        Remove-Item $dirSketch -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $dirSketch | Out-Null

    $arquivoInc = Join-Path $dirSketch "candidato.inc"
    $arquivoIno = Join-Path $dirSketch "$nomeSketch.ino"

    Copy-Item $codigoOriginal $arquivoInc -Force

    $harness = @'
#include <Arduino.h>
#include <math.h>
#include <RTClib.h>

// ============================================================
// Estruturas reais
// ============================================================

struct Acumulador {
    double soma = 0;
    int quantidade = 0;

    void adicionar(float valor) {
        if (!isnan(valor)) {
            soma += valor;
            quantidade++;
        }
    }

    float media() const {
        if (quantidade == 0) {
            return NAN;
        }

        return soma / quantidade;
    }

    void limpar() {
        soma = 0;
        quantidade = 0;
    }
};

struct RegistroMeteorologico {
    uint16_t ano;
    uint8_t mes, dia, hora, minuto, segundo;

    float tempGloboNegro, umidGloboNegro;
    float tempAr, umidAr;

    float pressao, altitude;
    float indiceUV, luminosidade;

    float co2, tvoc, aqi;

    float ITGU, ITU;
    float indiceCalor;

    float chuvaMm, velVento;

    bool enviado;
    uint32_t checksum;
};

// ============================================================
// Acumuladores globais reais
// ============================================================

Acumulador acTempGloboNegro;
Acumulador acUmidGloboNegro;

Acumulador acTempAr;
Acumulador acUmidAr;

Acumulador acPressao;
Acumulador acAltitude;

Acumulador acUV;
Acumulador acLDR;

Acumulador acCo2;
Acumulador acTvoc;
Acumulador acAqi;

// ============================================================
// RTC e estado global real
// ============================================================

RTC_DS3231 rtc;

bool rtcDisponivel = false;
bool eepromDisponivel = false;

const int MAX_REGISTROS = 50;

int totalRegistros = 0;
int proximoRegistro = 0;

RegistroMeteorologico registroPendenteRAM;
bool registroPendenteRAMValido = false;

// ============================================================
// Chuva e vento
// ============================================================

const float MM_POR_PULSO_CHUVA = 0.5f;
const float CONSTANTE_ANEMOMETRO = 2.4f;

const unsigned long INTERVALO_AGREGACAO_MS = 60000UL;

volatile unsigned long pulsosChuvaContador = 0;
volatile unsigned long pulsosVentoContador = 0;

// ============================================================
// Funcoes reais utilizadas pela tarefa
// ============================================================

float calcularPontoOrvalho(
    float temperatura,
    float umidade
) {
    float a = 17.27f;
    float b = 237.7f;

    float alpha =
        ((a * temperatura) / (b + temperatura)) +
        log(umidade / 100.0f);

    return (b * alpha) / (a - alpha);
}

float calcularITGU(
    float temperatura,
    float umidade
) {
    return temperatura +
           (0.36f * calcularPontoOrvalho(temperatura, umidade)) +
           41.5f;
}

float calcularITU(
    float temperatura,
    float umidade
) {
    return (0.8f * temperatura) +
           ((umidade / 100.0f) * (temperatura - 14.3f)) +
           46.3f;
}

float calcularIndiceCalor(
    float temperatura,
    float umidade
) {
    if (temperatura < 26.7f) {
        return temperatura;
    }

    float T = temperatura * 9.0f / 5.0f + 32.0f;
    float RH = umidade;

    float HI =
        -42.379f +
        (2.04901523f * T) +
        (10.14333127f * RH) -
        (0.22475541f * T * RH) -
        (0.00683783f * T * T) -
        (0.05481717f * RH * RH) +
        (0.00122874f * T * T * RH) +
        (0.00085282f * T * RH * RH) -
        (0.00000199f * T * T * RH * RH);

    float resultado =
        (HI - 32.0f) * 5.0f / 9.0f;

    if (resultado < -50.0f || resultado > 100.0f) {
        return NAN;
    }

    return resultado;
}

// ============================================================
// Contratos reais da persistencia
// ============================================================

void gravarRegistro(
    int indice,
    RegistroMeteorologico registro
) {
    (void)indice;
    (void)registro;
}

void salvarControleEEPROM() {
}

// ============================================================
// CANDIDATO ORIGINAL
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link
// ============================================================

void setup() {
    Serial.begin(115200);

    gravarRegistroPendente();
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
        "T26-$($m.modelo_id)-compile.txt"

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
            Select-Object -Last 25 |
            ForEach-Object {
                Write-Host $_
            }

        Write-Host "------------------------------------------------------------"
    }

    $resultados += [PSCustomObject]@{
        tarefa      = "T26"
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
Write-Host "RESULTADOS - T26 - FASE A"
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