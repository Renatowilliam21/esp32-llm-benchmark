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

    $nomeTeste = "T20-" + $modelo.Id
    $pastaTeste = Join-Path $baseTestes $nomeTeste

    New-Item -ItemType Directory -Force $pastaTeste | Out-Null

    $origem = Join-Path $baseRespostas ($modelo.Pasta + "\T20\codigo.cpp")

    Copy-Item $origem (Join-Path $pastaTeste "candidato.inc") -Force

    $arquivoSketch = Join-Path $pastaTeste ($nomeTeste + ".ino")

    $harness = @'
#include <Arduino.h>
#include <string.h>

/*
 * Contexto padronizado T20.
 *
 * checksum é uint32_t e último campo,
 * coerente com T19 e com o prompt oficial.
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

const uint16_t ENDERECO_DADOS = 100;
const uint16_t TAM_REGISTRO = sizeof(RegistroMeteorologico);

const int EEPROM_MOCK_SIZE = 4096;

uint8_t memoriaEEPROM[EEPROM_MOCK_SIZE];

uint32_t enderecosLidos[256];
int quantidadeLeituras = 0;

/*
 * Mesmo algoritmo oficial de T19.
 */
uint32_t calcularChecksum(const RegistroMeteorologico &registro) {

    const uint8_t *bytes =
        reinterpret_cast<const uint8_t *>(&registro);

    const size_t tamanho =
        sizeof(RegistroMeteorologico) - sizeof(uint32_t);

    uint32_t soma = 0;

    for (size_t i = 0; i < tamanho; ++i) {
        soma = (soma * 31U) + bytes[i];
    }

    return soma;
}

/*
 * Mock de leitura da EEPROM.
 */
uint8_t lerEEPROM(uint16_t endereco) {

    if (quantidadeLeituras < 256) {
        enderecosLidos[quantidadeLeituras] = endereco;
    }

    quantidadeLeituras++;

    if (endereco >= EEPROM_MOCK_SIZE) {
        return 0;
    }

    return memoriaEEPROM[endereco];
}

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

void limparMock() {

    memset(memoriaEEPROM, 0, sizeof(memoriaEEPROM));

    quantidadeLeituras = 0;

    for (int i = 0; i < 256; i++) {
        enderecosLidos[i] = 0;
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

    r.checksum = calcularChecksum(r);

    return r;
}

void gravarMock(
    uint16_t indice,
    const RegistroMeteorologico &registro
) {

    uint32_t inicio =
        ENDERECO_DADOS +
        static_cast<uint32_t>(indice) * TAM_REGISTRO;

    const uint8_t *dados =
        reinterpret_cast<const uint8_t *>(&registro);

    for (size_t i = 0;
         i < sizeof(RegistroMeteorologico);
         i++) {

        memoriaEEPROM[inicio + i] = dados[i];
    }
}

bool registrosIguais(
    const RegistroMeteorologico &a,
    const RegistroMeteorologico &b
) {
    return memcmp(
        &a,
        &b,
        sizeof(RegistroMeteorologico)
    ) == 0;
}

void setup() {

    Serial.begin(115200);
    delay(4000);

    Serial.println();
    Serial.println("======================================");
    Serial.println("ESP32-LLM BENCHMARK");
    Serial.println("T20 - lerRegistro");
    Serial.println("======================================");

    // ======================================================
    // CT01 - Registro íntegro
    // ======================================================

    limparMock();

    RegistroMeteorologico original1 =
        criarRegistroBase();

    gravarMock(0, original1);

    RegistroMeteorologico lido1 = {};

    bool retorno1 =
        lerRegistro(0, lido1);

    bool ct01 =
        retorno1 &&
        registrosIguais(original1, lido1);

    registrar("CT01", ct01);

    // ======================================================
    // CT02 - Registro corrompido
    //
    // Após gravar um registro válido,
    // altera-se um byte dos dados antes do checksum.
    // ======================================================

    limparMock();

    RegistroMeteorologico original2 =
        criarRegistroBase();

    gravarMock(0, original2);

    /*
     * Corrompe primeiro byte do timestamp.
     */
    memoriaEEPROM[ENDERECO_DADOS] ^= 0x01;

    RegistroMeteorologico lido2 = {};

    bool retorno2 =
        lerRegistro(0, lido2);

    bool ct02 =
        (retorno2 == false);

    registrar("CT02", ct02);

    // ======================================================
    // CT03 - Endereço índice 0
    // ======================================================

    limparMock();

    RegistroMeteorologico original3 =
        criarRegistroBase();

    gravarMock(0, original3);

    RegistroMeteorologico lido3 = {};

    lerRegistro(0, lido3);

    bool ct03 =
        quantidadeLeituras > 0 &&
        enderecosLidos[0] == ENDERECO_DADOS;

    registrar("CT03", ct03);

    // ======================================================
    // CT04 - Endereço índice N
    //
    // N = 3
    // ======================================================

    limparMock();

    const uint16_t indiceN = 3;

    RegistroMeteorologico original4 =
        criarRegistroBase();

    gravarMock(indiceN, original4);

    RegistroMeteorologico lido4 = {};

    lerRegistro(indiceN, lido4);

    uint32_t enderecoEsperado =
        ENDERECO_DADOS +
        static_cast<uint32_t>(indiceN) * TAM_REGISTRO;

    bool ct04 =
        quantidadeLeituras > 0 &&
        enderecosLidos[0] == enderecoEsperado;

    registrar("CT04", ct04);

    // ======================================================
    // CT05 - Cobertura
    //
    // Deve ler exatamente TAM_REGISTRO bytes.
    // ======================================================

    limparMock();

    RegistroMeteorologico original5 =
        criarRegistroBase();

    gravarMock(0, original5);

    RegistroMeteorologico lido5 = {};

    lerRegistro(0, lido5);

    bool ct05 =
        quantidadeLeituras == TAM_REGISTRO;

    registrar("CT05", ct05);

    Serial.println();

    Serial.print("TAM_REGISTRO=");
    Serial.println(TAM_REGISTRO);

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
    Write-Host "T20 - $($modelo.Nome)"
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
            tarefa="T20"
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
            ct05=0
            casos_aprovados=0
            casos_executados=5
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
            tarefa="T20"
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
            ct05=""
            casos_aprovados=""
            casos_executados=5
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
            tarefa="T20"
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
            ct05=""
            casos_aprovados=""
            casos_executados=5
            F_0_100=""
            resultado="INFRA_SERIAL"
        }

        continue
    }

    # ========================================================
    # RESULTADOS
    # ========================================================

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
        tarefa="T20"
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
        ct05=$ct05
        casos_aprovados=$aprovados
        casos_executados=5
        F_0_100=$F
        resultado=$resultadoFinal
    }
}

$resultados |
    Export-Csv `
    "$baseTestes\resultados_T20.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS T20"
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