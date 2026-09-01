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

TAREFA: T23 — inicializarSensores
NÍVEL: Difícil

ASSINATURA/CONTRATO
void inicializarSensores();

ENUNCIADO
Implemente rotina de inicialização tolerante a falhas para DHT22, BME280/BMP280, AHT10, SHT41, VEML7700, ENS160, RTC e EEPROM. Diferencie BME280 (ID 0x60) de BMP280 (ID 0x58), tente endereços I2C alternativos 0x76/0x77, use ENS160 em 0x52 e fallback 0x53, configure SHT41 em alta precisão sem heater, mantenha LDR como fallback se VEML falhar, ajuste RTC para data/hora de compilação se lostPower(), configure ADC com 12 bits e ADC_11db e atualize flags de disponibilidade/saúde.

CONTEXTO E RESTRIÇÕES
Use objetos e flags globais correspondentes; ausência de um sensor não pode abortar toda a rotina.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
