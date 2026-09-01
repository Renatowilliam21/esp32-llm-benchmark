# Etapa 6 — Pipeline automatizado e piloto

## 1. Pré-requisitos
- Python 3.10+ recomendado.
- Chaves válidas das APIs OpenAI, Google Gemini e Anthropic.
- Os prompts T01–T30 já presentes em `../03-prompts/prompts/`.

## 2. Instalação

Windows PowerShell:

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edite `.env` e informe as três chaves. **Nunca faça commit do `.env`.**

## 3. Piloto

```powershell
python pilot_runner.py
```

O piloto usa apenas `piloto/prompt_piloto.md`; não usa T01–T30.

Verifique:
- três pastas em `piloto/resultados/`;
- `resposta_bruta.txt`;
- `codigo.cpp`;
- `metadata.json`;
- ausência de erros/truncamento inesperado.

## 4. Execução unitária oficial

Exemplo:

```powershell
python runner.py --provider openai --task T01
python runner.py --provider gemini --task T01
python runner.py --provider anthropic --task T01
```

O script se recusa a sobrescrever uma execução existente. Não use `--force` na coleta oficial.

## 5. Coleta completa

Somente depois do piloto, revisão e commit do protocolo:

```powershell
python run_all.py
```

Isso produz 90 respostas: 30 por modelo.

## 6. Arquivos produzidos por unidade experimental

```text
05-respostas-llms/
└── LLMxx_Modelo/
    └── Txx/
        ├── prompt.md
        ├── resposta_bruta.txt
        ├── codigo.cpp
        └── metadata.json
```

Log agregado:
`06-resultados/brutos/registro_execucoes.csv`

## 7. Regra de integridade

`resposta_bruta.txt` nunca deve ser corrigido.
`codigo.cpp` pode apenas remover cercas Markdown/texto externo por regra automática.
Não corrigir sintaxe, assinatura, biblioteca ou lógica.

## 8. Antes da execução oficial

Crie um commit/tag para congelar:
- prompts;
- scripts;
- IDs dos modelos;
- dependências;
- procedimento experimental.
