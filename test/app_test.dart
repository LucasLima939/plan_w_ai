import 'package:flutter_test/flutter_test.dart';

import 'package:plan_w_ai/app/app.dart';
import 'package:plan_w_ai/app/models/quadro_model.dart';
import 'package:plan_w_ai/app/models/tarefa_model.dart';

void main() {
  group('App', () {
    test('should create the app', () {
      const app = App();
      expect(app, isA<App>());
    });
  });

  group('Tarefa', () {
    test('fromJson maps Angular union-type strings to Dart enums', () {
      final tarefa = Tarefa.fromJson(const {
        'titulo': 'Revisar slides',
        'categoria': 'trabalho',
        'prioridade': 'alta',
        'esforco': 'medio',
        'prazoSugerido': 'esta_semana',
        'status': 'a_fazer',
      });

      expect(tarefa.titulo, 'Revisar slides');
      expect(tarefa.categoria, CategoriaTarefa.trabalho);
      expect(tarefa.prioridade, PrioridadeTarefa.alta);
      expect(tarefa.esforco, EsforcoTarefa.medio);
      expect(tarefa.prazoSugerido, PrazoSugerido.estaSemana);
      expect(tarefa.status, StatusTarefa.aFazer);
    });

    test('toJson preserves the Angular string values', () {
      final tarefa = Tarefa(
        titulo: 'Pagar conta',
        categoria: CategoriaTarefa.financeiro,
        prioridade: PrioridadeTarefa.media,
        esforco: EsforcoTarefa.baixo,
        prazoSugerido: PrazoSugerido.hoje,
        status: StatusTarefa.emAndamento,
      );

      expect(tarefa.toJson(), {
        'titulo': 'Pagar conta',
        'categoria': 'financeiro',
        'prioridade': 'media',
        'esforco': 'baixo',
        'prazoSugerido': 'hoje',
        'status': 'em_andamento',
      });
    });
  });

  group('Quadro', () {
    test('fromJson parses tarefas list', () {
      final quadro = Quadro.fromJson(const {
        'id': 'abc',
        'tituloQuadro': 'Minha semana',
        'tarefas': [
          {
            'titulo': 'Tarefa 1',
            'categoria': 'pessoal',
            'prioridade': 'baixa',
            'esforco': 'baixo',
            'prazoSugerido': 'sem_prazo',
            'status': 'concluido',
          },
        ],
        'criadoEm': '2026-05-14T10:00:00.000Z',
      });

      expect(quadro.id, 'abc');
      expect(quadro.tituloQuadro, 'Minha semana');
      expect(quadro.criadoEm, '2026-05-14T10:00:00.000Z');
      expect(quadro.tarefas, hasLength(1));
      expect(quadro.tarefas.first.status, StatusTarefa.concluido);
    });
  });
}
