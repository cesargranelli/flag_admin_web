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
/// O elenco é uma extensão do TIME (não do campeonato): os elencos do time
/// são criados para o campeonato e o campeonato apenas **recebe a inscrição**
/// do time com o elenco escolhido. Por isso a tela:
///
/// - fixa o campeonato alvo num card não-editável quando [lockedCompetitionId]
///   é informado; sem o travamento, mostra um dropdown para a escolha e, após
///   selecionar, passa a exibir o card fixo (alvo não muda no resto do fluxo);
/// - para cada time disponível (filtro de clube/universidade), exibe um card
///   expansível com a lista de elencos do time (`teamRostersProvider`) para
///   escolher **exatamente um** elenco antes de inscrever;
/// - oferece "Criar novo elenco" (navega para `/teams/:id/roster` com o
///   `competitionId` no `extra`) — o backend cria o elenco implicitamente
///   (`getOrCreateRoster`) quando o primeiro atleta é adicionado.
class AssociateClubsScreen extends ConsumerStatefulWidget {
  const AssociateClubsScreen({super.key, this.lockedCompetitionId});

  /// Quando informado, o campeonato alvo é exibido como card fixo
  /// (sem dropdown para trocar).
  final String? lockedCompetitionId;

  @override
  ConsumerState<AssociateClubsScreen> createState() =>
      _AssociateClubsScreenState();
}

class _AssociateClubsScreenState extends ConsumerState<AssociateClubsScreen> {
  static const _enrollScope = 'team-enroll';

  /// Clube/universidade selecionado no filtro (nulo = primeiro da lista).
  String? _selectedOrgId;

  /// Campeonato escolhido via dropdown (usado quando a rota não trava).
  /// Depois da escolha, vira o card fixo da tela.
  String? _selectedCompetitionId;

  /// Elenco escolhido por time (teamId → rosterId) antes da inscrição.
  /// Limpo quando o campeonato alvo muda.
  final Map<String, String> _selectedRosterByTeam = {};

  /// Times com o card expandido (lista de elencos visível).
  final Set<String> _expandedTeams = {};

  @override
  void didUpdateWidget(AssociateClubsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockedCompetitionId != widget.lockedCompetitionId) {
      _selectedCompetitionId = null;
      _selectedRosterByTeam.clear();
      _expandedTeams.clear();
    }
  }

  /// Campeonato alvo da tela: o travado pela rota ?? o escolhido no dropdown.
  String? get _competitionId =>
      widget.lockedCompetitionId ?? _selectedCompetitionId;

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final competitionId = _competitionId;
    // Sem campeonato travado e ainda sem escolha: mostra o dropdown.
    final showCompetitionPicker = competitionId == null;

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
                        child: showCompetitionPicker
                            ? _buildCompetitionPicker(compItems)
                            : _buildCompetitionCard(
                                compItems,
                                competitionId,
                              ),
                      ),
                    ),
                    Expanded(
                      child: competitionId != null
                          ? _buildEnrollList(context, competitionId)
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

  /// Dropdown de seleção do campeonato (usado somente quando a rota não
  /// trava o alvo). Após a escolha, a tela passa a exibir o card fixo e o
  /// restante do fluxo usa sempre esse campeonato.
  Widget _buildCompetitionPicker(List<Competition> compItems) {
    return KicksterDropdown<String>(
      key: const ValueKey('associate-comp-picker'),
      label: 'Campeonato',
      value: null,
      hint: 'Selecione um campeonato',
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
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedCompetitionId = value;
          _selectedRosterByTeam.clear();
          _expandedTeams.clear();
        });
      },
      helperText:
          'O campeonato recebe a inscrição do time com o elenco escolhido.',
    );
  }

  /// Card fixo do campeonato alvo: o elenco é uma extensão do TIME e o
  /// campeonato apenas recebe a inscrição — o alvo não é editável aqui.
  Widget _buildCompetitionCard(
    List<Competition> compItems,
    String competitionId,
  ) {
    final competition = compItems
        .where((c) => c.id == competitionId)
        .firstOrNull;

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
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
                Icons.emoji_events_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Campeonato',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    competition?.name ?? 'Campeonato não encontrado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Tooltip(
              message: 'Campeonato alvo desta inscrição (não editável)',
              child: Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista os times disponíveis do clube selecionado, excluindo os que já
  /// estão inscritos no campeonato. O dropdown de clube é um filtro auxiliar:
  /// a unidade de inscrição é o TIME (com um elenco escolhido).
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

  /// Card expansível de um time disponível: header (avatar + nome + chevron)
  /// e, quando expandido, a lista de elencos do time para escolher
  /// **exatamente um** antes de inscrever.
  Widget _teamEnrollCard(
    BuildContext context,
    Team team,
    String competitionId,
  ) {
    final expanded = _expandedTeams.contains(team.id);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (!_expandedTeams.remove(team.id)) _expandedTeams.add(team.id);
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: KicksterAvatar(
                      name: team.name,
                      imageUrl: team.logoUrl,
                      icon: Icons.groups_outlined,
                      size: 48,
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
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _TeamRosterPicker(
                team: team,
                competitionId: competitionId,
                selectedRosterId: _selectedRosterByTeam[team.id],
                onSelectRoster: (rosterId) => setState(() {
                  _selectedRosterByTeam[team.id] = rosterId;
                }),
                onEnroll: () => _enroll(context, team, competitionId),
              ),
            ),
        ],
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
      onSuccess: () {
        ref.invalidate(teamsProvider(competitionId));
        if (mounted) {
          setState(() {
            _selectedRosterByTeam.remove(team.id);
            _expandedTeams.remove(team.id);
          });
        }
      },
    );
  }
}

