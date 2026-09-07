import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flag_admin_web/src/core/core.dart';

/// Secao modular de Identidade Visual para organizacao (ADR-001 / Kickster).
///
/// Encapsula a selecao de cores da marca, logo, idioma e a previa esportiva reativa
/// em tempo real sem latencia visual.
class OrganizationIdentitySection extends StatelessWidget {
  final TextEditingController tradeNameController;
  final TextEditingController abbreviationController;
  final TextEditingController logoUrlController;
  final TextEditingController primaryColorController;
  final TextEditingController secondaryColorController;
  final TextEditingController tertiaryColorController;
  final TextEditingController quaternaryColorController;
  final TextEditingController localeController;
  final List<(String, String)> localeOptions;
  final VoidCallback onDirty;

  const OrganizationIdentitySection({
    super.key,
    required this.tradeNameController,
    required this.abbreviationController,
    required this.logoUrlController,
    required this.primaryColorController,
    required this.secondaryColorController,
    required this.tertiaryColorController,
    required this.quaternaryColorController,
    required this.localeController,
    required this.localeOptions,
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
  Widget build(BuildContext context) {
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
                // Previa esportiva reativa ouvindo todos os controllers de marca
                ListenableBuilder(
                  listenable: Listenable.merge([
                    tradeNameController,
                    abbreviationController,
                    logoUrlController,
                    primaryColorController,
                    secondaryColorController,
                    tertiaryColorController,
                    quaternaryColorController,
                  ]),
                  builder: (context, _) => _buildSportBrandPreview(context),
                ),
                const SizedBox(height: 20),

                // Upload do Logo (Firebase Storage)
                ListenableBuilder(
                  listenable: logoUrlController,
                  builder: (context, _) => KicksterImageUploader(
                    label: 'Logotipo da Organização (opcional)',
                    controller: logoUrlController,
                    currentImageUrl: logoUrlController.text,
                    onUploaded: (url) {
                      logoUrlController.text = url;
                      onDirty();
                    },
                    onRemoved: () {
                      logoUrlController.clear();
                      onDirty();
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Cores Primaria e Secundaria
                Row(
                  children: [
                    _buildColorInputField(
                      context,
                      label: 'Cor primária (opcional)',
                      controller: primaryColorController,
                      fallbackColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _buildColorInputField(
                      context,
                      label: 'Cor secundária (opcional)',
                      controller: secondaryColorController,
                      fallbackColor: const Color(0xFF1877F2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cores Terciaria e Quaternaria
                Row(
                  children: [
                    _buildColorInputField(
                      context,
                      label: 'Cor terciária (opcional)',
                      controller: tertiaryColorController,
                      fallbackColor: const Color(0xFF00B14F),
                    ),
                    const SizedBox(width: 12),
                    _buildColorInputField(
                      context,
                      label: 'Cor quaternária (opcional)',
                      controller: quaternaryColorController,
                      fallbackColor: const Color(0xFF212529),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Idioma
                KicksterDropdown<String>(
                  label: 'Idioma',
                  value: localeController.text,
                  values: [for (final l in localeOptions) l.$1],
                  labels: [for (final l in localeOptions) l.$2],
                  onChanged: (value) {
                    if (value == null) return;
                    localeController.text = value;
                    onDirty();
                  },
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
    final parsed = _parseHex(controller.text) ?? fallbackColor;
    return Expanded(
      child: KicksterInput(
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
      ),
    );
  }

  /// Card Esportivo Kickster simulando a aplicacao real da identidade da marca
  Widget _buildSportBrandPreview(BuildContext context) {
    final primary = _parseHex(primaryColorController.text) ?? AppColors.primary;
    final secondary = _parseHex(secondaryColorController.text) ?? const Color(0xFF1877F2);
    final tertiary = _parseHex(tertiaryColorController.text);
    final quaternary = _parseHex(quaternaryColorController.text);

    final orgName = tradeNameController.text.trim().isEmpty
        ? 'Nome da Organização'
        : tradeNameController.text.trim();
    final abbreviation = abbreviationController.text.trim().isEmpty
        ? 'ORG'
        : abbreviationController.text.trim().toUpperCase();
    final logoUrl = logoUrlController.text.trim();

    final isLightPrimary = primary.computeLuminance() > 0.55;
    final headerTextColor = isLightPrimary ? AppColors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prévia da Identidade Visual (Kickster Kit)',
              style: AppTextStyles.fieldLabel.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // Indicador de Acessibilidade / Contraste
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLightPrimary
                    ? const Color(0xFFFFF3CD)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLightPrimary
                      ? const Color(0xFFFFEEBA)
                      : const Color(0xFFC8E6C9),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLightPrimary ? Icons.info_outline : Icons.check_circle_outline,
                    size: 14,
                    color: isLightPrimary ? const Color(0xFF856404) : const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLightPrimary ? 'Fundo claro' : 'Alto contraste AA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLightPrimary ? const Color(0xFF856404) : const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Card Mockup Kickster
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner da Marca com Gradiente Esportivo
              Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      Color.lerp(primary, secondary, 0.45) ?? secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // Avatar / Logo ampliado com borda dupla
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _buildLogoFallback(primary),
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
                            orgName,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

              // Barra inferior de simulacao Kickster
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Amostras da paleta
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
                    const Spacer(),

                    // Mini Botao de Acao Tematico (Kickster)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_football,
                            size: 14,
                            color: headerTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Competições',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: headerTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoFallback(Color primary) {
    return Container(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(Icons.shield_outlined, size: 36, color: primary),
      ),
    );
  }

  Widget _buildSwatchCircle(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line, width: 1),
        ),
      ),
    );
  }
}
