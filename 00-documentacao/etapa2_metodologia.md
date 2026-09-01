# Etapa 2 — Construção do Benchmark Experimental

## Resultado

A partir dos 36 candidatos do inventário funcional foram selecionadas **30 tarefas**:

- 10 fáceis;
- 10 médias;
- 10 difíceis.

## Critérios de seleção

1. possibilidade de teste objetivo;
2. clareza da especificação;
3. diversidade de conceitos ESP32/IoT;
4. baixa sobreposição entre tarefas;
5. relevância para o firmware real;
6. possibilidade de submeter a mesma tarefa às três LLMs;
7. representação crescente de dificuldade.

## Critério de dificuldade

### Fácil
Funções pequenas, com responsabilidade local, poucas dependências e saída predominantemente determinística.

### Média
Tarefas que introduzem estado, periféricos, I²C, interrupções, fallback ou cálculos/regras com maior número de condições.

### Difícil
Tarefas de integração envolvendo múltiplos componentes, resiliência, concorrência, persistência, filas, rede ou contrato de API.

## Candidatos excluídos

Foram excluídos C12, C25, C26, C28, C34 e C35 principalmente por redundância ou baixa contribuição para a diversidade do benchmark.

## Observação metodológica importante

A classificação de dificuldade é **operacional para este experimento** e deverá ser declarada como definida pelos pesquisadores com base em:
- quantidade de requisitos;
- número de dependências;
- necessidade de hardware/mocks;
- presença de estado;
- tratamento de falhas;
- integração entre componentes.

Ela não deve ser apresentada como uma classificação universal de dificuldade de programação.

## Próxima etapa

Transformar cada tarefa em uma especificação experimental completa, começando pelo desenho dos **casos de teste e critérios de correção** antes de consultar qualquer LLM.
