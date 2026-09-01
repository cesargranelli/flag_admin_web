import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Variantes de botão do kit Kickster (issue #436/#445).
enum KicksterButtonVariant {
  /// Fundo `primary`, texto branco — ação principal.
  primary,

  /// Borda `primary`, texto `primary` — ação secundária.
  outline,

  /// Sem fundo/borda — ação terciária (link).
  text,

  /// Fundo `danger`, texto branco — ação destrutiva (ex.: rejeitar).
  danger,

  /// Fundo `success`, texto branco — ação de confirmação/sucesso
  /// (ex.: aprovar).
  success,

  /// Borda `danger`, texto `danger` — ação destrutiva secundária
  /// (ex.: desativar).
  dangerOutline,
}

/// Botão no estilo do kit Kickster (issue #436/#445).
///
/// Medidas EXATAS do Figma (node `Element` 23:169) para o tamanho padrão
/// (large): altura **56px** e raio **24** (pill). Variantes:
/// [KicksterButtonVariant] — incluindo as semânticas `danger`/`success`
/// (preenchidas) e `dangerOutline` (borda). O estado desabilitado usa fundo
/// `grayFill` (`#ecf1f6`) + texto `textPrimary` (variante "Disable" do kit).
/// Tudo via tokens `AppColors` — sem hex hardcoded. Quando [loading] é
/// `true`, o botão é desabilitado e exibe um spinner no lugar do ícone.
class KicksterButton extends StatelessWidget {
  const KicksterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KicksterButtonVariant.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KicksterButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final foreground = switch (variant) {
      KicksterButtonVariant.primary ||
      KicksterButtonVariant.danger ||
      KicksterButtonVariant.success => Colors.white,
      KicksterButtonVariant.dangerOutline => AppColors.danger,
      KicksterButtonVariant.outline || KicksterButtonVariant.text =>
        AppColors.primary,
    };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    final style = _kicksterStyle(
      background: switch (variant) {
        KicksterButtonVariant.primary => AppColors.primary,
        KicksterButtonVariant.danger => AppColors.danger,
        KicksterButtonVariant.success => AppColors.success,
        _ => null,
      },
      foreground: foreground,
      side: switch (variant) {
        KicksterButtonVariant.outline =>
          const BorderSide(color: AppColors.primary),
        KicksterButtonVariant.dangerOutline =>
          const BorderSide(color: AppColors.danger),
        _ => null,
      },
      // Hover/pressed mais escuros nas variantes preenchidas semânticas
      // (overlay preto) e overlay na cor da borda no outline danger.
      overlay: switch (variant) {
        KicksterButtonVariant.danger || KicksterButtonVariant.success =>
          WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? null
                : Colors.black.withValues(
                    alpha: states.contains(WidgetState.pressed) ? 0.20 : 0.12,
                  ),
          ),
        KicksterButtonVariant.dangerOutline =>
          WidgetStateProperty.resolveWith<Color?>(
            (states) => states.contains(WidgetState.disabled)
                ? null
                : AppColors.danger.withValues(
                    alpha: states.contains(WidgetState.pressed) ? 0.20 : 0.12,
                  ),
          ),
        _ => null,
      },
    );

    return switch (variant) {
      KicksterButtonVariant.primary ||
      KicksterButtonVariant.danger ||
      KicksterButtonVariant.success => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
      KicksterButtonVariant.outline || KicksterButtonVariant.dangerOutline =>
        OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
      KicksterButtonVariant.text => TextButton(
          onPressed: enabled ? onPressed : null,
          style: style,
          child: child,
        ),
    };
  }

  /// Estilo do kit: altura 56px, raio 24, disable `grayFill` + `textPrimary`.
  ButtonStyle _kicksterStyle({
    Color? background,
    required Color foreground,
    BorderSide? side,
    WidgetStateProperty<Color?>? overlay,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.grayFill
            : background,
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.textPrimary
            : foreground,
      ),
      overlayColor: overlay,
      side: WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => states.contains(WidgetState.disabled)
            ? const BorderSide(color: Colors.transparent)
            : side,
      ),
      minimumSize: const WidgetStatePropertyAll(Size(88, 56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        AppTextStyles.buttonText.copyWith(color: null),
      ),
    );
  }
}
