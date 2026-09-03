from pathlib import Path
import warnings

import numpy as np
import pandas as pd
from scipy.stats import spearmanr, ConstantInputWarning


# ============================================================
# ESP32-LLM Benchmark
# Análise integrada: avaliação qualitativa x validação objetiva
# ============================================================

BASE = Path(__file__).resolve().parent.parent

ARQ_QUALITATIVO = (
    BASE
    / "11-avaliacao"
    / "resultados_qualitativos_finais_90.csv"
)

ARQ_OBJETIVO = (
    BASE
    / "12-testes-objetivos"
    / "resultados_objetivos_90.csv"
)

PASTA_SAIDA = BASE / "15-analise-qualitativa-objetiva"
PASTA_SAIDA.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# Funções auxiliares
# ------------------------------------------------------------

def definir_nivel(tarefa):
    numero = int(tarefa[1:])

    if numero <= 10:
        return "Facil"
    elif numero <= 20:
        return "Medio"
    else:
        return "Dificil"


def calcular_spearman(df, nome):
    """
    Calcula Spearman entre R e F.

    Quando uma das variáveis é constante, a correlação não é
    definida e os campos rho/p são armazenados como NaN.
    """

    r = df["R_0_100"]
    f = df["F_0_100"]

    if r.nunique() <= 1 or f.nunique() <= 1:
        return {
            "nivel": nome,
            "N": len(df),
            "rho_spearman": np.nan,
            "p_valor": np.nan,
        }

    resultado = spearmanr(r, f)

    return {
        "nivel": nome,
        "N": len(df),
        "rho_spearman": resultado.statistic,
        "p_valor": resultado.pvalue,
    }


# ------------------------------------------------------------
# 1. Leitura dos dados oficiais
# ------------------------------------------------------------

qual = pd.read_csv(ARQ_QUALITATIVO)
obj = pd.read_csv(ARQ_OBJETIVO)

print("=" * 70)
print("ESP32-LLM BENCHMARK")
print("Análise qualitativa x objetiva")
print("=" * 70)

print(f"\nRegistros qualitativos: {len(qual)}")
print(f"Registros objetivos:    {len(obj)}")


# ------------------------------------------------------------
# 2. Validações iniciais
# ------------------------------------------------------------

if len(qual) != 90:
    raise ValueError(
        f"Esperadas 90 avaliações qualitativas; encontradas {len(qual)}."
    )

if len(obj) != 90:
    raise ValueError(
        f"Esperados 90 resultados objetivos; encontrados {len(obj)}."
    )

if qual[["tarefa", "gerador_id"]].duplicated().any():
    raise ValueError(
        "Existem pares tarefa/gerador_id duplicados no arquivo qualitativo."
    )

if obj[["tarefa", "modelo_id"]].duplicated().any():
    raise ValueError(
        "Existem pares tarefa/modelo_id duplicados no arquivo objetivo."
    )


# ------------------------------------------------------------
# 3. Seleção das variáveis
# ------------------------------------------------------------

qual_sel = qual[
    [
        "anon_id",
        "tarefa",
        "gerador_id",
        "gerador",
        "R_final_0_100",
    ]
].copy()

qual_sel = qual_sel.rename(
    columns={
        "gerador_id": "modelo_id",
        "gerador": "modelo",
        "R_final_0_100": "R_0_100",
    }
)

obj_sel = obj[
    [
        "tarefa",
        "modelo_id",
        "C_0_100",
        "F_0_100",
        "casos_aprovados",
        "casos_total",
        "status",
    ]
].copy()


# ------------------------------------------------------------
# 4. Pareamento qualitativo x objetivo
# ------------------------------------------------------------

dados = qual_sel.merge(
    obj_sel,
    on=["tarefa", "modelo_id"],
    how="left",
    validate="one_to_one",
)

if len(dados) != 90:
    raise ValueError(
        f"O pareamento deveria produzir 90 registros, mas produziu {len(dados)}."
    )

colunas_objetivas = [
    "C_0_100",
    "F_0_100",
    "casos_aprovados",
    "casos_total",
    "status",
]

faltantes = dados[colunas_objetivas].isna().any(axis=1)

if faltantes.any():
    print("\nERRO: avaliações qualitativas sem resultado objetivo correspondente:")
    print(
        dados.loc[
            faltantes,
            ["anon_id", "tarefa", "modelo_id", "modelo"]
        ].to_string(index=False)
    )
    raise ValueError("Pareamento incompleto entre os dois conjuntos de dados.")


