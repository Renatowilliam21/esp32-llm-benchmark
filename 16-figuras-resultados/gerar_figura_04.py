from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# ESP32-LLM Benchmark
# Figura 4 — taxonomia das falhas em tarefas difíceis
# ============================================================

BASE = Path(__file__).resolve().parent.parent

ARQUIVO = (
    BASE
    / "14-taxonomia-falhas"
    / "taxonomia_falhas_tarefas_dificeis.csv"
)

SAIDA = BASE / "16-figuras-resultados"
SAIDA.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# Leitura
# ------------------------------------------------------------

df = pd.read_csv(ARQUIVO)


# ------------------------------------------------------------
# Validação
# ------------------------------------------------------------

if len(df) != 30:
    raise ValueError(
        f"Esperadas 30 observações das tarefas difíceis; "
        f"encontradas {len(df)}."
    )


# ------------------------------------------------------------
# Seleção apenas das falhas com causa classificável
#
# PASS e INDETERMINADO não entram no cálculo percentual
# das causas E1/E2/E3.
# ------------------------------------------------------------

falhas = df[
    df["categoria_principal"].isin(
        ["E1", "E2", "E3"]
    )
].copy()

contagem = (
    falhas["categoria_principal"]
    .value_counts()
    .reindex(["E1", "E2", "E3"])
    .fillna(0)
    .astype(int)
)

total_classificavel = int(contagem.sum())

percentuais = (
    contagem
    / total_classificavel
    * 100
)


# ------------------------------------------------------------
# Rótulos
# ------------------------------------------------------------

rotulos = [
    "E1\nAPI/biblioteca\nincompatível",
    "E2\nImplementação\nausente/incompleta",
    "E3\nIncompatibilidade\ncontextual",
]


# ------------------------------------------------------------
# Figura
# ------------------------------------------------------------

fig, ax = plt.subplots(
    figsize=(7.5, 5)
)

barras = ax.bar(
    rotulos,
    percentuais.values,
)

for barra, quantidade, percentual in zip(
    barras,
    contagem.values,
    percentuais.values,
):
    ax.text(
        barra.get_x()
        + barra.get_width() / 2,
        percentual + 2,
        f"{quantidade}\n({percentual:.1f}%)",
        ha="center",
        va="bottom",
        fontsize=9,
    )


# ------------------------------------------------------------
# Formatação
# ------------------------------------------------------------

ax.set_title(
    "Distribuição das causas classificáveis de falha "
    "nas tarefas difíceis"
)

ax.set_ylabel(
    "Percentual das falhas classificáveis (%)"
)

ax.set_ylim(
    0,
    90
)

ax.grid(
    axis="y",
    linestyle="--",
    linewidth=0.5,
    alpha=0.4,
)

fig.tight_layout()


# ------------------------------------------------------------
# Exportação
# ------------------------------------------------------------

arquivo_png = (
    SAIDA
    / "figura_04_taxonomia_falhas_dificeis.png"
)

arquivo_pdf = (
    SAIDA
    / "figura_04_taxonomia_falhas_dificeis.pdf"
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

pass_count = (
    df["categoria_principal"] == "PASS"
).sum()

indeterminado_count = (
    df["categoria_principal"] == "INDETERMINADO"
).sum()

print("=" * 70)
print("FIGURA 4 GERADA")
print("=" * 70)

print("\nDistribuição das causas classificáveis:")

for categoria in ["E1", "E2", "E3"]:
    print(
        f"{categoria}: "
        f"{contagem[categoria]} "
        f"({percentuais[categoria]:.1f}%)"
    )

print(
    f"\nTotal de falhas com causa classificável: "
    f"{total_classificavel}"
)

print(
    f"PASS nas tarefas difíceis: "
    f"{pass_count}"
)

print(
    f"INDETERMINADO: "
    f"{indeterminado_count}"
)

print("\nPNG:")
print(arquivo_png)

print("\nPDF:")
print(arquivo_pdf)

print("\nOK.")