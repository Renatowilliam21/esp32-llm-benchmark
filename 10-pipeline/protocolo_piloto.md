# Protocolo do experimento-piloto

## Objetivo
Validar a infraestrutura, não avaliar qualidade de código.

## Entrada
Usar exclusivamente `piloto/prompt_piloto.md`, que não pertence a T01–T30.

## Critérios de aprovação do pipeline
O piloto é aprovado se, para os três provedores:
- a autenticação funcionar;
- houver uma resposta registrada ou um erro operacional corretamente documentado;
- a resposta bruta for preservada;
- o código for extraído sem edição semântica;
- o `metadata.json` for criado;
- o modelo solicitado/retornado for registrado quando disponível;
- tempo e uso de tokens forem registrados quando a API os disponibilizar.

## Falhas permitidas no piloto
Uma falha operacional pode ser corrigida porque o piloto não integra o conjunto experimental.
Exemplos: chave inválida, pacote ausente, nome de campo da API alterado.

## Após aprovação
Registrar versões instaladas:

```powershell
python --version
pip freeze > requirements-lock.txt
```

Fazer commit e não alterar o pipeline durante a coleta oficial, salvo erro grave documentado.
