import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/domain/competition_permissions.dart';
import '../../../../providers/providers.dart';

/// Gestão de times: lista por competição e acesso ao detalhe.
///
/// O fluxo agora é: competição → times.
/// Os times associam-se diretamente ao competition_id (migração V24);
/// as categories foram removidas.
class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key, this.lockedCompetitionId});

  /// Quando informado, a tela fica "travada" nessa competição (dropdown
  /// desabilitado) — usado ao vir do detalhe da competição (#349).
  final String? lockedCompetitionId;

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    final lockedCompetitionId = widget.lockedCompetitionId;
    final compItems = competitions.valueOrNull ?? const [];
    // P4 #461: locked (rota) ?? efetivo (selecionado ?? primeiro da lista).
    final effectiveComp =
        lockedCompetitionId ?? ref.watch(effectiveCompetitionProvider);
    final locked = lockedCompetitionId != null;

    // Issue #261: inscrição de times exige ser criador da competição
    // ou ADMIN (o backend já bloqueia as escritas).
    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      selectedCompetitionObj,
    );

    return AppScreen(
      title: 'Times',
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Times'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              if (effectiveComp != null && canEdit)
                KicksterButton(
                  label: 'Novo',
                  icon: Icons.add,
                  onPressed: () =>
                      context.go('/teams/new', extra: effectiveComp),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo (Expanded para dar altura finita ao grid)
          Expanded(
            child: competitions.when(
              loading: () =>
                  const AppLoading(message: 'Carregando competições...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar as competições',
                onRetry: () => ref.invalidate(competitionsProvider),
              ),
              data: (_) {
                if (compItems.isEmpty) {
                  return KicksterEmptyState(
                    icon: Icons.emoji_events_outlined,
                    message: 'Nenhuma competição cadastrada',
                    description:
                        'Crie uma competição para inscrever times.',
                    action: KicksterButton(
                      label: 'Criar competição',
                      icon: Icons.add,
                      onPressed: () => context.go('/competitions/new'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KicksterDropdown<String>(
                          label: locked
                              ? 'Competição (travada)'
                              : 'Competição',
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
                                      .read(selectedCompetitionProvider
                                          .notifier)
                                      .state = value;
                                },
                        ),
                        if (!canEdit)
                          const EditRestrictionNote(
                            message:
                                'Apenas o criador da competição pode '
                                'inscrever times.',
                          ),
                      ],
                    ),
                    // Grid em altura finita (Expanded) → virtualização real.
                    const SizedBox(height: 16),
                    Expanded(
                      child: effectiveComp != null
                          ? ref
                                .watch(teamsProvider(effectiveComp))
                                .when(
                                  loading: () => const AppLoading(
                                    message: 'Carregando times...',
                                  ),
                                  error: (error, stackTrace) =>
                                      AppErrorState(
                                    message:
                                        'Não foi possível carregar os times',
                                    onRetry: () => ref.invalidate(
                                        teamsProvider(effectiveComp)),
                                  ),
                                  data: (items) {
                                    if (items.isEmpty) {
                                      return KicksterEmptyState(
                                        icon: Icons.groups_outlined,
                                        message: 'Nenhum time cadastrado',
                                        description:
                                            'Inscreva o primeiro time na competição.',
                                        action: KicksterButton(
                                          label: 'Criar time',
                                          icon: Icons.add,
                                          onPressed: () => context.go(
                                            '/teams/new',
                                            extra: effectiveComp,
                                          ),
                                        ),
                                      );
                                    }
                                    return AppEntityListScreen<Team>(
                                      items: items,
                                      cardBuilder: (team) =>
                                          _teamCard(context, team),
                                      searchField: _searchController,
                                      countLabel: 'times',
                                      countLabelSingular: 'time',
                                      emptyMessage:
                                          'Nenhum time encontrado',
                                      gridPadding:
                                          const EdgeInsets.all(16),
                                      filter: (all, query) => query.isEmpty
                                          ? all
                                          : all
                                              .where(
                                                (t) => t.name
                                                    .toLowerCase()
                                                    .contains(query),
                                              )
                                              .toList(growable: false),
                                    );
                                  },
                                )
                          : KicksterEmptyState(
                              icon: Icons.groups_outlined,
                              message: 'Nenhum time cadastrado',
                              description:
                                  'Crie uma competição para inscrever times.',
                              action: KicksterButton(
                                label: 'Criar competição',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.go('/competitions/new'),
                              ),
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

  /// Card de time no padrão Kickster (core #439): ícone de grupo, nome e
  /// subtítulo com esporte + contagem de atletas.
  Widget _teamCard(BuildContext context, Team team) {
    final subtitle = [
      if (team.sportName?.isNotEmpty ?? false) team.sportName!,
      '${team.athleteCount ?? 0} atletas',
    ].join(' · ');

    return KicksterCard(
      icon: Icons.groups_outlined,
      title: team.name,
      subtitle: subtitle,
      onTap: () => context.push('/teams/${team.id}', extra: team),
    );
  }
}
