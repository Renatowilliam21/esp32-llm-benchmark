# Etapa 4 — Protocolo Experimental de Geração

## 1. Objetivo

Padronizar o conteúdo recebido por cada LLM e o modo de coleta das respostas, evitando diferenças de instrução que possam se tornar variáveis de confusão.

## 2. Unidade experimental

Uma unidade experimental é a resposta de uma LLM a uma tarefa T01–T30.

Com três LLMs e 30 tarefas, a execução principal produzirá:

**30 tarefas × 3 LLMs = 90 soluções.**

## 3. Regras de geração

- Uma conversa/sessão nova para cada tarefa sempre que a interface permitir.
- Uma única resposta por tarefa e por LLM.
- Não fornecer feedback de compilação ou teste.
- Não solicitar correções ou refinamentos.
- Não editar manualmente o código gerado.
- Preservar integralmente a resposta bruta.
- Quando houver texto fora do código apesar da instrução, preservar a resposta bruta e extrair apenas o código para execução, registrando que houve violação de formato.
- Usar exatamente o mesmo prompt de Txx em todas as LLMs.
- Executar as tarefas em ordem previamente definida. Recomenda-se T01→T30 para todas as LLMs ou uma ordem aleatória pré-gerada e igual para todas; não alternar a regra durante o experimento.

## 4. Ambiente-alvo

- Plataforma: ESP32.
- Framework: Arduino.
- Linguagem: C++.
- As bibliotecas e objetos declarados no contexto de cada tarefa são considerados disponíveis no harness de compilação/testes.
- Não é permitido corrigir APIs inventadas pela LLM antes da avaliação.

## 5. Parâmetros de geração

Quando o provedor expuser parâmetros:
- temperatura: 0 ou o menor valor determinístico permitido;
- top-p: padrão do provedor, salvo se puder ser mantido idêntico entre todas as execuções;
- número de respostas: 1.

Quando a interface não permitir controlar temperatura/top-p, registrar `não configurável` nos metadados. Não simular equivalência inexistente entre provedores.

## 6. Metadados obrigatórios

Para cada solução registrar:
- ID da tarefa;
- LLM/provedor;
- nome exato do modelo;
- versão ou identificador exibido;
- data e hora;
- interface utilizada (web, API, LM Studio etc.);
- temperatura, quando configurável;
- top-p, quando configurável;
- duração da geração, se mensurável;
- resposta bruta;
- código extraído;
- observações de formato/recusa/truncamento.

## 7. Informações permitidas no prompt

Podem ser fornecidas:
- objetivo da tarefa;
- assinatura/contrato;
- fórmulas matemáticas necessárias;
- nomes de objetos, constantes e funções auxiliares consideradas disponíveis;
- bibliotecas necessárias;
- restrições de execução;
- comportamento funcional requerido.

## 8. Informações proibidas no prompt

Não fornecer:
- código da implementação original;
- código de referência;
- `casos_teste.csv`;
- valores concretos dos resultados esperados dos testes, exceto constantes que fazem parte do próprio requisito;
- logs de compilação;
- mensagens de erro produzidas em tentativas anteriores;
- solução gerada por outra LLM;
- pontuação ou desempenho de qualquer modelo.

## 9. Extração da resposta

A resposta original deve ser armazenada em `resposta_bruta.txt`.

O código utilizado nos testes deve ser armazenado separadamente em `codigo.cpp` ou extensão definida pelo harness. A extração pode remover somente delimitadores Markdown e texto claramente externo ao código. Não corrigir sintaxe, imports, nomes, tipos ou lógica.

## 10. Tratamento de ocorrências

- **Recusa:** registrar como resposta e atribuir falha funcional/compilação conforme protocolo.
- **Resposta vazia:** registrar sem repetir a consulta.
- **Código truncado:** registrar como fornecido; não solicitar continuação na execução principal.
- **Biblioteca fictícia:** não substituir manualmente.
- **Assinatura alterada:** conta contra aderência e poderá impedir os testes.
- **Explicação junto do código:** registrar violação de formato; extrair somente o código sem outras correções.

## 11. Congelamento

`prompt-base.md` e os 30 prompts devem receber commit antes da primeira execução de LLM. Qualquer alteração posterior deve resultar em nova versão do benchmark e ser registrada no diário experimental.
