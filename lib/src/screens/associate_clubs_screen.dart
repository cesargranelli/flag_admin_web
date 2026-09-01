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
/// A tela inscreve TIMES: um dropdown de clube/universidade filtra os times
/// do clube selecionado (`clubTeamsProvider`), excluindo os já inscritos
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

  /// Clube/universidade selecionado no filtro (nulo = primeiro da lista).
  String? _selectedOrgId;

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

  /// Lista os times disponíveis do clube selecionado, excluindo os que já
  /// estão inscritos no campeonato. O dropdown de clube é um filtro auxiliar:
  /// a unidade de inscrição é o TIME.
  Widget _buildEnrollList(BuildContext context, String competitionId) {
    final enrolledAsync = ref.watch(teamsProvider(competitionId));
    final orgsAsync = ref.watch(organizationsProvider);

    return enrolledAsync.when(
      loading: () =>
          const AppLoading(message: 'Carregando times inscritos...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os times inscritos',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      ),
      data: (enrolledTeams) {
        final enrolledIds = enrolledTeams.map((t) => t.id).toSet();

        final allOrgs = orgsAsync.valueOrNull ?? const <Organization>[];
        if (orgsAsync.isLoading && allOrgs.isEmpty) {
          return const AppLoading(message: 'Carregando clubes...');
        }
        if (orgsAsync.hasError && allOrgs.isEmpty) {
          return AppErrorState(
            message: 'Não foi possível carregar os clubes',
            onRetry: () => ref.invalidate(organizationsProvider),
          );
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
            message: 'Nenhum clube cadastrado',
            description:
                'Crie um clube ou universidade com times antes de '
                'inscrevê-los no campeonato.',
            action: KicksterButton(
              label: 'Criar clube',
              icon: Icons.add,
              onPressed: () => context.go('/organizations/new'),
            ),
          );
        }

        // Clube efetivo: selecionado ?? primeiro da lista.
        final effectiveOrgId = _selectedOrgId ?? clubs.first.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLayout.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: KicksterDropdown<String>(
                  key: ValueKey('associate-org-$effectiveOrgId'),
                  label: 'Clube / Universidade',
                  value: effectiveOrgId,
                  items: clubs
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: appDropdownItem(
                            organizationTypeIcon(c.organizationType),
                            c.tradeName,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedOrgId = value),
                  helperText:
                      'Filtre os times disponíveis por clube ou universidade.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _clubTeamsList(
                context,
                effectiveOrgId,
                competitionId,
                enrolledIds,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Lista os times do clube selecionado que ainda não estão inscritos.
  Widget _clubTeamsList(
    BuildContext context,
    String organizationId,
    String competitionId,
    Set<String> enrolledIds,
  ) {
    final teamsAsync = ref.watch(clubTeamsProvider(organizationId));

    return teamsAsync.when(
      loading: () => const AppLoading(message: 'Carregando times...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os times do clube.',
        onRetry: () => ref.invalidate(clubTeamsProvider(organizationId)),
      ),
      data: (teams) {
        final available =
            teams.where((t) => !enrolledIds.contains(t.id)).toList();
        if (available.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum time disponível neste clube.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (var i = 0; i < available.length; i++) ...[
              _teamEnrollCard(context, available[i], competitionId),
              if (i != available.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
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