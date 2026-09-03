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

    $nomeTeste = "T14-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    # ========================================================
    # CÃ³digo oficial preservado
    # ========================================================

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T14\codigo.cpp")

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
#include <math.h>

/*
 * Faixa fornecida pelo contexto da aplicaÃ§Ã£o.
 * Para o benchmark interessa principalmente o comportamento
 * dentro e fora dos limites.
 */
const float PRESSAO_MIN_VALIDA = 300.0f;
const float PRESSAO_MAX_VALIDA = 1100.0f;

/*
 * Mock comum para BME/BMP.
 *
 * Possui as duas formas de readAltitude() para permitir
 * compilar respostas que utilizem ambas as assinaturas.
 */
class MockSensorPressao {
public:

    float pressaoPa = 100000.0f;
    float altitudeConfigurada = 0.0f;

    int chamadasPressao = 0;
    int chamadasAltitudeSemParametro = 0;
    int chamadasAltitudeComParametro = 0;

    float ultimoParametroAltitude = NAN;

    void reset() {
        pressaoPa = 100000.0f;
        altitudeConfigurada = 0.0f;

        chamadasPressao = 0;
        chamadasAltitudeSemParametro = 0;
        chamadasAltitudeComParametro = 0;

        ultimoParametroAltitude = NAN;
    }

    float readPressure() {
        chamadasPressao++;
        return pressaoPa;
    }

    float readAltitude() {
        chamadasAltitudeSemParametro++;
        return altitudeConfigurada;
    }

    float readAltitude(float parametro) {
        chamadasAltitudeComParametro++;
        ultimoParametroAltitude = parametro;
        return altitudeConfigurada;
    }
};

MockSensorPressao bme;
MockSensorPressao bmp;

bool bmeDisponivel = false;
bool bmeSaudavel = false;

bool bmpDisponivel = false;
bool bmpSaudavel = false;

#include "candidato.inc"

int casosExecutados = 0;
int casosAprovados = 0;

bool quaseIgual(float a, float b, float tolerancia = 0.01f) {
    if (isnan(a) || isnan(b)) {
        return false;
    }

    return fabsf(a - b) <= tolerancia;
}

void registrar(const char *id, bool aprovado) {

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

void resetarTudo() {

    bme.reset();
    bmp.reset();

    bmeDisponivel = false;
    bmeSaudavel = false;

    bmpDisponivel = false;
    bmpSaudavel = false;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T14 - lerPressaoAltitude");
    Serial.println("======================================");

    float pressao = NAN;
    float altitude = NAN;

    // ======================================================
    // CT01 - Prioridade BME
    //
    // BME disponÃ­vel/saudÃ¡vel e BMP disponÃ­vel.
    // Esperado:
    // - usar BME
    // - pressÃ£o BME convertida Pa -> hPa
    // - altitude fornecida pelo BME
    // ======================================================

    resetarTudo();

    bmeDisponivel = true;
    bmeSaudavel = true;

    bmpDisponivel = true;
    bmpSaudavel = true;

    bme.pressaoPa = 100000.0f;       // 1000 hPa
    bme.altitudeConfigurada = 123.45f;

    bmp.pressaoPa = 95000.0f;
    bmp.altitudeConfigurada = 987.65f;

    pressao = NAN;
    altitude = NAN;

    lerPressaoAltitude(pressao, altitude);

    bool ct01 =
        quaseIgual(pressao, 1000.0f) &&
        quaseIgual(altitude, 123.45f) &&
        bme.chamadasPressao == 1 &&
        bmp.chamadasPressao == 0;

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Fallback BMP
    //
    // BME indisponÃ­vel; BMP disponÃ­vel.
    // Esperado:
    // pressÃ£o e altitude do BMP.
    // ======================================================

    resetarTudo();

    bmeDisponivel = false;
    bmeSaudavel = false;

    bmpDisponivel = true;
    bmpSaudavel = true;

    bmp.pressaoPa = 98000.0f;        // 980 hPa
    bmp.altitudeConfigurada = 222.22f;

    pressao = NAN;
    altitude = NAN;

    lerPressaoAltitude(pressao, altitude);

    bool ct02 =
        quaseIgual(pressao, 980.0f) &&
        quaseIgual(altitude, 222.22f) &&
        bmp.chamadasPressao == 1 &&
        bme.chamadasPressao == 0;

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - Sem sensor
    //
    // BME e BMP indisponÃ­veis.
    // Esperado:
    // pressÃ£o = NaN
    // altitude = NaN
    // ======================================================

    resetarTudo();

    pressao = 123.0f;
    altitude = 456.0f;

    lerPressaoAltitude(pressao, altitude);

    bool ct03 =
        isnan(pressao) &&
        isnan(altitude);

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - PressÃ£o invÃ¡lida
    //
    // Sensor disponÃ­vel, mas pressÃ£o abaixo do mÃ­nimo.
    // Esperado:
    // pressÃ£o = NaN
    // altitude = NaN
    // ======================================================

    resetarTudo();

    bmeDisponivel = true;
    bmeSaudavel = true;

    bme.pressaoPa =
        (PRESSAO_MIN_VALIDA - 1.0f) * 100.0f;

    bme.altitudeConfigurada = 999.0f;

    pressao = 123.0f;
    altitude = 456.0f;

    lerPressaoAltitude(pressao, altitude);

    bool ct04 =
        isnan(pressao) &&
        isnan(altitude);

    registrar("CT04", ct04);

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
    Write-Host "T14 - $($modelo.Nome)"
    Write-Host "========================================"

    # ========================================================
    # CompilaÃ§Ã£o
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
    # Falha de compilaÃ§Ã£o
    # ========================================================

    if ($exitCompilacao -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T14"
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
            tarefa = "T14"
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
    # Falha de infraestrutura serial
    # ========================================================

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa = "T14"
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
    # Resultado funcional
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
    }
    else {
        "FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T14"
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
    "$baseTestes\resultados_T14.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T14"
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
