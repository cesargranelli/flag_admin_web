import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_screen.dart';

/// Tela de associação de clubes a campeonatos — placeholder.
///
/// Esta tela será completamente reescrita para usar os novos endpoints de
/// inscrição de times em competições (enroll/disenroll).
/// Por enquanto, exibe um estado vazio informativo.
class AssociateClubsScreen extends StatelessWidget {
  const AssociateClubsScreen({super.key, this.lockedCompetitionId});

  final String? lockedCompetitionId;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Associar clubes',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.teams, route: '/teams'),
        BreadcrumbItem('Associar clubes'),
      ],
      body: KicksterEmptyState(
        icon: Icons.construction,
        message: 'Tela em reformulação',
        description:
            'A associação de clubes a campeonatos será reescrita para '
            'utilizar os novos endpoints de inscrição de times em '
            'competições. Em breve disponível.',
        action: KicksterButton(
          label: 'Voltar',
          icon: Icons.arrow_back,
          onPressed: () => context.go('/teams'),
        ),
      ),
    );
  }
}
