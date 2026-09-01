import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

from config import PROVIDERS
from providers import build_provider
from extrator_codigo import extrair_codigo

load_dotenv()

HERE = Path(__file__).resolve().parent
PROMPT = (HERE / "piloto" / "prompt_piloto.md").read_text(encoding="utf-8")
OUT = HERE / "piloto" / "resultados"
OUT.mkdir(parents=True, exist_ok=True)


def executar_piloto(provider_name: str):
    cfg = PROVIDERS[provider_name]
    target = OUT / f"{cfg.id}_{cfg.name}"

    if target.exists():
        raise RuntimeError(
            f"O piloto para {provider_name} já existe em {target}. "
            "Remova somente essa pasta se quiser repetir conscientemente o piloto."
        )

    target.mkdir(parents=True)

    started = datetime.now(timezone.utc)
    t0 = time.perf_counter()

    try:
        result = build_provider(provider_name).generate(PROMPT)
        status = "sucesso"
        error = None
        raw = result.text
    except Exception as exc:
        status = "erro"
        error = f"{type(exc).__name__}: {exc}"
        raw = ""
        result = None

    duration = time.perf_counter() - t0

    code, extraction = (
        extrair_codigo(raw)
        if raw
        else ("", {"metodo": "sem_resposta"})
    )

    (target / "prompt.md").write_text(PROMPT, encoding="utf-8")
    (target / "resposta_bruta.txt").write_text(raw, encoding="utf-8")
    (target / "codigo.cpp").write_text(code, encoding="utf-8")

    metadata = {
        "piloto": True,
        "provedor": provider_name,
        "modelo_solicitado": cfg.model,
        "modelo_retornado": result.model_returned if result else None,
        "inicio_utc": started.isoformat(),
        "duracao_s": round(duration, 6),
        "status": status,
        "usage": result.usage if result else {},
        "stop_reason": result.stop_reason if result else None,
        "extracao": extraction,
        "erro": error,
    }

    (target / "metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(provider_name, status, round(duration, 3), "s")


def main():
    parser = argparse.ArgumentParser(
        description="Executa o piloto técnico de um ou mais provedores."
    )

    parser.add_argument(
        "--provider",
        choices=["openai", "deepseek", "anthropic", "all"],
        default="all",
    )

    args = parser.parse_args()

    if args.provider == "all":
        providers = ["openai", "deepseek", "anthropic"]
    else:
        providers = [args.provider]

    for provider_name in providers:
        executar_piloto(provider_name)


if __name__ == "__main__":
    main()