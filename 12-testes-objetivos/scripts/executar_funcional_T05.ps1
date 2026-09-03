$root = (Get-Location).Path
$baseTestes = Join-Path $root "12-testes-objetivos"

$porta = "COM5"
$fqbn = "esp32:esp32:esp32"

$modelos = @(
    @{ Id="LLM01"; Nome="GPT-5.6-Sol";     Pasta="T05-LLM01" },
    @{ Id="LLM02"; Nome="DeepSeek-V4-Pro"; Pasta="T05-LLM02" },
    @{ Id="LLM03"; Nome="Claude-Sonnet-5"; Pasta="T05-LLM03" }
)

$resultados = @()

foreach ($modelo in $modelos) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "TESTANDO T05 - $($modelo.Nome)"
    Write-Host "========================================"

    $pastaTeste = Join-Path $baseTestes $modelo.Pasta

    $logUpload = Join-Path $pastaTeste "upload.log"
    $logSerial = Join-Path $pastaTeste "execucao_serial.log"

    # ========================================================
    # COMPILAÇÃO + UPLOAD
    # ========================================================

    $saidaUpload = & arduino-cli compile `
        --upload `
        -p $porta `
        --fqbn $fqbn `
        $pastaTeste 2>&1

    $exitUpload = $LASTEXITCODE

    $saidaUpload |
        Tee-Object -FilePath $logUpload

    if ($exitUpload -ne 0) {

        $resultados += [PSCustomObject]@{
            tarefa = "T05"
            modelo_id = $modelo.Id
            modelo = $modelo.Nome
            execucao_ok = 0
            casos_aprovados = 0
            casos_executados = 5
            F_0_100 = ""
            resultado = "COMPILE_UPLOAD_FAIL"
        }

        continue
    }

    # ========================================================
    # CAPTURA SERIAL
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
            -Path $logSerial `
            -Encoding UTF8

    # ========================================================
    # INTERPRETAÇÃO
    # ========================================================

    $aprovados = 0
    $executados = 5
    $resultadoFinal = "SEM_RESULTADO"
    $execucaoOK = 0

    if ($texto -match "CASOS_APROVADOS=(\d+)") {
        $aprovados = [int]$matches[1]
    }

    if ($texto -match "CASOS_EXECUTADOS=(\d+)") {
        $executados = [int]$matches[1]
    }

    if ($texto -match "RESULTADO=(PASS|FAIL)") {
        $resultadoFinal = $matches[1]
        $execucaoOK = 1
    }

    if ($execucaoOK -eq 1 -and $executados -gt 0) {

        $F = [math]::Round(
            ($aprovados / $executados) * 100,
            2
        )

    } else {

        $F = ""
    }

    $resultados += [PSCustomObject]@{
        tarefa = "T05"
        modelo_id = $modelo.Id
        modelo = $modelo.Nome
        execucao_ok = $execucaoOK
        casos_aprovados = $aprovados
        casos_executados = $executados
        F_0_100 = $F
        resultado = $resultadoFinal
    }
}

$resultados |
    Export-Csv `
        "$baseTestes\resultados_funcionais_T05.csv" `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host "RESULTADOS FUNCIONAIS T05"
Write-Host "========================================"

$resultados |
    Format-Table -AutoSize

Write-Host ""
Write-Host "CSV salvo em:"
Write-Host "$baseTestes\resultados_funcionais_T05.csv"