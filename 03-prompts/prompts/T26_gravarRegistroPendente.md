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

TAREFA: T26 — gravarRegistroPendente
NÍVEL: Difícil

ASSINATURA/CONTRATO
void gravarRegistroPendente();

ENUNCIADO
Crie RegistroMeteorologico a partir das médias dos acumuladores. Se não houver nenhuma amostra, retorne. Preencha timestamp do RTC quando disponível; calcule ITGU, ITU e índice de calor quando houver entradas necessárias; copie e zere pulsos de chuva/vento em região crítica e derive chuva/velocidade conforme constantes do firmware. Se EEPROM estiver disponível, grave em fila circular, atualize proximoRegistro/totalRegistros e salve controle; se estiver indisponível, use registroPendenteRAM e registroPendenteRAMValido. Ao final, limpe acumuladores.

CONTEXTO E RESTRIÇÕES
Considere structs, acumuladores, RTC, funções de cálculo, gravarRegistro, salvarControleEEPROM, MAX_REGISTROS e variáveis globais já existentes.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
