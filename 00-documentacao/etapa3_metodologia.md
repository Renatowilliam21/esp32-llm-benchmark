# Etapa 3 — Casos de Teste e Critérios de Correção

## Objetivo
Congelar os critérios de corretude **antes** da execução das LLMs, reduzindo o risco de adaptar a avaliação às respostas observadas.

## Resultado
Foram definidos **151 casos de teste** para as 30 tarefas do benchmark.

## Escore funcional por tarefa
A nota de cada solução será calculada em escala de 0 a 100:

- **70% — Corretude funcional:** proporção dos casos de teste aprovados;
- **20% — Compilação/integração:** compilação e integração no ambiente padronizado;
- **10% — Aderência à especificação:** respeito ao contrato e aos requisitos explícitos.

Essa nota mede a correção da solução. Métricas como complexidade ciclomática, code smells, RAM, Flash e tempo deverão ser analisadas separadamente para evitar misturar conceitos diferentes em um único indicador.

## Regra de execução
A execução principal utilizará **uma resposta por tarefa por LLM**, sem feedback corretivo. A resposta original deve ser preservada mesmo quando não compilar.

## Casos numéricos
Os resultados esperados de T06, T07, T08 e T16 foram derivados das fórmulas presentes no firmware-base. Comparações de ponto flutuante usam tolerância explícita.

## Hardware e rede
Casos que dependem de I²C, sensores, interrupções, HTTP/HTTPS ou tempo devem ser executados com mocks/stubs/simuladores ou em um ambiente físico rigorosamente padronizado. A mesma infraestrutura deve ser aplicada às três LLMs.

## Congelamento metodológico
Após o commit desta etapa, alterações em casos de teste devem ser registradas como nova versão e justificadas no diário do experimento. Não se deve modificar silenciosamente um teste após observar qual LLM foi favorecida ou prejudicada.

## Próxima etapa
Construir o **prompt experimental padronizado** e as fichas T01–T30 com as informações que serão realmente fornecidas às LLMs. O código de referência e os resultados esperados dos testes não devem ser incluídos no prompt.