# ------------------------------------------------------------
# 5. Nível de dificuldade
# ------------------------------------------------------------

dados["nivel"] = dados["tarefa"].apply(definir_nivel)

ordem_nivel = pd.CategoricalDtype(
    categories=["Facil", "Medio", "Dificil"],
    ordered=True,
)

dados["nivel"] = dados["nivel"].astype(ordem_nivel)


# ------------------------------------------------------------
# 6. Conversão numérica
# ------------------------------------------------------------

for coluna in [
    "R_0_100",
    "C_0_100",
    "F_0_100",
    "casos_aprovados",
    "casos_total",
]:
    dados[coluna] = pd.to_numeric(
        dados[coluna],
        errors="raise",
    )


# ------------------------------------------------------------
# 7. Validação da distribuição dos status
# ------------------------------------------------------------

status = (
    dados["status"]
    .value_counts()
    .rename_axis("status")
    .reset_index(name="quantidade")
)

print("\nDistribuição dos status objetivos:")
print(status.to_string(index=False))

if len(dados) != 90:
    raise ValueError("Número final de observações diferente de 90.")


# ------------------------------------------------------------
# 8. Correlação de Spearman global e por dificuldade
# ------------------------------------------------------------

resultados_correlacao = []

resultados_correlacao.append(
    calcular_spearman(dados, "Global")
)

for nivel in ["Facil", "Medio", "Dificil"]:
    subconjunto = dados[dados["nivel"] == nivel]

    resultados_correlacao.append(
        calcular_spearman(subconjunto, nivel)
    )

correlacoes = pd.DataFrame(resultados_correlacao)

print("\nCorrelação entre avaliação qualitativa R e funcionalidade F:")
print(correlacoes.to_string(index=False))


# ------------------------------------------------------------
# 9. Resumo R, C e F por modelo e dificuldade
# ------------------------------------------------------------

resumo_modelo_nivel = (
    dados
    .groupby(
        ["modelo", "nivel"],
        observed=True
    )[
        ["R_0_100", "C_0_100", "F_0_100"]
    ]
    .mean()
    .round(2)
    .reset_index()
)

resumo_modelo_nivel["diferenca_R_F"] = (
    resumo_modelo_nivel["R_0_100"]
    - resumo_modelo_nivel["F_0_100"]
).round(2)

print("\nMédias de R, C e F por modelo e dificuldade:")
print(resumo_modelo_nivel.to_string(index=False))


# ------------------------------------------------------------
# 10. Resumo global por modelo
# ------------------------------------------------------------

resumo_modelo = (
    dados
    .groupby("modelo")[
        ["R_0_100", "C_0_100", "F_0_100"]
    ]
    .mean()
    .round(2)
    .reset_index()
)

resumo_modelo["diferenca_R_F"] = (
    resumo_modelo["R_0_100"]
    - resumo_modelo["F_0_100"]
).round(2)


# ------------------------------------------------------------
# 11. Divergências qualitativo x objetivo
#
# R >= 80 é utilizado somente como corte descritivo/exploratório.
# Não constitui métrica primária do benchmark.
# ------------------------------------------------------------

divergencias = dados[
    (dados["R_0_100"] >= 80)
    & (dados["F_0_100"] < 100)
].copy()

divergencias = divergencias.sort_values(
    ["tarefa", "modelo"]
)

print(
    "\nCasos com R >= 80 e F < 100 "
    "(corte descritivo):"
)

print(
    divergencias[
        [
            "anon_id",
            "tarefa",
            "modelo",
            "nivel",
            "R_0_100",
            "C_0_100",
            "F_0_100",
            "status",
        ]
    ].to_string(index=False)
)

n_divergencias = len(divergencias)

n_compile_fail = (
    divergencias["status"] == "COMPILE_FAIL"
).sum()

n_fail = (
    divergencias["status"] == "FAIL"
).sum()


# ------------------------------------------------------------
# 12. Resumo PASS / FAIL / COMPILE_FAIL
# ------------------------------------------------------------

status_modelo = (
    dados
    .groupby(["modelo", "status"])
    .size()
    .reset_index(name="quantidade")
)


# ------------------------------------------------------------
# 13. Exportação dos artefatos
# ------------------------------------------------------------

dados.to_csv(
    PASTA_SAIDA / "qualitativo_vs_objetivo_90.csv",
    index=False,
)

