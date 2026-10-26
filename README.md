# ESP32-LLM Benchmark

Material de apoio do artigo **"ESP32-LLM: Uma Avaliação Experimental da Confiabilidade de Código Gerado por Large Language Models para Sistemas Embarcados"**.

O estudo avalia o código ESP32 gerado por três LLMs (GPT-5.6 Sol, DeepSeek V4 Pro e Claude Sonnet 5) em 30 tarefas derivadas do firmware de uma estação de monitoramento, divididas em três níveis de dificuldade (T01 a T10 fáceis, T11 a T20 médias, T21 a T30 difíceis). Cada tarefa foi submetida uma vez a cada modelo, o que resultou em 90 soluções avaliadas por compilação, 151 casos de teste funcionais e julgamento qualitativo cruzado e cego.

## Estrutura do repositório

| Pasta | Conteúdo |
|---|---|
| `00-documentacao` | Documentos metodológicos por etapa, plano e diário do experimento |
| `01-codigo-base/esp32-wemos-rtc-eeprom` | Firmware real de origem das tarefas (Smart Weather Platform) |
| `02-benchmark` | Inventário funcional (36 candidatos), `tarefas.csv` com as 30 tarefas selecionadas (função de origem, nível, enunciado, requisitos, tipo de teste e conceitos) |
| `03-prompts` | `prompt-base.md`, protocolo experimental, catálogo e os 30 prompts individuais |
| `04-testes` | Casos de teste e critérios de correção |
| `05-respostas-llms` | Respostas originais das três LLMs, com os metadados de cada execução (`metadata.json`) |
| `06-resultados` | Registro das 90 execuções (`brutos/registro_execucoes.csv`) |
| `08-artigo` | Manuscrito |
| `10-pipeline` | Scripts de geração das respostas pelas APIs (`config.py`, `runner.py`, `run_all.py`, `providers/`) |
| `11-avaliacao` | Julgamento cruzado cego: rubrica, prompt do juiz, protocolo, matriz de 180 julgamentos, julgamentos, auditoria humana e resultados consolidados |
| `12-testes-objetivos` | Ambientes de teste por tarefa e modelo, logs de compilação e `resultados_objetivos_90.csv` |
| `13-analise-estatistica` | Análise estatística; `reproduzir_resultados.py` reproduz os números do artigo |
| `14-taxonomia-falhas` | Taxonomia de falhas das tarefas difíceis e tabela de R, C e F por solução |
| `15-analise-qualitativa-objetiva` | Relação entre avaliação qualitativa e desempenho objetivo |
| `16-figuras-resultados` | Figuras do artigo, inclusive o mapa de calor da correção funcional por tarefa e modelo |
| `17-tabelas-resultados` | Tabelas de resultados |
| `modelosparapublicaodeartigos` | Template SBC (não faz parte do experimento) |

## Protocolo de geração

- **Modelos:** `gpt-5.6-sol`, `deepseek-v4-pro` e `claude-sonnet-5`, acessados pelas APIs dos provedores; o modelo retornado pela API foi registrado em cada execução.
- **Parâmetros:** limite de 8192 tokens de saída, sem prompt de sistema e demais parâmetros, inclusive a temperatura, nos valores padrão de cada provedor.
- **Geração:** uma única resposta por modelo e tarefa, sem feedback de compilação ou de testes, sem refinamento e sem correção manual. Quando o código veio em blocos Markdown, somente os delimitadores foram removidos.
- **Datas:** prompts e casos de teste versionados em 31/08/2026; respostas geradas em 01/09/2026.
- **Respostas sem código:** quatro respostas do DeepSeek V4 Pro (T23, T24, T25 e T29) atingiram o limite de 8192 tokens sem produzir código e foram contabilizadas como falha de compilação, sem nova consulta.
- **Desvio do protocolo:** o item 5 de `03-prompts/protocolo_experimental.md` previa temperatura 0 ou a menor permitida, mas o pipeline não definiu a temperatura explicitamente; vale o padrão de cada provedor.

## Avaliação

- **Objetiva:** Arduino CLI 1.5.1, core `esp32:esp32` 3.3.8, FQBN `esp32:esp32:esp32`. C indica compilação e integração (0 ou 100) e F, a proporção de casos aprovados; soluções que não compilaram recebem F = 0.
- **Qualitativa (R):** cinco critérios de 0 a 2 (`11-avaliacao/rubrica_julgamento.md`). Os três modelos atuaram como juízes, cada solução foi avaliada por dois deles, nunca pelo que a produziu, com identificador anônimo (`11-avaliacao/mapa_anonimizacao.csv`), sem repetição e com a ordem randomizada por semente fixa. Quando os juízes diferiram em quatro pontos ou mais, ou faltou um julgamento, houve auditoria humana.

## Reproduzir os números e a figura

```bash
pip install pandas scipy scikit-learn matplotlib

# imprime cada número calculado ao lado do valor do artigo (OK ou DIFERE)
python 13-analise-estatistica/reproduzir_resultados.py

# gera a figura de C, F e R por modelo e nível
python 16-figuras-resultados/gerar_figura_01.py
```

Os dois scripts leem apenas os CSV do repositório (`14-taxonomia-falhas/qualitativo_vs_objetivo_90.csv`, `14-taxonomia-falhas/taxonomia_falhas_tarefas_dificeis.csv` e `11-avaliacao/resultados_julgamento_consolidados.csv`).

**Convenção estatística.** Nas comparações par a par (Mann-Whitney bilateral), a correção de Holm é aplicada às comparações testáveis. Quando dois níveis têm F idêntico e constante (por exemplo, F = 100 em todas as tarefas fáceis e médias de um modelo), não há o que testar e o par fica fora da família de Holm. Os tamanhos de efeito são rank-biserial.

## Reexecutar a geração

As chaves das APIs são lidas de variáveis de ambiente (ver `10-pipeline/config.py` e `10-pipeline/README.md`). **Não versione o arquivo `.env`.**
