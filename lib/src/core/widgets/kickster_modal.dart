import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Raio padrão de modais do design system Kickster.
const double kKicksterModalRadius = 16;

/// Aplica o visual padrão do modal Kickster (surface + raio 16) a um
/// `AlertDialog`, evitando repetir backgroundColor/shape em cada modal.
AlertDialog kicksterModalDialog({
  required Widget title,
  required Widget content,
  List<Widget>? actions,
}) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kKicksterModalRadius),
      ),
      title: title,
      content: content,
      actions: actions,
    );