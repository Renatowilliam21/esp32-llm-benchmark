import argparse
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from dotenv import load_dotenv

PIPELINE_DIR = ROOT / "10-pipeline"

ENV_CANDIDATES = [
    ROOT / ".env",
    PIPELINE_DIR / ".env",
]

ENV_PATH = next(
    (path for path in ENV_CANDIDATES if path.exists()),
    None
)

if ENV_PATH is None:
    raise RuntimeError(
        "Arquivo .env não encontrado na raiz do projeto "
        "nem em 10-pipeline."
    )

load_dotenv(ENV_PATH)

PIPELINE_DIR = ROOT / "10-pipeline"
AVALIACAO_DIR = ROOT / "11-avaliacao"
PROMPTS_DIR = AVALIACAO_DIR / "prompts_julgamento"
JULGAMENTOS_DIR = AVALIACAO_DIR / "julgamentos"

# Permite reutilizar os providers da etapa de geração
sys.path.insert(0, str(PIPELINE_DIR))

from providers import build_provider


JUIZES = {
    "J01": {
        "provider": "openai",
        "nome": "GPT-5.6-Sol",
        "pasta": "J01_GPT-5.6-Sol",
    },
    "J02": {
        "provider": "deepseek",
        "nome": "DeepSeek-V4-Pro",
        "pasta": "J02_DeepSeek-V4-Pro",
    },
    "J03": {
        "provider": "anthropic",
        "nome": "Claude-Sonnet-5",
        "pasta": "J03_Claude-Sonnet-5",
    },
}


def extrair_json(texto: str) -> dict:
    """
    Valida a resposta do juiz.

    Não corrige valores nem conteúdo.
    Apenas remove espaços externos e tenta interpretar JSON.
    """

    texto = texto.strip()

    # Não fazemos reparo automático.
    try:
        data = json.loads(texto)
    except json.JSONDecodeError as exc:
        raise ValueError(
            f"Resposta não contém JSON válido: {exc}"
        )

    campos = [
        "R1",
        "R2",
        "R3",
        "R4",
        "R5",
        "total",
        "justificativa",
    ]

    for campo in campos:
        if campo not in data:
            raise ValueError(
                f"Campo obrigatório ausente: {campo}"
            )

    for campo in ["R1", "R2", "R3", "R4", "R5"]:
        valor = data[campo]

        if not isinstance(valor, int):
            raise ValueError(
                f"{campo} precisa ser inteiro."
            )

        if valor < 0 or valor > 2:
            raise ValueError(
                f"{campo} fora da faixa 0-2."
            )

    total_calculado = sum(
        data[campo]
        for campo in ["R1", "R2", "R3", "R4", "R5"]
    )

    if data["total"] != total_calculado:
        raise ValueError(
            f"Total inconsistente. "
            f"Recebido={data['total']} "
            f"Calculado={total_calculado}"
        )

    if not isinstance(data["justificativa"], str):
        raise ValueError(
            "justificativa precisa ser string."
        )

    return data


def executar(juiz_id: str, arquivo_prompt: Path):

    arquivo_prompt = arquivo_prompt.resolve()


    if juiz_id not in JUIZES:
        raise ValueError(
            f"Juiz inválido: {juiz_id}"
        )

    config = JUIZES[juiz_id]

    if not arquivo_prompt.exists():
        raise FileNotFoundError(
            f"Prompt não encontrado: {arquivo_prompt}"
        )

    nome_base = arquivo_prompt.stem

    pasta_saida = (
        JULGAMENTOS_DIR
        / config["pasta"]
        / nome_base
    )

    # Proteção metodológica:
    # julgamento oficial nunca deve ser sobrescrito.
    if pasta_saida.exists():
        raise RuntimeError(
            f"Julgamento já existe: {pasta_saida}"
        )

    pasta_saida.mkdir(
        parents=True,
        exist_ok=False
    )

    prompt = arquivo_prompt.read_text(
        encoding="utf-8"
    )

    (pasta_saida / "prompt.txt").write_text(
        prompt,
        encoding="utf-8"
    )

    provider = build_provider(
        config["provider"]
    )

    inicio = time.perf_counter()

    data_inicio = datetime.now(
        timezone.utc
    ).isoformat()

    resultado = provider.generate(prompt)

    duracao = time.perf_counter() - inicio

    data_fim = datetime.now(
        timezone.utc
    ).isoformat()

    resposta = resultado.text or ""

    (pasta_saida / "resposta_bruta.txt").write_text(
        resposta,
        encoding="utf-8"
    )

    status_json = "valido"
    erro_json = None
    avaliacao = None

    try:
        avaliacao = extrair_json(resposta)
    except Exception as exc:
        status_json = "invalido"
        erro_json = str(exc)

    if avaliacao is not None:
        with (
            pasta_saida / "avaliacao.json"
        ).open(
            "w",
            encoding="utf-8"
        ) as f:
            json.dump(
                avaliacao,
                f,
                ensure_ascii=False,
                indent=2,
            )

    metadata = {
        "juiz_id": juiz_id,
        "juiz_nome": config["nome"],
        "provider": config["provider"],
        "arquivo_prompt": str(
    	    arquivo_prompt.resolve().relative_to(ROOT.resolve())
        ),
        "model_requested": (
            resultado.model_requested
        ),
        "model_returned": (
            resultado.model_returned
        ),
        "stop_reason": (
            resultado.stop_reason
        ),
        "usage": (
            resultado.usage
        ),
        "raw_metadata": (
            resultado.raw_metadata
        ),
        "inicio_utc": data_inicio,
        "fim_utc": data_fim,
        "duracao_segundos": round(
            duracao,
            3
        ),
        "status_json": status_json,
        "erro_json": erro_json,
    }

    with (
        pasta_saida / "metadata.json"
    ).open(
        "w",
        encoding="utf-8"
    ) as f:
        json.dump(
            metadata,
            f,
            ensure_ascii=False,
            indent=2,
        )

    print()
    print("JULGAMENTO CONCLUÍDO")
    print("----------------------------")
    print(f"Juiz: {juiz_id}")
    print(f"Modelo: {config['nome']}")
    print(f"Prompt: {arquivo_prompt.name}")
    print(f"Duração: {duracao:.3f}s")
    print(f"JSON: {status_json}")

    if avaliacao:
        print(
            f"Nota: {avaliacao['total']}/10"
        )

    if erro_json:
        print(f"Erro JSON: {erro_json}")

    print(
        f"Saída: {pasta_saida}"
    )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Executor controlado de "
            "LLM-as-a-Judge"
        )
    )

    parser.add_argument(
        "--juiz",
        required=True,
        choices=[
            "J01",
            "J02",
            "J03",
        ],
    )

    parser.add_argument(
        "--prompt",
        required=True,
        type=Path,
    )

    args = parser.parse_args()

    executar(
        juiz_id=args.juiz,
        arquivo_prompt=args.prompt,
    )


if __name__ == "__main__":
    main()