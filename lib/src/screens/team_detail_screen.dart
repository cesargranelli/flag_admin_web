import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../widgets/app_screen.dart';

/// Detalhe de um time — placeholder até reescrita completa (#12).
class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: team?.name ?? 'Time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (team?.name != null) BreadcrumbItem(team!.name),
      ],
      body: AppEmptyState(
        message: 'Tela será reescrita na issue #12 '
            '(estrutura Team/Roster/Season).',
        icon: Icons.construction,
      ),
    );
  }
}
