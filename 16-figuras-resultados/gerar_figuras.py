from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


# ============================================================
# ESP32-LLM Benchmark
# Figuras dos resultados
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
# Configuração visual
# ------------------------------------------------------------

plt.rcParams.update({
    "font.size": 10,
    "axes.titlesize": 11,
    "axes.labelsize": 10,
    "xtick.labelsize": 9,
    "ytick.labelsize": 9,
    "legend.fontsize": 9,
    "figure.dpi": 150,
})


# ------------------------------------------------------------
# Leitura dos dados
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

metricas = [
    "R_0_100",
    "C_0_100",
    "F_0_100",
]

rotulos_metricas = [
    "Qualitativa (R)",
    "Compilação (C)",
    "Funcionalidade (F)",
]


# ------------------------------------------------------------
# Validação
# ------------------------------------------------------------

esperado = len(modelos) * len(niveis)

if len(df) != esperado:
    raise ValueError(
        f"Esperadas {esperado} combinações modelo/nível; "
        f"encontradas {len(df)}."
    )


# ------------------------------------------------------------
# Figura 1
# R, C e F por modelo e dificuldade
# ------------------------------------------------------------

fig, axes = plt.subplots(
    nrows=1,
    ncols=3,
    figsize=(12, 4.3),
    sharey=True,
)

largura = 0.24
x = np.arange(len(niveis))

for ax, modelo in zip(axes, modelos):

    dados_modelo = (
        df[df["modelo"] == modelo]
        .set_index("nivel")
        .reindex(niveis)
    )

    for i, (metrica, rotulo) in enumerate(
        zip(metricas, rotulos_metricas)
    ):

        valores = dados_modelo[metrica].values

        deslocamento = (i - 1) * largura

        barras = ax.bar(
            x + deslocamento,
            valores,
            largura,
            label=rotulo,
        )

        # Valores sobre as barras
        for barra, valor in zip(barras, valores):

            if pd.notna(valor):

                ax.text(
                    barra.get_x() + barra.get_width() / 2,
                    valor + 2,
                    f"{valor:.1f}",
                    ha="center",
                    va="bottom",
                    fontsize=7.5,
                    rotation=0,
                )

    ax.set_title(modelo)

    ax.set_xticks(x)

    ax.set_xticklabels(
        ["Fácil", "Médio", "Difícil"]
    )

    ax.set_ylim(0, 112)

    ax.grid(
        axis="y",
        linestyle="--",
        linewidth=0.5,
        alpha=0.4,
    )


axes[0].set_ylabel("Pontuação média (0–100)")

fig.legend(
    rotulos_metricas,
    loc="upper center",
    ncol=3,
    frameon=False,
    bbox_to_anchor=(0.5, 1.02),
)

fig.suptitle(
    "Avaliação qualitativa, compilação e funcionalidade por nível de dificuldade",
    y=1.09,
    fontsize=12,
)

fig.tight_layout()


# ------------------------------------------------------------
# Exportação
# ------------------------------------------------------------

arquivo_png = (
    SAIDA
    / "figura_01_R_C_F_por_modelo_nivel.png"
)

arquivo_pdf = (
    SAIDA
    / "figura_01_R_C_F_por_modelo_nivel.pdf"
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
# Finalização
# ------------------------------------------------------------

print("=" * 65)
print("FIGURA 1 GERADA")
print("=" * 65)

print("\nPNG:")
print(arquivo_png)

print("\nPDF:")
print(arquivo_pdf)

print("\nDados utilizados:")

print(
    df[
        [
            "modelo",
            "nivel",
            "R_0_100",
            "C_0_100",
            "F_0_100",
        ]
    ].to_string(index=False)
)

print("\nOK.")