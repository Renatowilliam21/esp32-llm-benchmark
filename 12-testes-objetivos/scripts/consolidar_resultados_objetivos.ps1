$root = (Get-Location).Path
$baseTestes = Join-Path $root "12-testes-objetivos"

$resultados = @()

function Obter-PrimeiroValor {
    param(
        $objeto,
        [string[]]$nomes
    )

    foreach ($nome in $nomes) {
        $propriedade = $objeto.PSObject.Properties[$nome]

        if ($null -ne $propriedade) {
            $valor = $propriedade.Value

            if ($null -ne $valor -and "$valor" -ne "") {
                return $valor
            }
        }
    }

    return ""
}

function Obter-Nivel {
    param([string]$tarefa)

    $numero = [int]($tarefa.Substring(1))

    if ($numero -le 10) {
        return "Facil"
    }
    elseif ($numero -le 20) {
        return "Medio"
    }
    else {
        return "Dificil"
    }
}

function Adicionar-Resultado {
    param(
        [string]$tarefa,
        [string]$modeloId,
        [string]$modelo,
        $C,
        $F,
        $aprovados,
        $total,
        $flash,
        $ram,
        [string]$status
    )

    $script:resultados += [PSCustomObject]@{
        tarefa           = $tarefa
        nivel            = Obter-Nivel $tarefa
        modelo_id        = $modeloId
        modelo           = $modelo
        C_0_100          = $C
        F_0_100          = $F
        casos_aprovados  = $aprovados
        casos_total      = $total
        flash_bytes      = $flash
        ram_bytes        = $ram
        status           = $status
    }
}

# ============================================================
# T01 a T06
# CSV de compilacao + CSV funcional
# ============================================================

1..6 | ForEach-Object {

    $tarefa = "T{0:D2}" -f $_

    $arquivoComp = Join-Path `
        $baseTestes `
        ("resultados_compilacao_" + $tarefa + ".csv")

    $arquivoFunc = Join-Path `
        $baseTestes `
        ("resultados_funcionais_" + $tarefa + ".csv")

    $compilacoes = Import-Csv $arquivoComp
    $funcionais = Import-Csv $arquivoFunc

    foreach ($comp in $compilacoes) {

        $func = $funcionais |
            Where-Object {
                $_.modelo_id -eq $comp.modelo_id
            } |
            Select-Object -First 1

        $C = Obter-PrimeiroValor $comp @("C_0_100")
        $F = Obter-PrimeiroValor $func @("F_0_100")

        $aprovados = Obter-PrimeiroValor `
            $func `
            @("casos_aprovados", "checks_aprovados")

        $total = Obter-PrimeiroValor `
            $func `
            @(
                "casos_total",
                "casos_executados",
                "checks_executados"
            )

        $flash = Obter-PrimeiroValor `
            $comp `
            @("flash_bytes")

        $ram = Obter-PrimeiroValor `
            $comp `
            @("ram_bytes")

        $status = Obter-PrimeiroValor `
            $func `
            @("resultado", "status")

        Adicionar-Resultado `
            $tarefa `
            $comp.modelo_id `
            $comp.modelo `
            $C `
            $F `
            $aprovados `
            $total `
            $flash `
            $ram `
            $status
    }
}

# ============================================================
# T07 a T22
# CSV unico por tarefa
# ============================================================

7..22 | ForEach-Object {

    $tarefa = "T{0:D2}" -f $_

    $arquivo = Join-Path `
        $baseTestes `
        ("resultados_" + $tarefa + ".csv")

    $dados = Import-Csv $arquivo

    foreach ($linha in $dados) {

        $C = Obter-PrimeiroValor `
            $linha `
            @("C_0_100")

        $F = Obter-PrimeiroValor `
            $linha `
            @("F_0_100")

        $aprovados = Obter-PrimeiroValor `
            $linha `
            @(
                "casos_aprovados",
                "checks_aprovados"
            )

        $total = Obter-PrimeiroValor `
            $linha `
            @(
                "casos_total",
                "casos_executados",
                "checks_executados"
            )

        $flash = Obter-PrimeiroValor `
            $linha `
            @("flash_bytes")

        $ram = Obter-PrimeiroValor `
            $linha `
            @("ram_bytes")

        $status = Obter-PrimeiroValor `
            $linha `
            @(
                "resultado",
                "status"
            )

        Adicionar-Resultado `
            $tarefa `
            $linha.modelo_id `
            $linha.modelo `
            $C `
            $F `
            $aprovados `
            $total `
            $flash `
            $ram `
            $status
    }
}

# ============================================================
# T23 a T27
# CSV final padronizado
# ============================================================