/// Corpo do card expandido de um time: lista de elencos (radio-style),
/// botão "Criar novo elenco" (sempre visível) e botão "Inscrever"
/// (habilitado somente quando um elenco foi escolhido).
class _TeamRosterPicker extends ConsumerWidget {
  const _TeamRosterPicker({
    required this.team,
    required this.competitionId,
    required this.selectedRosterId,
    required this.onSelectRoster,
    required this.onEnroll,
  });

  final Team team;

  /// Campeonato alvo (fixo) da inscrição — também passado como `extra`
  /// para a tela de elenco do time (`/teams/:id/roster`).
  final String competitionId;

  /// Elenco escolhido para este time (nulo = ainda não escolhido).
  final String? selectedRosterId;

  final ValueChanged<String> onSelectRoster;

  final VoidCallback onEnroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rostersAsync = ref.watch(teamRostersProvider(team.id));
    final competitions =
        ref.watch(competitionsProvider).valueOrNull ?? const <Competition>[];
    final enrolling = ref
        .watch(mutationProgressProvider(_AssociateClubsScreenState._enrollScope))
        .contains(team.id);

    // Nome do campeonato do elenco (o elenco é criado para um campeonato).
    String competitionName(String id) {
      for (final c in competitions) {
        if (c.id == id) return c.name;
      }
      return '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rostersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não foi possível carregar os elencos do time.',
                  style: TextStyle(fontSize: 13, color: AppColors.danger),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(teamRostersProvider(team.id)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (rosters) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rosters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum elenco criado',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                for (var i = 0; i < rosters.length; i++) ...[
                  _rosterRow(context, rosters[i], competitionName),
                  if (i < rosters.length - 1) const SizedBox(height: 4),
                ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: KicksterButton(
            label: 'Criar novo elenco',
            icon: Icons.add,
            variant: KicksterButtonVariant.outline,
            onPressed: () async {
              await context.push(
                '/teams/${team.id}/roster',
                extra: competitionId,
              );
              // Ao voltar, recarrega os elencos do time (o backend cria o
              // elenco implicitamente ao adicionar o primeiro atleta).
              ref.invalidate(teamRostersProvider(team.id));
            },
          ),
        ),
        const SizedBox(height: 12),
        KicksterButton(
          label: 'Inscrever',
          icon: Icons.add,
          loading: enrolling,
          onPressed:
              selectedRosterId == null || enrolling ? null : onEnroll,
        ),
      ],
    );
  }

  /// Linha selecionável de um elenco do time (radio-style): nome do
  /// campeonato + "Temporada {season}" (ou nome do elenco) + badge
  /// "Inativo" quando o status é INACTIVE.
  Widget _rosterRow(
    BuildContext context,
    Roster roster,
    String Function(String) competitionName,
  ) {
    final selected = roster.id == selectedRosterId;
    final compName = competitionName(roster.competitionId);
    final subtitle = (roster.season?.isNotEmpty ?? false)
        ? 'Temporada ${roster.season}'
        : (roster.name?.isNotEmpty ?? false ? roster.name! : 'Elenco');

    return InkWell(
      onTap: () => onSelectRoster(roster.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compName.isNotEmpty)
                    Text(
                      compName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (compName.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (roster.status == 'INACTIVE') ...[
              const SizedBox(width: 8),
              const KicksterBadge(label: 'Inativo', color: AppColors.danger),
            ],
          ],
        ),
      ),
    );
  }
}