import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';

/// Modal de associação de clubes/universidades a uma federação/liga/associação
/// (hierarquia ADR-006, issue #497).
///
/// Lista as organizações do tipo clube/universidade ainda NÃO associadas à
/// organização-pai e permite associar uma por vez.
Future<void> showAssociateClubModal(
  BuildContext context, {
  required String organizationId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AssociateClubModal(organizationId: organizationId),
  );
}

class AssociateClubModal extends ConsumerStatefulWidget {
  const AssociateClubModal({super.key, required this.organizationId});

  /// Organização-pai (federação/liga/associação) que receberá o clube.
  final String organizationId;

  @override
  ConsumerState<AssociateClubModal> createState() => _AssociateClubModalState();
}

class _AssociateClubModalState extends ConsumerState<AssociateClubModal> {
  static const _scope = 'associate-club';

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationsProvider);
    final associatedAsync = ref.watch(associatedClubsProvider(widget.organizationId));

    return AlertDialog(
      title: const Text('Associar clube'),
      content: SizedBox(
        width: AppLayout.maxFormWidth,
        child: associatedAsync.when(
          loading: () => const AppLoading(message: 'Carregando associações...'),
          error: (e, s) => AppErrorState(
            message: 'Não foi possível carregar as associações',
            onRetry: () =>
                ref.invalidate(associatedClubsProvider(widget.organizationId)),
          ),
          data: (associated) {
            final associatedIds = associated.map((o) => o.id).toSet();
            final allOrgs = orgsAsync.valueOrNull ?? const <Organization>[];

            // Clubes/universidades do sistema ainda não associados.
            final available = allOrgs
                .where(
                  (o) =>
                      o.id != widget.organizationId &&
                      (o.organizationType == OrganizationType.club ||
                          o.organizationType == OrganizationType.university) &&
                      !associatedIds.contains(o.id),
                )
                .toList();

            if (available.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    'Todos os clubes e universidades já estão associados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              height: 360,
              child: ListView.separated(
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final club = available[index];
                  return _clubRow(context, club);
                },
              ),
            );
          },
        ),
      ),
      actions: [
        KicksterButton(
          label: 'Fechar',
          variant: KicksterButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _clubRow(BuildContext context, Organization club) {
    final associating =
        ref.watch(mutationProgressProvider(_scope)).contains(club.id);

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                organizationTypeIcon(club.organizationType),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.tradeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (club.city?.isNotEmpty ?? false)
                    Text(
                      club.city!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            KicksterButton(
              label: 'Associar',
              icon: Icons.link,
              loading: associating,
              onPressed: associating ? null : () => _associate(club),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _associate(Organization club) async {
    await runMutation(
      context,
      ref: ref,
      scope: _scope,
      action: () => ref
          .read(organizationApiProvider)
          .associateClub(widget.organizationId, club.id),
      successMessage: '${club.tradeName} associado à organização.',
      errorMessage: 'Não foi possível associar o clube.',
      progressId: club.id,
      onSuccess: () {
        ref.invalidate(associatedClubsProvider(widget.organizationId));
        ref.invalidate(organizationsProvider);
      },
    );
  }
}