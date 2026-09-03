$root = (Get-Location).Path
$baseRespostas = Join-Path $root "05-respostas-llms"
$baseTestes = Join-Path $root "12-testes-objetivos"

$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{ Id="LLM01"; Nome="GPT-5.6-Sol";     Pasta="LLM01_GPT-5.6-Sol" },
    @{ Id="LLM02"; Nome="DeepSeek-V4-Pro"; Pasta="LLM02_DeepSeek-V4-Pro" },
    @{ Id="LLM03"; Nome="Claude-Sonnet-5"; Pasta="LLM03_Claude-Sonnet-5" }
)

$resultados = @()

foreach ($modelo in $modelos) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T21 - $($modelo.Nome)"
    Write-Host "========================================"

    $origem = Join-Path `
        $baseRespostas `
        ($modelo.Pasta + "\T21\codigo.cpp")

    # ========================================================
    # FASE 1 - COMPILACAO REAL
    # ========================================================

    $pastaReal = Join-Path `
        $baseTestes `
        ("T21-" + $modelo.Id + "-real")

    New-Item -ItemType Directory -Force $pastaReal | Out-Null

    Copy-Item `
        $origem `
        (Join-Path $pastaReal "candidato.inc") `
        -Force

    $sketchReal = Join-Path `
        $pastaReal `
        ("T21-" + $modelo.Id + "-real.ino")

    $codigoReal = @'
#include <Arduino.h>
#include <Wire.h>
#include <esp_task_wdt.h>

const uint8_t PINO_PLUVIOMETRO = 25;
const uint8_t PINO_ANEMOMETRO  = 26;

void isrPluviometro() {}
void isrAnemometro() {}

void inicializarSensores() {}

bool detectarEeprom() {
    return true;
}

void carregarControleEEPROM() {}
void carregarConfiguracao() {}
void configurarWiFi() {}
void configurarServidorAdmin() {}

#include "candidato.inc"

void loop() {
}
'@

    Set-Content `
        -Path $sketchReal `
        -Value $codigoReal `
        -Encoding UTF8

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaReal 2>&1

    $exitCompilacao = $LASTEXITCODE

    $saidaCompilacao |
        Tee-Object `
        -FilePath (Join-Path $pastaReal "compilacao.log")

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
            tarefa="T21"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=0
            C_0_100=0
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=0
            execucao_ok=0
            ct01=0
            ct02=0
            ct03=0
            ct04=0
            casos_aprovados=0
            casos_executados=4
            F_0_100=0
            resultado="COMPILE_FAIL"
        }

        continue
    }

    # ========================================================
    # FASE 2 - HARNESS FUNCIONAL CONTROLADO
    # ========================================================

    $pastaFunc = Join-Path `
        $baseTestes `
        ("T21-" + $modelo.Id + "-funcional")

    New-Item -ItemType Directory -Force $pastaFunc | Out-Null

    Copy-Item `
        $origem `
        (Join-Path $pastaFunc "candidato.inc") `
        -Force

    # ========================================================
    # Wire.h
    # ========================================================

    $wireHeader = @'
#ifndef BENCHMARK_WIRE_H
#define BENCHMARK_WIRE_H

class BenchmarkWireClass {
public:
    int chamadasBegin = 0;

    void begin() {
        chamadasBegin++;
    }
};

extern BenchmarkWireClass Wire;

#endif
'@

    Set-Content `
        -Path (Join-Path $pastaFunc "Wire.h") `
        -Value $wireHeader `
        -Encoding UTF8

    # ========================================================

    # ========================================================
    # esp_task_wdt.h
    # ========================================================

    $wdtHeader = @'
#ifndef BENCHMARK_ESP_TASK_WDT_H
#define BENCHMARK_ESP_TASK_WDT_H

#include <stdint.h>

typedef int esp_err_t;

#define ESP_OK 0
#define ESP_ERR_INVALID_STATE 0x103

#ifndef portNUM_PROCESSORS
#define portNUM_PROCESSORS 2
#endif

typedef struct {
    uint32_t timeout_ms;
    uint32_t idle_core_mask;
    bool trigger_panic;
} esp_task_wdt_config_t;

extern int benchmarkWdtInit;
extern int benchmarkWdtReconfigure;
extern int benchmarkWdtAdd;

inline esp_err_t esp_task_wdt_init(
    const esp_task_wdt_config_t *config
) {
    benchmarkWdtInit++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_reconfigure(
    const esp_task_wdt_config_t *config
) {
    benchmarkWdtReconfigure++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_init(
    uint32_t timeout,
    bool panic
) {
    benchmarkWdtInit++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_add(void *task) {
    benchmarkWdtAdd++;
    return ESP_OK;
}

#endif
'@

    Set-Content `
        -Path (Join-Path $pastaFunc "esp_task_wdt.h") `
        -Value $wdtHeader `
        -Encoding UTF8

    # ========================================================
    # HARNESS
    # ========================================================

    $sketchFunc = Join-Path `
        $pastaFunc `
        ("T21-" + $modelo.Id + "-funcional.ino")

    $harness = @'
#include <Arduino.h>

