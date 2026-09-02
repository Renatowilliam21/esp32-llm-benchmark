import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

AVALIACAO_DIR = ROOT / "11-avaliacao"
MAPA_PATH = AVALIACAO_DIR / "mapa_anonimizacao.csv"
MATRIZ_PATH = AVALIACAO_DIR / "matriz_180_julgamentos.csv"

RUBRICA_PATH = AVALIACAO_DIR / "rubrica_julgamento.md"

OUTPUT_DIR = AVALIACAO_DIR / "prompts_julgamento"

JUIZ_PASTAS = {
    "J01": OUTPUT_DIR / "J01",
    "J02": OUTPUT_DIR / "J02",
    "J03": OUTPUT_DIR / "J03",
}


def carregar_csv(path):
    with path.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:
        return list(csv.DictReader(f))


def carregar_texto(path):
    return path.read_text(encoding="utf-8")


def montar_prompt(
    anon_id,
    tarefa,
    prompt_original,
    codigo,
    rubrica,
):
    return f"""Você atua como juiz técnico independente em um experimento de avaliação de código para ESP32.

REGRAS DE JULGAMENTO

1. Avalie somente o material apresentado.
2. A identidade do modelo que gerou o código é desconhecida e irrelevante.
3. Não tente inferir qual modelo produziu a solução.
4. Não execute o código.
5. Não reescreva nem corrija a solução.
6. Não proponha código alternativo.
7. Não considere resultados externos de compilação ou testes.
8. Não considere avaliações anteriores.
9. Utilize exclusivamente a tarefa, o código candidato e a rubrica abaixo.
10. Faça o julgamento de forma independente.

IDENTIFICADOR ANÔNIMO

{anon_id}

TAREFA

{tarefa}

ESPECIFICAÇÃO ORIGINAL DA TAREFA

{prompt_original}

CÓDIGO CANDIDATO

{codigo}

RUBRICA DE AVALIAÇÃO

{rubrica}

FORMATO OBRIGATÓRIO DA RESPOSTA

Responda SOMENTE com JSON válido, sem Markdown e sem qualquer texto adicional.

Use exatamente esta estrutura:

{{
  "R1": 0,
  "R2": 0,
  "R3": 0,
  "R4": 0,
  "R5": 0,
  "total": 0,
  "justificativa": "texto curto"
}}

REGRAS DA SAÍDA

- R1 deve ser inteiro entre 0 e 2.
- R2 deve ser inteiro entre 0 e 2.
- R3 deve ser inteiro entre 0 e 2.
- R4 deve ser inteiro entre 0 e 2.
- R5 deve ser inteiro entre 0 e 2.
- total deve ser exatamente a soma de R1 + R2 + R3 + R4 + R5.
- justificativa deve conter no máximo 3 frases.
- Não inclua Markdown.
- Não inclua texto antes ou depois do JSON.
"""


def main():
    if not MAPA_PATH.exists():
        raise RuntimeError(
            f"Mapa de anonimização não encontrado: {MAPA_PATH}"
        )

    if not MATRIZ_PATH.exists():
        raise RuntimeError(
            f"Matriz de julgamentos não encontrada: {MATRIZ_PATH}"
        )

    if not RUBRICA_PATH.exists():
        raise RuntimeError(
            f"Rubrica não encontrada: {RUBRICA_PATH}"
        )

    mapa_rows = carregar_csv(MAPA_PATH)
    matriz_rows = carregar_csv(MATRIZ_PATH)

    mapa = {
        row["anon_id"]: row
        for row in mapa_rows
    }

    rubrica = carregar_texto(RUBRICA_PATH)

    for pasta in JUIZ_PASTAS.values():
        pasta.mkdir(parents=True, exist_ok=True)

    quantidade = {
        "J01": 0,
        "J02": 0,
        "J03": 0,
    }

    manifest = []

    for julgamento in matriz_rows:
        anon_id = julgamento["anon_id"]
        tarefa = julgamento["tarefa"]
        juiz_id = julgamento["juiz_id"]
        juiz = julgamento["juiz"]

        if anon_id not in mapa:
            raise RuntimeError(
                f"ID anônimo não encontrado no mapa: {anon_id}"
            )

        origem = mapa[anon_id]

        # Segurança metodológica adicional:
        # nenhum juiz pode avaliar código produzido pelo mesmo modelo.
        if origem["gerador"] == juiz:
            raise RuntimeError(
                f"Autoavaliação detectada: "
                f"{anon_id} / {juiz}"
            )

        prompt_path = Path(origem["prompt_path"])
        codigo_path = Path(origem["codigo_path"])

        if not prompt_path.exists():
            raise RuntimeError(
                f"Prompt original não encontrado: {prompt_path}"
            )

        if not codigo_path.exists():
            raise RuntimeError(
                f"Código candidato não encontrado: {codigo_path}"
            )

        prompt_original = carregar_texto(prompt_path)
        codigo = carregar_texto(codigo_path)

        prompt_final = montar_prompt(
            anon_id=anon_id,
            tarefa=tarefa,
            prompt_original=prompt_original,
            codigo=codigo,
            rubrica=rubrica,
        )

        nome_arquivo = (
            f"{juiz_id}_{anon_id}_{tarefa}.txt"
        )

        saida = (
            JUIZ_PASTAS[juiz_id]
            / nome_arquivo
        )

        saida.write_text(
            prompt_final,
            encoding="utf-8"
        )

        quantidade[juiz_id] += 1

        manifest.append({
            "anon_id": anon_id,
            "tarefa": tarefa,
            "juiz_id": juiz_id,
            "juiz": juiz,
            "arquivo_prompt": str(
                saida.relative_to(ROOT)
            ),
        })

    if len(manifest) != 180:
        raise RuntimeError(
            f"Esperados 180 prompts, gerados "
            f"{len(manifest)}."
        )

    manifest_path = (
        AVALIACAO_DIR
        / "manifest_prompts_julgamento.csv"
    )

    with manifest_path.open(
        "w",
        encoding="utf-8-sig",
        newline=""
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "anon_id",
                "tarefa",
                "juiz_id",
                "juiz",
                "arquivo_prompt",
            ],
        )

        writer.writeheader()
        writer.writerows(manifest)

    print()
    print("PROMPTS DE JULGAMENTO GERADOS")
    print("--------------------------------")
    print(
        f"J01: {quantidade['J01']}"
    )
    print(
        f"J02: {quantidade['J02']}"
    )
    print(
        f"J03: {quantidade['J03']}"
    )
    print("--------------------------------")
    print(
        f"Total: {len(manifest)}"
    )
    print()
    print(
        f"Manifesto: {manifest_path}"
    )


if __name__ == "__main__":
    main()