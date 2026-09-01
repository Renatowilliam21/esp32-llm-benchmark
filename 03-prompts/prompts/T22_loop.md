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

TAREFA: T22 — loop
NÍVEL: Difícil

ASSINATURA/CONTRATO
void loop();

ENUNCIADO
Implemente orquestração baseada em millis(): alimente watchdog, processe servidor administrativo e comandos seriais; se Wi-Fi estiver desconectado, tente reconectar e retorne; execute coletarAmostra quando INTERVALO_COLETA vencer; gravarRegistroPendente quando INTERVALO_AGREGACAO vencer; tentarDrenarFila quando INTERVALO_ENVIO vencer. Atualize os timestamps correspondentes apenas quando cada ação for disparada.

CONTEXTO E RESTRIÇÕES
Considere globais server, ultimaColeta, ultimaAgregacao, ultimaTentativaEnvio e constantes INTERVALO_COLETA/AGREGACAO/ENVIO; evite delay no fluxo normal.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
