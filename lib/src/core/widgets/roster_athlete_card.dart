import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'kickster_avatar.dart';

/// Card de atleta compartilhado para telas de elenco (roster).
///
/// Segue o Figma node 34442:3299:
/// - Background: `AppColors.grayFill` (#ECF1F6), border radius 12
/// - Padding: 4px 10px
/// - Avatar: 60x60 com border radius 16
/// - Nome: 14px Medium, cor preta
/// - Subtítulo: 12px Regular, cor secundária
/// - Trailing: slot livre para botão de ação (remover, adicionar, etc.)
class RosterAthleteCard extends StatelessWidget {
  const RosterAthleteCard({
    super.key,
    required this.name,
    this.subtitle,
    this.trailing,
    this.imageUrl,
  });

  /// Nome do atleta (obrigatório).
  final String name;

  /// Subtítulo (ex.: "#10 · Apelido · Posição"). Se nulo ou vazio, não exibe.
  final String? subtitle;

  /// Widget de ação à direita (botão remover, adicionar, chevron, etc.).
  final Widget? trailing;

  /// URL da foto do atleta. Se nulo, exibe iniciais.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.grayFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            // Avatar 60x60 com border radius 16px
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child: KicksterAvatar(
                  name: name,
                  imageUrl: imageUrl,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Nome + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Slot de ação
            ?trailing,
          ],
        ),
      ),
    );
  }
}
