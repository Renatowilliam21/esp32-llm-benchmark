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

TAREFA: T04 — lerUV
NÍVEL: Fácil

ASSINATURA/CONTRATO
float lerUV(int pinoUV);

ENUNCIADO
Leia o ADC de 12 bits do ESP32 no pino informado. Considere referência de 3,3 V. Converta a leitura para tensão e depois para índice UV usando indiceUV = tensao * 10. O retorno nunca pode ser negativo.

CONTEXTO E RESTRIÇÕES
Use analogRead(); ADC esperado no intervalo 0..4095.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
