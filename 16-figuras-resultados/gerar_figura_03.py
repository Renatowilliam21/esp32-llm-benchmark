from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


# ============================================================
# ESP32-LLM Benchmark
# Figura 3 — mapa de calor da funcionalidade por tarefa
# ============================================================

BASE = Path(__file__).resolve().parent.parent

ARQUIVO = (
    BASE
    / "12-testes-objetivos"
    / "resultados_objetivos_90.csv"
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

tarefas = [
    f"T{i:02d}"
    for i in range(1, 31)
]


# ------------------------------------------------------------
# Validação
# ------------------------------------------------------------

if len(df) != 90:
    raise ValueError(
        f"Esperadas 90 observações; encontradas {len(df)}."
    )

if df[["tarefa", "modelo"]].duplicated().any():
    raise ValueError(
        "Existem pares tarefa/modelo duplicados."
    )


# ------------------------------------------------------------
# Matriz tarefa x modelo
# ------------------------------------------------------------

matriz = (
    df
    .pivot(
        index="tarefa",
        columns="modelo",
        values="F_0_100",
    )
    .reindex(index=tarefas, columns=modelos)
)

if matriz.isna().any().any():
    raise ValueError(
        "Há combinações tarefa/modelo sem resultado funcional."
    )


# ------------------------------------------------------------
# Figura
# ------------------------------------------------------------

fig, ax = plt.subplots(
    figsize=(7.2, 10.5)
)

imagem = ax.imshow(
    matriz.values,
    aspect="auto",
    vmin=0,
    vmax=100,
)

# Eixos
ax.set_xticks(
    np.arange(len(modelos))
)

ax.set_xticklabels(
    modelos,
    rotation=20,
    ha="right",
)

ax.set_yticks(
    np.arange(len(tarefas))
)

ax.set_yticklabels(
    tarefas
)

ax.set_xlabel(
    "Large Language Model"
)

ax.set_ylabel(
    "Tarefa"
)

ax.set_title(
    "Desempenho funcional por tarefa e modelo"
)


# ------------------------------------------------------------
# Valores dentro das células
# ------------------------------------------------------------

for i in range(len(tarefas)):
    for j in range(len(modelos)):

        valor = matriz.iloc[i, j]

        ax.text(
            j,
            i,
            f"{valor:.0f}",
            ha="center",
            va="center",
            fontsize=7,
        )


# ------------------------------------------------------------
# Separação visual dos níveis
# ------------------------------------------------------------

ax.axhline(
    9.5,
    linewidth=1.2,
)

ax.axhline(
    19.5,
    linewidth=1.2,
)

ax.text(
    len(modelos) - 0.45,
    4.5,
    "Fácil",
    rotation=90,
    va="center",
    fontsize=9,
)

ax.text(
    len(modelos) - 0.45,
    14.5,
    "Médio",
    rotation=90,
    va="center",
    fontsize=9,
)

ax.text(
    len(modelos) - 0.45,
    24.5,
    "Difícil",
    rotation=90,
    va="center",
    fontsize=9,
)


# ------------------------------------------------------------
# Barra de escala
# ------------------------------------------------------------

cbar = fig.colorbar(
    imagem,
    ax=ax,
    fraction=0.04,
    pad=0.04,
)

cbar.set_label(
    "Pontuação funcional F (0–100)"
)


fig.tight_layout()


# ------------------------------------------------------------
# Exportação
# ------------------------------------------------------------

arquivo_png = (
    SAIDA
    / "figura_03_mapa_calor_funcionalidade_tarefas.png"
)

arquivo_pdf = (
    SAIDA
    / "figura_03_mapa_calor_funcionalidade_tarefas.pdf"
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
# Resumo textual
# ------------------------------------------------------------

print("=" * 65)
print("FIGURA 3 GERADA")
print("=" * 65)

print("\nPNG:")
print(arquivo_png)

print("\nPDF:")
print(arquivo_pdf)

print("\nMatriz funcional F:")

print(
    matriz.to_string()
)

print("\nOK.")