23..27 | ForEach-Object {

    $tarefa = "T{0:D2}" -f $_

    $arquivo = Join-Path `
        $baseTestes `
        ("resultados_" + $tarefa + ".csv")

    $dados = Import-Csv $arquivo

    foreach ($linha in $dados) {

        $C = Obter-PrimeiroValor `
            $linha `
            @("C_0_100")

        $F = Obter-PrimeiroValor `
            $linha `
            @("F_0_100")

        $aprovados = Obter-PrimeiroValor `
            $linha `
            @("casos_aprovados")

        $total = Obter-PrimeiroValor `
            $linha `
            @(
                "casos_total",
                "casos_executados"
            )

        $flash = Obter-PrimeiroValor `
            $linha `
            @("flash_bytes")

        $ram = Obter-PrimeiroValor `
            $linha `
            @("ram_bytes")

        $status = Obter-PrimeiroValor `
            $linha `
            @(
                "status",
                "resultado"
            )

        Adicionar-Resultado `
            $tarefa `
            $linha.modelo_id `
            $linha.modelo `
            $C `
            $F `
            $aprovados `
            $total `
            $flash `
            $ram `
            $status
    }
}

# ============================================================
# T28
# compilacao real + funcional
# ============================================================

$compilacoesT28 = Import-Csv `
    (Join-Path `
        $baseTestes `
        "resultados_T28_compilacao_real.csv")

$funcionaisT28 = Import-Csv `
    (Join-Path `
        $baseTestes `
        "resultados_T28_funcional.csv")

foreach ($comp in $compilacoesT28) {

    $func = $funcionaisT28 |
        Where-Object {
            $_.modelo_id -eq $comp.modelo_id
        } |
        Select-Object -First 1

    $status = if ($comp.C_0_100 -eq "100") {

        if ($func.F_0_100 -eq "100") {
            "PASS"
        }
        else {
            "FAIL"
        }
    }
    else {
        "COMPILE_FAIL"
    }

    Adicionar-Resultado `
        "T28" `
        $comp.modelo_id `
        $comp.modelo `
        $comp.C_0_100 `
        $func.F_0_100 `
        $func.casos_aprovados `
        $func.casos_total `
        $comp.flash_bytes `
        $comp.ram_bytes `
        $status
}

# ============================================================
# T29 e T30
# CSV final padronizado
# ============================================================

29..30 | ForEach-Object {

    $tarefa = "T{0:D2}" -f $_

    $arquivo = Join-Path `
        $baseTestes `
        ("resultados_" + $tarefa + ".csv")

    $dados = Import-Csv $arquivo

    foreach ($linha in $dados) {

        Adicionar-Resultado `
            $tarefa `
            $linha.modelo_id `
            $linha.modelo `
            $linha.C_0_100 `
            $linha.F_0_100 `
            $linha.casos_aprovados `
            $linha.casos_total `
            (Obter-PrimeiroValor $linha @("flash_bytes")) `
            (Obter-PrimeiroValor $linha @("ram_bytes")) `
            (Obter-PrimeiroValor $linha @("status", "resultado"))
    }
}

# ============================================================
# VALIDACOES
# ============================================================

$resultados = $resultados |
    Sort-Object `
        @{ Expression = {
            [int]($_.tarefa.Substring(1))
        }},
        modelo_id

Write-Host ""
Write-Host "========================================"
Write-Host "VALIDACAO DA CONSOLIDACAO"
Write-Host "========================================"

Write-Host "Total de observacoes: $($resultados.Count)"

$duplicados = $resultados |
    Group-Object tarefa, modelo_id |
    Where-Object {
        $_.Count -ne 1
    }

if ($duplicados.Count -gt 0) {

    Write-Host ""
    Write-Host "ERRO: duplicidades encontradas"

    $duplicados |
        Format-Table Name, Count -AutoSize

    throw "Consolidacao invalida: duplicidades."
}

if ($resultados.Count -ne 90) {
    throw "Esperadas 90 observacoes, encontradas $($resultados.Count)."
}

foreach ($n in 1..30) {

    $tarefa = "T{0:D2}" -f $n

    $quantidade = (
        $resultados |
        Where-Object {
            $_.tarefa -eq $tarefa
        }
    ).Count

    if ($quantidade -ne 3) {
        throw "$tarefa possui $quantidade observacoes; esperado: 3."
    }
}

# ============================================================
# EXPORTACAO
# ============================================================

$arquivoFinal = Join-Path `
    $baseTestes `
    "resultados_objetivos_90.csv"

$resultados |
    Export-Csv `
        -Path $arquivoFinal `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "Consolidacao concluida com sucesso."
Write-Host "Arquivo:"
Write-Host $arquivoFinal

Write-Host ""
Write-Host "RESUMO POR MODELO"
Write-Host "========================================"

$resultados |
    Group-Object modelo_id, modelo |
    ForEach-Object {

        $grupo = $_.Group

        [PSCustomObject]@{
            modelo = $grupo[0].modelo
            tarefas = $grupo.Count
            compilacoes_ok = (
                $grupo |
                Where-Object {
                    $_.C_0_100 -eq 100
                }
            ).Count
            funcionais_100 = (
                $grupo |
                Where-Object {
                    $_.F_0_100 -eq 100
                }
            ).Count
            media_C = [math]::Round(
                (
                    $grupo |
                    Measure-Object `
                        -Property C_0_100 `
                        -Average
                ).Average,
                2
            )
            media_F = [math]::Round(
                (
                    $grupo |
                    Measure-Object `
                        -Property F_0_100 `
                        -Average
                ).Average,
                2
            )
        }
    } |
    Format-Table -AutoSize