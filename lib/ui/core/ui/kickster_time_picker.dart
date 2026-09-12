import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'kickster_button.dart';

/// Tamanho do alvo de toque mínimo (tokens.md: "Alvos de toque: mín. 48px").
const double _kTouchTarget = 48;

/// Raio do container (padrão Kickster: border-radius 16px).
const double _kContainerRadius = 16;

/// Largura-alvo do seletor de tempo dentro do diálogo (~340–380px, spec Kickster).
const double _kTimePickerWidth = 360;

/// Abre o seletor de tempo Kickster em um diálogo modal.
///
/// Substituto direto de `showTimePicker` nas telas do admin web.
/// Comportamento:
/// - Permite selecionar hora e minuto em rodas (wheel);
/// - Possui botões de rodapé "Cancelar" e "Selecionar" no padrão Kickster;
/// - Fecha por fora do diálogo / ESC / Cancelar retornando `null`;
/// - Confirma selecionando e retornando o [TimeOfDay] escolhido.
Future<TimeOfDay?> showKicksterTimePickerDialog({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: KicksterTimePicker(initialTime: initialTime),
      ),
    ),
  );
}

/// Seletor de tempo no estilo do kit Kickster / Flag Platform.
///
/// Especificação implementada:
/// - Container branco (`AppColors.surface`) com raio 16, borda suave
///   (`AppColors.line`) e elevação/sombra sutil Kickster;
/// - Dois rodas (wheel) selecionáveis: horas (0–23) e minutos (0–59);
/// - Seleção destacada com cor primária (`AppColors.primary` / #083879);
/// - Alvos de toque mínimos de 48px;
/// - Botões de ação no rodapé: "Cancelar" e "Selecionar" no padrão
///   KicksterButton.
class KicksterTimePicker extends StatefulWidget {
  /// Hora inicial pré-selecionada.
  final TimeOfDay initialTime;

  const KicksterTimePicker({super.key, required this.initialTime});

  @override
  State<KicksterTimePicker> createState() => _KicksterTimePickerState();
}

class _KicksterTimePickerState extends State<KicksterTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
  }

  void _onHourSelected(int hour) {
    setState(() => _selectedHour = hour);
  }

  void _onMinuteSelected(int minute) {
    setState(() => _selectedMinute = minute);
  }

  void _confirmSelection() {
    Navigator.of(
      context,
    ).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    final double width = math.max(
      300.0,
      math.min(_kTimePickerWidth, MediaQuery.sizeOf(context).width - 32),
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
            _buildTimeDisplay(),
            const SizedBox(height: 24),
            _buildWheelRow(),
            const SizedBox(height: 24),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Exibe a hora selecionada no formato HH : MM.
  Widget _buildTimeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeDigit(_selectedHour),
        const Text(
          ' : ',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: AppColors.textSecondary,
          ),
        ),
        _buildTimeDigit(_selectedMinute),
      ],
    );
  }

  Widget _buildTimeDigit(int value) {
    return SizedBox(
      width: 80,
      child: Text(
        value.toString().padLeft(2, '0'),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w300,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildWheelRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWheelColumn(
          label: 'HORA',
          selectedValue: _selectedHour,
          count: 24,
          onSelected: _onHourSelected,
        ),
        const SizedBox(width: 32),
        _buildWheelColumn(
          label: 'MINUTO',
          selectedValue: _selectedMinute,
          count: 60,
          onSelected: _onMinuteSelected,
        ),
      ],
    );
  }

  Widget _buildWheelColumn({
    required String label,
    required int selectedValue,
    required int count,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grayLabel,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _kTouchTarget * 3,
          width: 100,
          child: ListView.builder(
            physics: const FixedExtentScrollPhysics(),
            itemCount: count,
            itemExtent: _kTouchTarget,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              final isSelected = index == selectedValue;
              return _buildWheelItem(
                value: index,
                isSelected: isSelected,
                onTap: () => onSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWheelItem({
    required int value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: _kTouchTarget,
        alignment: Alignment.center,
        child: Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
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
}
