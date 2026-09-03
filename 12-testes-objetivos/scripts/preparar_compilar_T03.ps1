$root = (Get-Location).Path
$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$modelos = @(
    @{
        Id = "LLM01"
        Nome = "GPT-5.6-Sol"
        Pasta = "LLM01_GPT-5.6-Sol"
    },
    @{
        Id = "LLM02"
        Nome = "DeepSeek-V4-Pro"
        Pasta = "LLM02_DeepSeek-V4-Pro"
    },
    @{
        Id = "LLM03"
        Nome = "Claude-Sonnet-5"
        Pasta = "LLM03_Claude-Sonnet-5"
    }
)

$resultados = @()

foreach ($modelo in $modelos) {

    $nomePastaTeste = "T03-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T03\codigo.cpp")

    $candidatoInc = Join-Path $pastaTeste "candidato.inc"

    Copy-Item $origem $candidatoInc -Force

    # ============================================================
    # MOCK LOCAL DE Wire.h
    # ============================================================

    $arquivoWire = Join-Path $pastaTeste "Wire.h"

    $mockWire = @'
#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t ultimoEndereco = 0;
    uint8_t retornoEndTransmission = 0;

    void beginTransmission(uint8_t endereco) {
        ultimoEndereco = endereco;
    }

    uint8_t endTransmission() {
        return retornoEndTransmission;
    }
};

extern MockWire Wire;

#endif
'@

    Set-Content `
        -Path $arquivoWire `
        -Value $mockWire `
        -Encoding UTF8

    # ============================================================
    # SKETCH DE TESTE
    # ============================================================

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomePastaTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

// ============================================================
// Código candidato - preservado sem alteração
// ============================================================

#include "candidato.inc"

// ============================================================
// Infraestrutura de testes
// ============================================================

int testesExecutados = 0;
int testesAprovados = 0;

void verificarCaso(const char *id, bool condicao) {

    testesExecutados++;

    Serial.print(id);
    Serial.print(": ");

    if (condicao) {
        testesAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T03 - detectarEeprom");
    Serial.println("======================================");

    // ========================================================
    // CT01
    // ACK em 0x50 -> true
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 0;

    bool r1 = detectarEeprom();

    bool ct01 =
        (r1 == true) &&
        (Wire.ultimoEndereco == 0x50);

    verificarCaso("CT01", ct01);


    // ========================================================
    // CT02
    // NACK -> false
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 2;

    bool r2 = detectarEeprom();

    bool ct02 =
        (r2 == false);

    verificarCaso("CT02", ct02);


    // ========================================================
    // CT03
    // deve iniciar transmissão em 0x50
    // ========================================================

    Wire.ultimoEndereco = 0;
    Wire.retornoEndTransmission = 4;

    detectarEeprom();

    bool ct03 =
        (Wire.ultimoEndereco == 0x50);

    verificarCaso("CT03", ct03);


    // ========================================================
    // Resultado
    // ========================================================

    Serial.println();
    Serial.println("======================================");

    Serial.print("TESTES_APROVADOS=");
    Serial.println(testesAprovados);

    Serial.print("TESTES_EXECUTADOS=");
    Serial.println(testesExecutados);

    Serial.print("RESULTADO=");

    if (testesAprovados == testesExecutados) {
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }

    Serial.println("======================================");
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoSketch `
        -Value $harness `
        -Encoding UTF8

    Write-Host ""
    Write-Host "========================================"
    Write-Host "Compilando T03 - $($modelo.Nome)"
    Write-Host "========================================"

    $logCompilacao = Join-Path $pastaTeste "compilacao.log"

    $saida = & arduino-cli compile `
        --fqbn esp32:esp32:esp32 `
        $pastaTeste 2>&1

    $exitCode = $LASTEXITCODE

    $saida |
        Tee-Object -FilePath $logCompilacao

    $texto = $saida -join "`n"

    $flashBytes = ""
    $flashPct = ""
    $ramBytes = ""
    $ramPct = ""

    if ($texto -match "Sketch uses\s+(\d+)\s+bytes\s+\((\d+)%\)") {
        $flashBytes = $matches[1]
        $flashPct = $matches[2]
    }

    if ($texto -match "Global variables use\s+(\d+)\s+bytes\s+\((\d+)%\)") {
        $ramBytes = $matches[1]
        $ramPct = $matches[2]
    }

    $compilou = if ($exitCode -eq 0) { 1 } else { 0 }

    $resultados += [PSCustomObject]@{
        tarefa = "T03"
        modelo_id = $modelo.Id
        modelo = $modelo.Nome
        compilou = $compilou
        C_0_100 = if ($compilou -eq 1) { 100 } else { 0 }
        flash_bytes = $flashBytes
        flash_percentual = $flashPct
        ram_bytes = $ramBytes
        ram_percentual = $ramPct
    }
}

$arquivoCSV = Join-Path `
    $baseTestes `
    "resultados_compilacao_T03.csv"

$resultados |
    Export-Csv `
    -Path $arquivoCSV `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO T03"
Write-Host "========================================"

$resultados | Format-Table -AutoSize