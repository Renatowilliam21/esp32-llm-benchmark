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

    $nomePastaTeste = "T01-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas `
        ($modelo.Pasta + "\T01\codigo.cpp")

    $candidatoInc = Join-Path $pastaTeste "candidato.inc"

    Copy-Item $origem $candidatoInc -Force

    $nomeSketch = $nomePastaTeste + ".ino"
    $arquivoSketch = Join-Path $pastaTeste $nomeSketch

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

void setup() {

    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T01 - passaTesteDegrau");
    Serial.println("======================================");

    // ========================================================
    // CT01
    // ultimo = NaN; novo = 25.0
    // esperado: true e ultimo = 25.0
    // ========================================================

    {
        float ultimoValor = NAN;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                25.0f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct01 =
            (retorno == true) &&
            (fabs(ultimoValor - 25.0f) < 0.001f);

        verificarCaso("CT01", ct01);
    }

    // ========================================================
    // CT02
    // ultimo = 25.0; novo = 28.0; limite = 3.0
    // esperado: true e ultimo = 28.0
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                28.0f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct02 =
            (retorno == true) &&
            (fabs(ultimoValor - 28.0f) < 0.001f);

        verificarCaso("CT02", ct02);
    }

    // ========================================================
    // CT03
    // ultimo = 25.0; novo = 28.1; limite = 3.0
    // esperado: false, ultimo permanece 25.0,
    // contador de rejeicoes incrementa
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                28.1f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct03 =
            (retorno == false) &&
            (fabs(ultimoValor - 25.0f) < 0.001f) &&
            (rejeicoes == 1);

        verificarCaso("CT03", ct03);
    }

    // ========================================================
    // CT04
    // ultimo = 25.0; novo = 21.9; limite = 3.0
    // esperado: false
    // testa diferenca absoluta
    // ========================================================

    {
        float ultimoValor = 25.0f;
        unsigned long rejeicoes = 0;

        bool retorno =
            passaTesteDegrau(
                21.9f,
                ultimoValor,
                3.0f,
                rejeicoes
            );

        bool ct04 =
            (retorno == false) &&
            (fabs(ultimoValor - 25.0f) < 0.001f) &&
            (rejeicoes == 1);

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

    $saida | Tee-Object -FilePath $logCompilacao

    $texto = $saida -join "`n"

    $flashBytes = ""
    $flashPct = ""
    $ramBytes = ""
    $ramPct = ""

    if ($texto -match `
        "Sketch uses\s+(\d+)\s+bytes\s+\((\d+)%\)") {

        $flashBytes = $matches[1]
        $flashPct = $matches[2]
    }

    if ($texto -match `
        "Global variables use\s+(\d+)\s+bytes\s+\((\d+)%\)") {

        $ramBytes = $matches[1]
        $ramPct = $matches[2]
    }

    $compilou = if ($exitCode -eq 0) { 1 } else { 0 }

    $resultados += [PSCustomObject]@{
        tarefa = "T01"
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
    "resultados_compilacao_T01.csv"

$resultados |
    Export-Csv `
    -Path $arquivoCSV `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADO FINAL"
Write-Host "========================================"

$resultados | Format-Table -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $arquivoCSV