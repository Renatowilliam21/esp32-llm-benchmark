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

TAREFA: T03 — detectarEeprom
NÍVEL: Fácil

ASSINATURA/CONTRATO
bool detectarEeprom();

ENUNCIADO
Implemente uma função que detecte uma EEPROM AT24C32 no endereço I2C 0x50. A função deve iniciar uma transmissão e considerar o dispositivo presente somente quando endTransmission() retornar 0.

CONTEXTO E RESTRIÇÕES
Use a instância global Wire; não inicialize o barramento dentro da função.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
