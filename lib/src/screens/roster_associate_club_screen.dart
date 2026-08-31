import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_screen.dart';

/// Tela para associar clubes/universidades ao campeonato — placeholder.
///
/// Esta tela será completamente reescrita para usar os novos endpoints de
/// inscrição de times em competições (enroll/disenroll).
/// Por enquanto, exibe um estado vazio informativo.
class RosterAssociateClubScreen extends StatelessWidget {
  const RosterAssociateClubScreen({super.key, this.competitionId});

  final String? competitionId;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Associar clube',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Elencos', route: '/rosters'),
        BreadcrumbItem('Associar clube'),
      ],
      body: KicksterEmptyState(
        icon: Icons.construction,
        message: 'Tela em reformulação',
        description:
            'A associação de clubes/universidades a campeonatos será '
            'reescrita para utilizar os novos endpoints de inscrição de '
            'times em competições. Em breve disponível.',
        action: KicksterButton(
          label: 'Voltar',
          icon: Icons.arrow_back,
          onPressed: () => context.go('/rosters'),
        ),
      ),
    );
  }
}
