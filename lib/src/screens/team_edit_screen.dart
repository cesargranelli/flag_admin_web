import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../widgets/app_screen.dart';

/// Formulário de edição de time — placeholder até reescrita completa (#12).
class TeamEditScreen extends StatelessWidget {
  const TeamEditScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Editar time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        const BreadcrumbItem('Editar'),
      ],
      body: AppEmptyState(
        message: 'Tela será reescrita na issue #12 '
            '(estrutura Team/Roster/Season).',
        icon: Icons.construction,
      ),
    );
  }
}
