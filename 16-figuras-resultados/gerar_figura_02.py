from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


# ============================================================
# ESP32-LLM Benchmark
# Figura 2 — desempenho funcional por dificuldade
# ============================================================

BASE = Path(__file__).resolve().parent.parent

ARQUIVO = (
    BASE
    / "15-analise-qualitativa-objetiva"
    / "resumo_R_C_F_por_modelo_nivel.csv"
)

SAIDA = BASE / "16-figuras-resultados"
SAIDA.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# Leitura
# ------------------------------------------------------------

df = pd.read_csv(ARQUIVO)

modelos = [
    "GPT-5.6-Sol",
    "DeepSeek-V4-Pro",
    "Claude-Sonnet-5",
]

niveis = [
    "Facil",
    "Medio",
    "Dificil",
]

rotulos_niveis = [
    "Fácil",
    "Médio",
    "Difícil",
]


# ------------------------------------------------------------
# Organização dos dados
# ------------------------------------------------------------

dados = {}

for modelo in modelos:
    serie = (
        df[df["modelo"] == modelo]
        .set_index("nivel")
        .reindex(niveis)["F_0_100"]
    )

    dados[modelo] = serie.values


# ------------------------------------------------------------
# Figura
# ------------------------------------------------------------

fig, ax = plt.subplots(
    figsize=(8.5, 5)
)

x = np.arange(len(niveis))
largura = 0.24

for i, modelo in enumerate(modelos):

    deslocamento = (i - 1) * largura

    barras = ax.bar(
        x + deslocamento,
        dados[modelo],
        largura,
        label=modelo,
    )

    for barra, valor in zip(
        barras,
        dados[modelo],
    ):
        ax.text(
            barra.get_x()
            + barra.get_width() / 2,
            valor + 2,
            f"{valor:.1f}",
            ha="center",
            va="bottom",
            fontsize=8,
        )


# ------------------------------------------------------------
# Formatação
# ------------------------------------------------------------

ax.set_title(
    "Desempenho funcional por nível de dificuldade"
)

ax.set_xlabel(
    "Nível de dificuldade"
)

ax.set_ylabel(
    "Pontuação funcional média F (0–100)"
)

ax.set_xticks(x)

ax.set_xticklabels(
    rotulos_niveis
)

ax.set_ylim(
    0,
    112
)

ax.grid(
    axis="y",
    linestyle="--",
    linewidth=0.5,
    alpha=0.4,
)

ax.legend(
    frameon=False
)

fig.tight_layout()


# ------------------------------------------------------------
# Exportação
# ------------------------------------------------------------

arquivo_png = (
    SAIDA
    / "figura_02_funcionalidade_por_dificuldade.png"
)

arquivo_pdf = (
    SAIDA
    / "figura_02_funcionalidade_por_dificuldade.pdf"
)

fig.savefig(
    arquivo_png,
    dpi=300,
    bbox_inches="tight",
)

fig.savefig(
    arquivo_pdf,
    bbox_inches="tight",
)

plt.close(fig)


# ------------------------------------------------------------
# Saída
# ------------------------------------------------------------

print("=" * 65)
print("FIGURA 2 GERADA")
print("=" * 65)

print("\nPNG:")
print(arquivo_png)

print("\nPDF:")
print(arquivo_pdf)

print("\nValores utilizados:")

for modelo in modelos:
    print(
        f"{modelo}: "
        f"Fácil={dados[modelo][0]:.1f}, "
        f"Médio={dados[modelo][1]:.1f}, "
        f"Difícil={dados[modelo][2]:.1f}"
    )

print("\nOK.")