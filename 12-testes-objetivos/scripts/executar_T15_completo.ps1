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

    $nomeTeste = "T15-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # ========================================================
    # Código oficial preservado
    # ========================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T15\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    # ========================================================
    # Harness
    # ========================================================

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>

/*
 * Contexto padronizado do benchmark.
 */
const int PIN_LDR = 34;

bool vemlDisponivel = false;

/*
 * Mock do VEML7700.
 */
class MockVEML7700 {
public:
    float luxConfigurado = 0.0f;
    int chamadasReadLux = 0;

    void reset() {
        luxConfigurado = 0.0f;
        chamadasReadLux = 0;
    }

    float readLux() {
        chamadasReadLux++;
        return luxConfigurado;
    }
};

MockVEML7700 veml;

/*
 * Mock determinístico do ADC.
 */
int benchmarkADC = 0;
int chamadasAnalogRead = 0;
int ultimoPinoAnalogico = -1;

int benchmarkAnalogRead(int pino) {
    chamadasAnalogRead++;
    ultimoPinoAnalogico = pino;
    return benchmarkADC;
}

#define analogRead(pino) benchmarkAnalogRead(pino)

#include "candidato.inc"

#undef analogRead

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
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

void resetarTudo() {

    veml.reset();

    vemlDisponivel = false;

    benchmarkADC = 0;
    chamadasAnalogRead = 0;
    ultimoPinoAnalogico = -1;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T15 - lerLDR");
    Serial.println("======================================");

    // ======================================================
    // CT01 - Digital prioritário
    //
    // VEML disponível
    // readLux = 450.5
    //
    // Esperado:
    // retorna 450.5
    // não usa ADC
    // ======================================================

    resetarTudo();

    vemlDisponivel = true;
    veml.luxConfigurado = 450.5f;

    benchmarkADC = 1234;

    float r1 = lerLDR();

    bool ct01 =
        quaseIgual(r1, 450.5f) &&
        veml.chamadasReadLux == 1 &&
        chamadasAnalogRead == 0;

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Fallback ADC mínimo
    //
    // VEML indisponível
    // ADC = 0
    //
    // map(0,4095,100,0) = 100
    // ======================================================

    resetarTudo();

    vemlDisponivel = false;
    benchmarkADC = 0;

    float r2 = lerLDR();

    bool ct02 =
        quaseIgual(r2, 100.0f) &&
        chamadasAnalogRead == 1 &&
        ultimoPinoAnalogico == PIN_LDR;

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - Fallback ADC máximo
    //
    // VEML indisponível
    // ADC = 4095
    //
    // Esperado: 0
    // ======================================================

    resetarTudo();

    vemlDisponivel = false;
    benchmarkADC = 4095;

    float r3 = lerLDR();

    bool ct03 =
        quaseIgual(r3, 0.0f) &&
        chamadasAnalogRead == 1 &&
        ultimoPinoAnalogico == PIN_LDR;

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - Prioridade
    //
    // VEML disponível e ADC também configurado.
    // Resultado deve vir do VEML7700.
    // ======================================================

    resetarTudo();

    vemlDisponivel = true;
    veml.luxConfigurado = 321.75f;

    benchmarkADC = 4095;

    float r4 = lerLDR();

    bool ct04 =
        quaseIgual(r4, 321.75f) &&
        veml.chamadasReadLux == 1 &&
        chamadasAnalogRead == 0;

    registrar("CT04", ct04);

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
    Write-Host "T15 - $($modelo.Nome)"
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
            tarefa = "T15"
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
            casos_aprovados = 0
            casos_executados = 4
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
            tarefa = "T15"
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
            casos_aprovados = ""
            casos_executados = 4
            F_0_100 = ""
            resultado = "UPLOAD_FAIL"
        }

        continue
    }

    # ========================================================
    # Serial
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

    # ========================================================
    # Falha de infraestrutura
    # ========================================================

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa = "T15"
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
            casos_aprovados = ""
            casos_executados = 4
            F_0_100 = ""
            resultado = "INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # Avaliação funcional
    # ========================================================

    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }
    $ct04 = if ($texto -match "CT04 -> PASS") { 1 } else { 0 }

    $aprovados =
        $ct01 +
        $ct02 +
        $ct03 +
        $ct04

    $F = [math]::Round(
        ($aprovados / 4) * 100,
        2
    )

    $resultadoFinal = if ($aprovados -eq 4) {
        "PASS"
    } else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T15"
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
        casos_aprovados = $aprovados
        casos_executados = 4
        F_0_100 = $F
        resultado = $resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T15.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T15"
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
        casos_aprovados,
        casos_executados,
        F_0_100,
        resultado `
        -AutoSize