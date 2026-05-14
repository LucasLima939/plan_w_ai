enum CategoriaTarefa {
  trabalho('trabalho'),
  pessoal('pessoal'),
  financeiro('financeiro'),
  estudos('estudos'),
  comunicacao('comunicacao'),
  outro('outro');

  const CategoriaTarefa(this.value);

  final String value;

  static CategoriaTarefa fromValue(String value) {
    return CategoriaTarefa.values.firstWhere(
      (categoria) => categoria.value == value,
      orElse: () => CategoriaTarefa.outro,
    );
  }
}

enum PrioridadeTarefa {
  baixa('baixa'),
  media('media'),
  alta('alta');

  const PrioridadeTarefa(this.value);

  final String value;

  static PrioridadeTarefa fromValue(String value) {
    return PrioridadeTarefa.values.firstWhere(
      (prioridade) => prioridade.value == value,
      orElse: () => PrioridadeTarefa.media,
    );
  }
}

enum EsforcoTarefa {
  baixo('baixo'),
  medio('medio'),
  alto('alto');

  const EsforcoTarefa(this.value);

  final String value;

  static EsforcoTarefa fromValue(String value) {
    return EsforcoTarefa.values.firstWhere(
      (esforco) => esforco.value == value,
      orElse: () => EsforcoTarefa.medio,
    );
  }
}

enum PrazoSugerido {
  hoje('hoje'),
  estaSemana('esta_semana'),
  semPrazo('sem_prazo');

  const PrazoSugerido(this.value);

  final String value;

  static PrazoSugerido fromValue(String value) {
    return PrazoSugerido.values.firstWhere(
      (prazo) => prazo.value == value,
      orElse: () => PrazoSugerido.semPrazo,
    );
  }
}

enum StatusTarefa {
  aFazer('a_fazer'),
  emAndamento('em_andamento'),
  concluido('concluido');

  const StatusTarefa(this.value);

  final String value;

  static StatusTarefa fromValue(String value) {
    return StatusTarefa.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StatusTarefa.aFazer,
    );
  }
}

class Tarefa {
  Tarefa({
    required this.titulo,
    required this.categoria,
    required this.prioridade,
    required this.esforco,
    required this.prazoSugerido,
    required this.status,
  });

  final String titulo;
  final CategoriaTarefa categoria;
  final PrioridadeTarefa prioridade;
  final EsforcoTarefa esforco;
  final PrazoSugerido prazoSugerido;
  final StatusTarefa status;

  Tarefa copyWith({
    String? titulo,
    CategoriaTarefa? categoria,
    PrioridadeTarefa? prioridade,
    EsforcoTarefa? esforco,
    PrazoSugerido? prazoSugerido,
    StatusTarefa? status,
  }) {
    return Tarefa(
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      prioridade: prioridade ?? this.prioridade,
      esforco: esforco ?? this.esforco,
      prazoSugerido: prazoSugerido ?? this.prazoSugerido,
      status: status ?? this.status,
    );
  }

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      titulo: json['titulo'] as String? ?? '',
      categoria: CategoriaTarefa.fromValue(json['categoria'] as String? ?? ''),
      prioridade: PrioridadeTarefa.fromValue(
        json['prioridade'] as String? ?? '',
      ),
      esforco: EsforcoTarefa.fromValue(json['esforco'] as String? ?? ''),
      prazoSugerido: PrazoSugerido.fromValue(
        json['prazoSugerido'] as String? ?? '',
      ),
      status: StatusTarefa.fromValue(json['status'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'categoria': categoria.value,
      'prioridade': prioridade.value,
      'esforco': esforco.value,
      'prazoSugerido': prazoSugerido.value,
      'status': status.value,
    };
  }
}
