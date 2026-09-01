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

TAREFA: T19 — calcularChecksum
NÍVEL: Média

ASSINATURA/CONTRATO
uint32_t calcularChecksum(const RegistroMeteorologico &registro);

ENUNCIADO
Calcule checksum sobre a representação em bytes do RegistroMeteorologico, excluindo os bytes do próprio campo checksum, que é o último campo uint32_t da estrutura. Inicie soma=0 e, para cada byte considerado, faça soma=(soma*31)+byte. Retorne soma.

CONTEXTO E RESTRIÇÕES
Considere que checksum é o último campo da struct e use sizeof(RegistroMeteorologico)-sizeof(uint32_t).

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
