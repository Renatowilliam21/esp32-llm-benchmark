$root = (Get-Location).Path
$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$porta = "COM5"
$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{ Id="LLM01"; Nome="GPT-5.6-Sol";     Pasta="LLM01_GPT-5.6-Sol" },
    @{ Id="LLM02"; Nome="DeepSeek-V4-Pro"; Pasta="LLM02_DeepSeek-V4-Pro" },
    @{ Id="LLM03"; Nome="Claude-Sonnet-5"; Pasta="LLM03_Claude-Sonnet-5" }
)

$resultados = @()

foreach ($modelo in $modelos) {

    $nomeTeste = "T09-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # Código original da LLM, preservado sem alteração
    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T09\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

void caso(
    const char *id,
    float entrada,
    const char *esperado
) {
    casosExecutados++;

    String obtido = classificarIndiceCalor(entrada);

    bool aprovado = (obtido == String(esperado));

    Serial.print(id);
    Serial.print(": obtido=\"");
    Serial.print(obtido);
    Serial.print("\" esperado=\"");
    Serial.print(esperado);
    Serial.print("\" -> ");

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
    Serial.println("T09 - classificarIndiceCalor");
    Serial.println("======================================");

    // CT01
    caso(
        "CT01",
        NAN,
        ""
    );

    // CT02
    caso(
        "CT02",
        27.0f,
        "normal"
    );

    // CT03
    caso(
        "CT03",
        27.01f,
        "atencao"
    );

    // CT04
    caso(
        "CT04",
        32.0f,
        "atencao"
    );

    // CT05
    caso(
        "CT05",
        32.01f,
        "atencao_extrema"
    );

    // CT06
    caso(
        "CT06",
        41.0f,
        "atencao_extrema"
    );

    // CT07
    caso(
        "CT07",
        41.01f,
        "perigo"
    );

    // CT08
    caso(
        "CT08",
        54.0f,
        "perigo"
    );

    // CT09
    caso(
        "CT09",
        54.01f,
        "perigo_extremo"
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
    Write-Host "T09 - $($modelo.Nome)"
    Write-Host "========================================"

    # --------------------------------------------------------
    # Compilação
    # --------------------------------------------------------

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitCompilacao = $LASTEXITCODE

    $saidaCompilacao |
        Tee-Object `
        -FilePath (Join-Path $pastaTeste "compilacao.log")

    $textoCompilacao = $saidaCompilacao -join "`n"

    $flashBytes = ""
    $ramBytes = ""

    if ($textoCompilacao -match "Sketch uses\s+(\d+)\s+bytes") {
        $flashBytes = $matches[1]
    }

    if ($textoCompilacao -match "Global variables use\s+(\d+)\s+bytes") {
        $ramBytes = $matches[1]
    }

    if ($exitCompilacao -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T09"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            compilou = 0
            C_0_100 = 0
            flash_bytes = $flashBytes
            ram_bytes = $ramBytes
            execucao_ok = 0
            casos_aprovados = 0
            casos_executados = 9
            F_0_100 = 0
            resultado = "COMPILE_FAIL"
        }

        continue
    }

    # --------------------------------------------------------
    # Upload
    # --------------------------------------------------------

    $saidaUpload = & arduino-cli upload `
        -p $porta `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object `
        -FilePath (Join-Path $pastaTeste "upload.log")

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T09"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            compilou = 1
            C_0_100 = 100
            flash_bytes = $flashBytes
            ram_bytes = $ramBytes
            execucao_ok = 0
            casos_aprovados = ""
            casos_executados = 9
            F_0_100 = ""
            resultado = "UPLOAD_FAIL"
        }

        continue
    }

    # --------------------------------------------------------
    # Serial
    # --------------------------------------------------------

    Start-Sleep -Milliseconds 300

    $serial = New-Object System.IO.Ports.SerialPort

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

        while (((Get-Date) - $inicio).TotalSeconds -lt 10) {

            try {

                $linha = $serial.ReadLine()

                if ($linha) {

                    Write-Host $linha
                    $texto += $linha + "`n"

                    if ($linha -match "RESULTADO=(PASS|FAIL)") {
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
        -Path (Join-Path $pastaTeste "execucao_serial.log") `
        -Encoding UTF8

    # --------------------------------------------------------
    # Resultado funcional
    # --------------------------------------------------------

    $aprovados = 0
    $executados = 9
    $execucaoOK = 0
    $resultadoFinal = "SEM_RESULTADO"

    if ($texto -match "CASOS_APROVADOS=(\d+)") {
        $aprovados = [int]$matches[1]
    }

    if ($texto -match "CASOS_EXECUTADOS=(\d+)") {
        $executados = [int]$matches[1]
    }

    if ($texto -match "RESULTADO=(PASS|FAIL)") {
        $resultadoFinal = $matches[1]
        $execucaoOK = 1
    }

    if ($execucaoOK -eq 1) {
        $F = [math]::Round(
            ($aprovados / $executados) * 100,
            2
        )
    }
    else {
        $F = ""
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T09"
        modelo_id = $modelo.Id
        modelo = $modelo.Nome
        compilou = 1
        C_0_100 = 100
        flash_bytes = $flashBytes
        ram_bytes = $ramBytes
        execucao_ok = $execucaoOK
        casos_aprovados = $aprovados
        casos_executados = $executados
        F_0_100 = $F
        resultado = $resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T09.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T09"
Write-Host "========================================"

$resultados | Format-Table -AutoSize