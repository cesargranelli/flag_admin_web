import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';

/// Modal de associação de clubes a uma divisão — placeholder até reescrita (#12).
///
/// O fluxo antigo (atribuir clube/divisão via Team.competitionId) não se
/// aplica mais à nova estrutura Team→CompetitionTeam→Roster.
void showClubAssignmentModal(
  BuildContext context, {
  required Division division,
}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Associação de clube'),
      content: const Text(
        'Esta funcionalidade será reescrita na issue #12 '
        '(estrutura Team/Roster/Season).',
      ),
      actions: [
        KicksterButton(
          label: 'Fechar',
          variant: KicksterButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