correlacoes.to_csv(
    PASTA_SAIDA / "correlacao_qualitativo_funcional.csv",
    index=False,
)

resumo_modelo_nivel.to_csv(
    PASTA_SAIDA / "resumo_R_C_F_por_modelo_nivel.csv",
    index=False,
)

resumo_modelo.to_csv(
    PASTA_SAIDA / "resumo_R_C_F_por_modelo.csv",
    index=False,
)

divergencias.to_csv(
    PASTA_SAIDA / "divergencias_R80_F_menor_100.csv",
    index=False,
)

status.to_csv(
    PASTA_SAIDA / "distribuicao_status.csv",
    index=False,
)

status_modelo.to_csv(
    PASTA_SAIDA / "status_por_modelo.csv",
    index=False,
)


# ------------------------------------------------------------
# 14. Relatório textual automático
# ------------------------------------------------------------

global_corr = correlacoes[
    correlacoes["nivel"] == "Global"
].iloc[0]

facil_corr = correlacoes[
    correlacoes["nivel"] == "Facil"
].iloc[0]

medio_corr = correlacoes[
    correlacoes["nivel"] == "Medio"
].iloc[0]

dificil_corr = correlacoes[
    correlacoes["nivel"] == "Dificil"
].iloc[0]

linhas = []

linhas.append("ESP32-LLM BENCHMARK")
linhas.append("ANÁLISE QUALITATIVA X OBJETIVA")
linhas.append("=" * 60)

linhas.append("")
linhas.append(f"N total: {len(dados)}")

linhas.append("")
linhas.append("DISTRIBUIÇÃO DOS STATUS")
for _, linha in status.iterrows():
    linhas.append(
        f"{linha['status']}: {linha['quantidade']}"
    )

linhas.append("")
linhas.append("CORRELAÇÃO R x F")

linhas.append(
    "Global: "
    f"rho={global_corr['rho_spearman']:.6f}; "
    f"p={global_corr['p_valor']:.6g}; "
    f"N={int(global_corr['N'])}"
)

if pd.isna(facil_corr["rho_spearman"]):
    linhas.append(
        "Fácil: correlação não estimável, "
        "pois F é constante."
    )
else:
    linhas.append(
        "Fácil: "
        f"rho={facil_corr['rho_spearman']:.6f}; "
        f"p={facil_corr['p_valor']:.6g}"
    )

linhas.append(
    "Médio: "
    f"rho={medio_corr['rho_spearman']:.6f}; "
    f"p={medio_corr['p_valor']:.6g}"
)

linhas.append(
    "Difícil: "
    f"rho={dificil_corr['rho_spearman']:.6f}; "
    f"p={dificil_corr['p_valor']:.6g}"
)

linhas.append("")
linhas.append("DIVERGÊNCIAS DESCRITIVAS")

linhas.append(
    f"Casos com R >= 80 e F < 100: {n_divergencias}"
)

linhas.append(
    f"Desses, COMPILE_FAIL: {n_compile_fail}"
)

linhas.append(
    f"Desses, FAIL funcional: {n_fail}"
)

linhas.append("")
linhas.append(
    "Observação: R >= 80 foi empregado apenas como "
    "corte descritivo para localizar divergências e não "
    "como métrica primária do benchmark."
)

linhas.append("")
linhas.append("MÉDIAS R/C/F POR MODELO E NÍVEL")

for _, linha in resumo_modelo_nivel.iterrows():
    linhas.append(
        f"{linha['modelo']} | {linha['nivel']} | "
        f"R={linha['R_0_100']:.2f} | "
        f"C={linha['C_0_100']:.2f} | "
        f"F={linha['F_0_100']:.2f} | "
        f"R-F={linha['diferenca_R_F']:.2f}"
    )

relatorio = "\n".join(linhas)

with open(
    PASTA_SAIDA / "relatorio_qualitativo_objetivo.txt",
    "w",
    encoding="utf-8",
) as arquivo:
    arquivo.write(relatorio)


# ------------------------------------------------------------
# 15. Finalização
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("ANÁLISE CONCLUÍDA")
print("=" * 70)

print(
    f"\nCasos R >= 80 e F < 100: {n_divergencias}"
)

print(
    f"  COMPILE_FAIL: {n_compile_fail}"
)

print(
    f"  FAIL:         {n_fail}"
)

print(
    "\nArquivos gerados em:"
)

print(PASTA_SAIDA)

print("\nOK.")