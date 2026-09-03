$ErrorActionPreference = "Continue"

# ============================================================
# ESP32-LLM Benchmark - T24
# lerAmbiente(float &temperatura, float &umidade)
#
# Ambiente congelado:
# Arduino CLI 1.5.1
# esp32:esp32 3.3.8
# FQBN esp32:esp32:esp32
# Porta COM5
#
# Regras:
# - candidato copiado sem alteração;
# - falha de compilação => C=0 e F=0;
# - falha de upload/serial => infraestrutura, não falha do candidato;
# - 6 CTs congelados.
# ============================================================

$raiz = (Resolve-Path ".").Path
$fqbn = "esp32:esp32:esp32"
$portaSerial = "COM5"

$modelos = @(
    @{
        id    = "LLM01"
        nome  = "GPT-5.6-Sol"
        pasta = "LLM01_GPT-5.6-Sol"
    },
    @{
        id    = "LLM02"
        nome  = "DeepSeek-V4-Pro"
        pasta = "LLM02_DeepSeek-V4-Pro"
    },
    @{
        id    = "LLM03"
        nome  = "Claude-Sonnet-5"
        pasta = "LLM03_Claude-Sonnet-5"
    }
)

$resultados = @()

function Extrair-Metricas {
    param([string]$texto)

    $flash = $null
    $ram = $null

    if ($texto -match 'Sketch uses\s+([0-9]+)\s+bytes') {
        $flash = [int]$Matches[1]
    }

    if ($texto -match 'Global variables use\s+([0-9]+)\s+bytes') {
        $ram = [int]$Matches[1]
    }

    return @($flash, $ram)
}

