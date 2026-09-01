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
/// O elenco é criado depois, na tela do time (tela de elencos); aqui a
/// inscrição é direta. Por isso a tela:
///
/// - fixa o campeonato alvo num card não-editável quando [lockedCompetitionId]
///   é informado; sem o travamento, mostra um dropdown para a escolha e, após
///   selecionar, passa a exibir o card fixo (alvo não muda no resto do fluxo);
/// - faz o mesmo com o clube/universidade alvo: card fixo quando
///   [lockedOrganizationId] é informado, dropdown que vira card fixo após a
///   escolha;
/// - para cada time disponível do clube efetivo (ainda não inscrito no
///   campeonato), exibe um card com botão "Inscrever" — sem escolha de elenco
///   (o elenco é criado posteriormente na tela de elencos do time).
class AssociateClubsScreen extends ConsumerStatefulWidget {
  const AssociateClubsScreen({
    super.key,
    this.lockedCompetitionId,
    this.lockedOrganizationId,
  });

  /// Quando informado, o campeonato alvo é exibido como card fixo
  /// (sem dropdown para trocar).
  final String? lockedCompetitionId;

  /// Quando informado, o clube/universidade alvo é exibido como card fixo
  /// (sem dropdown para trocar).
  final String? lockedOrganizationId;

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

  @override
  void didUpdateWidget(AssociateClubsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockedCompetitionId != widget.lockedCompetitionId) {
      _selectedCompetitionId = null;
    }
    if (oldWidget.lockedOrganizationId != widget.lockedOrganizationId) {
      _selectedOrgId = null;
    }
  }

  /// Campeonato alvo da tela: o travado pela rota ?? o escolhido no dropdown.
  String? get _competitionId =>
      widget.lockedCompetitionId ?? _selectedCompetitionId;

  /// Breadcrumb dinâmico (C3): reflete o caminho real de navegação.
  ///
  /// - Vindo do detalhe do clube ([lockedOrganizationId]): `Início ›
  ///   Organizações › {Clube} › Inscrever time`;
  /// - vindo do detalhe/campeonato ([lockedCompetitionId]): `Início ›
  ///   Campeonatos › {Campeonato} › Inscrever time`;
  /// - fluxo geral (tela Times): `Início › Times › Inscrever time`.
  List<BreadcrumbItem> _buildBreadcrumb() {
    final orgId = widget.lockedOrganizationId;
    if (orgId != null) {
      final orgs =
          ref.watch(organizationsProvider).valueOrNull ?? const <Organization>[];
      final org = orgs.where((o) => o.id == orgId).firstOrNull;
      return [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.organizations, route: '/organizations'),
        if (org != null)
          BreadcrumbItem(org.tradeName, route: '/organizations/${org.id}'),
        const BreadcrumbItem('Inscrever time'),
      ];
    }
    final compId = widget.lockedCompetitionId;
    if (compId != null) {
      final comps =
          ref.watch(competitionsProvider).valueOrNull ?? const <Competition>[];
      final comp = comps.where((c) => c.id == compId).firstOrNull;
      return [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
        if (comp != null)
          BreadcrumbItem(comp.name, route: '/competitions/${comp.id}'),
        const BreadcrumbItem('Inscrever time'),
      ];
    }
    return const [
      BreadcrumbItem('Início', route: '/'),
      BreadcrumbItem(AppStrings.teams, route: '/teams'),
      BreadcrumbItem('Inscrever time'),
    ];
  }

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
      breadcrumb: _buildBreadcrumb(),
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
  ///
  /// Largura limitada (não ocupa toda a largura da tela) e alinhado à
  /// esquerda, como os demais pickers da tela.
  Widget _buildCompetitionPicker(List<Competition> compItems) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 360,
        child: KicksterDropdown<String>(
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
            });
          },
          helperText:
              'O campeonato recebe a inscrição dos times disponíveis abaixo.',
        ),
      ),
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

  /// Dropdown de seleção do clube/universidade (usado somente quando a rota
  /// não trava o alvo). Após a escolha, a tela passa a exibir o card fixo e
  /// o restante do fluxo usa sempre esse clube.
  ///
  /// Largura limitada e alinhado à esquerda, como o picker de campeonato.
  Widget _buildOrganizationPicker(List<Organization> clubs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 360,
        child: KicksterDropdown<String>(
          key: const ValueKey('associate-org-picker'),
          label: 'Clube / Universidade',
          value: null,
          hint: 'Selecione um clube',
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
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedOrgId = value;
            });
          },
          helperText:
              'Filtre os times disponíveis por clube ou universidade.',
        ),
      ),
    );
  }

  /// Card fixo do clube/universidade alvo (mesmo padrão do campeonato):
  /// o alvo não é editável aqui, apenas direciona a lista de times abaixo.
  Widget _buildOrganizationCard(List<Organization> clubs, String orgId) {
    final org = clubs.where((o) => o.id == orgId).firstOrNull;

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
              child: Icon(
                organizationTypeIcon(org?.organizationType),
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
                    'Clube / Universidade',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    org?.tradeName ?? 'Clube não encontrado',
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
              message: 'Clube alvo desta inscrição (não editável)',
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
  /// estão inscritos no campeonato. O clube/universidade é apresentado como
  /// picker (dropdown) ou card fixo, igual ao campeonato: a unidade de
  /// inscrição é o TIME (com um elenco escolhido).
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

        // Clube efetivo: travado pela rota ?? escolhido no dropdown.
        // (Sem o travamento e sem escolha, o picker fica aberto.)
        final effectiveOrgId = widget.lockedOrganizationId ?? _selectedOrgId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLayout.form(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: effectiveOrgId != null
                    ? _buildOrganizationCard(clubs, effectiveOrgId)
                    : _buildOrganizationPicker(clubs),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: effectiveOrgId != null
                  ? _clubTeamsList(
                      context,
                      effectiveOrgId,
                      competitionId,
                      enrolledIds,
                    )
                  : const AppEmptyState(
                      message: 'Selecione um clube',
                      icon: Icons.groups_outlined,
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
        // Layout responsivo dos cards expansíveis: 2 por linha em telas
        // largas (>=900), coluna única abaixo disso. O Wrap permite alturas
        // variáveis (cards expandidos mudam de tamanho).
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final halfWidth = (constraints.maxWidth - 12) / 2;
            final Widget list = isWide
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final team in available)
                        SizedBox(
                          width: halfWidth,
                          child: _teamEnrollCard(context, team, competitionId),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < available.length; i++) ...[
                        _teamEnrollCard(context, available[i], competitionId),
                        if (i != available.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  );

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: list,
            );
          },
        );
      },
    );
  }

  /// Card simples de um time disponível (sem escolha de elenco): avatar +
  /// nome + sigla e, à direita, o botão "Inscrever" que faz a inscrição
  /// direta no campeonato. O elenco é criado depois, na tela do time.
  Widget _teamEnrollCard(
    BuildContext context,
    Team team,
    String competitionId,
  ) {
    final enrolling =
        ref.watch(mutationProgressProvider(_enrollScope)).contains(team.id);

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
      onSuccess: () {
        ref.invalidate(teamsProvider(competitionId));
        ref.invalidate(clubTeamsProvider(team.organizationId));
      },
    );
  }
}