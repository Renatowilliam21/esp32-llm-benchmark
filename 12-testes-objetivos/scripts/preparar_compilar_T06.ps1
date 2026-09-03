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

    $nomePastaTeste = "T06-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T06\codigo.cpp")

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

// Código original da LLM
#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float obtido, float esperado, float tolerancia = 0.01f) {
    return fabs(obtido - esperado) <= tolerancia;
}

void caso(const char *id, float obtido, float esperado) {

    casosExecutados++;

    bool aprovado = quaseIgual(obtido, esperado);

    Serial.print(id);
    Serial.print(": obtido=");
    Serial.print(obtido, 4);

    Serial.print(" esperado=");
    Serial.print(esperado, 4);

    Serial.print(" -> ");

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

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T06 - calcularPontoOrvalho");
    Serial.println("======================================");

    // CT01
    caso(
        "CT01",
        calcularPontoOrvalho(20.0f, 50.0f),
        9.2543f
    );

    // CT02
    caso(
        "CT02",
        calcularPontoOrvalho(25.0f, 60.0f),
        16.6842f
    );

    // CT03
    caso(
        "CT03",
        calcularPontoOrvalho(30.0f, 70.0f),
        23.9150f
    );

    // CT04
    caso(
        "CT04",
        calcularPontoOrvalho(35.0f, 80.0f),
        31.0167f
    );

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
    Write-Host "Compilando T06 - $($modelo.Nome)"
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
        tarefa = "T06"
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
        "$baseTestes\resultados_compilacao_T06.csv" `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO T06"
Write-Host "========================================"

$resultados | Format-Table -AutoSize