foreach ($modelo in $modelos) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "T24 - $($modelo.nome)"
    Write-Host "========================================"

    $arquivoCandidato = Join-Path `
        $raiz `
        "05-respostas-llms\$($modelo.pasta)\T24\codigo.cpp"

    if (-not (Test-Path $arquivoCandidato)) {
        Write-Host "ERRO DE INFRAESTRUTURA: candidato não encontrado."
        Write-Host $arquivoCandidato

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = ""
            C_0_100         = ""
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            flash_bytes     = ""
            ram_bytes       = ""
            resultado       = "INFRA_FAIL_ARQUIVO"
        }
        continue
    }

    # ========================================================
    # FASE A - COMPILAÇÃO / INTEGRAÇÃO REAL
    # ========================================================

    $pastaReal = Join-Path `
        $raiz `
        "12-testes-objetivos\T24-$($modelo.id)-real"

    if (Test-Path $pastaReal) {
        Remove-Item $pastaReal -Recurse -Force
    }

    New-Item -ItemType Directory `
        -Path $pastaReal `
        -Force | Out-Null

    # Copia byte a byte / sem edição do candidato
    Copy-Item `
        $arquivoCandidato `
        (Join-Path $pastaReal "candidato.inc") `
        -Force

    $arquivoInoReal = Join-Path `
        $pastaReal `
        "T24-$($modelo.id)-real.ino"

    $codigoReal = @'
#include <Arduino.h>
#include <math.h>

// Contexto global fornecido à tarefa T24.
// Os nomes correspondem ao contrato do benchmark.

bool sht41Saudavel = false;
float sht41Temperatura = NAN;
float sht41Umidade = NAN;

bool bme280Saudavel = false;
float bme280Temperatura = NAN;
float bme280Umidade = NAN;

bool aht10Saudavel = false;
float aht10Temperatura = NAN;
float aht10Umidade = NAN;

float ultimaTempDHT = NAN;
float ultimaUmidDHT = NAN;

String fonteAmbienteAtual = "nenhuma";
unsigned long trocasDeFonteAmbiente = 0;

void lerAmbiente(float &temperatura, float &umidade);

#include "candidato.inc"

void setup() {
  Serial.begin(115200);

  // Força integração/link da função candidata.
  float t = NAN;
  float u = NAN;
  lerAmbiente(t, u);
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoInoReal `
        -Value $codigoReal `
        -Encoding UTF8

    $saidaCompilacao = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaReal 2>&1

    $codigoSaida = $LASTEXITCODE
    $textoCompilacao = $saidaCompilacao -join "`n"

    Write-Host $textoCompilacao

    if ($codigoSaida -ne 0) {

        Write-Host ""
        Write-Host "RESULTADO: COMPILE_FAIL"

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = 0
            C_0_100         = 0
            casos_aprovados = 0
            casos_total     = 6
            F_0_100         = 0
            flash_bytes     = ""
            ram_bytes       = ""
            resultado       = "COMPILE_FAIL"
        }

        continue
    }

    $metricas = Extrair-Metricas $textoCompilacao
    $flash = $metricas[0]
    $ram = $metricas[1]

    # ========================================================
    # FASE B - TESTES FUNCIONAIS DETERMINÍSTICOS
    # ========================================================

    $pastaTeste = Join-Path `
        $raiz `
        "12-testes-objetivos\T24-$($modelo.id)-funcional"

    if (Test-Path $pastaTeste) {
        Remove-Item $pastaTeste -Recurse -Force
    }

    New-Item -ItemType Directory `
        -Path $pastaTeste `
        -Force | Out-Null

    Copy-Item `
        $arquivoCandidato `
        (Join-Path $pastaTeste "candidato.inc") `
        -Force

    $arquivoInoTeste = Join-Path `
        $pastaTeste `
        "T24-$($modelo.id)-funcional.ino"

    $codigoTeste = @'
#include <Arduino.h>
#include <math.h>

bool sht41Saudavel = false;
float sht41Temperatura = NAN;
float sht41Umidade = NAN;

bool bme280Saudavel = false;
float bme280Temperatura = NAN;
float bme280Umidade = NAN;

bool aht10Saudavel = false;
float aht10Temperatura = NAN;
float aht10Umidade = NAN;

float ultimaTempDHT = NAN;
float ultimaUmidDHT = NAN;

String fonteAmbienteAtual = "nenhuma";
unsigned long trocasDeFonteAmbiente = 0;

void lerAmbiente(float &temperatura, float &umidade);

#include "candidato.inc"

static int aprovados = 0;
static const int TOTAL = 6;

bool quaseIgual(float a, float b, float tol = 0.001f) {
  if (isnan(a) || isnan(b)) return false;
  return fabs(a - b) <= tol;
}

void registrar(int numero, bool passou) {
  Serial0.print("CT");
  if (numero < 10) Serial0.print("0");
  Serial0.print(numero);
  Serial0.print(" -> ");
  Serial0.println(passou ? "PASS" : "FAIL");

  if (passou) aprovados++;
}

void resetarSensores() {
  sht41Saudavel = false;
  sht41Temperatura = NAN;
  sht41Umidade = NAN;

  bme280Saudavel = false;
  bme280Temperatura = NAN;
  bme280Umidade = NAN;

  aht10Saudavel = false;
  aht10Temperatura = NAN;
  aht10Umidade = NAN;

  ultimaTempDHT = NAN;
  ultimaUmidDHT = NAN;

  fonteAmbienteAtual = "nenhuma";
  trocasDeFonteAmbiente = 0;
}

void setup() {
  Serial0.begin(115200);
  delay(4000);

  Serial0.println("======================================");
  Serial0.println("ESP32-LLM BENCHMARK");
  Serial0.println("T24 - lerAmbiente");
  Serial0.println("======================================");

  float t = NAN;
  float u = NAN;

  // --------------------------------------------------------
  // CT01
  // SHT41 válido; demais também válidos.
  // Deve selecionar SHT41.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 25.0f;
  sht41Umidade = 60.0f;

  bme280Saudavel = true;
  bme280Temperatura = 30.0f;
  bme280Umidade = 70.0f;

  aht10Saudavel = true;
  aht10Temperatura = 35.0f;
  aht10Umidade = 80.0f;

  ultimaTempDHT = 20.0f;
  ultimaUmidDHT = 50.0f;

  lerAmbiente(t, u);

  registrar(
    1,
    quaseIgual(t, 25.0f) &&
    quaseIgual(u, 60.0f) &&
    fonteAmbienteAtual == "SHT41"
  );

  // --------------------------------------------------------
  // CT02
  // SHT41 inválido; BME280 válido.
  // Deve selecionar BME280.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 100.0f; // fora de -40..85
  sht41Umidade = 60.0f;

  bme280Saudavel = true;
  bme280Temperatura = 26.0f;
  bme280Umidade = 61.0f;

  aht10Saudavel = true;
  aht10Temperatura = 27.0f;
  aht10Umidade = 62.0f;

  ultimaTempDHT = 28.0f;
  ultimaUmidDHT = 63.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    2,
    quaseIgual(t, 26.0f) &&
    quaseIgual(u, 61.0f) &&
    fonteAmbienteAtual == "BME280"
  );

  // --------------------------------------------------------
  // CT03
  // SHT41/BME280 inválidos; AHT10 válido.
  // Deve selecionar AHT10.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 25.0f;
  sht41Umidade = 120.0f; // inválida

  bme280Saudavel = true;
  bme280Temperatura = -50.0f; // inválida
  bme280Umidade = 50.0f;

  aht10Saudavel = true;
  aht10Temperatura = 24.0f;
  aht10Umidade = 55.0f;

  ultimaTempDHT = 23.0f;
  ultimaUmidDHT = 54.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    3,
    quaseIgual(t, 24.0f) &&
    quaseIgual(u, 55.0f) &&
    fonteAmbienteAtual == "AHT10"
  );

  // --------------------------------------------------------
  // CT04
  // SHT/BME/AHT inválidos; DHT previamente lido válido.
  // Deve selecionar DHT22.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = false;

  bme280Saudavel = true;
  bme280Temperatura = NAN;
  bme280Umidade = 50.0f;

  aht10Saudavel = true;
  aht10Temperatura = 25.0f;
  aht10Umidade = NAN;

  ultimaTempDHT = 22.0f;
  ultimaUmidDHT = 65.0f;

  t = NAN;
  u = NAN;
  lerAmbiente(t, u);

  registrar(
    4,
    quaseIgual(t, 22.0f) &&
    quaseIgual(u, 65.0f) &&
    fonteAmbienteAtual == "DHT22"
  );

  // --------------------------------------------------------
  // CT05
  // Todos inválidos.
  // Deve retornar NAN/NAN e fonte "nenhuma".
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = false;
  bme280Saudavel = false;
  aht10Saudavel = false;

  ultimaTempDHT = NAN;
  ultimaUmidDHT = NAN;

  t = 123.0f;
  u = 123.0f;

  lerAmbiente(t, u);

  registrar(
    5,
    isnan(t) &&
    isnan(u) &&
    fonteAmbienteAtual == "nenhuma"
  );

  // --------------------------------------------------------
  // CT06
  // Fonte muda entre chamadas.
  // Deve atualizar fonteAmbienteAtual e incrementar
  // trocasDeFonteAmbiente.
  // --------------------------------------------------------
  resetarSensores();

  sht41Saudavel = true;
  sht41Temperatura = 21.0f;
  sht41Umidade = 51.0f;

  bme280Saudavel = true;
  bme280Temperatura = 22.0f;
  bme280Umidade = 52.0f;

  t = NAN;
  u = NAN;

  lerAmbiente(t, u);

  unsigned long trocasAposPrimeira = trocasDeFonteAmbiente;

  // Torna SHT inválido para obrigar fallback para BME.
  sht41Temperatura = 100.0f;

  lerAmbiente(t, u);

  registrar(
    6,
    fonteAmbienteAtual == "BME280" &&
    quaseIgual(t, 22.0f) &&
    quaseIgual(u, 52.0f) &&
    trocasDeFonteAmbiente == (trocasAposPrimeira + 1)
  );

  Serial0.println();
  Serial0.print("CASOS_APROVADOS=");
  Serial0.println(aprovados);

  Serial0.print("CASOS_EXECUTADOS=");
  Serial0.println(TOTAL);

  Serial0.print("RESULTADO=");
  Serial0.println(aprovados == TOTAL ? "PASS" : "FAIL");
}

void loop() {
}
'@

    Set-Content `
        -Path $arquivoInoTeste `
        -Value $codigoTeste `
        -Encoding UTF8

    # Compilação do harness funcional.
    $saidaFuncional = & arduino-cli compile `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $codigoFuncional = $LASTEXITCODE
    $textoFuncional = $saidaFuncional -join "`n"

    if ($codigoFuncional -ne 0) {
        Write-Host $textoFuncional
        Write-Host ""
        Write-Host "ERRO DE INFRAESTRUTURA/HARNESS NA FASE B."
        Write-Host "Não registrar como falha do candidato."

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = 1
            C_0_100         = 100
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            flash_bytes     = $flash
            ram_bytes       = $ram
            resultado       = "INFRA_FAIL_HARNESS"
        }

        continue
    }

    # Upload.
    $saidaUpload = & arduino-cli upload `
        -p $portaSerial `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $codigoUpload = $LASTEXITCODE
    $textoUpload = $saidaUpload -join "`n"

    Write-Host $textoUpload

    if ($codigoUpload -ne 0) {
        Write-Host ""
        Write-Host "ERRO DE INFRAESTRUTURA: falha de upload."

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = 1
            C_0_100         = 100
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            flash_bytes     = $flash
            ram_bytes       = $ram
            resultado       = "INFRA_FAIL_UPLOAD"
        }

        continue
    }

    Start-Sleep -Seconds 1

    # Captura serial durante 15 s.
    $saidaSerial = ""
    $arquivoLog = Join-Path `
        $pastaTeste `
        "serial.log"

    try {
        $porta = New-Object System.IO.Ports.SerialPort `
            $portaSerial, 115200, None, 8, one

        $porta.ReadTimeout = 500
        $porta.DtrEnable = $false
        $porta.RtsEnable = $false
        $porta.Open()

        $fim = (Get-Date).AddSeconds(15)

        while ((Get-Date) -lt $fim) {
            try {
                $linha = $porta.ReadLine()
                $saidaSerial += $linha + "`n"
                Write-Host $linha
            }
            catch [System.TimeoutException] {
                # continua aguardando
            }
        }

        $porta.Close()
    }
    catch {
        Write-Host ""
        Write-Host "ERRO DE INFRAESTRUTURA: captura serial."
        Write-Host $_.Exception.Message

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = 1
            C_0_100         = 100
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            flash_bytes     = $flash
            ram_bytes       = $ram
            resultado       = "INFRA_FAIL_SERIAL"
        }

        continue
    }

    Set-Content `
        -Path $arquivoLog `
        -Value $saidaSerial `
        -Encoding UTF8

    $casosAprovados = $null

    if ($saidaSerial -match 'CASOS_APROVADOS=(\d+)') {
        $casosAprovados = [int]$Matches[1]
    }

    if ($null -eq $casosAprovados) {
        Write-Host ""
        Write-Host "ERRO DE INFRAESTRUTURA: marcador de resultado não recebido."

        $resultados += [PSCustomObject]@{
            tarefa          = "T24"
            modelo_id       = $modelo.id
            modelo          = $modelo.nome
            compilou        = 1
            C_0_100         = 100
            casos_aprovados = ""
            casos_total     = 6
            F_0_100         = ""
            flash_bytes     = $flash
            ram_bytes       = $ram
            resultado       = "INFRA_FAIL_SERIAL"
        }

        continue
    }

    $f = [math]::Round(($casosAprovados / 6.0) * 100, 2)

    $resultadoFinal = if ($casosAprovados -eq 6) {
        "PASS"
    }
    else {
        "FUNCTIONAL_FAIL"
    }

    $resultados += [PSCustomObject]@{
        tarefa          = "T24"
        modelo_id       = $modelo.id
        modelo          = $modelo.nome
        compilou        = 1
        C_0_100         = 100
        casos_aprovados = $casosAprovados
        casos_total     = 6
        F_0_100         = $f
        flash_bytes     = $flash
        ram_bytes       = $ram
        resultado       = $resultadoFinal
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS OBJETIVOS T24"
Write-Host "========================================"

$resultados | Format-Table -AutoSize

$csv = Join-Path `
    $raiz `
    "12-testes-objetivos\resultados_T24.csv"

$resultados |
    Export-Csv `
        -Path $csv `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host $csv
