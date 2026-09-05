import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/competition_permissions.dart';
import '../../../../providers/providers.dart';

/// Detalhe de um time: apresenta os dados e oferece a edição.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamFuture = team != null ? null : ref.watch(teamProvider(teamId!));

    return AppScreen(
      title: team?.name ?? 'Time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (team?.name != null) BreadcrumbItem(team!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          teamFuture == null
              ? _buildDetail(context, ref, team!)
              : teamFuture.when(
                  loading: () =>
                      const AppLoading(message: 'Carregando time...'),
                  error: (error, stackTrace) => AppErrorState(
                    message: 'Não foi possível carregar o time',
                    onRetry: () => ref.invalidate(teamProvider(teamId!)),
                  ),
                  data: (team) => _buildDetail(context, ref, team),
                ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Team team) {
    // P3 #471: resolve a competição pelo family (autoDispose) em vez de
    // assistir a lista completa.
    final compAsync = ref.watch(competitionProvider(team.competitionId));
    final competitionName = compAsync.valueOrNull?.name ?? '';
    final divisions = ref.watch(divisionsProvider(team.competitionId));
    final divisionName =
        divisions.valueOrNull
            ?.where((d) => d.id == team.divisionId)
            .map((d) => d.name)
            .firstOrNull ??
        '';
    // Issue #261: edição do time exige ser criador da competição ou ADMIN.
    final competition = compAsync.valueOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      competition,
    );

    return AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KicksterAvatar(
                          imageUrl: team.logoUrl,
                          name: team.name,
                          size: 64,
                          icon: Icons.groups_outlined,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (team.shortName != null &&
                                  team.shortName!.isNotEmpty)
                                Text(
                                  team.shortName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (canEdit)
                      KicksterButton(
                        label: 'Editar dados',
                        icon: Icons.edit_outlined,
                        onPressed: () =>
                            context.go('/teams/${team.id}/edit', extra: team),
                      )
                    else
                      const EditRestrictionNote(
                        message:
                            'Apenas o criador da competição pode editar '
                            'este time.',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppInfoCard(children: [
              AppInfoRow(label: 'Nome', value: team.name),
              AppInfoRow(
                label: 'Sigla',
                value: team.shortName?.isNotEmpty == true ? team.shortName! : '—',
              ),
              AppInfoRow(label: 'Competição', value: competitionName),
              AppInfoRow(label: 'Divisão', value: divisionName),
              if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                AppInfoRow(label: 'URL do logo', value: team.logoUrl!),
            ]),
            const SizedBox(height: 16),
            Text(
              'Criado em ${formatBrDate(team.createdAt)}'
              '${team.updatedAt != null ? ' • Atualizado em ${formatBrDate(team.updatedAt)}' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
    );
  }
}
