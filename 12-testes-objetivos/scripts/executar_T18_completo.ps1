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

    $nomeTeste = "T18-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas ($modelo.Pasta + "\T18\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    # ========================================================
    # Mock local de Wire.h
    # ========================================================

    $wireMock = @'
#ifndef BENCHMARK_MOCK_WIRE_H
#define BENCHMARK_MOCK_WIRE_H

#include <Arduino.h>

class MockWire {
public:
    uint8_t enderecoBegin = 0;
    uint8_t enderecoRequest = 0;

    uint8_t bytes[10];
    int quantidadeBytes = 0;

    uint8_t quantidadeSolicitada = 0;

    bool disponivel = false;
    uint8_t valorLeitura = 0;

    int chamadasBegin = 0;
    int chamadasEnd = 0;
    int chamadasRequest = 0;
    int chamadasRead = 0;

    bool ultimoStop = true;

    void reset() {
        enderecoBegin = 0;
        enderecoRequest = 0;

        quantidadeBytes = 0;
        quantidadeSolicitada = 0;

        disponivel = false;
        valorLeitura = 0;

        chamadasBegin = 0;
        chamadasEnd = 0;
        chamadasRequest = 0;
        chamadasRead = 0;

        ultimoStop = true;

        for (int i = 0; i < 10; i++) {
            bytes[i] = 0;
        }
    }

    void beginTransmission(uint8_t endereco) {
        enderecoBegin = endereco;
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
        ultimoStop = true;
        return 0;
    }

    uint8_t endTransmission(bool stop) {
        chamadasEnd++;
        ultimoStop = stop;
        return 0;
    }

    uint8_t requestFrom(uint8_t endereco, uint8_t quantidade) {
        enderecoRequest = endereco;
        quantidadeSolicitada = quantidade;
        chamadasRequest++;

        return disponivel ? quantidade : 0;
    }

    int available() {
        return disponivel ? 1 : 0;
    }

    int read() {
        chamadasRead++;
        return valorLeitura;
    }
};

extern MockWire Wire;

#endif
'@

    Set-Content `
        (Join-Path $pastaTeste "Wire.h") `
        $wireMock `
        -Encoding UTF8

    # ========================================================
    # Harness
    # ========================================================

    $arquivoSketch = Join-Path $pastaTeste ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include "Wire.h"

MockWire Wire;

#include "candidato.inc"

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

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T18 - lerEEPROM");
    Serial.println("======================================");

    // ======================================================
    // CT01
    //
    // endereco = 0x1234
    // available = true
    // read = 0xAB
    //
    // Esperado:
    // - escreve 0x12 e 0x34
    // - solicita 1 byte
    // - retorna 0xAB
    // ======================================================

    Wire.reset();

    Wire.disponivel = true;
    Wire.valorLeitura = 0xAB;

    uint8_t r1 = lerEEPROM(0x1234);

    bool ct01 =
        Wire.quantidadeBytes == 2 &&
        Wire.bytes[0] == 0x12 &&
        Wire.bytes[1] == 0x34 &&
        Wire.quantidadeSolicitada == 1 &&
        r1 == 0xAB;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    //
    // Nenhum byte disponível.
    //
    // Esperado:
    // retorno = 0
    // ======================================================

    Wire.reset();

    Wire.disponivel = false;
    Wire.valorLeitura = 0xAB;

    uint8_t r2 = lerEEPROM(0x1234);

    bool ct02 =
        r2 == 0 &&
        Wire.chamadasRead == 0;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    //
    // Tanto beginTransmission quanto requestFrom
    // devem utilizar o endereço 0x50.
    // ======================================================

    Wire.reset();

    Wire.disponivel = true;
    Wire.valorLeitura = 0x55;

    lerEEPROM(0x1234);

    bool ct03 =
        Wire.enderecoBegin == 0x50 &&
        Wire.enderecoRequest == 0x50 &&
        Wire.quantidadeSolicitada == 1;

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

    Set-Content `
        -Path $arquivoSketch `
        -Value $harness `
        -Encoding UTF8

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T18 - $($modelo.Nome)"
    Write-Host "========================================"

    # ========================================================
    # COMPILACAO
    # ========================================================

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
            tarefa = "T18"
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
            casos_aprovados = 0
            casos_executados = 3
            F_0_100 = 0
            resultado = "COMPILE_FAIL"
        }

        continue
    }

    # ========================================================
    # UPLOAD
    # ========================================================

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
            tarefa = "T18"
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
            casos_aprovados = ""
            casos_executados = 3
            F_0_100 = ""
            resultado = "UPLOAD_FAIL"
        }

        continue
    }

    # ========================================================
    # SERIAL
    # ========================================================

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
            tarefa = "T18"
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
            casos_aprovados = ""
            casos_executados = 3
            F_0_100 = ""
            resultado = "INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # RESULTADO FUNCIONAL
    # ========================================================

    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }

    $aprovados =
        $ct01 +
        $ct02 +
        $ct03

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
        tarefa = "T18"
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
        casos_aprovados = $aprovados
        casos_executados = 3
        F_0_100 = $F
        resultado = $resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T18.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T18"
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