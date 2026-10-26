#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reproduz, a partir dos CSV do repositório, os números reportados no artigo
"ESP32-LLM: Uma Avaliação Experimental da Confiabilidade de Código Gerado por
Large Language Models para Sistemas Embarcados".

Uso (na raiz do repositório ou em qualquer pasta):
    python 13-analise-estatistica/reproduzir_resultados.py [caminho_da_raiz]

Dependências: pandas, scipy, scikit-learn  (pip install pandas scipy scikit-learn)

Para cada número, o script imprime o valor calculado, o valor do artigo e
OK ou DIFERE. Nada é escrito em disco.

Arquivos lidos:
    14-taxonomia-falhas/qualitativo_vs_objetivo_90.csv   (R, C, F por solução)
    14-taxonomia-falhas/taxonomia_falhas_tarefas_dificeis.csv
    11-avaliacao/resultados_julgamento_consolidados.csv  (notas dos dois juízes)
"""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats
from sklearn.metrics import cohen_kappa_score

BASE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
MODELOS = ["GPT-5.6-Sol", "DeepSeek-V4-Pro", "Claude-Sonnet-5"]
NIVEIS = ["Fácil", "Médio", "Difícil"]
# Respostas do DeepSeek V4 Pro retornadas sem código (limite de 8192 tokens)
TAREFAS_VAZIAS = ["T23", "T24", "T25", "T29"]

resultados = []


def chk(nome, calculado, esperado, tol=0.006):
    """Compara um valor calculado com o valor do artigo."""
    if calculado is None or (isinstance(calculado, float) and np.isnan(calculado)):
        ok = esperado is None
    else:
        ok = esperado is not None and abs(calculado - esperado) <= tol
    resultados.append(ok)
    calc = "n/a" if calculado is None or (isinstance(calculado, float) and np.isnan(calculado)) else f"{calculado:.4f}"
    esp = "n/a" if esperado is None else f"{esperado}"
    print(f"  [{'OK ' if ok else 'DIFERE'}] {nome}: calculado={calc} | artigo={esp}")


def chk_menor(nome, calculado, limite):
    ok = calculado < limite
    resultados.append(ok)
    print(f"  [{'OK ' if ok else 'DIFERE'}] {nome}: calculado={calculado:.5f} | artigo=<{limite}")


def holm(ps):
    m = len(ps)
    ordem = np.argsort(ps)
    ajust = np.empty(m)
    anterior = 0.0
    for posicao, i in enumerate(ordem):
        valor = min(1.0, (m - posicao) * ps[i])
        anterior = max(anterior, valor)
        ajust[i] = anterior
    return ajust


def rank_biserial(x, y):
    u1, _ = stats.mannwhitneyu(x, y, alternative="two-sided", method="asymptotic")
    return abs(2 * u1 / (len(x) * len(y)) - 1)


# ----------------------------------------------------------------------------
q = pd.read_csv(BASE / "14-taxonomia-falhas" / "qualitativo_vs_objetivo_90.csv", encoding="utf-8")
q["num"] = q["tarefa"].str[1:].astype(int)
q["nivel"] = pd.cut(q["num"], [0, 10, 20, 30], labels=NIVEIS)
q["compilou"] = (q["C_0_100"] == 100).astype(int)

print("=" * 78)
print("1. Médias de C, F e R por modelo e nível (Figura 2 e Seção 4.1)")
esp_geral = {"GPT-5.6-Sol": (76.67, 76.67), "DeepSeek-V4-Pro": (73.33, 71.00), "Claude-Sonnet-5": (70.00, 70.00)}
esp_nivel = {  # (C, F, R) por nível
    "GPT-5.6-Sol": {"Fácil": (100, 100, 100), "Médio": (100, 100, 100), "Difícil": (30, 30, 96.5)},
    "DeepSeek-V4-Pro": {"Fácil": (100, 100, 99.5), "Médio": (100, 93, 100), "Difícil": (20, 20, 50.5)},
    "Claude-Sonnet-5": {"Fácil": (100, 100, 100), "Médio": (100, 100, 98.5), "Difícil": (10, 10, 90.0)},
}
for m in MODELOS:
    d = q[q["modelo"] == m]
    chk(f"{m} C geral", d["C_0_100"].mean(), esp_geral[m][0])
    chk(f"{m} F geral", d["F_0_100"].mean(), esp_geral[m][1])
    for n in NIVEIS:
        dn = d[d["nivel"] == n]
        c, f, r = esp_nivel[m][n]
        chk(f"{m} {n}: C", dn["C_0_100"].mean(), c)
        chk(f"{m} {n}: F", dn["F_0_100"].mean(), f)
        chk(f"{m} {n}: R", dn["R_0_100"].mean(), r)

print("=" * 78)
print("2. Compilações e tarefas difíceis (Seção 4.1)")
for m, n in zip(MODELOS, (23, 22, 21)):
    chk(f"{m}: soluções compiláveis", float(q[q["modelo"] == m]["compilou"].sum()), n, tol=0)
dif = q[q["nivel"] == "Difícil"]
chk("Difícil: combinações aprovadas integralmente", float((dif["F_0_100"] == 100).sum()), 6, tol=0)
chk("Difícil: falhas de compilação/integração", float((dif["compilou"] == 0).sum()), 24, tol=0)
chk("Difícil: compiláveis com aprovação parcial", float(((dif["compilou"] == 1) & (dif["F_0_100"] < 100)).sum()), 0, tol=0)

print("=" * 78)
print("3. Comparação global entre modelos (Seção 4.2)")
matriz_c = q.pivot(index="tarefa", columns="modelo", values="compilou")[MODELOS]
matriz_f = q.pivot(index="tarefa", columns="modelo", values="F_0_100")[MODELOS]
k = matriz_c.shape[1]
colunas = matriz_c.sum(axis=0).values
linhas = matriz_c.sum(axis=1).values
T = colunas.sum()
Q = (k - 1) * (k * (colunas ** 2).sum() - T ** 2) / (k * T - (linhas ** 2).sum())
chk("Cochran Q (compilação)", float(Q), 3.00)
chk("Cochran p", float(stats.chi2.sf(Q, k - 1)), 0.223, tol=0.0006)
fr = stats.friedmanchisquare(*[matriz_f[m] for m in MODELOS])
chk("Friedman chi2 (F)", float(fr.statistic), 3.50)
chk("Friedman p", float(fr.pvalue), 0.174, tol=0.0006)

print("=" * 78)
print("4. Dificuldade e F por modelo: Kruskal-Wallis, Mann-Whitney com Holm, rank-biserial")
esp_h = {"GPT-5.6-Sol": 17.65, "DeepSeek-V4-Pro": 17.64, "Claude-Sonnet-5": 24.86}
esp_holm = {  # (fácil-médio, fácil-difícil, médio-difícil)
    "GPT-5.6-Sol": (None, 0.0032, 0.0032),
    "DeepSeek-V4-Pro": (0.168, 0.0013, 0.0033),
    "Claude-Sonnet-5": (None, "<0.001", "<0.001"),
}
esp_r = {"GPT-5.6-Sol": (None, 0.70, 0.70), "DeepSeek-V4-Pro": (None, 0.80, 0.76), "Claude-Sonnet-5": (None, 0.90, 0.90)}
pares = [("Fácil", "Médio"), ("Fácil", "Difícil"), ("Médio", "Difícil")]
for m in MODELOS:
    d = q[q["modelo"] == m]
    grupos = {n: d[d["nivel"] == n]["F_0_100"].values for n in NIVEIS}
    h = stats.kruskal(*[grupos[n] for n in NIVEIS])
    chk(f"{m}: H de Kruskal-Wallis", float(h.statistic), esp_h[m], tol=0.011)
    chk_menor(f"{m}: p de Kruskal-Wallis", float(h.pvalue), 0.001)
    # Convenção do artigo: a correção de Holm é aplicada às comparações testáveis.
    # Pares em que os dois grupos são idênticos e constantes (ex.: F=100 em todas as
    # tarefas dos dois níveis) não têm o que testar e ficam fora da família de Holm.
    degenerado = [len(np.unique(np.concatenate([grupos[a], grupos[b]]))) == 1 for a, b in pares]
    testaveis = [i for i, dg in enumerate(degenerado) if not dg]
    brutos = {i: stats.mannwhitneyu(grupos[pares[i][0]], grupos[pares[i][1]], alternative="two-sided", method="asymptotic").pvalue for i in testaveis}
    ajust_lista = holm(np.array([brutos[i] for i in testaveis]))
    ajust = {i: v for i, v in zip(testaveis, ajust_lista)}
    for i, ((a, b), esp_p, esp_rb) in enumerate(zip(pares, esp_holm[m], esp_r[m])):
        if i not in ajust:
            print(f"  [info] {m} {a}-{b}: grupos idênticos e constantes, fora da família de Holm")
            continue
        p = ajust[i]
        if esp_p is None:
            print(f"  [info] {m} {a}-{b}: p_Holm calculado={p:.4f} (não reportado individualmente no artigo)")
        elif isinstance(esp_p, str):
            chk_menor(f"{m} {a}-{b}: p_Holm", float(p), 0.001)
        else:
            chk(f"{m} {a}-{b}: p_Holm", float(p), esp_p, tol=0.0006)
        if esp_rb is not None:
            chk(f"{m} {a}-{b}: rank-biserial", float(rank_biserial(grupos[a], grupos[b])), esp_rb, tol=0.006)

print("=" * 78)
print("5. Avaliação qualitativa (R) e desempenho funcional (F) (Seção 4.4)")
rho, p = stats.spearmanr(q["R_0_100"], q["F_0_100"])
chk("Spearman global", float(rho), 0.658, tol=0.0006)
chk_menor("Spearman global: p", float(p), 0.001)
for n, esp_rho, esp_p in (("Médio", -0.050, 0.795), ("Difícil", 0.292, 0.117)):
    dn = q[q["nivel"] == n]
    rho, p = stats.spearmanr(dn["R_0_100"], dn["F_0_100"])
    chk(f"Spearman {n}: rho", float(rho), esp_rho, tol=0.0006)
    chk(f"Spearman {n}: p", float(p), esp_p, tol=0.0006)
facil = q[q["nivel"] == "Fácil"]
print(f"  [info] Fácil: F constante? {facil['F_0_100'].nunique() == 1} (correlação não calculável)")

vazias = q[(q["modelo"] == "DeepSeek-V4-Pro") & (q["tarefa"].isin(TAREFAS_VAZIAS))]
chk("Respostas sem código: R=0 nas 4", float((vazias["R_0_100"] == 0).sum()), 4, tol=0)
s = q[~q.index.isin(vazias.index)]
rho, p = stats.spearmanr(s["R_0_100"], s["F_0_100"])
chk("Sem as 4 vazias: N", float(len(s)), 86, tol=0)
chk("Sem as 4 vazias: Spearman global", float(rho), 0.595, tol=0.0006)
sd = s[s["nivel"] == "Difícil"]
rho, p = stats.spearmanr(sd["R_0_100"], sd["F_0_100"])
chk("Sem as 4 vazias: N difícil", float(len(sd)), 26, tol=0)
chk("Sem as 4 vazias: Spearman difícil", float(rho), 0.223, tol=0.0006)
chk("Sem as 4 vazias: p difícil", float(p), 0.274, tol=0.0006)
ds_dif = q[(q["modelo"] == "DeepSeek-V4-Pro") & (q["nivel"] == "Difícil")]
chk("DeepSeek difícil: R médio com as 4 vazias", float(ds_dif["R_0_100"].mean()), 50.5)
chk("DeepSeek difícil: R médio nas 6 com código", float(ds_dif[~ds_dif.index.isin(vazias.index)]["R_0_100"].mean()), 84.2, tol=0.06)
chk("Soluções com R>=80 e F<100", float(((q["R_0_100"] >= 80) & (q["F_0_100"] < 100)).sum()), 18, tol=0)

print("=" * 78)
print("6. Taxonomia de falhas nas tarefas difíceis (Seção 4.3)")
tx = pd.read_csv(BASE / "14-taxonomia-falhas" / "taxonomia_falhas_tarefas_dificeis.csv", encoding="utf-8")
falhas = tx[tx["status_objetivo"] == "COMPILE_FAIL"]
cont = falhas["categoria_principal"].value_counts()
chk("Falhas de compilação/integração", float(len(falhas)), 24, tol=0)
classif = falhas[falhas["categoria_principal"].isin(["E1", "E2", "E3"])]
chk("Classificáveis", float(len(classif)), 21, tol=0)
for cat, n_esp, pct in (("E3", 16, 76.2), ("E2", 3, 14.3), ("E1", 2, 9.5)):
    n = int(cont.get(cat, 0))
    chk(f"{cat}: contagem", float(n), n_esp, tol=0)
    chk(f"{cat}: percentual", 100 * n / len(classif), pct, tol=0.06)
chk("Indeterminadas (T24)", float(cont.get("INDETERMINADO", 0)), 3, tol=0)

print("=" * 78)
print("7. Concordância entre os dois juízes (Seção 3.2)")
j = pd.read_csv(BASE / "11-avaliacao" / "resultados_julgamento_consolidados.csv", encoding="utf-8")
par = j.dropna(subset=["nota_juiz_1", "nota_juiz_2"]).copy()
a = par["nota_juiz_1"].round().astype(int)
b = par["nota_juiz_2"].round().astype(int)
d = (a - b).abs()
chk("Pares com duas notas válidas", float(len(par)), 87, tol=0)
chk("Kappa ponderado quadrático", float(cohen_kappa_score(a, b, weights="quadratic")), 0.80, tol=0.006)
chk("Diferença absoluta média", float(d.mean()), 0.30, tol=0.006)
chk("Pares com diferença <= 1 ponto (%)", float(100 * (d <= 1).mean()), 90.8, tol=0.06)

print("=" * 78)
print(f"Resumo: {sum(resultados)} de {len(resultados)} conferências OK")
if not all(resultados):
    print("Há valores que DIFEREM do artigo: revise antes de submeter.")
    sys.exit(1)
