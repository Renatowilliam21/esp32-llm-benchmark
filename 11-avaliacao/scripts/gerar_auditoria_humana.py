import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

AVALIACAO = ROOT / "11-avaliacao"
AUDITORIA = AVALIACAO / "auditoria"
PROMPTS = AVALIACAO / "prompts_julgamento"
MAPA = AVALIACAO / "mapa_anonimizacao.csv"
CASOS = AUDITORIA / "casos_para_auditoria.csv"

SAIDA = AUDITORIA / "fichas_cegas"
SAIDA.mkdir(parents=True, exist_ok=True)


def localizar_prompt(anon_id, tarefa):
    candidatos = list(
        PROMPTS.glob(
            f"J*/J*_{anon_id}_{tarefa}.txt"
        )
    )

    if not candidatos:
        raise RuntimeError(
            f"Prompt não encontrado para "
            f"{anon_id}/{tarefa}"
        )

    return candidatos[0]


def main():

    with CASOS.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:
        casos = list(csv.DictReader(f))

    print(f"Casos encontrados: {len(casos)}")

    for caso in casos:

        anon_id = caso["anon_id"]
        tarefa = caso["tarefa"]

        prompt = localizar_prompt(
            anon_id,
            tarefa
        )

        conteudo = prompt.read_text(
            encoding="utf-8"
        )

        # Remove a parte destinada ao juiz,
        # se houver identificação explícita.
        linhas = conteudo.splitlines()

        filtradas = []

        for linha in linhas:

            lower = linha.lower()

            if "gerador" in lower:
                continue

            if "llm01" in lower:
                continue

            if "llm02" in lower:
                continue

            if "llm03" in lower:
                continue

            filtradas.append(linha)

        ficha = "\n".join(filtradas)

        ficha += """

==================================================
AUDITORIA HUMANA
==================================================

Avalie o código utilizando os mesmos critérios
aplicados aos juízes LLM.

R1 — Contrato e assinatura
0 = não atende
1 = atende parcialmente
2 = atende completamente

R2 — Requisitos explícitos
0 = não atende
1 = atende parcialmente
2 = atende completamente

R3 — Uso coerente das dependências
0 = inadequado
1 = parcialmente adequado
2 = adequado

R4 — Ausência de comportamento incompatível
0 = incompatibilidades graves
1 = incompatibilidades menores
2 = sem incompatibilidades relevantes

R5 — Adequação ao contexto ESP32/embarcado
0 = inadequado
1 = parcialmente adequado
2 = adequado

Preencha:

R1 =
R2 =
R3 =
R4 =
R5 =

TOTAL =

JUSTIFICATIVA =
"""

        destino = (
            SAIDA /
            f"{anon_id}_{tarefa}_auditoria.txt"
        )

        destino.write_text(
            ficha,
            encoding="utf-8"
        )

        print(
            f"Criada: {destino.name}"
        )

    print()
    print(
        f"Fichas disponíveis em: {SAIDA}"
    )


if __name__ == "__main__":
    main()