import 'tarefa_model.dart';

class Quadro {
  Quadro({
    this.id,
    required this.tituloQuadro,
    required this.tarefas,
    this.criadoEm,
  });

  final String? id;
  final String tituloQuadro;
  final List<Tarefa> tarefas;
  final String? criadoEm;

  Quadro copyWith({
    String? id,
    String? tituloQuadro,
    List<Tarefa>? tarefas,
    String? criadoEm,
  }) {
    return Quadro(
      id: id ?? this.id,
      tituloQuadro: tituloQuadro ?? this.tituloQuadro,
      tarefas: tarefas ?? this.tarefas,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  factory Quadro.fromJson(Map<String, dynamic> json) {
    final tarefasJson = json['tarefas'] as List<dynamic>? ?? const [];

    return Quadro(
      id: json['id'] as String?,
      tituloQuadro: json['tituloQuadro'] as String? ?? '',
      tarefas: tarefasJson
          .map((item) => Tarefa.fromJson(item as Map<String, dynamic>))
          .toList(),
      criadoEm: json['criadoEm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tituloQuadro': tituloQuadro,
      'tarefas': tarefas.map((tarefa) => tarefa.toJson()).toList(),
      if (criadoEm != null) 'criadoEm': criadoEm,
    };
  }
}
