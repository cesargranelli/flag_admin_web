import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../src/core/theme/app_colors.dart';
import '../../../src/core/theme/app_text_styles.dart';
import 'kickster_button.dart';
import 'kickster_input.dart';

/// Modal de selecao de cor no padrao visual Kickster.
///
/// Apresenta paleta curada de cores esportivas, campo de entrada hex formatado
/// e preview dinamico em pill centralizado. Retorna o codigo hex no formato '#RRGGBB'
/// ou null se cancelado.
class KicksterColorPickerDialog extends StatefulWidget {
  final String? initialColor;
  final String title;

  const KicksterColorPickerDialog({
    super.key,
    this.initialColor,
    this.title = 'Escolher cor',
  });

  @override
  State<KicksterColorPickerDialog> createState() =>
      _KicksterColorPickerDialogState();
}

class _KicksterColorPickerDialogState extends State<KicksterColorPickerDialog> {
  late final TextEditingController _hexController;
  late String _selectedHex;

  /// Paleta esportiva curada no padrao Kickster
  static const List<String> _sportPresets = [
    '#FD6B22', // Laranja Kickster
    '#1877F2', // Azul Royal
    '#0D1B2A', // Azul Marinho
    '#00B14F', // Verde Gramado
    '#1B4332', // Verde Floresta
    '#E53935', // Vermelho Cardinal
    '#800020', // Bordo / Vinho
    '#7B1FA2', // Roxo Atletica
    '#FBC02D', // Dourado Esportivo
    '#00ACC1', // Turquesa
    '#212529', // Grafite
    '#78909C', // Aco / Prata
    '#111111', // Preto Profundo
    '#FFFFFF', // Branco
    '#42A5F5', // Azul Celeste
    '#E65100', // Âmbar Intenso
  ];

  @override
  void initState() {
    super.initState();
    final raw = widget.initialColor?.trim() ?? '#FD6B22';
    _selectedHex = _normalizeHex(raw);
    _hexController = TextEditingController(
      text: _selectedHex.replaceFirst('#', ''),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _normalizeHex(String value) {
    var v = value.trim().toUpperCase();
    if (!v.startsWith('#')) {
      v = '#$v';
    }
    if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(v)) {
      return v;
    }
    return '#FD6B22';
  }

  Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length != 6) return null;
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return null;
    }
  }

  void _onPresetTapped(String hex) {
    setState(() {
      _selectedHex = hex;
      _hexController.text = hex.replaceFirst('#', '');
    });
  }

  void _onHexChanged(String value) {
    final clean = value.trim().toUpperCase().replaceAll('#', '');
    if (clean != value) {
      _hexController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
    if (clean.length == 6 && RegExp(r'^[0-9A-F]{6}$').hasMatch(clean)) {
      setState(() {
        _selectedHex = '#$clean';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _parseColor(_selectedHex) ?? AppColors.primary;
    final isWhite = _selectedHex == '#FFFFFF';

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Preview Pill Centralizado
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isWhite
                                ? AppColors.line
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _selectedHex,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grade de Cores Esportivas
              Text(
                'Paleta Esportiva',
                style: AppTextStyles.fieldLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final hex in _sportPresets) _buildColorCircle(hex),
                ],
              ),
              const SizedBox(height: 20),

              // Campo de Entrada Hex
              KicksterInput(
                label: 'Código Hexadecimal',
                controller: _hexController,
                hintText: 'FD6B22',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 4, right: 2),
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: _onHexChanged,
              ),
              const SizedBox(height: 24),

              // Botoes de Acao Kickster
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  KicksterButton(
                    label: 'Cancelar',
                    variant: KicksterButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  KicksterButton(
                    label: 'Aplicar',
                    onPressed: () {
                      Navigator.of(context).pop(_selectedHex);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(String hex) {
    final color = _parseColor(hex) ?? Colors.transparent;
    final isSelected = hex == _selectedHex;
    final isLight = hex == '#FFFFFF' || hex == '#FBC02D';

    return GestureDetector(
      onTap: () => _onPresetTapped(hex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (hex == '#FFFFFF' ? AppColors.line : Colors.transparent),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 18,
                color: isLight ? AppColors.black : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// Helper para abrir o seletor de cores no padrao Kickster.
Future<String?> showKicksterColorPicker({
  required BuildContext context,
  String? initialColor,
  String title = 'Escolher cor',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        KicksterColorPickerDialog(initialColor: initialColor, title: title),
  );
}
