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

    $nomeTeste = "T17-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste
    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas ($modelo.Pasta + "\T17\codigo.cpp")
    Copy-Item $origem (Join-Path $pastaTeste "candidato.inc") -Force

    # --------------------------------------------------------
    # Wire.h local para interceptar inclusive #include <Wire.h>
    # --------------------------------------------------------
    $wireMock = @'
#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t enderecoI2C = 0;
    uint8_t bytes[10];
    int quantidadeBytes = 0;
    int chamadasBegin = 0;
    int chamadasEnd = 0;

    void reset() {
        enderecoI2C = 0;
        quantidadeBytes = 0;
        chamadasBegin = 0;
        chamadasEnd = 0;

        for (int i = 0; i < 10; i++) {
            bytes[i] = 0;
        }
    }

    void beginTransmission(uint8_t endereco) {
        enderecoI2C = endereco;
        chamadasBegin++;
    }

    size_t write(uint8_t valor) {
        if (quantidadeBytes < 10) {
            bytes[quantidadeBytes++] = valor;
        }
        return 1;
    }

    uint8_t endTransmission() {
        chamadasEnd++;
        return 0;
    }
};

extern MockWire Wire;

#endif
'@

    Set-Content `
        (Join-Path $pastaTeste "Wire.h") `
        $wireMock `
        -Encoding UTF8

    # --------------------------------------------------------
    # Harness
    # --------------------------------------------------------
    $arquivoSketch = Join-Path $pastaTeste ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

/*
 * Interceptação determinística de delay().
 */
unsigned long benchmarkDelayMs = 0;
int benchmarkChamadasDelay = 0;

void benchmarkDelay(unsigned long ms) {
    benchmarkDelayMs = ms;
    benchmarkChamadasDelay++;
}

#define delay(ms) benchmarkDelay(ms)

#include "candidato.inc"

#undef delay

int casosExecutados = 0;
int casosAprovados = 0;

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

void resetarTudo() {
    Wire.reset();
    benchmarkDelayMs = 0;
    benchmarkChamadasDelay = 0;
}

void setup() {

    Serial.begin(115200);

    /*
     * Aqui usamos ::delay para garantir o delay real do harness,
     * pois a macro já foi removida após candidato.inc.
     */
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T17 - escreverEEPROM");
    Serial.println("======================================");

    // ======================================================
    // CT01
    // endereco = 0x1234
    // valor    = 0xAB
    //
    // Esperado:
    // Wire.write recebe 0x12, 0x34, 0xAB nessa ordem.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct01 =
        Wire.quantidadeBytes == 3 &&
        Wire.bytes[0] == 0x12 &&
        Wire.bytes[1] == 0x34 &&
        Wire.bytes[2] == 0xAB;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    // beginTransmission deve utilizar 0x50.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct02 =
        Wire.chamadasBegin == 1 &&
        Wire.enderecoI2C == 0x50;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    // Deve existir espera de 5 ms após endTransmission().
    //
    // Aqui verificamos:
    // - endTransmission chamado;
    // - delay chamado;
    // - valor exatamente 5 ms.
    // ======================================================

    resetarTudo();

    escreverEEPROM(0x1234, 0xAB);

    bool ct03 =
        Wire.chamadasEnd == 1 &&
        benchmarkChamadasDelay == 1 &&
        benchmarkDelayMs == 5;

    registrar("CT03", ct03);

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

    Set-Content $arquivoSketch $harness -Encoding UTF8

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T17 - $($modelo.Nome)"
    Write-Host "========================================"

    # --------------------------------------------------------
    # COMPILACAO
    # --------------------------------------------------------
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
            tarefa="T17"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=0
            C_0_100=0
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            execucao_ok=0
            ct01=0
            ct02=0
            ct03=0
            casos_aprovados=0
            casos_executados=3
            F_0_100=0
            resultado="COMPILE_FAIL"
        }

        continue
    }

    # --------------------------------------------------------
    # UPLOAD
    # --------------------------------------------------------
    $saidaUpload = & arduino-cli upload `
        -p $porta `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object -FilePath (Join-Path $pastaTeste "upload.log")

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T17"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            casos_aprovados=""
            casos_executados=3
            F_0_100=""
            resultado="UPLOAD_FAIL"
        }

        continue
    }

    # --------------------------------------------------------
    # SERIAL
    # --------------------------------------------------------
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
        (Join-Path $pastaTeste "execucao_serial.log") `
        -Encoding UTF8

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa="T17"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            casos_aprovados=""
            casos_executados=3
            F_0_100=""
            resultado="INFRA_SERIAL"
        }

        continue
    }

    # --------------------------------------------------------
    # RESULTADO FUNCIONAL
    # --------------------------------------------------------
    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }

    $aprovados = $ct01 + $ct02 + $ct03

    $F = [math]::Round(
        ($aprovados / 3) * 100,
        2
    )

    $resultadoFinal = if ($aprovados -eq 3) {
        "PASS"
    } else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa="T17"
        modelo_id=$modelo.Id
        modelo=$modelo.Nome
        compilou=1
        C_0_100=100
        flash_bytes=$flashBytes
        ram_bytes=$ramBytes
        execucao_ok=1
        ct01=$ct01
        ct02=$ct02
        ct03=$ct03
        casos_aprovados=$aprovados
        casos_executados=3
        F_0_100=$F
        resultado=$resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T17.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T17"
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
        casos_aprovados,
        casos_executados,
        F_0_100,
        resultado `
        -AutoSize