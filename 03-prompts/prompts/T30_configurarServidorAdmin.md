Você está participando de um experimento de geração de código para ESP32.

REGRAS GERAIS
1. Linguagem: C++ para Arduino/ESP32.
2. Gere somente a implementação solicitada.
3. Não inclua explicações, comentários de análise, Markdown ou blocos ```; responda somente com código-fonte.
4. Preserve exatamente os nomes e assinaturas fornecidos.
5. Não altere requisitos para simplificar a solução.
6. Não crie bibliotecas fictícias ou APIs inexistentes.
7. Você pode criar pequenas funções auxiliares quando necessário, desde que não altere o contrato pedido.
8. Não implemente setup() ou loop() quando eles não forem explicitamente solicitados.
9. Quando o enunciado disser que objetos, constantes, structs ou funções já existem, apenas os utilize; não redefina-os.
10. Priorize código determinístico e compilável no ecossistema Arduino-ESP32.

TAREFA: T30 — configurarServidorAdmin
NÍVEL: Difícil

ASSINATURA/CONTRATO
void configurarServidorAdmin();

ENUNCIADO
Configure servidor WebServer embarcado. GET / deve responder 200 text/html com página administrativa mostrando estado da fila/buffer, disponibilidade dos sensores, fonte de ambiente e status de envio, além de formulário para URL/token local e de produção. POST /salvar deve atualizar os quatro valores, persistir em Preferences e responder com redirecionamento HTTP 303 para /. Inicie o servidor ao final.

CONTEXTO E RESTRIÇÕES
Considere objeto global server e Preferences; evite adicionar exposição desnecessária de segredos fora dos campos exigidos para configuração.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
