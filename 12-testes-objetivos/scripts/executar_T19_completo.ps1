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

    $nomeTeste = "T19-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas ($modelo.Pasta + "\T19\codigo.cpp")

    Copy-Item `
        $origem `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    $arquivoSketch = Join-Path $pastaTeste ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>

/*
 * T19 - calcularChecksum
 *
 * O campo checksum permanece obrigatoriamente por ultimo.
 * A estrutura e zerada antes de cada uso para evitar que
 * bytes de padding nao inicializados interfiram nos testes.
 */

struct RegistroMeteorologico {
    uint32_t timestamp;
    float temperatura;
    float umidade;
    float pressao;
    uint16_t chuva;
    uint16_t vento;
    uint32_t checksum;
};

#define TAM_REGISTRO sizeof(RegistroMeteorologico)

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

RegistroMeteorologico criarRegistroBase() {

    RegistroMeteorologico r = {};

    r.timestamp   = 123456789UL;
    r.temperatura = 28.5f;
    r.umidade     = 65.0f;
    r.pressao     = 1012.3f;
    r.chuva       = 17;
    r.vento       = 42;
    r.checksum    = 0;

    return r;
}

/*
 * Implementacao de referencia congelada para CT04.
 *
 * Percorre exatamente todos os bytes anteriores ao campo
 * checksum e aplica:
 *
 * soma = (soma * 31) + byte
 */
uint32_t checksumReferencia(const RegistroMeteorologico &registro) {

    const uint8_t *dados =
        reinterpret_cast<const uint8_t *>(&registro);

    uint32_t soma = 0;

    const size_t tamanhoDados =
        TAM_REGISTRO - sizeof(uint32_t);

    for (size_t i = 0; i < tamanhoDados; i++) {
        soma = (soma * 31U) + dados[i];
    }

    return soma;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T19 - calcularChecksum");
    Serial.println("======================================");

    // ======================================================
    // CT01 - determinismo
    // Mesmo registro duas vezes deve gerar o mesmo checksum.
    // ======================================================

    RegistroMeteorologico r1 = criarRegistroBase();

    uint32_t c1a = calcularChecksum(r1);
    uint32_t c1b = calcularChecksum(r1);

    bool ct01 = (c1a == c1b);

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - sensibilidade aos dados
    // Alterar um byte dos dados deve alterar o checksum.
    // ======================================================

    RegistroMeteorologico r2a = criarRegistroBase();
    RegistroMeteorologico r2b = r2a;

    uint8_t *dadosR2 =
        reinterpret_cast<uint8_t *>(&r2b);

    dadosR2[0] ^= 0x01;

    uint32_t c2a = calcularChecksum(r2a);
    uint32_t c2b = calcularChecksum(r2b);

    bool ct02 = (c2a != c2b);

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - campo checksum excluido
    // Alterar apenas o proprio checksum nao pode mudar
    // o checksum calculado.
    // ======================================================

    RegistroMeteorologico r3a = criarRegistroBase();
    RegistroMeteorologico r3b = r3a;

    r3a.checksum = 0x00000000UL;
    r3b.checksum = 0xDEADBEEFUL;

    uint32_t c3a = calcularChecksum(r3a);
    uint32_t c3b = calcularChecksum(r3b);

    bool ct03 = (c3a == c3b);

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - algoritmo conhecido
    //
    // O resultado da funcao candidata deve ser exatamente
    // igual ao algoritmo congelado:
    //
    // soma = (soma * 31) + byte
    //
    // em todos os bytes de:
    // TAM_REGISTRO - sizeof(uint32_t)
    // ======================================================

    RegistroMeteorologico r4 = criarRegistroBase();

    /*
     * Valor propositalmente diferente de zero para garantir
     * que o campo checksum seja realmente ignorado.
     */
    r4.checksum = 0xA5A5A5A5UL;

    uint32_t esperadoCT04 = checksumReferencia(r4);
    uint32_t obtidoCT04   = calcularChecksum(r4);

    bool ct04 = (obtidoCT04 == esperadoCT04);

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
    Write-Host "T19 - $($modelo.Nome)"
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
            tarefa="T19"
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
            ct04=0
            casos_aprovados=0
            casos_executados=4
            F_0_100=0
            resultado="COMPILE_FAIL"
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
            tarefa="T19"
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
            tarefa="T19"
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
            ct04=""
            casos_aprovados=""
            casos_executados=4
            F_0_100=""
            resultado="INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # RESULTADO FUNCIONAL
    # ========================================================

    $ct01 = if ($texto -match "CT01 -> PASS") { 1 } else { 0 }
    $ct02 = if ($texto -match "CT02 -> PASS") { 1 } else { 0 }
    $ct03 = if ($texto -match "CT03 -> PASS") { 1 } else { 0 }
    $ct04 = if ($texto -match "CT04 -> PASS") { 1 } else { 0 }

    $aprovados = $ct01 + $ct02 + $ct03 + $ct04

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
        tarefa="T19"
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
        ct04=$ct04
        casos_aprovados=$aprovados
        casos_executados=4
        F_0_100=$F
        resultado=$resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T19.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T19"
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