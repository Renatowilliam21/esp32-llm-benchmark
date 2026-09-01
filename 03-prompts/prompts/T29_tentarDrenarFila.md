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

TAREFA: T29 — tentarDrenarFila
NÍVEL: Difícil

ASSINATURA/CONTRATO
void tentarDrenarFila();

ENUNCIADO
Se EEPROM estiver disponível, processe o registro mais antigo pendente. Se totalRegistros==0, retorne. Se o registro falhar no checksum, descarte-o, decremente total e salve controle. Se já estiver marcado como enviado, apenas remova logicamente da fila. Caso contrário, monte JSON e envie aos dois destinos configurados; remova o registro somente quando ambos tiverem sucesso. Em sucesso, marque enviado e regrave antes de decrementar a fila. Se EEPROM estiver indisponível, aplique lógica equivalente ao único registroPendenteRAM, mantendo-o quando houver falha parcial.

CONTEXTO E RESTRIÇÕES
Considere lerRegistro, gravarRegistro, montarJSON, enviarParaUmServidor, salvarControleEEPROM e estado global da fila.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
