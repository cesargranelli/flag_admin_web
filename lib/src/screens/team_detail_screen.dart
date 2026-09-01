import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Detalhe de um time (#12): apresenta os dados da entidade e oferece a
/// edição.
///
/// O time pertence a uma organização (clube/universidade). A seção
/// "Elencos" lista os elencos do time por competição ([teamRostersProvider])
/// e permite criar um novo elenco via seleção de competição + navegação
/// para `/teams/:id/roster`.
class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, this.teamId, this.team});

  final String? teamId;
  final Team? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedId = team?.id ?? teamId!;
    // Sempre observa o provider para refletir mutações (ex.: desativar/
    // reativar). Quando o time foi passado via `extra`, ele serve de
    // fallback imediato enquanto o provider carrega.
    final teamAsync = ref.watch(teamProvider(resolvedId));

    return AppScreen(
      title: team?.name ?? teamAsync.valueOrNull?.name ?? 'Time',
      breadcrumb: [
        const BreadcrumbItem('Início', route: '/'),
        const BreadcrumbItem(AppStrings.teams, route: '/teams'),
        if (team?.name != null) BreadcrumbItem(team!.name),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo
          teamAsync.when(
            loading: () => team != null
                ? _buildDetail(context, ref, team!)
                : const AppLoading(message: 'Carregando time...'),
            error: (error, stackTrace) => team != null
                ? _buildDetail(context, ref, team!)
                : AppErrorState(
                    message: 'Não foi possível carregar o time',
                    onRetry: () =>
                        ref.invalidate(teamProvider(resolvedId)),
                  ),
            data: (freshTeam) => _buildDetail(context, ref, freshTeam),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Team team) {
    // Resolve o nome do clube/universidade dono do time quando a lista de
    // organizações já carregou (fallback: id bruto).
    final orgs =
        ref.watch(organizationsProvider).valueOrNull ?? const <Organization>[];
    final orgName = orgs
        .where((o) => o.id == team.organizationId)
        .map((o) => o.tradeName)
        .firstOrNull;
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;
    final isInactive = team.status == 'INACTIVE';

    return AppLayout.detail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card (estilo KicksterCard): logo/avatar + nome + clube.
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
            child: Container(
              constraints: const BoxConstraints(minHeight: 160),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _avatar(team, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            if (team.shortName?.isNotEmpty ?? false)
                              Text(
                                team.shortName!,
                                style: AppTextStyles.paragraph.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Clube: ${orgName ?? team.organizationId}',
                              style: AppTextStyles.paragraph.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (isInactive) ...[
                              const SizedBox(height: 8),
                              KicksterBadge(
                                label: 'Inativo',
                                color: AppColors.danger,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      KicksterButton(
                        label: 'Editar dados',
                        icon: Icons.edit_outlined,
                        onPressed: () =>
                            context.go('/teams/${team.id}/edit', extra: team),
                      ),
                      if (isAdmin && isInactive)
                        KicksterButton(
                          label: 'Reativar',
                          icon: Icons.play_circle_outline,
                          variant: KicksterButtonVariant.outline,
                          onPressed: () => _reactivate(context, ref, team),
                        ),
                      if (isAdmin && !isInactive)
                        KicksterButton(
                          label: 'Desativar',
                          icon: Icons.pause_circle_outline,
                          variant: KicksterButtonVariant.outline,
                          onPressed: () => _deactivate(context, ref, team),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Informações do time.
          AppInfoCard(
            children: [
              AppInfoRow(label: 'Nome', value: team.name),
              AppInfoRow(
                label: 'Sigla',
                value:
                    team.shortName?.isNotEmpty == true ? team.shortName! : '—',
              ),
              AppInfoRow(
                label: 'Esporte',
                value:
                    team.sportName?.isNotEmpty == true ? team.sportName! : '—',
              ),
              AppInfoRow(
                label: 'URL do logo',
                value: team.logoUrl?.isNotEmpty == true ? team.logoUrl! : '—',
              ),
              AppInfoRow(
                label: 'Status',
                value: _statusLabel(team.status),
              ),
              AppInfoRow(label: 'Criado em', value: formatBrDate(team.createdAt)),
              AppInfoRow(
                label: 'Atualizado em',
                value: formatBrDate(team.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Elencos do time por competição: lista real com criação via
          // seleção de competição + navegação para a tela do elenco.
          _buildRostersSection(context, ref, team),
        ],
      ),
    );
  }

  /// Rótulo amigável do status do time para o card de informações.
  String _statusLabel(String? status) => switch (status) {
        'ACTIVE' => 'Ativo',
        'INACTIVE' => 'Inativo',
        _ => '—',
      };

  // ---------------------------------------------------------------------------
  // Elencos
  // ---------------------------------------------------------------------------

  /// Seção "Elencos": lista os elencos do time por competição
  /// ([teamRostersProvider]) e oferece a ação de criar um novo elenco.
  Widget _buildRostersSection(BuildContext context, WidgetRef ref, Team team) {
    final rostersAsync = ref.watch(teamRostersProvider(team.id));
    final competitions =
        ref.watch(competitionsProvider).valueOrNull ?? const <Competition>[];
    final competitionNameById = {
      for (final c in competitions) c.id: c.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KicksterSectionTitle(
          title: 'Elencos',
          icon: Icons.groups_outlined,
          action: KicksterButton(
            label: 'Criar elenco',
            icon: Icons.add,
            variant: KicksterButtonVariant.outline,
            onPressed: () => _pickCompetitionAndCreateRoster(context, ref, team),
          ),
        ),
        const SizedBox(height: 12),
        rostersAsync.when(
          loading: () => const AppLoading(message: 'Carregando elencos...'),
          error: (error, stackTrace) => AppErrorState(
            message: 'Não foi possível carregar os elencos',
            onRetry: () => ref.invalidate(teamRostersProvider(team.id)),
          ),
          data: (rosters) {
            if (rosters.isEmpty) {
              return KicksterEmptyState(
                icon: Icons.groups_outlined,
                message: 'Nenhum elenco criado',
                description:
                    'Crie o primeiro elenco do time em uma competição.',
                action: KicksterButton(
                  label: 'Criar elenco',
                  icon: Icons.add,
                  onPressed: () =>
                      _pickCompetitionAndCreateRoster(context, ref, team),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rosters.length; i++) ...[
                  _RosterCard(
                    roster: rosters[i],
                    competitionName:
                        competitionNameById[rosters[i].competitionId],
                    onTap: () => context.push(
                      '/teams/${team.id}/roster',
                      extra: rosters[i].competitionId,
                    ),
                  ),
                  if (i < rosters.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Abre o modal de criação de elenco: escolha da competição e navegação
  /// para `/teams/:id/roster`. O elenco é criado implicitamente pelo
  /// backend (`getOrCreateRoster`) quando o primeiro atleta é adicionado.
  Future<void> _pickCompetitionAndCreateRoster(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    List<Competition> competitions;
    try {
      competitions = await ref.read(competitionsProvider.future);
    } catch (_) {
      competitions = const <Competition>[];
    }
    if (!context.mounted) return;

    if (competitions.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Criar elenco'),
          content: const Text(
            'Nenhum campeonato disponível. Crie um campeonato antes de '
            'criar um elenco.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            KicksterButton(
              label: 'Fechar',
              variant: KicksterButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Publicadas primeiro (candidatas mais prováveis a receber elencos); as
    // demais também aparecem — o `getOrCreateRoster` do backend funciona
    // para qualquer status de competição.
    final sorted = [...competitions]..sort((a, b) {
        final byStatus = _competitionRank(a).compareTo(_competitionRank(b));
        return byStatus != 0 ? byStatus : a.name.compareTo(b.name);
      });

    String? selectedId;
    final competitionId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Criar elenco'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione a competição para o novo elenco do time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                KicksterDropdown<String>(
                  label: 'Competição',
                  hint: 'Selecione uma competição',
                  value: selectedId,
                  items: [
                    for (final c in sorted)
                      DropdownMenuItem(
                        value: c.id,
                        child: appDropdownItem(
                          Icons.emoji_events_outlined,
                          c.name,
                        ),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => selectedId = value),
                ),
              ],
            ),
          ),
          actions: [
            KicksterButton(
              label: 'Cancelar',
              variant: KicksterButtonVariant.text,
              onPressed: () => Navigator.of(innerContext).pop(),
            ),
            KicksterButton(
              label: 'Criar elenco',
              icon: Icons.add,
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.of(innerContext).pop(selectedId),
            ),
          ],
        ),
      ),
    );

    if (competitionId == null || !context.mounted) return;
    context.push('/teams/${team.id}/roster', extra: competitionId);
  }

  /// Prioridade de ordenação das competições no modal: publicadas primeiro.
  int _competitionRank(Competition c) =>
      c.status == CompetitionStatus.published ? 0 : 1;

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final ok = await showKicksterConfirm(
      context: context,
      title: 'Desativar time',
      content: '"${team.name}" ficará inativo até ser reativado.',
      confirmLabel: 'Desativar',
      danger: true,
    );
    if (ok != true || !context.mounted) return;
    await _toggleActive(context, ref, team, activate: false);
  }

  Future<void> _reactivate(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) =>
      _toggleActive(context, ref, team, activate: true);

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    Team team, {
    required bool activate,
  }) async {
    await runMutation(
      context,
      ref: ref,
      scope: 'team-detail',
      action: () => activate
          ? ref.read(teamApiProvider).reactivate(team.id)
          : ref.read(teamApiProvider).deactivate(team.id),
      successMessage:
          activate ? '${team.name} reativado.' : '${team.name} desativado.',
      errorMessage: activate
          ? 'Não foi possível reativar o time.'
          : 'Não foi possível desativar o time.',
      progressId: team.id,
      onSuccess: () {
        ref.invalidate(teamProvider(team.id));
        ref.invalidate(allTeamsProvider);
      },
    );
  }

  /// Avatar do time: logo (Image.network) quando a URL é válida, ou o ícone
  /// de grupos como fallback.
  Widget _avatar(Team team, {required double size}) {
    final logo = team.logoUrl;
    final validLogo =
        logo != null &&
        logo.isNotEmpty &&
        (Uri.tryParse(logo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validLogo
          ? Image.network(
              logo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.groups_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            )
          : const Icon(
              Icons.groups_outlined,
              color: AppColors.primary,
              size: 32,
            ),
    );
  }
}

/// Card de um elenco do time numa competição (estilo Kickster): nome da
/// competição como título, temporada/nome do elenco como subtítulo, badge
/// "Inativo" quando o status é `INACTIVE` e chevron à direita. O toque
/// navega para a tela do elenco (`/teams/:id/roster`).
class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.roster,
    required this.competitionName,
    required this.onTap,
  });

  final Roster roster;

  /// Nome da competição resolvido via [competitionsProvider] (nulo quando
  /// a competição ainda não carregou ou foi removida).
  final String? competitionName;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Título: nome da competição; fallback para o nome do elenco e, por
    // último, o id bruto da competição.
    final title = competitionName ?? roster.name ?? roster.competitionId;
    // Subtítulo: temporada quando presente ("Temporada 2026"); senão o nome
    // do elenco (caso ele não tenha sido usado no título).
    final subtitle = roster.season != null
        ? 'Temporada ${roster.season}'
        : (competitionName != null && roster.name != null ? roster.name : null);
    final isInactive = roster.status == 'INACTIVE';

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // Ícone do elenco em quadrado 48x48 com tinta primária.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
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
                    if (isInactive) ...[
                      const SizedBox(height: 2),
                      KicksterBadge(label: 'Inativo', color: AppColors.danger),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}