/*
 * ==========================================================
 * ESTADO DOS MOCKS
 * ==========================================================
 */

int benchmarkSerialBegin = 0;
unsigned long benchmarkSerialBaud = 0;

int benchmarkPinModeChamadas = 0;
bool benchmarkPluvInputPullup = false;
bool benchmarkAnemoInputPullup = false;

int benchmarkAttachChamadas = 0;
bool benchmarkPluvISRCorreta = false;
bool benchmarkAnemoISRCorreta = false;

int benchmarkWdtInit = 0;
int benchmarkWdtReconfigure = 0;
int benchmarkWdtAdd = 0;

int benchmarkInicializarSensores = 0;
int benchmarkDetectarEeprom = 0;
int benchmarkCarregarControle = 0;
int benchmarkCarregarConfiguracao = 0;
int benchmarkConfigurarWiFi = 0;
int benchmarkConfigurarServidor = 0;

int benchmarkSequencia = 0;
int ordemDetectar = 0;
int ordemCarregarControle = 0;

bool benchmarkEepromDisponivel = true;

/*
 * ==========================================================
 * PINOS OFICIAIS
 * ==========================================================
 */

const uint8_t PINO_PLUVIOMETRO = 25;
const uint8_t PINO_ANEMOMETRO  = 26;

/*
 * ==========================================================
 * SERIAL MOCK
 * ==========================================================
 */

class BenchmarkSerialClass {
public:
    void begin(unsigned long baud) {
        benchmarkSerialBegin++;
        benchmarkSerialBaud = baud;
    }
};

BenchmarkSerialClass benchmarkSerial;

/*
 * ==========================================================
 * GPIO MOCK
 * ==========================================================
 */

void benchmarkPinMode(
    uint8_t pin,
    uint8_t mode
) {

    benchmarkPinModeChamadas++;

    if (
        pin == PINO_PLUVIOMETRO &&
        mode == INPUT_PULLUP
    ) {
        benchmarkPluvInputPullup = true;
    }

    if (
        pin == PINO_ANEMOMETRO &&
        mode == INPUT_PULLUP
    ) {
        benchmarkAnemoInputPullup = true;
    }
}

/*
 * ==========================================================
 * ISRs OFICIAIS
 * ==========================================================
 */

void isrPluviometro() {}
void isrAnemometro() {}

/*
 * ==========================================================
 * INTERRUPCOES MOCK
 * ==========================================================
 */

int benchmarkDigitalPinToInterrupt(uint8_t pin) {
    return pin;
}

void benchmarkAttachInterrupt(
    int pin,
    void (*func)(),
    int mode
) {

    benchmarkAttachChamadas++;

    if (
        pin == PINO_PLUVIOMETRO &&
        func == isrPluviometro &&
        mode == FALLING
    ) {
        benchmarkPluvISRCorreta = true;
    }

    if (
        pin == PINO_ANEMOMETRO &&
        func == isrAnemometro &&
        mode == FALLING
    ) {
        benchmarkAnemoISRCorreta = true;
    }
}

/*
 * ==========================================================
 * Wire
 * ==========================================================
 */

#include "Wire.h"

BenchmarkWireClass Wire;

/*
 * ==========================================================
 * AUXILIARES
 * ==========================================================
 */

void inicializarSensores() {
    benchmarkInicializarSensores++;
}

bool detectarEeprom() {

    benchmarkDetectarEeprom++;

    benchmarkSequencia++;
    ordemDetectar = benchmarkSequencia;

    return benchmarkEepromDisponivel;
}

void carregarControleEEPROM() {

    benchmarkCarregarControle++;

    benchmarkSequencia++;
    ordemCarregarControle = benchmarkSequencia;
}

void carregarConfiguracao() {
    benchmarkCarregarConfiguracao++;
}

void configurarWiFi() {
    benchmarkConfigurarWiFi++;
}

void configurarServidorAdmin() {
    benchmarkConfigurarServidor++;
}

/*
 * ==========================================================
 * INTERCEPTACOES
 * ==========================================================
 */

#define Serial benchmarkSerial

#define pinMode(pin, mode) \
    benchmarkPinMode(pin, mode)

#define digitalPinToInterrupt(pin) \
    benchmarkDigitalPinToInterrupt(pin)

#define attachInterrupt(pin, func, mode) \
    benchmarkAttachInterrupt(pin, func, mode)

/*
 * Renomeia somente durante a inclusÃ£o.
 *
 * candidato.inc permanece fisicamente inalterado.
 */
#define setup setupCandidato

#include "candidato.inc"

#undef setup
#undef Serial
#undef pinMode
#undef digitalPinToInterrupt
#undef attachInterrupt

/*
 * ==========================================================
 * RESULTADOS
 * ==========================================================
 */

int casosExecutados = 0;
int casosAprovados = 0;

