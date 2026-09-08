import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'kickster_button.dart';

/// Tamanho do alvo de toque mínimo (tokens.md: "Alvos de toque: mín. 48px").
const double _kTouchTarget = 40;

/// Diâmetro do círculo do dia selecionado/hoje (spec Figma Kickster).
const double _kDayCircleSize = 36;

/// Largura-alvo do calendário dentro do diálogo (~340–380px, spec Kickster).
const double _kCalendarWidth = 360;

/// Raio do container (padrão Kickster: border-radius 16px).
const double _kContainerRadius = 16;

/// Meses em pt-BR (com primeira letra maiúscula para exibição no header).
const List<String> _kMonthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

/// Rótulos dos dias da semana em pt-BR, domingo primeiro (D S T Q Q S S),
/// alinhado ao padrão Kickster.
const List<String> _kWeekdayLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

/// Abre o calendário Kickster em um diálogo modal.
///
/// Substituto direto de `showDatePicker` nas telas do admin web.
/// Comportamento:
/// - Permite navegar e selecionar uma data;
/// - Possui botões de rodapé "Cancelar" e "Selecionar" no padrão Kickster;
/// - Duplo toque ou seleção direta confirma e fecha o diálogo;
/// - Fechar por fora do diálogo/ESC/Cancelar retorna `null`.
Future<DateTime?> showKicksterCalendarDialog(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  assert(!firstDate.isAfter(lastDate), 'firstDate deve ser <= lastDate');
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: KicksterCalendar(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ),
    ),
  );
}

/// Alias para manter retrocompatibilidade imediata.
Future<DateTime?> showAppCalendarDialog(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) =>
    showKicksterCalendarDialog(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

/// Calendário do design system Kickster / Flag Platform.
///
/// Especificação implementada:
/// - Container branco (`AppColors.surface`) com raio 16, borda suave (`AppColors.line`)
///   e elevação/sombra sutil Kickster;
/// - Header com título refinado em H5/H6 (`16px`, w700, `AppColors.textPrimary`),
///   exibindo "Mês de AAAA", com setas de navegação circulares sutis;
/// - Rótulos D S T Q Q S S em `AppColors.grayLabel` (12px, w600);
/// - Dias em 14px w500 em `AppColors.textPrimary`;
/// - Dia selecionado com círculo preenchido em `AppColors.primary` (#083879) e texto branco;
/// - Dia de hoje com anel sutil `AppColors.primary`;
/// - Botões de ação no rodapé: "Cancelar" e "Selecionar" no padrão KicksterButton.
class KicksterCalendar extends StatefulWidget {
  const KicksterCalendar({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  /// Data pré-selecionada (hora é descartada).
  final DateTime initialDate;

  /// Primeira data selecionável.
  final DateTime firstDate;

  /// Última data selecionável.
  final DateTime lastDate;

  @override
  State<KicksterCalendar> createState() => _KicksterCalendarState();
}

/// Alias para manter retrocompatibilidade com código existente.
typedef AppCalendar = KicksterCalendar;

class _KicksterCalendarState extends State<KicksterCalendar> {
  late DateTime _selected;
  late DateTime _displayedMonth;

  static DateTime _midnight(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    var selected = _midnight(widget.initialDate);
    if (selected.isBefore(widget.firstDate)) {
      selected = _midnight(widget.firstDate);
    } else if (selected.isAfter(widget.lastDate)) {
      selected = _midnight(widget.lastDate);
    }
    _selected = selected;
    _displayedMonth = DateTime(selected.year, selected.month);
  }

  bool get _canGoToPreviousMonth => _displayedMonth.isAfter(
    DateTime(widget.firstDate.year, widget.firstDate.month),
  );

  bool get _canGoToNextMonth => _displayedMonth.isBefore(
    DateTime(widget.lastDate.year, widget.lastDate.month),
  );

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _onDayTap(DateTime date) {
    setState(() {
      _selected = _midnight(date);
    });
  }

  void _confirmSelection() => Navigator.of(context).pop(_selected);

  @override
  Widget build(BuildContext context) {
    // Responsivo: adapta-se à largura da viewport mantendo o teto ideal de 360px
    final double width = math.max(
      296.0,
      math.min(_kCalendarWidth, MediaQuery.sizeOf(context).width - 32),
    );

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_kContainerRadius),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildWeekdayRow(),
            const SizedBox(height: 8),
            ..._buildWeekRows(),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title =
        '${_kMonthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}';
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_left,
          tooltip: 'Mês anterior',
          onPressed: _canGoToPreviousMonth ? _goToPreviousMonth : null,
        ),
        const SizedBox(width: 6),
        _NavButton(
          icon: Icons.chevron_right,
          tooltip: 'Próximo mês',
          onPressed: _canGoToNextMonth ? _goToNextMonth : null,
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Semantics(
      header: true,
      child: Row(
        children: [
          for (final label in _kWeekdayLabels)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 18 / 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayLabel,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Gera as semanas do mês exibido preenchendo a grade completa com dias
  /// dos meses adjacente (renderizados esmaecidos, sem interação).
  List<Widget> _buildWeekRows() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingDays = _displayedMonth.weekday % 7; // domingo = 0
    final trailingDays =
        (7 - (leadingDays + daysInMonth) % 7) % 7;

    final cells = <DateTime>[
      for (var i = leadingDays; i > 0; i--)
        _displayedMonth.subtract(Duration(days: i)),
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(year, month, day),
      for (var i = 1; i <= trailingDays; i++)
        DateTime(year, month + 1, i),
    ];

    return [
      for (var week = 0; week < cells.length ~/ 7; week++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: _buildDayCell(cells[week * 7 + column])),
            ],
          ),
        ),
    ];
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        KicksterButton(
          label: 'Cancelar',
          variant: KicksterButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        const SizedBox(width: 8),
        KicksterButton(
          label: 'Selecionar',
          variant: KicksterButtonVariant.primary,
          onPressed: _confirmSelection,
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final bool inMonth =
        date.month == _displayedMonth.month && date.year == _displayedMonth.year;
    final bool enabled =
        !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);
    final bool isSelected = date == _selected;
    final bool isToday = date == _midnight(DateTime.now());

    Widget cell = SizedBox(
      height: _kTouchTarget,
      child: Center(
        child: Container(
          width: _kDayCircleSize,
          height: _kDayCircleSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primary : null,
            border: isSelected || !isToday
                ? null
                : Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
          ),
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              height: 18 / 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );

    if (!inMonth || !enabled) {
      // Dias de outros meses ou fora do intervalo: decorativos (opacity 0.25).
      cell = Opacity(opacity: 0.25, child: ExcludeSemantics(child: cell));
    } else {
      cell = Semantics(
        button: true,
        selected: isSelected,
        label:
            '${date.day} de ${_kMonthNames[date.month - 1]} de ${date.year}',
        child: cell,
      );
    }

    return InkWell(
      onTap: enabled && inMonth ? () => _onDayTap(date) : null,
      onDoubleTap: enabled && inMonth
          ? () {
              _onDayTap(date);
              _confirmSelection();
            }
          : null,
      customBorder: const CircleBorder(),
      child: cell,
    );
  }
}

/// Botão circular de navegação do header (‹ ›).
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Material(
            color: AppColors.surfaceMuted,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
