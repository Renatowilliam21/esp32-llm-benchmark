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

TAREFA: T18 — lerEEPROM
NÍVEL: Média

ASSINATURA/CONTRATO
uint8_t lerEEPROM(uint16_t endereco);

ENUNCIADO
Leia um byte da AT24C32 em 0x50. Envie endereço interno alto e baixo, finalize a fase de endereço, solicite exatamente 1 byte e retorne o byte quando disponível; se não houver byte, retorne 0.

CONTEXTO E RESTRIÇÕES
Use Wire.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
