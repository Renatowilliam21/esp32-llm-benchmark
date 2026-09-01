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

TAREFA: T09 — classificarIndiceCalor
NÍVEL: Fácil

ASSINATURA/CONTRATO
String classificarIndiceCalor(float indiceCalor);

ENUNCIADO
Se NaN, retorne String vazia. Caso contrário: <=27 normal; >27 e <=32 atencao; >32 e <=41 atencao_extrema; >41 e <=54 perigo; >54 perigo_extremo.

CONTEXTO E RESTRIÇÕES
Use exatamente os textos: normal, atencao, atencao_extrema, perigo, perigo_extremo.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
