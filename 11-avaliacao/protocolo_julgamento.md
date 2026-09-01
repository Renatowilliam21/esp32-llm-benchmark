# Protocolo de Julgamento Cruzado Cego

## Objetivo

Avaliar aspectos qualitativos das soluções produzidas pelas três LLMs
utilizadas no benchmark, minimizando viés de autoavaliação.

## Modelos avaliados

- GPT-5.6 Sol
- DeepSeek V4 Pro
- Claude Sonnet 5

## Juízes

Os mesmos modelos são utilizados como juízes, porém é proibida a
autoavaliação.

### Matriz de julgamento

| Gerador | GPT-5.6 Sol | DeepSeek V4 Pro | Claude Sonnet 5 |
|---|---|---|---|
| GPT-5.6 Sol | Não | Sim | Sim |
| DeepSeek V4 Pro | Sim | Não | Sim |
| Claude Sonnet 5 | Sim | Sim | Não |

Cada solução recebe exatamente dois julgamentos independentes.

90 soluções × 2 julgamentos = 180 julgamentos.

## Avaliação cega

O juiz não recebe:

- nome do modelo gerador;
- identificador LLM01, LLM02 ou LLM03;
- provedor;
- resultados de compilação;
- resultados de testes;
- avaliação de outro juiz;
- metadados de geração.

O juiz recebe somente:

- identificador anonimizado;
- tarefa;
- requisitos;
- contrato;
- código candidato;
- rubrica.

## Ordem

As soluções serão apresentadas em ordem randomizada.

A randomização será reproduzível por meio de uma seed fixa.

Seed adotada:

20260901

## Independência

Cada julgamento é realizado em uma chamada independente.

Não será fornecido histórico de avaliações anteriores.

Não haverá feedback, correção ou segunda avaliação do mesmo juiz para a
mesma solução.

## Pontuação

Cada juiz atribui:

R1, R2, R3, R4 e R5 em escala 0–2.

Total máximo = 10.

Quando a diferença entre os dois juízes for inferior a 4 pontos:

R_final = média(J1, J2)

Quando:

|J1 - J2| >= 4

o caso será marcado para auditoria humana.

As notas originais serão sempre preservadas.

## Papel da avaliação qualitativa

O julgamento por LLM não substitui compilação nem testes automatizados.

A correção funcional será medida separadamente.

O julgamento qualitativo compõe apenas a dimensão de aderência aos
requisitos e adequação qualitativa.