$ErrorActionPreference = "Continue"

$raiz = (Resolve-Path ".").Path
$baseSaida = Join-Path $raiz "12-testes-objetivos\temp_T30_compilacao"
$csvSaida = Join-Path $raiz "12-testes-objetivos\resultados_T30_compilacao_real.csv"

$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{
        modelo_id = "LLM01"
        modelo = "GPT-5.6-Sol"
        pasta = "LLM01_GPT-5.6-Sol"
    },
    @{
        modelo_id = "LLM02"
        modelo = "DeepSeek-V4-Pro"
        pasta = "LLM02_DeepSeek-V4-Pro"
    },
    @{
        modelo_id = "LLM03"
        modelo = "Claude-Sonnet-5"
        pasta = "LLM03_Claude-Sonnet-5"
    }
)

if (Test-Path $baseSaida) {
    Remove-Item $baseSaida -Recurse -Force
}

New-Item -ItemType Directory -Path $baseSaida -Force | Out-Null

$resultados = @()

foreach ($m in $modelos) {

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "T30 COMPILACAO REAL - $($m.modelo)"
    Write-Host "============================================================"

    $codigoOriginal = Join-Path $raiz `
        "05-respostas-llms\$($m.pasta)\T30\codigo.cpp"

    if (-not (Test-Path $codigoOriginal)) {

        Write-Host "ERRO: codigo.cpp nao encontrado."

        $resultados += [PSCustomObject]@{
            modelo_id = $m.modelo_id
            modelo = $m.modelo
            compilacao = 0
            C_0_100 = 0
            flash_bytes = ""
            ram_bytes = ""
            status = "ARQUIVO_NAO_ENCONTRADO"
        }

        continue
    }

    $pastaSketch = Join-Path $baseSaida $m.modelo_id
    New-Item -ItemType Directory -Path $pastaSketch -Force | Out-Null

    $candidatoDestino = Join-Path $pastaSketch "candidato.inc"

    # Copia byte a byte, sem alterar o candidato.
    [System.IO.File]::WriteAllBytes(
        $candidatoDestino,
        [System.IO.File]::ReadAllBytes($codigoOriginal)
    )

    $nomeSketch = Split-Path $pastaSketch -Leaf
    $arquivoIno = Join-Path $pastaSketch "$nomeSketch.ino"

    $wrapper = @'
#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>

/*
 * ============================================================
 * T30 - CONTEXTO DE INTEGRACAO FIEL AO FIRMWARE-BASE
 * ============================================================
 *
 * O codigo candidato e incluido sem alteracoes.
 * Somente nomes, objetos e estado existentes no firmware
 * original sao disponibilizados.
 */

/* Objetos reais */
Preferences preferencias;
WebServer servidorAdmin(80);

/* Estado da fila */
bool eepromDisponivel = false;

const int MAX_REGISTROS = 100;
int totalRegistros = 0;

struct RegistroMeteorologico {
    uint16_t ano;
    uint8_t mes;
    uint8_t dia;
    uint8_t hora;
    uint8_t minuto;
    uint8_t segundo;

    float tempGloboNegro;
    float umidGloboNegro;

    float tempAr;
    float umidAr;

    float pressao;
    float altitude;

    float indiceUV;
    float luminosidade;

    float co2;
    float tvoc;
    float aqi;

    float ITGU;
    float ITU;
    float indiceCalor;

    float chuvaMm;
    float velVento;

    bool enviado;
    uint32_t checksum;
};

RegistroMeteorologico registroPendenteRAM;
bool registroPendenteRAMValido = false;

/* Estado real dos sensores */
bool sht4Disponivel = false;
bool bmeDisponivel = false;
bool bmpDisponivel = false;
bool ahtDisponivel = false;
bool vemlDisponivel = false;
bool ens160Disponivel = false;
bool rtcDisponivel = false;

/* Fonte ambiente */
String fonteAmbienteAtual = "nenhuma";

/* Configuracao real dos destinos */
String servidorUrlLocal = "";
String tokenLocal = "";

String servidorUrlProducao = "";
String tokenProducao = "";

/* Status real dos envios */
String ultimoStatusLocal = "";
String ultimoStatusProducao = "";

/*
 * A funcao deve ser fornecida pelo candidato.
 */
void configurarServidorAdmin();

/* ============================================================
 * CODIGO CANDIDATO - COPIADO SEM ALTERACOES
 * ============================================================
 */
#include "candidato.inc"

/*
 * Forca compilacao e vinculacao da rotina.
 */
void setup() {
    Serial.begin(115200);
    configurarServidorAdmin();
}

void loop() {
    servidorAdmin.handleClient();
}
'@

    Set-Content `
        -Path $arquivoIno `
        -Value $wrapper `
        -Encoding UTF8

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaSketch 2>&1

    $codigoSaida = $LASTEXITCODE
    $textoSaida = ($saidaCompilacao | Out-String)

    Write-Host $textoSaida

    if ($codigoSaida -eq 0) {

        Write-Host "RESULTADO: PASS"

        $flash = ""
        $ram = ""

        if ($textoSaida -match 'Sketch uses\s+([0-9]+)\s+bytes') {
            $flash = $matches[1]
        }

        if ($textoSaida -match 'Global variables use\s+([0-9]+)\s+bytes') {
            $ram = $matches[1]
        }

        $resultados += [PSCustomObject]@{
            modelo_id = $m.modelo_id
            modelo = $m.modelo
            compilacao = 1
            C_0_100 = 100
            flash_bytes = $flash
            ram_bytes = $ram
            status = "PASS"
        }

    }
    else {

        Write-Host "RESULTADO: COMPILE_FAIL"

        $resultados += [PSCustomObject]@{
            modelo_id = $m.modelo_id
            modelo = $m.modelo
            compilacao = 0
            C_0_100 = 0
            flash_bytes = ""
            ram_bytes = ""
            status = "COMPILE_FAIL"
        }
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "RESULTADOS DE COMPILACAO REAL - T30"
Write-Host "============================================================"

$resultados | Format-Table -AutoSize

$resultados |
    Export-Csv `
        -Path $csvSaida `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $csvSaida