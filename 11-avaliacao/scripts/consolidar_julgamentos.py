import csv
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

AVALIACAO_DIR = ROOT / "11-avaliacao"
JULGAMENTOS_DIR = AVALIACAO_DIR / "julgamentos"

MAPA_PATH = AVALIACAO_DIR / "mapa_anonimizacao.csv"

SAIDA_CONSOLIDADA = (
    AVALIACAO_DIR / "resultados_julgamento_consolidados.csv"
)

SAIDA_AUDITORIA = (
    AVALIACAO_DIR / "auditoria" / "casos_para_auditoria.csv"
)

JUIZES = {
    "J01": {
        "nome": "GPT-5.6-Sol",
        "pasta": "J01_GPT-5.6-Sol",
    },
    "J02": {
        "nome": "DeepSeek-V4-Pro",
        "pasta": "J02_DeepSeek-V4-Pro",
    },
    "J03": {
        "nome": "Claude-Sonnet-5",
        "pasta": "J03_Claude-Sonnet-5",
    },
}


def carregar_mapa():
    with MAPA_PATH.open(
        "r",
        encoding="utf-8-sig",
        newline=""
    ) as f:
        return {
            row["anon_id"]: row
            for row in csv.DictReader(f)
        }


def carregar_avaliacoes():

    registros = []

    for juiz_id, config in JUIZES.items():

        pasta_juiz = JULGAMENTOS_DIR / config["pasta"]

        for pasta in pasta_juiz.iterdir():

            if not pasta.is_dir():
                continue

            if pasta.name == "piloto_juiz":
                continue

            avaliacao_path = (
                pasta / "avaliacao_extraida.json"
            )

            if not avaliacao_path.exists():
                continue

            with avaliacao_path.open(
                "r",
                encoding="utf-8"
            ) as f:
                avaliacao = json.load(f)

            partes = pasta.name.split("_")

            anon_id = partes[1]
            tarefa = partes[2]

            registros.append({
                "anon_id": anon_id,
                "tarefa": tarefa,
                "juiz_id": juiz_id,
                "juiz": config["nome"],
                "R1": avaliacao["R1"],
                "R2": avaliacao["R2"],
                "R3": avaliacao["R3"],
                "R4": avaliacao["R4"],
                "R5": avaliacao["R5"],
                "total": avaliacao["total"],
                "justificativa":
                    avaliacao["justificativa"],
            })

    return registros


def main():

    mapa = carregar_mapa()
    avaliacoes = carregar_avaliacoes()

    print()
    print(
        f"Julgamentos recuperáveis encontrados: "
        f"{len(avaliacoes)}"
    )

    if len(avaliacoes) != 177:
        raise RuntimeError(
            f"Esperados 177 julgamentos, "
            f"encontrados {len(avaliacoes)}."
        )

    por_solucao = defaultdict(list)

    for avaliacao in avaliacoes:
        por_solucao[
            avaliacao["anon_id"]
        ].append(avaliacao)

    # Inclui também soluções com julgamento ausente
    for anon_id in mapa:
        por_solucao.setdefault(
            anon_id,
            []
        )

    if len(por_solucao) != 90:
        raise RuntimeError(
            f"Esperadas 90 soluções, "
            f"encontradas {len(por_solucao)}."
        )

    consolidados = []
    auditoria = []

    for anon_id in sorted(por_solucao):

        julgamentos = por_solucao[anon_id]

        origem = mapa[anon_id]

        if len(julgamentos) == 2:

            j1, j2 = julgamentos

            nota1 = j1["total"]
            nota2 = j2["total"]

            media = (
                nota1 + nota2
            ) / 2

            diferenca = abs(
                nota1 - nota2
            )

            if diferenca >= 4:
                auditoria_humana = "SIM"
                motivo = "DISCORDANCIA_LLM"
            else:
                auditoria_humana = "NAO"
                motivo = ""

            linha = {
                "anon_id": anon_id,
                "tarefa": origem["tarefa"],
                "gerador_id": origem["gerador_id"],
                "gerador": origem["gerador"],

                "juiz_1": j1["juiz"],
                "nota_juiz_1": nota1,

                "juiz_2": j2["juiz"],
                "nota_juiz_2": nota2,

                "media_qualitativa_0_10":
                    round(media, 2),

                "R_0_100":
                    round(media * 10, 2),

                "diferenca_juizes":
                    diferenca,

                "auditoria_humana":
                    auditoria_humana,

                "motivo_auditoria":
                    motivo,

                "justificativa_juiz_1":
                    j1["justificativa"],

                "justificativa_juiz_2":
                    j2["justificativa"],
            }

        elif len(julgamentos) == 1:

            j1 = julgamentos[0]

            linha = {
                "anon_id": anon_id,
                "tarefa": origem["tarefa"],
                "gerador_id": origem["gerador_id"],
                "gerador": origem["gerador"],

                "juiz_1": j1["juiz"],
                "nota_juiz_1": j1["total"],

                "juiz_2": "",
                "nota_juiz_2": "",

                "media_qualitativa_0_10": "",
                "R_0_100": "",
                "diferenca_juizes": "",

                "auditoria_humana": "SIM",

                "motivo_auditoria":
                    "JULGAMENTO_LLM_AUSENTE",

                "justificativa_juiz_1":
                    j1["justificativa"],

                "justificativa_juiz_2": "",
            }

        else:
            raise RuntimeError(
                f"{anon_id}: número inesperado "
                f"de julgamentos = {len(julgamentos)}"
            )

        consolidados.append(linha)

        if linha["auditoria_humana"] == "SIM":
            auditoria.append(linha)

    campos = list(
        consolidados[0].keys()
    )

    with SAIDA_CONSOLIDADA.open(
        "w",
        encoding="utf-8-sig",
        newline=""
    ) as f:

        writer = csv.DictWriter(
            f,
            fieldnames=campos
        )

        writer.writeheader()
        writer.writerows(consolidados)

    SAIDA_AUDITORIA.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    with SAIDA_AUDITORIA.open(
        "w",
        encoding="utf-8-sig",
        newline=""
    ) as f:

        writer = csv.DictWriter(
            f,
            fieldnames=campos
        )

        writer.writeheader()
        writer.writerows(auditoria)

    print()
    print("==============================")
    print("CONSOLIDAÇÃO FINALIZADA")
    print("==============================")
    print(f"Soluções:             {len(consolidados)}")
    print(f"Julgamentos válidos:  {len(avaliacoes)}")
    print(f"Casos para auditoria: {len(auditoria)}")
    print("==============================")
    print()
    print(f"Arquivo: {SAIDA_CONSOLIDADA}")
    print(f"Auditoria: {SAIDA_AUDITORIA}")


if __name__ == "__main__":
    main()