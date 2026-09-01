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

TAREFA: T14 — lerPressaoAltitude
NÍVEL: Média

ASSINATURA/CONTRATO
void lerPressaoAltitude(float &pressaoHpa, float &altitudeM);

ENUNCIADO
Priorize BME280 quando bmeDisponivel && bmeSaudavel. Caso contrário, use BMP280 quando bmpDisponivel && bmpSaudavel. Pressão lida em Pa deve ser convertida para hPa. Se nenhum sensor estiver utilizável ou a pressão estiver fora de PRESSAO_MIN_VALIDA..PRESSAO_MAX_VALIDA, retorne NAN em pressão e altitude.

CONTEXTO E RESTRIÇÕES
Considere globais bme, bmp, bmeDisponivel, bmeSaudavel, bmpDisponivel, bmpSaudavel, PRESSAO_MIN_VALIDA e PRESSAO_MAX_VALIDA.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
