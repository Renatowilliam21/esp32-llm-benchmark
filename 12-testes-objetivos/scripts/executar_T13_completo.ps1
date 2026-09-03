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

    $nomeTeste = "T13-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # ========================================================
    # Código oficial preservado sem alteração
    # ========================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T13\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    # ========================================================
    # Wire.h falso local
    #
    # Também resolve corretamente o #include <Wire.h>
    # presente na resposta do DeepSeek.
    # ========================================================

    $fakeWire = @'
#ifndef BENCHMARK_FAKE_WIRE_H
#define BENCHMARK_FAKE_WIRE_H

#include <Arduino.h>

class MockWireClass {
public:

    uint8_t enderecoBegin = 0;
    uint8_t registradorEscrito = 0;

    uint8_t enderecoRequest = 0;
    uint8_t quantidadeRequest = 0;

    uint8_t retornoEndTransmission = 0;
    uint8_t retornoRequestFrom = 1;

    int quantidadeDisponivel = 1;
    int valorLeitura = 0;

    int chamadasBeginTransmission = 0;
    int chamadasWrite = 0;
    int chamadasEndTransmission = 0;
    int chamadasRequestFrom = 0;
    int chamadasAvailable = 0;
    int chamadasRead = 0;

    bool ultimoStop = true;

    void reset() {

        enderecoBegin = 0;
        registradorEscrito = 0;

        enderecoRequest = 0;
        quantidadeRequest = 0;

        retornoEndTransmission = 0;
        retornoRequestFrom = 1;

        quantidadeDisponivel = 1;
        valorLeitura = 0;

        chamadasBeginTransmission = 0;
        chamadasWrite = 0;
        chamadasEndTransmission = 0;
        chamadasRequestFrom = 0;
        chamadasAvailable = 0;
        chamadasRead = 0;

        ultimoStop = true;
    }

    void beginTransmission(uint8_t endereco) {
        chamadasBeginTransmission++;
        enderecoBegin = endereco;
    }

    size_t write(uint8_t valor) {
        chamadasWrite++;
        registradorEscrito = valor;
        return 1;
    }

    uint8_t endTransmission(bool stopBit = true) {
        chamadasEndTransmission++;
        ultimoStop = stopBit;
        return retornoEndTransmission;
    }

    uint8_t requestFrom(uint8_t endereco, uint8_t quantidade) {
        chamadasRequestFrom++;
        enderecoRequest = endereco;
        quantidadeRequest = quantidade;
        return retornoRequestFrom;
    }

    int available() {
        chamadasAvailable++;
        return quantidadeDisponivel;
    }

    int read() {
        chamadasRead++;
        return valorLeitura;
    }
};

extern MockWireClass Wire;

#endif
'@

    Set-Content `
        -Path (Join-Path $pastaTeste "Wire.h") `
        -Value $fakeWire `
        -Encoding UTF8

    # ========================================================
    # Harness
    # ========================================================

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include "Wire.h"

MockWireClass Wire;

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(
    const char *id,
    bool aprovado
) {
    casosExecutados++;

    Serial.print(id);
    Serial.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial.println("PASS");
    }
    else {
        Serial.println("FAIL");
    }
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T13 - identificarChipBmx");
    Serial.println("======================================");

    const uint8_t enderecoTeste = 0x76;

    // ======================================================
    // CT01
    // Falha em endTransmission(false)
    // Esperado: retorna 0
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 4;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    uint8_t r1 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT01",
        r1 == 0
    );

    // ======================================================
    // CT02
    // Transmissão OK, porém available() = false.
    //
    // requestFrom() retorna 1 para representar que a
    // solicitação I2C foi realizada. Entretanto nenhum byte
    // está disponível para leitura.
    //
    // Esperado: retorna 0.
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 0;

    /*
     * Valor sentinela proposital.
     * Caso uma implementação faça read() sem verificar
     * available(), não poderá passar acidentalmente.
     */
    Wire.valorLeitura = 0xA5;

    uint8_t r2 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT02",
        r2 == 0
    );

    // ======================================================
    // CT03
    // CHIP ID BME280 = 0x60
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    uint8_t r3 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT03",
        r3 == 0x60
    );

    // ======================================================
    // CT04
    // CHIP ID BMP280 = 0x58
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x58;

    uint8_t r4 = identificarChipBmx(enderecoTeste);

    registrar(
        "CT04",
        r4 == 0x58
    );

    // ======================================================
    // CT05
    // Contrato I2C:
    // - beginTransmission(endereco informado)
    // - write(0xD0)
    // - endTransmission(false)
    // - requestFrom(endereco, 1)
    // ======================================================

    Wire.reset();

    Wire.retornoEndTransmission = 0;
    Wire.retornoRequestFrom = 1;
    Wire.quantidadeDisponivel = 1;
    Wire.valorLeitura = 0x60;

    identificarChipBmx(enderecoTeste);

    bool contratoOK =
        Wire.chamadasBeginTransmission == 1 &&
        Wire.enderecoBegin == enderecoTeste &&
        Wire.chamadasWrite == 1 &&
        Wire.registradorEscrito == 0xD0 &&
        Wire.chamadasEndTransmission == 1 &&
        Wire.ultimoStop == false &&
        Wire.chamadasRequestFrom == 1 &&
        Wire.enderecoRequest == enderecoTeste &&
        Wire.quantidadeRequest == 1;

    registrar(
        "CT05",
        contratoOK
    );

    Serial.println();

    Serial.print("CASOS_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial.println("PASS");
    }
    else {
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
    Write-Host "T13 - $($modelo.Nome)"
    Write-Host "========================================"

    # ========================================================
    # Compilação
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
            tarefa = "T13"
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

    # ========================================================
    # Upload
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
            tarefa = "T13"
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

    # ========================================================
    # Captura serial
    # ========================================================

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

    # ========================================================
    # Verificação de infraestrutura
    # ========================================================

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa = "T13"
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

    # ========================================================
    # Cada CT congelado é uma unidade
    # ========================================================

    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }
    $ct04 = if ($texto -match "CT04 -> PASS") { 1 } else { 0 }
    $ct05 = if ($texto -match "CT05 -> PASS") { 1 } else { 0 }

    $aprovados = $ct01 + $ct02 + $ct03 + $ct04 + $ct05

    $F = [math]::Round(
        ($aprovados / 5) * 100,
        2
    )

    $resultadoFinal = if ($aprovados -eq 5) {
        "PASS"
    }
    else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T13"
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
    "$baseTestes\resultados_T13.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T13"
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