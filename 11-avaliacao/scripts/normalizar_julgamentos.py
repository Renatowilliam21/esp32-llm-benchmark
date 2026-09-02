import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

JULGAMENTOS_DIR = (
    ROOT / "11-avaliacao" / "julgamentos"
)


def validar_avaliacao(data):
    campos = [
        "R1",
        "R2",
        "R3",
        "R4",
        "R5",
        "total",
        "justificativa",
    ]

    if not isinstance(data, dict):
        raise ValueError("O conteúdo não é um objeto JSON.")

    for campo in campos:
        if campo not in data:
            raise ValueError(
                f"Campo obrigatório ausente: {campo}"
            )

    for campo in ["R1", "R2", "R3", "R4", "R5"]:

        valor = data[campo]

        if not isinstance(valor, int):
            raise ValueError(
                f"{campo} não é inteiro."
            )

        if valor < 0 or valor > 2:
            raise ValueError(
                f"{campo} fora da faixa 0-2."
            )

    total_calculado = sum(
        data[c]
        for c in ["R1", "R2", "R3", "R4", "R5"]
    )

    if data["total"] != total_calculado:
        raise ValueError(
            f"Total inconsistente: "
            f"{data['total']} != {total_calculado}"
        )

    if not isinstance(
        data["justificativa"],
        str
    ):
        raise ValueError(
            "justificativa não é string."
        )

    return data


def extrair(texto):
    """
    Extração exclusivamente sintática.

    Não modifica:
    - R1-R5
    - total
    - justificativa
    - conteúdo semântico
    """

    texto = texto.strip()

    if not texto:
        return None, "RESPOSTA_VAZIA"

    # Caso 1: JSON puro
    try:
        data = json.loads(texto)

        validar_avaliacao(data)

        return data, "JSON_DIRETO"

    except (json.JSONDecodeError, ValueError):
        pass

    # Caso 2: bloco Markdown ```json ... ```
    if texto.startswith("```"):

        linhas = texto.splitlines()

        if len(linhas) >= 3:

            primeira = linhas[0].strip().lower()
            ultima = linhas[-1].strip()

            if (
                primeira in ("```", "```json")
                and ultima == "```"
            ):

                interno = "\n".join(
                    linhas[1:-1]
                ).strip()

                try:
                    data = json.loads(interno)

                    validar_avaliacao(data)

                    return (
                        data,
                        "JSON_BLOCO_MARKDOWN"
                    )

                except (
                    json.JSONDecodeError,
                    ValueError
                ) as exc:

                    return (
                        None,
                        f"BLOCO_INVALIDO: {exc}"
                    )

    return None, "FORMATO_NAO_RECONHECIDO"


def main():

    total = 0
    extraidos = 0
    diretos = 0
    markdown = 0
    vazios = 0
    outros_erros = 0

    casos_problematicos = []

    for pasta_juiz in sorted(
        JULGAMENTOS_DIR.iterdir()
    ):

        if not pasta_juiz.is_dir():
            continue

        for pasta in sorted(
            pasta_juiz.iterdir()
        ):

            if not pasta.is_dir():
                continue

            if pasta.name == "piloto_juiz":
                continue

            resposta_path = (
                pasta / "resposta_bruta.txt"
            )

            if not resposta_path.exists():
                casos_problematicos.append({
                    "caso": pasta.name,
                    "status": "SEM_RESPOSTA_BRUTA",
                })

                outros_erros += 1
                continue

            total += 1

            texto = resposta_path.read_text(
                encoding="utf-8"
            )

            avaliacao, status = extrair(texto)

            metadata_extracao = {
                "status_extracao": status,
                "normalizacao_semantica": False,
                "resposta_original_preservada": True,
            }

            if avaliacao is not None:

                saida = (
                    pasta /
                    "avaliacao_extraida.json"
                )

                with saida.open(
                    "w",
                    encoding="utf-8"
                ) as f:

                    json.dump(
                        avaliacao,
                        f,
                        ensure_ascii=False,
                        indent=2,
                    )

                extraidos += 1

                if status == "JSON_DIRETO":
                    diretos += 1

                elif status == "JSON_BLOCO_MARKDOWN":
                    markdown += 1

            else:

                if status == "RESPOSTA_VAZIA":
                    vazios += 1
                else:
                    outros_erros += 1

                casos_problematicos.append({
                    "caso": pasta.name,
                    "status": status,
                })

            with (
                pasta /
                "extracao_metadata.json"
            ).open(
                "w",
                encoding="utf-8"
            ) as f:

                json.dump(
                    metadata_extracao,
                    f,
                    ensure_ascii=False,
                    indent=2,
                )

    print()
    print("==============================")
    print("NORMALIZAÇÃO DOS JULGAMENTOS")
    print("==============================")
    print(f"Respostas analisadas: {total}")
    print(f"Avaliações extraídas: {extraidos}")
    print(f"JSON direto:          {diretos}")
    print(f"Bloco Markdown:       {markdown}")
    print(f"Respostas vazias:     {vazios}")
    print(f"Outros erros:         {outros_erros}")
    print("==============================")

    if casos_problematicos:
        print()
        print("CASOS SEM AVALIAÇÃO UTILIZÁVEL")

        for caso in casos_problematicos:
            print(
                f"{caso['caso']}: "
                f"{caso['status']}"
            )


if __name__ == "__main__":
    main()