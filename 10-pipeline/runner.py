import argparse
import json
import os
import shutil
import time
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv

from config import PROVIDERS, PROMPTS_DIR, OUTPUT_DIR, RESULTS_DIR
from providers import build_provider
from extrator_codigo import extrair_codigo
from logger_experimento import append_log

load_dotenv()

def nivel_por_tarefa(task_id: str) -> str:
    n = int(task_id[1:])
    if n <= 10:
        return "Fácil"
    if n <= 20:
        return "Média"
    return "Difícil"

def localizar_prompt(task_id: str) -> Path:
    matches = sorted(PROMPTS_DIR.glob(f"{task_id}_*.md"))
    if len(matches) != 1:
        raise RuntimeError(
            f"Esperado exatamente 1 prompt para {task_id}; encontrados {len(matches)}."
        )
    return matches[0]

def executar(provedor_nome: str, task_id: str, force: bool = False):
    cfg = PROVIDERS[provedor_nome]
    prompt_path = localizar_prompt(task_id)
    prompt = prompt_path.read_text(encoding="utf-8")

    out_dir = OUTPUT_DIR / f"{cfg.id}_{cfg.name}" / task_id
    if out_dir.exists() and any(out_dir.iterdir()) and not force:
        raise RuntimeError(
            f"{out_dir} já contém dados. Use --force somente se a execução NÃO for oficial."
        )
    out_dir.mkdir(parents=True, exist_ok=True)

    shutil.copy2(prompt_path, out_dir / "prompt.md")

    started = datetime.now(timezone.utc)
    t0 = time.perf_counter()
    status = "erro"
    error_text = ""
    raw = ""
    result = None

    try:
        provider = build_provider(provedor_nome)
        result = provider.generate(prompt)
        raw = result.text
        status = "sucesso"
    except Exception as e:
        error_text = f"{type(e).__name__}: {e}"
    duration = time.perf_counter() - t0
    ended = datetime.now(timezone.utc)

    (out_dir / "resposta_bruta.txt").write_text(raw, encoding="utf-8")

    code, extraction = extrair_codigo(raw) if raw else ("", {
        "metodo": "sem_resposta",
        "quantidade_blocos": 0,
        "alteracao_semantica": False,
    })
    (out_dir / "codigo.cpp").write_text(code, encoding="utf-8")

    metadata = {
        "execucao_id": f"{cfg.id}-{task_id}",
        "tarefa": task_id,
        "nivel": nivel_por_tarefa(task_id),
        "provedor": provedor_nome,
        "llm_id": cfg.id,
        "modelo_solicitado": cfg.model,
        "modelo_retornado": result.model_returned if result else None,
        "inicio_utc": started.isoformat(),
        "fim_utc": ended.isoformat(),
        "duracao_s": round(duration, 6),
        "status": status,
        "stop_reason": result.stop_reason if result else None,
        "usage": result.usage if result else {},
        "raw_metadata": result.raw_metadata if result else {},
        "extracao": extraction,
        "resposta_vazia": raw.strip() == "",
        "erro": error_text or None,
        "prompt_arquivo": prompt_path.name,
    }
    (out_dir / "metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    usage = result.usage if result else {}
    append_log(
        RESULTS_DIR / "registro_execucoes.csv",
        {
            "execucao_id": metadata["execucao_id"],
            "tarefa": task_id,
            "nivel": metadata["nivel"],
            "provedor": provedor_nome,
            "llm_id": cfg.id,
            "modelo_solicitado": cfg.model,
            "modelo_retornado": metadata["modelo_retornado"],
            "data_hora_utc": started.isoformat(),
            "duracao_s": round(duration, 6),
            "status": status,
            "stop_reason": metadata["stop_reason"],
            "input_tokens": usage.get("input_tokens", ""),
            "output_tokens": usage.get("output_tokens", ""),
            "total_tokens": usage.get("total_tokens", ""),
            "codigo_extraido": bool(code.strip()),
            "resposta_vazia": metadata["resposta_vazia"],
            "erro": error_text,
            "pasta_saida": str(out_dir),
        }
    )

    print(json.dumps(metadata, ensure_ascii=False, indent=2))

def main():
    p = argparse.ArgumentParser(description="Executor do benchmark ESP32 × LLMs")
    p.add_argument("--provider", choices=sorted(PROVIDERS), required=True)
    p.add_argument("--task", required=True, help="Ex.: T01")
    p.add_argument("--force", action="store_true",
                   help="Sobrescreve pasta existente. NÃO usar na coleta oficial.")
    args = p.parse_args()
    executar(args.provider, args.task.upper(), args.force)

if __name__ == "__main__":
    main()
