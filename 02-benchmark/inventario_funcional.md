# Inventário Funcional — ESP32 LLM Benchmark

## Código-base
`esp32-wemos-rtc-eeprom.ino` — Smart Weather Platform firmware v2.10.

## Objetivo desta etapa
Identificar candidatos funcionais derivados do firmware real antes de selecionar as 30 tarefas do benchmark.

## Resultado
Foram identificados **36 candidatos funcionais**, cobrindo:

- validação e tratamento de dados;
- interrupções e temporização;
- inicialização e orquestração;
- sensores e redundância/fallback;
- índices bioclimáticos;
- EEPROM e integridade;
- fila circular e persistência;
- serialização JSON;
- comunicação HTTP/HTTPS;
- configuração Wi‑Fi;
- interface administrativa embarcada.

## Regra metodológica
Nenhum dos 36 itens é ainda uma tarefa experimental definitiva. A próxima etapa deverá aplicar critérios de seleção para formar exatamente:

- 10 tarefas fáceis;
- 10 tarefas médias;
- 10 tarefas difíceis.

Os critérios sugeridos para seleção são:
1. independência da tarefa;
2. possibilidade de teste objetivo;
3. clareza da especificação;
4. diversidade de conceitos;
5. relevância para ESP32/IoT;
6. baixa sobreposição com outras tarefas;
7. viabilidade de execução nas três LLMs sob o mesmo prompt.

## Próxima etapa
Construir `tarefas.csv`, selecionando 30 dos 36 candidatos e justificando a dificuldade de cada tarefa.
