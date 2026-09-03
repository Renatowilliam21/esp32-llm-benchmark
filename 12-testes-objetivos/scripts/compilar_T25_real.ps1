$ErrorActionPreference = "Continue"

# ============================================================
# ESP32-LLM BENCHMARK
# T25 - coletarAmostra()
# FASE A: COMPILACAO / INTEGRACAO
#
# Ambiente congelado:
# Arduino CLI 1.5.1
# ESP32 core 3.3.8
# FQBN esp32:esp32:esp32
#
# Regra:
# - candidato copiado sem alteracao;
# - nenhum alias criado para ajudar qualquer LLM;
# - contexto segue os nomes e contratos reais do firmware-base;
# - falha de compilacao/integracao => C = 0.
# ============================================================

$root = "C:\Users\renat\Documents\esp32-llm-benchmark"
$fqbn = "esp32:esp32:esp32"

$saidaCsv = Join-Path $root "12-testes-objetivos\resultados_T25_compilacao_real.csv"
$dirLogs  = Join-Path $root "12-testes-objetivos\logs\T25"

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
    Write-Host "T25 - $($m.modelo_id) - $($m.modelo)"
    Write-Host "============================================================"

    $codigoOriginal = Join-Path `
        $root `
        "05-respostas-llms\$($m.pasta)\T25\codigo.cpp"

    if (-not (Test-Path $codigoOriginal)) {
        throw "Codigo candidato nao encontrado: $codigoOriginal"
    }

    # --------------------------------------------------------
    # Pasta isolada para compilacao
    # --------------------------------------------------------
    $nomeSketch = "T25-$($m.modelo_id)-real"
    $dirSketch = Join-Path `
        $root `
        "12-testes-objetivos\$nomeSketch"

    if (Test-Path $dirSketch) {
        Remove-Item $dirSketch -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $dirSketch | Out-Null

    $arquivoInc = Join-Path $dirSketch "candidato.inc"
    $arquivoIno = Join-Path $dirSketch "$nomeSketch.ino"

    # Candidato preservado byte a byte.
    Copy-Item $codigoOriginal $arquivoInc -Force

    # --------------------------------------------------------
    # Harness de integracao
    #
    # Os nomes/assinaturas abaixo reproduzem o contexto
    # relevante existente no firmware-base.
    # --------------------------------------------------------
    $harness = @'
#include <Arduino.h>
#include <math.h>

// ============================================================
// Estrutura real de acumulacao
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

// ============================================================
// Acumuladores globais reais
// ============================================================

Acumulador acTempGloboNegro;
Acumulador acUmidGloboNegro;

Acumulador acTempAr;
Acumulador acUmidAr;

Acumulador acPressao;
Acumulador acAltitude;

Acumulador acCo2;
Acumulador acTvoc;
Acumulador acAqi;

Acumulador acUV;
Acumulador acLDR;

// ============================================================
// Contadores e estado reais relevantes
// ============================================================

unsigned long leiturasDescartadasFaixa = 0;

const float TEMP_MIN_VALIDA = -40.0f;
const float TEMP_MAX_VALIDA = 85.0f;

const float UMIDADE_MIN_VALIDA = 0.0f;
const float UMIDADE_MAX_VALIDA = 100.0f;

const float PRESSAO_MIN_VALIDA = 300.0f;
const float PRESSAO_MAX_VALIDA = 1100.0f;

const float UV_MAX_VALIDO = 20.0f;

const float DEGRAU_MAX_VARIACAO_C = 3.0f;

float ultimaTempGloboNegroValida = NAN;
float ultimaTempArValida = NAN;

unsigned long degrauRejeicoes = 0;

String fonteAmbienteAtual = "nenhuma";

// ============================================================
// Contratos reais das funcoes auxiliares
// ============================================================

bool faixaValida(float valor, float minimo, float maximo) {
    if (isnan(valor)) {
        return false;
    }

    return valor >= minimo && valor <= maximo;
}

bool passaTesteDegrau(
    float novoValor,
    float &ultimoValorValido
) {
    if (isnan(ultimoValorValido)) {
        ultimoValorValido = novoValor;
        return true;
    }

    if (fabs(novoValor - ultimoValorValido) <= DEGRAU_MAX_VARIACAO_C) {
        ultimoValorValido = novoValor;
        return true;
    }

    degrauRejeicoes++;
    return false;
}

void lerAmbiente(
    float &temperatura,
    float &umidade,
    float dhtTempJaLido,
    float dhtUmidJaLido
) {
    temperatura = dhtTempJaLido;
    umidade = dhtUmidJaLido;
}

void lerPressaoAltitude(
    float &pressao,
    float &altitude
) {
    pressao = 1013.25f;
    altitude = 100.0f;
}

void lerQualidadeAr(
    float &co2,
    float &tvoc,
    float &aqi
) {
    co2 = 500.0f;
    tvoc = 10.0f;
    aqi = 1.0f;
}

float lerUV() {
    return 1.0f;
}

float lerLDR() {
    return 50.0f;
}

// ============================================================
// CANDIDATO - COPIADO SEM ALTERACAO
// ============================================================

#include "candidato.inc"

// ============================================================
// Entrada minima para forcar compilacao e link da tarefa
// ============================================================

void setup() {
    Serial.begin(115200);

    // Forca referencia real a funcao solicitada.
    coletarAmostra();
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoIno `
        -Value $harness `
        -Encoding UTF8

    # --------------------------------------------------------
    # Compilacao
    # --------------------------------------------------------
    $arquivoLog = Join-Path `
        $dirLogs `
        "T25-$($m.modelo_id)-compile.txt"

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

        # Extracao de Flash
        if ($textoSaida -match 'Sketch uses\s+([0-9]+)\s+bytes') {
            $flash = $matches[1]
        }

        # Extracao de RAM
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
            Select-Object -Last 20 |
            ForEach-Object {
                Write-Host $_
            }

        Write-Host "------------------------------------------------------------"
    }

    $resultados += [PSCustomObject]@{
        tarefa      = "T25"
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

# ============================================================
# Exportacao
# ============================================================

$resultados |
    Export-Csv `
        -Path $saidaCsv `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "============================================================"
Write-Host "RESULTADOS - T25 - FASE A"
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
