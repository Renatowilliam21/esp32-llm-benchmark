$root = (Get-Location).Path

$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$porta = "COM5"
$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{
        Id="LLM01"
        Nome="GPT-5.6-Sol"
        Pasta="LLM01_GPT-5.6-Sol"
    },
    @{
        Id="LLM02"
        Nome="DeepSeek-V4-Pro"
        Pasta="LLM02_DeepSeek-V4-Pro"
    },
    @{
        Id="LLM03"
        Nome="Claude-Sonnet-5"
        Pasta="LLM03_Claude-Sonnet-5"
    }
)

$resultados = @()

foreach ($modelo in $modelos) {

    $nomePastaTeste = "T07-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomePastaTeste

    New-Item `
        -ItemType Directory `
        -Force `
        $pastaTeste | Out-Null

    # ============================================================
    # COPIA O CÓDIGO ORIGINAL SEM ALTERAÇÃO
    # ============================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T07\codigo.cpp")

    $candidato = Join-Path `
        $pastaTeste `
        "candidato.inc"

    Copy-Item `
        $origem `
        $candidato `
        -Force

    # ============================================================
    # CRIA HARNESS
    # ============================================================

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomePastaTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(
    float obtido,
    float esperado,
    float tolerancia = 0.01f
) {
    return fabs(obtido - esperado) <= tolerancia;
}

void caso(
    const char *id,
    float obtido,
    float esperado
) {

    casosExecutados++;

    bool aprovado =
        quaseIgual(
            obtido,
            esperado,
            0.01f
        );

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
    Serial.println(
        "======================================"
    );

    Serial.println(
        "ESP32-LLM BENCHMARK"
    );

    Serial.println(
        "T07 - calcularITGU"
    );

    Serial.println(
        "======================================"
    );

    // CT01
    caso(
        "CT01",
        calcularITGU(
            20.0f,
            50.0f
        ),
        64.8315f
    );

    // CT02
    caso(
        "CT02",
        calcularITGU(
            25.0f,
            60.0f
        ),
        72.5063f
    );

    // CT03
    caso(
        "CT03",
        calcularITGU(
            30.0f,
            70.0f
        ),
        80.1094f
    );

    // CT04
    caso(
        "CT04",
        calcularITGU(
            35.0f,
            80.0f
        ),
        87.6660f
    );

    Serial.println();

    Serial.println(
        "======================================"
    );

    Serial.print(
        "CASOS_APROVADOS="
    );

    Serial.println(
        casosAprovados
    );

    Serial.print(
        "CASOS_EXECUTADOS="
    );

    Serial.println(
        casosExecutados
    );

    Serial.print(
        "RESULTADO="
    );

    if (
        casosAprovados ==
        casosExecutados
    ) {

        Serial.println("PASS");

    } else {

        Serial.println("FAIL");
    }

    Serial.println(
        "======================================"
    );
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoSketch `
        -Value $harness `
        -Encoding UTF8

    # ============================================================
    # COMPILAÇÃO
    # ============================================================

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T07 - $($modelo.Nome)"
    Write-Host "========================================"

    $logCompilacao = Join-Path `
        $pastaTeste `
        "compilacao.log"

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitCompilacao = $LASTEXITCODE

    $saidaCompilacao |
        Tee-Object `
            -FilePath $logCompilacao

    $textoCompilacao =
        $saidaCompilacao -join "`n"

    $flashBytes = ""
    $flashPct = ""

    $ramBytes = ""
    $ramPct = ""

    if (
        $textoCompilacao -match `
        "Sketch uses\s+(\d+)\s+bytes\s+\((\d+)%\)"
    ) {

        $flashBytes = $matches[1]
        $flashPct = $matches[2]
    }

    if (
        $textoCompilacao -match `
        "Global variables use\s+(\d+)\s+bytes\s+\((\d+)%\)"
    ) {

        $ramBytes = $matches[1]
        $ramPct = $matches[2]
    }

    if ($exitCompilacao -ne 0) {

        $resultados += [PSCustomObject]@{

            tarefa = "T07"

            modelo_id =
                $modelo.Id

            modelo =
                $modelo.Nome

            compilou = 0

            C_0_100 = 0

            flash_bytes = $flashBytes

            ram_bytes = $ramBytes

            execucao_ok = 0

            casos_aprovados = 0

            casos_executados = 4

            F_0_100 = 0

            resultado =
                "COMPILE_FAIL"
        }

        continue
    }

    # ============================================================
    # UPLOAD
    # ============================================================

    $logUpload = Join-Path `
        $pastaTeste `
        "upload.log"

    $saidaUpload = & arduino-cli upload `
        -p $porta `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object `
            -FilePath $logUpload

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{

            tarefa = "T07"

            modelo_id =
                $modelo.Id

            modelo =
                $modelo.Nome

            compilou = 1

            C_0_100 = 100

            flash_bytes =
                $flashBytes

            ram_bytes =
                $ramBytes

            execucao_ok = 0

            casos_aprovados = ""

            casos_executados = 4

            F_0_100 = ""

            resultado =
                "UPLOAD_FAIL"
        }

        continue
    }

    # ============================================================
    # SERIAL
    # ============================================================

    Start-Sleep `
        -Milliseconds 300

    $serial =
        New-Object `
        System.IO.Ports.SerialPort

    $serial.PortName = $porta
    $serial.BaudRate = 115200
    $serial.DataBits = 8
    $serial.Parity = "None"
    $serial.StopBits = "One"
    $serial.ReadTimeout = 500

    $texto = ""

    try {

        $serial.Open()

        $inicio = Get-Date

        while (
            ((Get-Date) - $inicio).
            TotalSeconds -lt 10
        ) {

            try {

                $linha =
                    $serial.ReadLine()

                if ($linha) {

                    Write-Host $linha

                    $texto +=
                        $linha + "`n"

                    if (
                        $linha -match `
                        "RESULTADO=(PASS|FAIL)"
                    ) {

                        break
                    }
                }

            }
            catch [System.TimeoutException] {
}
        }

    }
    finally {

        if ($serial.IsOpen) {
            $serial.Close()
        }
    }

    $texto |
        Set-Content `
            -Path (
                Join-Path `
                $pastaTeste `
                "execucao_serial.log"
            ) `
            -Encoding UTF8

    # ============================================================
    # RESULTADO FUNCIONAL
    # ============================================================

    $aprovados = 0
    $executados = 4

    $execucaoOK = 0

    $resultadoFinal =
        "SEM_RESULTADO"

    if (
        $texto -match `
        "CASOS_APROVADOS=(\d+)"
    ) {

        $aprovados =
            [int]$matches[1]
    }

    if (
        $texto -match `
        "CASOS_EXECUTADOS=(\d+)"
    ) {

        $executados =
            [int]$matches[1]
    }

    if (
        $texto -match `
        "RESULTADO=(PASS|FAIL)"
    ) {

        $resultadoFinal =
            $matches[1]

        $execucaoOK = 1
    }

    if (
        $execucaoOK -eq 1 `
        -and `
        $executados -gt 0
    ) {

        $F = [math]::Round(
            (
                $aprovados /
                $executados
            ) * 100,
            2
        )

    } else {

        $F = ""
    }

    $resultados +=
        [PSCustomObject]@{

        tarefa = "T07"

        modelo_id =
            $modelo.Id

        modelo =
            $modelo.Nome

        compilou = 1

        C_0_100 = 100

        flash_bytes =
            $flashBytes

        ram_bytes =
            $ramBytes

        execucao_ok =
            $execucaoOK

        casos_aprovados =
            $aprovados

        casos_executados =
            $executados

        F_0_100 = $F

        resultado =
            $resultadoFinal
    }
}

# ================================================================
# EXPORTA RESULTADOS
# ================================================================

$arquivoCSV = Join-Path `
    $baseTestes `
    "resultados_T07.csv"

$resultados |
    Export-Csv `
        $arquivoCSV `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T07"
Write-Host "========================================"

$resultados |
    Format-Table -AutoSize

Write-Host ""
Write-Host "CSV:"
Write-Host $arquivoCSV