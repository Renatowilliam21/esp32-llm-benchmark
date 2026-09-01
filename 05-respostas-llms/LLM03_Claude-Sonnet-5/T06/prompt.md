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

TAREFA: T06 — calcularPontoOrvalho
NÍVEL: Fácil

ASSINATURA/CONTRATO
float calcularPontoOrvalho(float temperaturaC, float umidadeRelativa);

ENUNCIADO
Calcule o ponto de orvalho pela fórmula de Magnus: a=17.27; b=237.7; alpha=(a*T)/(b+T)+ln(UR/100); Td=(b*alpha)/(a-alpha). Retorne Td em graus Celsius.

CONTEXTO E RESTRIÇÕES
Use log() natural; entradas são consideradas fisicamente válidas.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
