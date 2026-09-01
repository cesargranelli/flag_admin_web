import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Tela de elencos: lista os times já inscritos no campeonato selecionado e,
/// ao expandir cada card, mostra os atletas dentro do elenco daquele time.
///
/// Para inscrever novos times, navega para `/teams/associate`. Para
/// desativar a inscrição, o ícone no card executa a desativação lógica do
/// time (`teamApi.deactivate`).
class RostersScreen extends ConsumerStatefulWidget {
  const RostersScreen({super.key});

  @override
  ConsumerState<RostersScreen> createState() => _RostersScreenState();
}

class _RostersScreenState extends ConsumerState<RostersScreen> {
  static const _deactivateScope = 'roster-deactivate';
  static const _rosterToggleScope = 'roster-toggle';
  final _searchController = TextEditingController();
  String _query = '';

  /// Times com o card expandido (mostrando os atletas do elenco).
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compItems = competitions.valueOrNull ?? const [];
    final effectiveComp = ref.watch(effectiveCompetitionProvider);

    return AppScreen(
      title: 'Elencos',
      scrollable: false,
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
                        'Crie um campeonato para organizar os elencos.',
                    action: KicksterButton(
                      label: 'Criar campeonato',
                      icon: Icons.add,
                      onPressed: () => context.push('/competitions/new'),
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
                          key: ValueKey('comp-$effectiveComp'),
                          label: 'Campeonato',
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
                          onChanged: (value) {
                            ref.read(selectedCompetitionProvider.notifier).state =
                                value;
                            ref.read(selectedTeamProvider.notifier).state = null;
                            setState(_expanded.clear);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: effectiveComp != null
                          ? _associatedTeamsList(context, effectiveComp)
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

  /// Lista os times (clubes/universidades) já associados ao campeonato com
  /// seus respectivos elencos (atletas) em cards expansíveis.
  Widget _associatedTeamsList(BuildContext context, String competitionId) {
    final teamsAsync = ref.watch(teamsProvider(competitionId));

    return teamsAsync.when(
      loading: () => const AppLoading(message: 'Carregando times...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os times',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return KicksterEmptyState(
            icon: Icons.groups_outlined,
            message: 'Nenhum time inscrito',
            description: 'Inscreva times no campeonato para criar elencos.',
            action: KicksterButton(
              label: 'Inscrever time',
              icon: Icons.add,
              onPressed: () => context.push('/teams/associate',
                  extra: competitionId),
            ),
          );
        }

        final query = _query.trim().toLowerCase();
        final filtered = query.isEmpty
            ? teams
            : teams
                .where(
                  (t) => t.name.toLowerCase().contains(query),
                )
                .toList(growable: false);

        // Primeiro time inscrito começa expandido para o usuário já ver os
        // atletas assim que a tela carrega.
        final defaultExpandedId =
            _expanded.isEmpty && teams.isNotEmpty ? teams.first.id : null;

        return AppLayout.content(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    if (query.isNotEmpty)
                      Text(
                        '${filtered.length} ${filtered.length == 1 ? 'resultado' : 'resultados'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      Text(
                        '${teams.length} ${teams.length == 1 ? 'time' : 'times'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    KicksterButton(
                      label: 'Inscrever time',
                      icon: Icons.add,
                      onPressed: () => context.push('/teams/associate',
                          extra: competitionId),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 280,
                      child: KicksterSearchField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const AppEmptyState(
                        message: 'Nenhum elenco encontrado',
                        icon: Icons.search_off,
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final team = filtered[index];
                          return _TeamRosterCard(
                            team: team,
                            competitionId: competitionId,
                            expanded: _expanded.contains(team.id) ||
                                team.id == defaultExpandedId,
                            onToggle: () => _toggleExpanded(team.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleExpanded(String teamId) {
    setState(() {
      if (!_expanded.remove(teamId)) _expanded.add(teamId);
    });
  }
}

/// Card expansível de um time inscrito: header com nome + ações e, quando
/// expandido, a lista de atletas do elenco (via [teamRosterProvider]).
class _TeamRosterCard extends ConsumerWidget {
  const _TeamRosterCard({
    required this.team,
    required this.competitionId,
    required this.expanded,
    required this.onToggle,
  });

  final Team team;
  final String competitionId;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deactivating = ref
        .watch(mutationProgressProvider(_RostersScreenState._deactivateScope))
        .contains(team.id);
    final togglingRoster = ref
        .watch(mutationProgressProvider(_RostersScreenState._rosterToggleScope))
        .contains(team.id);

    // Dados completos do time (shortName) — o mapping de `teamsProvider` só
    // carrega name/logo; o detalhe resolve o restante quando disponível.
    final detail = ref.watch(teamProvider(team.id)).valueOrNull;
    final shortName = team.shortName ??
        (detail?.shortName?.isNotEmpty ?? false ? detail!.shortName : null);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  // Avatar/logo do time
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
                        if (shortName != null && shortName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (team.status == 'INACTIVE') ...[
                          const SizedBox(height: 2),
                          KicksterBadge(
                            label: 'Inativo',
                            color: AppColors.danger,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  if (togglingRoster)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Desativar elenco',
                      icon: const Icon(
                        Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _deactivateRoster(context, ref),
                    ),
                  const SizedBox(width: 4),
                  if (deactivating)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Desativar time',
                      icon: const Icon(
                        Icons.pause_circle_outline,
                        color: AppColors.danger,
                      ),
                      onPressed: () =>
                          _deactivate(context, ref, team, competitionId),
                    ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _RosterBody(
                teamId: team.id,
                teamName: team.name,
                competitionId: competitionId,
              ),
            ),
        ],
      ),
    );
  }

  /// Desativa o time (status INACTIVE, desativação lógica).
  ///
  /// Exibe confirmação antes de executar a mutação e, após o sucesso,
  /// invalida a listagem de inscritos do campeonato (o time desativado deixa
  /// de aparecer como ativo).
  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    Team team,
    String competitionId,
  ) async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Desativar time',
      content: '"${team.name}" ficará inativo até ser reativado.',
      confirmLabel: 'Desativar',
      danger: true,
    );
    if (confirmed != true || !context.mounted) return;

    await runMutation(
      context,
      ref: ref,
      scope: _RostersScreenState._deactivateScope,
      action: () => ref.read(teamApiProvider).deactivate(team.id),
      successMessage: '${team.name} desativado.',
      errorMessage: 'Não foi possível desativar o time.',
      progressId: team.id,
      onSuccess: () => ref.invalidate(teamsProvider(competitionId)),
    );
  }

  /// Desativa o elenco do time na competição (status INACTIVE).
  ///
  /// Decisão pragmática: a tela de elencos não expõe o status do roster
  /// (o provider carrega apenas as entradas), então o botão executa a
  /// desativação sem espelhar estado — a reativação fica por conta do
  /// backend/futura tela dedicada.
  Future<void> _deactivateRoster(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await runMutation(
      context,
      ref: ref,
      scope: _RostersScreenState._rosterToggleScope,
      action: () =>
          ref.read(rosterApiProvider).deactivate(team.id, competitionId),
      successMessage: 'Elenco de ${team.name} desativado.',
      errorMessage: 'Não foi possível desativar o elenco.',
      progressId: team.id,
      onSuccess: () {
        ref.invalidate(
          teamRosterProvider(
            (teamId: team.id, competitionId: competitionId),
          ),
        );
        ref.invalidate(teamsProvider(competitionId));
      },
    );
  }
}

/// Corpo do card expandido: atletas do elenco do time na competição, com
/// estados de loading/erro/vazio por time.
class _RosterBody extends ConsumerWidget {
  const _RosterBody({
    required this.teamId,
    required this.teamName,
    required this.competitionId,
  });

  final String teamId;
  final String teamName;
  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(
      teamRosterProvider((teamId: teamId, competitionId: competitionId)),
    );

    return rosterAsync.when(
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
              'Não foi possível carregar o elenco',
              style: TextStyle(fontSize: 13, color: AppColors.danger),
            ),
            KicksterButton(
              label: 'Tentar novamente',
              variant: KicksterButtonVariant.text,
              onPressed: () => ref.invalidate(
                teamRosterProvider(
                  (teamId: teamId, competitionId: competitionId),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return _buildEmpty(context);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              _athleteCard(context, entries[i]),
              if (i < entries.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: KicksterButton(
                label: 'Adicionar atleta',
                icon: Icons.person_add_outlined,
                variant: KicksterButtonVariant.text,
                onPressed: () => context.push(
                  '/teams/$teamId/roster/add',
                  extra: (
                    teamId: teamId,
                    teamName: teamName,
                    competitionId: competitionId,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Nenhum atleta no elenco',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        KicksterButton(
          label: 'Adicionar atleta',
          icon: Icons.person_add_outlined,
          variant: KicksterButtonVariant.text,
          onPressed: () => context.push(
            '/teams/$teamId/roster/add',
            extra: (
              teamId: teamId,
              teamName: teamName,
              competitionId: competitionId,
            ),
          ),
        ),
      ],
    );
  }

  /// Card de atleta no estilo Figma (mesmo padrão do `TeamRosterScreen`):
  /// - Background: #ECF1F6 (Grayscale 20), raio 12, padding 4px 10px
  /// - Avatar: 60x60, border radius 16px
  /// - Nome: 14px Medium #111111
  /// - Subtítulo: 12px Regular #9CA4AB (#number · nickname · position)
  Widget _athleteCard(BuildContext context, RosterEntry entry) {
    final displayNickname = entry.nickname ?? entry.athleteNickname;
    final subtitle = [
      if (entry.number != null) '#${entry.number}',
      if (displayNickname != null && displayNickname.isNotEmpty)
        displayNickname,
      if (entry.position != null) entry.position!.label,
    ].join(' · ');

    return Card(
      elevation: 0,
      color: AppColors.grayFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child: KicksterAvatar(
                  name: entry.athleteName,
                  imageUrl: entry.photoUrl,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.athleteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Ações de edição do elenco ficam na tela dedicada do time.
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}