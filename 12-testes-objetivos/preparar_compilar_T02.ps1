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

    $nomePastaTeste = "T02-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T02\codigo.cpp")

    $candidatoInc = Join-Path $pastaTeste "candidato.inc"

    Copy-Item $origem $candidatoInc -Force

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomePastaTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

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

bool quaseIgual(float a, float b, float tolerancia = 0.001f) {
    return fabs(a - b) <= tolerancia;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T02 - Acumulador");
    Serial.println("======================================");


    // ========================================================
    // CT01
    // adicionar 10, 20, 30
    // esperado: soma=60, quantidade=3, media=20
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(20.0f);
        a.adicionar(30.0f);

        bool ct01 =
            quaseIgual(a.soma, 60.0f) &&
            (a.quantidade == 3) &&
            quaseIgual(a.media(), 20.0f);

        verificarCaso("CT01", ct01);
    }


    // ========================================================
    // CT02
    // adicionar 10, NaN, 20
    // esperado: soma=30, quantidade=2, media=15
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(NAN);
        a.adicionar(20.0f);

        bool ct02 =
            quaseIgual(a.soma, 30.0f) &&
            (a.quantidade == 2) &&
            quaseIgual(a.media(), 15.0f);

        verificarCaso("CT02", ct02);
    }


    // ========================================================
    // CT03
    // acumulador novo
    // esperado: media = NaN
    // ========================================================

    {
        Acumulador a{};

        bool ct03 =
            isnan(a.media());

        verificarCaso("CT03", ct03);
    }


    // ========================================================
    // CT04
    // apos adicionar valores, limpar()
    // esperado: soma=0, quantidade=0, media=NaN
    // ========================================================

    {
        Acumulador a{};

        a.adicionar(10.0f);
        a.adicionar(20.0f);

        a.limpar();

        bool ct04 =
            quaseIgual(a.soma, 0.0f) &&
            (a.quantidade == 0) &&
            isnan(a.media());

        verificarCaso("CT04", ct04);
    }


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

    $logCompilacao = Join-Path $pastaTeste "compilacao.log"

    Write-Host ""
    Write-Host "========================================"
    Write-Host "Compilando $($modelo.Nome)"
    Write-Host "========================================"

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
        tarefa = "T02"
        modelo_id = $modelo.Id
        modelo = $modelo.Nome
        compilou = $compilou
        C_0_100 = if ($compilou -eq 1) { 100 } else { 0 }
        flash_bytes = $flashBytes
        flash_percentual = $flashPct
        ram_bytes = $ramBytes
        ram_percentual = $ramPct
        fqbn = "esp32:esp32:esp32"
        esp32_core = "3.3.8"
        arduino_cli = "1.5.1"
    }
}

$arquivoCSV = Join-Path `
    $baseTestes `
    "resultados_compilacao_T02.csv"

$resultados |
    Export-Csv `
    -Path $arquivoCSV `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS COMPILACAO T02"
Write-Host "========================================"

$resultados |
    Format-Table -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $arquivoCSV