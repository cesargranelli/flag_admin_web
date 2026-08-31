import 'package:flag_admin_web/src/core/flag_core.dart';
import 'package:flag_admin_web/src/domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/mutation.dart';
import '../widgets/app_screen.dart';

/// Tela de elencos: lista apenas os clubes/universidades já associados ao
/// campeonato selecionado.
///
/// Para associar novos clubes, navega para `/rosters/associate`. Para
/// desassociar, o ícone `link_off` no card executa a remoção.
/// Tocar no card navega para `/teams/:id/roster`.
class RostersScreen extends ConsumerStatefulWidget {
  const RostersScreen({super.key});

  @override
  ConsumerState<RostersScreen> createState() => _RostersScreenState();
}

class _RostersScreenState extends ConsumerState<RostersScreen> {
  static const _disassociateScope = 'roster-disassociate';
  final _searchController = TextEditingController();
  String _query = '';

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
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Elencos'),
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
                        'Crie um campeonato para organizar os elencos.',
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

  /// Lista apenas os times (clubes/universidades) já associados ao campeonato.
  Widget _associatedTeamsList(BuildContext context, String competitionId) {
    final teamsAsync = ref.watch(teamsProvider(competitionId));

    return teamsAsync.when(
      loading: () => const AppLoading(message: 'Carregando elencos...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os elencos',
        onRetry: () => ref.invalidate(teamsProvider(competitionId)),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return KicksterEmptyState(
            icon: Icons.groups_outlined,
            message: 'Nenhum elenco associado',
            description: 'Associe clubes ao campeonato para criar elencos.',
            action: KicksterButton(
              label: 'Associar clube',
              icon: Icons.add,
              onPressed: () => context.go('/rosters/associate',
                  extra: competitionId),
            ),
          );
        }

        final query = _query.trim().toLowerCase();
        final filtered = query.isEmpty
            ? teams
            : teams
                .where(
                  (t) =>
                      t.name.toLowerCase().contains(query),
                )
                .toList(growable: false);

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
                        '${teams.length} ${teams.length == 1 ? 'elenco' : 'elencos'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    KicksterButton(
                      label: 'Associar clube',
                      icon: Icons.add,
                      onPressed: () => context.go('/rosters/associate',
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
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 960
                              ? 3
                              : constraints.maxWidth >= 600
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: filtered.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 112,
                            ),
                            itemBuilder: (context, index) {
                              return _teamCard(
                                context,
                                filtered[index],
                                competitionId: competitionId,
                              );
                            },
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

  /// Card de elenco (time já associado) no estilo Kickster:
  /// - Ícone do tipo de organização à esquerda
  /// - Nome do time + detalhes
  /// - Ícone `link_off` para desassociar (direita)
  /// - Tocar navega para `/teams/:id/roster`
  Widget _teamCard(
    BuildContext context,
    Team team, {
    required String competitionId,
  }) {
    final disassociating = ref
        .watch(mutationProgressProvider(_disassociateScope))
        .contains(team.id);

    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: 'Elenco do campeonato',
      trailing: disassociating
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              tooltip: 'Desassociar elenco',
              icon: const Icon(
                Icons.link_off,
                color: AppColors.danger,
              ),
              onPressed: () =>
                  _disassociate(context, team, competitionId),
            ),
      onTap: () => context.go('/teams/${team.id}/roster', extra: team),
    );
  }

  /// Desassocia o clube do campeonato (remove o Team).
  Future<void> _disassociate(
    BuildContext context,
    Team team,
    String competitionId,
  ) async {
    await runMutation(
      context,
      ref: ref,
      scope: _disassociateScope,
      action: () => ref.read(teamApiProvider).delete(team.id),
      successMessage: '${team.name} desassociado do campeonato.',
      errorMessage: 'Não foi possível desassociar o elenco.',
      progressId: team.id,
      onSuccess: () => ref.invalidate(teamsProvider(competitionId)),
    );
  }
}
