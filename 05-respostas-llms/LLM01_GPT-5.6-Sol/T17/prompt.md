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

TAREFA: T17 — escreverEEPROM
NÍVEL: Média

ASSINATURA/CONTRATO
void escreverEEPROM(uint16_t endereco, uint8_t valor);

ENUNCIADO
Escreva um byte em EEPROM AT24C32 no endereço I2C 0x50. O endereço interno possui 16 bits e deve ser enviado primeiro byte alto e depois byte baixo, seguido do valor. Finalize a transmissão e aguarde 5 ms para o ciclo de gravação.

CONTEXTO E RESTRIÇÕES
Use Wire e delay(5) somente para o ciclo de gravação da EEPROM.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
