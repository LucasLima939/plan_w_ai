import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../environments/environment.dart';
import '../models/quadro_model.dart';

class GeminiService {
  GeminiService()
      : _ai = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: Environment.geminiApiKey,
        );

  final GenerativeModel _ai;

  Future<Quadro> organizarTarefas(String textoUsuario) async {
    final prompt = _criarPrompt(textoUsuario);

    final response = await _ai.generateContent([Content.text(prompt)]);

    final textoResposta = response.text ?? '';

    return _converterRespostaParaQuadro(textoResposta);
  }

  String _criarPrompt(String textoUsuario) {
    return '''
Você é um assistente de produtividade.

Sua função é transformar uma lista bagunçada de tarefas em um quadro Kanban organizado.

Analise o texto enviado pelo usuário e extraia as tarefas.

Para cada tarefa, defina:

- titulo
- categoria
- prioridade
- esforco
- prazoSugerido
- status

Regras:

- Não invente tarefas que não estejam no texto.
- Se uma tarefa estiver pouco clara, reescreva de forma objetiva.
- Use categoria apenas entre: trabalho, pessoal, financeiro, estudos, comunicacao, outro.
- Use prioridade apenas entre: baixa, media, alta.
- Use esforco apenas entre: baixo, medio, alto.
- Use prazoSugerido apenas entre: hoje, esta_semana, sem_prazo.
- Use status sempre como: a_fazer.
- Responda apenas em JSON válido.
- Não use markdown.
- Não escreva explicações fora do JSON.

Formato esperado:

{
  "tituloQuadro": "string",
  "tarefas": [
    {
      "titulo": "string",
      "categoria": "trabalho | pessoal | financeiro | estudos | comunicacao | outro",
      "prioridade": "baixa | media | alta",
      "esforco": "baixo | medio | alto",
      "prazoSugerido": "hoje | esta_semana | sem_prazo",
      "status": "a_fazer"
    }
  ]
}

Texto do usuário:

$textoUsuario
''';
  }

  Quadro _converterRespostaParaQuadro(String resposta) {
    final respostaLimpa = resposta
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final json = jsonDecode(respostaLimpa) as Map<String, dynamic>;

    return Quadro.fromJson(json);
  }
}
