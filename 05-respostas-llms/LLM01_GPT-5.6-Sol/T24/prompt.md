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

TAREFA: T24 — lerAmbiente
NÍVEL: Difícil

ASSINATURA/CONTRATO
void lerAmbiente(float &temperatura, float &umidade);

ENUNCIADO
Selecione a primeira fonte saudável e com valores válidos nesta prioridade: SHT41, BME280, AHT10, DHT22. Faixas válidas: temperatura -40..85 °C e umidade 0..100%. Se uma fonte retornar dado inválido, tente a próxima. Se nenhuma for válida, retorne NAN/NAN e fonteAmbienteAtual='nenhuma'. Quando a fonte selecionada for diferente da fonteAmbienteAtual anterior, atualize-a e incremente trocasDeFonteAmbiente.

CONTEXTO E RESTRIÇÕES
Considere flags/objetos globais dos sensores, ultimaTempDHT, ultimaUmidDHT, fonteAmbienteAtual e trocasDeFonteAmbiente.

SAÍDA
Retorne somente o código C++ necessário para implementar a tarefa.
