from pathlib import Path
import pandas as pd


# ============================================================
# ESP32-LLM Benchmark
# Geração das tabelas finais de resultados
# ============================================================

BASE = Path(__file__).resolve().parent.parent

PASTA_EST = BASE / "13-analise-estatistica" / "saida"
SAIDA = BASE / "17-tabelas-resultados"
SAIDA.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# Arquivos de entrada
# ------------------------------------------------------------

ARQ_COCHRAN = PASTA_EST / "cochran_compilacao.csv"
ARQ_FRIEDMAN = PASTA_EST / "friedman_funcional.csv"
ARQ_KRUSKAL = PASTA_EST / "kruskal_dificuldade.csv"
ARQ_POSTHOC = PASTA_EST / "posthoc_dificuldade_holm.csv"
ARQ_EFEITO = PASTA_EST / "tamanhos_efeito_rank_biserial.csv"


# ------------------------------------------------------------
# Leitura
# ------------------------------------------------------------

cochran = pd.read_csv(ARQ_COCHRAN)
friedman = pd.read_csv(ARQ_FRIEDMAN)
kruskal = pd.read_csv(ARQ_KRUSKAL)
posthoc = pd.read_csv(ARQ_POSTHOC)
efeito = pd.read_csv(ARQ_EFEITO)


# ------------------------------------------------------------
# Diagnóstico inicial
# ------------------------------------------------------------

print("=" * 70)
print("GERAÃ‡ÃƒO DAS TABELAS DE RESULTADOS")
print("=" * 70)

print("\nArquivos lidos:")
print(f"Cochran:   {len(cochran)} linha(s)")
print(f"Friedman:  {len(friedman)} linha(s)")
print(f"Kruskal:   {len(kruskal)} linha(s)")
print(f"Post-hoc:  {len(posthoc)} linha(s)")
print(f"Efeito:    {len(efeito)} linha(s)")


# ------------------------------------------------------------
# TABELA 1
# Síntese dos testes estatísticos principais
# ------------------------------------------------------------

linhas = []

# Cochran
for _, r in cochran.iterrows():
    linhas.append({
        "analise": "Compilação entre LLMs",
        "teste": "Cochran Q",
        "escopo": str(r.get("escopo", "Global")),
        "estatistica": float(r["Q"]),
        "gl": int(r.get("gl", 2)),
        "p_valor": float(r["p"]),
    })

# Friedman
for _, r in friedman.iterrows():
    linhas.append({
        "analise": "Funcionalidade entre LLMs",
        "teste": "Friedman",
        "escopo": str(r.get("escopo", "Global")),
        "estatistica": float(r["chi2"]),
        "gl": int(r.get("gl", 2)),
        "p_valor": float(r["p"]),
    })

# Kruskal-Wallis
for _, r in kruskal.iterrows():
    linhas.append({
        "analise": "Efeito da dificuldade",
        "teste": "Kruskal-Wallis",
        "escopo": str(r["modelo"]),
        "estatistica": float(r["H"]),
        "gl": int(r.get("gl", 2)),
        "p_valor": float(r["p"]),
    })

tabela1 = pd.DataFrame(linhas)

tabela1["significativo_0_05"] = tabela1["p_valor"] < 0.05


# ------------------------------------------------------------
# Formatação amigável
# ------------------------------------------------------------

def formatar_p(p):
    if p < 0.001:
        return "< 0,001"
    return f"{p:.4f}".replace(".", ",")


def formatar_estatistica(x):
    return f"{x:.4f}".replace(".", ",")


tabela1_fmt = tabela1.copy()

tabela1_fmt["estatistica"] = (
    tabela1_fmt["estatistica"]
    .apply(formatar_estatistica)
)

tabela1_fmt["p_valor"] = (
    tabela1_fmt["p_valor"]
    .apply(formatar_p)
)

tabela1_fmt["significativo_0_05"] = (
    tabela1_fmt["significativo_0_05"]
    .map({
        True: "Sim",
        False: "Não",
    })
)


# ------------------------------------------------------------
# TABELA 2
# Pós-hoc da dificuldade
# ------------------------------------------------------------

tabela2 = posthoc.copy()

# tenta localizar automaticamente colunas usuais
for coluna in tabela2.columns:
    if "p_holm" in coluna.lower():
        tabela2[coluna] = pd.to_numeric(
            tabela2[coluna],
            errors="coerce"
        )

    elif coluna.lower() in ["p_valor", "p", "p_bruto"]:
        tabela2[coluna] = pd.to_numeric(
            tabela2[coluna],
            errors="coerce"
        )


# ------------------------------------------------------------
# TABELA 3
# Tamanhos de efeito
# ------------------------------------------------------------

tabela3 = efeito.copy()


# ------------------------------------------------------------
# Exportação CSV
# ------------------------------------------------------------

tabela1.to_csv(
    SAIDA / "tabela_01_testes_estatisticos.csv",
    index=False,
)

tabela1_fmt.to_csv(
    SAIDA / "tabela_01_testes_estatisticos_formatada.csv",
    index=False,
)

tabela2.to_csv(
    SAIDA / "tabela_02_posthoc_dificuldade.csv",
    index=False,
)

tabela3.to_csv(
    SAIDA / "tabela_03_tamanhos_efeito.csv",
    index=False,
)


# ------------------------------------------------------------
# LaTeX
# ------------------------------------------------------------

latex1 = tabela1_fmt.to_latex(
    index=False,
    escape=True,
    caption=(
        "Síntese dos testes estatísticos aplicados "
        "aos resultados do benchmark."
    ),
    label="tab:testes_estatisticos",
)

latex2 = tabela2.to_latex(
    index=False,
    escape=True,
    caption=(
        "Comparações pós-hoc entre os níveis de dificuldade "
        "com correção de Holm."
    ),
    label="tab:posthoc_dificuldade",
)

latex3 = tabela3.to_latex(
    index=False,
    escape=True,
    caption=(
        "Tamanhos de efeito para as comparações entre "
        "níveis de dificuldade."
    ),
    label="tab:tamanhos_efeito",
)


with open(
    SAIDA / "tabela_01_testes_estatisticos.tex",
    "w",
    encoding="utf-8",
) as f:
    f.write(latex1)

with open(
    SAIDA / "tabela_02_posthoc_dificuldade.tex",
    "w",
    encoding="utf-8",
) as f:
    f.write(latex2)

with open(
    SAIDA / "tabela_03_tamanhos_efeito.tex",
    "w",
    encoding="utf-8",
) as f:
    f.write(latex3)


# ------------------------------------------------------------
# Saída no terminal
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("TABELA 1 â€” TESTES ESTATÃSTICOS")
print("=" * 70)

print(
    tabela1_fmt.to_string(
        index=False
    )
)

print("\n" + "=" * 70)
print("TABELA 2 â€” PÃ“S-HOC")
print("=" * 70)

print(
    tabela2.to_string(
        index=False
    )
)

print("\n" + "=" * 70)
print("TABELA 3 â€” TAMANHOS DE EFEITO")
print("=" * 70)

print(
    tabela3.to_string(
        index=False
    )
)

print("\nArquivos gerados em:")
print(SAIDA)

print("\nOK.")

