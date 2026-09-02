import csv
import random
from pathlib import Path

SEED = 20260901

ROOT = Path(__file__).resolve().parents[2]
RESPOSTAS_DIR = ROOT / "05-respostas-llms"
AVALIACAO_DIR = ROOT / "11-avaliacao"

MAPA_MODELOS = {
    "LLM01_GPT-5.6-Sol": {
        "gerador_id": "LLM01",
        "gerador": "GPT-5.6-Sol",
        "juizes": ["DeepSeek-V4-Pro", "Claude-Sonnet-5"],
    },
    "LLM02_DeepSeek-V4-Pro": {
        "gerador_id": "LLM02",
        "gerador": "DeepSeek-V4-Pro",
        "juizes": ["GPT-5.6-Sol", "Claude-Sonnet-5"],
    },
    "LLM03_Claude-Sonnet-5": {
        "gerador_id": "LLM03",
        "gerador": "Claude-Sonnet-5",
        "juizes": ["GPT-5.6-Sol", "DeepSeek-V4-Pro"],
    },
}

JUIZ_IDS = {
    "GPT-5.6-Sol": "J01",
    "DeepSeek-V4-Pro": "J02",
    "Claude-Sonnet-5": "J03",
}


def main():
    random.seed(SEED)

    solucoes = []

    for pasta_modelo, config in MAPA_MODELOS.items():
        base = RESPOSTAS_DIR / pasta_modelo

        if not base.exists():
            raise RuntimeError(f"Pasta não encontrada: {base}")

        for tarefa_dir in sorted(base.iterdir()):
            if not tarefa_dir.is_dir():
                continue

            if not tarefa_dir.name.startswith("T"):
                continue

            codigo = tarefa_dir / "codigo.cpp"
            prompt = tarefa_dir / "prompt.md"

            if not codigo.exists():
                raise RuntimeError(
                    f"Código ausente: {codigo}"
                )

            if not prompt.exists():
                raise RuntimeError(
                    f"Prompt ausente: {prompt}"
                )

            solucoes.append({
                "gerador_id": config["gerador_id"],
                "gerador": config["gerador"],
                "tarefa": tarefa_dir.name,
                "codigo_path": codigo,
                "prompt_path": prompt,
                "juizes": config["juizes"],
            })

    if len(solucoes) != 90:
        raise RuntimeError(
            f"Esperadas 90 soluções, encontradas {len(solucoes)}."
        )

    random.shuffle(solucoes)

    mapa_anonimo = []

    for i, solucao in enumerate(solucoes, start=1):
        anon_id = f"X{i:03d}"
        solucao["anon_id"] = anon_id

        mapa_anonimo.append({
            "anon_id": anon_id,
            "gerador_id": solucao["gerador_id"],
            "gerador": solucao["gerador"],
            "tarefa": solucao["tarefa"],
            "codigo_path": str(solucao["codigo_path"]),
            "prompt_path": str(solucao["prompt_path"]),
        })

    julgamentos = []

    for solucao in solucoes:
        for juiz in solucao["juizes"]:
            julgamentos.append({
                "anon_id": solucao["anon_id"],
                "tarefa": solucao["tarefa"],
                "juiz_id": JUIZ_IDS[juiz],
                "juiz": juiz,
            })

    if len(julgamentos) != 180:
        raise RuntimeError(
            f"Esperados 180 julgamentos, encontrados {len(julgamentos)}."
        )

    random.shuffle(julgamentos)

    mapa_path = AVALIACAO_DIR / "mapa_anonimizacao.csv"

    with mapa_path.open(
        "w",
        newline="",
        encoding="utf-8-sig"
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "anon_id",
                "gerador_id",
                "gerador",
                "tarefa",
                "codigo_path",
                "prompt_path",
            ],
        )

        writer.writeheader()
        writer.writerows(mapa_anonimo)

    matriz_path = AVALIACAO_DIR / "matriz_180_julgamentos.csv"

    with matriz_path.open(
        "w",
        newline="",
        encoding="utf-8-sig"
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "anon_id",
                "tarefa",
                "juiz_id",
                "juiz",
            ],
        )

        writer.writeheader()
        writer.writerows(julgamentos)

    print(f"Soluções encontradas: {len(solucoes)}")
    print(f"Julgamentos gerados: {len(julgamentos)}")
    print(f"Seed: {SEED}")
    print(f"Mapa: {mapa_path}")
    print(f"Matriz: {matriz_path}")


if __name__ == "__main__":
    main()