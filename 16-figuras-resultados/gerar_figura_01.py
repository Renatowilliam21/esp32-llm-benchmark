#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera a Figura 2 do artigo (médias de C, F e R por modelo e nível de dificuldade,
em três painéis) a partir de 14-taxonomia-falhas/qualitativo_vs_objetivo_90.csv.

Uso:
    python 16-figuras-resultados/gerar_figura_01.py [caminho_da_raiz]

Saída: 16-figuras-resultados/figura_01_R_C_F_por_modelo_nivel.pdf
Dependências: pandas, matplotlib
"""
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

BASE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
MODELOS = ["GPT-5.6-Sol", "DeepSeek-V4-Pro", "Claude-Sonnet-5"]
NIVEIS = ["Fácil", "Médio", "Difícil"]
CORES = ["#1f77b4", "#ff7f0e", "#2ca02c"]

q = pd.read_csv(BASE / "14-taxonomia-falhas" / "qualitativo_vs_objetivo_90.csv", encoding="utf-8")
q["num"] = q["tarefa"].str[1:].astype(int)
q["nivel"] = pd.cut(q["num"], [0, 10, 20, 30], labels=NIVEIS)
medias = q.groupby(["modelo", "nivel"], observed=True)[["C_0_100", "F_0_100", "R_0_100"]].mean()

paineis = [
    ("(a) Compilação (C)", "C_0_100"),
    ("(b) Correção funcional (F)", "F_0_100"),
    ("(c) Avaliação qualitativa (R)", "R_0_100"),
]

fig, eixos = plt.subplots(1, 3, figsize=(10, 3.4), sharey=True)
x = np.arange(len(NIVEIS))
w = 0.26
for ax, (titulo, coluna) in zip(eixos, paineis):
    for i, m in enumerate(MODELOS):
        valores = [medias.loc[(m, n), coluna] for n in NIVEIS]
        barras = ax.bar(x + (i - 1) * w, valores, w, label=m, color=CORES[i])
        for b, v in zip(barras, valores):
            ax.text(b.get_x() + b.get_width() / 2, v + 1.5, f"{v:g}", ha="center", va="bottom", fontsize=6.5)
    ax.set_title(titulo, fontsize=9)
    ax.set_xticks(x)
    ax.set_xticklabels(NIVEIS, fontsize=8)
    ax.set_ylim(0, 115)
    ax.grid(axis="y", linestyle=":", alpha=0.5)
    ax.set_axisbelow(True)
eixos[0].set_ylabel("Pontuação média (0 a 100)", fontsize=8)
eixos[0].tick_params(axis="y", labelsize=8)
h, l = eixos[0].get_legend_handles_labels()
fig.legend(h, l, loc="lower center", ncol=3, fontsize=8, frameon=False)
fig.tight_layout(rect=(0, 0.08, 1, 1))
saida = BASE / "16-figuras-resultados" / "figura_01_R_C_F_por_modelo_nivel.pdf"
fig.savefig(saida, bbox_inches="tight")
print("Figura gerada em", saida)
