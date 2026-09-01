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

TAREFA: T15 — lerLDR
NÍVEL: Média

ASSINATURA/CONTRATO
float lerLDR();

ENUNCIADO
Se vemlDisponivel for verdadeiro, retorne veml.readLux(). Caso contrário, leia PIN_LDR com analogRead() e converta linearmente o intervalo 0..4095 para 100..0 usando map().

CONTEXTO E RESTRIÇÕES
Considere globais vemlDisponivel, veml e PIN_LDR.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
