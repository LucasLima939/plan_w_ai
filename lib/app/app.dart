import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/quadro_model.dart';
import 'models/tarefa_model.dart';
import 'services/gemini_service.dart';
import 'services/quadros_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const Color _bg = Color(0xFF000000);
  static const Color _surface = Color(0xFF050505);
  static const Color _accent = Color(0xFFFF005C);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textHeading = Color(0xFFE7E7E7);
  static const Color _textCardTitle = Color(0xFFEEEEEE);
  static const Color _textSubtitle = Color(0xFFA7A7A7);
  static const Color _textTag = Color(0xFFB8B8B8);
  static const Color _textHistoryEmpty = Color(0xFF8B8B8B);
  static const Color _placeholder = Color(0xFF6F6F6F);
  static const Color _borderSoft = Color(0x29FFFFFF);
  static const Color _borderMedium = Color(0x2EFFFFFF);
  static const Color _borderStrong = Color(0x3DFFFFFF);

  late final GeminiService geminiService;
  late final QuadrosService quadrosService;

  final TextEditingController _textoTarefasController = TextEditingController();

  String textoTarefas = '';

  Quadro? quadroAtual;
  List<Quadro> historico = const [];
  bool carregando = false;
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    geminiService = GeminiService();
    quadrosService = QuadrosService();
    _textoTarefasController.addListener(() {
      textoTarefas = _textoTarefasController.text;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      carregarHistorico();
    });
  }

  @override
  void dispose() {
    _textoTarefasController.dispose();
    super.dispose();
  }

  Future<void> organizarComIA() async {
    if (textoTarefas.trim().isEmpty) {
      setState(() => erro = 'Digite algumas tarefas antes de organizar.');
      return;
    }

    try {
      setState(() {
        carregando = true;
        erro = null;
      });

      final quadro = await geminiService.organizarTarefas(textoTarefas);

      setState(() => quadroAtual = quadro);
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      setState(
        () => erro = 'Não foi possível organizar as tarefas. Tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  List<Tarefa> tarefasPorStatus(StatusTarefa status) {
    final quadro = quadroAtual;

    if (quadro == null) {
      return const [];
    }

    return quadro.tarefas.where((tarefa) => tarefa.status == status).toList();
  }

  void moverTarefa(Tarefa tarefa, StatusTarefa novoStatus) {
    final quadro = quadroAtual;

    if (quadro == null) {
      return;
    }

    final tarefasAtualizadas = quadro.tarefas.map((item) {
      if (item.titulo == tarefa.titulo) {
        return item.copyWith(status: novoStatus);
      }

      return item;
    }).toList();

    setState(() {
      quadroAtual = quadro.copyWith(tarefas: tarefasAtualizadas);
    });
  }

  Future<void> salvarQuadro() async {
    final quadro = quadroAtual;

    if (quadro == null) {
      setState(() => erro = 'Nenhum quadro para salvar.');
      return;
    }

    try {
      setState(() {
        salvando = true;
        erro = null;
      });

      await quadrosService.salvarQuadro(quadro);
      await carregarHistorico();
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      setState(() => erro = 'Não foi possível salvar o quadro.');
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  Future<void> carregarHistorico() async {
    try {
      final quadros = await quadrosService.listarQuadros();
      setState(() => historico = quadros);
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      setState(() => erro = 'Não foi possível carregar o histórico.');
    }
  }

  void abrirQuadro(Quadro quadro) {
    setState(() => quadroAtual = quadro);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan w/ AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          secondary: _accent,
          surface: _bg,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: _textPrimary, height: 1.6),
        ),
      ),
      home: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _buildScrollable(
            isMobilePlatform: _isMobilePlatform,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 980;
                final isMobile = constraints.maxWidth < 640;
                final horizontalPadding = isMobile ? 14.0 : 48.0;
                final maxWidth = 1240.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: isMobile ? 24 : 56,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(isMobile: isMobile),
                          const SizedBox(height: 36),
                          _buildPanel(isMobile: isMobile),
                          const SizedBox(height: 42),
                          if (quadroAtual != null)
                            _buildBoard(isNarrow: isNarrow, isMobile: isMobile),
                          if (quadroAtual != null) const SizedBox(height: 42),
                          _buildHistory(isMobile: isMobile),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Widget _buildScrollable({
    required bool isMobilePlatform,
    required Widget child,
  }) {
    final scrollView = SingleChildScrollView(
      physics: isMobilePlatform
          ? const AlwaysScrollableScrollPhysics()
          : null,
      child: child,
    );

    if (!isMobilePlatform) {
      return scrollView;
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _surface,
      onRefresh: carregarHistorico,
      child: scrollView,
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderStrong)),
      ),
      padding: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'GEMINI + FIREBASE + FLUTTER',
            style: TextStyle(
              color: _accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              'DO CAOS AO KANBAN',
              style: TextStyle(
                color: _textHeading,
                fontSize: isMobile ? 36 : 60,
                fontWeight: FontWeight.w200,
                height: 1.08,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: const Text(
              'Cole uma lista bagunçada de tarefas e deixe o Gemini transformar tudo em um quadro visual organizado.',
              style: TextStyle(
                color: _textSubtitle,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel('LISTA DE TAREFAS'),
          const SizedBox(height: 18),
          _buildTextArea(),
          const SizedBox(height: 22),
          _buildActions(isMobile: isMobile),
          if (erro != null) ...[
            const SizedBox(height: 18),
            Text(
              erro!,
              style: const TextStyle(
                color: _accent,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      child: TextField(
        controller: _textoTarefasController,
        maxLines: null,
        minLines: 7,
        cursorColor: _accent,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        decoration: const InputDecoration(
          hintText:
              'Exemplo: revisar slides, responder mensagens, pagar conta, preparar demo...',
          hintStyle: TextStyle(color: _placeholder, fontSize: 16, height: 1.6),
          filled: true,
          fillColor: _surface,
          contentPadding: EdgeInsets.all(22),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: _borderMedium),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: _accent, width: 1.5),
          ),
        ),
        onChanged: (value) {
          textoTarefas = value;
        },
      ),
    );
  }

  Widget _buildActions({required bool isMobile}) {
    final primary = _ChaosButton(
      label: carregando ? 'ORGANIZANDO...' : 'ORGANIZAR COM IA',
      onPressed: carregando ? null : organizarComIA,
      filled: false,
      fullWidth: isMobile,
    );

    final secondary = _ChaosButton(
      label: salvando ? 'SALVANDO...' : 'SALVAR QUADRO',
      onPressed: (quadroAtual == null || salvando) ? null : salvarQuadro,
      filled: false,
      secondary: true,
      fullWidth: isMobile,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: 14),
          secondary,
        ],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [primary, secondary],
    );
  }

  Widget _buildBoard({required bool isNarrow, required bool isMobile}) {
    final quadro = quadroAtual!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBoardHeader(quadro, isMobile: isMobile),
          const SizedBox(height: 28),
          _buildKanban(isNarrow: isNarrow),
        ],
      ),
    );
  }

  Widget _buildBoardHeader(Quadro quadro, {required bool isMobile}) {
    final title = Text(
      quadro.tituloQuadro.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );

    final count = Text(
      '${quadro.tarefas.length} TAREFAS',
      style: const TextStyle(
        color: _accent,
        fontSize: 12.8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          count,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Flexible(child: title), count],
    );
  }

  Widget _buildKanban({required bool isNarrow}) {
    final columns = [
      _buildColumn(
        title: 'A FAZER',
        status: StatusTarefa.aFazer,
        moveLabel: 'MOVER PARA ANDAMENTO',
        moveTo: StatusTarefa.emAndamento,
      ),
      _buildColumn(
        title: 'EM ANDAMENTO',
        status: StatusTarefa.emAndamento,
        moveLabel: 'CONCLUIR',
        moveTo: StatusTarefa.concluido,
      ),
      _buildColumn(
        title: 'CONCLUÍDO',
        status: StatusTarefa.concluido,
        moveLabel: null,
        moveTo: null,
      ),
    ];

    if (isNarrow) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _borderSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i == columns.length - 1
                        ? BorderSide.none
                        : const BorderSide(color: _borderSoft),
                  ),
                ),
                child: columns[i],
              ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderSoft)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < columns.length; i++)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: i == columns.length - 1
                          ? BorderSide.none
                          : const BorderSide(color: _borderSoft),
                    ),
                  ),
                  child: columns[i],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required StatusTarefa status,
    required String? moveLabel,
    required StatusTarefa? moveTo,
  }) {
    final tarefas = tarefasPorStatus(status);

    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          for (final tarefa in tarefas)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCard(tarefa, moveLabel: moveLabel, moveTo: moveTo),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(
    Tarefa tarefa, {
    required String? moveLabel,
    required StatusTarefa? moveTo,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _borderSoft),
          right: BorderSide(color: _borderSoft),
          bottom: BorderSide(color: _borderSoft),
          left: BorderSide(color: _accent, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tarefa.titulo,
            style: const TextStyle(
              color: _textCardTitle,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(tarefa.categoria.value),
              _buildTag('PRIORIDADE: ${tarefa.prioridade.value}'),
              _buildTag('ESFORÇO: ${tarefa.esforco.value}'),
              _buildTag('PRAZO: ${tarefa.prazoSugerido.value}'),
            ],
          ),
          if (moveLabel != null && moveTo != null) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: _ChaosButton(
                label: moveLabel,
                onPressed: () => moverTarefa(tarefa, moveTo),
                filled: false,
                small: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _borderSoft),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: _textTag,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildHistory({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel('QUADROS SALVOS'),
          const SizedBox(height: 18),
          if (historico.isEmpty)
            const Text(
              'Nenhum quadro salvo ainda.',
              style: TextStyle(color: _textHistoryEmpty, fontSize: 16),
            ),
          for (final quadro in historico)
            _buildHistoryCard(quadro, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Quadro quadro, {required bool isMobile}) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          quadro.tituloQuadro,
          style: const TextStyle(
            color: _textHeading,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${quadro.tarefas.length} TAREFAS',
          style: const TextStyle(
            color: _accent,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );

    final button = _ChaosButton(
      label: 'ABRIR',
      onPressed: () => abrirQuadro(quadro),
      filled: false,
      small: true,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderSoft)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: button),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Flexible(child: info), button],
            ),
    );
  }
}

class _ChaosButton extends StatefulWidget {
  const _ChaosButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.secondary = false,
    this.small = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool secondary;
  final bool small;
  final bool fullWidth;

  @override
  State<_ChaosButton> createState() => _ChaosButtonState();
}

class _ChaosButtonState extends State<_ChaosButton> {
  static const Color _accent = Color(0xFFFF005C);
  static const Color _borderSecondary = Color(0x61FFFFFF);
  static const Color _textSecondary = Color(0xFFD7D7D7);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final hovered = _hovered && !disabled;

    final Color borderColor = widget.secondary && !hovered
        ? _borderSecondary
        : _accent;
    final Color background = hovered ? _accent : Colors.transparent;
    final Color textColor = hovered
        ? Colors.white
        : widget.secondary
            ? _textSecondary
            : Colors.white;

    final double horizontal = widget.small ? 13 : 22;
    final double vertical = widget.small ? 10 : 14;
    final double fontSize = widget.small ? 10.5 : 12.2;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      constraints: BoxConstraints(
        minWidth: widget.small ? 0 : 180,
        minHeight: widget.small ? 0 : 0,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );

    final clickable = MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(opacity: disabled ? 0.42 : 1, child: button),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: clickable);
    }

    return clickable;
  }
}
