# Etapa 5 — Seleção das LLMs e Ambiente de Execução — Versão Corrigida

## Correção do desenho

A condição local com Qwen2.5-Coder-7B-Instruct foi removida. O experimento não dependerá de inferência local, pois a máquina disponível não será utilizada para executar LLMs.

O conjunto principal passa a ser:

1. **GPT-5.6 Sol — OpenAI**
2. **Gemini 2.5 Pro — Google**
3. **Claude Sonnet 5 — Anthropic**

Assim, as 90 soluções continuam sendo:

**30 tarefas × 3 LLMs × 1 resposta = 90 soluções.**

## Justificativa do Claude

Foi selecionado **Claude Sonnet 5**, modelo ativo da Anthropic. A Anthropic o apresenta como uma evolução da família Sonnet com melhorias em raciocínio, uso de ferramentas e programação. O identificador documentado para API é `claude-sonnet-5`.

A escolha de Sonnet, em vez de Opus, mantém uma condição forte para programação sem transformar o experimento em uma comparação baseada apenas nos modelos de maior custo de cada fornecedor.

## Mudança na interpretação do estudo

A versão anterior permitia comparar nuvem versus execução local e proprietário versus modelo aberto. **Essa interpretação deve ser removida.**

A nova comparação é entre **três LLMs proprietárias de fornecedores distintos**. Portanto, as conclusões deverão ser formuladas em termos dos modelos avaliados:

> “Entre GPT-5.6 Sol, Gemini 2.5 Pro e Claude Sonnet 5...”

e não como:

> “Modelos proprietários são melhores/piores que modelos open-source.”

## Vantagem metodológica da correção

As três condições passam a usar infraestrutura de inferência fornecida pelos próprios provedores. Isso elimina do desenho principal variáveis locais como:
- RAM disponível;
- VRAM;
- quantização GGUF;
- GPU offload;
- número de threads;
- versão do backend do LM Studio.

O computador local continuará sendo relevante para **compilação, testes e análise dos códigos**, mas não para gerar as respostas das LLMs.

## Controle experimental

Para cada T01–T30:
- utilizar exatamente o mesmo prompt;
- obter somente uma resposta de cada modelo;
- não fornecer feedback;
- não solicitar correção;
- não permitir ferramentas externas;
- armazenar a resposta bruta;
- registrar modelo/ID, data/hora, interface/API e parâmetros disponíveis.

## Parâmetros

Não assumir que temperatura, top-p ou mecanismos internos têm equivalência perfeita entre fornecedores. Quando um parâmetro não puder ser configurado de modo comparável, manter o comportamento documentado/recomendado do fornecedor e registrar a diferença.

Isso é metodologicamente mais correto do que afirmar que três APIs distintas operam sob exatamente a mesma configuração interna.

## Piloto

Antes das 90 execuções oficiais, realizar chamadas de piloto que não pertençam às 30 unidades experimentais para verificar:
- autenticação;
- leitura dos prompts;
- salvamento da resposta;
- extração do código;
- limite de saída;
- registro dos metadados;
- tratamento de erro da API.

Os resultados do piloto não entram na análise.

## Congelamento

Após o piloto:
1. registrar IDs dos modelos;
2. registrar versões dos SDKs/APIs;
3. congelar scripts e parâmetros;
4. realizar commit;
5. iniciar as 90 gerações oficiais.
