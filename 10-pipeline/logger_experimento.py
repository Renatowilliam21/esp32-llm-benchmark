import csv
from pathlib import Path

FIELDS = [
    "execucao_id", "tarefa", "nivel", "provedor", "llm_id",
    "modelo_solicitado", "modelo_retornado", "data_hora_utc",
    "duracao_s", "status", "stop_reason", "input_tokens",
    "output_tokens", "total_tokens", "codigo_extraido",
    "resposta_vazia", "erro", "pasta_saida"
]

def append_log(path: Path, row: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    exists = path.exists()
    with path.open("a", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, delimiter=";")
        if not exists:
            w.writeheader()
        w.writerow({k: row.get(k, "") for k in FIELDS})