void registrar(
    const char *id,
    bool aprovado
) {

    casosExecutados++;

    Serial0.print(id);
    Serial0.print(" -> ");

    if (aprovado) {
        casosAprovados++;
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void setup() {

    Serial0.begin(115200);
    delay(4000);

    Serial0.println();
    Serial0.println("======================================");
    Serial0.println("ESP32-LLM BENCHMARK");
    Serial0.println("T21 - setup");
    Serial0.println("======================================");

    /*
     * CenÃ¡rio congelado:
     * EEPROM disponÃ­vel.
     */
    benchmarkEepromDisponivel = true;

    /*
     * Executa explicitamente o setup gerado pela LLM.
     */
    setupCandidato();

    // ======================================================
    // CT01
    // Boot normal / integraÃ§Ã£o
    // ======================================================

    bool ct01 =
        benchmarkSerialBegin >= 1 &&
        benchmarkSerialBaud == 115200 &&
        benchmarkPluvInputPullup &&
        benchmarkAnemoInputPullup &&
        benchmarkPluvISRCorreta &&
        benchmarkAnemoISRCorreta &&
        benchmarkWdtInit >= 1 &&
        benchmarkWdtAdd >= 1 &&
        Wire.chamadasBegin >= 1 &&
        benchmarkInicializarSensores >= 1 &&
        benchmarkCarregarConfiguracao >= 1 &&
        benchmarkConfigurarWiFi >= 1 &&
        benchmarkConfigurarServidor >= 1;

    registrar("CT01", ct01);

    // ======================================================
    // CT02
    // EEPROM disponÃ­vel
    // ======================================================

    bool ct02 =
        benchmarkDetectarEeprom >= 1 &&
        benchmarkCarregarControle >= 1 &&
        ordemDetectar > 0 &&
        ordemCarregarControle > ordemDetectar;

    registrar("CT02", ct02);

    // ======================================================
    // CT03
    // GPIO + interrupÃ§Ãµes
    // ======================================================

    bool ct03 =
        benchmarkPluvInputPullup &&
        benchmarkAnemoInputPullup &&
        benchmarkPluvISRCorreta &&
        benchmarkAnemoISRCorreta;

    registrar("CT03", ct03);

    // ======================================================
    // CT04
    // Watchdog
    // ======================================================

    bool ct04 =
        benchmarkWdtInit >= 1 &&
        benchmarkWdtAdd >= 1;

    registrar("CT04", ct04);

    Serial0.println();

    Serial0.print("CASOS_APROVADOS=");
    Serial0.println(casosAprovados);

    Serial0.print("CASOS_EXECUTADOS=");
    Serial0.println(casosExecutados);

    Serial0.print("RESULTADO=");

    if (casosAprovados == casosExecutados) {
        Serial0.println("PASS");
    }
    else {
        Serial0.println("FAIL");
    }
}

void loop() {
}
'@

    Set-Content `
        -Path $sketchFunc `
        -Value $harness `
        -Encoding UTF8

    # ========================================================
    # COMPILACAO FUNCIONAL
    # ========================================================

    $saidaFunc = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaFunc 2>&1

    $exitFunc = $LASTEXITCODE

    $saidaFunc |
        Tee-Object `
        -FilePath (Join-Path $pastaFunc "compilacao_funcional.log")

    if ($exitFunc -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T21"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=0
            execucao_ok=0
            ct01=0
            ct02=0
            ct03=0
            ct04=0
            casos_aprovados=0
            casos_executados=4
            F_0_100=0
            resultado="HARNESS_COMPILE_FAIL"
        }

        continue
    }

    # ========================================================
    # UPLOAD
    # ========================================================

    $saidaUpload = & arduino-cli upload `
        -p COM5 `
        --fqbn $fqbn `
        $pastaFunc 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object `
        -FilePath (Join-Path $pastaFunc "upload.log")

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa="T21"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=1
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            ct04=""
            casos_aprovados=""
            casos_executados=4
            F_0_100=""
            resultado="UPLOAD_FAIL"
        }

        continue
    }

    # ========================================================
    # SERIAL
    # ========================================================

    Start-Sleep -Milliseconds 1000

    $serial = New-Object System.IO.Ports.SerialPort

    $serial.PortName = "COM5"
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
        -Path (Join-Path $pastaFunc "execucao_serial.log") `
        -Encoding UTF8

    if ($texto -notmatch "RESULTADO=(PASS|FAIL)") {

        $resultados += [PSCustomObject]@{
            tarefa="T21"
            modelo_id=$modelo.Id
            modelo=$modelo.Nome
            compilou=1
            C_0_100=100
            flash_bytes=$flashBytes
            ram_bytes=$ramBytes
            funcional_compilou=1
            execucao_ok=0
            ct01=""
            ct02=""
            ct03=""
            ct04=""
            casos_aprovados=""
            casos_executados=4
            F_0_100=""
            resultado="INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # RESULTADOS FUNCIONAIS
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
        tarefa="T21"
        modelo_id=$modelo.Id
        modelo=$modelo.Nome
        compilou=1
        C_0_100=100
        flash_bytes=$flashBytes
        ram_bytes=$ramBytes
        funcional_compilou=1
        execucao_ok=1
        ct01=$ct01
        ct02=$ct02
        ct03=$ct03
        ct04=$ct04
        casos_aprovados=$aprovados
        casos_executados=4
        F_0_100=$F
        resultado=$resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T21.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T21"
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
        funcional_compilou,
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


