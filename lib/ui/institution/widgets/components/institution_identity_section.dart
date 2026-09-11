import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flag_admin_web/config/core_imports.dart';
import 'package:flag_admin_web/config/providers/providers.dart';

/// Secao modular de Identidade Visual para Agremiação (ADR-001 / Kickster).
///
/// Encapsula selecao de logotipo, 4 cores da marca com reatividade em tempo real e preview esportivo.
class InstitutionIdentitySection extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController abbreviationController;
  final TextEditingController logoUrlController;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final TextEditingController tertiaryColorController;
  final TextEditingController quaternaryColorController;
  final VoidCallback onDirty;

  const InstitutionIdentitySection({
    super.key,
    required this.nameController,
    required this.abbreviationController,
    required this.logoUrlController,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.tertiaryColorController,
    required this.quaternaryColorController,
    required this.onDirty,
  });

  Color? _parseHex(String text) {
    var raw = text.trim();
    if (raw.isEmpty) return null;
    if (!raw.startsWith('#')) {
      raw = '#$raw';
    }
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(raw)) return null;
    try {
      return Color(int.parse('0xFF${raw.substring(1)}'));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickColor(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) async {
    final picked = await showKicksterColorPicker(
      context: context,
      title: label,
      initialColor: controller.text.isNotEmpty ? controller.text : '#FD6B22',
    );
    if (picked != null) {
      controller.text = picked;
      onDirty();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KicksterSectionTitle(
          title: 'Identidade e Marca',
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shadowColor: AppColors.black.withValues(alpha: 0.08),
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview Esportivo Dinamico
                _buildSportBrandPreview(),
                const SizedBox(height: 16),

                // Upload de Logotipo
                KicksterImageUploader(
                  label: 'Escudo / Logotipo da Agremiação',
                  controller: logoUrlController,
                  uploadFunction:
                      ({required bytes, required filename, onProgress}) =>
                          storageService.uploadInstitutionLogo(
                            bytes: bytes,
                            filename: filename,
                            onProgress: onProgress,
                          ),
                  onUploaded: (url) => onDirty(),
                  onRemoved: () => onDirty(),
                ),
                const SizedBox(height: 16),

                // Inputs das 4 cores com preview individual e reatividade
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColorInputField(
                      context,
                      label: 'Cor Primária',
                      controller: primaryColorController,
                      fallbackColor: const Color(0xFFFD6B22),
                    ),
                    const SizedBox(width: 12),
                    _buildColorInputField(
                      context,
                      label: 'Cor Secundária',
                      controller: secondaryColorController,
                      fallbackColor: const Color(0xFF1E293B),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColorInputField(
                      context,
                      label: 'Cor Terciária',
                      controller: tertiaryColorController,
                      fallbackColor: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 12),
                    _buildColorInputField(
                      context,
                      label: 'Cor Quaternária',
                      controller: quaternaryColorController,
                      fallbackColor: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorInputField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Color fallbackColor,
  }) {
    return Expanded(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final parsed = _parseHex(controller.text) ?? fallbackColor;
          return KicksterInput(
            label: label,
            controller: controller,
            hintText: '#FD6B22',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(7),
            ],
            onChanged: (v) {
              var t = v.toUpperCase();
              if (t.isNotEmpty && !t.startsWith('#')) {
                t = '#$t';
              }
              if (t != v) {
                controller.value = TextEditingValue(
                  text: t,
                  selection: TextSelection.collapsed(offset: t.length),
                );
              }
              onDirty();
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final trimmed = v.trim();
              final formatted = trimmed.startsWith('#') ? trimmed : '#$trimmed';
              return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(formatted)
                  ? null
                  : 'Use #RRGGBB';
            },
            prefix: Padding(
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: GestureDetector(
                onTap: () => _pickColor(context, label, controller),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: parsed,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSportBrandPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        nameController,
        abbreviationController,
        logoUrlController,
        primaryColorController,
        secondaryColorController,
        tertiaryColorController,
        quaternaryColorController,
      ]),
      builder: (context, _) {
        final primary =
            _parseHex(primaryColorController.text) ?? const Color(0xFFFD6B22);
        final secondary =
            _parseHex(secondaryColorController.text) ?? const Color(0xFF1E293B);
        final tertiary = _parseHex(tertiaryColorController.text);
        final quaternary = _parseHex(quaternaryColorController.text);

        final instName = nameController.text.trim().isEmpty
            ? 'Nome da Agremiação'
            : nameController.text.trim();
        final abbreviation = abbreviationController.text.trim().isEmpty
            ? 'AGR'
            : abbreviationController.text.trim().toUpperCase();
        final logoUrl = logoUrlController.text.trim();

        final headerBrightness = ThemeData.estimateBrightnessForColor(primary);
        final headerTextColor = headerBrightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1E293B);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Superior Esportivo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    // Escudo
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildLogoFallback(primary),
                              )
                            : _buildLogoFallback(primary),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Titulo e Sigla no Banner
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: headerTextColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              abbreviation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: headerTextColor.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Barra inferior de amostras
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Paleta:',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSwatchCircle(primary, 'Primária'),
                    const SizedBox(width: 6),
                    _buildSwatchCircle(secondary, 'Secundária'),
                    if (tertiary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchCircle(tertiary, 'Terciária'),
                    ],
                    if (quaternary != null) ...[
                      const SizedBox(width: 6),
                      _buildSwatchCircle(quaternary, 'Quaternária'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoFallback(Color color) {
    return Center(child: Icon(Icons.shield_outlined, size: 28, color: color));
  }

  Widget _buildSwatchCircle(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
      ),
    );
  }
}
