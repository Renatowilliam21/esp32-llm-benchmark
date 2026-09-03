$root = (Get-Location).Path
$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$modelos = @(
    @{ Id="LLM01"; Nome="GPT-5.6-Sol";     Pasta="LLM01_GPT-5.6-Sol" },
    @{ Id="LLM02"; Nome="DeepSeek-V4-Pro"; Pasta="LLM02_DeepSeek-V4-Pro" },
    @{ Id="LLM03"; Nome="Claude-Sonnet-5"; Pasta="LLM03_Claude-Sonnet-5" }
)

$resultados = @()

foreach ($modelo in $modelos) {

    $nomePastaTeste = "T04-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T04\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomePastaTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <math.h>

// ============================================================
// Mock de analogRead
// ============================================================

int adcSimulado = 0;
int ultimoPinoLido = -1;

int mockAnalogRead(int pino) {
    ultimoPinoLido = pino;
    return adcSimulado;
}

#define analogRead mockAnalogRead

// Código original da LLM
#include "candidato.inc"

#undef analogRead

// ============================================================
// Infraestrutura
// ============================================================

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
    return fabs(a - b) <= tolerancia;
}

void caso(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
    Serial.print(": ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    } else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    const int PINO_TESTE = 35;

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T04 - lerUV");
    Serial.println("======================================");


    // ========================================================
    // CT01 - ADC mínimo
    // ADC=0 -> UV=0.0
    // ========================================================

    adcSimulado = 0;
    ultimoPinoLido = -1;

    float uv1 = lerUV(PINO_TESTE);

    caso(
        "CT01",
        quaseIgual(uv1, 0.0f)
    );


    // ========================================================
    // CT02 - ADC intermediário
    // ADC=2048 -> UV aproximadamente 16.504
    // ========================================================

    adcSimulado = 2048;

    float uv2 = lerUV(PINO_TESTE);

    caso(
        "CT02",
        quaseIgual(uv2, 16.504f)
    );


    // ========================================================
    // CT03 - ADC máximo
    // ADC=4095 -> UV=33.0
    // ========================================================

    adcSimulado = 4095;

    float uv3 = lerUV(PINO_TESTE);

    caso(
        "CT03",
        quaseIgual(uv3, 33.0f)
    );


    // ========================================================
    // CT04 - Não-negatividade
    // Um ADC válido 0..4095 nunca pode produzir valor negativo.
    // Percorremos todo o domínio do ADC de 12 bits.
    // ========================================================

    bool naoNegativo = true;

    for (int adc = 0; adc <= 4095; adc++) {

        adcSimulado = adc;

        float uv = lerUV(PINO_TESTE);

        if (uv < 0.0f) {
            naoNegativo = false;
            break;
        }
    }

    caso(
        "CT04",
        naoNegativo
    );


    // ========================================================
    // Resultado
    // ========================================================

    Serial.println();
    Serial.println("======================================");

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
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
    Write-Host "Compilando T04 - $($modelo.Nome)"
    Write-Host "========================================"

    $log = Join-Path $pastaTeste "compilacao.log"

    $saida = & arduino-cli compile `
        --fqbn esp32:esp32:esp32 `
        $pastaTeste 2>&1

    $exitCode = $LASTEXITCODE

    $saida | Tee-Object -FilePath $log

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
        tarefa = "T04"
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

$resultados |
    Export-Csv `
    "$baseTestes\resultados_compilacao_T04.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO T04"
Write-Host "========================================"

$resultados | Format-Table -AutoSize