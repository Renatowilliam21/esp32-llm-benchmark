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

TAREFA: T28 — enviarParaUmServidor
NÍVEL: Difícil

ASSINATURA/CONTRATO
bool enviarParaUmServidor(const String &url, const String &token, const String &json, String &status);

ENUNCIADO
Se url ou token estiver vazio, não faça requisição, defina status='nao configurado' e retorne true. Para http:// use cliente HTTP normal; para https:// use WiFiClientSecure. Configure connect timeout de 8000 ms e timeout de 60000 ms, Content-Type application/json e header X-API-Token. Faça POST do JSON. Retorne true apenas para códigos 2xx. Para códigos HTTP de erro ou erro de transporte, retorne false e preencha status com informação útil.

CONTEXTO E RESTRIÇÕES
Use HTTPClient; em HTTPS é permitido setInsecure() para reproduzir o comportamento experimental.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
