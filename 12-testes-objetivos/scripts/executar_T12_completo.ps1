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

    $nomeTeste = "T12-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # ========================================================
    # Preservação do código original
    # ========================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T12\codigo.cpp")

    $candidato = Join-Path $pastaTeste "candidato.inc"

    Copy-Item $origem $candidato -Force

    $codigoOriginal = Get-Content $candidato -Raw

    # ========================================================
    # CT04 - inspeção estática
    # ========================================================

    $operacaoBloqueante = $false

    $padroesProibidos = @(
        '\bdelay\s*\(',
        '\bdelayMicroseconds\s*\(',
        '\bSerial\.',
        '\bWire\.',
        '\bHTTPClient\b',
        '\bWiFiClient\b',
        '\bWiFi\.',
        '\byield\s*\('
    )

    foreach ($padrao in $padroesProibidos) {
        if ($codigoOriginal -match $padrao) {
            $operacaoBloqueante = $true
        }
    }

    if ($operacaoBloqueante) {
        $ct04 = 0
        $resultadoCT04 = "FAIL"
    }
    else {
        $ct04 = 1
        $resultadoCT04 = "PASS"
    }

    # ========================================================
    # Harness
    # ========================================================

    $arquivoSketch = Join-Path `
        $pastaTeste `
        ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>

/*
 * Contexto fornecido pelo sistema original.
 * Variáveis compartilhadas com ISR são volatile.
 */
volatile unsigned long pulsosAnemometro = 0;
volatile unsigned long ultimoPulsoAnemometro = 0;

/*
 * Relógio determinístico do benchmark.
 */
unsigned long benchmarkMillisAtual = 0;

unsigned long benchmarkMillis() {
    return benchmarkMillisAtual;
}

/*
 * Substitui millis() apenas durante a inclusão
 * do código candidato.
 */
#define millis() benchmarkMillis()

#include "candidato.inc"

#undef millis

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
    Serial.println("T12 - isrAnemometro");
    Serial.println("======================================");

    /*
     * CT01
     * ultimoPulso=0
     * millis=100
     *
     * Esperado:
     * contador incrementa
     * ultimoPulso=100
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 0;
    benchmarkMillisAtual = 100;

    isrAnemometro();

    registrar(
        "CT01",
        pulsosAnemometro == 1 &&
        ultimoPulsoAnemometro == 100
    );

    /*
     * CT02
     * ultimoPulso=100
     * millis=105
     *
     * diferença = 5
     * condição é > 5
     *
     * Esperado: rejeitar
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 100;
    benchmarkMillisAtual = 105;

    isrAnemometro();

    registrar(
        "CT02",
        pulsosAnemometro == 0 &&
        ultimoPulsoAnemometro == 100
    );

    /*
     * CT03
     * ultimoPulso=100
     * millis=106
     *
     * diferença = 6
     *
     * Esperado: aceitar
     */

    pulsosAnemometro = 0;
    ultimoPulsoAnemometro = 100;
    benchmarkMillisAtual = 106;

    isrAnemometro();

    registrar(
        "CT03",
        pulsosAnemometro == 1 &&
        ultimoPulsoAnemometro == 106
    );

    Serial.println();

    Serial.print("CASOS_RUNTIME_APROVADOS=");
    Serial.println(casosAprovados);

    Serial.print("CASOS_RUNTIME_EXECUTADOS=");
    Serial.println(casosExecutados);

    Serial.println("FIM_RUNTIME=1");
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
    Write-Host "T12 - $($modelo.Nome)"
    Write-Host "========================================"

    Write-Host "CT04_estatico = $resultadoCT04"

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

    # ========================================================
    # Falha de compilação
    # ========================================================

    if ($exitCompilacao -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T12"
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
            ct04 = $ct04
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
            tarefa = "T12"
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
            ct04 = $ct04
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

                    if ($linha -match "FIM_RUNTIME=1") {
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
    # Interpretação
    # ========================================================

    $execucaoOK = 0

    if ($texto -match "FIM_RUNTIME=1") {
        $execucaoOK = 1
    }

    if ($execucaoOK -eq 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T12"
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
            ct04 = $ct04
            casos_aprovados = ""
            casos_executados = 4
            F_0_100 = ""
            resultado = "INFRA_SERIAL"
        }

        continue
    }

    $ct01 = 0
    $ct02 = 0
    $ct03 = 0

    if ($texto -match "CT01 -> PASS") {
        $ct01 = 1
    }

    if ($texto -match "CT02 -> PASS") {
        $ct02 = 1
    }

    if ($texto -match "CT03 -> PASS") {
        $ct03 = 1
    }

    # ========================================================
    # F = 4 CTs congelados
    # ========================================================

    $aprovados = $ct01 + $ct02 + $ct03 + $ct04
    $executados = 4

    $F = [math]::Round(
        ($aprovados / $executados) * 100,
        2
    )

    if ($aprovados -eq 4) {
        $resultadoFinal = "PASS"
    }
    else {
        $resultadoFinal = "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T12"
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
    "$baseTestes\resultados_T12.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T12"
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