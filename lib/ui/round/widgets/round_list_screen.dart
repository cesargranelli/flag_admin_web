import 'package:flag_admin_web/src/core/core.dart';
import 'package:flag_admin_web/src/domain/domain.dart';
import 'package:flag_admin_web/config/providers/providers.dart';
import 'package:flag_admin_web/domain/competition_permissions.dart';
import 'package:flag_admin_web/ui/round/view_models/round_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Gestão de rodadas: lista por competição e acesso ao detalhe.
///
/// O fluxo agora é: competição → rodadas.
/// As categories foram removidas; as rodadas associam-se diretamente
/// ao competition_id (migração V24).
class RoundListScreen extends ConsumerStatefulWidget {
  const RoundListScreen({super.key});

  @override
  ConsumerState<RoundListScreen> createState() => _RoundListScreenState();
}

class _RoundListScreenState extends ConsumerState<RoundListScreen> {
  final _searchController = TextEditingController();
  late RoundListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(roundListViewModelProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load(forceRefresh: true);
    });
  }

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

    final selectedCompetitionObj = compItems
        .where((c) => c.id == effectiveComp)
        .firstOrNull;
    final isDraft = selectedCompetitionObj?.status == CompetitionStatus.draft;
    final canEdit = canEditCompetition(
      ref.watch(authControllerProvider.select((a) => a.state.user)),
      selectedCompetitionObj,
    );
    final canManage = canEdit && isDraft;

    return AppScreen(
      title: AppStrings.rounds,
      scrollable: false,
      breadcrumb: const [
        BreadcrumbItem(AppStrings.home, route: '/'),
        BreadcrumbItem(AppStrings.rounds, route: '/rounds'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              if (effectiveComp != null && canManage)
                KicksterButton(
                  label: 'Novo',
                  icon: Icons.add,
                  onPressed: () =>
                      context.go('/rounds/new', extra: effectiveComp),
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
                    description: 'Crie uma competição para adicionar rodadas.',
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
                          key: ValueKey('comp-$effectiveComp'),
                          label: 'Competição',
                          value: effectiveComp,
                          items: compItems
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            ref
                                    .read(selectedCompetitionProvider.notifier)
                                    .state =
                                value;
                            _viewModel.setSelectedCompetition(value);
                          },
                        ),
                        if (!canManage)
                          EditRestrictionNote(
                            message: !isDraft
                                ? 'Competição publicada — as rodadas estão '
                                      'travadas.'
                                : 'Apenas o criador da competição pode '
                                      'gerenciar rodadas.',
                          ),
                      ],
                    ),
                    // Grid em altura finita (Expanded) → virtualização real.
                    const SizedBox(height: 16),
                    Expanded(
                      child: effectiveComp != null
                          ? ref
                                .watch(roundsProvider(effectiveComp))
                                .when(
                                  loading: () => const AppLoading(
                                    message: 'Carregando rodadas...',
                                  ),
                                  error: (error, stackTrace) => AppErrorState(
                                    message:
                                        'Não foi possível carregar as rodadas',
                                    onRetry: () => ref.invalidate(
                                      roundsProvider(effectiveComp),
                                    ),
                                  ),
                                  data: (items) {
                                    if (items.isEmpty) {
                                      return KicksterEmptyState(
                                        icon: Icons.format_list_numbered,
                                        message: 'Nenhuma rodada cadastrada',
                                        description:
                                            'Crie a primeira rodada da competição.',
                                        action: KicksterButton(
                                          label: 'Criar rodada',
                                          icon: Icons.add,
                                          onPressed: () => context.go(
                                            '/rounds/new',
                                            extra: effectiveComp,
                                          ),
                                        ),
                                      );
                                    }
                                    return AppEntityListScreen<Round>(
                                      items: items,
                                      cardBuilder: (round) =>
                                          _roundCard(context, round),
                                      searchField: _searchController,
                                      countLabel: 'rodadas',
                                      countLabelSingular: 'rodada',
                                      emptyMessage: 'Nenhuma rodada encontrada',
                                      gridPadding: const EdgeInsets.all(16),
                                      filter: (all, query) => query.isEmpty
                                          ? all
                                          : all
                                                .where(
                                                  (r) => r.name
                                                      .toLowerCase()
                                                      .contains(query),
                                                )
                                                .toList(growable: false),
                                    );
                                  },
                                )
                          : KicksterEmptyState(
                              icon: Icons.format_list_numbered,
                              message: 'Nenhuma rodada cadastrada',
                              description:
                                  'Crie uma competição para adicionar rodadas.',
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

  Widget _roundCard(BuildContext context, Round round) {
    return KicksterCard(
      icon: Icons.format_list_numbered,
      title: round.name,
      subtitle: 'Rodada ${round.number} · ${round.type.label}',
      trailing: const Icon(
        Icons.chevron_right,
        size: 22,
        color: AppColors.textSecondary,
      ),
      onTap: () => context.go('/rounds/${round.id}', extra: round),
    );
  }
}
