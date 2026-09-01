import re

def extrair_codigo(resposta: str) -> tuple[str, dict]:
    """
    Extrai código sem corrigir a solução.
    Remove apenas cercas Markdown quando existirem.
    """
    fences = re.findall(r"```(?:cpp|c\+\+|arduino|c)?\s*\n(.*?)```", resposta, flags=re.I | re.S)

    if fences:
        codigo = "\n\n".join(x.strip() for x in fences).strip()
        return codigo, {
            "metodo": "blocos_markdown",
            "quantidade_blocos": len(fences),
            "alteracao_semantica": False,
        }

    return resposta.strip(), {
        "metodo": "resposta_integral",
        "quantidade_blocos": 0,
        "alteracao_semantica": False,
    }
