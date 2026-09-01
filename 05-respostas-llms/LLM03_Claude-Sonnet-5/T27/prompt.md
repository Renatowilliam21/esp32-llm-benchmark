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

TAREFA: T27 — montarJSON
NÍVEL: Difícil

ASSINATURA/CONTRATO
String montarJSON(const RegistroMeteorologico &r);

ENUNCIADO
Monte JSON com ArduinoJson representando o registro meteorológico. Inclua somente campos numéricos que não sejam NaN. Inclua tipo_agregacao='agregado'. Para ITGU, ITU e índice de calor, inclua também suas classificações quando o índice existir. Se r.ano>0, inclua registrado_em no formato YYYY-MM-DD HH:MM:SS. AQI deve ser serializado como inteiro arredondado.

CONTEXTO E RESTRIÇÕES
Considere funções classificar() e classificarIndiceCalor(); use ArduinoJson.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
