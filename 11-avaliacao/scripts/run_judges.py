import argparse
import csv
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
AVALIACAO_DIR = ROOT / "11-avaliacao"

MANIFEST_PATH = (
    AVALIACAO_DIR / "manifest_prompts_julgamento.csv"
)

JUDGE_RUNNER = (
    AVALIACAO_DIR / "scripts" / "judge_runner.py"
)

LOG_PATH = (
    AVALIACAO_DIR / "log_execucao_julgamentos.csv"
)

JULGAMENTOS_DIR = (
    AVALIACAO_DIR / "julgamentos"
)


JUIZES = {
    "J01": {
        "pasta": "J01_GPT-5.6-Sol",
    },
    "J02": {
        "pasta": "J02_DeepSeek-V4-Pro",
    },
    "J03": {
        "pasta": "J03_Claude-Sonnet-5",
    },
}


def carregar_manifest():
    if not MANIFEST_PATH.exists():
        raise RuntimeError(
            f"Manifesto não encontrado: {MANIFEST_PATH}"
        )

    with MANIFEST_PATH.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:
        return list(csv.DictReader(f))


def registrar_log(
    juiz,
    anon_id,
    tarefa,
    prompt,
    status,
    duracao,
    mensagem=""
):
    existe = LOG_PATH.exists()

    with LOG_PATH.open(
        "a",
        encoding="utf-8-sig",
        newline=""
    ) as f:

        campos = [
            "timestamp",
            "juiz",
            "anon_id",
            "tarefa",
            "prompt",
            "status",
            "duracao_segundos",
            "mensagem",
        ]

        writer = csv.DictWriter(
            f,
            fieldnames=campos
        )

        if not existe:
            writer.writeheader()

        writer.writerow({
            "timestamp": datetime.now().isoformat(),
            "juiz": juiz,
            "anon_id": anon_id,
            "tarefa": tarefa,
            "prompt": prompt,
            "status": status,
            "duracao_segundos": round(
                duracao, 3
            ),
            "mensagem": mensagem,
        })


def pasta_resultado(juiz, prompt_path):
    nome = Path(prompt_path).stem

    return (
        JULGAMENTOS_DIR
        / JUIZES[juiz]["pasta"]
        / nome
    )


def julgamento_completo(pasta):
    """
    Um julgamento é considerado completo somente
    quando os quatro artefatos existem.
    """

    obrigatorios = [
        "prompt.txt",
        "resposta_bruta.txt",
        "avaliacao.json",
        "metadata.json",
    ]

    return all(
        (pasta / arquivo).exists()
        for arquivo in obrigatorios
    )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Executor oficial dos julgamentos "
            "LLM-as-a-Judge"
        )
    )

    parser.add_argument(
        "--juiz",
        required=True,
        choices=["J01", "J02", "J03"],
    )

    parser.add_argument(
        "--pausa",
        type=float,
        default=1.0,
        help=(
            "Pausa em segundos entre chamadas. "
            "Padrão: 1.0"
        ),
    )

    parser.add_argument(
        "--limite",
        type=int,
        default=None,
        help=(
            "Executa no máximo N novos julgamentos. "
            "Útil para validação controlada."
        ),
    )

    args = parser.parse_args()

    manifest = carregar_manifest()

    itens = [
        row
        for row in manifest
        if row["juiz_id"] == args.juiz
    ]

    if len(itens) != 60:
        raise RuntimeError(
            f"{args.juiz}: esperados 60 prompts, "
            f"encontrados {len(itens)}."
        )

    print()
    print("EXECUÇÃO DE JULGAMENTOS")
    print("==============================")
    print(f"Juiz: {args.juiz}")
    print(f"Prompts no manifesto: {len(itens)}")
    print(f"Pausa: {args.pausa}s")

    if args.limite is not None:
        print(
            f"Limite de novos julgamentos: "
            f"{args.limite}"
        )

    print("==============================")
    print()

    novos = 0
    ignorados = 0
    erros = 0

    for indice, row in enumerate(
        itens,
        start=1
    ):
        anon_id = row["anon_id"]
        tarefa = row["tarefa"]

        prompt_path = (
            ROOT / row["arquivo_prompt"]
        ).resolve()

        saida = pasta_resultado(
            args.juiz,
            prompt_path
        )

        print(
            f"[{indice:02d}/60] "
            f"{anon_id} / {tarefa}"
        )

        if julgamento_completo(saida):
            print("  -> já concluído; ignorando.")
            ignorados += 1
            continue

        # Proteção importante:
        # uma pasta incompleta não é sobrescrita.
        if saida.exists():
            print(
                "  -> ATENÇÃO: existe resultado "
                "incompleto."
            )

            registrar_log(
                juiz=args.juiz,
                anon_id=anon_id,
                tarefa=tarefa,
                prompt=str(
                    prompt_path.relative_to(ROOT)
                ),
                status="INCOMPLETO_EXISTENTE",
                duracao=0,
                mensagem=(
                    "Pasta existente não foi "
                    "sobrescrita."
                ),
            )

            erros += 1
            continue

        if (
            args.limite is not None
            and novos >= args.limite
        ):
            print()
            print(
                "Limite solicitado atingido."
            )
            break

        inicio = time.perf_counter()

        comando = [
            sys.executable,
            str(JUDGE_RUNNER),
            "--juiz",
            args.juiz,
            "--prompt",
            str(prompt_path),
        ]

        resultado = subprocess.run(
            comando,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )

        duracao = (
            time.perf_counter() - inicio
        )

        if resultado.returncode == 0:
            print(
                f"  -> concluído em "
                f"{duracao:.2f}s"
            )

            registrar_log(
                juiz=args.juiz,
                anon_id=anon_id,
                tarefa=tarefa,
                prompt=str(
                    prompt_path.relative_to(ROOT)
                ),
                status="SUCESSO",
                duracao=duracao,
            )

            novos += 1

        else:
            print("  -> ERRO")

            erro = (
                resultado.stderr.strip()
                or resultado.stdout.strip()
            )

            print(erro[:500])

            registrar_log(
                juiz=args.juiz,
                anon_id=anon_id,
                tarefa=tarefa,
                prompt=str(
                    prompt_path.relative_to(ROOT)
                ),
                status="ERRO",
                duracao=duracao,
                mensagem=erro[:2000],
            )

            erros += 1

        if args.pausa > 0:
            time.sleep(args.pausa)

    print()
    print("==============================")
    print("RESUMO")
    print("==============================")
    print(f"Novos concluídos: {novos}")
    print(f"Já existentes:    {ignorados}")
    print(f"Erros/incompletos:{erros}")
    print("==============================")


if __name__ == "__main__":
    main()