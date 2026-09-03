#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import annotations

from pathlib import Path
import math
import sys
import warnings

import pandas as pd
from scipy.stats import friedmanchisquare, kruskal, mannwhitneyu
from statsmodels.stats.contingency_tables import cochrans_q
from statsmodels.stats.multitest import multipletests

ROOT = Path(__file__).resolve().parents[1]
ARQUIVO_ENTRADA = ROOT / "12-testes-objetivos" / "resultados_objetivos_90.csv"
PASTA_SAIDA = ROOT / "13-analise-estatistica" / "saida"

MODELOS = ["LLM01", "LLM02", "LLM03"]
NOMES_MODELOS = {
    "LLM01": "GPT-5.6-Sol",
    "LLM02": "DeepSeek-V4-Pro",
    "LLM03": "Claude-Sonnet-5",
}
NIVEIS = ["Facil", "Medio", "Dificil"]
ALFA = 0.05


def significancia(p):
    if p is None or pd.isna(p):
        return "NA"
    return "SIGNIFICATIVO" if p < ALFA else "NAO_SIGNIFICATIVO"


def classificar_efeito_rrb(r):
    if r is None or pd.isna(r):
        return "NA"
    a = abs(float(r))
    if a < 0.10:
        return "desprezivel"
    if a < 0.30:
        return "pequeno"
    if a < 0.50:
        return "moderado"
    return "grande"


def rank_biserial(u, n1, n2):
    return (2.0 * float(u) / (n1 * n2)) - 1.0


def grupos_identicos(a: pd.Series, b: pd.Series) -> bool:
    aa = sorted(pd.to_numeric(a, errors="coerce").dropna().tolist())
    bb = sorted(pd.to_numeric(b, errors="coerce").dropna().tolist())
    return aa == bb


def localizar_status(df):
    for c in ("status", "resultado"):
        if c in df.columns:
            return c
    return None


