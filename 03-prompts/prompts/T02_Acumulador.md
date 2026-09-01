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

TAREFA: T02 — Acumulador
NÍVEL: Fácil

ASSINATURA/CONTRATO
struct Acumulador { float soma; unsigned int quantidade; void adicionar(float valor); float media() const; void limpar(); };

ENUNCIADO
Implemente a estrutura Acumulador. Valores NaN devem ser ignorados. media() deve retornar NaN quando não houver amostras. limpar() deve restaurar soma=0 e quantidade=0.

CONTEXTO E RESTRIÇÕES
C++/Arduino; pode usar NAN/isnan().

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
