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

TAREFA: T21 — setup
NÍVEL: Difícil

ASSINATURA/CONTRATO
void setup();

ENUNCIADO
Implemente a inicialização do firmware: Serial a 115200; configure pinos de pluviômetro e anemômetro como INPUT_PULLUP e associe as respectivas ISRs; inicialize watchdog; inicialize Wire; chame inicializarSensores(); detecte EEPROM e, se disponível, carregue o controle persistido; carregue configuração; configure/conecte Wi-Fi; configure servidor administrativo.

CONTEXTO E RESTRIÇÕES
Considere funções auxiliares já existentes com nomes: inicializarSensores, detectarEeprom, carregarControleEEPROM, carregarConfiguracao, configurarWiFi, configurarServidorAdmin. Não implemente essas auxiliares.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
