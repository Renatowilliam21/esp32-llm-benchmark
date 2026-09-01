# Rubrica de Julgamento Qualitativo

Cada solução deve ser avaliada de forma independente, sem conhecimento
do modelo que produziu o código.

Cada critério recebe nota 0, 1 ou 2.

## R1 — Atendimento ao contrato e assinatura

0 — A solução altera, ignora ou viola de forma relevante o contrato,
assinatura, tipo de retorno ou parâmetros especificados.

1 — A solução preserva parcialmente o contrato, mas apresenta pequenas
inconsistências que podem afetar integração ou uso.

2 — A solução preserva integralmente assinatura, parâmetros, tipos,
retorno e contrato especificados.

## R2 — Atendimento aos requisitos explícitos

0 — Um ou mais requisitos essenciais não são implementados ou são
implementados de maneira incompatível.

1 — A maior parte dos requisitos é atendida, mas existe omissão,
ambiguidade ou implementação parcial.

2 — Todos os requisitos explícitos identificáveis no enunciado são
atendidos.

## R3 — Uso coerente das dependências fornecidas

0 — A solução inventa APIs, objetos ou bibliotecas, utiliza dependências
de maneira incompatível ou ignora dependências essenciais.

1 — O uso das dependências é parcialmente adequado, mas apresenta
alguma inconsistência ou escolha questionável.

2 — As dependências fornecidas são utilizadas de forma coerente com o
contexto e com o contrato da tarefa.

## R4 — Ausência de comportamento incompatível

0 — A solução introduz comportamento claramente incompatível com o
enunciado, efeitos colaterais indevidos ou lógica contraditória.

1 — Existem pequenas incompatibilidades ou decisões discutíveis, mas a
intenção principal da tarefa é preservada.

2 — Não há comportamento evidentemente incompatível com a especificação.

## R5 — Adequação ao contexto ESP32 e sistemas embarcados

0 — A solução apresenta decisões claramente inadequadas ao ESP32 ou ao
contexto embarcado descrito.

1 — A solução é utilizável, mas possui escolhas que podem ser melhoradas
para o contexto embarcado.

2 — A solução é adequada ao contexto ESP32, respeitando as restrições e
o estilo esperado para sistemas embarcados.

## Escore

Total = R1 + R2 + R3 + R4 + R5

Faixa:

0 a 10 pontos.

O juiz deve também fornecer uma justificativa curta e objetiva.