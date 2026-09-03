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

    $nomeTeste = "T16-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas ($modelo.Pasta + "\T16\codigo.cpp")

    Copy-Item $origem (Join-Path $pastaTeste "candidato.inc") -Force

    $arquivoSketch = Join-Path $pastaTeste ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <math.h>

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.02f) {
    return fabsf(a - b) <= tolerancia;
}

void registrar(const char *id, bool aprovado) {

    casosExecutados++;

    Serial.print(id);
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
    Serial.println("T16 - calcularIndiceCalor");
    Serial.println("======================================");

    // CT01
    // 20 C / 50%
    // Esperado ~= 20.0000
    float r1 = calcularIndiceCalor(20.0f, 50.0f);

    registrar(
        "CT01",
        quaseIgual(r1, 20.0000f)
    );

    // CT02
    // 26.6 C / 90%
    // Esperado ~= 26.6000
    float r2 = calcularIndiceCalor(26.6f, 90.0f);

    registrar(
        "CT02",
        quaseIgual(r2, 26.6000f)
    );

    // CT03
    // 30 C / 70%
    // Esperado ~= 35.0380
    float r3 = calcularIndiceCalor(30.0f, 70.0f);

    registrar(
        "CT03",
        quaseIgual(r3, 35.0380f)
    );

    // CT04
    // 35 C / 80%
    // Esperado ~= 56.5466
    float r4 = calcularIndiceCalor(35.0f, 80.0f);

    registrar(
        "CT04",
        quaseIgual(r4, 56.5466f)
    );

    // CT05
    // Cenário cujo índice calculado ultrapassa 100 C.
    // Deve retornar NaN.
    float r5 = calcularIndiceCalor(50.0f, 100.0f);

    registrar(
        "CT05",
        isnan(r5)
    );

    Serial.println();

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
    Write-Host "T16 - $($modelo.Nome)"
    Write-Host "========================================"

    # COMPILACAO
    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitCompilacao = $LASTEXITCODE

    $saidaCompilacao |
        Tee-Object -FilePath (Join-Path $pastaTeste "compilacao.log")

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
            tarefa = "T16"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            compilou = 0
            C_0_100 = 0
            flash_bytes = $flashBytes
            ram_bytes = $ramBytes
            execucao_ok = 0
            ct01 = 0
            ct02 = 0
            ct03 = 0
            ct04 = 0
            ct05 = 0
            casos_aprovados = 0
            casos_executados = 5
            F_0_100 = 0
            resultado = "COMPILE_FAIL"
        }

        continue
    }

    # UPLOAD
    $saidaUpload = & arduino-cli upload `
        -p $porta `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object -FilePath (Join-Path $pastaTeste "upload.log")

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T16"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            compilou = 1
            C_0_100 = 100
            flash_bytes = $flashBytes
            ram_bytes = $ramBytes
            execucao_ok = 0
            ct01 = ""
            ct02 = ""
            ct03 = ""
            ct04 = ""
            ct05 = ""
            casos_aprovados = ""
            casos_executados = 5
            F_0_100 = ""
            resultado = "UPLOAD_FAIL"
        }

        continue
    }

    # SERIAL
    Start-Sleep -Milliseconds 1000

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

        while (((Get-Date) - $inicio).TotalSeconds -lt 15) {

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

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa = "T16"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            compilou = 1
            C_0_100 = 100
            flash_bytes = $flashBytes
            ram_bytes = $ramBytes
            execucao_ok = 0
            ct01 = ""
            ct02 = ""
            ct03 = ""
            ct04 = ""
            ct05 = ""
            casos_aprovados = ""
            casos_executados = 5
            F_0_100 = ""
            resultado = "INFRA_SERIAL"
        }

        continue
    }

    # RESULTADOS
    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }
    $ct04 = if ($texto -match "CT04 -> PASS") { 1 } else { 0 }
    $ct05 = if ($texto -match "CT05 -> PASS") { 1 } else { 0 }

    $aprovados =
        $ct01 +
        $ct02 +
        $ct03 +
        $ct04 +
        $ct05

    $F = [math]::Round(
        ($aprovados / 5) * 100,
        2
    )

    $resultadoFinal = if ($aprovados -eq 5) {
        "PASS"
    } else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T16"
        modelo_id = $modelo.Id
        modelo = $modelo.Nome
        compilou = 1
        C_0_100 = 100
        flash_bytes = $flashBytes
        ram_bytes = $ramBytes
        execucao_ok = 1
        ct01 = $ct01
        ct02 = $ct02
        ct03 = $ct03
        ct04 = $ct04
        ct05 = $ct05
        casos_aprovados = $aprovados
        casos_executados = 5
        F_0_100 = $F
        resultado = $resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T16.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T16"
Write-Host "========================================"

$resultados |
    Format-Table `
        tarefa,
        modelo_id,
        modelo,
        compilou,
        C_0_100,
        flash_bytes,
        ram_bytes,
        execucao_ok,
        ct01,
        ct02,
        ct03,
        ct04,
        ct05,
        casos_aprovados,
        casos_executados,
        F_0_100,
        resultado `
        -AutoSize