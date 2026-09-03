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

    $nomeTeste = "T11-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # ========================================================
    # Preservação do código original
    # ========================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T11\codigo.cpp")

    $candidato = Join-Path $pastaTeste "candidato.inc"

    Copy-Item $origem $candidato -Force

    $codigoOriginal = Get-Content $candidato -Raw

    # ========================================================
    # CT04 - inspeção estática da ISR
    # ========================================================
    #
    # As variáveis compartilhadas pertencem ao contexto
    # da aplicação e serão declaradas volatile no harness.
    #
    # Aqui verificamos se o código GERADO introduziu
    # operações claramente inadequadas/bloqueantes na ISR.
    # ========================================================

    $operacaoBloqueante = $false
    $motivosEstaticos = @()

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
            $motivosEstaticos += $padrao
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
 * Contexto original da aplicação:
 * variáveis compartilhadas com ISR são volatile.
 */
volatile unsigned long pulsosPluviometro = 0;
volatile unsigned long ultimoPulsoPluviometro = 0;

/*
 * Controle determinístico do tempo.
 */
unsigned long benchmarkMillisAtual = 0;

unsigned long benchmarkMillis() {
    return benchmarkMillisAtual;
}

/*
 * Durante a inclusão do candidato, millis()
 * é substituído pelo relógio controlado do benchmark.
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
    Serial.println("T11 - isrPluviometro");
    Serial.println("======================================");

    /*
     * CT01
     * ultimoPulso=0
     * millis=100
     *
     * Esperado:
     * contador +1
     * ultimoPulso=100
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 0;
    benchmarkMillisAtual = 100;

    isrPluviometro();

    registrar(
        "CT01",
        pulsosPluviometro == 1 &&
        ultimoPulsoPluviometro == 100
    );

    /*
     * CT02
     * ultimoPulso=100
     * millis=115
     *
     * diferença = 15
     * condição deve ser > 15
     *
     * Esperado: rejeitar.
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 100;
    benchmarkMillisAtual = 115;

    isrPluviometro();

    registrar(
        "CT02",
        pulsosPluviometro == 0 &&
        ultimoPulsoPluviometro == 100
    );

    /*
     * CT03
     * ultimoPulso=100
     * millis=116
     *
     * diferença = 16
     *
     * Esperado: aceitar.
     */

    pulsosPluviometro = 0;
    ultimoPulsoPluviometro = 100;
    benchmarkMillisAtual = 116;

    isrPluviometro();

    registrar(
        "CT03",
        pulsosPluviometro == 1 &&
        ultimoPulsoPluviometro == 116
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
    Write-Host "T11 - $($modelo.Nome)"
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
            tarefa = "T11"
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
            tarefa = "T11"
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
    # Captura Serial
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
    # Interpretação dos três CTs executáveis
    # ========================================================

    $execucaoOK = 0

    if ($texto -match "FIM_RUNTIME=1") {
        $execucaoOK = 1
    }

    if ($execucaoOK -eq 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T11"
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
    # F considera EXATAMENTE os quatro CTs congelados
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
        tarefa = "T11"
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

# ============================================================
# Exportação
# ============================================================

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T11.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T11"
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