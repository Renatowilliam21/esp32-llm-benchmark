"""
NÃO execute este arquivo antes do piloto e do congelamento do protocolo.
Executa as 90 unidades experimentais em ordem T01..T30.
"""
import subprocess
import sys

PROVIDERS = ["openai", "deepseek", "anthropic"]
TASKS = [f"T{i:02d}" for i in range(1, 31)]

for provider in PROVIDERS:
    for task in TASKS:
        print(f"\n=== {provider} / {task} ===")
        completed = subprocess.run(
            [sys.executable, "runner.py", "--provider", provider, "--task", task],
            check=False,
        )
        if completed.returncode != 0:
            print(f"Falha operacional em {provider}/{task}. Interrompendo.")
            raise SystemExit(completed.returncode)
