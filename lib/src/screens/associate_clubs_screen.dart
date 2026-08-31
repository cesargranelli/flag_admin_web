import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Inscrição de times em um campeonato (#12) — substitui a antiga
/// "associação de clubes".
///
/// Não existe endpoint global de "todos os times": a tela itera as
/// organizações do tipo clube/universidade e lista os times de cada uma
/// (`clubTeamsProvider`), agrupados por seção, excluindo os já inscritos
/// (`teamsProvider`). O campeonato fica travado quando [lockedCompetitionId]
/// é informado (ex.: vindo do detalhe do campeonato ou dos elencos).
class AssociateClubsScreen extends ConsumerStatefulWidget {
  const AssociateClubsScreen({super.key, this.lockedCompetitionId});

  /// Quando informado, a tela fica "travada" nesse campeonato (dropdown
  /// desabilitado).
  final String? lockedCompetitionId;

  @override
  ConsumerState<AssociateClubsScreen> createState() =>
      _AssociateClubsScreenState();
}

class _AssociateClubsScreenState extends ConsumerState<AssociateClubsScreen> {
  static const _enrollScope = 'team-enroll';

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final lockedCompetitionId = widget.lockedCompetitionId;
    // Campeonato efetivo: travado (rota) ?? selecionado ?? primeiro.
    final effectiveComp =
        lockedCompetitionId ?? ref.watch(effectiveCompetitionProvider);
    final locked = lockedCompetitionId != null;

    return AppScreen(
      title: 'Inscrever time',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.teams, route: '/teams'),
        BreadcrumbItem('Inscrever time'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando campeonatos...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar os campeonatos',
                onRetry: () => ref.invalidate(competitionsProvider),
              ),
              data: (_) {
                if (compItems.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhum campeonato cadastrado',
                    description:
                        'Crie um campeonato antes de inscrever times.',
                    action: KicksterButton(
                      label: 'Criar campeonato',
                      icon: Icons.add,
                      onPressed: () => context.go('/competitions/new'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLayout.form(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: KicksterDropdown<String>(
                          key: ValueKey('associate-comp-$effectiveComp'),
                          label: locked
                              ? 'Campeonato (travado)'
                              : 'Campeonato',
                          value: effectiveComp,
                          items: compItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: appDropdownItem(
                                    Icons.emoji_events_outlined,
                                    c.name,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: locked
                              ? null
                              : (value) {
                                  ref
                                      .read(selectedCompetitionProvider.notifier)
                                      .state = value;
                                },
                        ),
                      ),
                    ),
                    Expanded(
                      child: effectiveComp != null
                          ? _buildEnrollList(context, effectiveComp)
                          : const AppEmptyState(
                              message: 'Selecione um campeonato',
                              icon: Icons.emoji_events_outlined,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lista os times disponíveis por clube/universidade, excluindo os que já
  /// estão inscritos no campeonato.
  Widget _buildEnrollList(BuildContext context, String competitionId) {
    final enrolledAsync = ref.watch(teamsProvider(competitionId));

    return enrolledAsync.when(
      loading: () =>
          const AppLoading(message: 'Carregando times inscritos...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os times inscritos',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      ),
      data: (enrolledTeams) {
        final enrolledIds = enrolledTeams.map((t) => t.id).toSet();

        final orgsAsync = ref.watch(organizationsProvider);
        final allOrgs = orgsAsync.valueOrNull ?? const <Organization>[];
        if (orgsAsync.isLoading && allOrgs.isEmpty) {
          return const AppLoading(message: 'Carregando clubes...');
        }

        final clubs = allOrgs
            .where(
              (o) =>
                  o.organizationType == OrganizationType.club ||
                  o.organizationType == OrganizationType.university,
            )
            .toList();

        if (clubs.isEmpty) {
          return KicksterEmptyState(
            icon: Icons.groups_outlined,
            message: 'Nenhum time disponível',
            description:
                'Crie um clube ou universidade com times antes de '
                'inscrevê-los no campeonato.',
            action: KicksterButton(
              label: 'Voltar',
              icon: Icons.arrow_back,
              variant: KicksterButtonVariant.outline,
              onPressed: () => context.go('/teams'),
            ),
          );
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (final org in clubs)
              _clubSection(context, org, competitionId, enrolledIds),
          ],
        );
      },
    );
  }

  /// Seção de um clube/universidade: título + times ainda não inscritos.
  Widget _clubSection(
    BuildContext context,
    Organization org,
    String competitionId,
    Set<String> enrolledIds,
  ) {
    final teamsAsync = ref.watch(clubTeamsProvider(org.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(
          title: org.tradeName,
          icon: organizationTypeIcon(org.organizationType),
        ),
        const SizedBox(height: 12),
        teamsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Carregando times...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          error: (error, stackTrace) => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Não foi possível carregar os times deste clube.',
              style: TextStyle(fontSize: 13, color: AppColors.danger),
            ),
          ),
          data: (teams) {
            final available =
                teams.where((t) => !enrolledIds.contains(t.id)).toList();
            if (available.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Todos os times deste clube já estão inscritos.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < available.length; i++) ...[
                  _teamEnrollCard(context, available[i], competitionId),
                  if (i != available.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Card de time disponível (nome + sigla) com o botão "Inscrever".
  Widget _teamEnrollCard(
    BuildContext context,
    Team team,
    String competitionId,
  ) {
    final enrolling = ref
        .watch(mutationProgressProvider(_enrollScope))
        .contains(team.id);

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
              child: const Icon(
                Icons.groups_outlined,
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
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (team.shortName?.isNotEmpty ?? false)
                    Text(
                      team.shortName!,
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
              label: 'Inscrever',
              icon: Icons.add,
              loading: enrolling,
              onPressed: enrolling
                  ? null
                  : () => _enroll(context, team, competitionId),
            ),
          ],
        ),
      ),
    );
  }

  /// Inscreve o time no campeonato e atualiza a listagem de inscritos.
  Future<void> _enroll(
    BuildContext context,
    Team team,
    String competitionId,
  ) async {
    await runMutation(
      context,
      ref: ref,
      scope: _enrollScope,
      action: () => ref.read(teamApiProvider).enroll(competitionId, team.id),
      successMessage: '${team.name} inscrito no campeonato.',
      errorMessage: 'Não foi possível inscrever o time.',
      progressId: team.id,
      onSuccess: () => ref.invalidate(teamsProvider(competitionId)),
    );
  }
}