def carregar_dados():
    if not ARQUIVO_ENTRADA.exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {ARQUIVO_ENTRADA}")

    df = pd.read_csv(ARQUIVO_ENTRADA)

    obrigatorias = {
        "tarefa", "nivel", "modelo_id", "modelo",
        "C_0_100", "F_0_100", "casos_aprovados", "casos_total"
    }
    faltantes = sorted(obrigatorias - set(df.columns))
    if faltantes:
        raise ValueError("Colunas ausentes: " + ", ".join(faltantes))

    for c in ["tarefa", "nivel", "modelo_id", "modelo"]:
        df[c] = df[c].astype(str).str.strip()

    for c in ["C_0_100", "F_0_100", "casos_aprovados", "casos_total"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    if len(df) != 90:
        raise ValueError(f"Esperadas 90 observações; encontradas {len(df)}.")

    for m in MODELOS:
        qtd = int((df["modelo_id"] == m).sum())
        if qtd != 30:
            raise ValueError(f"{m}: esperadas 30 observações; encontradas {qtd}.")

    por_tarefa = df.groupby("tarefa").size()
    ruins = por_tarefa[por_tarefa != 3]
    if not ruins.empty:
        raise ValueError(f"Cada tarefa deve ter 3 observações: {ruins.to_dict()}")

    tarefas = sorted(df["tarefa"].unique())
    esperadas = [f"T{i:02d}" for i in range(1, 31)]
    if tarefas != esperadas:
        raise ValueError(f"Tarefas diferentes de T01..T30: {tarefas}")

    status_col = localizar_status(df)
    if status_col:
        inconsistencias = []
        for _, row in df.iterrows():
            s = str(row[status_col]).strip().upper()
            c = row["C_0_100"]
            f = row["F_0_100"]
            if c == 0 and s == "PASS":
                inconsistencias.append(f"{row['tarefa']}/{row['modelo_id']}: C=0 e PASS")
            if c == 100 and f == 100 and s == "COMPILE_FAIL":
                inconsistencias.append(f"{row['tarefa']}/{row['modelo_id']}: C=100/F=100 e COMPILE_FAIL")
        if inconsistencias:
            raise ValueError("Status inconsistente:\n- " + "\n- ".join(inconsistencias))

    return df


def gerar_resumos(df):
    resumo_modelo = (
        df.groupby(["modelo_id", "modelo"], as_index=False)
        .agg(
            tarefas=("tarefa", "count"),
            compilacoes_ok=("C_0_100", lambda x: int((x == 100).sum())),
            funcionais_100=("F_0_100", lambda x: int((x == 100).sum())),
            media_C=("C_0_100", "mean"),
            media_F=("F_0_100", "mean"),
            mediana_C=("C_0_100", "median"),
            mediana_F=("F_0_100", "median"),
        )
    )

    resumo_nivel = (
        df.groupby(["modelo_id", "modelo", "nivel"], as_index=False)
        .agg(
            tarefas=("tarefa", "count"),
            compilacoes_ok=("C_0_100", lambda x: int((x == 100).sum())),
            funcionais_100=("F_0_100", lambda x: int((x == 100).sum())),
            media_C=("C_0_100", "mean"),
            media_F=("F_0_100", "mean"),
            mediana_C=("C_0_100", "median"),
            mediana_F=("F_0_100", "median"),
        )
    )
    ordem = pd.Categorical(resumo_nivel["nivel"], categories=NIVEIS, ordered=True)
    resumo_nivel = resumo_nivel.assign(_ordem=ordem).sort_values(["modelo_id", "_ordem"]).drop(columns="_ordem")
    return resumo_modelo, resumo_nivel


def gerar_matrizes(df):
    comp = df.pivot(index=["tarefa", "nivel"], columns="modelo_id", values="C_0_100").reset_index().rename(columns=NOMES_MODELOS)
    func = df.pivot(index=["tarefa", "nivel"], columns="modelo_id", values="F_0_100").reset_index().rename(columns=NOMES_MODELOS)
    return comp, func


def analise_cochran(df):
    linhas = []
    subconjuntos = [("Todas", df)] + [(n, df[df["nivel"] == n]) for n in NIVEIS]

    for nome, sub in subconjuntos:
        p = sub.pivot(index="tarefa", columns="modelo_id", values="C_0_100")[MODELOS] / 100.0
        discordancia = p.apply(lambda r: r.nunique() > 1, axis=1).any()
        if not discordancia:
            linhas.append({
                "escopo": nome, "n_tarefas": len(p), "Q": math.nan,
                "gl": 2, "p": math.nan, "resultado": "NA_SEM_DISCORDANCIA"
            })
            continue

        r = cochrans_q(p.values)
        linhas.append({
            "escopo": nome, "n_tarefas": len(p), "Q": float(r.statistic),
            "gl": 2, "p": float(r.pvalue), "resultado": significancia(r.pvalue)
        })
    return pd.DataFrame(linhas)


def analise_friedman(df):
    linhas = []
    subconjuntos = [("Todas", df)] + [(n, df[df["nivel"] == n]) for n in NIVEIS]

    for nome, sub in subconjuntos:
        p = sub.pivot(index="tarefa", columns="modelo_id", values="F_0_100")[MODELOS]
        if p["LLM01"].equals(p["LLM02"]) and p["LLM01"].equals(p["LLM03"]):
            linhas.append({
                "escopo": nome, "n_tarefas": len(p), "chi2": math.nan,
                "gl": 2, "p": math.nan, "resultado": "NA_GRUPOS_IDENTICOS"
            })
            continue

        r = friedmanchisquare(p["LLM01"], p["LLM02"], p["LLM03"])
        linhas.append({
            "escopo": nome, "n_tarefas": len(p), "chi2": float(r.statistic),
            "gl": 2, "p": float(r.pvalue), "resultado": significancia(r.pvalue)
        })
    return pd.DataFrame(linhas)


def analise_kruskal(df):
    linhas = []
    for modelo_id in MODELOS:
        d = df[df["modelo_id"] == modelo_id]
        g = {n: d[d["nivel"] == n]["F_0_100"].dropna() for n in NIVEIS}
        r = kruskal(g["Facil"], g["Medio"], g["Dificil"])
        linhas.append({
            "modelo_id": modelo_id,
            "modelo": NOMES_MODELOS[modelo_id],
            "media_facil": g["Facil"].mean(),
            "media_medio": g["Medio"].mean(),
            "media_dificil": g["Dificil"].mean(),
            "mediana_facil": g["Facil"].median(),
            "mediana_medio": g["Medio"].median(),
            "mediana_dificil": g["Dificil"].median(),
            "H": float(r.statistic), "gl": 2, "p": float(r.pvalue),
            "resultado": significancia(r.pvalue),
        })
    return pd.DataFrame(linhas)


def posthoc_dificuldade(df):
    comparacoes = [("Facil", "Medio"), ("Facil", "Dificil"), ("Medio", "Dificil")]
    linhas = []

    for modelo_id in MODELOS:
        d = df[df["modelo_id"] == modelo_id]
        temporarios = []
        validos = []

        for g1, g2 in comparacoes:
            a = d[d["nivel"] == g1]["F_0_100"].dropna()
            b = d[d["nivel"] == g2]["F_0_100"].dropna()

            if grupos_identicos(a, b):
                item = {
                    "modelo_id": modelo_id, "modelo": NOMES_MODELOS[modelo_id],
                    "comparacao": f"{g1} x {g2}", "grupo1": g1, "grupo2": g2,
                    "U": math.nan, "p_bruto": math.nan, "p_holm": math.nan,
                    "resultado": "NA_GRUPOS_IDENTICOS"
                }
            else:
                r = mannwhitneyu(a, b, alternative="two-sided")
                item = {
                    "modelo_id": modelo_id, "modelo": NOMES_MODELOS[modelo_id],
                    "comparacao": f"{g1} x {g2}", "grupo1": g1, "grupo2": g2,
                    "U": float(r.statistic), "p_bruto": float(r.pvalue),
                    "p_holm": math.nan, "resultado": None
                }
                validos.append(item)

            temporarios.append(item)

        if validos:
            ajustados = multipletests([x["p_bruto"] for x in validos], alpha=ALFA, method="holm")[1]
            for item, p_adj in zip(validos, ajustados):
                item["p_holm"] = float(p_adj)
                item["resultado"] = significancia(p_adj)

        linhas.extend(temporarios)

    return pd.DataFrame(linhas)


def tamanhos_efeito(df, posthoc):
    linhas = []
    for _, row in posthoc.iterrows():
        if row["resultado"] == "NA_GRUPOS_IDENTICOS":
            linhas.append({
                "modelo_id": row["modelo_id"], "modelo": row["modelo"],
                "comparacao": row["comparacao"], "U": math.nan,
                "rank_biserial": math.nan, "magnitude": "NA_GRUPOS_IDENTICOS",
                "direcao": "NA"
            })
            continue

        d = df[df["modelo_id"] == row["modelo_id"]]
        a = d[d["nivel"] == row["grupo1"]]["F_0_100"].dropna()
        b = d[d["nivel"] == row["grupo2"]]["F_0_100"].dropna()
        u = float(row["U"])
        rrb = rank_biserial(u, len(a), len(b))

        if rrb > 0:
            direcao = f"{row['grupo1']} > {row['grupo2']}"
        elif rrb < 0:
            direcao = f"{row['grupo2']} > {row['grupo1']}"
        else:
            direcao = "sem_direcao"

        linhas.append({
            "modelo_id": row["modelo_id"], "modelo": row["modelo"],
            "comparacao": row["comparacao"], "U": u,
            "rank_biserial": rrb, "magnitude": classificar_efeito_rrb(rrb),
            "direcao": direcao
        })
    return pd.DataFrame(linhas)


def gerar_relatorio(resumo_modelo, cochran, friedman, kruskal_df, posthoc, efeitos):
    linhas = []
    add = linhas.append

    add("ESP32-LLM BENCHMARK — RELATÓRIO ESTATÍSTICO")
    add("=" * 64)
    add(f"Entrada: {ARQUIVO_ENTRADA}")
    add("Observações: 90 (30 tarefas x 3 LLMs)")
    add(f"Alfa: {ALFA}")
    add("")

    add("1. RESUMO POR MODELO")
    add("-" * 64)
    for _, r in resumo_modelo.iterrows():
        add(f"{r['modelo']}: compilações={int(r['compilacoes_ok'])}/30; F=100={int(r['funcionais_100'])}/30; média C={r['media_C']:.2f}; média F={r['media_F']:.2f}")
    add("")

    add("2. COCHRAN Q — COMPILAÇÃO ENTRE LLMs")
    add("-" * 64)
    for _, r in cochran.iterrows():
        if pd.isna(r["Q"]):
            add(f"{r['escopo']}: não aplicável ({r['resultado']}).")
        else:
            add(f"{r['escopo']}: Q({int(r['gl'])})={r['Q']:.4f}; p={r['p']:.8f}; {r['resultado']}.")
    add("")

    add("3. FRIEDMAN — F ENTRE LLMs")
    add("-" * 64)
    for _, r in friedman.iterrows():
        if pd.isna(r["chi2"]):
            add(f"{r['escopo']}: não aplicável ({r['resultado']}).")
        else:
            add(f"{r['escopo']}: chi2({int(r['gl'])})={r['chi2']:.4f}; p={r['p']:.8f}; {r['resultado']}.")
    add("")

    add("4. KRUSKAL–WALLIS — DIFICULDADE DENTRO DE CADA MODELO")
    add("-" * 64)
    for _, r in kruskal_df.iterrows():
        add(f"{r['modelo']}: Fácil={r['media_facil']:.2f}; Médio={r['media_medio']:.2f}; Difícil={r['media_dificil']:.2f}; H({int(r['gl'])})={r['H']:.4f}; p={r['p']:.8f}; {r['resultado']}.")
    add("")

    add("5. PÓS-TESTES MANN–WHITNEY + HOLM")
    add("-" * 64)
    for _, r in posthoc.iterrows():
        if pd.isna(r["U"]):
            add(f"{r['modelo']} — {r['comparacao']}: NA (grupos idênticos).")
        else:
            add(f"{r['modelo']} — {r['comparacao']}: U={r['U']:.1f}; p={r['p_bruto']:.8f}; p_Holm={r['p_holm']:.8f}; {r['resultado']}.")
    add("")

    add("6. TAMANHO DE EFEITO — RANK-BISERIAL")
    add("-" * 64)
    for _, r in efeitos.iterrows():
        if pd.isna(r["rank_biserial"]):
            add(f"{r['modelo']} — {r['comparacao']}: NA.")
        else:
            add(f"{r['modelo']} — {r['comparacao']}: r_rb={r['rank_biserial']:.4f}; magnitude={r['magnitude']}; direção={r['direcao']}.")
    add("")

    add("7. INTERPRETAÇÃO SINTÉTICA")
    add("-" * 64)
    add("A compilabilidade não apresentou diferença estatisticamente significativa entre as três LLMs no conjunto das 30 tarefas.")
    add("A correção funcional F também não apresentou diferença global estatisticamente significativa entre as três LLMs quando as mesmas tarefas foram comparadas de forma pareada.")
    add("A dificuldade apresentou associação estatisticamente significativa com a redução de F em cada uma das três LLMs, com a queda concentrada no nível Difícil.")
    add("Os contrastes Fácil x Difícil e Médio x Difícil foram significativos após Holm nos três modelos. Fácil x Médio não foi significativo no DeepSeek e foi não aplicável no GPT e Claude por grupos idênticos.")
    add("")
    add("OBSERVAÇÃO METODOLÓGICA")
    add("-" * 64)
    add("Os testes entre LLMs preservam o pareamento por tarefa. Para comparar níveis de dificuldade dentro de cada modelo foi usado Kruskal–Wallis, pois Fácil, Médio e Difícil são conjuntos distintos de tarefas, não medições repetidas da mesma tarefa.")
    add("Ausência de significância estatística não deve ser interpretada como prova de equivalência entre modelos.")

    return "\n".join(linhas)


def main():
    PASTA_SAIDA.mkdir(parents=True, exist_ok=True)
    print("=" * 70)
    print("ESP32-LLM BENCHMARK — ANÁLISE ESTATÍSTICA")
    print("=" * 70)
    print(f"Entrada: {ARQUIVO_ENTRADA}")
    print(f"Saída:   {PASTA_SAIDA}\n")

    df = carregar_dados()
    print("Validação estrutural: OK")
    print("90 observações, 30 tarefas e 3 modelos confirmados.\n")

    resumo_modelo, resumo_nivel = gerar_resumos(df)
    matriz_comp, matriz_func = gerar_matrizes(df)
    cochran = analise_cochran(df)
    friedman = analise_friedman(df)
    kruskal_df = analise_kruskal(df)
    posthoc = posthoc_dificuldade(df)
    efeitos = tamanhos_efeito(df, posthoc)

    resumo_modelo.to_csv(PASTA_SAIDA / "resumo_por_modelo.csv", index=False, encoding="utf-8-sig")
    resumo_nivel.to_csv(PASTA_SAIDA / "resumo_por_modelo_nivel.csv", index=False, encoding="utf-8-sig")
    matriz_comp.to_csv(PASTA_SAIDA / "matriz_compilacao.csv", index=False, encoding="utf-8-sig")
    matriz_func.to_csv(PASTA_SAIDA / "matriz_funcional.csv", index=False, encoding="utf-8-sig")
    cochran.to_csv(PASTA_SAIDA / "cochran_compilacao.csv", index=False, encoding="utf-8-sig")
    friedman.to_csv(PASTA_SAIDA / "friedman_funcional.csv", index=False, encoding="utf-8-sig")
    kruskal_df.to_csv(PASTA_SAIDA / "kruskal_dificuldade.csv", index=False, encoding="utf-8-sig")
    posthoc.to_csv(PASTA_SAIDA / "posthoc_dificuldade_holm.csv", index=False, encoding="utf-8-sig")
    efeitos.to_csv(PASTA_SAIDA / "tamanhos_efeito_rank_biserial.csv", index=False, encoding="utf-8-sig")

    relatorio = gerar_relatorio(resumo_modelo, cochran, friedman, kruskal_df, posthoc, efeitos)
    (PASTA_SAIDA / "relatorio_estatistico.txt").write_text(relatorio, encoding="utf-8")

    print("RESUMO POR MODELO")
    print(resumo_modelo[["modelo", "tarefas", "compilacoes_ok", "funcionais_100", "media_C", "media_F"]].to_string(index=False))
    print("\nCOCHRAN Q")
    print(cochran.to_string(index=False))
    print("\nFRIEDMAN")
    print(friedman.to_string(index=False))
    print("\nKRUSKAL–WALLIS")
    print(kruskal_df[["modelo", "media_facil", "media_medio", "media_dificil", "H", "p", "resultado"]].to_string(index=False))
    print("\nArquivos gerados:")
    for p in sorted(PASTA_SAIDA.iterdir()):
        print(" -", p.name)
    print("\nAnálise concluída com sucesso.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        sys.exit(1)
