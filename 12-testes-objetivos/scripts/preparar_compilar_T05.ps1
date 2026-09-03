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

    $nomePastaTeste = "T05-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T05\codigo.cpp")

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

// Código original gerado pela LLM
#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

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

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T05 - faixaValida");
    Serial.println("======================================");

    const float minimo = 0.0f;
    const float maximo = 10.0f;

    // CT01 - NaN
    caso(
        "CT01",
        faixaValida(NAN, minimo, maximo) == false
    );

    // CT02 - abaixo do mínimo
    caso(
        "CT02",
        faixaValida(-0.1f, minimo, maximo) == false
    );

    // CT03 - limite inferior
    caso(
        "CT03",
        faixaValida(0.0f, minimo, maximo) == true
    );

    // CT04 - limite superior
    caso(
        "CT04",
        faixaValida(10.0f, minimo, maximo) == true
    );

    // CT05 - acima do máximo
    caso(
        "CT05",
        faixaValida(10.1f, minimo, maximo) == false
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
    Write-Host "Compilando T05 - $($modelo.Nome)"
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
        tarefa = "T05"
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
        "$baseTestes\resultados_compilacao_T05.csv" `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO T05"
Write-Host "========================================"

$resultados |
    Format-Table -AutoSize